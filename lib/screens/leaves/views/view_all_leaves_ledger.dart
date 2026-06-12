import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

// ════════════════════════════════════════════════════
// TOKENS — Meta / Facebook
// ════════════════════════════════════════════════════

class _M {
  static const bg          = Color(0xFFF0F2F5);
  static const surface     = Color(0xFFFFFFFF);
  static const ink         = Color(0xFF1C1E21);
  static const inkSub      = Color(0xFF65676B);
  static const inkHint     = Color(0xFFBCC0C4);
  static const line        = Color(0xFFE4E6EB);
  static const blue        = Color(0xFF1877F2);
  static const blueSurface = Color(0xFFE7F3FF);
  static const greenFg     = Color(0xFF1A7F37);
  static const greenSurface= Color(0xFFDFFBE8);
  static const redFg       = Color(0xFFC0392B);
  static const redSurface  = Color(0xFFFFF0EF);

  static const r8    = BorderRadius.all(Radius.circular(8));
  static const r12   = BorderRadius.all(Radius.circular(12));
  static const rFull = BorderRadius.all(Radius.circular(100));

  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 6,
      offset: const Offset(0, 1),
    ),
  ];
}

// ════════════════════════════════════════════════════
// MODEL
// ════════════════════════════════════════════════════

class _Entry {
  final int id;
  final String staffName, leaveType, source;
  final double previousBalance, changeAmount, newBalance, lwop;
  final int? lrId, dtrId;
  final DateTime reportMonth, createdAt;
  final String? remarks;

  const _Entry({
    required this.id,
    required this.staffName,
    required this.leaveType,
    required this.source,
    required this.previousBalance,
    required this.changeAmount,
    required this.newBalance,
    required this.lwop,
    this.lrId,
    this.dtrId,
    required this.reportMonth,
    required this.createdAt,
    this.remarks,
  });

  bool   get isCredit => changeAmount > 0;
  double get absAmt   => changeAmount.abs();

  String get amtLabel {
    final s = absAmt % 1 == 0
        ? absAmt.toInt().toString()
        : absAmt.toStringAsFixed(1);
    return '${isCredit ? '+' : '−'}$s d';
  }

  String get typeLabel => leaveType
      .split('_')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  bool get hasRemarks => remarks != null && remarks!.trim().isNotEmpty;
}

// ════════════════════════════════════════════════════
// SCREEN
// ════════════════════════════════════════════════════

class LeaveLedgerScreen extends StatefulWidget {
  final int staffId; // 👈 ADD THIS

  const LeaveLedgerScreen({super.key, required this.staffId});
  @override
  State<LeaveLedgerScreen> createState() => _ScreenState();
}

