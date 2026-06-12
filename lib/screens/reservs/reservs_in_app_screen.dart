import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ReservsWebViewScreen extends StatelessWidget {
  const ReservsWebViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Reservs",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.primaries[4],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri("https://172.31.16.67"),
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
