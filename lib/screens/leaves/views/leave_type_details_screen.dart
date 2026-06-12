import 'package:flutter/material.dart';

class LeaveTypeDetails extends StatelessWidget {
  final String title;
  final String imagePath;

  const LeaveTypeDetails({
    super.key,
    required this.title,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔹 HEADER IMAGE WITH TITLE
            Stack(
              children: [
                SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: ClipRRect(
                    child: Image.asset(
                      imagePath, // now dynamic
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                /// Dark overlay
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                /// Title
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Text(
                    title, // now dynamic
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                /// Close Button
                Positioned(
                  top: 40,
                  right: 20,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      iconSize: 20.00,
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔹 INFO ROW
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  InfoItem(icon: Icons.schedule, label: "15 Days"),
                  InfoItem(icon: Icons.people, label: "2-3 Eligible"),
                  InfoItem(icon: Icons.verified, label: "Easy Approval"),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// 🔹 ELIGIBILITY SECTION
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Requirements",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 40,
                runSpacing: 10,
                children: const [
                  BulletItem(text: "Medical Certificate"),
                  BulletItem(text: "Manager Approval"),
                  BulletItem(text: "Leave Form"),
                  BulletItem(text: "HR Validation"),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// 🔹 PROCESS SECTION
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Application Process",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 15),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  StepItem(
                    number: 1,
                    text: "Select leave dates and type.",
                  ),
                  SizedBox(height: 12),
                  StepItem(
                    number: 2,
                    text: "Upload required documents.",
                  ),
                  SizedBox(height: 12),
                  StepItem(
                    number: 3,
                    text: "Submit for approval.",
                  ),
                  SizedBox(height: 12),
                  StepItem(
                    number: 4,
                    text: "Wait for HR confirmation.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// 🔹 TIP CONTAINER
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Tip",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Submit your leave request at least 3 days before your intended leave date.",
                          ),
                        ],
                      ),
                    )
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

/// 🔹 INFO ITEM
class InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const InfoItem({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}

/// 🔹 BULLET ITEM
class BulletItem extends StatelessWidget {
  final String text;

  const BulletItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.circle, size: 8, color: Colors.green),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}

/// 🔹 STEP ITEM
class StepItem extends StatelessWidget {
  final int number;
  final String text;

  const StepItem({
    super.key,
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.green,
          child: Text(
            number.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}
