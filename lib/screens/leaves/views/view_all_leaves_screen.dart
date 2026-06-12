import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shop/constants.dart'; // <- import your constants file

// ════════════════════════════════════════════════════
// MODELS
// ════════════════════════════════════════════════════

enum LeaveTab { all, pending, approved, disapproved }

extension LeavTabX on LeaveTab {
  String get label => name[0].toUpperCase() + name.substring(1);
}

class _StatusStyle {
  final Color fg, bg, bar;
  final IconData icon;
  const _StatusStyle({
    required this.fg,
    required this.bg,
    required this.bar,
    required this.icon,
  });

  static _StatusStyle of(String s) {
  switch (s.toLowerCase()) {
    case 'approved':
      return const _StatusStyle(
          fg: C.approvedFg,
          bg: C.approvedBg,
          bar: C.approvedBar,
          icon: Icons.check_circle_rounded);
    case 'disapproved':
    case 'rejected':
    case 'declined':
      return const _StatusStyle(
          fg: C.rejectedFg,
          bg: C.rejectedBg,
          bar: C.rejectedBar,
          icon: Icons.cancel_rounded);
    case 'for_hr_review':
    case 'for hr review':
      return const _StatusStyle(
          fg: C.pendingFg,
          bg: C.pendingBg,
          bar: C.pendingBar,
          icon: Icons.manage_accounts_rounded);
    case 'for_hr_dc_review':
    case 'for hr dc review':
      return const _StatusStyle(
          fg: C.pendingFg,
          bg: C.pendingBg,
          bar: C.pendingBar,
          icon: Icons.rate_review_rounded);
    case 'for_supervisor_review':
    case 'for supervisor review':
      return const _StatusStyle(
          fg: C.pendingFg,
          bg: C.pendingBg,
          bar: C.pendingBar,
          icon: Icons.supervisor_account_rounded);
    case 'for_approval':
    case 'for approval':
      return const _StatusStyle(
          fg: C.pendingFg,
          bg: C.pendingBg,
          bar: C.pendingBar,
          icon: Icons.pending_actions_rounded);
    default:
      return const _StatusStyle(
          fg: C.neutralFg,
          bg: C.neutralBg,
          bar: C.textLow,
          icon: Icons.info_outline_rounded);
  }
}
}

class _LeaveDate {
  final String date, type;
  const _LeaveDate({required this.date, required this.type});
  factory _LeaveDate.fromJson(Map<String, dynamic> j) =>
      _LeaveDate(date: j['date'] ?? '', type: j['type'] ?? '');
}

class _LeaveRequest {
  final int id;
  final String staffName,
      status,
      reason,
      typeName,
      typeCode;
  final String totalDays,
      actualDays,
      splUsed,
      createdAt,
      updatedAt;
  final String computationNotes;
  final List<_LeaveDate> leaveDates;

  const _LeaveRequest({
    required this.id,
    required this.staffName,
    required this.status,
    required this.reason,
    required this.typeName,
    required this.typeCode,
    required this.totalDays,
    required this.actualDays,
    required this.splUsed,
    required this.createdAt,
    required this.updatedAt,
    required this.computationNotes,
    required this.leaveDates,
  });

factory _LeaveRequest.fromJson(Map<String, dynamic> j) {
  // leave_dates comes as a JSON string, so decode it first
  final rawDates = j['leave_dates'];
  final List dateList = rawDates is String
      ? (jsonDecode(rawDates) as List? ?? [])
      : (rawDates as List? ?? []);

  final dates = dateList
      .map((d) => _LeaveDate.fromJson(d as Map<String, dynamic>))
      .toList();

  return _LeaveRequest(
    id: j['id'] ?? 0,
    staffName: j['staff_name'] ?? '',
    status: j['status'] ?? '',
    reason: j['reason'] ?? '',
    typeName: j['leave_type']?['name'] ?? '',
    typeCode: j['leave_type']?['code'] ?? '',
    totalDays: j['total_days']?.toString() ?? '',
    actualDays: j['actual_days']?.toString() ?? '',
    splUsed: j['spl_used']?.toString() ?? '',
    createdAt: j['created_at'] ?? '',
    updatedAt: j['updated_at'] ?? '',
    computationNotes: j['computation_notes'] ?? '',
    leaveDates: dates,
  );
}
  String get startDate => leaveDates.isNotEmpty ? leaveDates.first.date : '';
  String get endDate => leaveDates.isNotEmpty ? leaveDates.last.date : '';

  String get daysDisplay {
    final d = double.tryParse(totalDays);
    if (d == null) return totalDays;
    return d == d.truncateToDouble() ? d.toInt().toString() : d.toString();
  }

