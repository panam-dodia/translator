import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

// Android: Whisper Kit
import 'package:whisper_kit/whisper_kit.dart';
import 'package:record/record.dart';

// iOS: Native Speech Framework
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechRecognitionService {
  // Android Whisper components
  Whisper? _whisper;
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentRecordingPath;

  // iOS Speech Recognition components
  stt.SpeechToText? _speechToText;

  bool _isInitialized = false;
  bool _isRecording = false;

  // Initialize speech recognition (platform-specific)
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw Exception('Microphone permission not granted');
      }

      if (Platform.isAndroid) {
        // Initialize Whisper Kit for Android (using tiny model for speed)
        _whisper = Whisper(model: WhisperModel.tiny);
        print('Initialized Whisper Kit for Android with tiny model');
      } else if (Platform.isIOS) {
        // Initialize iOS Speech Recognition
        _speechToText = stt.SpeechToText();
        final available = await _speechToText!.initialize(
          onError: (error) => print('Speech recognition error: $error'),
          onStatus: (status) => print('Speech recognition status: $status'),
        );
        if (!available) {
          throw Exception('iOS Speech Recognition not available');
        }
        print('Initialized iOS Speech Recognition');
      } else {
        throw Exception('Unsupported platform');
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      _isInitialized = false;
      throw Exception('Speech recognition initialization error: $e');
    }
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

    if (_isRecording) {
      throw Exception('Already recording');
    }

    try {
      if (Platform.isAndroid) {
        // Android: Start recording for Whisper
        await _startAndroidRecording(onPartialResult);
      } else if (Platform.isIOS) {
        // iOS: Start native speech recognition
        await _startIOSListening(languageCode, onResult, onPartialResult);
      }

      _isRecording = true;
    } catch (e) {
      _isRecording = false;
      throw Exception('Failed to start listening: $e');
    }
  }

  // Android: Start recording audio for Whisper
  Future<void> _startAndroidRecording(Function(String)? onPartialResult) async {
    // Check if recording is permitted
    if (!await _audioRecorder.hasPermission()) {
      throw Exception('Microphone permission not granted');
    }

    // Create temp file for recording
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentRecordingPath = '${tempDir.path}/whisper_audio_$timestamp.wav';

    // Start recording in WAV format (required by Whisper)
    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000, // Whisper requires 16kHz
        numChannels: 1,    // Mono audio
      ),
      path: _currentRecordingPath!,
    );

    // Provide feedback
    if (onPartialResult != null) {
      onPartialResult('Listening...');
    }
  }

  // iOS: Start native speech recognition
  Future<void> _startIOSListening(
    String languageCode,
    Function(String) onResult,
    Function(String)? onPartialResult,
  ) async {
    await _speechToText!.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        } else if (onPartialResult != null) {
          onPartialResult(result.recognizedWords);
        }
      },
      localeId: languageCode,
      listenMode: stt.ListenMode.confirmation,
      cancelOnError: false,
      partialResults: true,
    );
  }

  // Stop listening and transcribe
  Future<void> stopListening({
    required Function(String) onResult,
  }) async {
    if (!_isRecording) {
      return;
    }

    try {
      if (Platform.isAndroid) {
        await _stopAndroidRecording(onResult);
      } else if (Platform.isIOS) {
        await _stopIOSListening();
      }

      _isRecording = false;
    } catch (e) {
      _isRecording = false;
      throw Exception('Failed to stop listening: $e');
    }
  }

  // Android: Stop recording and transcribe with Whisper
  Future<void> _stopAndroidRecording(Function(String) onResult) async {
    String? recordingPath;
    try {
      // Stop recording
      recordingPath = await _audioRecorder.stop();

      if (recordingPath == null || _whisper == null) {
        throw Exception('Recording failed or Whisper not initialized');
      }

      // Check if audio file exists and has content
      final audioFile = File(recordingPath);
      if (!await audioFile.exists()) {
        throw Exception('Audio file was not created');
      }

      final fileSize = await audioFile.length();
      if (fileSize < 1000) {
        throw Exception('Recording too short or empty');
      }

      print('Transcribing audio file: $recordingPath (${fileSize} bytes)');

      // Transcribe using Whisper
      final request = TranscribeRequest(
        audio: recordingPath,
        language: 'auto', // Auto-detect language
      );

      final result = await _whisper!.transcribe(transcribeRequest: request);
      final transcription = result.text.trim();

      print('Transcription result: $transcription');

      // Clean up temp file
      try {
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      } catch (e) {
        print('Cleanup error: $e');
      }

      // Return result
      if (transcription.isNotEmpty) {
        onResult(transcription);
      } else {
        throw Exception('No transcription generated');
      }
    } catch (e) {
      // Clean up file on error
      if (recordingPath != null) {
        try {
          final file = File(recordingPath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }

      throw Exception('Transcription failed: $e');
    }
  }

  // iOS: Stop native speech recognition
  Future<void> _stopIOSListening() async {
    await _speechToText!.stop();
  }

  // Cancel listening
  Future<void> cancelListening() async {
    if (_isRecording) {
      if (Platform.isAndroid) {
        await _audioRecorder.stop();

        // Clean up temp file
        if (_currentRecordingPath != null) {
          try {
            final file = File(_currentRecordingPath!);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (_) {}
        }
      } else if (Platform.isIOS) {
        await _speechToText!.cancel();
      }

      _isRecording = false;
    }
  }

  // Check if currently listening
  bool get isListening => _isRecording;

  // Check if speech recognition is available
  bool get isAvailable => _isInitialized;

  // Get available locales
  Future<List<LocaleName>> getAvailableLocales() async {
    if (Platform.isIOS && _speechToText != null) {
      // Get actual iOS supported locales
      final locales = await _speechToText!.locales();
      return locales.map((locale) => LocaleName(locale.localeId, locale.name)).toList();
    }

    // Android Whisper supports many languages
    return [
      LocaleName('en-US', 'English (US)'),
      LocaleName('en-GB', 'English (UK)'),
      LocaleName('hi-IN', 'Hindi'),
      LocaleName('es-ES', 'Spanish'),
      LocaleName('fr-FR', 'French'),
      LocaleName('de-DE', 'German'),
      LocaleName('it-IT', 'Italian'),
      LocaleName('pt-BR', 'Portuguese'),
      LocaleName('ru-RU', 'Russian'),
      LocaleName('ja-JP', 'Japanese'),
      LocaleName('zh-CN', 'Chinese'),
      LocaleName('ar-SA', 'Arabic'),
    ];
  }

  // Dispose resources
  void dispose() {
    _audioRecorder.dispose();
    _currentRecordingPath = null;
    _whisper = null;
    _speechToText = null;
  }
}

// LocaleName class for compatibility
class LocaleName {
  final String localeId;
  final String name;

  LocaleName(this.localeId, this.name);
}
