import 'dart:convert';
import 'package:http/http.dart' as http;

class PassSlipService {
  static const String baseUrl = 'http://172.31.22.33:8001/api'; // Change if needed

  /// CREATE
  static Future<bool> createPassSlip(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/pass-slips'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        print('✅ Pass slip created successfully');
        return true;
      } else {
        print('❌ Failed to create: ${response.statusCode}');
        print(response.body);
        return false;
      }
    } catch (e) {
      print('⚠️ Error connecting to backend: $e');
      return false;
    }
  }

  /// READ ALL
  static Future<List<dynamic>> getAllPassSlips() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pass-slips'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Failed to fetch: ${response.statusCode}');
        print(response.body);
        return [];
      }
    } catch (e) {
      print('⚠️ Error fetching pass slips: $e');
      return [];
    }
  }

  /// READ ONE
  static Future<Map<String, dynamic>?> getPassSlipById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/pass-slips/$id'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Failed to fetch pass slip #$id: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('⚠️ Error fetching pass slip by ID: $e');
      return null;
    }
  }

  /// UPDATE
  static Future<bool> updatePassSlip(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/pass-slips/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        print('✅ Pass slip updated successfully');
        return true;
      } else {
        print('❌ Failed to update: ${response.statusCode}');
        print(response.body);
        return false;
      }
    } catch (e) {
      print('⚠️ Error updating pass slip: $e');
      return false;
    }
  }

  /// DELETE
  static Future<bool> deletePassSlip(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/pass-slips/$id'));

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Pass slip deleted successfully');
        return true;
      } else {
        print('❌ Failed to delete: ${response.statusCode}');
        print(response.body);
        return false;
      }
    } catch (e) {
      print('⚠️ Error deleting pass slip: $e');
      return false;
    }
  }
}
