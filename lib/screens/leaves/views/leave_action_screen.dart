import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shop/services/api_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shop/constants.dart';

// ════════════════════════════════════════════════════
// DESIGN TOKENS — Meta-style
// ════════════════════════════════════════════════════

class _M {
  static const bg = Color(0xFFF0F2F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceHover = Color(0xFFF7F8FA);
  static const textPrimary = Color(0xFF050505);
  static const textSecondary = Color(0xFF65676B);
  static const textTertiary = Color(0xFF8A8D91);
  static const divider = Color(0xFFE4E6EB);
  static const blue = Color(0xFF1877F2);
  static const blueLight = Color(0xFFE7F0FD);
  static const blueMid = Color(0xFFB0C8F7);
  static const greenFg = Color(0xFF1F7A1F);
  static const greenBg = Color(0xFFE6F4EA);
  static const orangeFg = Color(0xFFB45309);
  static const orangeBg = Color(0xFFFEF3C7);
  static const redFg = Color(0xFFB91C1C);
  static const redBg = Color(0xFFFEE2E2);

  static const r8 = BorderRadius.all(Radius.circular(8));
  static const r12 = BorderRadius.all(Radius.circular(12));
  static const r16 = BorderRadius.all(Radius.circular(16));
  static const r20 = BorderRadius.all(Radius.circular(20));
  static const rFull = BorderRadius.all(Radius.circular(100));

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
}

// ════════════════════════════════════════════════════
// TIMEZONE HELPER — Asia/Manila (UTC+8)
// ════════════════════════════════════════════════════
//
// The backend stores timestamps in UTC (Laravel/MySQL default).
// Dart's `DateTime.parse` interprets a string with no timezone
// designator as the *device's* local time, which is unreliable
// across users. This helper forces a UTC interpretation and then
// shifts by the fixed Asia/Manila offset (UTC+8, no DST), so every
// user sees the same Philippine time regardless of device settings.
DateTime? parseAsManilaTime(String raw) {
  if (raw.isEmpty) return null;
  try {
    final hasTz =
        raw.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(raw);
    final utc = DateTime.parse(hasTz ? raw : '${raw}Z').toUtc();
    return utc.add(const Duration(hours: 8)); // Asia/Manila, UTC+8
  } catch (_) {
    return null;
  }
}

// ════════════════════════════════════════════════════
// MODELS
// ════════════════════════════════════════════════════

class LeaveDate {
  final String date, type;
  const LeaveDate({required this.date, required this.type});
  factory LeaveDate.fromJson(Map<String, dynamic> j) =>
      LeaveDate(date: j['date'] ?? '', type: j['type'] ?? '');
}

class LeaveApprovals {
  final String? onDraft;
  final String? forHrReview;
  final String? forHrDcReview;
  final String? forSupervisorReview;
  final String? forArdaReview;
  final String? approved;
  final String? disapproved;
  final String? cancelled;

  const LeaveApprovals({
    this.onDraft,
    this.forHrReview,
    this.forHrDcReview,
    this.forSupervisorReview,
    this.forArdaReview,
    this.approved,
    this.disapproved,
    this.cancelled,
  });

  factory LeaveApprovals.fromJson(Map<String, dynamic> j) => LeaveApprovals(
    onDraft: j['on_draft'],
    forHrReview: j['for_hr_review'],
    forHrDcReview: j['for_hr_dc_review'],
    forSupervisorReview: j['for_supervisor_review'],
    forArdaReview: j['for_approval'],
    approved: j['approved'],
    disapproved: j['disapproved'],
    cancelled: j['cancelled'],
  );
}

class LeaveRemark {
  final String staffName, stage, remarks, action, createdAt;
  const LeaveRemark({
    required this.staffName,
    required this.stage,
    required this.remarks,
    required this.action,
    required this.createdAt,
  });

  factory LeaveRemark.fromJson(Map<String, dynamic> j) => LeaveRemark(
    staffName: j['staff_name'] ?? '',
    stage: j['stage'] ?? '',
    remarks: j['remarks'] ?? '',
    action: j['action'] ?? '',
    createdAt: j['created_at'] ?? '',
  );
}

class LeaveAttachment {
  final int id;
  final String path, fileType, createdAt;

