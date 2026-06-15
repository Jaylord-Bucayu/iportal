import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shop/route/route_constants.dart';

// ─── Design System ────────────────────────────────────────────────────────────
class _DS {
  // Brand
  static const brand        = Color(0xFF3D5AFE);
  static const brandLight   = Color(0xFFEEF1FF);
  static const brandMid     = Color(0xFF2541CC);

  // Neutrals
  static const bgPage       = Color(0xFFF5F6FA);
  static const surface      = Color(0xFFFFFFFF);
  static const surfaceHover = Color(0xFFF9FAFB);
  static const border       = Color(0xFFE8EAF0);
  static const borderStrong = Color(0xFFCDD0DC);

  // Text
  static const ink1         = Color(0xFF0F1117);
  static const ink2         = Color(0xFF4B5068);
  static const ink3         = Color(0xFF9397A8);
  static const inkHint      = Color(0xFFB8BAC8);

  // Status — black and white only
  static const black        = Color(0xFF000000);
  static const white        = Color(0xFFFFFFFF);
  static const greyBg       = Color(0xFFF5F5F5);
  static const greyBorder   = Color(0xFFE0E0E0);
  static const greyDark     = Color(0xFF757575);

  // Leave type accents (keep colored)
  static const sick         = Color(0xFFEF4444);
  static const sickBg       = Color(0xFFFEF2F2);
  static const vacation     = Color(0xFF3D5AFE);
  static const vacationBg   = Color(0xFFEEF1FF);
  static const emergency    = Color(0xFFF59E0B);
  static const emergencyBg  = Color(0xFFFFFBEB);
  static const maternity    = Color(0xFF8B5CF6);
  static const maternityBg  = Color(0xFFF5F3FF);
  static const other        = Color(0xFF0EA5E9);
  static const otherBg      = Color(0xFFEFF9FF);

  // Elevation
  static List<BoxShadow> get z1 => [
    BoxShadow(color: const Color(0xFF0F1117).withOpacity(0.05),
        blurRadius: 8, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> get z2 => [
    BoxShadow(color: const Color(0xFF0F1117).withOpacity(0.08),
        blurRadius: 20, offset: const Offset(0, 4)),
    BoxShadow(color: const Color(0xFF0F1117).withOpacity(0.04),
        blurRadius: 6, offset: const Offset(0, 1)),
  ];
  static List<BoxShadow> get zAvatar => [
    BoxShadow(color: const Color(0xFF3D5AFE).withOpacity(0.22),
        blurRadius: 12, offset: const Offset(0, 4)),
  ];

  // Type
  static TextStyle display({double size = 22, FontWeight w = FontWeight.w700, Color? c}) =>
      TextStyle(fontSize: size, fontWeight: w, color: c ?? ink1,
          letterSpacing: -0.6, height: 1.15, fontFamily: null);

  static TextStyle body({double size = 14, FontWeight w = FontWeight.w400, Color? c}) =>
      TextStyle(fontSize: size, fontWeight: w, color: c ?? ink2,
          letterSpacing: -0.1, height: 1.45);

  static TextStyle caption({double size = 11, FontWeight w = FontWeight.w500, Color? c}) =>
      TextStyle(fontSize: size, fontWeight: w, color: c ?? ink3,
          letterSpacing: 0.1, height: 1.3);
}

// ─── Search Bar (Moved before StickyHeader) ───────────────────────────────────
class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _DS.bgPage,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _focused ? _DS.brand.withOpacity(0.5) : _DS.border,
            width: _focused ? 1.5 : 0.5,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          style: _DS.body(size: 14, c: _DS.ink1),
          decoration: InputDecoration(
            hintText: 'Search by name, reason, or type…',
            hintStyle: _DS.body(size: 14, c: _DS.inkHint),
            prefixIcon: Icon(Icons.search_rounded, size: 18,
                color: _focused ? _DS.brand : _DS.ink3),
            suffixIcon: AnimatedOpacity(
              opacity: widget.controller.text.isEmpty ? 0 : 1,
              duration: const Duration(milliseconds: 150),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, size: 16, color: _DS.ink3),
                onPressed: () { widget.controller.clear(); widget.onChanged(''); },
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          ),
        ),
      ),
    );
  }
}

