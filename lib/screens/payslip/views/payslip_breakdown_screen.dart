import 'dart:convert';
import 'dart:io' as io;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/screens/payslip/components/printPdf.dart';
import 'package:shop/screens/payslip/views/payslip_theme.dart';

import '../../../constants.dart';

class _Deduction {
  final String name;
  final double amount;
  final int cat; // 0 contributions, 1 loans, 2 others, 3 attendance/adjustments
  final bool credit; // true = added to pay (+), false = taken off (−)
  final String? label; // overrides the group name shown under the item
  const _Deduction(this.name, this.amount, this.cat,
      {this.credit = false, this.label});

  String get group => label ?? PayslipPalette.categoryNames[cat];
}

class PayslipBreakdownScreen extends ConsumerStatefulWidget {
  final String month;
  final int year;

  const PayslipBreakdownScreen({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  ConsumerState<PayslipBreakdownScreen> createState() =>
      _PayslipBreakdownScreenState();
}

class _PayslipBreakdownScreenState
    extends ConsumerState<PayslipBreakdownScreen> {
  // Staff ID of the signed-in user, from the auth provider.
  String get _staffId => ref.read(authProvider)?.staffId?.toString() ?? '';

  Map<String, dynamic>? _payslipData;
  List<_Deduction> _items = [];
  bool _loading = true;
  String? _error;
  int _tab = 0; // 0 All, 1 Contributions, 2 Loans, 3 Others
  bool _showNetIncome = true;
  bool _showAll = false; // deductions list: show first 5 or everything

  // Appointment status of the signed-in user, taken from the first work
  // history record, the same way the Categories widget does it.
  String _appointmentStatus = '';

  /// "CONTRACT OF SERVICE - NON-KALAHI" -> "Contract of Service - Non-Kalahi".
  /// Capitalizes each word and each part of a hyphenated word; small words
  /// like "of" stay lower case.
  String _titleCase(String input) {
    const small = {'of', 'and', 'the', 'for', 'in', 'on'};
    var first = true;
    return input.trim().split(RegExp(r'\s+')).map((word) {
      final lower = word.toLowerCase();
      final isFirst = first;
      first = false;
      if (!isFirst && small.contains(lower)) return lower;
      return lower
          .split('-')
          .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1))
          .join('-');
    }).join(' ');
  }

  Future<String> _loadAppointmentStatus() async {
    try {
      final list = await ref.read(workHistoryProvider.future);
      if (list.isNotEmpty) {
        return (list.first['appointment_status'] as String?) ?? '';
      }
    } catch (e) {
      debugPrint('Error reading work history: $e');
    }
    return '';
  }

  // Deductions to print, from Settings for this appointment status, grouped
  // like the web payslip: contributions, loans, others.
  Map<String, List<String>> _deductionLayout = {};

  // TODO: confirm this is your settings endpoint (same one the web payroll
  // uses for SettingsApi.getAll).
  static const _settingsUrl = 'https://fo2-paygen.dswd.gov.ph/api/settings-filter';

  @override
  void initState() {
    super.initState();
    _fetchPayslipData();
  }

  /// Same as the web payslip: the settings of the user's appointment status,
  /// grouped by _type ("Contribution" -> contributions, "Loan" -> loans,
  /// "Other" -> others). Settings of any other type are ignored.
  Future<Map<String, List<String>>> _fetchDeductionLayout() async {
    final status = (await _loadAppointmentStatus()).trim();
    _appointmentStatus = status;
    if (status.isEmpty) return const {};

    // Work history stores the status in ALL CAPS; send it to Settings in
    // normal case, e.g. "Permanent". Every "Contract of Service - ..." status
    // (Kalahi, Non-Kalahi, ...) is sent as plain "Contract of Service".
    final appStatus = status.toUpperCase().contains('CONTRACT OF SERVICE')
        ? 'Contract of Service'
        : _titleCase(status);

    final url =
        '$_settingsUrl?appointment_status=${Uri.encodeQueryComponent(appStatus)}';
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );
      if (res.statusCode != 200) {
        debugPrint('Settings API error: ${res.statusCode} ${res.body}');
        return const {};
      }
      final body = jsonDecode(res.body);
      final list = body is List
          ? body
          : (body is Map && body['data'] is List ? body['data'] as List : const []);

