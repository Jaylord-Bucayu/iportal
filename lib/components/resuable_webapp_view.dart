import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ReusableWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const ReusableWebViewScreen({
    super.key,
    required this.url,
    this.title = "WebView",
  });

  @override
  State<ReusableWebViewScreen> createState() => _ReusableWebViewScreenState();
}

class _ReusableWebViewScreenState extends State<ReusableWebViewScreen> {
  InAppWebViewController? _webViewController;
  double _zoomLevel = 1.0;

  static const double _minZoom = 0.5;
  static const double _maxZoom = 3.0;
  static const double _zoomStep = 0.1;

  Future<void> _applyZoom() async {
    // Uses CSS zoom on the page content - works cross-platform.
    await _webViewController?.evaluateJavascript(source: """
      document.body.style.zoom = '$_zoomLevel';
    """);
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel + _zoomStep).clamp(_minZoom, _maxZoom);
    });
    _applyZoom();
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel - _zoomStep).clamp(_minZoom, _maxZoom);
    });
    _applyZoom();
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
    });
    _applyZoom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: _zoomOut,
            tooltip: "Zoom out",
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: _zoomIn,
            tooltip: "Zoom in",
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            onPressed: _resetZoom,
            tooltip: "Reset zoom",
          ),
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(Uri.encodeFull(widget.url)),
        ),
        initialSettings: InAppWebViewSettings(
          supportZoom: true,
          builtInZoomControls: true,   // enables pinch-to-zoom on Android
          displayZoomControls: false,  // hides Android's default on-screen zoom buttons
          useWideViewPort: true,
          loadWithOverviewMode: true,
        ),
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        onLoadStop: (controller, url) async {
          // Reapply current zoom level whenever a new page finishes loading
          await _applyZoom();
        },
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