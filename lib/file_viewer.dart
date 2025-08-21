import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'models.dart';
import 'services/speech_service.dart';

class FileViewer extends StatefulWidget {
  final FileMeta file;
  final Function(int currentPage, int totalPages)? onPdfPageChanged;

  const FileViewer({super.key, required this.file, this.onPdfPageChanged});

  @override
  State<FileViewer> createState() => _FileViewerState();
}

class _FileViewerState extends State<FileViewer> {
  final PdfViewerController _pdfController = PdfViewerController();
  WebViewController? _webViewController;
  Timer? _hideCounterTimer;
  final SpeechService _speech = SpeechService();

  bool _speaking = false;
  bool _webViewError = false;
  bool _showPdfPageCounter = false;
  int _currentPdfPage = 1;
  int? _pdfPageCount;

  // TTS with highlighting variables
  String _fullText = '';
  List<TextSpan> _highlightedTextSpans = [];
  int _currentWordIndex = 0;
  List<String> _words = [];
  Timer? _highlightTimer;
  final ScrollController _textScrollController = ScrollController();
  final GlobalKey _textKey = GlobalKey();

  bool get _isPdf => widget.file.type.toLowerCase() == 'pdf';
  bool get _isOfficeFile =>
      ['docx', 'pptx', 'xlsx'].contains(widget.file.type.toLowerCase());

  @override
  void initState() {
    super.initState();
    _speech.initialize();
    _initializeContent();
    if (_isOfficeFile) _setupWebView();
  }

  void _initializeContent() {
    // Get text content for TTS
    _fullText =
        widget.file.summary?.isNotEmpty == true
            ? widget.file.summary!
            : (widget.file.extractedText?.isNotEmpty == true
                ? widget.file.extractedText!
                : 'No text available yet.');

    _words = _fullText.split(RegExp(r'\s+'));
    _generateTextSpans();
  }

  void _generateTextSpans() {
    _highlightedTextSpans = [];
    for (int i = 0; i < _words.length; i++) {
      _highlightedTextSpans.add(
        TextSpan(
          text: '${_words[i]} ',
          style: TextStyle(
            backgroundColor:
                i == _currentWordIndex
                    // ignore: deprecated_member_use
                    ? Colors.yellow.withOpacity(0.7)
                    : Colors.transparent,
            color: i == _currentWordIndex ? Colors.black : null,
            fontWeight:
                i == _currentWordIndex ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }
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
      await _stopSpeaking();
      return;
    }
    await _startSpeaking();
  }

  Future<void> _startSpeaking() async {
    if (_fullText.trim().isEmpty) return;

    setState(() {
      _speaking = true;
      _currentWordIndex = 0;
    });

    // Start TTS
    await _speech.speak(
      _fullText,
      onComplete: () {
        if (mounted) {
          setState(() {
            _speaking = false;
            _currentWordIndex = 0;
          });
          _generateTextSpans();
          _highlightTimer?.cancel();
        }
      },
    );

    // Start word highlighting timer
    _startWordHighlighting();
  }

  void _startWordHighlighting() {
    _highlightTimer?.cancel();

    // Calculate approximate timing per word (adjust based on speech rate)
    final wordsPerMinute = 150; // Average reading speed
    final millisecondsPerWord = (60 * 1000) ~/ wordsPerMinute;

    _highlightTimer = Timer.periodic(
      Duration(milliseconds: millisecondsPerWord),
      (timer) {
        if (!_speaking || _currentWordIndex >= _words.length) {
          timer.cancel();
          return;
        }

        setState(() {
          _currentWordIndex++;
          _generateTextSpans();
        });

        // Auto-scroll to keep highlighted word visible
        _autoScrollToCurrentWord();
      },
    );
  }

  void _autoScrollToCurrentWord() {
    if (!_textScrollController.hasClients) return;

    // Estimate position based on current word index
    final totalWords = _words.length;
    final progress = _currentWordIndex / totalWords;
    final maxScroll = _textScrollController.position.maxScrollExtent;
    final targetScroll = maxScroll * progress;

    _textScrollController.animateTo(
      targetScroll,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _stopSpeaking() async {
    await _speech.stop();
    _highlightTimer?.cancel();
    setState(() {
      _speaking = false;
      _currentWordIndex = 0;
    });
    _generateTextSpans();
  }

  @override
  void dispose() {
    _hideCounterTimer?.cancel();
    _highlightTimer?.cancel();
    _pdfController.dispose();
    _textScrollController.dispose();
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
    return _buildTextViewer();
  }

  Widget _buildPdfViewer() {
    return Stack(
      children: [
        SfPdfViewer.network(
          widget.file.url,
          controller: _pdfController,
          onPageChanged: (details) {
            _handlePdfPageChange(details.newPageNumber);
            if (_pdfPageCount != details.oldPageNumber) {
              setState(() => _pdfPageCount = details.oldPageNumber);
            }
          },
        ),
        if (_showPdfPageCounter)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Page $_currentPdfPage${_pdfPageCount != null ? ' of $_pdfPageCount' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        Positioned(top: 12, right: 12, child: _ttsButton()),
      ],
    );
  }

  Widget _buildOfficeViewer() {
    return Stack(
      children: [
        _webViewError
            ? const Center(child: Text('Failed to load document viewer'))
            : _webViewController != null
            ? WebViewWidget(controller: _webViewController!)
            : const Center(child: CircularProgressIndicator()),
        Positioned(top: 12, right: 12, child: _ttsButton()),
      ],
    );
  }

  Widget _buildTextViewer() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            controller: _textScrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Text Content:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  key: _textKey,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText.rich(
                    TextSpan(children: _highlightedTextSpans),
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
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