// ─── Enums ────────────────────────────────────────────────────────────────────
enum LeaveStatus { pending, approved, disapproved, all }

extension LeaveStatusX on LeaveStatus {
  String get label => switch (this) {
    LeaveStatus.pending      => 'Pending',
    LeaveStatus.approved     => 'Approved',
    LeaveStatus.disapproved  => 'Disapproved',
    LeaveStatus.all          => 'All',
  };
  String get apiValue => name;

  Color get color => _DS.black;
  Color get bg => _DS.greyBg;
  Color get textColor => _DS.black;

  IconData get icon => switch (this) {
    LeaveStatus.pending      => Icons.schedule_rounded,
    LeaveStatus.approved     => Icons.check_circle_rounded,
    LeaveStatus.disapproved  => Icons.cancel_rounded,
    LeaveStatus.all          => Icons.dashboard_rounded,
  };
}

// ─── Leave type resolver ──────────────────────────────────────────────────────
({Color bg, Color fg, IconData icon, String label}) _leaveType(String? raw) {
  final t = (raw ?? '').toLowerCase();
  if (t.contains('sick'))
    return (bg: _DS.sickBg, fg: _DS.sick, icon: Icons.medical_services_rounded, label: raw ?? 'Sick');
  if (t.contains('vacation') || t.contains('annual'))
    return (bg: _DS.vacationBg, fg: _DS.vacation, icon: Icons.beach_access_rounded, label: raw ?? 'Vacation');
  if (t.contains('emergency'))
    return (bg: _DS.emergencyBg, fg: _DS.emergency, icon: Icons.bolt_rounded, label: raw ?? 'Emergency');
  if (t.contains('maternity') || t.contains('paternity'))
    return (bg: _DS.maternityBg, fg: _DS.maternity, icon: Icons.child_friendly_rounded, label: raw ?? 'Maternity');
  return (bg: _DS.otherBg, fg: _DS.other, icon: Icons.calendar_today_rounded, label: raw ?? 'Leave');
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class ForLeaveApprovalScreen extends StatefulWidget {
  final String status;
  final String authorityType;
  final int authorityId;

  const ForLeaveApprovalScreen({
    Key? key,
    required this.status,
    required this.authorityType,
    required this.authorityId,
  }) : super(key: key);

  @override
  State<ForLeaveApprovalScreen> createState() => _ForLeaveApprovalScreenState();
}

class _ForLeaveApprovalScreenState extends State<ForLeaveApprovalScreen>
    with TickerProviderStateMixin {

  List<Map<String, dynamic>> _all       = [];
  List<Map<String, dynamic>> _filtered  = [];
  bool _loading                         = false;
  LeaveStatus _tab                      = LeaveStatus.pending;
  String _query                         = '';
  Map<LeaveStatus, int> _counts         = {};

  late final AnimationController _entryCtrl;
  late final AnimationController _listCtrl;
  late final Animation<double>   _headerFade;
  late final Animation<Offset>   _headerSlide;

  final _searchCtrl  = TextEditingController();
  final _scrollCtrl  = ScrollController();
  bool _isScrolled   = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _listCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _headerFade  = CurvedAnimation(parent: _entryCtrl, curve: const Interval(0, 0.7, curve: Curves.easeOut));
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: const Interval(0, 0.8, curve: Curves.easeOutCubic)));

    _scrollCtrl.addListener(() {
      final s = _scrollCtrl.offset > 4;
      if (s != _isScrolled && mounted) setState(() => _isScrolled = s);
    });

    _entryCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _listCtrl.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() => _loading = true);
    _listCtrl.reset();

    try {
      final payload = {
        'authority_type': widget.authorityType,
        'authority_id'  : widget.authorityId.toString(),
        if (_tab != LeaveStatus.all) 'status_filter': _tab.apiValue,
      };

      final res = await http.post(
        Uri.parse('http://172.31.16.69/api/v1/leave-pending/authority'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;
      if (res.statusCode == 200) {
        final raw = (jsonDecode(res.body)['data'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        final countMap = <LeaveStatus, int>{};
        if (_tab == LeaveStatus.all) {
          for (final status in LeaveStatus.values) {
            if (status == LeaveStatus.all) {
              countMap[status] = raw.length;
            } else {
              countMap[status] = raw.where((l) =>
              (l['status'] ?? '').toString().toLowerCase() == status.apiValue).length;
            }
          }
        } else {
          countMap[_tab] = raw.length;
          for (final s in LeaveStatus.values) {
            if (!countMap.containsKey(s)) countMap[s] = _counts[s] ?? 0;
          }
          countMap[LeaveStatus.all] = (_counts[LeaveStatus.all] ?? 0);
        }

        setState(() {
          _all     = raw;
          _counts  = countMap;
        });
        _applyFilter();
        await Future.delayed(const Duration(milliseconds: 50));
        if (mounted) _listCtrl.forward();
      } else {
        _snack('Could not load requests');
      }
    } catch (_) {
      if (mounted) _snack('Network error — check your connection');
    }

    if (mounted) setState(() => _loading = false);
  }

  void _applyFilter() {
    final q = _query.toLowerCase();
    setState(() {
      _filtered = _all.where((l) {
        if (q.isEmpty) return true;
        return (l['staff_name'] ?? '').toString().toLowerCase().contains(q) ||
            (l['reason'] ?? '').toString().toLowerCase().contains(q) ||
            ((l['leave_type']?['name'] ?? '').toString().toLowerCase()).contains(q);
      }).toList();
    });
    _listCtrl
      ..reset()
      ..forward();
  }

  void _onTabChange(LeaveStatus s) {
    if (_tab == s) return;
    HapticFeedback.selectionClick();
    setState(() {
      _tab   = s;
      _query = '';
      _searchCtrl.clear();
    });
    _fetch();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: _DS.body(size: 13, c: Colors.white)),
      backgroundColor: _DS.ink1,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  String _fmtDate(String? s) {
    if (s == null) return '';
    try { return DateFormat('MMM d').format(DateTime.parse(s)); }
    catch (_) { return s; }
  }

  String _initials(String name) => name.trim().split(' ')
      .take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

  void _zoomAvatar(dynamic staffId, String name) {
    HapticFeedback.lightImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, anim, __) => _AvatarZoom(staffId: staffId, name: name, anim: anim),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: _DS.bgPage,
      body: Column(
        children: [
          _StickyHeader(
            topPad       : topPad,
            isScrolled   : _isScrolled,
            loading      : _loading,
            count        : _filtered.length,
            tab          : _tab,
            counts       : _counts,
            searchCtrl   : _searchCtrl,
            headerFade   : _headerFade,
            headerSlide  : _headerSlide,
            onBack       : () => Navigator.pop(context),
            onRefresh    : () { HapticFeedback.lightImpact(); _fetch(); },
            onTabChange  : _onTabChange,
            onSearch     : (q) { _query = q; _applyFilter(); },
          ),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _loading
                  ? _buildShimmer()
                  : _filtered.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                color: _DS.brand,
                backgroundColor: _DS.surface,
                onRefresh: _fetch,
                child: ListView.builder(
                  key: ValueKey('list_${_tab.name}_${_filtered.length}'),
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _buildCard(_filtered[i], i),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> leave, int index) {
    final type   = _leaveType(leave['leave_type']?['name']?.toString());
    final status = (leave['status'] ?? '').toString().toLowerCase();
    final leaveStatus = switch (status) {
      'approved' || 'accept'                  => LeaveStatus.approved,
      'disapproved' || 'reject' || 'denied'   => LeaveStatus.disapproved,
      _                                        => LeaveStatus.pending,
    };

    final delay = (index * 0.055).clamp(0.0, 0.55);
    final end   = (delay + 0.35).clamp(0.0, 1.0);

    final fade  = CurvedAnimation(parent: _listCtrl,
        curve: Interval(delay, end, curve: Curves.easeOut));
    final slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _listCtrl,
        curve: Interval(delay, end, curve: Curves.easeOutCubic)));

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: _PressableCard(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pushNamed(
              context,
              _tab == LeaveStatus.pending ? leaveDetailsScreenRoute : leaveActionScreenRoute,
              arguments: leave['id'].toString(),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _zoomAvatar(leave['staff_id'], leave['staff_name'] ?? ''),
                  child: _Avatar(
                    staffId  : leave['staff_id'],
                    initials : _initials(leave['staff_name'] ?? ''),
                    typeColor: type.fg,
                    typeBg   : type.bg,
                    typeIcon : type.icon,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leave['staff_name'] ?? '',
                        style: _DS.body(size: 14, w: FontWeight.w600, c: _DS.ink1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _TypeChip(
                            icon : type.icon,
                            label: type.label,
                            bg   : type.bg,
                            fg   : type.fg,
                          ),
                          const SizedBox(width: 6),
                          _StatusBadge(status: leaveStatus),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _fmtDate(leave['created_at']),
                      style: _DS.caption(size: 11, c: _DS.ink3),
                    ),
                    const SizedBox(height: 6),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: _DS.ink3),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final msg = _query.isNotEmpty
        ? 'No results for "$_query"'
        : switch (_tab) {
      LeaveStatus.pending     => 'No pending requests',
      LeaveStatus.approved    => 'No approved requests',
      LeaveStatus.disapproved => 'No disapproved requests',
      LeaveStatus.all         => 'No requests found',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _tab.bg,
                shape: BoxShape.circle,
              ),
              child: Icon(_tab.icon, size: 36, color: _tab.color),
            ),
            const SizedBox(height: 20),
            Text(msg, style: _DS.display(size: 16, w: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              _query.isNotEmpty ? 'Try a different search term' : 'Pull down to refresh',
              style: _DS.body(size: 13, c: _DS.ink3),
            ),
            if (_query.isNotEmpty) ...[
              const SizedBox(height: 16),
              _OutlineButton(
                label: 'Clear search',
                onTap: () {
                  _searchCtrl.clear();
                  _query = '';
                  _applyFilter();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: 5,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ShimmerCard(delay: i * 80),
      ),
    );
  }
}

// ─── Sticky Header ────────────────────────────────────────────────────────────
class _StickyHeader extends StatelessWidget {
  final double topPad;
  final bool isScrolled, loading;
  final int count;
  final LeaveStatus tab;
  final Map<LeaveStatus, int> counts;
  final TextEditingController searchCtrl;
  final Animation<double> headerFade;
  final Animation<Offset> headerSlide;
  final VoidCallback onBack, onRefresh;
  final ValueChanged<LeaveStatus> onTabChange;
  final ValueChanged<String> onSearch;

  const _StickyHeader({
    required this.topPad, required this.isScrolled, required this.loading,
    required this.count,  required this.tab,        required this.counts,
    required this.searchCtrl, required this.headerFade, required this.headerSlide,
    required this.onBack, required this.onRefresh,  required this.onTabChange,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _DS.surface,
        boxShadow: isScrolled ? _DS.z1 : [],
        border: isScrolled
            ? const Border(bottom: BorderSide(color: _DS.border, width: 0.5))
            : const Border(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPad + 6),

          FadeTransition(
            opacity: headerFade,
            child: SlideTransition(
              position: headerSlide,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _BackButton(onTap: onBack),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Leave Requests',
                                  style: _DS.display(size: 20, w: FontWeight.w700)),
                              const SizedBox(height: 2),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  loading ? 'Loading…' : '$count request${count == 1 ? '' : 's'}',
                                  key: ValueKey('$loading$count'),
                                  style: _DS.caption(size: 12, c: _DS.ink3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _CircleButton(
                          icon: loading ? null : Icons.refresh_rounded,
                          isLoading: loading,
                          onTap: onRefresh,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _SearchBar(controller: searchCtrl, onChanged: onSearch),

                    const SizedBox(height: 12),

                    _TabRow(
                      selected: tab,
                      counts  : counts,
                      onChange: onTabChange,
                    ),

                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Row ──────────────────────────────────────────────────────────────────
class _TabRow extends StatelessWidget {
  final LeaveStatus selected;
  final Map<LeaveStatus, int> counts;
  final ValueChanged<LeaveStatus> onChange;

  const _TabRow({required this.selected, required this.counts, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: LeaveStatus.values.map((s) {
          final active = s == selected;
          final cnt    = counts[s] ?? 0;

          return GestureDetector(
            onTap: () => onChange(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? _DS.greyBg : _DS.bgPage,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: active ? _DS.black : _DS.border,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(s.icon, size: 13,
                      color: active ? _DS.black : _DS.ink3),
                  const SizedBox(width: 5),
                  Text(
                    s.label,
                    style: _DS.caption(
                      size: 12,
                      w: active ? FontWeight.w700 : FontWeight.w500,
                      c: active ? _DS.black : _DS.ink3,
                    ),
                  ),
                  if (cnt > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: active ? _DS.black : _DS.greyBorder,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$cnt',
                        style: _DS.caption(
                          size: 10,
                          w: FontWeight.w700,
                          c: active ? _DS.white : _DS.ink3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final dynamic staffId;
  final String initials;
  final Color typeColor, typeBg;
  final IconData typeIcon;

  const _Avatar({
    required this.staffId,  required this.initials,
    required this.typeColor, required this.typeBg, required this.typeIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _DS.brandLight,
            border: Border.all(color: _DS.surface, width: 2),
            boxShadow: _DS.zAvatar,
          ),
          child: ClipOval(
            child: Image.network(
              'https://fo2-staff-search.dswd.gov.ph/images/$staffId.jpg',
              width: 52, height: 52, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(initials,
                    style: _DS.body(size: 14, w: FontWeight.w700, c: _DS.brand)),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -2,
          right: -4,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: typeBg,
              shape: BoxShape.circle,
              border: Border.all(color: _DS.surface, width: 1.5),
            ),
            child: Icon(typeIcon, size: 11, color: typeColor),
          ),
        ),
      ],
    );
  }
}

// ─── Type Chip ────────────────────────────────────────────────────────────────
class _TypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg, fg;
  const _TypeChip({required this.icon, required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: fg),
        const SizedBox(width: 5),
        Text(label,
            style: _DS.caption(size: 11, w: FontWeight.w700, c: fg)),
      ],
    ),
  );
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final LeaveStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: _DS.greyBg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _DS.greyBorder, width: 0.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(status.icon, size: 11, color: _DS.black),
        const SizedBox(width: 5),
        Text(status.label,
            style: _DS.caption(size: 11, w: FontWeight.w700, c: _DS.black)),
      ],
    ),
  );
}

// ─── Outline Button ───────────────────────────────────────────────────────────
class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: _DS.brand),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(label,
          style: _DS.body(size: 13, w: FontWeight.w600, c: _DS.brand)),
    ),
  );
}

// ─── Back Button ─────────────────────────────────────────────────────────────
class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});
  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => _c.forward(),
    onTapUp:     (_) { _c.reverse(); widget.onTap(); },
    onTapCancel: () => _c.reverse(),
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.scale(scale: 1 - _c.value * 0.08, child: child),
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: _DS.bgPage,
          shape: BoxShape.circle,
          border: Border.all(color: _DS.border, width: 0.5),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: _DS.ink1),
      ),
    ),
  );
}

