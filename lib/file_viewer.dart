// lib/file_viewer.dart
//
// Tiny viewer that supports three types by URL:
//   • PDF   – rendered with Syncfusion PDF Viewer (text selection supported)
//   • PPTX  – rendered via Google Docs in an iframe
//   • DOCX  – idem
//   • XLSX  – idem

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Conditional imports for web
import 'web_platform_view_registry_stub.dart'
    if (dart.library.html) 'web_platform_view_registry.dart'
    as web_registry;

class FileViewer extends StatefulWidget {
  const FileViewer({
    super.key,
    required this.fileUrl,
    required this.fileType,
    this.onPdfPageChanged,
  });

  final String fileUrl;
  final String fileType;
  final void Function(int currentPage, int totalPages)? onPdfPageChanged;

  @override
  State<FileViewer> createState() => _FileViewerState();
}

class _FileViewerState extends State<FileViewer> {
  String? _iframeViewType;
  bool _iframeFailed = false;
  int? _pdfPageCount;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && _isOfficeFile) _setupIframe();
  }

  @override
  void didUpdateWidget(covariant FileViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fileUrl != oldWidget.fileUrl) {
      if (kIsWeb && _isOfficeFile) _setupIframe();
    }
  }

  bool get _isOfficeFile =>
      widget.fileType == 'pptx' ||
      widget.fileType == 'docx' ||
      widget.fileType == 'xlsx';

  void _setupIframe() {
    final viewType = 'iframe-${widget.fileUrl.hashCode}';
    final viewerUrl =
        'https://docs.google.com/gview?url=${Uri.encodeComponent(widget.fileUrl)}&embedded=true';
    try {
      web_registry.registerIframe(viewType, viewerUrl);
      setState(() {
        _iframeViewType = viewType;
        _iframeFailed = false;
      });
    } catch (e) {
      setState(() {
        _iframeViewType = null;
        _iframeFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fileUrl.isEmpty) {
      return const Center(child: Text('No file selected.'));
    }

    switch (widget.fileType) {
      case 'pdf':
        // Use Syncfusion PDF Viewer for text selection/highlighting
        return SfPdfViewer.network(
          widget.fileUrl,
          onDocumentLoaded: (details) {
            _pdfPageCount = details.document.pages.count;
            // Use Future.microtask to avoid setState during build
            Future.microtask(() {
              if (mounted) {
                widget.onPdfPageChanged?.call(1, _pdfPageCount!);
              }
            });
          },
          onPageChanged: (details) {
            // Use Future.microtask to avoid setState during build
            Future.microtask(() {
              if (mounted) {
                widget.onPdfPageChanged?.call(
                  details.newPageNumber,
                  _pdfPageCount ?? 0,
                );
              }
            });
          },
        );

      case 'pptx':
      case 'docx':
      case 'xlsx':
        if (kIsWeb) {
          if (_iframeFailed) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Preview is not supported in this browser or Flutter version.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Please convert your file to PDF to preview it.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          if (_iframeViewType == null) {
            return const Center(child: CircularProgressIndicator());
          }
          // Use HtmlElementView with the registered iframe
          return HtmlElementView(viewType: _iframeViewType!);
        } else {
          final viewerUrl =
              'https://docs.google.com/gview?url=${Uri.encodeComponent(widget.fileUrl)}&embedded=true';
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
