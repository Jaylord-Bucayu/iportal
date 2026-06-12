import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class VermsWebViewScreen extends StatelessWidget {
  const VermsWebViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Verms",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.primaries[4],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri("https://www.appsheet.com/start/ce476aa2-19db-4c94-bd4f-409e5c7c7d9d"),
        ),
        // onReceivedServerTrustAuthRequest: (controller, challenge) async {
        //   // 👇 Accept all SSL certs (dev only!)
        //   return ServerTrustAuthResponse(
        //     action: ServerTrustAuthResponseAction.PROCEED,
        //   );
        // },
      ),
    );
  }
}
