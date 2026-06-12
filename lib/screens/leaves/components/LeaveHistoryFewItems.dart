import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop/route/screen_export.dart';

/// =========================
/// ENUM
/// =========================
enum LeaveStatus { approved, pending, rejected }

/// =========================
/// MODEL
/// =========================
class LeaveRecord {
  final int id;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final LeaveStatus status;

  LeaveRecord({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory LeaveRecord.fromJson(Map<String, dynamic> json) {
    try {
      final List dates = jsonDecode(json['leave_dates']);
      final parsedDates = dates
          .map((e) => DateTime.parse(e['date']))
          .toList()
        ..sort();

      final start = parsedDates.first;
      final end = parsedDates.last;

      return LeaveRecord(
        id: json['id'] as int,
        type: json['leave_type']?['name'] ?? 'Leave',
        startDate: start,
        endDate: end,
        status: _mapStatus(json['status']),
      );
    } catch (e) {
      print('LeaveRecord parsing error: $e');
      print(json);
      rethrow;
    }
  }

  static LeaveStatus _mapStatus(String status) {
    if (status == 'approved') return LeaveStatus.approved;
    if (status == 'rejected') return LeaveStatus.rejected;
    return LeaveStatus.pending;
  }
}

/// =========================
/// API SERVICE
/// =========================
class LeaveService {
  static Future<List<LeaveRecord>> fetchLeaves(int staffId) async {
    final url = Uri.parse(
        'http://172.31.16.69/api/v1/leave-requests/staff-id/$staffId?limit=3');

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

        return LeaveHistoryWidget(leaveRecords: records);
      },
    );
  }
}

/// =========================
/// LIST WIDGET
/// =========================
class LeaveHistoryWidget extends StatelessWidget {
  final List<LeaveRecord> leaveRecords;

  const LeaveHistoryWidget({super.key, required this.leaveRecords});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: leaveRecords.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return LeaveHistoryCard(record: leaveRecords[index]);
      },
    );
  }
}

/// =========================
/// CARD WIDGET
/// =========================
class LeaveHistoryCard extends StatelessWidget {
  final LeaveRecord record;

  const LeaveHistoryCard({super.key, required this.record});

  Color getStatusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.approved:
        return Colors.green;
      case LeaveStatus.pending:
        return Colors.orange;
      case LeaveStatus.rejected:
        return Colors.red;
    }
  }

  String getStatusText(LeaveStatus status) {
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(record.status);
    final statusText = getStatusText(record.status);
    final dateRange = formatDateRange(record.startDate, record.endDate);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          leaveActionScreenRoute,
          arguments: record.id.toString(),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.type,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateRange,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}