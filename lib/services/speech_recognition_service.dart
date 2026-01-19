import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechRecognitionService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  // Get available locales
  Future<List<LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speechToText.locales();
  }

  // Initialize speech recognition
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw Exception('Microphone permission not granted');
    }

    _isInitialized = await _speechToText.initialize(
      onError: (error) {
        throw Exception('Speech recognition error: ${error.errorMsg}');
      },
      onStatus: (status) {
        // Can be used to track status changes
      },
    );

    return _isInitialized;
  }

  // Start listening to speech
  Future<void> startListening({
    required String languageCode,
    required Function(String) onResult,
    Function(String)? onPartialResult,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_speechToText.isAvailable) {
      throw Exception('Speech recognition not available');
    }

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        } else if (onPartialResult != null) {
          onPartialResult(result.recognizedWords);
        }
      },
      localeId: languageCode,
      listenMode: ListenMode.confirmation,
      cancelOnError: true,
      partialResults: onPartialResult != null,
    );
  }

  // Stop listening
  Future<void> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
  }

  // Cancel listening
  Future<void> cancelListening() async {
    if (_speechToText.isListening) {
      await _speechToText.cancel();
    }
  }

  // Check if currently listening
  bool get isListening => _speechToText.isListening;

  // Check if speech recognition is available
  bool get isAvailable => _speechToText.isAvailable;

  // Get last error
  String? get lastError => _speechToText.lastError?.errorMsg;

  // Dispose resources
  void dispose() {
    _speechToText.cancel();
  }
}
