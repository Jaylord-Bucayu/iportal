import 'package:flutter/material.dart';
import 'package:openid_client/openid_client_io.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ✅ All pointing to the public domain now
const _keycloakBase = 'https://fo2-auth.dswd.gov.ph/realms/dswd-fo2';
const _apiBase = 'https://fo2-api.dswd.gov.ph'; // 🔁 Replace with your actual public API domain

final uri = Uri.parse(_keycloakBase);

/// Authenticate with Keycloak using username/password and get token.
Future<Map<String, dynamic>?> authenticateWithKeycloak(
    String username, String password) async {
  final url = Uri.parse('$_keycloakBase/protocol/openid-connect/token');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': 'dswd-fo2-iportal-leave',
        'client_secret': '9pA3B4szE8VmoYyW287hON7q6cqdE5RP',
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
  } catch (e) {
    debugPrint('Auth error: $e');
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
      urlLancher: (url) =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    );

    final credential = await authenticator.authorize();
    closeWebView();

    final userInfo = await credential.getUserInfo();
    debugPrint('Logged in as: ${userInfo.name}');
    return userInfo;
  } catch (e) {
    debugPrint('Authentication error: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication failed: $e')),
      );
    }
    return null;
  }
}

/// Fetch user info from Keycloak using the access token.
Future<Map<String, dynamic>?> fetchUserInfo(String accessToken) async {
  // ✅ Was: https://172.31.16.53/... (private IP)
  final url = Uri.parse('$_keycloakBase/protocol/openid-connect/userinfo');

  try {
    final response = await http.get( // ✅ Changed POST → GET (correct for userinfo)
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      debugPrint('Failed to fetch user info: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error fetching user info: $e');
  }

  return null;
}

/// Fetch active work history for a given staff ID.
Future<List<Map<String, dynamic>>> fetchUserWH(String staffId) async {
  // ✅ Was: https://172.31.16.68/... (private IP) — replace _apiBase with your real domain
  final url = Uri.parse('$_apiBase/api/work-history/$staffId?is_active=1');

  try {
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['status'] == true && decoded['data'] != null) {
        return List<Map<String, dynamic>>.from(decoded['data']);
      } else {
        debugPrint('Work history returned no data: ${decoded['message']}');
      }
    } else {
      debugPrint('Failed to fetch work history: ${response.statusCode}');
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

  final staffId = userInfo['staff_id']?.toString()
      ?? userInfo['employee_id']?.toString()
      ?? userInfo['sub']?.toString();

  final workHistory =
  staffId != null ? await fetchUserWH(staffId) : <Map<String, dynamic>>[];

  if (staffId == null) {
    debugPrint('No staff_id found in userInfo; skipping work history fetch.');
  }

  return {...userInfo, 'work_history': workHistory};
});