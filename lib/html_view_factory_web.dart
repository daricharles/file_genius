// Only used on web builds
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

void registerIframe(String viewId, String src) {
  final iframe =
      html.IFrameElement()
        ..src = src
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';

  ui_web.platformViewRegistry.registerViewFactory(viewId, (int _) => iframe);
}
