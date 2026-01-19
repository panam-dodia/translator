import 'package:flutter/foundation.dart';
import '../services/tts_service.dart';

class TtsProvider extends ChangeNotifier {
  final TtsService _ttsService = TtsService();

  bool _isSpeaking = false;
  String _currentLanguage = 'en-US';
  double _speechRate = 0.5;
  double _pitch = 1.0;

  TtsProvider() {
    _setupCallbacks();
  }

  void _setupCallbacks() {
    _ttsService.onStart = () {
      _isSpeaking = true;
      notifyListeners();
    };

    _ttsService.onComplete = () {
      _isSpeaking = false;
      notifyListeners();
    };

    _ttsService.onError = (message) {
      _isSpeaking = false;
      notifyListeners();
    };
  }

  // Getters
  bool get isSpeaking => _isSpeaking;
  String get currentLanguage => _currentLanguage;
  double get speechRate => _speechRate;
  double get pitch => _pitch;

  // Set language
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    await _ttsService.setLanguage(languageCode);
    notifyListeners();
  }

  // Set speech rate
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _ttsService.setSpeechRate(rate);
    notifyListeners();
  }

  // Set pitch
  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    await _ttsService.setPitch(pitch);
    notifyListeners();
  }

  // Speak text
  Future<void> speak(String text, {String? languageCode}) async {
    await _ttsService.speak(text, languageCode: languageCode);
  }

  // Add to queue
  Future<void> addToQueue(String text, {String? languageCode}) async {
    await _ttsService.addToQueue(text, languageCode: languageCode);
  }

  // Stop speaking
  Future<void> stop() async {
    await _ttsService.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  // Pause speaking
  Future<void> pause() async {
    await _ttsService.pause();
    _isSpeaking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }
}
