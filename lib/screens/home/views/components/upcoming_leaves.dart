import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop/route/screen_export.dart';

const Map<int, String> leaveTypeNames = {
  1: 'Vacation Leave',
  2: 'Sick Leave',
  3: 'Emergency Leave',
};

class EventItem {
  final String id;
  final String leaveType;
  final String staffName;
  final String imageUrl;
  final int staffId;

  EventItem({
    required this.id,
    required this.leaveType,
    required this.staffName,
    required this.imageUrl,
    required this.staffId,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    final int typeId = json['leave_type_id'] ?? 0;
    return EventItem(
      id: json['id'].toString(),
      leaveType: leaveTypeNames[typeId] ?? 'Unknown Leave',
      staffName: json['staff_name'] ?? '',
      staffId: json['staff_id'] ?? 0,
      imageUrl: 'https://fo2-staff-search.dswd.gov.ph/images/${json['staff_id']}.jpg',
    );
  }
}


  class LeaveResponse {
  final List<EventItem> data;
  final int totalCount;

  LeaveResponse({
    required this.data,
    required this.totalCount,
  });

  factory LeaveResponse.fromJson(Map<String, dynamic> json) {
    return LeaveResponse(
      data: (json['data'] as List)
          .map((e) => EventItem.fromJson(e))
          .toList(),
      totalCount: json['total_count'] ?? 0,
    );
  }
}

class UpcomingLeaves extends StatelessWidget {
  final String status;
  final int limit;
  final String headerTitle;
  final int authorityId;

  const UpcomingLeaves({
    super.key,
    required this.status,
    this.limit = 5,
    this.headerTitle = "Awaiting Approval",
    required this.authorityId,
  });





Future<LeaveResponse> fetchUpcomingLeaves() async {
  final url = Uri.parse(
    'http://172.31.16.69/api/v1/leave-pending/authority?limit=$limit'
  );

  final body = jsonEncode({
    'authority_type': status,
    'authority_id': authorityId
  });

  final response = await http.post(
    url,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    },
    body: body,
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return LeaveResponse.fromJson(data);
  } else {
    throw Exception('Failed to load leaves');
  }
}


  Widget _buildShimmer() {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            width: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  // Summary card — count + stacked avatars
 Widget _buildSummaryCard(BuildContext context, List<EventItem> events, int totalEvents) {
  const int maxAvatars = 4;
  final shown = events.take(maxAvatars).toList();
  final extra = events.length - maxAvatars;

  return GestureDetector(
    onTap: () => Navigator.pushNamed(
    context,
    leaveListForApprovalLeavecreenRoute,
    arguments: {
      'status': status,
      'authorityType': status,
      'authorityId': authorityId,
    },
  ),
    child: Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F0FF), 
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Count
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${totalEvents > 10 ? '10+' : totalEvents}', // Cap at 99+
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D47A1), // <-- dark blue for contrast
                      height: 1,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        leaveListForApprovalLeavecreenRoute,
                        arguments: {
                          'status': status,
                          'authorityType': status,
                          'authorityId': authorityId,
                        },
                      );
                    },
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D47A1),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Awaiting your\napproval',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0D47A1), // <-- readable on light bg
                  height: 1.4,
                ),
              ),
            ],
          ),

          // Stacked avatars + +N
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: 28,
                width: (shown.length * 20.0) + 8,
                child: Stack(
                  children: List.generate(shown.length, (i) {
                    return Positioned(
                      left: i * 20.0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF90CAF9),
                          backgroundImage: NetworkImage(shown[i].imageUrl),
                          onBackgroundImageError: (_, __) {},
                        ),
                      ),
                    );
                  }),
                ),
              ),

              if (extra > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBBDEFB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '+$extra',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D47A1),
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

  // Individual leave card
  Widget _buildLeaveCard(BuildContext context, EventItem e) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        leaveDetailsScreenRoute,
        arguments: e.id,
      ),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
         
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE7F0FF), width: 2),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE7F0FF),
                backgroundImage: NetworkImage(e.imageUrl),
                onBackgroundImageError: (_, __) {},
                child: e.imageUrl.isEmpty
                    ? const Icon(Icons.person_rounded, size: 20, color: Color(0xFF0866FF))
                    : null,
              ),
            ),

            // Name + leave type
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.staffName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF050505),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F0FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    e.leaveType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0866FF),
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

@override
Widget build(BuildContext context) {
  return FutureBuilder<LeaveResponse>(
    future: fetchUpcomingLeaves(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _buildShimmer();
      } else if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      } else if (!snapshot.hasData || snapshot.data!.data.isEmpty) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E6EB)),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/images/eyes_1f440.png',
                width: 32,
                height: 32,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nothing pending right now',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'See previously approved leaves',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: Colors.black45,
              ),
            ],
          ),
        );
      }

      // ✅ FIXED: response wrapper
      final response = snapshot.data!;
      final events = response.data;
      final totalEvents = response.totalCount;

      return SizedBox(
        height: 160,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: events.length + 1, // +1 for summary card
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildSummaryCard(context, events,totalEvents);
            }
            return _buildLeaveCard(context, events[index - 1]);
          },
        ),
      );
    },
  );
}
}