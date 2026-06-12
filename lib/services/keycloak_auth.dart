import 'package:flutter/material.dart';
import 'package:openid_client/openid_client_io.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final uri = Uri.parse('https://fo2-auth.dswd.gov.ph/realms/dswd-fo2');

/// Authenticate with Keycloak using username/password and get token.
Future<Map<String, dynamic>?> authenticateWithKeycloak(String username, String password) async {
  final url = Uri.parse('https://fo2-auth.dswd.gov.ph/realms/dswd-fo2/protocol/openid-connect/token');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: {
      'client_id': 'dswd-fo2-iportal-leave',
      'client_secret': 'laEXyBsfwFW6HZUsYNFtiaujiAlM7Qsn',
      'scope': 'openid profile email',
      'grant_type': 'password',
      'username': username,
      'password': password,
    },
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    debugPrint("Auth failed: ${response.body}");
    return null;
  }
}

/// Authenticate via external browser (PKCE flow)
Future<UserInfo?> authenticate(BuildContext context) async {
  try {
    final issuer = await Issuer.discover(uri);
    final client = Client(issuer, 'playground');

    final redirectUri = Uri.parse('com.dev.myapp://auth');
    const scopes = ['openid', 'profile', 'email'];

    final authenticator = Authenticator(
      client,
      scopes: scopes,
      port: 4000,
      redirectUri: redirectUri,
      urlLancher: (url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    );

    final credential = await authenticator.authorize();
    closeWebView();

    final userInfo = await credential.getUserInfo();
    debugPrint('Logged in as: ${userInfo.name}');

    return userInfo;
  } catch (e) {
    debugPrint('Authentication error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Authentication failed: $e')),
    );
    return null;
  }
}

/// Fetch user info from Keycloak using the access token.
Future<Map<String, dynamic>?> fetchUserInfo(String accessToken) async {
  const url = 'https://172.31.16.53/realms/dswd-fo2/protocol/openid-connect/userinfo';

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      debugPrint('Failed to fetch user info, status code: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error fetching user info: $e');
  }

  return null;
}

/// Fetch active work history for a given staff ID.
Future<List<Map<String, dynamic>>> fetchUserWH(String staffId) async {
  final url = 'https://172.31.16.68/api/work-history/$staffId?is_active=1';

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['status'] == true && decoded['data'] != null) {
        return List<Map<String, dynamic>>.from(decoded['data']);
      } else {
        debugPrint('Work history fetch returned no data: ${decoded['message']}');
      }
    } else {
      debugPrint('Failed to fetch work history, status code: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error fetching work history: $e');
  }

  return [];
}
/// Riverpod provider to fetch user info and work history, merged into one map.
final userInfoProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>?, String>((ref, accessToken) async {
  final userInfo = await fetchUserInfo(accessToken);

  if (userInfo == null) return null;

  // Extract staff_id from userInfo (adjust key to match your Keycloak claims)
  final staffId = userInfo['staff_id']?.toString()
      ?? userInfo['employee_id']?.toString()
      ?? userInfo['sub']?.toString();

  if (staffId != null) {
    final workHistory = await fetchUserWH(staffId);
    return {
      ...userInfo,
      'work_history': workHistory,
    };
  }

  // Return userInfo with empty work history if no staff_id found
  debugPrint('No staff_id found in userInfo; skipping work history fetch.');
  return {
    ...userInfo,
    'work_history': <Map<String, dynamic>>[],
  };
});