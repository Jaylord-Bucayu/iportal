import 'package:flutter/material.dart';

class DocsScreen extends StatelessWidget {
  const DocsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Request Documents",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Set the color of the back icon
        ),
        backgroundColor: Colors.primaries[4],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header for Start Investing Options
            Text(
              "Employment Requests",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.primaries[4]),
            ),
            const SizedBox(height: 16),

            const Wrap(
              alignment: WrapAlignment.start,
              spacing: 16, // Horizontal spacing
              runSpacing: 16, // Vertical spacing
              children: [
                InvestmentOption(
                  icon: Icons.book,
                  title: "COE",
                  subtitle: "Certificate of Employment",
                ),
                InvestmentOption(
                  icon: Icons.money,
                  title: "Payslip",
                  subtitle: "Payroll Payslip",
                ),
                InvestmentOption(
                  icon: Icons.door_sliding,
                  title: "Pass-slip",
                  subtitle: "Pass slip for personal/agency request",
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Row 2: Accounting Requests
            Text(
              "Accounting Requests",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.primaries[4]),
            ),
            const SizedBox(height: 16),
            const Wrap(
              alignment: WrapAlignment.start,
              spacing: 16, // Horizontal spacing
              runSpacing: 16, // Vertical spacing
              children: [
                InvestmentOption(
                  icon: Icons.money_off,
                  title: "Tax",
                  subtitle: "Review the taxes added",
                ),
                InvestmentOption(
                  icon: Icons.trending_up,
                  title: "Payments",
                  subtitle: "Transactions of your payments",
                ),
                InvestmentOption(
                  icon: Icons.trending_down,
                  title: "Deductions",
                  subtitle: "Amount deducted to your account",
                ),
              ],
            ),
   const SizedBox(height: 26),

            // Row 2: Budget Requests
            Text(
              "Budget Requests",
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.primaries[4]),
            ),
            const SizedBox(height: 16),

              const Wrap(
              alignment: WrapAlignment.start,
              spacing: 16, // Horizontal spacing
              runSpacing: 16, // Vertical spacing
              children: [
                InvestmentOption(
                  icon: Icons.attach_money,
                  title: "Cash Advance",
                  subtitle: "Request for a Cash advance",
                ),
                // InvestmentOption(
                //   icon: Icons.trending_up,
                //   title: "Payslip",
                //   subtitle: "Payroll Payslip",
                // ),
                InvestmentOption(
                  icon: Icons.car_rental,
                  title: "Travel Order",
                  subtitle: "Pass slip for personal/agency request",
                ),
              ],
            ),
  
          ],
        ),
      ),
    );
  }
}

class InvestmentOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isFullWidth;

  const InvestmentOption({super.key, 
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth
          ? double.infinity
          : MediaQuery.of(context).size.width / 3 - 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[100],
            child: Icon(icon, size: 30, color: Colors.primaries[4]),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