  const LeaveAttachment({
    required this.id,
    required this.path,
    required this.fileType,
    required this.createdAt,
  });

  factory LeaveAttachment.fromJson(Map<String, dynamic> j) => LeaveAttachment(
    id: j['id'] ?? 0,
    path: j['path'] ?? '',
    fileType: j['file_type'] ?? '',
    createdAt: j['created_at'] ?? '',
  );

  static const _base = 'https://fo2-staff-search.dswd.gov.ph/';

  String get fullUrl => '$_base$path';

  bool get isImage =>
      fileType == 'jpg' ||
          fileType == 'jpeg' ||
          fileType == 'png' ||
          fileType == 'webp';

  bool get isPdf => fileType == 'pdf';

  String get fileName => path.split('/').last;

  IconData get icon {
    if (isPdf) return Icons.picture_as_pdf_rounded;
    if (isImage) return Icons.image_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color get iconColor {
    if (isPdf) return const Color(0xFFDC2626);
    if (isImage) return const Color(0xFF7C3AED);
    return _M.blue;
  }

  Color get iconBg {
    if (isPdf) return const Color(0xFFFEE2E2);
    if (isImage) return const Color(0xFFEDE9FE);
    return _M.blueLight;
  }
}

class LeaveRequestDetail {
  final int id;
  final String status, reason, typeName, typeCode;
  final String totalDays, actualDays, splUsed;
  final String createdAt, updatedAt, computationNotes;
  final List<LeaveDate> leaveDates;
  final LeaveApprovals? approvals;
  final List<LeaveRemark> remarks;
  final List<LeaveAttachment> attachments;

  const LeaveRequestDetail({
    required this.id,
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
    this.approvals,
    required this.remarks,
    required this.attachments,
  });

