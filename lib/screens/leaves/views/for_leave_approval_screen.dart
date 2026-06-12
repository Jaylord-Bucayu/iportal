import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shop/route/route_constants.dart';

// ─── Design Tokens — Meta-style ───────────────────────────────────────────────
class _T {
  // Core palette (Meta blue system)
  static const metaBlue     = Color(0xFF0866FF);
  static const metaBlueSoft = Color(0xFFE7F0FF);
  static const metaBlueMid  = Color(0xFF0050D0);

  static const bg           = Color(0xFFF0F2F5); // Meta feed background
  static const surface      = Color(0xFFFFFFFF);
  static const surfaceHover = Color(0xFFF7F8FA);
  static const divider      = Color(0xFFE4E6EB);

  static const textPrimary   = Color(0xFF050505);
  static const textSecondary = Color(0xFF65676B);
  static const textTertiary  = Color(0xFF8A8D91);
  static const textPlaceholder = Color(0xFFBCC0C4);

  // Leave type palette — refined
  static const sick        = Color(0xFFE02020);
  static const sickSoft    = Color(0xFFFFF0F0);
  static const vacation    = Color(0xFF0866FF);
  static const vacationSoft= Color(0xFFE7F0FF);
  static const emergency   = Color(0xFFE67700);
  static const emergencySoft = Color(0xFFFFF4E0);
  static const maternity   = Color(0xFF9340CC);
  static const maternitySoft = Color(0xFFF5EBFF);
  static const other       = Color(0xFF00875A);
  static const otherSoft   = Color(0xFFE6F7F1);

  // Shadows — Meta's subtle layering
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get avatarShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.14),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get headerShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  // Typography helpers
  static TextStyle heading({double size = 18, FontWeight w = FontWeight.w700, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: w,
        color: color ?? textPrimary,
        letterSpacing: -0.4,
        height: 1.15,
      );

  static TextStyle label({double size = 14, FontWeight w = FontWeight.w400, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: w,
        color: color ?? textSecondary,
        letterSpacing: -0.1,
        height: 1.4,
      );
}

// ─── Leave type resolver ──────────────────────────────────────────────────────
({Color bg, Color fg, IconData icon, String short}) _resolveLeaveType(String? raw) {
  final t = (raw ?? '').toLowerCase();
  if (t.contains('sick'))
    return (bg: _T.sickSoft, fg: _T.sick, icon: Icons.medical_services_rounded, short: 'SL');
  if (t.contains('vacation') || t.contains('annual'))
    return (bg: _T.vacationSoft, fg: _T.vacation, icon: Icons.beach_access_rounded, short: 'VL');
  if (t.contains('emergency'))
    return (bg: _T.emergencySoft, fg: _T.emergency, icon: Icons.priority_high_rounded, short: 'EL');
  if (t.contains('maternity') || t.contains('paternity'))
    return (bg: _T.maternitySoft, fg: _T.maternity, icon: Icons.child_friendly_rounded, short: 'ML');
  return (bg: _T.otherSoft, fg: _T.other, icon: Icons.event_note_rounded, short: 'OL');
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

  // ── Data ──────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> allLeaves      = [];
  List<Map<String, dynamic>> filteredLeaves = [];
  bool isLoading = false;

  // ── Controllers ───────────────────────────────────────────────────────────
  late final AnimationController _headerCtrl;
  late final AnimationController _searchCtrl;
  late final AnimationController _listCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double>  _headerFade;
  late final Animation<Offset>  _headerSlide;
  late final Animation<double>  _searchFade;
  late final Animation<Offset>  _searchSlide;

  final TextEditingController _searchText  = TextEditingController();
  final ScrollController      _scrollCtrl  = ScrollController();
  bool _isScrolled  = false;
  String _searchQuery = '';

  // ── Init ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _searchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _listCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _pulseCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);

    _headerFade  = CurvedAnimation(parent: _headerCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut));
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl,
            curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic)));
    _searchFade  = CurvedAnimation(parent: _searchCtrl, curve: Curves.easeOut);
    _searchSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _searchCtrl, curve: Curves.easeOutCubic));

    _scrollCtrl.addListener(() {
      final scrolled = _scrollCtrl.offset > 6;
      if (scrolled != _isScrolled && mounted) setState(() => _isScrolled = scrolled);
    });

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _searchCtrl.forward();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) fetchPendingLeaves();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _searchCtrl.dispose();
    _listCtrl.dispose();
    _pulseCtrl.dispose();
    _searchText.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── API ───────────────────────────────────────────────────────────────────