      final layout = <String, List<String>>{
        'contributions': [],
        'loans': [],
        'others': [],
      };
      for (final s in list.whereType<Map>()) {
        final cat = '${'${s['_type'] ?? ''}'.toLowerCase()}s';
        if (layout.containsKey(cat)) layout[cat]!.add('${s['_abbr'] ?? ''}');
      }
      return layout;
    } catch (e) {
      debugPrint('Error fetching settings: $e');
      return const {};
    }
  }

  // ── Data ───────────────────────────────────────────────────────────────────
  Future<void> _fetchPayslipData({bool silent = false}) async {
    final staffId = _staffId;
    if (staffId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No staff ID found. Please sign in again.';
      });
      return;
    }

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final response = await http.post(
        Uri.parse('https://fo2-paygen.dswd.gov.ph/api/payslip-by-id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          // Sent as a number when possible, like the old hard-coded value.
          'staff_id': int.tryParse(staffId) ?? staffId,
          'period_month': widget.month,
          'period_year': widget.year.toString(),
        }),
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final list = (json['data'] as List?) ?? const [];
        final layout = await _fetchDeductionLayout();
        if (!mounted) return;
        setState(() {
          _deductionLayout = layout;
          _error = null;
          _payslipData = list.isNotEmpty
              ? Map<String, dynamic>.from(list[0] as Map)
              : null;
          _items = _parseDeductions();
        });
      } else {
        debugPrint(
            'API Error: ${widget.month} ${widget.year} ${response.statusCode} ${response.body}');
        setState(() => _error =
        'The server answered with error ${response.statusCode}. Try again in a moment.');
      }
    } catch (e) {
      debugPrint('Error fetching payslip: $e');
      if (mounted) {
        setState(() => _error =
        "Couldn't reach the payslip service. Check your connection and try again.");
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_Deduction> _parseDeductions() {
    final d = _payslipData;
    final out = <_Deduction>[];

    // Attendance first, like the printed payslip: absences, tardiness and
    // premium late are taken off the pay.
    const attendance = [
      ['Absences', 'absences_amount'],
      ['Tardiness', 'late_amount'],
      ['Premium late', 'premium_late'],
    ];
    for (final it in attendance) {
      final v = payNum(d?[it[1]]);
      if (v != 0) out.add(_Deduction(it[0], v, 3, label: 'Attendance'));
    }

    // Contributions, loans and others from the payslip.
    const keys = ['contributions', 'loans', 'others'];
    for (var i = 0; i < keys.length; i++) {
      final raw = (d?['deductions']?[keys[i]] ?? []) as List;
      for (final e in raw.whereType<Map>()) {
        out.add(_Deduction('${e['deduction_name'] ?? ''}', payNum(e['amount']), i));
      }
    }

    // Adjustments: only shown when there is an amount.
    const adjustments = [
      ['Overpayment', 'overpayment'],
      ['Disallowance', 'disallowances'],
      ['Refund', 'refund'],
      ['Unearned pay', 'unearned_pay'],
    ];
    for (final it in adjustments) {
      final v = payNum(d?[it[1]]);
      if (v != 0) out.add(_Deduction(it[0], v, 3, label: 'Adjustment'));
    }
    // Underpayment is owed to the employee, so it is added (+).
    final under = payNum(d?['underpayment']);
    if (under != 0) {
      out.add(_Deduction('Underpayment', under, 3, credit: true, label: 'Adjustment'));
    }
    return out;
  }

  double _catTotal(int cat) =>
      _items.where((e) => e.cat == cat).fold(0.0, (a, b) => a + b.amount);

  // Money taken off the pay (−) and money added to it (+).
  double get _totalDeductions =>
      _items.where((e) => !e.credit).fold(0.0, (a, b) => a + b.amount);
  double get _credits =>
      _items.where((e) => e.credit).fold(0.0, (a, b) => a + b.amount);
  // Pay before deductions.
  double get _gross => _net + _totalDeductions - _credits;
  double get _net => payNum(_payslipData?['net_amount']);
  double get _first => payNum(_payslipData?['first_quincena']);
  double get _second => payNum(_payslipData?['second_quincena']);

  List<_Deduction> get _visible =>
      _tab == 0 ? _items : _items.where((e) => e.cat == _tab - 1).toList();

  // ── Dates ──────────────────────────────────────────────────────────────────
  int get _monthNumber {
    final m = widget.month.trim();
    for (final fmt in [DateFormat.MMMM(), DateFormat.MMM()]) {
      try {
        return fmt.parseLoose(m).month;
      } catch (_) {}
    }
    final n = int.tryParse(m);
    if (n != null && n >= 1 && n <= 12) return n;
    return DateTime.now().month;
  }

  String get _monthName =>
      DateFormat.MMMM().format(DateTime(widget.year, _monthNumber));

  String get _dateRange {
    final last = DateTime(widget.year, _monthNumber + 1, 0).day;
    return '1 $_monthName ${widget.year} - $last $_monthName ${widget.year}';
  }

  // ── PDF: download & print ──────────────────────────────────────────────────
  Future<pw.MemoryImage> _loadLogoImage() async {
    final ByteData logoData =
    await rootBundle.load('assets/images/dswd-pilipinas.png');
    return pw.MemoryImage(logoData.buffer.asUint8List());
  }

  void _snack(String message) {
    if (!mounted) return;
    final p = PayslipPalette.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: pText(15, FontWeight.w500, p.bg)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: p.ink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  Future<void> _handleDownload() async {
    if (_payslipData == null) {
      _snack('No payslip data to download yet.');
      return;
    }
    try {
      final logoImage = await _loadLogoImage();
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => buildPayslip(
              logoImage, _payslipData!, _monthName, widget.year, _dateRange,
              staffId: _staffId,
              appointmentStatus: _appointmentStatus,
              deductionLayout: _deductionLayout),
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      final base = 'payslip-${_monthName.toLowerCase()}-${widget.year}';

      if (kIsWeb || io.Platform.isAndroid || io.Platform.isIOS) {
        await FileSaver.instance.saveFile(
          name: base,
          bytes: pdfBytes,
          ext: 'pdf',
          mimeType: MimeType.pdf,
        );
      } else {
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save payslip PDF',
          fileName: '$base.pdf',
        );
        if (savePath == null) {
          _snack('Download canceled.');
          return;
        }
        await io.File(savePath).writeAsBytes(pdfBytes);
        _snack('Payslip saved to $savePath');
        return;
      }
      _snack('Payslip downloaded.');
    } catch (e) {
      debugPrint('Error saving PDF: $e');
      _snack("Couldn't save the PDF. Try again.");
    }
  }

  Future<void> _handlePrint() async {
    if (_payslipData == null) {
      _snack('No payslip data to print yet.');
      return;
    }
    try {
      final logoImage = await _loadLogoImage();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          final pdf = pw.Document();
          pdf.addPage(
            pw.Page(
              pageFormat: format.copyWith(
                marginTop: 20,
                marginBottom: 20,
                marginLeft: 20,
                marginRight: 20,
              ),
              build: (_) => buildPayslip(logoImage, _payslipData!, _monthName,
                  widget.year, _dateRange,
                  staffId: _staffId,
                  appointmentStatus: _appointmentStatus,
                  deductionLayout: _deductionLayout),
            ),
          );
          return pdf.save();
        },
      );
    } catch (e) {
      debugPrint('Error printing PDF: $e');
      _snack("Couldn't open the print dialog.");
    }
  }

  void _selectTab(int i) {
    HapticFeedback.selectionClick();
    setState(() {
      _tab = i;
      _showAll = false;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final p = PayslipPalette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: CupertinoTheme(
            data: CupertinoTheme.of(context).copyWith(primaryColor: p.tint),
            child: LayoutBuilder(
              builder: (context, c) {
                final pad = c.maxWidth >= 600 ? 28.0 : 20.0;
                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics()),
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      automaticallyImplyLeading: false,
                      backgroundColor: p.bg.withOpacity(0.9),
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      toolbarHeight: 72,
                      centerTitle: true,
                      leadingWidth: 76,
                      leading: Navigator.of(context).canPop()
                          ? const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: _RoundBackButton(),
                        ),
                      )
                          : null,
                      title: Text('${widget.month} ${widget.year}',
                          style: pText(17, FontWeight.w600, p.ink)),
                    ),
                    ..._content(p, pad),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(PayslipPalette p, double pad) {
    if (_loading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CupertinoActivityIndicator(radius: 14)),
        ),
      ];
    }
    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _MessageState(
            icon: CupertinoIcons.wifi_exclamationmark,
            title: "Couldn't load this payslip",
            message: _error!,
            actionLabel: 'Try again',
            onAction: _fetchPayslipData,
          ),
        ),
      ];
    }
    if (_payslipData == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _MessageState(
            icon: CupertinoIcons.doc_text_search,
            title: 'No payslip for ${widget.month} ${widget.year}',
            message: 'Payslips appear here once payroll has released them.',
            actionLabel: 'Refresh',
            onAction: _fetchPayslipData,
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, 4, pad, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _card(),
              const SizedBox(height: 16),
              _actions(p),
              const SizedBox(height: 28),
              _ringsPanel(p),
              const SizedBox(height: 28),
              _usageCard(p),
            ],
          ),
        ),
      ),
    ];
  }

  // ── Sections ───────────────────────────────────────────────────────────────
  Widget _card() {
    final id = _staffId;
    return _TiltCard(
      child: LandbankNetPayCard(
        amount: payPeso(_net),
        visible: _showNetIncome,
        onToggle: () {
          HapticFeedback.lightImpact(); // same moment as the visual change
          setState(() => _showNetIncome = !_showNetIncome);
        },
        period:
        '${widget.month.length > 3 ? widget.month.substring(0, 3) : widget.month} ${widget.year}',
        staffTail: id.length >= 4 ? id.substring(id.length - 4) : id,
      ),
    );
  }

  Widget _actions(PayslipPalette p) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: CupertinoIcons.arrow_down_to_line,
          label: 'Download',
          filled: false,
          onTap: _handleDownload,
        ),
        const SizedBox(width: 10),
        _ActionButton(
          icon: CupertinoIcons.printer,
          label: 'Print',
          filled: false,
          onTap: _handlePrint,
        ),
      ],
    );
  }

  Widget _summaryGroup(PayslipPalette p) {
    final gross = _gross;

    Widget row(String label, String value,
        {Color? color, bool bold = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: pText(17, bold ? FontWeight.w600 : FontWeight.w400, p.ink)),
            ),
            const SizedBox(width: 12),
            Text(value,
                style: pText(17, bold ? FontWeight.w700 : FontWeight.w500,
                    color ?? p.ink)),
          ],
        ),
      );
    }

    return PayslipGroup(
      children: [
        row('Before deductions', payPeso(gross)),
        row('Deductions', '−${payPeso(_totalDeductions)}', color: p.red),
        row('Take-home', payPeso(_net), bold: true),
      ],
    );
  }

  Widget _sectionTitle(PayslipPalette p, String text, {Widget? trailing}) =>
      Padding(
        padding: const EdgeInsets.only(left: 4, right: 4, bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(text, style: pText(18, FontWeight.w600, p.sub)),
            ),
            if (trailing != null) trailing,
          ],
        ),
      );

  BoxDecoration _cardDecoration(PayslipPalette p) => BoxDecoration(
    color: p.cell,
    borderRadius: BorderRadius.circular(18),
  );

  // ── Where your pay went: graph left, legend right ──────────────────────────
  Widget _ringsPanel(PayslipPalette p) {
    final cats = [_catTotal(0), _catTotal(1), _catTotal(2)];
    final gross = _gross;
    double frac(int i) => gross > 0 ? cats[i] / gross : 0;
    final kept = gross > 0 ? _net / gross * 100 : 0.0;

    Widget rings(double size) => Semantics(
      label:
      'Take-home is ${kept.round()} percent of your pay before deductions',
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          key: ValueKey('rings-${widget.month}-${widget.year}-$gross-$size'),
          tween: Tween(begin: 0, end: 1),
          duration: payMotion(context, 1000),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => CustomPaint(
            painter: _RingsPainter(
              fractions: [frac(0), frac(1), frac(2)],
              colors: p.categories,
              track: p.tile,
              progress: t,
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size * 0.26),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(kept * t).round()}%',
                          style: pText(22, FontWeight.w700, p.ink)),
                      Text('kept',
                          style: pText(13, FontWeight.w400, p.sub)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Widget legendRow(int i) {
      final pct = gross > 0 ? cats[i] / gross * 100 : 0;
      return PayslipPressable(
        onTap: null,
        semanticLabel:
        '${PayslipPalette.categoryNames[i]}, ${payPeso(cats[i])}',
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: p.categories[i], shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(PayslipPalette.categoryNames[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: pText(14, FontWeight.w500, p.ink)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                  text: payPeso(cats[i]),
                                  style: pText(13, FontWeight.w600, p.ink)),
                              TextSpan(
                                  text: '  ${pct.toStringAsFixed(0)}%',
                                  style: pText(13, FontWeight.w400, p.sub)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(p, 'Where your pay went'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(p),
          child: LayoutBuilder(
            builder: (context, box) {
              final size = box.maxWidth < 380 ? 124.0 : 168.0;
              return Row(
                children: [
                  rings(size),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [for (var i = 0; i < 3; i++) legendRow(i)],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ── One container, like Battery's "Daily Usage": headline, two numbers,
  //    horizontal bars with an average line, then the deductions list ───────
  Widget _usageCard(PayslipPalette p) {
    final first = _first, second = _second;
    final diff = second - first;
    final avg = (first + second) / 2;
    final maxV = math.max(math.max(first, second), 1.0);

    // Highlight is DSWD red; the other bars stay light / dark grey.
    const hiTop = Color(0xFFE5424F);
    const hi = Color(0xFFCE1126);
    final barFill = p.dark ? const Color(0xFF636366) : const Color(0xFFB4B4B8);
    final barTrack = p.dark ? const Color(0xFF2C2C2E) : const Color(0xFFE3E3E6);

    final headline = diff.abs() < 0.005
        ? 'Both cut-offs paid the same amount.'
        : diff > 0
        ? 'Your 2nd cut-off paid ${payPeso(diff)} more than your 1st.'
        : 'Your 2nd cut-off paid ${payPeso(-diff)} less than your 1st.';

    Widget hairline({double indent = 0}) => Container(
      height: 0.5,
      margin: EdgeInsets.only(left: indent),
      color: p.line,
    );

    Widget stat(String label, double v, Color color) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: pText(15, FontWeight.w600, color)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: '₱', style: pText(15, FontWeight.w600, color)),
                TextSpan(
                    text: payPeso(v).substring(1),
                    style: pText(24, FontWeight.w600, color, ls: -0.4)),
              ]),
            ),
          ),
        ],
      ),
    );

    // Horizontal bars: lighter bar = highest cut-off, darker bar = this cut-off.
    Widget chart() {
      return LayoutBuilder(builder: (context, box) {
        const labelW = 34.0, gap = 12.0, rowH = 30.0, topH = 26.0, barH = 24.0;
        final barW = math.max(40.0, box.maxWidth - labelW - gap);
        final avgX = labelW + gap + barW * (avg / maxV);
        final labelLeft =
        (avgX - 40).clamp(0.0, math.max(0.0, box.maxWidth - 80)).toDouble();

        Widget row(String label, double v, bool highlight) => SizedBox(
          height: rowH,
          child: Row(
            children: [
              SizedBox(
                width: labelW,
                child: Text(label,
                    style: pText(15, FontWeight.w600,
                        highlight ? p.red : p.sub)),
              ),
              const SizedBox(width: gap),
              SizedBox(
                width: barW,
                height: barH,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: barTrack,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      key: ValueKey('hbar-$label-${widget.month}-$v'),
                      tween: Tween(begin: 0, end: v / maxV),
                      duration: payMotion(context, 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, f, _) => Container(
                        width: math.max(8.0, barW * f),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: highlight ? null : barFill,
                          gradient: highlight
                              ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [hiTop, hi],
                          )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        return Semantics(
          label:
          '1st cut-off ${payPeso(first)}, 2nd cut-off ${payPeso(second)}, average ${payPeso(avg)}',
          child: SizedBox(
            height: topH + rowH * 2 + 12,
            child: Stack(
              children: [
                Positioned(
                  top: topH,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      row('1st', first, false),
                      const SizedBox(height: 12),
                      row('2nd', second, true),
                    ],
                  ),
                ),
                Positioned(
                  left: avgX - 1.25,
                  top: topH - 4,
                  bottom: 0,
                  width: 2.5,
                  child: ColoredBox(color: p.sub.withOpacity(0.4)),
                ),
                Positioned(
                  left: labelLeft,
                  width: 80,
                  top: 0,
                  child: Center(
                    child: Text('Average',
                        style: pText(15, FontWeight.w600, p.sub)),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }

    Widget legendDot(Color c, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: pText(14, FontWeight.w400, p.sub)),
      ],
    );

    // ── deductions list (inside the same container, no heading or filter) ──
    final rows = _items;
    final gross = _gross;
    const limit = 5;
    final canExpand = rows.length > limit;
    final shown = (!_showAll && canExpand) ? rows.take(limit).toList() : rows;

    final items = <Widget>[];
    for (var i = 0; i < shown.length; i++) {
      items.add(_DeductionRow(
        item: shown[i],
        pctOfPay: gross > 0 ? shown[i].amount / gross * 100 : 0,
      ));
      if (i != shown.length - 1) items.add(hairline(indent: 54));
    }

    final Widget list = rows.isEmpty
        ? Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: SizedBox(
        width: double.infinity,
        child: Text('No deductions this month.',
            textAlign: TextAlign.center,
            style: pText(15, FontWeight.w400, p.sub)),
      ),
    )
        : Column(children: items);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(p, 'Pay per Cut-off'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          decoration: BoxDecoration(
            color: p.cell,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(headline,
                  style: pText(17, FontWeight.w600, p.ink, h: 1.3)),
              const SizedBox(height: 16),
              hairline(),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  stat('1st Cut-off', first, p.sub),
                  const SizedBox(width: 12),
                  stat('2nd Cut-off', second, p.red),
                ],
              ),
              const SizedBox(height: 18),
              chart(),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  legendDot(barTrack, 'Highest cut-off'),
                  legendDot(barFill, 'Cut-off pay'),
                ],
              ),
              const SizedBox(height: 22),
              hairline(),
              AnimatedSize(
                duration: payMotion(context, 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: payMotion(context, 220),
                  child: KeyedSubtree(
                    key: ValueKey(_showAll),
                    child: list,
                  ),
                ),
              ),
              if (canExpand) ...[
                hairline(),
                PayslipPressable(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _showAll = !_showAll);
                  },
                  semanticLabel: _showAll
                      ? 'Show fewer deductions'
                      : 'View all ${rows.length} deductions',
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                              _showAll
                                  ? 'Show Fewer'
                                  : 'View All Deductions (${rows.length})',
                              style: pText(17, FontWeight.w400, p.ink)),
                        ),
                        Icon(
                            _showAll
                                ? CupertinoIcons.chevron_up
                                : CupertinoIcons.chevron_down,
                            size: 15,
                            color: p.sub.withOpacity(0.7)),
                      ],
                    ),
                  ),
                ),
              ] else
                const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────
/// Round, white back button.
class _RoundBackButton extends StatelessWidget {
  const _RoundBackButton();

  @override
  Widget build(BuildContext context) {
    final p = PayslipPalette.of(context);
    return Semantics(
      button: true,
      label: 'Back',
      excludeSemantics: true,
      child: SpringPress(
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: p.cell,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(p.dark ? 0.4 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(CupertinoIcons.chevron_left, size: 22, color: p.ink),
        ),
      ),
    );
  }
}

/// Small rounded button. White with dark text; `filled` makes it dark.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = PayslipPalette.of(context);
    final fg = filled ? (p.dark ? Colors.black : Colors.white) : p.ink;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SpringPress(
        onTap: onTap,
        // Extra padding keeps a 44pt touch area around the smaller button.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Container(
            constraints: const BoxConstraints(minHeight: 38),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled ? p.ink : p.cell,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: pText(15, FontWeight.w600, fg)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeductionRow extends StatelessWidget {
  final _Deduction item;
  final double pctOfPay;
  const _DeductionRow({required this.item, required this.pctOfPay});

  @override
  Widget build(BuildContext context) {
    final p = PayslipPalette.of(context);
    final imagePath = DeductionIcons.assetFor(item.name);
    // Icons now come from a URL. Check the path only, so a "?v=2" query
    // string on an .svg link still counts as SVG.
    final isSvg = Uri.tryParse(imagePath)?.path.toLowerCase().endsWith('.svg') ??
        false;

    // Dark fallback color, since the tile behind it is now white.
    const fallbackColor = Color(0xFF2C2C2E);
    // Absences, tardiness and adjustments have no agency logo, so give them
    // a meaningful icon instead of the plain document.
    final IconData fallbackData;
    switch (item.name) {
      case 'Absences':
        fallbackData = CupertinoIcons.calendar_badge_minus;
        break;
      case 'Tardiness':
      case 'Premium late':
        fallbackData = CupertinoIcons.clock;
        break;
      case 'Underpayment':
        fallbackData = CupertinoIcons.plus_circle;
        break;
      case 'Overpayment':
      case 'Disallowance':
      case 'Refund':
      case 'Unearned pay':
        fallbackData = CupertinoIcons.minus_circle;
        break;
      default:
        fallbackData = CupertinoIcons.doc_text;
    }
    final fallbackIcon = Icon(fallbackData, size: 22, color: fallbackColor);

    Widget icon;
    if (imagePath.isEmpty) {
      icon = fallbackIcon;
    } else if (isSvg) {
      icon = SvgPicture.network(
        imagePath,
        width: 24,
        height: 24,
        placeholderBuilder: (_) => const SizedBox(
          width: 16,
          height: 16,
          child: CupertinoActivityIndicator(radius: 7),
        ),
      );
    } else {
      icon = Image.network(
        imagePath,
        width: 30,
        height: 30,
        fit: BoxFit.contain,
        // On Flutter web, fall back to a plain <img> tag when the server
        // doesn't send CORS headers. Needs Flutter 3.22 or newer.
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const SizedBox(
          width: 16,
          height: 16,
          child: CupertinoActivityIndicator(radius: 7),
        ),
        errorBuilder: (_, __, ___) => fallbackIcon,
      );
    }

    return Semantics(
      label:
      '${item.name}, ${item.group}, ${item.credit ? 'plus' : 'minus'} ${payPeso(item.amount)}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                // Hairline border so the white tile stays visible on a
                // white card in light mode.
                border: Border.all(
                  color: p.dark
                      ? Colors.transparent
                      : Colors.black.withOpacity(0.08),
                  width: 0.5,
                ),
              ),
              child: icon,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: pText(13.5, FontWeight.w700, p.ink, h: 1.2)),
                  const SizedBox(height: 2),
                  Text(item.group,
                      style: pText(11.5, FontWeight.w400, p.sub)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('${item.credit ? '+' : '−'}${payPeso(item.amount)}',
                style: pText(
                    15,
                    FontWeight.w400,
                    item.credit ? const Color(0xFF1A7F4B) : p.sub)),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final p = PayslipPalette.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: p.sub),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: pText(20, FontWeight.w600, p.ink)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: pText(15, FontWeight.w400, p.sub, h: 1.4)),
              const SizedBox(height: 20),
              SizedBox(
                width: 180,
                child: _ActionButton(
                  icon: CupertinoIcons.refresh,
                  label: actionLabel,
                  filled: true,
                  onTap: onAction,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Net-pay card styled after the LANDBANK ATM card: green body, thin
/// yellow-green leaf outline, overlapping leaf shapes bottom-right, silver EMV
/// chip, white rounded sans type.
///
/// Drop-in replacement for `_NetPayCard` (same parameters). It draws the
/// "LANDBANK" wordmark as text. To use the real logo, add your licensed asset
/// to pubspec.yaml and pass [logoAsset].
class LandbankNetPayCard extends StatelessWidget {
  final String amount;
  final bool visible;
  final VoidCallback onToggle;
  final String period;
  final String staffTail;
  final String? logoAsset;

  const LandbankNetPayCard({
    super.key,
    required this.amount,
    required this.visible,
    required this.onToggle,
    required this.period,
    required this.staffTail,
    this.logoAsset,
  });

  static const _greenDeep = Color(0xFF148A3A);
  static const _greenMid = Color(0xFF2BA244);
  static const _greenLight = Color(0xFF4CB848);

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    final shadow = [
      Shadow(color: Colors.black.withOpacity(.18), blurRadius: 3, offset: const Offset(0, 1)),
    ];
    TextStyle t(double size, FontWeight w, {double ls = 0, double o = 1}) =>
        pText(size, w, white.withOpacity(o), ls: ls).copyWith(shadows: shadow);

    return MediaQuery(
      // Fixed-size object like a physical card: cap text scaling at 120%.
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: AspectRatio(
            aspectRatio: 1.586, // ISO/IEC 7810 ID-1
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _greenDeep.withOpacity(.35),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_greenDeep, _greenMid, _greenLight],
                          stops: [0, .55, 1],
                        ),
                      ),
                    ),
                    CustomPaint(painter: _LandbankArtPainter()),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 8, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (logoAsset != null)
                                  Image.asset(
                                    logoAsset!,
                                    height: 24,
                                    errorBuilder: (_, __, ___) => _wordmark(t),
                                  )
                                else
                                  _wordmark(t),
                                const Spacer(),
                                Text('Payroll Card', style: t(12, FontWeight.w500)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const _SilverChip(),
                          const Spacer(),
                          Text('NET PAY', style: t(12, FontWeight.w600, ls: .8)),
                          Row(
                            children: [
                              Flexible(
                                child: Semantics(
                                  label: visible ? 'Net pay $amount' : 'Net pay hidden',
                                  excludeSemantics: true,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: AnimatedSwitcher(
                                      duration: payMotion(context, 220),
                                      child: Text(
                                        visible ? amount : '₱ ••••••',
                                        key: ValueKey(visible),
                                        style: t(27, FontWeight.w700, ls: -.4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Semantics(
                                button: true,
                                label: visible ? 'Hide net pay' : 'Show net pay',
                                excludeSemantics: true,
                                child: GestureDetector(
                                  onTap: onToggle,
                                  behavior: HitTestBehavior.opaque,
                                  child: SizedBox(
                                    width: 44,
                                    height: 36,
                                    child: Center(
                                      child: Icon(
                                        visible ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                                        color: white,
                                        size: 21,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'STAFF ID •••• $staffTail     PAY PERIOD ${period.toUpperCase()}',
                                style: t(11, FontWeight.w500, ls: .6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _wordmark(TextStyle Function(double, FontWeight, {double ls, double o}) t) =>
      Text('LANDBANK', style: t(21, FontWeight.w800, ls: .6));
}

/// Light silver EMV chip, like the one on the reference card.
class _SilverChip extends StatelessWidget {
  const _SilverChip();

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 33,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(6),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF4F6F4), Color(0xFFCDD3CF), Color(0xFFE9ECE9)],
      ),
      border: Border.all(color: Colors.white.withOpacity(.6), width: .6),
    ),
    child: CustomPaint(painter: _ChipPainter()),
  );
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .9
      ..color = const Color(0xFF8C958F).withOpacity(.75);
    final w = s.width, h = s.height;
    // contact pads
    canvas.drawLine(Offset(0, h * .34), Offset(w * .36, h * .34), p);
    canvas.drawLine(Offset(0, h * .66), Offset(w * .36, h * .66), p);
    canvas.drawLine(Offset(w * .64, h * .34), Offset(w, h * .34), p);
    canvas.drawLine(Offset(w * .64, h * .66), Offset(w, h * .66), p);
    canvas.drawLine(Offset(w * .36, 0), Offset(w * .36, h), p);
    canvas.drawLine(Offset(w * .64, 0), Offset(w * .64, h), p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .36, h * .34, w * .28, h * .32),
        const Radius.circular(3),
      ),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Leaf outline + overlapping yellow-green leaves + soft sheen.
class _LandbankArtPainter extends CustomPainter {
  static const _lime = Color(0xFFC9DA3A);
  static const _yellowGreen = Color(0xFFA6CF3A);
  static const _leafGreen = Color(0xFF86C440);

  void _leaf(Canvas c, Offset o, double len, double wid, double angle, Paint p) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(angle);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(len * .5, -wid, len, 0)
      ..quadraticBezierTo(len * .5, wid, 0, 0);
    c.drawPath(path, p);
    c.restore();
  }

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;

    // Sheen, top-left.
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.7, -.9),
          radius: 1.1,
          colors: [Colors.white.withOpacity(.16), Colors.white.withOpacity(0)],
        ).createShader(Offset.zero & s),
    );

    // Overlapping leaves, bottom-right.
    _leaf(canvas, Offset(w * .36, h * 1.04), w * .66, h * .26, -.18,
        Paint()..color = _leafGreen.withOpacity(.45));
    _leaf(canvas, Offset(w * .50, h * 1.0), w * .62, h * .44, -.55,
        Paint()..color = _yellowGreen.withOpacity(.55));
    _leaf(canvas, Offset(w * .64, h * 1.02), w * .52, h * .36, -.95,
        Paint()..color = _lime.withOpacity(.55));

    // Thin leaf outline sweeping from bottom-left over the top.
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = _lime.withOpacity(.9);
    final outline = Path()
      ..moveTo(0, h * .84)
      ..cubicTo(w * .10, h * .30, w * .42, h * .02, w * .80, h * .03)
      ..cubicTo(w * .78, h * .24, w * .86, h * .48, w * .80, h * .66);
    canvas.drawPath(outline, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tilt. The card follows your finger (or the mouse) 1:1 and springs back on
// release, carrying the release velocity. Listens to raw pointer events so it
// never blocks scrolling; a touch that moves mostly vertically is treated as a
// scroll and the card lets go.
// ─────────────────────────────────────────────────────────────────────────────
class _TiltCard extends StatefulWidget {
  final Widget child;
  const _TiltCard({required this.child});

  @override
  State<_TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<_TiltCard> with TickerProviderStateMixin {
  late final AnimationController _x = AnimationController.unbounded(vsync: this);
  late final AnimationController _y = AnimationController.unbounded(vsync: this);
  Offset? _last;
  Duration? _lastT;
  Offset _vel = Offset.zero;
  Offset? _downAt;
  bool _scrolling = false;

  bool get _off => MediaQuery.of(context).disableAnimations;

  void _track(PointerEvent e) {
    final size = context.size;
    if (_off || _scrolling || size == null || size.isEmpty) return;
    final nx = (e.localPosition.dx / size.width * 2 - 1).clamp(-1.0, 1.0).toDouble();
    final ny = (e.localPosition.dy / size.height * 2 - 1).clamp(-1.0, 1.0).toDouble();
    if (_last != null && _lastT != null) {
      final dt = (e.timeStamp - _lastT!).inMicroseconds / 1e6;
      if (dt > 0) {
        _vel = Offset((nx - _last!.dx) / dt, (ny - _last!.dy) / dt);
      }
    }
    _last = Offset(nx, ny);
    _lastT = e.timeStamp;
    _x.stop();
    _y.stop();
    _x.value = nx;
    _y.value = ny;
  }

  void _release() {
    final spring = paySpring(response: 0.45, damping: 0.8);
    _x.animateWith(SpringSimulation(spring, _x.value, 0, _vel.dx));
    _y.animateWith(SpringSimulation(spring, _y.value, 0, _vel.dy));
    _last = null;
    _lastT = null;
    _vel = Offset.zero;
  }

  void _down(PointerDownEvent e) {
    _downAt = e.position;
    _scrolling = false;
    _track(e);
  }

  void _move(PointerMoveEvent e) {
    if (e.kind == PointerDeviceKind.touch &&
        !_scrolling &&
        _downAt != null &&
        (e.position - _downAt!).dy.abs() > 12) {
      _scrolling = true;
      _release();
      return;
    }
    _track(e);
  }

  void _up(PointerEvent e) {
    _downAt = null;
    _scrolling = false;
    _release();
  }

  @override
  void dispose() {
    _x.dispose();
    _y.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onExit: (_) => _release(),
      child: Listener(
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerHover: _track,
        onPointerUp: _up,
        onPointerCancel: _up,
        child: AnimatedBuilder(
          animation: Listenable.merge([_x, _y]),
          builder: (context, child) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(-_y.value * 0.16)
              ..rotateY(_x.value * 0.16),
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rings: one ring per deduction group, each filled to its share of pay before
// deductions. What is left unfilled across all rings is what you take home.
// ─────────────────────────────────────────────────────────────────────────────
class _RingsPainter extends CustomPainter {
  final List<double> fractions;
  final List<Color> colors;
  final Color track;
  final double progress;

  _RingsPainter({
    required this.fractions,
    required this.colors,
    required this.track,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.083;
    final gap = size.width * 0.03;
    final center = size.center(Offset.zero);
    var radius = size.width / 2 - stroke / 2;

    for (var i = 0; i < fractions.length; i++) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = track,
      );
      final f = fractions[i];
      if (f > 0) {
        final sweep = math.max(f, 0.012) * math.pi * 2 * progress;
        canvas.drawArc(
          rect,
          -math.pi / 2,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = stroke
            ..color = colors[i],
        );
      }
      radius -= stroke + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) =>
      old.progress != progress ||
          old.track != track ||
          !listEquals(old.fractions, fractions) ||
          !listEquals(old.colors, colors);
}