class _ScreenState extends State<LeaveLedgerScreen>
    with SingleTickerProviderStateMixin {
  String _tab = 'All';
  DateTimeRange? _range;
  bool _loading = true;
  List<_Entry> _all = [];
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fetch();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final r = await http
          .get(Uri.parse(
              'http://172.31.16.69/api/v1/leave-balances-history/${widget.staffId}'))
          .timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body)['data'] as List;
        _all = data
            .map((e) => _Entry(
                  id: e['id'],
                  staffName: e['staff_name'],
                  leaveType: e['leave_type'],
                  source: e['source'],
                  previousBalance:
                      double.tryParse(e['previous_balance'].toString()) ?? 0,
                  changeAmount:
                      double.tryParse(e['change_amount'].toString()) ?? 0,
                  newBalance:
                      double.tryParse(e['new_balance'].toString()) ?? 0,
                  lwop: double.tryParse(e['lwop'].toString()) ?? 0,
                  lrId: e['lr_id'],
                  dtrId: e['dtr_id'],
                  reportMonth: DateTime.parse(e['report_month']),
                  createdAt: DateTime.parse(e['created_at']),
                  remarks: e['remarks'],
                ))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        _all = [];
      }
    } catch (_) {
      _all = [];
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _ac.forward(from: 0);
      }
    }
  }

  List<_Entry> get _filtered => _all.where((e) {
        if (_tab == 'Credit' && !e.isCredit) return false;
        if (_tab == 'Debit' && e.isCredit) return false;
        if (_range != null) {
          final end = _range!.end
              .add(const Duration(hours: 23, minutes: 59, seconds: 59));
          if (e.createdAt.isBefore(_range!.start) ||
              e.createdAt.isAfter(end)) return false;
        }
        return true;
      }).toList();

  Map<String, List<_Entry>> _group(List<_Entry> list) {
    final m = <String, List<_Entry>>{};
    for (final e in list) {
      final k = DateFormat('MMMM yyyy').format(e.createdAt);
      m.putIfAbsent(k, () => []).add(e);
    }
    return m;
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final p = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _range,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _M.blue,
            onPrimary: Colors.white,
            surface: _M.surface,
            onSurface: _M.ink,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: _M.blue),
          ),
        ),
        child: child!,
      ),
    );
    if (p != null) setState(() => _range = p);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,

    ));

    final filtered = _filtered;
    final grouped  = _group(filtered);

    return Scaffold(
      backgroundColor: _M.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NavBar(onBack: () => Navigator.pop(context), onRefresh: _fetch),
            Expanded(
              child: _loading
                  ? const _Loader()
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // ── Filter ─────────────────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: _FilterCard(
                              tab: _tab,
                              range: _range,
                              onTab: (v) {
                                setState(() => _tab = v);
                                _ac.forward(from: 0);
                              },
                              onPickRange: _pickRange,
                              onClearRange: () =>
                                  setState(() => _range = null),
                            ),
                          ),
                        ),

                        if (filtered.isEmpty)
                          const SliverFillRemaining(child: _Empty())
                        else ...[
                          // ── Count ───────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                              child: Text(
                                '${filtered.length} transaction${filtered.length != 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _M.inkHint,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ),

                          // ── Groups ──────────────────
                          for (final entry in grouped.entries) ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 14, 16, 8),
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _M.inkSub,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (ctx, i) {
                                    final e     = entry.value[i];
                                    final delay = (i * 0.04).clamp(0.0, 0.4);
                                    final anim  = CurvedAnimation(
                                      parent: _ac,
                                      curve: Interval(
                                        delay,
                                        (delay + 0.5).clamp(0.0, 1.0),
                                        curve: Curves.easeOut,
                                      ),
                                    );
                                    return FadeTransition(
                                      opacity: anim,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.04),
                                          end: Offset.zero,
                                        ).animate(anim),
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: _Card(entry: e),
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: entry.value.length,
                                ),
                              ),
                            ),
                          ],

                          const SliverToBoxAdapter(child: SizedBox(height: 40)),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// NAV BAR
// ════════════════════════════════════════════════════

class _NavBar extends StatelessWidget {
  final VoidCallback onBack, onRefresh;
  const _NavBar({required this.onBack, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _M.surface,
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
      child: Row(
        children: [
          _IconBtn(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 2),
          const Expanded(
            child: Text(
              'Leave Ledger',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _M.ink,
                letterSpacing: -0.4,
              ),
            ),
          ),
          _IconBtn(icon: Icons.refresh_rounded, onTap: onRefresh),
        ],
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});
  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _down ? _M.line : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(widget.icon, size: 20, color: _M.ink),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// FILTER CARD
// ════════════════════════════════════════════════════

class _FilterCard extends StatelessWidget {
  final String tab;
  final DateTimeRange? range;
  final ValueChanged<String> onTab;
  final VoidCallback onPickRange, onClearRange;

  const _FilterCard({
    required this.tab,
    required this.range,
    required this.onTab,
    required this.onPickRange,
    required this.onClearRange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A), // dark black
            Color(0xFF3A3A3A), // medium grey
          ],
        ),
        borderRadius: _M.r12,
        boxShadow: _M.card,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          _Chip(label: 'All',    active: tab == 'All',    onTap: () => onTab('All')),
          const SizedBox(width: 4),
          _Chip(label: 'Credit', active: tab == 'Credit', onTap: () => onTab('Credit')),
          const SizedBox(width: 4),
          _Chip(label: 'Debit',  active: tab == 'Debit',  onTap: () => onTab('Debit')),
          const Spacer(),