Future<void> fetchPendingLeaves() async {
  if (!mounted) return;
  setState(() => isLoading = true);
  _listCtrl.reset();

  try {
    final url = 'http://172.31.16.69/api/v1/leave-pending/authority';
    final payload = {
      'authority_type': widget.authorityType,
      'authority_id': widget.authorityId.toString(),
    };
    debugPrint('POST $url');
    debugPrint('Body: ${jsonEncode(payload)}');

    final res = await http.post(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    debugPrint('Status: ${res.statusCode}');
    debugPrint('Response: ${res.body}');

    if (!mounted) return;
    if (res.statusCode == 200) {
      final data = (jsonDecode(res.body)['data'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      setState(() {
        allLeaves      = data;
        filteredLeaves = data;
      });
      await Future.delayed(const Duration(milliseconds: 60));
      if (mounted) _listCtrl.forward();
    } else {
      _snack('Failed to load leave requests');
    }
  } catch (e) {
    debugPrint('Error: $e');
    if (mounted) _snack('Connection error');
  }
  if (mounted) setState(() => isLoading = false);
}
  
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.info_outline_rounded, color: Colors.white, size: 15),
        const SizedBox(width: 8),
        Text(msg, style: _T.label(size: 13, color: Colors.white)),
      ]),
      backgroundColor: _T.textPrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  void _onSearch(String q) {
    _searchQuery = q;
    final lower = q.toLowerCase();
    setState(() {
      filteredLeaves = lower.isEmpty
          ? allLeaves
          : allLeaves.where((l) =>
              (l['staff_name'] ?? '').toString().toLowerCase().contains(lower) ||
              (l['reason'] ?? '').toString().toLowerCase().contains(lower) ||
              ((l['leave_type']['name'] ?? '').toString().toLowerCase()).contains(lower),
            ).toList();
    });
    _listCtrl.reset();
    _listCtrl.forward();
  }

  String _fmt(String? s) {
    if (s == null) return '';
    try { return DateFormat('MMM d').format(DateTime.parse(s)); } catch (_) { return s; }
  }

  // ── Avatar zoom ───────────────────────────────────────────────────────────
  void _zoomAvatar(dynamic staffId, String name) {
    HapticFeedback.lightImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (_, anim, __) =>
          _AvatarZoomDialog(staffId: staffId, name: name, animation: anim),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _T.bg,
      body: Column(
        children: [
          // ── Sticky top bar ────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: _T.bg,
              boxShadow: _isScrolled ? _T.headerShadow : [],
              border: _isScrolled
                  ? Border(bottom: BorderSide(color: _T.divider, width: 0.5))
                  : const Border(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: topPad + 4),

                // Back button row
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 16, 0),
                  child: _MetaBackButton(onTap: () => Navigator.pop(context)),
                ),

                // Title + refresh
                FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 16, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Leave Requests',
                                    style: _T.heading(size: 20, w: FontWeight.w800)),
                                const SizedBox(height: 3),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 280),
                                  child: Text(
                                    isLoading
                                        ? 'Loading…'
                                        : '${filteredLeaves.length} pending request${filteredLeaves.length == 1 ? '' : 's'}',
                                    key: ValueKey('${isLoading}_${filteredLeaves.length}'),
                                    style: _T.label(size: 13, color: _T.textTertiary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _RefreshButton(
                            isLoading: isLoading,
                            pulseCtrl: _pulseCtrl,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              fetchPendingLeaves();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Search bar
                FadeTransition(
                  opacity: _searchFade,
                  child: SlideTransition(
                    position: _searchSlide,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: _MetaSearchBar(
                        controller: _searchText,
                        onChanged: _onSearch,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── List / empty / shimmer ────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve:  Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: isLoading
                  ? _buildShimmerList()
                  : filteredLeaves.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: _T.metaBlue,
                          onRefresh: fetchPendingLeaves,
                          child: ListView.builder(
                            key: ValueKey(filteredLeaves.length),
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
                            itemCount: filteredLeaves.length,
                            itemBuilder: (_, i) => _buildCard(filteredLeaves[i], i),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Card ──────────────────────────────────────────────────────────────────
  Widget _buildCard(Map<String, dynamic> leave, int index) {
    final type   = _resolveLeaveType(leave['leave_type']['name']?.toString());
    final delay  = (index * 0.065).clamp(0.0, 0.65);
    final end    = (delay + 0.32).clamp(0.0, 1.0);

    final fade  = CurvedAnimation(parent: _listCtrl,
        curve: Interval(delay, end, curve: Curves.easeOut));
    final slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _listCtrl,
            curve: Interval(delay, end, curve: Curves.easeOutCubic)));

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: _TappableCard(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pushNamed(
              context,
              leaveDetailsScreenRoute,
              arguments: leave['id'].toString(),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with zoom
                _ZoomableAvatar(
                  staffId:   leave['staff_id'],
                  staffName: leave['staff_name'] ?? '',
                  onTap: () => _zoomAvatar(leave['staff_id'], leave['staff_name'] ?? ''),
                ),
                const SizedBox(width: 13),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + date row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              leave['staff_name'] ?? '',
                              style: _T.heading(size: 14, w: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _fmt(leave['created_at']),
                            style: _T.label(size: 11, color: _T.textTertiary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Leave type chip
                      _LeaveChip(
                        label: leave['leave_type']['name'] ?? 'Leave',
                        icon:  type.icon,
                        bg:    type.bg,
                        fg:    type.fg,
                      ),
                      const SizedBox(height: 7),

                      // Reason
                      Text(
                        leave['reason'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _T.label(size: 13, color: _T.textSecondary),
                      ),
                    ],
                  ),
                ),

                // Chevron
                const Padding(
                  padding: EdgeInsets.only(left: 6, top: 1),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 18, color: _T.textTertiary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _T.metaBlueSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_outlined,
                size: 32, color: _T.metaBlue),
          ),
          const SizedBox(height: 16),
          Text('No requests found',
              style: _T.heading(size: 16, w: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            _searchQuery.isEmpty
                ? 'Pull down to refresh'
                : 'Try a different search',
            style: _T.label(size: 13, color: _T.textTertiary),
          ),
        ],
      ),
    );
  }

  // ── Shimmer list ──────────────────────────────────────────────────────────
  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: 6,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _ShimmerCard(delayMs: i * 70),
      ),
    );
  }
}