 String get resolvedStatus {
  final s = status.trim().toLowerCase();
  if (s == 'approved') return 'Approved';
  if (s == 'disapproved') return 'Disapproved';
  if (s == 'for_hr_review') return 'For HR Review';
  if (s == 'for_hr_dc_review') return 'For HR DC Review';
  if (s == 'for_supervisor_review') return 'For Supervisor Review';
  if (s == 'for_approval') return 'For Approval';
  return status.isNotEmpty
      ? status[0].toUpperCase() + status.substring(1)
      : 'Pending';
}
  String get typeImagePath {
    switch (typeName) {
      case 'Sick Leave':
        return 'assets/images/face-with-thermometer.png';
      case 'Vacation Leave':
        return 'assets/images/tent.png';
      case 'Emergency Leave':
        return 'assets/images/emergency.png';
      default:
        return 'assets/images/leave_default.png';
    }
  }

  Color get typeColor {
    switch (typeName) {
      case 'Sick Leave':
        return const Color.fromARGB(255, 196, 218, 6);
      case 'Vacation Leave':
        return const Color(0xFF34A853);
      case 'Emergency Leave':
        return const Color.fromARGB(255, 196, 92, 92);
      default:
        return C.primary;
    }
  }

  List<_ApprovalStep> get timeline {
    final steps = <_ApprovalStep>[
      _ApprovalStep('Request Submitted', 'Your leave request was filed.', createdAt),
      _ApprovalStep('Under Review', 'Being evaluated by the approving officer.', ''),
    ];
    if (resolvedStatus != 'Pending') {
      final isApproved = resolvedStatus == 'Approved';
      steps.add(_ApprovalStep(
        resolvedStatus,
        isApproved
            ? 'Your leave has been approved. Enjoy your time off!'
            : computationNotes.isNotEmpty
                ? computationNotes
                : 'Your leave request was ${resolvedStatus.toLowerCase()}.',
        updatedAt,
      ));
    }
    return steps;
  }
}

class _ApprovalStep {
  final String title, subtitle, timestamp;
  const _ApprovalStep(this.title, this.subtitle, this.timestamp);
  bool get isDone => timestamp.isNotEmpty;
  String get date => timestamp.contains('T')
      ? timestamp.split('T')[0]
      : (timestamp.isNotEmpty ? timestamp : '');
  String get time => timestamp.contains('T')
      ? timestamp.split('T')[1].split('.')[0]
      : '';
}

// ════════════════════════════════════════════════════
// SCREEN
// ════════════════════════════════════════════════════

class LeaveRequestsScreen extends StatefulWidget {
  final int staffId;
  const LeaveRequestsScreen({super.key, required this.staffId});

