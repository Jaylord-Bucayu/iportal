class AuthUser {
  final String accessToken;
  final String refreshToken;
  final String email;
  final String fullName;
  final int staffId;
  final List<String> roles; 

  AuthUser({
    required this.accessToken,
    required this.refreshToken,
    required this.email,
    required this.fullName,
    required this.staffId,
  this.roles = const [],
  });
}
