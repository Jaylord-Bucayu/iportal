import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LeaveApprovalConfimationScreen extends StatefulWidget {
  final String leaveId; // Accept leave request ID

  const LeaveApprovalConfimationScreen({super.key, required this.leaveId});

  @override
  State<LeaveApprovalConfimationScreen> createState() =>
      _LeaveApprovalConfimationScreenState();
}

class _LeaveApprovalConfimationScreenState
    extends State<LeaveApprovalConfimationScreen> {
  final TextEditingController _remarksController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleAction(String action) async {
    setState(() {
      _isLoading = true;
    });

    final remarks = _remarksController.text;

    try {
      // Replace with your actual API endpoint
      final uri = Uri.parse('https://example.com/api/leaves/${widget.leaveId}/$action');
      final response = await http.post(
        uri,
        body: {'remarks': remarks},
      );

      if (response.statusCode == 200) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$action successful')),
        );
        Navigator.of(context).pop(true); // Return true to previous screen
      } else {
        // Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to $action leave')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Leave Approval"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Are you sure?",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Please confirm if you want to approve this leave request. "
                  "You may add remarks before proceeding.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Image.asset(
                  "assets/approval.png", // Replace with your image
                  height: 150,
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: _remarksController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Remarks",
                    hintText: "Enter remarks (optional)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleAction("approve"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Approve",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _handleAction("decline"),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.red)
                        : const Text(
                            "Decline",
                            style: TextStyle(fontSize: 16, color: Colors.red),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}