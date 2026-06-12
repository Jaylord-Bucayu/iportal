import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:shop/components/resuable_webapp_view.dart';
import 'package:shop/screens/leaves/components/RemarksPerStage.dart';

/// Core constants for the leave request UI
class LeaveRequestConstants {
  static const double modalBorderRadius = 24;
  static const double cardBorderRadius = 12;
  static const double avatarSize = 40;
  static const double timelineIconSize = 24;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double defaultPadding = 16;
  static const double defaultSizedBoxHeight = 12;
}

/// Color scheme for leave statuses
class LeaveStatusTheme {
  static const Map<String, Color> statusColors = {
    'approved': Color(0xFF10B981),
    'rejected': Color(0xFFF43F5E),
    'pending': Color(0xFFF59E0B),
    'draft': Color(0xFF6B7280),
  };

  static Color getStatusColor(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('approved')) return statusColors['approved']!;
    if (lowerStatus.contains('rejected')) return statusColors['rejected']!;
    if (lowerStatus.contains('draft')) return statusColors['draft']!;
    return statusColors['pending']!;
  }

  static Color getStatusBackgroundColor(String status) {
    return getStatusColor(status).withOpacity(0.1);
  }
}

/// Models for structured data
class ApprovalStep {
  final String key;
  final String displayName;
  final DateTime? timestamp;
  final bool isRejectedOrCancelled;
  final bool isLast;

  ApprovalStep({
    required this.key,
    required this.displayName,
    this.timestamp,
    required this.isRejectedOrCancelled,
    required this.isLast,
  });

  Color get iconColor =>
      isRejectedOrCancelled ? Colors.red : const Color(0xFF10B981);

  String get formattedTime {
    if (timestamp == null) return '';
    return DateFormat('MMM d, h:mm a').format(timestamp!);
  }
}

/// Extract and parse approval data from leave data
class ApprovalDataExtractor {
  static List<ApprovalStep> extractApprovalSteps(Map<String, dynamic> leaveData) {
    final approvalsRaw = leaveData['approvals'];
    final approvals = approvalsRaw is List
        ? approvalsRaw
        : approvalsRaw is Map
            ? [approvalsRaw]
            : [];

    if (approvals.isEmpty) return [];

    final approval = approvals.first as Map<String, dynamic>;

    const stepKeys = [
      'on_draft',
      'for_supervisor_review',
      'for_hr_review',
      'for_hr_dc_review',
      'for_arda_review',
      'approved',
      'rejected',
      'cancelled',
    ];

    final activeSteps =
        stepKeys.where((key) => approval[key] != null).toList();

    if (activeSteps.isEmpty) return [];

    return activeSteps.asMap().entries.map((entry) {
      final index = entry.key;
      final key = entry.value;
      final isLast = index == activeSteps.length - 1;
      final timestampRaw = approval[key];

      DateTime? dateTime;
      if (timestampRaw != null) {
        dateTime = DateTime.tryParse(timestampRaw.toString());
      }

      return ApprovalStep(
        key: key,
        displayName: key.replaceAll('_', ' ').toUpperCase(),
        timestamp: dateTime,
        isRejectedOrCancelled: key == 'rejected' || key == 'cancelled',
        isLast: isLast,
      );
    }).toList();
  }
}

/// Main widget
class PendingLeaveRequest extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic> leaveData;

  const PendingLeaveRequest({
    Key? key,
    required this.imagePath,
    required this.leaveData,
  }) : super(key: key);

  @override
  State<PendingLeaveRequest> createState() => _PendingLeaveRequestState();
}

