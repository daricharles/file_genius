import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'html_view_factory_stub.dart'
    if (dart.library.html) 'html_view_factory_web.dart';

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
  int? _pdfPageCount;
  WebViewController? _webViewController;
  bool _webViewError = false;
  String? _viewId;

  @override
  void initState() {
    super.initState();

    if (_isOfficeFile) {
      if (kIsWeb) {
        _registerIframe();
      } else {
        _setupWebView();
      }
    }
  }

  bool get _isOfficeFile =>
      widget.fileType == 'pptx' ||
      widget.fileType == 'docx' ||
      widget.fileType == 'xlsx';

  void _registerIframe() {
    final viewerUrl =
        'https://docs.google.com/gview?url=${Uri.encodeComponent(widget.fileUrl)}&embedded=true';
    final viewId = 'iframe-${widget.fileUrl.hashCode}';

    registerIframe(viewId, viewerUrl);

    setState(() => _viewId = viewId);
  }

  void _setupWebView() {
    final viewerUrl =
        'https://docs.google.com/gview?url=${Uri.encodeComponent(widget.fileUrl)}&embedded=true';

    try {
      _webViewController =
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse(viewerUrl));
    } catch (_) {
      setState(() => _webViewError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fileUrl.isEmpty) {
      return const Center(child: Text('No file selected.'));
    }

    switch (widget.fileType) {
      case 'pdf':
        return SfPdfViewer.network(
          widget.fileUrl,
          onDocumentLoaded: (details) {
            _pdfPageCount = details.document.pages.count;
            Future.microtask(() {
              if (mounted) {
                widget.onPdfPageChanged?.call(1, _pdfPageCount!);
              }
            });
          },
          onPageChanged: (details) {
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
        if (_webViewError) {
          return const Center(child: Text('❌ Failed to load preview.'));
        }

        if (kIsWeb) {
          if (_viewId == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return HtmlElementView(viewType: _viewId!);
        } else {
          if (_webViewController == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return WebViewWidget(controller: _webViewController!);
        }

      default:
        return Center(child: Text('Unsupported file type: ${widget.fileType}'));
    }
  }
}
