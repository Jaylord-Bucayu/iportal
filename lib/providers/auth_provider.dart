import 'dart:convert';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/services/keycloak_auth.dart';
import '../models/auth_user.dart';
import '../services/sso_service.dart';

/// Result of an SSO sign-in attempt.
enum SsoOutcome { success, mfaRequired, mfaSetupRequired, cancelled }

class AuthNotifier extends StateNotifier<AuthUser?> {
  AuthNotifier() : super(null);

  // Held between the SSO exchange and the MFA screens.
  String? ssoPendingToken; // mfa_pending_token or setup_token
  String? ssoPendingMethod; // e.g. 'totp' / 'email'

  // ✅ Decode JWT and extract roles (new payload shape: top-level "roles")
  List<String> _getRolesFromToken(String accessToken) {
    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) return [];

      String payload = parts[1];
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> data = jsonDecode(decoded);

      final rawRoles = data['roles'];
      if (rawRoles is! List) {
        print('roles claim is not a List: $rawRoles (${rawRoles.runtimeType})');
        return [];
      }

      // ✅ normalize: stringify, trim, lowercase
      final roles = rawRoles
          .map((e) => e.toString().trim().toLowerCase())
          .toList();

      print('ROLES (normalized): $roles');
      return roles;
    } catch (e) {
      print('Token decode error: $e');
      return [];
    }
  }

  /// Normalizes a roles list from an API response (stringify, trim, lowercase).
  List<String> _normalizeRoles(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => e.toString().trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// SSO login: opens the browser, exchanges the code, populates state.
  Future<SsoOutcome> loginWithSso() async {
    final Map<String, dynamic> result;
    try {
      result = await SsoService().login();
    } on PlatformException catch (e) {
      // User closed the browser / sign-in sheet.
      if (e.code == 'CANCELED') return SsoOutcome.cancelled;
      rethrow;
    }

    if (result['mfa_setup_required'] == true) {
      ssoPendingToken = result['setup_token'] as String?;
      return SsoOutcome.mfaSetupRequired;
    }
    if (result['mfa_required'] == true) {
      ssoPendingToken = result['mfa_pending_token'] as String?;
      ssoPendingMethod = result['method'] as String?;
      return SsoOutcome.mfaRequired;
    }

    final currentUser = result['current_user'] as Map<String, dynamic>?;
    final accessToken = result['access_token'] as String?;
    final refreshToken = result['refresh_token'] as String?;
    final staffId = int.tryParse('${currentUser?['staff_id']}');

    if (currentUser == null ||
        accessToken == null ||
        refreshToken == null ||
        staffId == null) {
      throw Exception('Unexpected response from server');
    }

    // The access token has no "roles" claim; the roles only come back in the
    // exchange response's current_user, so keep them from there.
    final exchangeRoles = _normalizeRoles(currentUser['roles']);
    print('ROLES (from exchange): $exchangeRoles');

    await login(
      accessToken: accessToken,
      refreshToken: refreshToken,
      email: (currentUser['email'] ?? '') as String,
      fullName: (currentUser['full_name'] ?? 'User') as String,
      staffId: staffId,
      roles: exchangeRoles,
    );
    return SsoOutcome.success;
  }

  /// Legacy staff-id + password login (kept in case you still need it).
  Future<bool> loginWithCredentials(String staffId, String password) async {
    final result = await authenticateWithStaffId(staffId, password);
    if (result == null) return false;

    final currentUser = result['current_user'] as Map<String, dynamic>?;
    final accessToken = result['access_token'] as String?;
    final refreshToken = result['refresh_token'] as String?;

    if (currentUser == null || accessToken == null || refreshToken == null) {
      print('Login response missing expected fields');
      return false;
    }

    await login(
      accessToken: accessToken,
      refreshToken: refreshToken,
      email: currentUser['email'] as String,
      fullName: currentUser['full_name'] as String,
      staffId: currentUser['staff_id'] as int,
      roles: _normalizeRoles(currentUser['roles']),
    );

    return true;
  }

  Future<void> login({
    required String accessToken,
    required String refreshToken,
    required String email,
    required String fullName,
    required int staffId,
    List<String>? roles,
  }) async {
    // Prefer the roles passed in (from the API response); fall back to the
    // token's "roles" claim for any caller that doesn't pass them.
    final tokenRoles = _getRolesFromToken(accessToken);
    final finalRoles =
    (roles != null && roles.isNotEmpty) ? roles : tokenRoles;

    print('ROLES: $finalRoles');

    state = AuthUser(
      accessToken: accessToken,
      refreshToken: refreshToken,
      email: email,
      fullName: fullName,
      staffId: staffId,
      roles: finalRoles,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);
    await prefs.setString('email', email);
    await prefs.setString('fullName', fullName);
    await prefs.setInt('staffId', staffId);
    await prefs.setStringList('roles', finalRoles);
  }

  void updateUserInfo({
    required String email,
    required String fullName,
    required int staffId,
  }) {
    if (state != null) {
      state = AuthUser(
        accessToken: state!.accessToken,
        refreshToken: state!.refreshToken,
        email: email,
        fullName: fullName,
        staffId: staffId,
        roles: state!.roles,
      );
    }
  }

  Future<void> logout() async {
    // Clears this app's session only. The browser's SSO session stays alive,
    // so the next "Sign in with SSO" may sign the user straight back in
    // (a backend end-session route is needed to prevent that).
    final prefs = await SharedPreferences.getInstance();
    state = null;
    ssoPendingToken = null;
    ssoPendingMethod = null;
    await prefs.clear();
  }

  // Load saved user info on app start
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');
    final email = prefs.getString('email');
    final fullName = prefs.getString('fullName');
    final roles = prefs.getStringList('roles') ?? [];

    int? staffId;
    try {
      staffId = prefs.getInt('staffId');
    } catch (_) {}

    if (staffId == null) {
      final staffIdStr = prefs.getString('staffId');
      staffId = int.tryParse(staffIdStr ?? '');
    }

    if (accessToken != null &&
        refreshToken != null &&
        email != null &&
        fullName != null &&
        staffId != null) {
      state = AuthUser(
        accessToken: accessToken,
        refreshToken: refreshToken,
        email: email,
        fullName: fullName,
        staffId: staffId,
        roles: roles,
      );
    }
  }
}

/// Extracts the first name from a "LASTNAME, FIRSTNAME, MIDDLENAME" style
/// full name (e.g. "BUCAYU, JAYLORD, CONAG" -> "JAYLORD").
/// Falls back gracefully for names that don't follow this format.
String getFirstName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return '';

  final parts = fullName
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  if (parts.length >= 2) {
    // "LASTNAME, FIRSTNAME, MIDDLENAME" -> second segment is the first name
    return parts[1];
  }

  // No comma format — just return the first word of whatever we got
  final words = fullName.trim().split(RegExp(r'\s+'));
  return words.isNotEmpty ? words.first : fullName.trim();
}

bool hasRole(List<String> roles, String role) {
  final target = role.trim().toLowerCase();
  return roles.any((r) => r.trim().toLowerCase() == target);
}

// Riverpod provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthUser?>((ref) {
  return AuthNotifier();
});

final workHistoryProvider =
FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth == null) return [];
  return await fetchUserWH(auth.staffId.toString(),
      accessToken: auth.accessToken);
});