// ─── Circle Button ────────────────────────────────────────────────────────────
class _CircleButton extends StatelessWidget {
  final IconData? icon;
  final bool isLoading;
  final VoidCallback onTap;
  const _CircleButton({this.icon, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: isLoading ? _DS.brandLight : _DS.bgPage,
        shape: BoxShape.circle,
        border: Border.all(color: _DS.border, width: 0.5),
      ),
      child: isLoading
          ? const Padding(padding: EdgeInsets.all(10),
          child: CircularProgressIndicator(strokeWidth: 2, color: _DS.brand))
          : Icon(icon, size: 18, color: _DS.ink2),
    ),
  );
}

// ─── Pressable Card ───────────────────────────────────────────────────────────
class _PressableCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _PressableCard({required this.onTap, required this.child});
  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => _c.forward(),
    onTapUp:     (_) { _c.reverse(); widget.onTap(); },
    onTapCancel: () => _c.reverse(),
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.scale(scale: 1 - _c.value * 0.015, child: child),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _DS.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _DS.border, width: 0.5),
          boxShadow: _DS.z1,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: widget.child,
        ),
      ),
    ),
  );
}

// ─── Shimmer Card ─────────────────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  final int delay;
  const _ShimmerCard({this.delay = 0});
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  late final _a = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  Widget _bone(double w, double h, {double r = 8}) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: w, height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        color: Color.lerp(const Color(0xFFE8EAF0), const Color(0xFFF5F6FA), _a.value),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _DS.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _DS.border, width: 0.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _bone(52, 52, r: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bone(140, 14),
                  const SizedBox(height: 6),
                  _bone(90, 11),
                ],
              ),
            ),
            _bone(40, 11),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, color: _DS.border),
        const SizedBox(height: 14),
        Row(children: [_bone(80, 11), const SizedBox(width: 8), _bone(12, 11), const SizedBox(width: 8), _bone(80, 11)]),
        const SizedBox(height: 10),
        _bone(double.infinity, 11),
        const SizedBox(height: 5),
        _bone(200, 11),
        const SizedBox(height: 12),
        Row(children: [_bone(90, 26, r: 8), const SizedBox(width: 6), _bone(80, 26, r: 8)]),
      ],
    ),
  );
}

