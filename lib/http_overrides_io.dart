import 'dart:io';

/// Native build only: accepts self-signed certs globally.
/// Remove this once your backend has a valid, trusted certificate.
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void setHttpOverrides() {
  HttpOverrides.global = MyHttpOverrides();
}