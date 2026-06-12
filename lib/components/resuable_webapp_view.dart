import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ReusableWebViewScreen extends StatelessWidget {
  final String url;
  final String title;

  const ReusableWebViewScreen({
    super.key,
    required this.url,
    this.title = "WebView",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          Navigator.pop(context);
        },
  ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(Uri.encodeFull(url)), // Encode URL to handle spaces/special chars
        ),
        onReceivedServerTrustAuthRequest: (controller, challenge) async {
          // 👇 Accept all SSL certs (dev only!)
          return ServerTrustAuthResponse(
            action: ServerTrustAuthResponseAction.PROCEED,
          );
        },
      ),
    );
  }
}