// ─── Meta Back Button ─────────────────────────────────────────────────────────
class _MetaBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _MetaBackButton({required this.onTap});
  @override
  State<_MetaBackButton> createState() => _MetaBackButtonState();
}

class _MetaBackButtonState extends State<_MetaBackButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 110));

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown:   (_) => _c.forward(),
        onTapUp:     (_) { _c.reverse(); widget.onTap(); },
        onTapCancel: () => _c.reverse(),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) =>
              Transform.scale(scale: 1.0 - _c.value * 0.1, child: child),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _T.surface,
              shape: BoxShape.circle,
              boxShadow: _T.cardShadow,
              border: Border.all(color: _T.divider, width: 0.5),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 14, color: _T.textPrimary),
          ),
        ),
      );
}

// ─── Refresh Button ───────────────────────────────────────────────────────────
class _RefreshButton extends StatelessWidget {
  final bool isLoading;
  final AnimationController pulseCtrl;
  final VoidCallback onTap;

  const _RefreshButton({
    required this.isLoading,
    required this.pulseCtrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, child) => Transform.scale(
        scale: isLoading ? 1.0 : 1.0 + pulseCtrl.value * 0.035,
        child: child,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isLoading ? _T.metaBlueSoft : _T.surface,
            shape: BoxShape.circle,
            boxShadow: _T.cardShadow,
            border: Border.all(color: _T.divider, width: 0.5),
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _T.metaBlue),
                )
              : const Icon(Icons.refresh_rounded,
                  size: 18, color: _T.textSecondary),
        ),
      ),
    );
  }
}

// ─── Meta Search Bar ──────────────────────────────────────────────────────────
class _MetaSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _MetaSearchBar({required this.controller, required this.onChanged});

  @override
  State<_MetaSearchBar> createState() => _MetaSearchBarState();
}

class _MetaSearchBarState extends State<_MetaSearchBar> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(24), // Pill shape — Meta style
          boxShadow: _T.cardShadow,
          border: Border.all(
            color: _focused ? _T.metaBlue.withOpacity(0.4) : _T.divider,
            width: _focused ? 1.5 : 0.5,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          style: _T.label(size: 14, color: _T.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search requests…',
            hintStyle: _T.label(size: 14, color: _T.textPlaceholder),
            prefixIcon: Icon(Icons.search_rounded,
                size: 18,
                color: _focused ? _T.metaBlue : _T.textTertiary),
            suffixIcon: AnimatedOpacity(
              opacity: widget.controller.text.isEmpty ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 180),
              child: IconButton(
                icon: const Icon(Icons.cancel_rounded,
                    size: 17, color: _T.textTertiary),
                onPressed: () {
                  widget.controller.clear();
                  widget.onChanged('');
                },
              ),
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          ),
        ),
      ),
    );
  }
}

// ─── Tappable Card ────────────────────────────────────────────────────────────
class _TappableCard extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _TappableCard({required this.onTap, required this.child});
  @override
  State<_TappableCard> createState() => _TappableCardState();
}

