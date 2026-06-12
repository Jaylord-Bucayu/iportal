import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QrApprovalInfoScreen extends StatelessWidget {
  final Map<String, dynamic> scannedData;

  const QrApprovalInfoScreen({Key? key, required this.scannedData})
      : super(key: key);

  Future<void> _handleAction(
      BuildContext context, String action) async {
    try {
      final response = await http.post(
        Uri.parse("https://your-api.com/qr/approval"), // 🔹 change to your endpoint
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": scannedData['id'],
          "action": action, // "accept" or "decline"
        }),
      );

      if (response.statusCode == 200) {
        // ✅ Successfully updated
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      } else {
        // ❌ Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          Navigator.pushReplacementNamed(context, 'pass_slip');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // ✅ Circular Progress / Success Icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.shade50,
                      ),
                    ),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.shade100,
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.primaries[4],
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 30),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ✅ Title and subtitle
                const Text(
                  "Approval In Progress",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "There are many variations",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 30),

                // ✅ Info section
                _buildInfoRow("Purpose:", scannedData['purpose'] ?? "N/A"),
                _buildInfoRow("Date:", scannedData['created_at'] ?? "N/A"),
                _buildInfoRow("Staff ID:", (scannedData['staff_id']?.toString()) ?? "N/A"),
                _buildInfoRow("Status:", scannedData['status'] ?? "N/A"),

                const Divider(thickness: 1, height: 30),

                // ✅ Total row
                _buildInfoRow("ID:", scannedData['id'].toString(), isTotal: true),

                const Spacer(),

                // ✅ Accept button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.primaries[4],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _handleAction(context, "accept"),
                    child: const Text(
                      "Accept",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),

               const SizedBox(height: 12.0),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.grey.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _handleAction(context, "decline"),
                    child: const Text(
                      "Decline",
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ),
                ),

                // const SizedBox(height: 12.0),

                // ❌ Decline button
                // SizedBox(
                //   width: double.infinity,
                //   child: OutlinedButton(
                //     style: OutlinedButton.styleFrom(
                //       padding: const EdgeInsets.symmetric(vertical: 15),
                //       side: const BorderSide(color: Colors.white, width: 2),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(10),
                //       ),
                //     ),
                //     onPressed: () => _handleAction(context, "decline"),
                //     child: const Text(
                //       "Decline",
                //       style: TextStyle(fontSize: 16, color: Colors.red),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable info row
  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.blue : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