  @override
  State<LeaveRequestsScreen> createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends State<LeaveRequestsScreen> {
  int _selectedTab = 0;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  List<_LeaveRequest> _all = [];
  bool _loading = true;
  String? _err;

  LeaveTab get _currentTab => LeaveTab.values[_selectedTab];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final res = await http
          .get(Uri.parse('http://172.31.16.69/api/v1/leave-requests/staff-id/${widget.staffId}'))
          .timeout(const Duration(seconds: 15));

          debugPrint('Fetching: $res');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = (jsonDecode(res.body)['data'] as List?) ?? [];
        setState(() {
          _all = data.map((e) => _LeaveRequest.fromJson(e)).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _err = 'Server error ${res.statusCode}.';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = 'Unable to connect. Check your network.';
        _loading = false;
      });
    }
  }

 List<_LeaveRequest> _filtered(LeaveTab t) {
  var list = t == LeaveTab.all
      ? List<_LeaveRequest>.from(_all)
      : t == LeaveTab.pending
          ? _all.where((r) {
              final s = r.status.toLowerCase();
              return s.startsWith('for_') || s == 'pending';
            }).toList()
          : _all
              .where((r) => r.status.toLowerCase() == t.name.toLowerCase())
              .toList();

  final q = _searchQuery.trim().toLowerCase();
  if (q.isEmpty) return list;
  return list
      .where((r) =>
          r.typeName.toLowerCase().contains(q) ||
          r.reason.toLowerCase().contains(q) ||
          r.startDate.contains(q) ||
          r.endDate.contains(q))
      .toList();
}
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));

    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────
            Container(
              color: C.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 16, 6),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded, size: 20),
                          color: C.textHi,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 36, minHeight: 36),
                        ),
                        const SizedBox(width: 2),
                        const Expanded(
                          child: Text(
                            'Leave Requests',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: C.textHi,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(fontSize: 14, color: C.textHi),
                      decoration: InputDecoration(
                        hintText: 'Search by type, reason or date…',
                        hintStyle:
                            const TextStyle(fontSize: 14, color: C.textLow),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 14, right: 10),
                          child: Icon(Icons.search_rounded,
                              size: 20, color: C.textLow),
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 0),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Icon(Icons.close_rounded,
                                      size: 18, color: C.textLow),
                                ),
                              )
                            : null,
                        suffixIconConstraints:
                            const BoxConstraints(minWidth: 0),
                        filled: true,
                        fillColor: C.bg,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: C.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),

                  // ── Badge Tabs ───────────────────────────
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      itemCount: LeaveTab.values.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        final tab = LeaveTab.values[i];
                        final isSelected = _selectedTab == i;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTab = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1A1A1A)
                                  : const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tab.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF8A8A8A),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────
            Expanded(
              child: _loading
                  ? const _Loader()
                  : _err != null
                      ? _ErrorView(msg: _err!, onRetry: _fetch)
                      : _LeaveListView(
                          leaves: _filtered(_currentTab),
                          onRefresh: _fetch,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// LIST VIEW
// ════════════════════════════════════════════════════

class _LeaveListView extends StatelessWidget {
  final List<_LeaveRequest> leaves;
  final Future<void> Function() onRefresh;
  const _LeaveListView({required this.leaves, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (leaves.isEmpty) return const _EmptyView();
    return RefreshIndicator(
      color: C.primary,
      backgroundColor: C.surface,
      displacement: 20,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 40),
        itemCount: leaves.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _AnimatedCard(index: i, leave: leaves[i]),
      ),
    );
  }
}

class _AnimatedCard extends StatefulWidget {
  final int index;
  final _LeaveRequest leave;
  const _AnimatedCard({required this.index, required this.leave});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    final delay = Duration(milliseconds: 40 * widget.index.clamp(0, 5));
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: _LeaveCard(leave: widget.leave),
        ),
      );
}

// ════════════════════════════════════════════════════
// LEAVE CARD — Redesigned
// ════════════════════════════════════════════════════

class _LeaveCard extends StatelessWidget {
  final _LeaveRequest leave;
  const _LeaveCard({required this.leave});

  @override
  Widget build(BuildContext context) {
    final st = _StatusStyle.of(leave.status);
    final isSingleDay = leave.startDate == leave.endDate || leave.endDate.isEmpty;

    return Material(
      color: C.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _DetailSheet(leave: leave),
        ),
        child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Row 1: Icon + Type + Status pill ───
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: leave.typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          leave.typeImagePath,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Type name + Filed date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              leave.typeName.isEmpty
                                  ? 'Leave Request'
                                  : leave.typeName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: C.textHi,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Filed ${_fmt(leave.createdAt)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: C.textLow,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status pill
                      _StatusPill(label: leave.resolvedStatus, style: st),
                    ],
                  ),

                 // ── Reason snippet ───────────────────────
                 if (leave.reason.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    "${leave.reason}", // Add your emoji here
                    style: const TextStyle(
                      fontSize: 12,
                      color: C.textMid,
                      height: 1.45,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                  // ── Divider ─────────────────────────────
                  const SizedBox(height: 20),
                  // ── Row 2: Date range block + Days badge ─
                  Row(
                    children: [
                      // Calendar icon
                      const Icon(Icons.calendar_month_rounded,
                          size: 14, color: C.textLow),
                      const SizedBox(width: 6),

                      // Date range text
                      Expanded(
                        child: isSingleDay
                            ? Text(
                                leave.startDate.isNotEmpty
                                    ? leave.startDate
                                    : '—',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: C.textHi,
                                ),
                              )
                            : Row(
                                children: [
                                  Text(
                                    leave.startDate.isNotEmpty
                                        ? leave.startDate
                                        : '—',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: C.textHi,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    child: Container(
                                      width: 16,
                                      height: 1,
                                      color: C.textLow,
                                    ),
                                  ),
                                  Text(
                                    leave.endDate,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: C.textHi,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),

                 
                ],
              ),
            ),
      ),
    );
  }

  String _fmt(String raw) =>
      raw.isNotEmpty ? (raw.contains('T') ? raw.split('T')[0] : raw) : '—';
}