// ─── Avatar Zoom Dialog ───────────────────────────────────────────────────────
class _AvatarZoom extends StatelessWidget {
  final dynamic staffId;
  final String name;
  final Animation<double> anim;
  const _AvatarZoom({required this.staffId, required this.name, required this.anim});

  String _initials(String n) => n.trim().split(' ')
      .take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) {
        final t = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic).value;
        return Opacity(
          opacity: t,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: t * 24, sigmaY: t * 24),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black.withOpacity(0.6),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: anim,
                  builder: (_, child) {
                    final t = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic).value;
                    return Transform.translate(
                        offset: Offset(0, (1 - t) * 16), child: Opacity(opacity: t, child: child));
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(name,
                        style: const TextStyle(color: Colors.white, fontSize: 20,
                            fontWeight: FontWeight.w700, letterSpacing: -0.4)),
                  ),
                ),
                AnimatedBuilder(
                  animation: anim,
                  builder: (_, child) {
                    final t = CurvedAnimation(parent: anim, curve: Curves.easeOutBack).value;
                    return Transform.scale(scale: 0.75 + t * 0.25, child: child);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
                      boxShadow: [BoxShadow(color: _DS.brand.withOpacity(0.4),
                          blurRadius: 40, spreadRadius: 8)],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://fo2-staff-search.dswd.gov.ph/images/$staffId.jpg',
                        width: 220, height: 220, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 220, height: 220, color: _DS.brandLight,
                          child: Center(
                            child: Text(_initials(name),
                                style: const TextStyle(fontSize: 62,
                                    fontWeight: FontWeight.w800, color: _DS.brand)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                AnimatedBuilder(
                  animation: anim,
                  builder: (_, child) => Opacity(
                    opacity: CurvedAnimation(parent: anim,
                        curve: const Interval(0.5, 1.0)).value,
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.18), width: 0.5),
                    ),
                    child: const Text('Tap anywhere to close',
                        style: TextStyle(color: Colors.white, fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}