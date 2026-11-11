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

import '../../../services/api_config.dart';

// ─── Safe parsing helpers ─────────────────────────────────────────────────
// The backend (PHP/Laravel) can return different shapes per leave type
// (e.g. `[]` instead of `{}`, a JSON string instead of a list). These
// helpers make sure a bad shape never crashes the screen.

int _toInt(dynamic v, [int fallback = 0]) =>
    v is int ? v : int.tryParse(v?.toString() ?? '') ?? fallback;

Map<String, dynamic> _toMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<dynamic> _toList(dynamic v) {
  if (v is List) return v;
  if (v is String && v.trim().isNotEmpty) {
    try {
      final d = jsonDecode(v);
      if (d is List) return d;
      if (d is String) return _toList(d); // double-encoded JSON
    } catch (_) {}
  }
  return <dynamic>[];
}

// ─── Timeline Models ──────────────────────────────────────────────────────

class LeaveRemarkItem {
  final String staffName, stage, remarks, action, createdAt;
  final int? staffId;
  const LeaveRemarkItem({
    required this.staffName,
    required this.stage,
    required this.remarks,
    required this.action,
    required this.createdAt,
    this.staffId,
  });

  factory LeaveRemarkItem.fromJson(Map<String, dynamic> j) => LeaveRemarkItem(
    staffName: (j['staff_name'] ?? '').toString(),
    stage: (j['stage'] ?? '').toString(),
    remarks: (j['remarks'] ?? '').toString(),
    action: (j['action'] ?? '').toString(),
    createdAt: (j['created_at'] ?? '').toString(),
    staffId: j['staff_id'] is int
        ? j['staff_id']
        : int.tryParse(j['staff_id']?.toString() ?? ''),
  );
}

class ApprovalStepItem {
  final String title, subtitle, timestamp, stageKey;
  final List<LeaveRemarkItem> remarks;
  final bool isCurrent;

  const ApprovalStepItem({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.stageKey,
    this.remarks = const [],
    this.isCurrent = false,
  });

  // Done = timestamp was set AND this isn't the stage the request is
  bool get isDone => timestamp.isNotEmpty && !isCurrent;
  bool get hasRemarks => remarks.isNotEmpty;

  DateTime? get _parsedDate {
    if (timestamp.isEmpty) return null;
    try {
      return DateTime.parse(timestamp);
    } catch (_) {
      return null;
    }
  }

  String get date {
    final d = _parsedDate;
    if (d == null) return '';
    return DateFormat('MMM d, yyyy').format(d);
  }

  String get time {
    final d = _parsedDate;
    if (d == null) return '';
    return DateFormat('h:mm a').format(d).toLowerCase();
  }
}

// ─── Attachment Model ─────────────────────────────────────────────────────

class LeaveAttachmentItem {
  final int id;
  final String path, fileType, createdAt;

  const LeaveAttachmentItem({
    required this.id,
    required this.path,
    required this.fileType,
    required this.createdAt,
  });

  factory LeaveAttachmentItem.fromJson(Map<String, dynamic> j) {
    final rawPath = (j['path'] ?? '').toString();
    final rawType = (j['file_type'] ?? '').toString();
    final resolvedType =
    rawType.isNotEmpty ? rawType : rawPath.split('.').last.toLowerCase();
    return LeaveAttachmentItem(
      id: _toInt(j['id']),
      path: rawPath,
      fileType: resolvedType,
      createdAt: (j['created_at'] ?? '').toString(),
    );
  }

  static const _base = 'https://fo2-staff-search.dswd.gov.ph/';
  String get fullUrl => Uri.encodeFull('$_base$path');

  bool get isImage =>
      fileType == 'jpg' ||
          fileType == 'jpeg' ||
          fileType == 'png' ||
          fileType == 'webp';

  bool get isPdf => fileType == 'pdf';

  String get fileName => path.isNotEmpty ? path.split('/').last : 'Attachment';

