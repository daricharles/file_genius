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
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.fileType == 'pdf') _loadPdf();
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
        return Center(
          child: ElevatedButton(
            onPressed: () async {
              if (await canLaunchUrl(Uri.parse(viewerUrl))) {
                await launchUrl(Uri.parse(viewerUrl));
              }
            },
            child: Text('Open Document'),
          ),
        );

      default:
        return Center(child: Text('Unsupported file type: ${widget.fileType}'));
    }
  }
}

/* ---------------- Web‑view wrapper for pptx / docx ---------------- */

// ignore: unused_element
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
