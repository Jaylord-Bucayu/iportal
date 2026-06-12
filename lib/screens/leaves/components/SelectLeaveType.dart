import 'package:flutter/material.dart';
import 'package:shop/route/route_constants.dart';

class LeaveTypeList extends StatelessWidget {
  const LeaveTypeList({super.key});

  // SAMPLE DATA
  List<LeaveType> get _leaveTypes => [
        LeaveType(
          name: 'Sick Leave',
          shortDescription:
              'For employees who are unable to work due to illness.',
          fullDescription:
              'Sick leave allows employees to take time off when they are ill '
              'or need medical attention. Supporting documents may be required.',
          imageAsset: 'assets/images/sick_leave.png',
          bannerImage: 'assets/images/leave_banner.png',
        ),
        LeaveType(
          name: 'Vacation Leave',
          shortDescription:
              'Planned leave for rest, travel, or personal matters.',
          fullDescription:
              'Vacation leave is used for personal time off such as travel, '
              'family matters, or rest and recreation.',
          imageAsset: 'assets/images/vacation_leave.png',
          bannerImage: 'assets/images/leave_banner.png',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _leaveTypes.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final leave = _leaveTypes[index];

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, leaveTypeDetailscreenRoute),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                // LEFT IMAGE
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    leave.imageAsset,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),

                // TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leave.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        leave.shortDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // RIGHT ARROW
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===============================
  // BOTTOM SHEET (DETAILS VIEW)
  // ===============================
  void _showLeaveDetails(BuildContext context, LeaveType leave) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return SingleChildScrollView(
              controller: controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DRAG HANDLE
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  // BANNER IMAGE
                  Image.asset(
                    leave.bannerImage,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      leave.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      leave.fullDescription,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ACTION BUTTON
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Apply Leave'),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ===============================
// MODEL
// ===============================
class LeaveType {
  final String name;
  final String shortDescription;
  final String fullDescription;
  final String imageAsset;
  final String bannerImage;

  LeaveType({
    required this.name,
    required this.shortDescription,
    required this.fullDescription,
    required this.imageAsset,
    required this.bannerImage,
  });
}