class _PendingLeaveRequestState extends State<PendingLeaveRequest>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrowController;

  final Map<String, String> leaveTypeImages = {
    'Vacation Leave': 'assets/images/vacation.png',
    'Sick Leave': 'assets/images/sick.png',
    'Emergency Leave': 'assets/images/emergency.png',
    'Special Privilege Leave': 'assets/images/spl.png',
  };

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(
      vsync: this,
      duration: LeaveRequestConstants.animationDuration,
    );
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  String _getLeaveImage(String? leaveName) {
    if (leaveName == null) return 'assets/images/default.jpg';
    return leaveTypeImages[leaveName] ?? 'assets/images/default.jpg';
  }

  void _showPendingModal() async {
    if (widget.leaveData.isEmpty) return;

    final leaveDates =
        jsonDecode(widget.leaveData['leave_dates'] ?? '[]') as List<dynamic>;
    final attachments =
        widget.leaveData['attachments'] as List<dynamic>? ?? [];
    final status = widget.leaveData['status'] ?? '';
    final leaveType = widget.leaveData['leave_type'];
    final reason = widget.leaveData['reason'] ?? '';
    final remarks = widget.leaveData['remarks'] ?? [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LeaveRequestModal(
        leaveType: leaveType,
        status: status,
        leaveDates: leaveDates,
        attachments: attachments,
        reason: reason,
        remarks: remarks,
        leaveImage: _getLeaveImage(leaveType?['name']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.leaveData.isEmpty) return const SizedBox.shrink();

    final leaveType = widget.leaveData['leave_type'];
    final status = widget.leaveData['status'] ?? '';

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(LeaveRequestConstants.cardBorderRadius),
          onTap: _showPendingModal,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: LeaveRequestConstants.defaultPadding,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1F2937), Color(0xFF111827)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.circular(LeaveRequestConstants.cardBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Leave type avatar
                _LeaveTypeAvatar(
                  imagePath: _getLeaveImage(leaveType?['name']),
                  leaveName: leaveType?['name'] ?? 'Leave',
                ),
                const SizedBox(width: LeaveRequestConstants.defaultPadding),
                // Leave info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leaveType?['name'] ?? 'Leave',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: LeaveStatusTheme.getStatusBackgroundColor(status),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: LeaveStatusTheme.getStatusColor(status),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow animation
                _AnimatedArrow(controller: _arrowController),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated arrow component
class _AnimatedArrow extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedArrow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: controller.value * 3.14159,
          child: const Icon(
            Icons.arrow_upward,
            color: Colors.white,
            size: 20,
          ),
        );
      },
    );
  }
}

/// Leave type avatar with shadow
class _LeaveTypeAvatar extends StatelessWidget {
  final String imagePath;
  final String leaveName;

  const _LeaveTypeAvatar({
    required this.imagePath,
    required this.leaveName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(LeaveRequestConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(LeaveRequestConstants.cardBorderRadius),
        child: Image.asset(
          imagePath,
          width: LeaveRequestConstants.avatarSize,
          height: LeaveRequestConstants.avatarSize,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Modal widget for leave request details
class _LeaveRequestModal extends StatefulWidget {
  final Map<String, dynamic>? leaveType;
  final String status;
  final List<dynamic> leaveDates;
  final List<dynamic> attachments;
  final String reason;
  final List<dynamic> remarks;
  final String leaveImage;

  const _LeaveRequestModal({
    required this.leaveType,
    required this.status,
    required this.leaveDates,
    required this.attachments,
    required this.reason,
    required this.remarks,
    required this.leaveImage,
  });

  @override
  State<_LeaveRequestModal> createState() => _LeaveRequestModalState();
}

class _LeaveRequestModalState extends State<_LeaveRequestModal>
    with SingleTickerProviderStateMixin {
  late String _selectedView = "approval";
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedView = _tabController.index == 0 ? "approval" : "remarks";
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leaveName = widget.leaveType?['name'] ?? 'Leave';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(
            Radius.circular(LeaveRequestConstants.modalBorderRadius),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _ModalHeader(
                leaveImage: widget.leaveImage,
                leaveName: leaveName,
                status: widget.status,
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(LeaveRequestConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leave dates section
                    if (widget.leaveDates.isNotEmpty)
                      _LeaveDatesSection(dates: widget.leaveDates),

                    // Reason section
                    _ReasonSection(reason: widget.reason),

                    // Attachments section
                    if (widget.attachments.isNotEmpty)
                      _AttachmentsSection(
                        attachments: widget.attachments,
                        context: context,
                      ),

                    const SizedBox(height: LeaveRequestConstants.defaultSizedBoxHeight),

                    // Tabs
                    _TabsSection(
                      selectedView: _selectedView,
                      tabController: _tabController,
                      onTabChange: (view) {
                        setState(() => _selectedView = view);
                      },
                    ),

                    const SizedBox(height: LeaveRequestConstants.defaultSizedBoxHeight),

                    // Tab content
                    if (_selectedView == "approval")
                      _ApprovalContent(leaveType: widget.leaveType)
                    else
                      _RemarksContent(remarks: widget.remarks),
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

/// Modal header component
class _ModalHeader extends StatelessWidget {
  final String leaveImage;
  final String leaveName;
  final String status;

  const _ModalHeader({
    required this.leaveImage,
    required this.leaveName,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: LeaveRequestConstants.defaultPadding,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F2937), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              leaveImage,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leaveName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: LeaveStatusTheme.getStatusBackgroundColor(status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: LeaveStatusTheme.getStatusColor(status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          CloseButton(color: Colors.white),
        ],
      ),
    );
  }
}

/// Leave dates section
class _LeaveDatesSection extends StatelessWidget {
  final List<dynamic> dates;

  const _LeaveDatesSection({required this.dates});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Leave Dates",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: dates.map((d) {
              final date = d['date'] ?? '';
              final type = d['type'] ?? '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$date • $type',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: LeaveRequestConstants.defaultSizedBoxHeight),
      ],
    );
  }
}

/// Reason section
class _ReasonSection extends StatelessWidget {
  final String reason;

  const _ReasonSection({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Reason",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            reason.isNotEmpty ? reason : 'No reason provided',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: LeaveRequestConstants.defaultSizedBoxHeight),
      ],
    );
  }
}

/// Attachments section
class _AttachmentsSection extends StatelessWidget {
  final List<dynamic> attachments;
  final BuildContext context;

  const _AttachmentsSection({
    required this.attachments,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Attachments",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: attachments.asMap().entries.map((entry) {
              final isLast = entry.key == attachments.length - 1;
              final attachment = entry.value;
              return _AttachmentTile(
                attachment: attachment,
                isLast: isLast,
                onTap: () => _openAttachment(context, attachment),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: LeaveRequestConstants.defaultSizedBoxHeight),
      ],
    );
  }

  void _openAttachment(BuildContext context, dynamic attachment) {
    final url = Uri.encodeFull(
      'https://fo2-staff-search.dswd.gov.ph/${attachment['path']}',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReusableWebViewScreen(
          url: url,
          title: attachment['path'] ?? 'Attachment',
        ),
      ),
    );
  }
}

/// Individual attachment tile
class _AttachmentTile extends StatelessWidget {
  final dynamic attachment;
  final bool isLast;
  final VoidCallback onTap;

