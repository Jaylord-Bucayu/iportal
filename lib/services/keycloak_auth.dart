import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'insecure_client.dart';
import 'api_config.dart';

/// Thrown when the request itself fails (network/cert/CORS) as opposed to
/// the server responding with "invalid credentials". Lets the UI show a
/// different message/flow for each case.
class ApiConnectionException implements Exception {
  final String message;
  ApiConnectionException(this.message);
  @override
  String toString() => message;
}

http.Client _createInsecureClient() => createPlatformClient();

/// Authenticate with staff_id + password via /auth/login-no-otp.
/// Returns the "result" object from the response, or null if the server
/// responded but rejected the credentials.
/// Throws [ApiConnectionException] if the request itself couldn't be made
/// (network error, cert rejected by browser, CORS, etc).
Future<Map<String, dynamic>?> authenticateWithStaffId(
    String staffId, String password) async {
  final url = Uri.parse('${ApiConfig.authBase}/auth/login-no-otp');
  final client = _createInsecureClient();

  try {
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'staff_id': staffId,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['status'] == true && decoded['result'] != null) {
        return decoded['result'] as Map<String, dynamic>;
      }
      debugPrint('Login failed: ${decoded['message'] ?? response.body}');
      return null; // server responded — genuinely wrong credentials
    } else {
      debugPrint('Auth failed (${response.statusCode}): ${response.body}');
      return null; // server responded — genuinely wrong credentials/bad request
    }
  } catch (e) {
    debugPrint('Auth error: $e');
    // The request never completed — almost always network/cert/CORS on web.
    throw ApiConnectionException(
      'Could not reach the server. This usually means your browser hasn\'t '
          'trusted this server\'s security certificate yet.',
    );
  } finally {
    client.close();
  }
}

/// Fetch the currently authenticated user's profile via /auth/me.
Future<Map<String, dynamic>?> fetchMe(String accessToken) async {
  final url = Uri.parse('${ApiConfig.authBase}/auth/me');
  final client = _createInsecureClient();

  try {
    final response = await client.get(
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return (decoded['result'] ?? decoded) as Map<String, dynamic>;
    } else {
      debugPrint('Failed to fetch /me: ${response.statusCode} ${response.body}');
      return null;
    }
  } catch (e) {
    debugPrint('Error fetching /me: $e');
    return null;
  } finally {
    client.close();
  }
}

/// Fetch active work history for a given staff ID.
Future<List<Map<String, dynamic>>> fetchUserWH(String staffId,
    {String? accessToken}) async {
  final url = Uri.parse('${ApiConfig.umsBase}/api/work-history/$staffId?is_active=1');
  final client = _createInsecureClient();

  try {
    final response = await client.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['status'] == true && decoded['data'] != null) {
        return List<Map<String, dynamic>>.from(decoded['data']);
      }
      debugPrint('Work history returned no data: ${decoded['message']}');
    } else {
      debugPrint('Failed to fetch work history: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error fetching work history: $e');
  } finally {
    client.close();
  }

  return [];
}

/// Riverpod provider: fetch /me + work history, merged into one map.
final userInfoProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>?, String>((ref, accessToken) async {
  final me = await fetchMe(accessToken);
  if (me == null) return null;

  final currentUser = (me['current_user'] ?? me) as Map<String, dynamic>;
  final staffId = currentUser['staff_id']?.toString();

  final workHistory = staffId != null
      ? await fetchUserWH(staffId, accessToken: accessToken)
      : <Map<String, dynamic>>[];

  return {...currentUser, 'work_history': workHistory};
});