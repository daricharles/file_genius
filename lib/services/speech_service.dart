// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

typedef VoidCallback = void Function();

class SpeechService extends ChangeNotifier {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  // TTS variables
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool _isPaused = false;
  bool _ttsReady = false;

  // STT variables
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';

  // Getters
  bool get isSpeaking => _isSpeaking;
  bool get isPaused => _isPaused;
  bool get isListening => _isListening;
  bool get speechEnabled => _speechEnabled;
  String get lastWords => _lastWords;

  Future<void> initialize() async {
    await _initializeTts();
    await _initializeStt();
  }

  // TTS Methods
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
      notifyListeners();
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      _isPaused = false;
      notifyListeners();
    });
    _ttsReady = true;
  }

  Future<void> speak(String text, {VoidCallback? onComplete}) async {
    if (text.isNotEmpty) {
      if (!_ttsReady) await _initializeTts();
      await _flutterTts.speak(text);
    }
    onComplete?.call();
  }

  Future<void> speakText(String text) async {
    if (text.isEmpty) return;
    if (!_ttsReady) await _initializeTts();
    // Stop any current speech before starting new
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    // await _tts.stop();
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

  // STT Methods
  Future<void> _initializeStt() async {
    // Request microphone permission
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return;
    }

    _speechEnabled = await _speechToText.initialize(
      onError: (error) {
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
          if (result.finalResult) {
            onResult(_lastWords);
            _isListening = false;
            notifyListeners();
          }
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
