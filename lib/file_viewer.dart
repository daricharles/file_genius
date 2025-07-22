import 'dart:async'; // <-- Add this import for Timer
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
    this.fileName,
    this.onPdfPageChanged,
  });

  final String fileUrl;
  final String fileType;
  final String? fileName;
  final void Function(int currentPage, int totalPages)? onPdfPageChanged;

  @override
  State<FileViewer> createState() => _FileViewerState();
}

class _FileViewerState extends State<FileViewer> {
  int? _pdfPageCount;
  late final PdfViewerController _pdfController;
  WebViewController? _webViewController;
  bool _webViewError = false;
  String? _viewId;
  bool _pdfLoading = true;
  int _currentPdfPage = 1;
  double _pdfZoomLevel = 1.0;

  // For showing/hiding the page counter overlay
  bool _showPdfPageCounter = false;
  Timer? _hideCounterTimer;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();

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

  void _onPdfPageChanged(int newPage, int? totalPages) {
    setState(() {
      _currentPdfPage = newPage;
      _showPdfPageCounter = true;
    });
    widget.onPdfPageChanged?.call(newPage, totalPages ?? 0);

    // Reset timer to hide the counter after 1.5 seconds
    _hideCounterTimer?.cancel();
    _hideCounterTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _showPdfPageCounter = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _hideCounterTimer?.cancel();
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fileUrl.isEmpty) {
      return const Center(child: Text('No file selected.'));
    }

    switch (widget.fileType) {
      case 'pdf':
        return Stack(
          children: [
            SfPdfViewer.network(
              widget.fileUrl,
              controller: _pdfController,
              onDocumentLoaded: (details) {
                _pdfPageCount = details.document.pages.count;
                setState(() {
                  _pdfLoading = false;
                  _currentPdfPage = 1;
                });
                widget.onPdfPageChanged?.call(1, _pdfPageCount!);
              },
              onPageChanged: (details) {
                _onPdfPageChanged(details.newPageNumber, _pdfPageCount);
              },
              canShowScrollHead: true,
              canShowScrollStatus: true,
            ),
            if (_pdfLoading) const Center(child: CircularProgressIndicator()),
            // PDF page counter and controls overlay (bottom center, only when scrolling)
            if (_pdfPageCount != null && !_pdfLoading && _showPdfPageCounter)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(
                        33,
                        33,
                        33,
                        0.85,
                      ), // replaces withOpacity
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Page',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(
                              255,
                              255,
                              255,
                              0.15,
                            ), // replaces withOpacity
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$_currentPdfPage',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Text(
                          ' / ',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        Text(
                          '$_pdfPageCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Zoom out
                        IconButton(
                          icon: const Icon(
                            Icons.remove,
                            color: Colors.white,
                            size: 20,
                          ),
                          tooltip: 'Zoom out',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _pdfZoomLevel = (_pdfZoomLevel - 0.25).clamp(
                                1.0,
                                3.0,
                              );
                              _pdfController.zoomLevel = _pdfZoomLevel;
                            });
                          },
                        ),
                        // Page fit
                        IconButton(
                          icon: const Icon(
                            Icons.fit_screen,
                            color: Colors.white,
                            size: 20,
                          ),
                          tooltip: 'Page fit',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _pdfZoomLevel = 1.0;
                              _pdfController.zoomLevel = _pdfZoomLevel;
                            });
                          },
                        ),
                        // Zoom in
                        IconButton(
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                          tooltip: 'Zoom in',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _pdfZoomLevel = (_pdfZoomLevel + 0.25).clamp(
                                1.0,
                                3.0,
                              );
                              _pdfController.zoomLevel = _pdfZoomLevel;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );

      case 'pptx':
      case 'docx':
      case 'xlsx':
        return Column(
          children: [
            Expanded(
              child:
                  _webViewError
                      ? const Center(child: Text('❌ Failed to load preview.'))
                      : kIsWeb
                      ? (_viewId == null
                          ? const Center(child: CircularProgressIndicator())
                          : HtmlElementView(viewType: _viewId!))
                      : (_webViewController == null
                          ? const Center(child: CircularProgressIndicator())
                          : WebViewWidget(controller: _webViewController!)),
            ),
            // Page/file info counter for Office files (bottom bar)
            Container(
              width: double.infinity,
              color: Colors.grey[100],
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: Text(
                widget.fileType.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        );

      default:
        return Center(child: Text('Unsupported file type: ${widget.fileType}'));
    }
  }
}

// Helper: File type icon
