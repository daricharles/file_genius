import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'html_view_factory_stub.dart'
    if (dart.library.html) 'html_view_factory_web.dart';
import 'services/speech_service.dart'; // adjust relative path if needed
import 'models.dart';

class FileViewer extends StatefulWidget {
  final FileMeta file;
  final void Function(int page, int total)? onPdfPageChanged;

  const FileViewer({super.key, required this.file, this.onPdfPageChanged});

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

  bool _showPdfPageCounter = false;
  Timer? _hideCounterTimer;

  final SpeechService _speech = SpeechService(); // NEW
  bool _speaking = false; // NEW

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

  bool get _isOfficeFile {
    final ext = widget.file.type.toLowerCase();
    return ext == 'pptx' || ext == 'docx' || ext == 'xlsx';
  }

  bool get _isPdf => widget.file.type.toLowerCase() == 'pdf';

  void _registerIframe() {
    final viewerUrl =
        'https://docs.google.com/gview?url=${Uri.encodeComponent(widget.file.url)}&embedded=true';
    final viewId = 'iframe-${widget.file.url.hashCode}';
    registerIframe(viewId, viewerUrl);
    setState(() => _viewId = viewId);
  }

  void _setupWebView() {
    final viewerUrl =
        'https://docs.google.com/gview?url=${Uri.encodeComponent(widget.file.url)}&embedded=true';
    try {
      _webViewController =
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse(viewerUrl));
    } catch (_) {
      setState(() => _webViewError = true);
    }
  }

  void _handlePdfPageChange(int newPage) {
    setState(() {
      _currentPdfPage = newPage;
      _showPdfPageCounter = true;
    });
    widget.onPdfPageChanged?.call(newPage, _pdfPageCount ?? 0);

    _hideCounterTimer?.cancel();
    _hideCounterTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() => _showPdfPageCounter = false);
      }
    });
  }

  Future<void> _toggleSpeak() async {
    if (_speaking) {
      await _speech.stop();
      setState(() => _speaking = false);
      return;
    }
    final text =
        widget.file.summary?.isNotEmpty == true
            ? widget.file.summary!
            : (widget.file.extractedText?.isNotEmpty == true
                ? widget.file.extractedText!
                : 'No text available yet.');
    if (text.trim().isEmpty) return;
    setState(() => _speaking = true);
    await _speech.speak(
      text,
      onComplete: () {
        if (mounted) {
          setState(() => _speaking = false);
        }
      },
    );
  }

  @override
  void dispose() {
    _hideCounterTimer?.cancel();
    _pdfController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.file.url.isEmpty) {
      return const Center(child: Text('No file selected.'));
    }

    if (_isPdf) return _buildPdfViewer();
    if (_isOfficeFile) return _buildOfficeViewer();
    return _buildUnsupported();
  }

  Widget _buildPdfViewer() {
    return Stack(
      children: [
        SfPdfViewer.network(
          widget.file.url,
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
            _handlePdfPageChange(details.newPageNumber);
          },
          canShowScrollHead: true,
          canShowScrollStatus: true,
        ),
        if (_pdfLoading) const Center(child: CircularProgressIndicator()),
        if (_pdfPageCount != null && !_pdfLoading && _showPdfPageCounter)
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: _pdfOverlayControls(),
          ),
        Positioned(top: 12, right: 12, child: _ttsButton()),
      ],
    );
  }

  Widget _pdfOverlayControls() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(33, 33, 33, 0.85),
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.15),
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
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.white, size: 20),
              tooltip: 'Zoom out',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  _pdfZoomLevel = (_pdfZoomLevel - 0.25).clamp(1.0, 3.0);
                  _pdfController.zoomLevel = _pdfZoomLevel;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.fit_screen, color: Colors.white, size: 20),
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
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              tooltip: 'Zoom in',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  _pdfZoomLevel = (_pdfZoomLevel + 0.25).clamp(1.0, 3.0);
                  _pdfController.zoomLevel = _pdfZoomLevel;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficeViewer() {
    return Stack(
      children: [
        Column(
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
            Container(
              width: double.infinity,
              color: Colors.grey[100],
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: Text(
                widget.file.type.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        Positioned(top: 12, right: 12, child: _ttsButton()),
      ],
    );
  }

  Widget _buildUnsupported() {
    return Stack(
      children: [
        Center(child: Text('Unsupported file type: ${widget.file.type}')),
        Positioned(top: 12, right: 12, child: _ttsButton()),
      ],
    );
  }

  Widget _ttsButton() {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: _speaking ? 'Stop Reading' : 'Read Aloud',
        icon: Icon(
          _speaking ? Icons.stop_circle : Icons.volume_up,
          color: Colors.white,
        ),
        onPressed: _toggleSpeak,
      ),
    );
  }
}
