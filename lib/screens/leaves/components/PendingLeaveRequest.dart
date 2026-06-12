import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:shop/components/resuable_webapp_view.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/screens/leaves/components/RemarksPerStage.dart';
import 'leave_dates_enhanced.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _T {
  static const blue        = Color(0xFF0866FF);
  static const blueSoft    = Color(0xFFE7F0FF);

  static const bg          = Color(0xFFF0F2F5);
  static const surface     = Color(0xFFFFFFFF);
  static const divider     = Color(0xFFE4E6EB);

  static const textPrimary = Color(0xFF050505);
  static const textSub     = Color(0xFF65676B);
  static const textMuted   = Color(0xFF8A8D91);

  static const green       = Color(0xFF10B981);
  static const greenSoft   = Color(0xFFD1FAE5);
  static const red         = Color(0xFFF43F5E);
  static const redSoft     = Color(0xFFFFE4E8);
  static const amber       = Color(0xFFF59E0B);
  static const amberSoft   = Color(0xFFFEF3C7);
  static const grey        = Color(0xFF6B7280);
  static const greySoft    = Color(0xFFF3F4F6);

  static List<BoxShadow> get cardShadow => [
        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 2)),
        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4,  offset: const Offset(0, 1)),
      ];

  static TextStyle heading({double size = 16, FontWeight w = FontWeight.w700, Color? color}) =>
      TextStyle(fontSize: size, fontWeight: w, color: color ?? textPrimary, letterSpacing: -0.4, height: 1.2);

  static TextStyle body({double size = 13, FontWeight w = FontWeight.w400, Color? color}) =>
      TextStyle(fontSize: size, fontWeight: w, color: color ?? textSub, letterSpacing: -0.1, height: 1.5);
}

// ─── Status helpers ───────────────────────────────────────────────────────────
class _Status {
  static Color fg(String s) {
    final v = s.toLowerCase();
    if (v.contains('approved')) return _T.green;
    if (v.contains('rejected')) return _T.red;
    if (v.contains('draft'))    return _T.grey;
    return _T.amber;
  }

  static Color bg(String s) {
    final v = s.toLowerCase();
    if (v.contains('approved')) return _T.greenSoft;
    if (v.contains('rejected')) return _T.redSoft;
    if (v.contains('draft'))    return _T.greySoft;
    return _T.amberSoft;
  }

  static IconData icon(String s) {
    final v = s.toLowerCase();
    if (v.contains('approved')) return Icons.check_circle_rounded;
    if (v.contains('rejected')) return Icons.cancel_rounded;
    if (v.contains('draft'))    return Icons.edit_rounded;
    return Icons.hourglass_top_rounded;
  }
}

// ─── Models ───────────────────────────────────────────────────────────────────
class ApprovalStep {
  final String key;
  final String displayName;
  final DateTime? timestamp;
  final bool isRejectedOrCancelled;
  final bool isLast;

  const ApprovalStep({
    required this.key,
    required this.displayName,
    this.timestamp,
    required this.isRejectedOrCancelled,
    required this.isLast,
  });

  Color get iconColor => isRejectedOrCancelled ? _T.red : _T.green;

  String get formattedTime {
    if (timestamp == null) return '';
    return DateFormat('MMM d · h:mm a').format(timestamp!);
  }
}

class ApprovalDataExtractor {
  static List<ApprovalStep> extractApprovalSteps(Map<String, dynamic> data) {
    final raw  = data['approvals'];
    final list = raw is List ? raw : raw is Map ? [raw] : [];
    if (list.isEmpty) return [];

    final approval = list.first as Map<String, dynamic>;
    const keys = [
      'on_draft', 'for_supervisor_review', 'for_hr_review',
      'for_hr_dc_review', 'for_approval', 'approved', 'rejected', 'cancelled',
    ];
    final active = keys.where((k) => approval[k] != null).toList();

    return active.asMap().entries.map((e) {
      final k = e.value;
      final v = approval[k];
      return ApprovalStep(
        key: k,
        displayName: k.replaceAll('_', ' ').toUpperCase(),
        timestamp: v != null ? DateTime.tryParse(v.toString()) : null,
        isRejectedOrCancelled: k == 'rejected' || k == 'cancelled',
        isLast: e.key == active.length - 1,
      );
    }).toList();
  }
}