  const _AttachmentTile({
    required this.attachment,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = (attachment['path'] as String?)?.split('/').last ?? 'File';

    return Column(
      children: [
        ListTile(
          dense: true,
          leading: const Icon(Icons.insert_drive_file, color: Colors.blue, size: 20),
          title: Text(
            fileName,
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
          onTap: onTap,
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade300),
      ],
    );
  }
}

/// Tabs section for approval/remarks toggle
class _TabsSection extends StatelessWidget {
  final String selectedView;
  final TabController tabController;
  final Function(String) onTabChange;

  const _TabsSection({
    required this.selectedView,
    required this.tabController,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: "Approval Timeline",
              isSelected: selectedView == "approval",
              onPressed: () => onTabChange("approval"),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TabButton(
              label: "Remarks",
              isSelected: selectedView == "remarks",
              onPressed: () => onTabChange("remarks"),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab button component
class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Approval timeline content
class _ApprovalContent extends StatelessWidget {
  final Map<String, dynamic>? leaveType;

  const _ApprovalContent({required this.leaveType});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Approval Progress',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _ApprovalTimeline(leaveType: leaveType),
      ],
    );
  }
}

/// Approval timeline widget
class _ApprovalTimeline extends StatelessWidget {
  final Map<String, dynamic>? leaveType;

  const _ApprovalTimeline({required this.leaveType});

  @override
  Widget build(BuildContext context) {
    final approvalSteps =
        ApprovalDataExtractor.extractApprovalSteps(leaveType ?? {});

    if (approvalSteps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No approval data available',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Column(
      children: approvalSteps.map((step) => _TimelineStep(step: step)).toList(),
    );
  }
}

/// Single timeline step
class _TimelineStep extends StatelessWidget {
  final ApprovalStep step;

  const _TimelineStep({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline connector
        Column(
          children: [
            // Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: step.iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: step.iconColor, width: 2),
              ),
              child: Center(
                child: Icon(
                  step.isRejectedOrCancelled ? Icons.close : Icons.check,
                  color: step.iconColor,
                  size: 18,
                ),
              ),
            ),
            // Vertical line
            if (!step.isLast)
              Container(
                width: 2,
                height: 48,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Step content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: step.isRejectedOrCancelled
                        ? Colors.red
                        : Colors.black87,
                  ),
                ),
                if (step.formattedTime.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      step.formattedTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Remarks content
class _RemarksContent extends StatelessWidget {
  final List<dynamic> remarks;

  const _RemarksContent({required this.remarks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Remarks',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        RemarksPerStage(remarks: remarks),
      ],
    );
  }
}
