import 'package:flutter/foundation.dart';
import '../services/speech_recognition_service.dart';

enum SpeechState { idle, listening, processing, error }

class SpeechProvider extends ChangeNotifier {
  final SpeechRecognitionService _speechService = SpeechRecognitionService();

  SpeechState _state = SpeechState.idle;
  String _partialText = '';
  String _finalText = '';
  String? _error;
  String _currentLanguage = 'en-US';

  // Getters
  SpeechState get state => _state;
  String get partialText => _partialText;
  String get finalText => _finalText;
  String? get error => _error;
  String get currentLanguage => _currentLanguage;
  bool get isListening => _state == SpeechState.listening;

  // Initialize speech recognition
  Future<bool> initialize() async {
    try {
      final success = await _speechService.initialize();
      return success;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Set language for speech recognition
  void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
    notifyListeners();
  }

  // Start listening
  Future<void> startListening({
    required Function(String) onFinalResult,
  }) async {
    try {
      _state = SpeechState.listening;
      _partialText = '';
      _finalText = '';
      _error = null;
      notifyListeners();

      await _speechService.startListening(
        languageCode: _currentLanguage,
        onResult: (text) {
          _finalText = text;
          _state = SpeechState.processing;
          notifyListeners();
          onFinalResult(text);
        },
        onPartialResult: (text) {
          _partialText = text;
          notifyListeners();
        },
      );
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    try {
      await _speechService.stopListening();
      _state = SpeechState.idle;
      _partialText = '';
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Cancel listening
  Future<void> cancelListening() async {
    try {
      await _speechService.cancelListening();
      _state = SpeechState.idle;
      _partialText = '';
      _finalText = '';
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Reset state
  void reset() {
    _state = SpeechState.idle;
    _partialText = '';
    _finalText = '';
    _error = null;
    notifyListeners();
  }

  // Set error
  void _setError(String errorMessage) {
    _state = SpeechState.error;
    _error = errorMessage;
    notifyListeners();
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }
}
