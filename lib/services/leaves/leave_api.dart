import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop/models/leave_type_model.dart';

class LeavesApi {
  static const String baseUrl = "http://172.31.16.69/api/v1"; // ← change this

  /// Fetch upcoming leaves
  static Future<List<EventItem>> getUpcomingLeaves() async {
    final url = Uri.parse("$baseUrl/upcoming-leaves");

    final response = await http.get(url, headers: {
      "Accept": "application/json",
      // "Authorization": "Bearer YOUR_TOKEN", // ← add if needed
    });

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((json) => EventItem.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load upcoming leaves");
    }
  }

  /// 🔥 Fetch leave balance (e.g. /api/v1/leave-balances/215463)
  static Future<LeaveBalance> getLeaveBalance(int employeeId) async {
    final url = Uri.parse("$baseUrl/leave-balances/$employeeId");

    try {
      final response = await http.get(url, headers: {
        "Accept": "application/json",
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // Check if "data" exists
        if (decoded["data"] == null) {
          throw Exception("API returned null data for leave balance");
        }

        final data = decoded["data"];
        return LeaveBalance.fromJson(data);
      } else {
        throw Exception(
            "Failed to load leave balance. Status code: ${response.statusCode}");
      }
    } catch (e) {
      // Print the error to console
      print("Error in getLeaveBalance: $e");

      // Rethrow so caller can handle it
      throw Exception("Error fetching leave balance: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> fetchPendingLeaves(
      {required int staffId}) async {
    final url =
        Uri.parse("$baseUrl/leave-pending/staff/$staffId");

    final response = await http.post(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['status'] == true && jsonData['data'] != null) {
        // Convert each item to Map<String, dynamic>
        return List<Map<String, dynamic>>.from(jsonData['data']);
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to fetch leave requests');
    }
  }
}