class _TappableCardState extends State<_TappableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 110));

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown:   (_) => _c.forward(),
        onTapUp:     (_) { _c.reverse(); widget.onTap(); },
        onTapCancel: () => _c.reverse(),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) =>
              Transform.scale(scale: 1.0 - _c.value * 0.018, child: child),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(16),
              // boxShadow: _T.cardShadow,
              border: Border.all(color: _T.divider, width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: widget.child,
            ),
          ),
        ),
      );
}

// ─── Zoomable Avatar ─────────────────────────────────────────────────────────
class _ZoomableAvatar extends StatefulWidget {
  final dynamic staffId;
  final String staffName;
  final VoidCallback onTap;

  const _ZoomableAvatar({
    required this.staffId,
    required this.staffName,
    required this.onTap,
  });

  @override
  State<_ZoomableAvatar> createState() => _ZoomableAvatarState();
}

class _ZoomableAvatarState extends State<_ZoomableAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 130));

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  String _initials(String n) => n.trim().split(' ').take(2)
      .map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _c.forward(),
      onTapUp:     (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) =>
            Transform.scale(scale: 1.0 - _c.value * 0.12, child: child),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            // Avatar circle
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _T.metaBlueSoft,
                boxShadow: _T.avatarShadow,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: ClipOval(
                child: Image.network(
                  'https://fo2-staff-search.dswd.gov.ph/images/${widget.staffId}.jpg',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      _initials(widget.staffName),
                      style: _T.label(size: 13, w: FontWeight.w800, color: _T.metaBlue),
                    ),
                  ),
                ),
              ),
            ),
            // Zoom hint badge
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(bottom: 1, right: 1),
              decoration: BoxDecoration(
                color: _T.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3),
                ],
              ),
              child: const Icon(Icons.zoom_in_rounded, size: 10, color: _T.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Leave Type Chip ─────────────────────────────────────────────────────────
class _LeaveChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg, fg;

  const _LeaveChip({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fg,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      );
}

// ─── Shimmer Card ─────────────────────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  final int delayMs;
  const _ShimmerCard({this.delayMs = 0});
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));
  late final Animation<double> _anim =
      CurvedAnimation(parent: _c, curve: Curves.easeInOut);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.repeat(reverse: true);
    });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  Widget _bone(double w, double h, {double r = 8}) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          color: Color.lerp(
            const Color(0xFFE4E6EB),
            const Color(0xFFF0F2F5),
            _anim.value,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _T.cardShadow,
          border: Border.all(color: _T.divider, width: 0.5),
        ),
        child: Row(children: [
          _bone(50, 50, r: 25),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bone(130, 13),
                const SizedBox(height: 8),
                _bone(76, 22),
                const SizedBox(height: 8),
                _bone(double.infinity, 11),
              ],
            ),
          ),
        ]),
      );
}

// ─── Avatar Zoom Dialog ───────────────────────────────────────────────────────
class _AvatarZoomDialog extends StatelessWidget {
  final dynamic staffId;
  final String name;
  final Animation<double> animation;

  const _AvatarZoomDialog({
    required this.staffId,
    required this.name,
    required this.animation,
  });

  String _initials(String n) => n.trim().split(' ').take(2)
      .map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) {
        final t = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic).value;
        return Opacity(
          opacity: t,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: t * 22, sigmaY: t * 22),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black.withOpacity(0.55),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name — slides up
                AnimatedBuilder(
                  animation: animation,
                  builder: (_, child) {
                    final t = CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic).value;
                    return Transform.translate(
                      offset: Offset(0, (1 - t) * 18),
                      child: Opacity(opacity: t, child: child),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ),

                // Photo — spring scale
                AnimatedBuilder(
                  animation: animation,
                  builder: (_, child) {
                    final t = CurvedAnimation(
                        parent: animation, curve: Curves.easeOutBack).value;
                    return Transform.scale(scale: 0.72 + t * 0.28, child: child);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.25), width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.45),
                          blurRadius: 48,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        'https://fo2-staff-search.dswd.gov.ph/images/$staffId.jpg',
                        width: 220,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 220,
                          height: 220,
                          color: _T.metaBlueSoft,
                          child: Center(
                            child: Text(
                              _initials(name),
                              style: const TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.w800,
                                color: _T.metaBlue,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Dismiss hint
                AnimatedBuilder(
                  animation: animation,
                  builder: (_, child) => Opacity(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: const Interval(0.5, 1.0),
                    ).value,
                    child: child,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.15), width: 0.5),
                    ),
                    child: const Text(
                      'Tap anywhere to close',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
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