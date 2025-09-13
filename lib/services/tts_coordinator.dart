import 'package:flutter/foundation.dart';

enum TtsSource { filePreview, chat }

class TtsCoordinator extends ChangeNotifier {
  TtsCoordinator._();
  static final TtsCoordinator instance = TtsCoordinator._();

  TtsSource? _activeSource;
  String? _activeMessageId; // used only for chat

  TtsSource? get activeSource => _activeSource;
  String? get activeMessageId => _activeMessageId;

  void setActive({required TtsSource source, String? messageId}) {
    _activeSource = source;
    _activeMessageId = messageId;
    notifyListeners();
  }

  void clear() {
    _activeSource = null;
    _activeMessageId = null;
    notifyListeners();
  }

  void clearIfMatches({required TtsSource source, String? messageId}) {
    if (_activeSource == source && _activeMessageId == messageId) {
      clear();
    }
  }
}