// ─── Leave image map ──────────────────────────────────────────────────────────
const _leaveImages = {
  'Vacation Leave':          'assets/images/vacation.png',
  'Sick Leave':              'assets/images/sick.png',
  'Emergency Leave':         'assets/images/emergency.png',
  'Special Privilege Leave': 'assets/images/spl.png',
};
String _leaveImg(String? name) => _leaveImages[name] ?? 'assets/images/default.jpg';

// ─── Floating pill (bottom bar) ───────────────────────────────────────────────
class PendingLeaveRequest extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic> leaveData;

  const PendingLeaveRequest({Key? key, required this.imagePath, required this.leaveData})
      : super(key: key);

  @override
  State<PendingLeaveRequest> createState() => _PendingLeaveRequestState();
}

class _PendingLeaveRequestState extends State<PendingLeaveRequest>
    with TickerProviderStateMixin {
  late final AnimationController _press =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 130));

  @override
  void dispose() { _press.dispose(); super.dispose(); }

  // void _open() async {
  //   if (widget.leaveData.isEmpty) return;
  //   HapticFeedback.selectionClick();

  //   final leaveDates  = jsonDecode(widget.leaveData['leave_dates'] ?? '[]') as List;
  //   final attachments = widget.leaveData['attachments']  as List? ?? [];
  //   final status      = widget.leaveData['status']       ?? '';
  //   final leaveType   = widget.leaveData['leave_type'];
  //   final reason      = widget.leaveData['reason']       ?? '';
  //   final remarks     = widget.leaveData['remarks']      ?? [];

  //   await showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (_) => _LeaveModal(
  //       leaveType:   leaveType,
  //       status:      status,
  //       leaveDates:  leaveDates,
  //       attachments: attachments,
  //       reason:      reason,
  //       remarks:     remarks,
  //       leaveImage:  _leaveImg(leaveType?['name']),
  //     ),
  //   );
  // }

  void _open() async {
  if (widget.leaveData.isEmpty) return;
  HapticFeedback.selectionClick();

  final id = widget.leaveData['id']?.toString();
  if (id == null) return;

  Navigator.pushNamed(
    context,
    leaveActionScreenRoute,
    arguments: id,
  );
}

  @override
  Widget build(BuildContext context) {
    if (widget.leaveData.isEmpty) return const SizedBox.shrink();
    final leaveType = widget.leaveData['leave_type'];
    final status    = widget.leaveData['status'] ?? '';

    return Positioned(
      left: 16, right: 16, bottom: 16,
      child: GestureDetector(
        onTapDown:   (_) { HapticFeedback.lightImpact(); _press.forward(); },
        onTapUp:     (_) { _press.reverse(); _open(); },
        onTapCancel: () => _press.reverse(),
        child: AnimatedBuilder(
          animation: _press,
          builder: (_, child) =>
              Transform.scale(scale: 1.0 - _press.value * 0.02, child: child),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _T.divider, width: 0.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 8)),
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6,  offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                // Leave icon
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _T.cardShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(_leaveImg(leaveType?['name']), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(leaveType?['name'] ?? 'Leave',
                          style: _T.heading(size: 14, w: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      _StatusPill(status: status),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // CTA button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _T.blueSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View',
                          style: _T.body(size: 12, w: FontWeight.w700, color: _T.blue)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 12, color: _T.blue),
                    ],
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

// ─── Status pill ──────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _Status.bg(status),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_Status.icon(status), size: 10, color: _Status.fg(status)),
            const SizedBox(width: 4),
            Text(status,
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: _Status.fg(status), letterSpacing: 0.1,
                )),
          ],
        ),
      );
}

// ─── Modal ────────────────────────────────────────────────────────────────────
class _LeaveModal extends StatefulWidget {
  final Map<String, dynamic>? leaveType;
  final String status;
  final List leaveDates;
  final List attachments;
  final String reason;
  final List remarks;
  final String leaveImage;

  const _LeaveModal({
    required this.leaveType,
    required this.status,
    required this.leaveDates,
    required this.attachments,
    required this.reason,
    required this.remarks,
    required this.leaveImage,
  });

  @override
  State<_LeaveModal> createState() => _LeaveModalState();
}

