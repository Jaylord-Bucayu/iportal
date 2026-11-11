import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const _blue = PdfColor.fromInt(0xFF2E3192);
const _gray = PdfColor.fromInt(0xFFDDDDDD);
const _red = PdfColor.fromInt(0xFFE00000);

final _fmt = NumberFormat('#,##0.00');

/// Deduction list used when the Settings request returns nothing. It is the
/// full list printed on the reference payslip PDF, in the same order. When
/// Settings load, they replace it.
const _defaultDeductionNames = [
  'PHIC', 'PAG-IBIG CONT', 'PAG-IBIG MP2', 'SSS CONT', 'SWEAP CONT', 'MBA CONT',
  'PAG-IBIG MPL', 'PAG-IBIG CL', 'PAG-IBIG REL', 'PAG-IBIG SL',
  'GSIS CONSO LOAN', 'GSIS EMERGENCY LOAN', 'GSIS PL REG', 'GSIS REL',
  'GSIS OPT', 'GSIS GFAL', 'GSIS MPL', 'GSIS MPL-LITE', 'COA SL', 'LBP SL',
  'SWEAP LOAN', 'MBA LOAN', 'GSIS LRP', 'PAG - IBIG SL', 'L&R', 'TAX',
  'SWEAP FA', 'OTHERS', 'HMO', 'DW COA', 'PERA',
];

double _n(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('${v ?? ''}'.replaceAll(',', '')) ?? 0;
}

String _money(dynamic v) => _fmt.format(_n(v));
String _moneyOrDash(dynamic v) => _n(v) == 0 ? '-' : _fmt.format(_n(v));