  factory LeaveRequestDetail.fromJson(Map<String, dynamic> j) {
    List<LeaveDate> dates = [];
    final rawDates = j['leave_dates'];
    if (rawDates is String && rawDates.isNotEmpty) {
      final decoded = jsonDecode(rawDates) as List;
      dates = decoded
          .map((d) => LeaveDate.fromJson(d as Map<String, dynamic>))
          .toList();
    } else if (rawDates is List) {
      dates = rawDates
          .map((d) => LeaveDate.fromJson(d as Map<String, dynamic>))
          .toList();
    }

    return LeaveRequestDetail(
      id: j['id'] ?? 0,
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
      approvals: j['approvals'] != null
          ? LeaveApprovals.fromJson(j['approvals'])
          : null,
      remarks: (j['remarks'] as List? ?? [])
          .map((r) => LeaveRemark.fromJson(r as Map<String, dynamic>))
          .toList(),
      attachments: (j['attachments'] as List? ?? [])
          .map((a) => LeaveAttachment.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  String get startDate => leaveDates.isNotEmpty ? leaveDates.first.date : '';
  String get endDate => leaveDates.isNotEmpty ? leaveDates.last.date : '';

  String get daysDisplay {
    final d = double.tryParse(totalDays);
    if (d == null) return totalDays;
    return d == d.truncateToDouble() ? d.toInt().toString() : d.toString();
  }

  // ── Raw status, normalized (lowercase, trimmed) ──────────
  // Used internally for logic checks like "is this a draft?"
  String get normalizedStatus => status.trim().toLowerCase();

  // ── True when this leave request is still an editable/deletable draft ──
  bool get isDraft =>
      normalizedStatus == 'on_draft' || normalizedStatus == 'draft';

  String get resolvedStatus {
    final s = normalizedStatus;
    if (s == 'disapproved') return 'Disapproved';
    if (s == 'approved') return 'Approved';
    if (s == 'pending') return 'Pending';
    if (s == 'on_draft' || s == 'draft') return 'Draft';
    if (s.isEmpty) return 'Pending';

    // Fallback for stage-keyed statuses like "for_supervisor_review"
    // or "for_hr_dc_review" — split on underscores and title-case each word.
    return s
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
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
        return const Color(0xFFEAB308);
      case 'Vacation Leave':
        return const Color(0xFF22C55E);
      case 'Emergency Leave':
        return const Color(0xFFEF4444);
      default:
        return _M.blue;
    }
  }

  /// Builds timeline steps and injects matching remarks per stage.
  List<ApprovalStep> buildTimeline() {
    final steps = <ApprovalStep>[];
    final currentStage = status.trim();

    void add(String title, String subtitle, String stageKey, String? ts) {
      final stageRemarks = remarks.where((r) => r.stage == stageKey).toList();
      final isCurrent = stageKey == currentStage;

      steps.add(ApprovalStep(
        title: title,
        subtitle: isCurrent ? 'Currently pending at this stage.' : subtitle,
        timestamp: ts ?? '',
        stageKey: stageKey,
        remarks: stageRemarks,
        isCurrentStage: isCurrent,
      ));
    }


    add('Request Submitted', 'Leave request was filed.', 'on_draft', createdAt);

    add(
        'HR Review',
        'For review by Human Resources.',
        'for_hr_review',
        approvals?.forHrReview
    );

    add(
        'HR DC Review',
        'For review by HRMDD Division Chief.',
        'for_hr_dc_review',
        approvals?.forHrDcReview
    );

    add(
        'DC Review',
        'For review by your Division Chief.',
        'for_supervisor_review',
        approvals?.forSupervisorReview
    );

    add(
        'Approval Review',
        'Final review by the approver.',
        'for_approval',
        approvals?.forArdaReview
    );

    // ── Terminal outcomes ─────────────────────────────────
    // Approved / Disapproved / Cancelled are FINAL states, never
    // "pending". Build these directly instead of via add() so they
    // don't get matched against `currentStage` (status == 'approved'
    // would otherwise flip isCurrentStage=true and make the step look
    // like it's still awaiting action instead of done).
    if (approvals?.approved != null) {
      steps.add(ApprovalStep(
        title: 'Approved',
        subtitle: 'Leave fully approved. Enjoy your time off!',
        timestamp: approvals!.approved!,
        stageKey: 'approved',
        remarks: remarks.where((r) => r.stage == 'approved').toList(),
        isCurrentStage: false,
      ));
    } else if (approvals?.disapproved != null) {
      steps.add(ApprovalStep(
        title: 'Disapproved',
        subtitle: computationNotes.isNotEmpty
            ? computationNotes
            : 'Leave request was disapproved.',
        timestamp: approvals!.disapproved!,
        stageKey: 'Disapproved',
        remarks: remarks.where((r) => r.stage == 'Disapproved').toList(),
        isCurrentStage: false,
      ));
    } else if (approvals?.cancelled != null) {
      steps.add(ApprovalStep(
        title: 'Cancelled',
        subtitle: 'This leave request was cancelled.',
        timestamp: approvals!.cancelled!,
        stageKey: 'cancelled',
        remarks: remarks.where((r) => r.stage == 'cancelled').toList(),
        isCurrentStage: false,
      ));
    }

    return steps;
  }
}

class ApprovalStep {
  final String title, subtitle, timestamp, stageKey;
  final List<LeaveRemark> remarks;
  final bool isCurrentStage;

  const ApprovalStep({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.stageKey,
    this.remarks = const [],
    this.isCurrentStage = false,
  });

  // A stage only counts as "done" if it has a timestamp AND it isn't
  // the stage the request is currently sitting at — otherwise a
  // pending review looks like it was already approved.
  bool get isDone => timestamp.isNotEmpty && !isCurrentStage;
  bool get isPending => isCurrentStage;

  bool get hasRemarks => remarks.isNotEmpty;

  // Timestamps are converted to Asia/Manila (UTC+8) so every user
  // sees the same Philippine time regardless of device timezone.
  DateTime? get _parsedDate => parseAsManilaTime(timestamp);

  String get date {
    final d = _parsedDate;
    if (d == null) return '';
    return DateFormat('yyyy-MM-dd').format(d);
  }

  String get time {
    final d = _parsedDate;
    if (d == null) return '';
    return '${DateFormat('h:mm a').format(d).toLowerCase()}';
  }
}
// ════════════════════════════════════════════════════
// STATUS HELPERS
// ════════════════════════════════════════════════════

class _StatusConfig {
  final Color fg, bg;
  final IconData icon;
  final String label;
  const _StatusConfig({
    required this.fg,
    required this.bg,
    required this.icon,
    required this.label,
  });

  static _StatusConfig of(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return const _StatusConfig(
            fg: _M.greenFg,
            bg: _M.greenBg,
            icon: Icons.check_circle_rounded,
            label: 'Approved');
      case 'pending':
        return const _StatusConfig(
            fg: _M.orangeFg,
            bg: _M.orangeBg,
            icon: Icons.schedule_rounded,
            label: 'Pending');
      case 'disapproved':
        return const _StatusConfig(
            fg: _M.redFg,
            bg: _M.redBg,
            icon: Icons.cancel_rounded,
            label: 'Disapproved');
      case 'draft':
        return const _StatusConfig(
            fg: _M.textSecondary,
            bg: Color(0xFFF0F2F5),
            icon: Icons.edit_note_rounded,
            label: 'Draft');
      default:
        return const _StatusConfig(
            fg: _M.textSecondary,
            bg: Color(0xFFF0F2F5),
            icon: Icons.info_outline_rounded,
            label: 'Unknown');
    }
  }
}

// ════════════════════════════════════════════════════
// API SERVICE
// ════════════════════════════════════════════════════

class _LeaveDetailService {
  static Future<LeaveRequestDetail> fetch(String leaveId) async {
    final url = Uri.parse('${ApiConfig.leaveBase}/leave-requests/$leaveId');
    final res = await http.get(url).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return LeaveRequestDetail.fromJson(json['data']);
    } else {
      throw Exception('Server error ${res.statusCode}');
    }
  }

