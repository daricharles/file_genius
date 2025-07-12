// lib/web_platform_view_registry.dart
// Registers iframe views on Flutter web

// ignore_for_file: deprecated_member_use

// ignore: duplicate_ignore
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Registers an iframe for web preview via Google Docs Viewer
void registerIframe(String viewId, String src) {
  try {
    // Try to access platformViewRegistry through JavaScript
    final jsContext = js.context;
    final ui = jsContext['ui'];
    if (ui != null) {
      final registry = ui['platformViewRegistry'];
      if (registry != null) {
        registry.callMethod('registerViewFactory', [
          viewId,
          js.allowInterop((int _) {
            final iframe =
                html.IFrameElement()
                  ..src = src
                  ..style.border = 'none'
                  ..style.width = '100%'
                  ..style.height = '100%';
            return iframe;
          }),
        ]);
        return;
      }
    }

    // Fallback: if platformViewRegistry is not available, show a message
  // ignore: avoid_print
  print(
      'Warning: platformViewRegistry not available in current Flutter version',
    );
  } catch (e) {
    // ignore: avoid_print
    print('Warning: Failed to register iframe: $e');
  }
}