/// One payslip page, laid out like the web (Vue) payslip:
/// letterhead + logo, employee block (name, Staff ID, designation, salary),
/// red net pay, EARNINGS / DEDUCTIONS tables in Courier, totals, quincena net
/// pay, signatory and remarks.
///
/// [staffId] is printed under the employee name. If you leave it empty, the
/// builder falls back to `staff_id` in [d]. [signature] is optional.
pw.Widget buildPayslip(
    pw.MemoryImage logo,
    Map<String, dynamic> d,
    String monthName,
    int year,
    String dateRange, {
      String staffId = '',
      String appointmentStatus = '',
      Map<String, List<String>> deductionLayout = const {},
      pw.MemoryImage? signature,
    }) {
  // ── Data ───────────────────────────────────────────────────────────────
  const categories = ['contributions', 'loans', 'others'];
  final deductions = <MapEntry<String, double>>[];
  final byCat = <String, List<MapEntry<String, double>>>{
    for (final c in categories) c: [],
  };
  for (final key in categories) {
    final raw = d['deductions']?[key];
    if (raw is List) {
      for (final e in raw.whereType<Map>()) {
        final entry = MapEntry('${e['deduction_name'] ?? ''}', _n(e['amount']));
        deductions.add(entry);
        byCat[key]!.add(entry);
      }
    }
  }

  // ── Earnings ───────────────────────────────────────────────────────────
  final earnings = <MapEntry<String, String>>[
    MapEntry('Basic Salary', _moneyOrDash(d['sg_amount'])),
    MapEntry('Allowance/ADCOM', _moneyOrDash(d['pera_premium'])),
  ];
  if (_n(d['underpayment']) != 0) {
    earnings.add(MapEntry('Underpayment', _money(d['underpayment'])));
  }
  earnings.add(const MapEntry('NBC', '0.00'));

  // ── Other deductions: attendance and adjustments ───────────────────────
  // Same rule as the web payslip: Permanent and Contractual staff have no
  // attendance rows, unless they actually have an amount.
  final hideAttendance = const ['PERMANENT', 'CONTRACTUAL']
      .contains(appointmentStatus.trim().toUpperCase());
  const attendanceItems = [
    ['Absences', 'absences_amount'],
    ['Tardiness', 'late_amount'],
    ['Premium late', 'premium_late'],
  ];
  const adjustmentItems = [
    ['Overpayment', 'overpayment'],
    ['Disallowance', 'disallowances'],
    ['Refund', 'refund'],
    ['Unearned pay', 'unearned_pay'],
  ];
  final attendanceRows = <MapEntry<String, String>>[
    for (final it in attendanceItems)
      if (!hideAttendance || _n(d[it[1]]) != 0)
        MapEntry(it[0], _moneyOrDash(d[it[1]])),
  ];
  // Adjustments only print when there is an amount.
  final adjustmentRows = <MapEntry<String, String>>[
    for (final it in adjustmentItems)
      if (_n(d[it[1]]) != 0) MapEntry(it[0], _money(d[it[1]])),
  ];

  // ── Totals ─────────────────────────────────────────────────────────────
  // Earnings: salary + allowance (+ underpayment). Deductions: absences,
  // tardiness, premium late and the adjustments, plus the Settings
  // deductions (contributions, loans, others).
  final totalEarned =
      _n(d['sg_amount']) + _n(d['pera_premium']) + _n(d['underpayment']);
  final settingsDeducted = d['total_deductions'] != null
      ? _n(d['total_deductions'])
      : deductions.fold<double>(0, (a, b) => a + b.value);
  final otherDeducted = [...attendanceItems, ...adjustmentItems]
      .fold<double>(0, (a, it) => a + _n(d[it[1]]));
  final totalDeducted = settingsDeducted + otherDeducted;

  final id = staffId.isNotEmpty ? staffId : '${d['staff_id'] ?? ''}';

  // "NOVEMBER 1 - 30, 2026"
  var monthIdx = DateTime.now().month;
  try {
    monthIdx = DateFormat.MMMM().parse(monthName).month;
  } catch (_) {}
  final lastDay = DateTime(year, monthIdx + 1, 0).day;
  final period = '${monthName.toUpperCase()} 1 - $lastDay, $year';

  // ── Auto-scale so the whole payslip always fits on one page ───────────
  // Same as the web payslip: every deduction in Settings for this appointment
  // status, contributions then loans then others, each matched only inside its
  // own group, with a dash where the staff has none. Anything the staff has
  // that Settings does not list is added at the end so no amount is dropped.
  // With no settings at all, it lists just the staff's own deductions.
  String key(String s) => s.trim().toUpperCase();
  final deductionRows = <MapEntry<String, String>>[...attendanceRows];
  // With Settings: match inside each group. Without: use the built-in list and
  // match it against all of the staff's deductions.
  final hasLayout =
  categories.any((c) => (deductionLayout[c] ?? const <String>[]).isNotEmpty);
  final groups = hasLayout ? categories : const ['all'];
  for (final cat in groups) {
    final mine = hasLayout ? byCat[cat]! : deductions;
    final used = <int>{};
    final names = hasLayout
        ? (deductionLayout[cat] ?? const <String>[])
        : _defaultDeductionNames;
    for (final name in names) {
      final i = mine.indexWhere((e) => key(e.key) == key(name));
      if (i >= 0) used.add(i);
      deductionRows.add(MapEntry(name.isEmpty ? '-' : name, i >= 0 ? _moneyOrDash(mine[i].value) : '-'));
    }
    for (var i = 0; i < mine.length; i++) {
      if (!used.contains(i)) {
        deductionRows.add(MapEntry(mine[i].key, _moneyOrDash(mine[i].value)));
      }
    }
  }
  deductionRows.addAll(adjustmentRows);

  final rowCount =
  deductionRows.length > earnings.length ? deductionRows.length : earnings.length;
  const fixedHeight = 374.0; // letterhead, employee block, totals, signature, remarks
  const rowHeight = 12.6;
  const available = 740.0; // safe for A4 and Letter once page margins are removed
  final k = (available / (fixedHeight + rowCount * rowHeight)).clamp(0.35, 1.0).toDouble();
  double f(double v) => v * k;

  // ── Styles ─────────────────────────────────────────────────────────────
  final reg = pw.Font.helvetica();
  final bold = pw.Font.helveticaBold();
  final mono = pw.Font.courier();

  pw.TextStyle t(double size,
      {bool b = false, PdfColor? color, pw.Font? font}) =>
      pw.TextStyle(
        font: font ?? (b ? bold : reg),
        fontSize: f(size),
        color: color ?? PdfColors.black,
      );

  // ── Pieces ─────────────────────────────────────────────────────────────
  // "Label: value" with only the value underlined.
  pw.Widget detailLine(String label, String value,
      {bool isBold = false, double bottom = 4}) =>
      pw.Padding(
        padding: pw.EdgeInsets.only(bottom: f(bottom)),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(label, style: t(9)),
            pw.SizedBox(width: f(4)),
            pw.Container(
              padding: pw.EdgeInsets.only(bottom: f(0.6)),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(width: 1.2, color: PdfColors.black),
                ),
              ),
              child: pw.Text(value, style: t(9, b: isBold)),
            ),
          ],
        ),
      );

  pw.Widget sectionHeader(String title) => pw.Container(
    width: double.infinity,
    color: _gray,
    padding: pw.EdgeInsets.fromLTRB(4, f(3), 0, f(3)),
    margin: pw.EdgeInsets.only(bottom: f(3)),
    child: pw.Text(title, style: t(10, color: _blue)),
  );

  pw.Widget amountRows(List<MapEntry<String, String>> rows) => pw.Column(
    children: [
      for (final r in rows)
        pw.Padding(
          padding: pw.EdgeInsets.symmetric(vertical: f(1)),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.only(left: f(4)),
                child: pw.Text(r.key, style: t(9, font: mono)),
              ),
              pw.Text(r.value, style: t(9, font: mono)),
            ],
          ),
        ),
    ],
  );

  pw.Widget rule() => pw.Container(
    height: 0.8,
    color: PdfColors.black,
    margin: pw.EdgeInsets.only(top: f(4), bottom: f(3)),
  );

  // ── Page ───────────────────────────────────────────────────────────────
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      // Letterhead
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Department of Social Welfare and Development Field Office II',
                    style: t(10)),
                pw.Text(
                    '#3 Dalan na Pagayaya, Regional Government Center, Carig, Tuguegarao City',
                    style: t(8)),
                pw.SizedBox(height: 3),
                pw.Text('EMPLOYEE $period PAYSLIP',
                    style: t(12.5, b: true, color: _blue)),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.SizedBox(
            width: f(130),
            height: f(55),
            child: pw.Image(logo, fit: pw.BoxFit.contain, alignment: pw.Alignment.topRight),
          ),
        ],
      ),
      pw.SizedBox(height: f(22)),

      // Employee block + net pay
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                detailLine('Employee:', '${d['staff_name'] ?? ''}'.toUpperCase(),
                    isBold: true),
                // Staff ID directly below the employee name
                detailLine('Staff ID:', id),
                detailLine('Designation:', '${d['position_name'] ?? ''}'.toUpperCase()),
                detailLine('Salary:', _money(d['sg_amount']), bottom: 0),
              ],
            ),
          ),
          pw.SizedBox(
            width: 200,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Employee Net Pay', style: t(12)),
                pw.SizedBox(height: f(5)),
                pw.Text(_money(d['net_amount']), style: t(14, b: true, color: _red)),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: f(24)),

      // Earnings / Deductions
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(children: [
              sectionHeader('EARNINGS'),
              amountRows(earnings),
            ]),
          ),
          pw.SizedBox(width: 30),
          pw.Expanded(
            child: pw.Column(children: [
              sectionHeader('DEDUCTIONS'),
              amountRows(deductionRows),
            ]),
          ),
        ],
      ),
      rule(),

      // Totals
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL', style: t(10, b: true, color: _blue)),
                pw.Text(_money(totalEarned), style: t(10, b: true, color: _blue)),
              ],
            ),
          ),
          pw.SizedBox(width: 30),
          pw.Expanded(
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(_money(totalDeducted), style: t(10, b: true, color: _blue)),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: f(12)),

      // Quincena net pay
      pw.Padding(
        padding: const pw.EdgeInsets.only(left: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('First Net Pay: ${_money(d['first_quincena'])}',
                style: t(8, color: _blue)),
            pw.SizedBox(height: 2),
            pw.Text('Second Net Pay: ${_money(d['second_quincena'])}',
                style: t(8, color: _blue)),
          ],
        ),
      ),

      // Signatory
      pw.SizedBox(height: f(20)),
      pw.Row(
        children: [
          pw.Expanded(child: pw.SizedBox()),
          pw.SizedBox(
            width: 250,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Certified Correct:', style: t(8)),
                pw.SizedBox(
                  height: f(30),
                  child: signature == null
                      ? null
                      : pw.Center(child: pw.Image(signature, width: f(100), height: f(30))),
                ),
                pw.Container(height: 0.8, color: PdfColors.black),
                pw.SizedBox(height: 3),
                pw.Center(child: pw.Text('ROWENA S. ARUGAY', style: t(8, b: true))),
                pw.SizedBox(height: 3),
                pw.Center(
                  child: pw.Text('Supervising Administrative Officer/OIC-Chief, HRMDD',
                      style: t(7.5)),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 30),
        ],
      ),
      pw.SizedBox(height: f(18)),

      // Remarks
      pw.Padding(
        padding: const pw.EdgeInsets.only(left: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Remarks:', style: t(8)),
            pw.Text('Late counts: ${d['minutes_late'] ?? ''}', style: t(8)),
            pw.Text('Absent counts: ${d['absences_no_pay'] ?? ''}', style: t(8)),
            pw.Text('Unearned counts: 0.00', style: t(8)),
          ],
        ),
      ),
    ],
  );
}