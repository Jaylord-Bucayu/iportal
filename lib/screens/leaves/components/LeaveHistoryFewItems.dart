import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// apply_leave_screen.dart (re-exported here) declares its own DayPortion,
// which clashes with the one in LeaveDateSelector.dart, so hide it.
import 'package:shop/route/screen_export.dart' hide DayPortion;
import 'package:shop/screens/leaves/components/LeaveDateSelector.dart'; // LeaveDateItem, DayPortion
import 'package:shop/services/api_config.dart';

/// =========================
/// ENUM
/// =========================
enum LeaveStatus { draft, approved, pending, rejected }

/// =========================
/// MODEL
/// =========================
class LeaveRecord {
  final int id;
  final int leaveTypeId;
  final String type;
  final String reason;
  final DateTime startDate;
  final DateTime endDate;
  final LeaveStatus status;
  final List<Map<String, dynamic>> rawDates;
  final List<String> attachmentNames;

  LeaveRecord({
    required this.id,
    required this.leaveTypeId,
    required this.type,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.rawDates,
    required this.attachmentNames,
  });

  bool get isDraft => status == LeaveStatus.draft;

  /// Converts the API dates into the selector's items (used by the edit screen).
  List<LeaveDateItem> toDateItems() => rawDates.map((d) {
    final portion = switch (d['type']) {
      'AM_HALF' => DayPortion.am,
      'PM_HALF' => DayPortion.pm,
      _ => DayPortion.whole,
    };
    return LeaveDateItem(
      date: DateTime.parse(d['date'] as String),
      portion: portion,
    );
  }).toList();

  factory LeaveRecord.fromJson(Map<String, dynamic> json) {
    try {
      final rawLeaveDates = json['leave_dates'];
      final List dates = rawLeaveDates is String
          ? jsonDecode(rawLeaveDates)
          : (rawLeaveDates as List);

      final rawDates =
      dates.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      final parsedDates = rawDates
          .map((e) => DateTime.parse(e['date'] as String))
          .toList()
        ..sort();

      return LeaveRecord(
        id: json['id'] as int,
        leaveTypeId: int.tryParse(
            (json['leave_type_id'] ?? json['leave_type']?['id'])
                ?.toString() ??
                '') ??
            0,
        type: json['leave_type']?['name'] ?? 'Leave',
        reason: json['reason'] ?? '',
        startDate: parsedDates.first,
        endDate: parsedDates.last,
        status: _mapStatus(json['status']),
        rawDates: rawDates,
        attachmentNames: (json['attachments'] as List? ?? [])
            .map((a) => (a['path'] ?? '').toString().split('/').last)
            .toList(),
      );
    } catch (e) {
      print('LeaveRecord parsing error: $e');
      print(json);
      rethrow;
    }
  }

  static LeaveStatus _mapStatus(String? status) {
    final s = (status ?? '').trim().toLowerCase();
    if (s == 'on_draft' || s == 'draft') return LeaveStatus.draft;
    if (s == 'approved') return LeaveStatus.approved;
    if (s == 'rejected' || s == 'disapproved') return LeaveStatus.rejected;
    return LeaveStatus.pending;
  }
}

/// =========================
/// API SERVICE
/// =========================
class LeaveService {
  static Future<List<LeaveRecord>> fetchLeaves(int staffId) async {
    final url = Uri.parse(
        '${ApiConfig.leaveBase}/leave-requests/staff-id/$staffId?limit=3');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List data = jsonData['data'];
      return data.map((e) => LeaveRecord.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load leave records');
    }
  }
}

/// =========================
/// COMPONENT WIDGET
/// =========================
class LeaveHistoryComponent extends StatefulWidget {
  final int staffId;

  const LeaveHistoryComponent({super.key, required this.staffId});

  @override
  State<LeaveHistoryComponent> createState() => _LeaveHistoryComponentState();
}

class _LeaveHistoryComponentState extends State<LeaveHistoryComponent> {
  late Future<List<LeaveRecord>> _leaveFuture;

  @override
  void initState() {
    super.initState();
    _leaveFuture = LeaveService.fetchLeaves(widget.staffId);
  }

  void _reload() =>
      setState(() => _leaveFuture = LeaveService.fetchLeaves(widget.staffId));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LeaveRecord>>(
      future: _leaveFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final records = snapshot.data ?? [];

        if (records.isEmpty) {
          return const Center(child: Text('No leave records'));
        }

        return LeaveHistoryWidget(
          leaveRecords: records,
          staffId: widget.staffId,
          onChanged: _reload,
        );
      },
    );
  }
}

/// =========================
/// LIST WIDGET
/// =========================
class LeaveHistoryWidget extends StatelessWidget {
  final List<LeaveRecord> leaveRecords;
  final int staffId;
  final VoidCallback? onChanged;

  const LeaveHistoryWidget({
    super.key,
    required this.leaveRecords,
    required this.staffId,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: leaveRecords.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) => LeaveHistoryCard(
        record: leaveRecords[index],
        staffId: staffId,
        onChanged: onChanged,
      ),
    );
  }
}

/// =========================
/// CARD WIDGET
/// =========================
class LeaveHistoryCard extends StatelessWidget {
  final LeaveRecord record;
  final int staffId;
  final VoidCallback? onChanged;

  const LeaveHistoryCard({
    super.key,
    required this.record,
    required this.staffId,
    this.onChanged,
  });

  String getStatusText(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.draft:
        return 'Draft';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.rejected:
        return 'Rejected';
    }
  }

  String formatDateRange(DateTime start, DateTime end) {
    final startMonth = _getMonthName(start.month);
    final endMonth = _getMonthName(end.month);

    if (start.month == end.month && start.year == end.year) {
      return '$startMonth ${start.day} – ${end.day}, ${start.year}';
    } else if (start.year == end.year) {
      return '$startMonth ${start.day} – $endMonth ${end.day}, ${start.year}';
    } else {
      return '$startMonth ${start.day}, ${start.year} – $endMonth ${end.day}, ${end.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Future<void> _handleTap(BuildContext context) async {
    if (record.isDraft) {
      // Drafts open the edit screen.
      final updated = await Navigator.pushNamed<bool>(
        context,
        editLeaveScreenRoute,
        arguments: {
          'leaveId': record.id,
          'staffId': staffId,
          'leaveTypeId': record.leaveTypeId.toString(),
          'initialReason': record.reason,
          'initialDates': record.toDateItems(),
          'existingAttachmentNames': record.attachmentNames,
        },
      );

      if (updated == true) onChanged?.call(); // refresh the list
    } else {
      Navigator.pushNamed(
        context,
        leaveActionScreenRoute,
        arguments: record.id.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusText = getStatusText(record.status);
    final dateRange = formatDateRange(record.startDate, record.endDate);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.grey.withOpacity(0.06),
        highlightColor: Colors.grey.withOpacity(0.03),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            record.type,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateRange,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[500],
                      ),
                    ),
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