class _LeaveModalState extends State<_LeaveModal>
    with SingleTickerProviderStateMixin {
  String _tab = 'approval';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 12, right: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _T.divider, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: _T.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),

            // Header
            _ModalHeader(
              leaveImage: widget.leaveImage,
              leaveName:  widget.leaveType?['name'] ?? 'Leave',
              status:     widget.status,
            ),

            // Body
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.70),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dates
                    if (widget.leaveDates.isNotEmpty)
                      EnhancedLeaveDatesSection(
                        rawDates: widget.leaveDates,
                        defaultView: LeaveDatesViewType.timeline,
                      ),

                    const SizedBox(height: 12),

                    // Reason card
                    _InfoCard(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Reason',
                      child: Text(
                        widget.reason.isNotEmpty ? widget.reason : 'No reason provided.',
                        style: _T.body(size: 13, color: _T.textSub),
                      ),
                    ),

                    // Attachments card
                    if (widget.attachments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _InfoCard(
                        icon: Icons.attach_file_rounded,
                        label: 'Attachments',
                        child: Column(
                          children: widget.attachments.asMap().entries.map((e) =>
                              _AttachmentRow(
                                attachment: e.value,
                                isLast: e.key == widget.attachments.length - 1,
                              )).toList(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Tab toggle
                    _TabToggle(
                      selected: _tab,
                      onChanged: (v) => setState(() => _tab = v),
                    ),
                    const SizedBox(height: 14),

                    // Tab content
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve:  Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _tab == 'approval'
                          ? _ApprovalTimeline(
                              key: const ValueKey('a'),
                              leaveType: widget.leaveType)
                          : _RemarksView(
                              key: const ValueKey('r'),
                              remarks: widget.remarks),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Modal header ─────────────────────────────────────────────────────────────
class _ModalHeader extends StatelessWidget {
  final String leaveImage, leaveName, status;
  const _ModalHeader({required this.leaveImage, required this.leaveName, required this.status});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 14),
        decoration: BoxDecoration(
          color: _T.surface,
          border: Border(bottom: BorderSide(color: _T.divider, width: 0.5)),
        ),
        child: Row(
          children: [
            // Image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: _T.cardShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(leaveImage, width: 46, height: 46, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(leaveName,
                      style: _T.heading(size: 15, w: FontWeight.w800),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  _StatusPill(status: status),
                ],
              ),
            ),

            // Close button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: _T.bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: _T.divider, width: 0.5),
                ),
                child: const Icon(Icons.close_rounded, size: 16, color: _T.textSub),
              ),
            ),
          ],
        ),
      );
}

// ─── Info card wrapper ────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  const _InfoCard({required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.divider, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: _T.blueSoft, borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 14, color: _T.blue),
                  ),
                  const SizedBox(width: 9),
                  Text(label, style: _T.heading(size: 13, w: FontWeight.w700)),
                ],
              ),
            ),
            Container(height: 0.5, color: _T.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: child,
            ),
          ],
        ),
      );
}

// ─── Attachment row ───────────────────────────────────────────────────────────
class _AttachmentRow extends StatelessWidget {
  final dynamic attachment;
  final bool isLast;
  const _AttachmentRow({required this.attachment, required this.isLast});

  void _open(BuildContext ctx) {
    final url = Uri.encodeFull(
        'https://fo2-staff-search.dswd.gov.ph/${attachment['path']}');
    Navigator.push(ctx, MaterialPageRoute(
      builder: (_) => ReusableWebViewScreen(
        url: url,
        title: attachment['path'] ?? 'Attachment',
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final name = (attachment['path'] as String?)?.split('/').last ?? 'File';
    return Column(
      children: [
        GestureDetector(
          onTap: () => _open(context),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: _T.blueSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.insert_drive_file_rounded, size: 16, color: _T.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(name,
                    style: _T.body(size: 13, w: FontWeight.w500, color: _T.blue),
                    overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.open_in_new_rounded, size: 13, color: _T.textMuted),
            ],
          ),
        ),
        if (!isLast) ...[
          const SizedBox(height: 10),
          Container(height: 0.5, color: _T.divider),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

// ─── Tab toggle ───────────────────────────────────────────────────────────────
class _TabToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _TabToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: _T.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _T.divider, width: 0.5),
        ),
        child: Row(
          children: [
            _tab('Approval Flow', Icons.timeline_rounded,   'approval'),
            const SizedBox(width: 4),
            _tab('Remarks',       Icons.comment_outlined,   'remarks'),
          ],
        ),
      );

  Widget _tab(String label, IconData icon, String value) {
    final on = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: on ? _T.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: on ? _T.cardShadow : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: on ? _T.blue : _T.textMuted),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w400,
                    color: on ? _T.textPrimary : _T.textMuted,
                    letterSpacing: -0.1,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Approval timeline ────────────────────────────────────────────────────────
class _ApprovalTimeline extends StatelessWidget {
  final Map<String, dynamic>? leaveType;
  const _ApprovalTimeline({super.key, required this.leaveType});

  @override
  Widget build(BuildContext context) {
    final steps = ApprovalDataExtractor.extractApprovalSteps(leaveType ?? {});

    if (steps.isEmpty) {
      return _EmptyState(
          icon: Icons.timeline_rounded, message: 'No approval data available');
    }

    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.divider, width: 0.5),
      ),
      child: Column(
        children: steps.asMap().entries.map((e) =>
            _TimelineStep(step: e.value, index: e.key, total: steps.length),
        ).toList(),
      ),
    );
  }
}

