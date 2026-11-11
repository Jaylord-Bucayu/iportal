import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Native build only: accepts self-signed certs for `_apiBase`.
/// Remove this and use `http.Client()` directly once `_apiBase` has a
/// valid, trusted certificate.
http.Client createPlatformClient() {
  final httpClient = HttpClient()
    ..badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
  return IOClient(httpClient);
}