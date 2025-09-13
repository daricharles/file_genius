// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService extends ChangeNotifier {
  // (Optional) remove singleton if not strictly needed with Provider.
  // static final SpeechService _instance = SpeechService._internal();
  // factory SpeechService() => _instance;
  // SpeechService._internal();
  SpeechService(); // simple constructor

  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool _isPaused = false;
  bool _ttsReady = false;
  VoidCallback? _pendingOnComplete;

  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';

  bool _ready = false;

  bool get isSpeaking => _isSpeaking;
  bool get isPaused => _isPaused;
  bool get isListening => _isListening;
  bool get speechEnabled => _speechEnabled;
  String get lastWords => _lastWords;
  bool get isReady => _ready;

  Future<void> initialize() async {
    await _initializeTts();
    await _initializeStt();
    _ready = true;
    notifyListeners();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _isPaused = false;
      // Fire any pending onComplete callback for the last speak()
      try {
        _pendingOnComplete?.call();
      } finally {
        _pendingOnComplete = null;
      }
      notifyListeners();
    });

    _flutterTts.setErrorHandler((_) {
      _isSpeaking = false;
      _isPaused = false;
      notifyListeners();
    });
    _ttsReady = true;
  }

  Future<void> speak(String text, {VoidCallback? onComplete}) async {
    if (text.isNotEmpty) {
      if (!_ttsReady) await _initializeTts();
      _pendingOnComplete = onComplete;
      await _flutterTts.speak(text);
    }
  }

  Future<void> speakText(String text) async {
    if (text.isEmpty) return;
    if (!_ttsReady) await _initializeTts();
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    _isPaused = false;
    notifyListeners();
  }

  Future<void> pause() async {
    await _flutterTts.pause();
    _isPaused = true;
    notifyListeners();
  }

  // Best-effort resume: supported on some platforms; if unavailable, callers
  // should re-invoke speak(text) from their own stored source.
  Future<bool> resume() async {
    try {
      // This may throw on platforms where resume isn't implemented.
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      final r = await (_flutterTts as dynamic).resume();
      // Some platforms return 1/true on success; treat non-null as success
      _isPaused = false;
      _isSpeaking = true;
      notifyListeners();
      return r != null ? true : true;
    } catch (_) {
      return false; // Caller should fallback to re-speak from the beginning.
    }
  }

  Future<void> _initializeStt() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return;
    }

    _speechEnabled = await _speechToText.initialize(
      onError: (_) {
        _isListening = false;
        notifyListeners();
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          notifyListeners();
        }
      },
    );
    notifyListeners();
  }

  Future<void> startListening({required Function(String) onResult}) async {
    if (!_speechEnabled) {
      await _initializeStt();
    }
    if (_speechEnabled && !_isListening) {
      _lastWords = '';
      _isListening = true;
      notifyListeners();

      await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          onResult(_lastWords);
          _isListening = result.finalResult ? false : _isListening;
          notifyListeners();
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }
}