  // ── Cancel/Delete a draft leave request ──────────────────
  // Adjust the method/endpoint here if your backend expects
  // something different (e.g. a PATCH to set status = 'cancelled').
  static Future<void> cancel(String leaveId) async {
    final url = Uri.parse('${ApiConfig.leaveBase}/leave-requests/$leaveId');
    final res = await http.delete(url).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200 && res.statusCode != 204) {
      String msg = 'Server error ${res.statusCode}';
      try {
        final json = jsonDecode(res.body);
        if (json['message'] != null) msg = json['message'];

      } catch (_) {}
      throw Exception(msg);
    }
  }
}

// ════════════════════════════════════════════════════
// SCREEN
// ════════════════════════════════════════════════════

class LeaveActionScreen extends StatefulWidget {
  final String leaveId;
  const LeaveActionScreen({super.key, required this.leaveId});

  @override
  State<LeaveActionScreen> createState() => _LeaveActionScreenState();
}

class _LeaveActionScreenState extends State<LeaveActionScreen> {
  late Future<LeaveRequestDetail> _future;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _future = _LeaveDetailService.fetch(widget.leaveId);
  }

  void _retry() =>
      setState(() => _future = _LeaveDetailService.fetch(widget.leaveId));

  // ── Confirm dialog before cancelling/deleting a draft ─────
  Future<void> _confirmAndCancel(String leaveId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: _M.r12),
        title: const Text(
          'Cancel this leave request?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'This draft leave request will be permanently deleted. This action cannot be undone.',
          style: TextStyle(fontSize: 14, color: _M.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No, Keep It',
                style: TextStyle(color: _M.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: _M.redFg, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);
    try {
      await _LeaveDetailService.cancel(leaveId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft leave request cancelled')),
      );
      Navigator.pop(context); // back to leaves list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));

    return Scaffold(
      backgroundColor: _M.bg,
      body: FutureBuilder<LeaveRequestDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _Loader();
          }
          if (snapshot.hasError) {
            return _ErrorView(
              msg: snapshot.error.toString(),
              onRetry: _retry,
            );
          }
          return _Body(leave: snapshot.data!);
        },
      ),
      // ── Draft-only cancel/delete bar ──────────────────────
      bottomNavigationBar: FutureBuilder<LeaveRequestDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final leave = snapshot.data!;
          if (!leave.isDraft) return const SizedBox.shrink();

          return _DraftActionsBar(
            isBusy: _isCancelling,
            onCancel: () => _confirmAndCancel(leave.id.toString()),
          );
        },
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// DRAFT ACTIONS BAR (Cancel / Delete)
// ════════════════════════════════════════════════════

class _DraftActionsBar extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onCancel;
  const _DraftActionsBar({required this.isBusy, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: _M.surface,
        border: Border(top: BorderSide(color: _M.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: isBusy ? null : onCancel,
            icon: isBusy
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.delete_outline_rounded,
                size: 18, color: Colors.white),
            label: Text(
              isBusy ? 'Cancelling…' : 'Cancel / Delete Request',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _M.redFg,
              disabledBackgroundColor: _M.redFg.withOpacity(0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: _M.rFull),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// BODY
// ════════════════════════════════════════════════════

class _Body extends StatelessWidget {
  final LeaveRequestDetail leave;
  const _Body({required this.leave});

  @override
  Widget build(BuildContext context) {
    final cfg = _StatusConfig.of(leave.isDraft ? 'draft' : leave.resolvedStatus);
    final timeline = leave.buildTimeline();
    final totalRemarks = leave.remarks.length;

    return CustomScrollView(
      slivers: [
        // ── App Bar ─────────────────────────────
        SliverAppBar(
          pinned: true,
          backgroundColor: _M.surface,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: Colors.black.withOpacity(0.08),
          automaticallyImplyLeading: false,
          toolbarHeight: 56,
          title: Row(
            children: [
              _BackButton(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave.typeName.isEmpty ? 'Leave Request' : leave.typeName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _M.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Request #${leave.id}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _M.textTertiary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(cfg: cfg, label: leave.resolvedStatus),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _M.divider),
          ),
        ),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ── Draft notice banner ───────────
              if (leave.isDraft) ...[
                _DraftNoticeBanner(),
                const SizedBox(height: 8),
              ],

              // ── Hero Card ─────────────────────
              _HeroCard(leave: leave, cfg: cfg),
              const SizedBox(height: 8),

              // ── Stats Row ─────────────────────
              _StatsRow(leave: leave),
              const SizedBox(height: 8),

              // ── Leave Dates ───────────────────
              if (leave.leaveDates.isNotEmpty) ...[
                _SectionCard(
                  leading: const Icon(Icons.calendar_today_rounded),
                  title: 'Leave Dates',
                  child: _LeaveDatesGrid(dates: leave.leaveDates),
                ),
                const SizedBox(height: 8),
              ],

              // ── Reason ────────────────────────
              if (leave.reason.isNotEmpty) ...[
                _SectionCard(
                  leading: const Icon(Icons.chat_bubble_outline_rounded),
                  title: 'Reason',
                  child: _ExpandableText(text: leave.reason),
                ),
                const SizedBox(height: 8),
              ],

              // ── Computation Notes ─────────────
              if (leave.computationNotes.isNotEmpty) ...[
                _NotesBanner(notes: leave.computationNotes),
                const SizedBox(height: 8),
              ],

              // ── Timeline + Remarks (merged) ───
              if (timeline.isNotEmpty) ...[
                _SectionCard(
                  leading: const Icon(Icons.timeline_rounded),
                  title: 'Approval Timeline',
                  trailing: totalRemarks > 0
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.forum_outlined,
                          size: 12, color: _M.textTertiary),
                      const SizedBox(width: 4),
                      _CountBadge(count: totalRemarks),
                    ],
                  )
                      : null,
                  child: _TimelineWithRemarks(steps: timeline),
                ),
                const SizedBox(height: 8),
              ],

              // ── Attachments ───────────────────
              if (leave.attachments.isNotEmpty) ...[
                _SectionCard(
                  leading:  const Text('📁'),
                  title: 'Attachments',
                  trailing: _CountBadge(count: leave.attachments.length),
                  child: _AttachmentsList(attachments: leave.attachments),
                ),
                const SizedBox(height: 8),
              ],

              // ── Extra bottom padding so content isn't hidden
              // behind the draft actions bar ────────────────
              SizedBox(height: leave.isDraft ? 24 : 48),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Draft notice banner ───────────────────────────────

class _DraftNoticeBanner extends StatelessWidget {
  const _DraftNoticeBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _M.blueLight,
          borderRadius: _M.r12,
          border: Border.all(color: _M.blueMid.withOpacity(0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.edit_note_rounded, size: 16, color: _M.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'This leave request is still a draft. You can cancel/delete it below.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: _M.blue.withOpacity(0.9),
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// COMPONENTS
// ════════════════════════════════════════════════════

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _M.bg,
          borderRadius: _M.rFull,
        ),
        child: const Icon(Icons.arrow_back_rounded,
            size: 18, color: _M.textPrimary),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _StatusConfig cfg;
  final String label;
  const _StatusBadge({required this.cfg, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: _M.rFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.icon, size: 11, color: cfg.fg),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: cfg.fg)),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final LeaveRequestDetail leave;
  final _StatusConfig cfg;
  const _HeroCard({required this.leave, required this.cfg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: _M.surface,
          borderRadius: _M.r12,
          boxShadow: _M.cardShadow,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: leave.typeColor.withOpacity(0.1),
                      borderRadius: _M.r12,
                    ),
                    padding: const EdgeInsets.all(12),
                    child:
                    Image.asset(leave.typeImagePath, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leave.typeName.isEmpty
                              ? 'Leave Request'
                              : leave.typeName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _M.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 12, color: _M.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              _fmtDate(leave.createdAt),
                              style: const TextStyle(
                                  fontSize: 12, color: _M.textSecondary),
                            ),
                          ],
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

  String _fmtDate(String raw) {
    if (raw.isEmpty) return '—';

    final date = parseAsManilaTime(raw);
    if (date == null) return 'Filed $raw';

    final formatted = DateFormat("MMMM d, yyyy 'at' h:mm a").format(date).toLowerCase();
    // Capitalize the month name again since toLowerCase() lowercases everything
    final capitalized = formatted.replaceFirstMapped(
      RegExp(r'^[a-z]'),
          (m) => m.group(0)!.toUpperCase(),
    );

    return 'Filed $capitalized PHT';
  }
}

class _StatsRow extends StatelessWidget {
  final LeaveRequestDetail leave;
  const _StatsRow({required this.leave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.login_rounded,
            label: 'Start Date',
            value: leave.startDate.isNotEmpty ? leave.startDate : '—',
          ),
          const SizedBox(width: 8),
          _StatCard(
            icon: Icons.logout_rounded,
            label: 'End Date',
            value: leave.endDate.isNotEmpty ? leave.endDate : '—',
          ),
          const SizedBox(width: 8),
          _StatCard(
            icon: Icons.wb_sunny_outlined,
            label: 'Total Days',
            value: '${leave.daysDisplay}d',
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool highlight;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: highlight ? _M.blue : _M.surface,
          borderRadius: _M.r12,
          boxShadow: _M.subtleShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 16, color: highlight ? _M.surface : _M.textTertiary),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: highlight
                        ? _M.surface
                        : _M.textTertiary,
                    letterSpacing: 0.2)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: highlight ? _M.surface : _M.textPrimary)),
          ],
        ),
      ),
    );
  }
}

// ── Section Card wrapper ──────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget? leading; // 👈 can be Icon OR Text
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    this.leading,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: _M.surface,
          borderRadius: _M.r12,
          boxShadow: _M.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  if (leading != null) ...[
                    DefaultTextStyle(
                      style: const TextStyle(
                        fontSize: 15,
                        color: _M.blue,
                      ),
                      child: IconTheme(
                        data: const IconThemeData(
                          size: 15,
                          color: _M.blue,
                        ),
                        child: leading!,
                      ),
                    ),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _M.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Divider(height: 1, color: _M.divider),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _M.blueLight,
        borderRadius: _M.rFull,
      ),
      child: Text('$count',
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: _M.blue)),
    );
  }
}