// ─── Timeline step ────────────────────────────────────────────────────────────
class _TimelineStep extends StatelessWidget {
  final ApprovalStep step;
  final int index;
  final int total;

  const _TimelineStep({
    required this.step,
    required this.index,
    required this.total,
  });

  // Step number label — e.g. "01", "02"
  String get _stepNum => index.toString().padLeft(2, '0');

  BorderRadius get _rowRadius {
    if (total == 1) return BorderRadius.circular(16);
    if (index == 0) return const BorderRadius.vertical(top: Radius.circular(16));
    if (index == total - 1) return const BorderRadius.vertical(bottom: Radius.circular(16));
    return BorderRadius.zero;
  }

  @override
  Widget build(BuildContext context) {
    final isLast      = step.isLast;
    final isDone      = step.timestamp != null;
    final isRejected  = step.isRejectedOrCancelled;

    final Color accentColor = isRejected
        ? _T.red
        : isDone
            ? _T.green
            : _T.textMuted;

    final Color softColor = isRejected
        ? _T.redSoft
        : isDone
            ? _T.greenSoft
            : _T.bg;

    return Column(
      children: [
        // ── Row ───────────────────────────────────────────────────
        ClipRRect(
          borderRadius: _rowRadius,
          child: Container(
            color: isDone && !isRejected
                ? _T.green.withOpacity(0.02)
                : Colors.transparent,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // ── Step indicator ─────────────────────────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Circle icon
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: softColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDone || isRejected
                              ? accentColor.withOpacity(0.35)
                              : _T.divider,
                          width: 1.5,
                        ),
                      ),
                      child: isDone
                          ? Icon(
                              isRejected
                                  ? Icons.close_rounded
                                  : Icons.check_rounded,
                              size: 17,
                              color: accentColor,
                            )
                          : Center(
                              child: Text(
                                _stepNum,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _T.textMuted,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // ── Content ────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step label
                      Text(
                        step.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDone ? accentColor : _T.textMuted,
                          letterSpacing: 0.3,
                        ),
                      ),

                      // Timestamp
                      if (step.formattedTime.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 11,
                              color: accentColor.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              step.formattedTime,
                              style: TextStyle(
                                fontSize: 11,
                                color: accentColor.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 4),
                        Text(
                          'Awaiting',
                          style: TextStyle(
                            fontSize: 11,
                            color: _T.textMuted.withOpacity(0.6),
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Status badge ───────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: softColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDone || isRejected
                          ? accentColor.withOpacity(0.25)
                          : _T.divider,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    isRejected
                        ? 'Rejected'
                        : isDone
                            ? 'Done'
                            : 'Pending',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Divider / connector ────────────────────────────────────
        if (!isLast)
          Row(
            children: [
              // Aligns with center of the 38px circle (16 padding + 19 center)
              const SizedBox(width: 35),
              Container(
                width: 1.5,
                height: 1,
                color: Colors.transparent,
              ),
              Container(
                width: 1.5,
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(isDone ? 0.35 : 0.15),
                      _T.divider,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),

        // Hairline row separator (not on last)
        if (!isLast)
          Container(height: 0.5, color: _T.divider),
      ],
    );
  }
}
// ─── Remarks view ─────────────────────────────────────────────────────────────
class _RemarksView extends StatelessWidget {
  final List remarks;
  const _RemarksView({super.key, required this.remarks});

  @override
  Widget build(BuildContext context) {
    if (remarks.isEmpty) {
      return _EmptyState(icon: Icons.comment_outlined, message: 'No remarks yet');
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.divider, width: 0.5),
      ),
      child: RemarksPerStage(remarks: remarks),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: const BoxDecoration(color: _T.bg, shape: BoxShape.circle),
                child: Icon(icon, size: 26, color: _T.textMuted),
              ),
              const SizedBox(height: 10),
              Text(message,
                  style: TextStyle(fontSize: 13, color: _T.textMuted, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
}