          // Date button
          // GestureDetector(
          //   onTap: onPickRange,
          //   child: AnimatedContainer(
          //     duration: const Duration(milliseconds: 180),
          //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          //     decoration: BoxDecoration(
          //       color: range != null ? _M.blue : _M.bg,
          //       borderRadius: _M.rFull,
          //     ),
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Icon(
          //           Icons.calendar_today_rounded,
          //           size: 13,
          //           color: range != null ? Colors.white : _M.inkSub,
          //         ),
          //         const SizedBox(width: 5),
          //         Text(
          //           range == null
          //               ? 'Date'
          //               : '${DateFormat('MMM d').format(range!.start)} – ${DateFormat('MMM d').format(range!.end)}',
          //           style: TextStyle(
          //             fontSize: 13,
          //             fontWeight: FontWeight.w600,
          //             color: range != null ? Colors.white : _M.inkSub,
          //           ),
          //         ),
          //         if (range != null) ...[
          //           const SizedBox(width: 6),
          //           GestureDetector(
          //             onTap: onClearRange,
          //             child: const Icon(Icons.close_rounded,
          //                 size: 13, color: Colors.white),
          //           ),
          //         ],
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? Colors.black : Colors.transparent,
          borderRadius: _M.rFull,
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : _M.inkSub,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// CARD
// ════════════════════════════════════════════════════

class _Card extends StatefulWidget {
  final _Entry entry;
  const _Card({required this.entry});
  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  bool _down = false;

  @override
 @override
Widget build(BuildContext context) {
  final e        = widget.entry;
  final isCredit = e.isCredit;
  final fgColor  = isCredit ? _M.greenFg      : _M.redFg;
  final surfaceC = isCredit ? _M.greenSurface  : _M.redSurface;

  return GestureDetector(
    onTapDown:   (_) => setState(() => _down = true),
    onTapUp:     (_) => setState(() => _down = false),
    onTapCancel: ()  => setState(() => _down = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        color: _down ? const Color(0xFFF7F8FA) : _M.surface,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: const Color(0x12000000), width: 0.5),
        boxShadow: _M.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Main row ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.source,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _M.ink,
                          letterSpacing: -0.2,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        e.typeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _M.inkSub,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(color: surfaceC, borderRadius: _M.r8),
                  child: Text(
                    e.amtLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: fgColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Remarks ──────────────────────────────
          if (e.hasRemarks) ...[
            Divider(height: 0.5, thickness: 0.5, color: _M.line, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Text(
                e.remarks!,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: _M.inkSub,
                  height: 1.55,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],

          // ── Footer ───────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFE9EAEC),
              border: Border(top: BorderSide(color: Color(0xFFD8DADF), width: 0.5)),
              borderRadius: BorderRadius.only(
                bottomLeft:  Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                Text(
                  DateFormat('MMM d, yyyy').format(e.createdAt),
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF8A8D91), fontWeight: FontWeight.w500),
                ),
                Container(
                  width: 3, height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: const BoxDecoration(color: _M.inkHint, shape: BoxShape.circle),
                ),
                Text(
                  DateFormat('h:mm a').format(e.createdAt),
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF8A8D91), fontWeight: FontWeight.w500),
                ),
                if (e.lrId != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8DADF),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'LR-${e.lrId}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8A8D91),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}}

// ════════════════════════════════════════════════════
// UTILITY
// ════════════════════════════════════════════════════

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: _M.blue,
        strokeWidth: 2.5,
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: _M.blueSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 24,
              color: _M.blue,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _M.ink,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(
              fontSize: 13,
              color: _M.inkSub,
            ),
          ),
        ],
      ),
    );
  }
}