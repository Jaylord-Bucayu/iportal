import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

int _n = 0;

Widget buildEdlvsFrame(String url) {
  final viewType = 'edlvs-frame-${_n++}';
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int id) {
    return web.HTMLIFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';
  });
  return HtmlElementView(viewType: viewType);
}