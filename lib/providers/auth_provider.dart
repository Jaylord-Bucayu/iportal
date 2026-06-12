import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop/services/keycloak_auth.dart';
import '../models/auth_user.dart';
import 'package:http/io_client.dart';

class AuthNotifier extends StateNotifier<AuthUser?> {
  AuthNotifier() : super(null);

  // Create an IOClient that accepts self-signed SSL certificates
  IOClient _createInsecureClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  // ✅ Decode JWT and extract roles
  List<String> _getRolesFromToken(String accessToken) {
    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) return [];

      // Base64 decode the payload (index 1)
      String payload = parts[1];
      // Pad base64 string if needed
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
      
      // Realm roles (global)
      final realmRoles = (data['realm_access']?['roles'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      // Client-specific roles
      final clientRoles =
          (data['resource_access']?['dswd-fo2-iportal-leave']?['roles'] as List?) // ✅ updated client name
                  ?.map((e) => e.toString())
                  .toList() ??
              [];

      return [...realmRoles, ...clientRoles];
    } catch (e) {
      print('Token decode error: $e');
      return [];
    }
  }

  Future<void> login({
    required String accessToken,
    required String refreshToken,
    required String email,
    required String fullName,
    required int staffId,
  }) async {
    final roles = _getRolesFromToken(accessToken); // ✅ extract roles

   print('ROLES: $roles');

    state = AuthUser(
      accessToken: accessToken,
      refreshToken: refreshToken,
      email: email,
      fullName: fullName,
      staffId: staffId,
      roles: roles, // ✅
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);
    await prefs.setString('email', email);
    await prefs.setString('fullName', fullName);
    await prefs.setInt('staffId', staffId);
    await prefs.setStringList('roles', roles); // ✅ persist roles
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
        roles: state!.roles, // ✅ preserve existing roles
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');

    if (refreshToken != null) {
      const keycloakBaseUrl = 'https://172.31.16.53';
      const realm = 'dswd-fo2';
      const clientId = 'dswd-fo2-reservs';

      final url = Uri.parse(
        '$keycloakBaseUrl/realms/$realm/protocol/openid-connect/logout',
      );

      try {
        final ioClient = _createInsecureClient();
        final response = await ioClient.post(
          url,
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'client_id': clientId,
            'refresh_token': refreshToken,
          },
        );

        if (response.statusCode != 204) {
          print('Keycloak logout failed: ${response.statusCode}');
          print(response.body);
        } else {
          print('Successfully logged out from Keycloak');
        }
      } catch (e) {
        print('Logout error: $e');
      }
    }

    state = null;
    await prefs.clear();
  }

  // Load saved user info on app start
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');
    final email = prefs.getString('email');
    final fullName = prefs.getString('fullName');
    final roles = prefs.getStringList('roles') ?? []; // ✅ load roles

    // ✅ Handle both old String and new int storage
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
        roles: roles, // ✅
      );
    }
  }
}

// Riverpod provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthUser?>((ref) {
  return AuthNotifier();
});

final workHistoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth == null) return [];
  return await fetchUserWH(auth.staffId.toString());
});