  IconData get icon {
    if (isPdf) return Icons.picture_as_pdf_rounded;
    if (isImage) return Icons.image_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color get iconColor {
    if (isPdf) return const Color(0xFFDC2626);
    if (isImage) return const Color(0xFF7C3AED);
    return Colors.black;
  }

  Color get iconBg {
    if (isPdf) return const Color(0xFFFEE2E2);
    if (isImage) return const Color(0xFFEDE9FE);
    return const Color(0xFFF0F2F5);
  }
}

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
            '${ApiConfig.leaveBase}/leave-pending/${widget.leaveId}/approve');
      } else if (action == 'disapproved') {
        url = Uri.parse(
            '${ApiConfig.leaveBase}/leave-pending/${widget.leaveId}/reject');
      } else {
        throw Exception('Unknown action');
      }

      final response = await http.post(url, headers: {
        // 'Authorization': 'Bearer YOUR_ACCESS_TOKEN',
        'Accept': 'application/json',
      }, body: {
        'remarks': remarks,
        'staff_name': staffName,
        'staff_id': staffId.toString(),
      });

      if (!mounted) return;
      final isApprove = action == 'approve';

      if (response.statusCode == 200) {
        await SuccessModal.show(
          context,
          message: isApprove
              ? 'Leave approved successfully'
              : 'Leave disapproved successfully',
          description: isApprove
              ? 'Your leave request has been approved.'
              : 'The leave request has been disapproved.',
          assetImage: 'assets/images/success.png',
          onDone: () => Navigator.pushNamed(context, leavesScreenRoute),
        );
      } else {
        debugPrint(response.body);
        await SuccessModal.show(
          context,
          message:
          isApprove ? 'Leave approval failed' : 'Leave disapproval failed',
          description:
          'Something went wrong while processing the leave request.',
          assetImage: 'assets/images/error.png',
          onDone: () => Navigator.pushNamed(context, leavesScreenRoute),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
    if (mounted) setState(() => actionLoading = false);
  }

  Future<void> fetchLeaveDetails() async {
    try {
      final url = Uri.parse(
          '${ApiConfig.leaveBase}/leave-requests/${widget.leaveId}');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // DEBUG - remove after fix
        debugPrint('=== RAW API RESPONSE ===');
        debugPrint(response.body);
        debugPrint('========================');

        if (!mounted) return;
        setState(() {
          leave = _toMap(data['data']);
          isLoading = false;
        });
        _startEntryAnimations();
      } else {
        if (!mounted) return;
        setState(() {
          error = 'Failed to load leave (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stackTrace');
      if (!mounted) return;
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

  /// Builds the approval timeline steps from the raw `leave` map,
  /// attaching any matching remarks per stage.
  List<ApprovalStepItem> _buildTimeline() {
    if (leave == null) return [];

    // `approvals` may arrive as `[]` (empty PHP array) instead of `{}`
    final approvals = _toMap(leave!['approvals']);
    final allRemarks = _toList(leave!['remarks'])
        .whereType<Map>()
        .map((r) => LeaveRemarkItem.fromJson(Map<String, dynamic>.from(r)))
        .toList();

    final currentStatus = (leave!['status'] ?? '').toString();

    final steps = <ApprovalStepItem>[];

    void add(String title, String subtitle, String stageKey, String? ts) {
      final stageRemarks =
      allRemarks.where((r) => r.stage == stageKey).toList();
      steps.add(ApprovalStepItem(
        title: title,
        subtitle: subtitle,
        timestamp: ts ?? '',
        stageKey: stageKey,
        remarks: stageRemarks,
        isCurrent: stageKey == currentStatus,
      ));
    }

    add('Request Submitted', 'Leave request was filed.', 'on_draft',
        leave!['created_at']?.toString());

    add(
      'HR Review',
      'For review by Human Resources.',
      'for_hr_review',
      approvals['for_hr_review']?.toString(),
    );

    add(
      'HR DC Review',
      'For review by HRMDD Division Chief.',
      'for_hr_dc_review',
      approvals['for_hr_dc_review']?.toString(),
    );

    add(
      'DC Review',
      'For review by your Division Chief.',
      'for_supervisor_review',
      approvals['for_supervisor_review']?.toString(),
    );

    add(
      'Approval Review',
      'Final review by the approver.',
      'for_approval',
      approvals['for_approval']?.toString(),
    );

    if (approvals['approved'] != null) {
      add('Approved', 'Leave fully approved. Enjoy your time off!', 'approved',
          approvals['approved']?.toString());
    } else if (approvals['disapproved'] != null) {
      final notes = (leave!['computation_notes'] ?? '').toString();
      add(
        'Disapproved',
        notes.isNotEmpty ? notes : 'Leave request was disapproved.',
        'disapproved',
        approvals['disapproved']?.toString(),
      );
    } else if (approvals['cancelled'] != null) {
      add('Cancelled', 'This leave request was cancelled.', 'cancelled',
          approvals['cancelled']?.toString());
    }

    return steps;
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

    // Read auth user before entering modal builder
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
                    updateLeaveStatus(
                        action, remarks, approverName, approverId);
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

    // ── Safe reads (no unchecked casts) ─────────────────────────────
    final leaveTypeMap = _toMap(leave!['leave_type']);
    final leaveTypeId = _toInt(leave!['leave_type_id']);
    final leaveType = (leaveTypeMap['name']?.toString().isNotEmpty ?? false)
        ? leaveTypeMap['name'].toString()
        : (leaveTypeNames[leaveTypeId] ?? 'Unknown Leave');

    // Always black, regardless of leave type
    const Color leaveColor = Colors.black;

    final totalDays = leave!['total_days'];
    final applicationDate = (leave!['created_at'] ?? '-').toString();

    final leaveDates = _toList(leave!['leave_dates'])
        .map<Map<String, dynamic>>((d) => d is Map
        ? Map<String, dynamic>.from(d)
        : {'date': d.toString(), 'type': ''})
        .toList();

    final staffName = (leave!['staff_name'] ?? 'No Name').toString();
    final staffImageUrl =
        'https://fo2-staff-search.dswd.gov.ph/images/${leave!['staff_id']}.jpg';

    final attachments = _toList(leave!['attachments'])
        .whereType<Map>()
        .map((a) => LeaveAttachmentItem.fromJson(Map<String, dynamic>.from(a)))
        .toList();

    final timeline = _buildTimeline();
    final totalRemarks =
    timeline.fold<int>(0, (sum, s) => sum + s.remarks.length);

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
                                      // Guarded so a bad leave type can
                                      // never blank the whole page
                                      Builder(builder: (_) {
                                        try {
                                          return leaveIconCard(
                                              leaveType, 52, 52);
                                        } catch (_) {
                                          return Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0F2F5),
                                              borderRadius:
                                              BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                                Icons.event_note_rounded,
                                                color: Colors.black),
                                          );
                                        }
                                      }),
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
                                      Text(
                                        'Day${(double.tryParse(totalDays?.toString() ?? '') ?? 0) == 1.0 ? '' : 's'} requested',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF65676B),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        totalDays != null
                                            ? double.tryParse(
                                            totalDays.toString())
                                            ?.toStringAsFixed(2) ??
                                            '-'
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
                                  (leave!['reason'] ?? '—').toString(),
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
                                  final date = (d['date'] ?? '-').toString();
                                  final type = (d['type'] ?? '').toString();
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
                                          if (type.isNotEmpty)
                                            Container(
                                              padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4),
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

                    // Approval Timeline card
                    if (timeline.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _AnimatedCard(
                          delay: const Duration(milliseconds: 230),
                          child: _SectionCard(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _SectionHeader(
                                      label: 'Approval Timeline',
                                      icon: Icons.timeline_rounded,
                                      color: leaveColor,
                                    ),
                                    const Spacer(),
                                    if (totalRemarks > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE7F0FF),
                                          borderRadius:
                                          BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '$totalRemarks remark${totalRemarks == 1 ? '' : 's'}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0866FF),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _TimelineWithRemarks(steps: timeline),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Attachments card
                    if (attachments.isNotEmpty)
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
                                _AttachmentsList(attachments: attachments),
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
                              staffName,
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

              // Floating Approve/Disapprove bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.14),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
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
                              staffName: staffName,
                              leaveType: leaveType,
                              imageUrl: staffImageUrl,
                              description:
                              'Are you sure you want to disapprove this leave? You can add optional remarks below.',
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            onTap: actionLoading
                                ? null
                                : () => _showLeaveModal(
                              context: context,
                              action: 'approve',
                              staffName: staffName,
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

// ════════════════════════════════════════════════════
// ATTACHMENTS
// ════════════════════════════════════════════════════

class _AttachmentsList extends StatelessWidget {
  final List<LeaveAttachmentItem> attachments;
  const _AttachmentsList({required this.attachments});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: attachments.asMap().entries.map((e) {
        final isLast = e.key == attachments.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
          child: _AttachmentTile(attachment: e.value),
        );
      }).toList(),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final LeaveAttachmentItem attachment;
  const _AttachmentTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReusableWebViewScreen(
            url: attachment.fullUrl,
            title: attachment.fileName,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E6EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: attachment.iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
              Icon(attachment.icon, size: 18, color: attachment.iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.fileName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (attachment.fileType.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      attachment.fileType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: attachment.iconColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: Colors.black.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// APPROVAL TIMELINE — Dot Stepper (matches LeaveActionScreen)
// ════════════════════════════════════════════════════

class _TimelineWithRemarks extends StatelessWidget {
  final List<ApprovalStepItem> steps;
  const _TimelineWithRemarks({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        steps.length,
            (i) => _TimelineItemWithRemarks(
          step: steps[i],
          isLast: i == steps.length - 1,
        ),
      ),
    );
  }
}

class _TimelineItemWithRemarks extends StatefulWidget {
  final ApprovalStepItem step;
  final bool isLast;
  const _TimelineItemWithRemarks({required this.step, required this.isLast});

  @override
  State<_TimelineItemWithRemarks> createState() =>
      _TimelineItemWithRemarksState();
}

class _TimelineItemWithRemarksState extends State<_TimelineItemWithRemarks> {
  static const _blue = Color(0xFF0866FF);
  static const _blueLight = Color(0xFFE7F0FF);
  static const _red = Color(0xFFE2420E);
  static const _redBg = Color(0xFFFFF0ED);
  static const _divider = Color(0xFFE4E6EB);
  static const _textPrimary = Color(0xFF050505);
  static const _textSecondary = Color(0xFF65676B);
  static const _textTertiary = Color(0xFF8A8D91);

  bool _remarksExpanded = false;

  String _fmtRemarkTime(String raw) {
    if (raw.isEmpty) return '';
    try {
      return DateFormat('MMM d, h:mm a')
          .format(DateTime.parse(raw))
          .toLowerCase();
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final isDone = step.isDone;
    final isDisapproved = step.stageKey.toLowerCase() == 'disapproved';
    final dotColor = isDisapproved ? _red : _blue;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Dot + connector line ──────────────
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? dotColor : Colors.white,
                    border: Border.all(
                      color: isDone ? dotColor : _divider,
                      width: isDone ? 0 : 2,
                    ),
                    boxShadow: isDone
                        ? [
                      BoxShadow(
                        color: dotColor.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                        : null,
                  ),
                  child: isDone
                      ? Icon(
                    isDisapproved
                        ? Icons.close_rounded
                        : Icons.check_rounded,
                    size: 9,
                    color: Colors.white,
                  )
                      : null,
                ),
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isDone ? _blue.withOpacity(0.2) : _divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Content ───────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          step.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDone ? _textPrimary : _textTertiary,
                          ),
                        ),
                      ),
                      if (step.date.isNotEmpty && isDone) ...[
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(step.date,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: _textTertiary,
                                    fontWeight: FontWeight.w500)),
                            if (step.time.isNotEmpty)
                              Text(step.time,
                                  style: const TextStyle(
                                      fontSize: 10, color: _textTertiary)),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(step.subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: _textSecondary, height: 1.4)),

                  // ── Remarks toggle pill ───────
                  if (step.hasRemarks) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _remarksExpanded = !_remarksExpanded),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDisapproved ? _redBg : _blueLight,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.forum_outlined,
                                size: 11, color: isDisapproved ? _red : _blue),
                            const SizedBox(width: 4),
                            Text(
                              _remarksExpanded
                                  ? 'Hide remarks'
                                  : '${step.remarks.length} remark${step.remarks.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDisapproved ? _red : _blue),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              _remarksExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 13,
                              color: isDisapproved ? _red : _blue,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Inline remarks (initials only, no photos) ─
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: _remarksExpanded
                          ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: step.remarks.asMap().entries.map(
                                (e) {
                              final isLastRemark =
                                  e.key == step.remarks.length - 1;
                              final r = e.value;
                              return Padding(
                                padding: EdgeInsets.only(
                                    bottom: isLastRemark ? 0 : 10),
                                child: Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                        color: _blueLight,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          r.staffName.isNotEmpty
                                              ? r.staffName[0]
                                              .toUpperCase()
                                              : 'S',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: _blue),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r.staffName.isNotEmpty
                                                ? r.staffName
                                                : 'System',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                FontWeight.w700,
                                                color: _textPrimary),
                                          ),
                                          const SizedBox(height: 3),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 10,
                                                vertical: 8),
                                            decoration: BoxDecoration(
                                              color:
                                              const Color(0xFFF0F2F5),
                                              borderRadius:
                                              BorderRadius.circular(
                                                  10),
                                            ),
                                            child: Text(r.remarks,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: _textSecondary,
                                                    height: 1.45)),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            _fmtRemarkTime(r.createdAt),
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: _textTertiary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}