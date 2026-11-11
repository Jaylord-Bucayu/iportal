import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop/providers/auth_provider.dart';

// Web gets a real <iframe>; other platforms get an empty stub.
import 'edlvs_iframe_stub.dart'
if (dart.library.js_interop) 'edlvs_iframe_web.dart';

/// Site opened inside the app. It must have the /sso/handoff route.
const String edlvsUrl = 'https://172.31.16.80';

/// Call this from the eDLVS tile's onTap: onTap: () => openEdlvs(context)
///
/// Opens the site inside the app on every platform:
///  - Web: an <iframe> inside the Flutter page (same tab, PWA friendly).
///  - Mobile: an in-app WebView.
/// The IAM access token (and the user's roles, for display) are handed over
/// in the URL fragment (/sso/handoff#token=...&roles=...), which is never
/// sent to a server.
Future<void> openEdlvs(BuildContext context) async {
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ReservsWebViewScreen()),
  );
}

class ReservsWebViewScreen extends ConsumerStatefulWidget {
  const ReservsWebViewScreen({super.key});

  @override
  ConsumerState<ReservsWebViewScreen> createState() =>
      _ReservsWebViewScreenState();
}

class _ReservsWebViewScreenState extends ConsumerState<ReservsWebViewScreen> {
  String? _handoffUrl;
  Widget? _webFrame; // built ONCE, so rebuilds don't reload the iframe

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    final token = auth?.accessToken;
    if (token != null && token.isNotEmpty) {
      final roles =
      Uri.encodeComponent((auth?.roles ?? const <String>[]).join(','));
      _handoffUrl = '$edlvsUrl/sso/handoff'
          '#token=${Uri.encodeComponent(token)}'
          '&roles=$roles'
          '&redirect=%2F';
      if (kIsWeb) _webFrame = buildEdlvsFrame(_handoffUrl!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'eDLVS',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.primaries[4],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _handoffUrl == null
          ? const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'You are not signed in. Please sign in again.',
            textAlign: TextAlign.center,
          ),
        ),
      )
          : kIsWeb
          ? _webFrame!
          : InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(_handoffUrl!)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          domStorageEnabled: true,
          thirdPartyCookiesEnabled: true, // Android
          sharedCookiesEnabled: true, // iOS
        ),
        onReceivedHttpError: (controller, request, response) {
          debugPrint(
              '[edlvs] HTTP ${response.statusCode} ${request.url}');
        },
        onReceivedError: (controller, request, error) {
          debugPrint(
              '[edlvs] ERROR ${error.description} ${request.url}');
        },
        onReceivedServerTrustAuthRequest:
            (controller, challenge) async {
          // Internal certificate: trust only the 172.31.x.x servers.
          final host = challenge.protectionSpace.host;
          return ServerTrustAuthResponse(
            action: host.startsWith('172.31.')
                ? ServerTrustAuthResponseAction.PROCEED
                : ServerTrustAuthResponseAction.CANCEL,
          );
        },
      ),
    );
  }
}