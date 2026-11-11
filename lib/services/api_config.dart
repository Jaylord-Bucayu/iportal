import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralized API base URLs for every backend this app talks to.
///
/// Web builds go through the Nginx proxy on a trusted HTTPS domain
/// (fo2-staff-search.dswd.gov.ph) — this avoids CORS, mixed-content, and
/// self-signed-certificate restrictions that browsers enforce.
///
/// Native builds (Android/iOS) talk to each backend directly — none of
/// those browser-only restrictions apply to compiled native apps.
class ApiConfig {
  ApiConfig._(); // no instances — static access only

  /// Auth / Keycloak-replacement API (login, /me).
  static String get authBase => kIsWeb
      ? 'https://fo2-staff-search.dswd.gov.ph/auth-api'
      : 'https://172.31.16.77/api';


  /// UMS API (images, uploads, work-history) — already on a real domain,
  /// so no platform branching needed here.
  static String get umsBase => kIsWeb
  ? 'https://fo2-staff-search.dswd.gov.ph'
  : 'https://172.31.16.68';

  /// Leave management API.
  static String get leaveBase => kIsWeb
      ? 'https://fo2-staff-search.dswd.gov.ph/leave-api-stg'
      : 'http://172.31.16.69/api/v1';

  /// FCM token save endpoint (same backend as leaveBase).
  static String get fcmSaveUrl => kIsWeb
      ? 'https://fo2-staff-search.dswd.gov.ph/leave-api-stg/notifications/save-fcm'
      : 'http://172.31.16.69/api/v1/notifications/save-fcm';
}
