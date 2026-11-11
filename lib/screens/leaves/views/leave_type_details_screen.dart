import 'package:flutter/material.dart';

/// 🔹 CONFIG MODEL — holds all the rules/content that differ per leave type
class LeaveTypeConfig {
  final String duration;
  final String eligibility;
  final String approval;
  final List<String> requirements;
  final List<String> steps;
  final String tipTitle;
  final String tipText;

  const LeaveTypeConfig({
    required this.duration,
    required this.eligibility,
    required this.approval,
    required this.requirements,
    required this.steps,
    required this.tipTitle,
    required this.tipText,
  });
}

/// 🔹 CENTRAL LOOKUP — add/edit a leave type's rules here only
final Map<String, LeaveTypeConfig> leaveTypeConfigs = {
  "Vacation Leave": const LeaveTypeConfig(
    duration: "15 Days",
    eligibility: "2-3 Eligible",
    approval: "Manager Approval",
    requirements: [
      "Leave Form",
      "Manager Approval",
      "HR Validation",
    ],
    steps: [
      "Select your vacation leave dates.",
      "Submit your request at least 5 days before the leave date.",
      "Wait for manager approval.",
      "Wait for HR confirmation.",
    ],
    tipTitle: "Tip",
    tipText:
    "Vacation leave must be filed at least 5 days before your intended leave date. Late requests may not be approved.",
  ),

  "Sick Leave": const LeaveTypeConfig(
    duration: "15 Days",
    eligibility: "2-3 Eligible",
    approval: "Easy Approval",
    requirements: [
      "Medical Certificate",
      "File Attachment (within 5 days)",
      "Manager Approval",
      "HR Validation",
    ],
    steps: [
      "Select the sick leave date (past or future).",
      "Attach your medical certificate or supporting document.",
      "Submit within 5 days of the leave date.",
      "Wait for HR confirmation.",
    ],
    tipTitle: "Tip",
    tipText:
    "Sick leave can be filed for a previous or upcoming date, but a supporting file attachment (e.g. medical certificate) must be submitted within 5 days.",
  ),

  "Emergency Leave": const LeaveTypeConfig(
    duration: "3 Days",
    eligibility: "1-2 Eligible",
    approval: "Urgent Approval",
    requirements: [
      "Justification / Reason",
      "Manager Approval",
      "HR Validation",
    ],
    steps: [
      "Select today or tomorrow's date.",
      "State the reason for the emergency.",
      "Submit immediately for urgent review.",
      "Wait for HR confirmation.",
    ],
    tipTitle: "Tip",
    tipText:
    "Emergency leave can only be filed for today or the next day. Submit as soon as possible for faster urgent processing.",
  ),

  "Special Leave": const LeaveTypeConfig(
    duration: "7 Days",
    eligibility: "2-3 Eligible",
    approval: "HR Approval",
    requirements: [
      "Supporting Document",
      "Leave Form",
      "HR Validation",
    ],
    steps: [
      "Select leave dates and specify the special leave reason.",
      "Upload the supporting document (e.g. government/legal notice).",
      "Submit at least 7 days before the leave date.",
      "Wait for HR confirmation.",
    ],
    tipTitle: "Tip",
    tipText:
    "Special leave (SPL) requires a supporting document and should be filed at least 7 days in advance whenever possible.",
  ),

  "Forced Leave": const LeaveTypeConfig(
    duration: "5 Days",
    eligibility: "All Employees",
    approval: "Auto-Applied",
    requirements: [
      "HR Notice",
      "Acknowledgement",
    ],
    steps: [
      "HR issues a forced leave notice.",
      "Review the scheduled forced leave dates.",
      "Acknowledge the notice.",
      "Leave is automatically applied to your record.",
    ],
    tipTitle: "Tip",
    tipText:
    "Forced leave is scheduled by HR/management and applied automatically. No manual application is required — just acknowledge the notice.",
  ),
};

/// 🔹 DEFAULT FALLBACK — used if a title doesn't match any config above
const LeaveTypeConfig _defaultConfig = LeaveTypeConfig(
  duration: "15 Days",
  eligibility: "2-3 Eligible",
  approval: "Easy Approval",
  requirements: [
    "Leave Form",
    "Manager Approval",
    "HR Validation",
  ],
  steps: [
    "Select leave dates and type.",
    "Upload required documents.",
    "Submit for approval.",
    "Wait for HR confirmation.",
  ],
  tipTitle: "Tip",
  tipText:
  "Submit your leave request at least 3 days before your intended leave date.",
);

class LeaveTypeDetails extends StatelessWidget {
  final String title;
  final String imagePath;

  const LeaveTypeDetails({
    super.key,
    required this.title,
    required this.imagePath,
  });

  LeaveTypeConfig get _config => leaveTypeConfigs[title] ?? _defaultConfig;

  @override
  Widget build(BuildContext context) {
    final config = _config;

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
                      imagePath,
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
                    title,
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

            /// 🔹 INFO ROW — now dynamic per leave type
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InfoItem(icon: Icons.schedule, label: config.duration),
                  InfoItem(icon: Icons.people, label: config.eligibility),
                  InfoItem(icon: Icons.verified, label: config.approval),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// 🔹 ELIGIBILITY / REQUIREMENTS SECTION
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
                children: [
                  for (final req in config.requirements)
                    BulletItem(text: req),
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  for (int i = 0; i < config.steps.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    StepItem(
                      number: i + 1,
                      text: config.steps[i],
                    ),
                  ],
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
                        children: [
                          Text(
                            config.tipTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(config.tipText),
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
        Icon(icon, color: Colors.black),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 13),
          textAlign: TextAlign.center,
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
        const Icon(Icons.circle, size: 8, color: Colors.black),
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
          backgroundColor: Colors.black,
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