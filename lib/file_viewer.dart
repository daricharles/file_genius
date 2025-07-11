// lib/file_viewer.dart
//
// Tiny viewer that supports three types by URL:
//   • PDF   – rendered with pdfx
//   • PPTX  – rendered via Google‑Docs viewer in WebView
//   • DOCX  – idem
//
//   FileViewer(url: someUrl, type: 'pdf' | 'pptx' | 'docx')

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';
import 'package:webview_flutter/webview_flutter.dart';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html; // for web iframe
// Conditional import for platformViewRegistry
import 'web_platform_view_registry_stub.dart'
    if (dart.library.html) 'web_platform_view_registry.dart'
    as web_registry;

class FileViewer extends StatefulWidget {
  const FileViewer({
    super.key,
    required this.fileUrl,
    required this.fileType, // lower-case extension
    this.onPdfPageChanged,
  });

  final String fileUrl;
  final String fileType;
  final void Function(int currentPage, int totalPages)? onPdfPageChanged;

  @override
  State<FileViewer> createState() => _FileViewerState();
}

class _FileViewerState extends State<FileViewer> {
  PdfControllerPinch? _pdf;
  bool _busy = false;
  String? _err;
  int _totalPages = 1;
  String? _iframeViewType;

  @override
  void initState() {
    super.initState();
    if (widget.fileType == 'pdf') _loadPdf();
    if (kIsWeb &&
        (widget.fileType == 'pptx' ||
            widget.fileType == 'docx' ||
            widget.fileType == 'xlsx')) {
      _registerIframe();
    }
  }

  void _registerIframe() {
    final viewType = 'iframe-${widget.fileUrl.hashCode}';
    final viewerUrl =
        'https://docs.google.com/gview?url=${Uri.encodeComponent(widget.fileUrl)}&embedded=true';
    if (kIsWeb) {
      web_registry.platformViewRegistry.registerViewFactory(
        viewType,
        (int viewId) =>
            html.IFrameElement()
              ..src = viewerUrl
              ..style.border = 'none'
              ..width = '100%'
              ..height = '100%',
      );
    }
    _iframeViewType = viewType;
  }

  @override
  void didUpdateWidget(covariant FileViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fileUrl != oldWidget.fileUrl &&
        kIsWeb &&
        (widget.fileType == 'pptx' ||
            widget.fileType == 'docx' ||
            widget.fileType == 'xlsx')) {
      _registerIframe();
    }
    if (widget.fileType == 'pdf' && widget.fileUrl != oldWidget.fileUrl) {
      _loadPdf();
    }
  }

  Future<void> _loadPdf() async {
    setState(() => _busy = true);
    try {
      final res = await http.get(Uri.parse(widget.fileUrl));
      if (res.statusCode != 200) throw 'HTTP  ${res.statusCode}';
      final doc = await PdfDocument.openData(res.bodyBytes);
      _totalPages = doc.pagesCount;
      _pdf = PdfControllerPinch(document: Future.value(doc));
      // Notify initial page
      widget.onPdfPageChanged?.call(1, _totalPages);
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
    if (widget.fileUrl.isEmpty) {
      return Center(child: Text('No file selected or URL is empty.'));
    }
    switch (widget.fileType) {
      case 'pdf':
        if (_busy) return const Center(child: CircularProgressIndicator());
        if (_err != null) return Center(child: Text(_err!));
        return PdfViewPinch(
          controller: _pdf!,
          onPageChanged: (page) {
            widget.onPdfPageChanged?.call(page, _totalPages);
          },
        );
      case 'pptx':
      case 'docx':
      case 'xlsx':
        final viewerUrl =
            'https://docs.google.com/gview?url=${Uri.encodeComponent(widget.fileUrl)}&embedded=true';
        if (kIsWeb) {
          // Embed iframe for web
          return _iframeViewType == null
              ? const Center(child: CircularProgressIndicator())
              : HtmlElementView(viewType: _iframeViewType!);
        } else {
          // Use WebView for mobile/desktop
          return WebViewWidget(
            controller:
                WebViewController()
                  ..setJavaScriptMode(JavaScriptMode.unrestricted)
                  ..loadRequest(Uri.parse(viewerUrl)),
          );
        }
      default:
        return Center(child: Text('Unsupported file type: ${widget.fileType}'));
    }
  }
}
