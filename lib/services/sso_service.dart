// lib/services/sso_service.dart  (NEW)
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

// IAM backend base URL. Override per build:
//   flutter run --dart-define=IAM_BASE=http://192.168.1.10:3000
const String _envBase = String.fromEnvironment('IAM_BASE');

String get iamBase {
  if (_envBase.isNotEmpty) return _envBase.replaceAll(RegExp(r'/+$'), '');
  return 'https://172.31.16.83/backend';
}

// Client code registered in the IAM applications table (public client, no secret).
String get ssoClientId => kIsWeb ? 'IPORTAL_WEB' : 'IPORTAL_MOBILE';
const String ssoScheme = 'com.dswd.iportal';

// Mobile: custom scheme.  Web: a static callback page served by the Flutter web app.
String get ssoRedirectUri =>
    kIsWeb ? '${Uri.base.origin}/auth.html' : '$ssoScheme://sso/complete';

String _b64(List<int> b) => base64UrlEncode(b).replaceAll('=', '');

String _randomString([int bytes = 32]) {
  final r = Random.secure();
  return _b64(List.generate(bytes, (_) => r.nextInt(256)));
}

String _challenge(String verifier) =>
    _b64(sha256.convert(ascii.encode(verifier)).bytes);

class SsoService {
  /// Runs the full Authorization Code + PKCE flow and returns the exchange
  /// result map: access_token / refresh_token / current_user,
  /// or the mfa_required / mfa_setup_required flags.
  Future<Map<String, dynamic>> login() async {
    final verifier = _randomString();
    final state = _randomString(16);
    final redirectUri = ssoRedirectUri;

    final authUrl = Uri.parse('$iamBase/oidc/auth').replace(queryParameters: {
      'client_id': ssoClientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'openid email profile',
      'state': state,
      'code_challenge': _challenge(verifier),
      'code_challenge_method': 'S256',
    });

    // iOS: ASWebAuthenticationSession, Android: Chrome Custom Tab, Web: popup.
    // preferEphemeral:false keeps the browser's IAM cookie -> real SSO.
    print(authUrl);
    final callback = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: kIsWeb ? Uri.base.scheme : ssoScheme,
      options: const FlutterWebAuth2Options(preferEphemeral: false),
    );

    final q = Uri.parse(callback).queryParameters;
    if (q['error'] != null) {
      throw Exception(q['error_description'] ?? 'Login failed');
    }
    if (q['state'] != state) {
      throw Exception('Your sign-in session could not be verified. Please try again.');
    }
    final code = q['code'];
    if (code == null || code.isEmpty) {
      throw Exception('Login failed — no authorization code received.');
    }

    final res = await http.post(
      Uri.parse('$iamBase/api/auth/sso/exchange'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'code': code,
        'state': state,
        'code_verifier': verifier,
        'redirect_uri': redirectUri,
        'client_id': ssoClientId,
      }),
    );

    dynamic body;
    try {
      body = jsonDecode(res.body);
    } catch (_) {
      body = null;
    }

    if (res.statusCode >= 400) {
      throw Exception(
        (body is Map ? body['message'] : null) ?? 'Token exchange failed (${res.statusCode})',
      );
    }
    if (body is! Map) throw Exception('Unexpected response from server');

    return (body['result'] ?? body) as Map<String, dynamic>;
  }
}