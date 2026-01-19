import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused }

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  TtsState _ttsState = TtsState.stopped;
  final List<String> _speechQueue = [];
  bool _isProcessingQueue = false;

  // Callbacks
  Function()? onStart;
  Function()? onComplete;
  Function(String)? onError;

  TtsService() {
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setSharedInstance(true);

    // Set up handlers
    _flutterTts.setStartHandler(() {
      _ttsState = TtsState.playing;
      onStart?.call();
    });

    _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
      onComplete?.call();
      _processNextInQueue();
    });

    _flutterTts.setErrorHandler((message) {
      _ttsState = TtsState.stopped;
      onError?.call(message);
      _processNextInQueue();
    });

    // Default settings
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  // Set language
  Future<void> setLanguage(String languageCode) async {
    await _flutterTts.setLanguage(languageCode);
  }

  // Set speech rate (0.0 - 1.0)
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  // Set volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }

  // Set pitch (0.5 - 2.0)
  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }

  // Get available languages
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return languages.map((lang) => lang.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  // Get available voices
  Future<List<Map>> getAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      return voices;
    } catch (e) {
      return [];
    }
  }

  // Set voice
  Future<void> setVoice(Map<String, String> voice) async {
    await _flutterTts.setVoice(voice);
  }

  // Speak text immediately (stops current speech)
  Future<void> speak(String text, {String? languageCode}) async {
    if (text.trim().isEmpty) return;

    // Stop current speech
    await stop();

    // Set language if provided
    if (languageCode != null) {
      await setLanguage(languageCode);
    }

    // Speak
    await _flutterTts.speak(text);
  }

  // Add to queue (doesn't interrupt current speech)
  Future<void> addToQueue(String text, {String? languageCode}) async {
    if (text.trim().isEmpty) return;

    if (languageCode != null) {
      _speechQueue.add('$languageCode|$text');
    } else {
      _speechQueue.add(text);
    }

    if (!_isProcessingQueue && _ttsState == TtsState.stopped) {
      _processNextInQueue();
    }
  }

  Future<void> _processNextInQueue() async {
    if (_speechQueue.isEmpty) {
      _isProcessingQueue = false;
      return;
    }

    _isProcessingQueue = true;
    final next = _speechQueue.removeAt(0);

    if (next.contains('|')) {
      final parts = next.split('|');
      final languageCode = parts[0];
      final text = parts[1];
      await speak(text, languageCode: languageCode);
    } else {
      await speak(next);
    }
  }

  // Stop current speech
  Future<void> stop() async {
    _speechQueue.clear();
    _isProcessingQueue = false;
    await _flutterTts.stop();
    _ttsState = TtsState.stopped;
  }

  // Pause speech
  Future<void> pause() async {
    await _flutterTts.pause();
    _ttsState = TtsState.paused;
  }

  // Get current state
  TtsState get state => _ttsState;

  // Check if speaking
  bool get isSpeaking => _ttsState == TtsState.playing;

  // Dispose
  void dispose() {
    _flutterTts.stop();
    _speechQueue.clear();
  }
}
