// lib/file_viewer.dart
//
// Tiny viewer that supports three types by URL:
//   • PDF   – rendered with pdfx
//   • PPTX  – rendered via Google‑Docs viewer in WebView
//   • DOCX  – idem
//
//   FileViewer(url: someUrl, type: 'pdf' | 'pptx' | 'docx')

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FileViewer extends StatefulWidget {
  const FileViewer({
    super.key,
    required this.url,
    required this.type, // lower-case extension
  });

  final String url;
  final String type;

  @override
  State<FileViewer> createState() => _FileViewerState();
}

class _FileViewerState extends State<FileViewer> {
  PdfControllerPinch? _pdf;
  bool _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'pdf') _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() => _busy = true);
    try {
      final res = await http.get(Uri.parse(widget.url));
      if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';
      final doc = await PdfDocument.openData(res.bodyBytes);
      _pdf = PdfControllerPinch(document: Future.value(doc));
    } catch (e) {
      _err = 'Failed to load PDF ($e)';
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  void dispose() {
    _pdf?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case 'pdf':
        if (_busy) return const Center(child: CircularProgressIndicator());
        if (_err != null) return Center(child: Text(_err!));
        return PdfViewPinch(controller: _pdf!);

      case 'pptx':
      case 'docx':
        return _DocsWebView(widget.url);

      default:
        return const Center(child: Text('Preview not available'));
    }
  }
}

/* ---------------- Web‑view wrapper for pptx / docx ---------------- */

class _DocsWebView extends StatelessWidget {
  const _DocsWebView(this.fileUrl);
  final String fileUrl;

  String get _viewer =>
      'https://docs.google.com/gview?embedded=1&url=${Uri.encodeComponent(fileUrl)}';

  @override
  Widget build(BuildContext context) {
    // Mobile / desktop: in‑app WebView
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      return WebViewWidget(
        controller:
            WebViewController()
              ..setJavaScriptMode(JavaScriptMode.unrestricted)
              ..loadRequest(Uri.parse(_viewer)),
      );
    }
    // Web: same widget works (webview_flutter_web)
    return WebViewWidget(
      controller:
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse(_viewer)),
    );
  }
}