// ── Leave Dates Grid ─────────────────────────────────

class _LeaveDatesGrid extends StatefulWidget {
  final List<LeaveDate> dates;
  const _LeaveDatesGrid({required this.dates});

  @override
  State<_LeaveDatesGrid> createState() => _LeaveDatesGridState();
}

class _LeaveDatesGridState extends State<_LeaveDatesGrid> {
  static const _preview = 6;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasMore = widget.dates.length > _preview;
    final shown =
    _expanded ? widget.dates : widget.dates.take(_preview).toList();
    final hidden = widget.dates.length - _preview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: shown.map((d) => _DateChip(d: d)).toList(),
        ),
        if (hasMore) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Show less' : 'Show $hidden more',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _M.blue),
            ),
          ),
        ],
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  final LeaveDate d;
  const _DateChip({required this.d});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _M.bg,
        borderRadius: _M.r8,
        border: Border.all(color: _M.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(d.date,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _M.textPrimary)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: _M.blueLight,
              borderRadius: _M.r8,
            ),
            child: Text(d.type,
                style: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700, color: _M.blue)),
          ),
        ],
      ),
    );
  }
}

// ── Expandable Text ──────────────────────────────────

class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;
  final _isLongThreshold = 120;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.text.length > _isLongThreshold;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _expanded || !isLong
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(widget.text,
              style: const TextStyle(
                  fontSize: 14, color: _M.textSecondary, height: 1.6),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          secondChild: Text(widget.text,
              style: const TextStyle(
                  fontSize: 14, color: _M.textSecondary, height: 1.6)),
        ),
        if (isLong) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'See less' : 'See more',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _M.blue),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Notes Banner ─────────────────────────────────────

