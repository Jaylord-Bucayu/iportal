import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>?> _fetchUserInfo(String accessToken) async {
  const url =
      'https://172.31.16.53/realms/dswd-fo2/protocol/openid-connect/userinfo';

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    debugPrint('UserInfo response status: ${response.statusCode}');
    debugPrint('UserInfo response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } else {
      debugPrint(
          'Failed to fetch user info, status code: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error fetching user info: $e');
  }

  return null;
}
