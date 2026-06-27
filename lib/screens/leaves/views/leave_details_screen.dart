import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shop/components/leave/leave_icon.dart';
import 'package:shop/components/modal/success_modal.dart';
import 'package:shop/components/resuable_webapp_view.dart';
import 'package:shop/providers/auth_provider.dart';
import 'package:shop/route/screen_export.dart';



class LeaveDetailScreen extends ConsumerStatefulWidget {
  final String leaveId;

  const LeaveDetailScreen({super.key, required this.leaveId});

  @override
  ConsumerState<LeaveDetailScreen> createState() => _LeaveDetailScreenState();
}

class _LeaveDetailScreenState extends ConsumerState<LeaveDetailScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? leave;
  bool isLoading = true;
  String? error;
  bool actionLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    fetchLeaveDetails();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _startEntryAnimations() {
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> updateLeaveStatus(
    String action,
    String remarks,
    String staffName,
    int staffId,
  ) async {
    setState(() => actionLoading = true);
    try {
      Uri url;
      if (action == 'approve') {
        url = Uri.parse(
            'http://172.31.16.69/api/v1/leave-pending/${widget.leaveId}/approve');
      } else if (action == 'disapproved') {
        url = Uri.parse(
            'http://172.31.16.69/api/v1/leave-pending/${widget.leaveId}/reject');
      } else {
        throw Exception('Unknown action');
      }

      final response = await http.post(url, headers: {
        // 'Authorization': 'Bearer YOUR_ACCESS_TOKEN',
        'Accept': 'application/json',
      }, body: {
        'remarks': remarks,
        'staff_name': staffName, // ✅ from authProvider
        'staff_id': staffId.toString(),     // ✅ from authProvider
      });

      if (response.statusCode == 200) {
        await SuccessModal.show(
          context,
          message: 'Leave approved successfully',
          description: 'Your leave request has been approved.',
          assetImage: 'assets/images/success.png',
          onDone: () => Navigator.pushNamed(context, leavesScreenRoute),
        );
      } else {
        await SuccessModal.show(
          context,
          message: 'Leave approved failed',
          description: 'Something went wrong while processing the leave request.',
          assetImage: 'assets/images/error.png',
          onDone: () => Navigator.pushNamed(context, leavesScreenRoute),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    setState(() => actionLoading = false);
  }

  Future<void> fetchLeaveDetails() async {
    try {
      final url = Uri.parse(
          'http://172.31.16.69/api/v1/leave-requests/${widget.leaveId}');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // DEBUG - remove after fix
        debugPrint('=== RAW API RESPONSE ===');
        debugPrint(response.body);
        debugPrint('========================');

        setState(() {
          leave = Map<String, dynamic>.from(data['data']);
          isLoading = false;
        });
        _startEntryAnimations();
      } else {
        setState(() {
          error = 'Failed to load leave (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {          // 👈 add stackTrace
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stackTrace'); // 👈 this shows the exact line
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  String getWeekday(String date) {
    try {
      return DateFormat('EEE').format(DateTime.parse(date));
    } catch (_) {
      return '';
    }
  }

  void _showLeaveModal({
    required BuildContext context,
    required String action,
    required String description,
    required Color accentColor,
    required String staffName,
    required String leaveType,
    required String? imageUrl,
  }) {
    String remarks = '';
    final isApprove = action == 'approve';

    // ✅ Read auth user before entering modal builder
    final authUser = ref.read(authProvider);
    final approverName = authUser?.fullName ?? 'Unknown';
    final approverId = (authUser?.staffId ?? 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF0F2F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grabber pill
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCDD1D8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // White card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar + name + leave type
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: accentColor.withOpacity(0.25),
                                  width: 2.5),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                imageUrl ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFF0F2F5),
                                  child: const Icon(Icons.person_rounded,
                                      color: Color(0xFF8A8D91), size: 26),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  staffName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF050505),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    leaveType,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFF0F2F5)),
                      const SizedBox(height: 14),

                      // Description
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF65676B),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Remarks input
                      TextField(
                        maxLines: 3,
                        onChanged: (v) => remarks = v,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF050505),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add a remark (optional)...',
                          hintStyle: const TextStyle(
                            color: Color(0xFFBCC0C4),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF0F2F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: accentColor.withOpacity(0.5),
                                width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Confirm button
                _MetaButton(
                  label: isApprove ? 'Confirm Approve' : 'Confirm Disapprove',
                  backgroundColor: accentColor,
                  textColor: Colors.white,
                  onTap: () {
                    Navigator.pop(context);
                    updateLeaveStatus(action, remarks, approverName, approverId); // ✅
                  },
                ),

                const SizedBox(height: 8),

                // Cancel button
                _MetaButton(
                  label: 'Cancel',
                  backgroundColor: Colors.white,
                  textColor: const Color(0xFF050505),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: _MetaLoadingState(),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFE2420E), size: 48),
              const SizedBox(height: 12),
              Text('Error: $error',
                  style: const TextStyle(color: Color(0xFF65676B))),
            ],
          ),
        ),
      );
    }

    if (leave == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Leave not found')),
      );
    }

    final leaveTypeId = leave!['leave_type_id'] as int? ?? 0;
    final leaveType = (leave!['leave_type'] as Map<String, dynamic>?)?['name']
        ?? leaveTypeNames[leave!['leave_type_id'] as int? ?? 0]
        ?? 'Unknown Leave';
    const leaveColor =  Colors.black;
    final totalDays = leave!['total_days'];
    final applicationDate = leave!['created_at'] ?? '-';
    final leaveDates = leave!['leave_dates'] != null
        ? (jsonDecode(leave!['leave_dates']) as List? ?? [])
        : <dynamic>[];
    final staffImageUrl =
        'https://fo2-staff-search.dswd.gov.ph/images/${leave!['staff_id']}.jpg';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Stack(
            children: [
              // Scrollable body
              Padding(
                padding: const EdgeInsets.only(bottom: 88),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),

                    // Leave summary hero card
                    SliverToBoxAdapter(
                      child: _AnimatedCard(
                        delay: const Duration(milliseconds: 80),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      leaveIconCard(leaveType,52,52),
                                      const SizedBox(height: 12),
                                      Text(
                                        leaveType,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: leaveColor,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '☁️',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF65676B),
                                        ),
                                      ),
                                      Text('Day${(double.tryParse(totalDays?.toString() ?? '') ?? 0) == 1.0 ? '' : 's'} requested',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF65676B),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                          totalDays != null
                                              ? double.tryParse(totalDays.toString())?.toStringAsFixed(2) ?? '-'
                                              : '-',
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w800,
                                          color: leaveColor,
                                          letterSpacing: -1.5,
                                          height: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Reason card
                    SliverToBoxAdapter(
                      child: _AnimatedCard(
                        delay: const Duration(milliseconds: 140),
                        child: _SectionCard(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                  label: 'Reason for Leave',
                                  textBadge: '📓',
                                  color: leaveColor),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F8FA),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  leave!['reason'] ?? '—',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF444950),
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Leave dates card
                    SliverToBoxAdapter(
                      child: _AnimatedCard(
                        delay: const Duration(milliseconds: 200),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF111111), Color(0xFF2E2E2E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Text('📅', style: TextStyle(fontSize: 16)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Selected Dates',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Container(
                                    height: 0.5,
                                    color: Colors.white.withOpacity(0.12)),
                                const SizedBox(height: 14),
                                ...leaveDates.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final d = entry.value;
                                  final date = d['date'] ?? '-';
                                  final type = d['type'] ?? '';
                                  final weekday = getWeekday(date);

                                  String formattedDate = '-';
                                  try {
                                    formattedDate = DateFormat('MMMM dd, yyyy')
                                        .format(DateTime.parse(date));
                                  } catch (_) {}

                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: Duration(
                                        milliseconds: 300 + (idx * 60)),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, val, child) =>
                                        Opacity(opacity: val, child: child),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.10),
                                            width: 0.5),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withOpacity(0.10),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.calendar_today_rounded,
                                              size: 18,
                                              color: Colors.white
                                                  .withOpacity(0.85),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  weekday,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  formattedDate,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white
                                                        .withOpacity(0.55),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.18),
                                                  width: 0.5),
                                            ),
                                            child: Text(
                                              type
                                                  .toUpperCase()
                                                  .replaceAll('_', ' '),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white
                                                    .withOpacity(0.90),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Attachments card
                    if (leave!['attachments'] != null &&
                        (leave!['attachments'] as List?)?.isNotEmpty == true)
                      SliverToBoxAdapter(
                        child: _AnimatedCard(
                          delay: const Duration(milliseconds: 260),
                          child: _SectionCard(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionHeader(
                                    label: 'Attachments',
                                    icon: Icons.attach_file_rounded,
                                    color: leaveColor),
                                const SizedBox(height: 12),
                                ...leave!['attachments'].map((a) {
                                  final url = Uri.encodeFull(
                                      'https://172.31.16.68/${a['path']}');
                                  return GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReusableWebViewScreen(
                                          url: url,
                                          title: a['path'],
                                        ),
                                      ),
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F2F5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFFE4E6EB)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color:
                                                  leaveColor.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                                Icons.description_rounded,
                                                size: 18,
                                                color: leaveColor),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              a['path'],
                                              style: TextStyle(
                                                color: leaveColor,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(Icons.chevron_right_rounded,
                                              size: 18,
                                              color:
                                                  leaveColor.withOpacity(0.6)),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  ],
                ),
              ),

              // Sticky Header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    8,
                    8 + MediaQuery.of(context).padding.top,
                    16,
                    12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: const Color(0xFF050505),
                        iconSize: 20,
                        splashRadius: 22,
                        onPressed: () =>
                            Navigator.pushNamed(context, leavesScreenRoute),
                      ),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: leaveColor.withOpacity(0.3), width: 2),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            staffImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFF0F2F5),
                              child: const Icon(Icons.person_rounded,
                                  color: Color(0xFF8A8D91), size: 22),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              leave!['staff_name'] ?? 'No Name',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF050505),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Applied ${applicationDate.split('T')[0]}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8A8D91),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Sticky Bottom Buttons
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Disapprove',
                              foregroundColor: const Color(0xFFE2420E),
                              backgroundColor: const Color(0xFFFFF0ED),
                              isLoading: actionLoading,
                              onTap: actionLoading
                                  ? null
                                  : () => _showLeaveModal(
                                        context: context,
                                        action: 'disapproved',
                                        staffName:
                                            leave!['staff_name'] ?? 'No Name',
                                        leaveType: leaveType,
                                        imageUrl: staffImageUrl,
                                        description:
                                            'Are you sure you want to disapproved this leave? You can add optional remarks below.',
                                        accentColor: const Color(0xFFE2420E),
                                      ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: _ActionButton(
                              label: 'Approve Now',
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF0866FF),
                              isLoading: actionLoading,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              onTap: actionLoading
                                  ? null
                                  : () => _showLeaveModal(
                                        context: context,
                                        action: 'approve',
                                        staffName:
                                            leave!['staff_name'] ?? 'No Name',
                                        leaveType: leaveType,
                                        imageUrl: staffImageUrl,
                                        description:
                                            'Are you sure you want to approve this leave? You can add optional remarks below.',
                                        accentColor: const Color(0xFF0866FF),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _MetaLoadingState extends StatefulWidget {
  const _MetaLoadingState();

  @override
  State<_MetaLoadingState> createState() => _MetaLoadingStateState();
}

class _MetaLoadingStateState extends State<_MetaLoadingState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF0866FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.event_note_rounded,
                  color: Color(0xFF0866FF), size: 28),
            ),
            const SizedBox(height: 14),
            const Text(
              'Loading leave details...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF65676B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedCard({required this.child, required this.delay});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
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
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;

  const _SectionCard({required this.child, required this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}


class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? textBadge;
  final Color color;

  const _SectionHeader({
    required this.label,
    required this.color,
    this.icon,
    this.textBadge,
  }) : assert(icon != null || textBadge != null,
            'Provide either icon or textBadge');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: icon != null
              ? Icon(icon, size: 16, color: color)
              : Text(
                  textBadge!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF050505),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final bool isLoading;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final double borderRadius;
  final double? height;

  const _ActionButton({
    required this.label,
    this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.isLoading,
    this.onTap,
    this.padding,
    this.borderRadius = 100,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onTap == null || isLoading;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: isDisabled ? 0.6 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: double.infinity,
          height: height ?? 55,
          alignment: Alignment.center,
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: foregroundColor,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: foregroundColor),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: foregroundColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _MetaButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const _MetaButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: backgroundColor == Colors.white
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}