class _NotesBanner extends StatelessWidget {
  final String notes;
  const _NotesBanner({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: _M.r12,
          border: Border.all(color: const Color(0xFFFDE68A)),
          boxShadow: _M.subtleShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 16, color: _M.orangeFg),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Computation Notes',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _M.orangeFg)),
                  const SizedBox(height: 4),
                  Text(notes,
                      style: const TextStyle(
                          fontSize: 13, color: _M.orangeFg, height: 1.5)),
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
// MERGED TIMELINE + REMARKS
// ════════════════════════════════════════════════════

class _TimelineWithRemarks extends StatelessWidget {
  final List<ApprovalStep> steps;
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
  final ApprovalStep step;
  final bool isLast;
  const _TimelineItemWithRemarks({required this.step, required this.isLast});

  @override
  State<_TimelineItemWithRemarks> createState() =>
      _TimelineItemWithRemarksState();
}

class _TimelineItemWithRemarksState extends State<_TimelineItemWithRemarks> {
  bool _remarksExpanded = false;

  String _fmtTime(String raw) {
    final date = parseAsManilaTime(raw);
    if (date == null) return '';
    return '${DateFormat('yyyy-MM-dd  h:mm a').format(date)} PHT';
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final isDone = step.isDone;
    final isCurrent = step.isCurrentStage;
    final hasRemarks = step.hasRemarks;

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
                    color: isDone
                        ? _M.blue
                        : isCurrent
                        ? _M.orangeBg
                        : _M.surface,
                    border: Border.all(
                      color: isDone
                          ? _M.blue
                          : isCurrent
                          ? _M.orangeFg
                          : _M.divider,
                      width: isDone ? 0 : 2,
                    ),
                    boxShadow: isDone
                        ? [
                      BoxShadow(
                        color: _M.blue.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                        : null,
                  ),
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                      size: 9, color: Colors.white)
                      : isCurrent
                      ? const Icon(Icons.schedule_rounded,
                      size: 9, color: _M.orangeFg)
                      : null,
                ),
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color:
                        isDone ? _M.blue.withOpacity(0.2) : _M.divider,
                        borderRadius: _M.rFull,
                      ),
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
                  const SizedBox(height: 1),

                  // Title + timestamp
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                step.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDone
                                      ? _M.textPrimary
                                      : isCurrent
                                      ? _M.orangeFg
                                      : _M.textTertiary,
                                ),
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _M.orangeBg,
                                  borderRadius: _M.rFull,
                                ),
                                child: const Text(
                                  'PENDING',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                    color: _M.orangeFg,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Only show a timestamp for stages that actually
                      // finished — a pending stage has no completion time.
                      if (isDone && step.date.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(step.date,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: _M.textTertiary,
                                    fontWeight: FontWeight.w500)),
                            if (step.time.isNotEmpty)
                              Text(step.time,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: _M.textTertiary)),
                          ],
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 2),
                  Text(step.subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: isCurrent ? _M.orangeFg : _M.textSecondary,
                          height: 1.4)),

                  // ── Remarks toggle pill ───────
                  if (hasRemarks) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(
                              () => _remarksExpanded = !_remarksExpanded),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: _M.blueLight,
                          borderRadius: _M.rFull,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.forum_outlined,
                                size: 11, color: _M.blue),
                            const SizedBox(width: 4),
                            Text(
                              _remarksExpanded
                                  ? 'Hide remarks'
                                  : '${step.remarks.length} remark${step.remarks.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _M.blue),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              _remarksExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 13,
                              color: _M.blue,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Inline remarks ────────────
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
                                    // Avatar
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: _M.blueLight,
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
                                              fontWeight:
                                              FontWeight.w700,
                                              color: _M.blue),
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
                                                color: _M.textPrimary),
                                          ),
                                          const SizedBox(height: 3),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 10,
                                                vertical: 8),
                                            decoration: BoxDecoration(
                                              color: _M.bg,
                                              borderRadius:
                                              const BorderRadius
                                                  .only(
                                                topRight:
                                                Radius.circular(10),
                                                bottomLeft:
                                                Radius.circular(10),
                                                bottomRight:
                                                Radius.circular(10),
                                              ),
                                            ),
                                            child: Text(r.remarks,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                    _M.textSecondary,
                                                    height: 1.45)),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            _fmtTime(r.createdAt),
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: _M.textTertiary),
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