class _StatusPill extends StatelessWidget {
  final String label;
  final _StatusStyle style;
  const _StatusPill({required this.label, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: style.bar),
          ),
          const SizedBox(width: 5),
          Text(
            label.isEmpty ? 'Unknown' : label,
            style: TextStyle(
                color: style.fg, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// DETAIL BOTTOM SHEET
// ════════════════════════════════════════════════════

class _DetailSheet extends StatelessWidget {
  final _LeaveRequest leave;
  const _DetailSheet({required this.leave});

  @override
  Widget build(BuildContext context) {
    final st = _StatusStyle.of(leave.resolvedStatus);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 1.0,
      builder: (_, ctrl) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Scaffold(
          backgroundColor: C.bg,
          body: CustomScrollView(
            controller: ctrl,
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: C.surface,
                elevation: 0,
                automaticallyImplyLeading: false,
                toolbarHeight: 52,
                title: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 18,
                      decoration: BoxDecoration(
                        color: C.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        leave.typeName.isEmpty
                            ? 'Leave Request'
                            : leave.typeName,
                        style: const TextStyle(
                          color: C.textHi,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: C.bg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 17, color: C.textMid),
                      ),
                    ),
                  ],
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: C.divider),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    _StatusHero(leave: leave, st: st),
                    const SizedBox(height: 10),
                    _DateCardsRow(leave: leave),
                    const SizedBox(height: 8),
                    if (leave.leaveDates.isNotEmpty) ...[
                      _LeaveDatesCard(dates: leave.leaveDates),
                      const SizedBox(height: 8),
                    ],
                    if (leave.reason.isNotEmpty) ...[
                      _ReasonCard(reason: leave.reason),
                      const SizedBox(height: 8),
                    ],
                    if (leave.computationNotes.isNotEmpty) ...[
                      _NotesCard(notes: leave.computationNotes),
                      const SizedBox(height: 8),
                    ],
                    _FiledRow(leave: leave),
                    const SizedBox(height: 8),
                    _TimelineSection(steps: leave.timeline),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// DETAIL SHEET COMPONENTS (unchanged)
// ════════════════════════════════════════════════════

class _StatusHero extends StatelessWidget {
  final _LeaveRequest leave;
  final _StatusStyle st;
  const _StatusHero({required this.leave, required this.st});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: leave.typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                leave.typeImagePath,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leave.typeName.isEmpty ? 'Leave Request' : leave.typeName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: C.textHi,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: st.bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(st.icon, size: 11, color: st.fg),
                        const SizedBox(width: 4),
                        Text(
                          leave.resolvedStatus,
                          style: TextStyle(
                            color: st.fg,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateCardsRow extends StatelessWidget {
  final _LeaveRequest leave;
  const _DateCardsRow({required this.leave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _DateInfoCard(
              icon: Icons.login_rounded,
              label: 'Start',
              value: leave.startDate.isNotEmpty ? leave.startDate : '—',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DateInfoCard(
              icon: Icons.logout_rounded,
              label: 'End',
              value: leave.endDate.isNotEmpty ? leave.endDate : '—',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DateInfoCard(
              icon: Icons.timelapse_rounded,
              label: 'Days',
              value: '${leave.daysDisplay}d',
              highlight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateInfoCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool highlight;
  const _DateInfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight ? C.primaryLight : C.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: highlight ? C.primary.withOpacity(0.2) : C.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: highlight ? C.primary : C.textLow),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: highlight ? C.primary.withOpacity(0.7) : C.textLow,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.isNotEmpty ? value : '—',
            style: TextStyle(
              fontSize: 12,
              color: highlight ? C.primary : C.textHi,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveDatesCard extends StatefulWidget {
  final List<_LeaveDate> dates;
  const _LeaveDatesCard({required this.dates});

  @override
  State<_LeaveDatesCard> createState() => _LeaveDatesCardState();
}

class _LeaveDatesCardState extends State<_LeaveDatesCard>
    with SingleTickerProviderStateMixin {
  static const _previewCount = 5;
  bool _expanded = false;
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final hasMore = widget.dates.length > _previewCount;
    final shown = _expanded
        ? widget.dates
        : widget.dates.take(_previewCount).toList();
    final hiddenCount = widget.dates.length - _previewCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.date_range_rounded,
                    size: 13, color: C.textLow),
                const SizedBox(width: 5),
                const Text(
                  'LEAVE DATES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: C.textLow,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: C.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${widget.dates.length} date${widget.dates.length != 1 ? "s" : ""}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: C.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: shown.map((d) => _DateChip(d: d)).toList(),
            ),
            if (hasMore) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _toggle,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: C.primary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _expanded
                          ? 'Show less'
                          : 'View all $hiddenCount more date${hiddenCount != 1 ? "s" : ""}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: C.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final _LeaveDate d;
  const _DateChip({required this.d});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: C.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            d.date,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: C.primary,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: C.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              d.type,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: C.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonCard extends StatefulWidget {
  final String reason;
  const _ReasonCard({required this.reason});

  @override
  State<_ReasonCard> createState() => _ReasonCardState();
}

class _ReasonCardState extends State<_ReasonCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.reason.length > 120;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notes_rounded, size: 13, color: C.textLow),
                SizedBox(width: 5),
                Text(
                  'REASON FOR LEAVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: C.textLow,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _expanded || !isLong
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(
                widget.reason,
                style: const TextStyle(
                  fontSize: 13,
                  color: C.textMid,
                  height: 1.55,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(
                widget.reason,
                style: const TextStyle(
                  fontSize: 13,
                  color: C.textMid,
                  height: 1.55,
                ),
              ),
            ),
            if (isLong) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: C.primary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _expanded ? 'Show less' : 'Read more',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: C.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String notes;
  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.rejectedBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.rejectedBar.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 15, color: C.rejectedFg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notes,
                style: const TextStyle(
                  fontSize: 12,
                  color: C.rejectedFg,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiledRow extends StatelessWidget {
  final _LeaveRequest leave;
  const _FiledRow({required this.leave});

  @override
  Widget build(BuildContext context) {
    final filed = leave.createdAt.contains('T')
        ? leave.createdAt.split('T')[0]
        : leave.createdAt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.history_rounded, size: 15, color: C.textLow),
            const SizedBox(width: 8),
            const Text('Filed on',
                style: TextStyle(fontSize: 13, color: C.textMid)),
            const Spacer(),
            Text(
              filed.isNotEmpty ? filed : '—',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: C.textHi,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final List<_ApprovalStep> steps;
  const _TimelineSection({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_tree_rounded, size: 13, color: C.textLow),
                SizedBox(width: 5),
                Text(
                  'APPROVAL TIMELINE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: C.textLow,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...List.generate(
              steps.length,
              (i) =>
                  _TimelineRow(step: steps[i], isLast: i == steps.length - 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final _ApprovalStep step;
  final bool isLast;
  const _TimelineRow({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final isDone = step.isDone;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 2),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? C.primary : C.surface,
                    border: Border.all(
                      color: isDone ? C.primary : C.timelinePend,
                      width: isDone ? 0 : 1.5,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          size: 8, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: isDone ? C.primary.withOpacity(0.2) : C.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDone ? C.textHi : C.textLow,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          step.subtitle,
                          style: const TextStyle(
                              fontSize: 11, color: C.textMid, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  if (step.date.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          step.date,
                          style: const TextStyle(
                            fontSize: 10,
                            color: C.textLow,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (step.time.isNotEmpty)
                          Text(
                            step.time,
                            style:
                                const TextStyle(fontSize: 10, color: C.textLow),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// UTILITY STATES
// ════════════════════════════════════════════════════

class _Loader extends StatefulWidget {
  const _Loader();
  @override
  State<_Loader> createState() => _LoaderState();
}

class _LoaderState extends State<_Loader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                  color: C.primary, strokeWidth: 2.5),
              const SizedBox(height: 16),
              Text(
                'Loading requests…',
                style: TextStyle(
                  fontSize: 13,
                  color: C.textMid,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
}

class _EmptyView extends StatefulWidget {
  const _EmptyView();
  @override
  State<_EmptyView> createState() => _EmptyViewState();
}

class _EmptyViewState extends State<_EmptyView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Container(
      width: 64,
      height: 64,
      alignment: Alignment.center, // ✅ center the emoji
      decoration: const BoxDecoration(
        color: C.primaryLight,
        shape: BoxShape.circle,
      ),
      child: const Text(
        '❓',
        style: TextStyle(fontSize: 28), // ✅ make emoji visible
      ),
    ),
    const SizedBox(height: 16),

    const Text(
      'No requests found',
      textAlign: TextAlign.center, // ✅ center text
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: C.textHi,
      ),
    ),

    const SizedBox(height: 6),

    const Text(
      'Try a different filter or pull down to refresh.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        color: C.textMid,
        height: 1.3, // ✅ better readability
      ),
    ),
  ],
),
            ),
          ),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorView({required this.msg, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                    color: C.rejectedBg, shape: BoxShape.circle),
                child: const Icon(Icons.wifi_off_rounded,
                    color: C.rejectedFg, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                "Can't connect",
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: C.textHi),
              ),
              const SizedBox(height: 6),
              Text(
                msg,
                style: const TextStyle(fontSize: 13, color: C.textMid),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Try Again',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}