import 'package:flutter/material.dart';

class LeaveRequest {
  final String? employeeName;
  final String? employeeImage; // URL or asset path
  final String? leaveType;
  final String? startDate;
  final String? endDate;
  final String? filledDate;
  final String? status;
  final String? purpose;
  final String? position;

  LeaveRequest({
    this.employeeName,
    this.employeeImage,
    this.leaveType,
    this.startDate,
    this.endDate,
    this.filledDate,
    this.status,
    this.purpose,
    this.position,
  });
}

class LeaveApprovalScreen extends StatefulWidget {
  const LeaveApprovalScreen({super.key});

  @override
  State<LeaveApprovalScreen> createState() => _LeaveApprovalScreenState();
}

class _LeaveApprovalScreenState extends State<LeaveApprovalScreen> {
  int selectedTab = 0;

  final List<LeaveRequest> leaveRequests = [
    LeaveRequest(
      employeeName: "John Doe",
      employeeImage: "https://i.pravatar.cc/150?img=1",
      leaveType: "Sick Leave",
      startDate: "11-26-2025",
      endDate: "11-27-2025",
      filledDate: "11-25-2025",
      status: "Pending",
      purpose: "Medical Checkup",
      position: "Software Engineer",
    ),
    LeaveRequest(
      employeeName: "Jane Smith",
      employeeImage: "https://i.pravatar.cc/150?img=2",
      leaveType: "Vacation Leave",
      startDate: "12-01-2025",
      endDate: "12-05-2025",
      filledDate: "11-20-2025",
      status: "Approved",
      purpose: "Family Vacation",
      position: "Project Manager",
    ),
    LeaveRequest(
      employeeName: "Mark Wilson",
      employeeImage: "https://i.pravatar.cc/150?img=3",
      leaveType: "Force Leave",
      startDate: "12-10-2025",
      endDate: "12-11-2025",
      filledDate: "12-09-2025",
      status: "Rejected",
      purpose: "Urgent Personal Matter",
      position: "Designer",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 8),
                          Text("Search", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune, color: Colors.black),
                  ),
                ],
              ),
            ),

            // TABS
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  tabButton("All Leaves", 0),
                  tabButton("Pending", 1),
                  tabButton("Approved", 2),
                  tabButton("Rejected", 3),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // MAIN LIST
            Expanded(
              child: ListView.builder(
                itemCount: leaveRequests.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  return leaveCard(leaveRequests[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAB BUTTON
  Widget tabButton(String text, int index) {
    final bool active = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: active ? Colors.blue.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.blue : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // LEAVE CARD
  Widget leaveCard(LeaveRequest leave) {
    Color statusColor;
    switch (leave.status ?? "") {
      case "Approved":
        statusColor = Colors.green;
        break;
      case "Pending":
        statusColor = Colors.orange;
        break;
      case "Rejected":
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
   
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEAVE TYPE + STATUS (Top Row)
          Container(
            
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
              padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  leave.leaveType ?? "-",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: statusColor.withOpacity(0.2),
                  ),
                  child: Text(
                    leave.status ?? "-",
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // EMPLOYEE IMAGE + NAME + POSITION
      Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8), // Add vertical padding
  child: Row(
    children: [
      CircleAvatar(
        radius: 22,
        backgroundImage: leave.employeeImage != null &&
                leave.employeeImage!.isNotEmpty
            ? NetworkImage(leave.employeeImage!)
            : const AssetImage("assets/images/default_avatar.png")
                as ImageProvider,
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            leave.employeeName ?? "-",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          Text(
            leave.position ?? "-",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    ],
  ),
),

          const SizedBox(height: 12),

         // DATES + PURPOSE + Filled/View Details
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8), // add vertical padding
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // DATES
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Start: ${leave.startDate ?? "-"}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            "End: ${leave.endDate ?? "-"}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      const SizedBox(height: 6),

      // PURPOSE BELOW DATES
      Text(
        "Purpose: ${leave.purpose ?? "-"}",
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      const SizedBox(height: 12),

      // FILLED DATE + VIEW DETAILS BUTTON
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Filled: ${leave.filledDate ?? "-"}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.primaries[4]),
            ),
            child: Text(
              "View Details",
              style: TextStyle(
                color: Colors.primaries[4],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
        const SizedBox(height: 8),

    ],
  ),
),
],
      ),
    );
  }
}