// ── Attachments List ──────────────────────────────────

class _AttachmentsList extends StatelessWidget {
  final List<LeaveAttachment> attachments;
  const _AttachmentsList({required this.attachments});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: attachments.asMap().entries.map((e) {
        final isLast = e.key == attachments.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
          child: _AttachmentTile(attachment: e.value),
        );
      }).toList(),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final LeaveAttachment attachment;
  const _AttachmentTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _M.bg,
          borderRadius: _M.r8,
          border: Border.all(color: _M.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: attachment.iconBg,
                borderRadius: _M.r8,
              ),
              child: Icon(attachment.icon,
                  size: 20, color: attachment.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.fileName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _M.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _M.blueLight,
                borderRadius: _M.rFull,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.open_in_new_rounded, size: 11, color: _M.blue),
                  SizedBox(width: 4),
                  Text('Open',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _M.blue)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    if (attachment.isImage) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _ImagePreviewScreen(
            url: attachment.fullUrl,
            fileName: attachment.fileName,
          ),
        ),
      );
      return;
    }
    launchUrl(Uri.parse(attachment.fullUrl),
        mode: LaunchMode.externalApplication);
  }
}

// ── Full-screen image preview ─────────────────────────

class _ImagePreviewScreen extends StatelessWidget {
  final String url, fileName;
  const _ImagePreviewScreen({required this.url, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          fileName,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon:
            const Icon(Icons.open_in_new_rounded, color: Colors.white),
            onPressed: () => launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication),
          ),
        ],
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              );
            },
            errorBuilder: (_, __, ___) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_rounded,
                      color: Colors.white38, size: 48),
                  SizedBox(height: 8),
                  Text('Failed to load image',
                      style:
                      TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// UTILITY STATES
// ════════════════════════════════════════════════════

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _M.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                  color: _M.blue, strokeWidth: 2.5),
            ),
            SizedBox(height: 16),
            Text('Loading details…',
                style: TextStyle(
                    fontSize: 14,
                    color: _M.textSecondary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorView({required this.msg, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _M.bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: _M.surface,
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  _BackButton(),
                  const SizedBox(width: 12),
                  const Text('Leave Request',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _M.textPrimary)),
                ],
              ),
            ),
            Container(height: 1, color: _M.divider),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _M.redBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.wifi_off_rounded,
                            color: _M.redFg, size: 28),
                      ),
                      const SizedBox(height: 16),
                      const Text("Can't load request",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _M.textPrimary)),
                      const SizedBox(height: 6),
                      Text(msg,
                          style: const TextStyle(
                              fontSize: 13, color: _M.textSecondary),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _M.blue,
                            foregroundColor: Colors.white,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: _M.r8),
                            elevation: 0,
                          ),
                          child: const Text('Try Again',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
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
    );
  }
}