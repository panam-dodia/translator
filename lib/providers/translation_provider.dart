import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../services/translation_service.dart';

class TranslationProvider extends ChangeNotifier {
  final TranslationService _translationService = TranslationService();

  bool _isTranslating = false;
  String? _error;
  Map<String, bool> _downloadedModels = {};

  // Getters
  bool get isTranslating => _isTranslating;
  String? get error => _error;
  Map<String, bool> get downloadedModels => Map.unmodifiable(_downloadedModels);

  // Check if model is downloaded
  Future<bool> isModelDownloaded(TranslateLanguage language) async {
    final isDownloaded = await _translationService.isModelDownloaded(language);
    _downloadedModels[language.bcpCode] = isDownloaded;
    notifyListeners();
    return isDownloaded;
  }

  // Download language model
  Future<bool> downloadModel(TranslateLanguage language) async {
    try {
      final success = await _translationService.downloadLanguageModel(language);
      _downloadedModels[language.bcpCode] = success;
      notifyListeners();
      return success;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Translate text
  Future<String> translate({
    required String text,
    required TranslateLanguage sourceLanguage,
    required TranslateLanguage targetLanguage,
  }) async {
    try {
      _isTranslating = true;
      _error = null;
      notifyListeners();

      final translatedText = await _translationService.translate(
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );

      _isTranslating = false;
      notifyListeners();

      return translatedText;
    } catch (e) {
      _isTranslating = false;
      _setError(e.toString());
      rethrow;
    }
  }

  // Get downloaded models
  Future<void> loadDownloadedModels() async {
    final models = await _translationService.getDownloadedModels();
    for (var model in models) {
      _downloadedModels[model] = true;
    }
    notifyListeners();
  }

  // Delete model
  Future<bool> deleteModel(TranslateLanguage language) async {
    final success = await _translationService.deleteLanguageModel(language);
    if (success) {
      _downloadedModels[language.bcpCode] = false;
      notifyListeners();
    }
    return success;
  }

  // Clear cache
  void clearCache() {
    _translationService.clearCache();
  }

  // Set error
  void _setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  @override
  void dispose() {
    _translationService.dispose();
    super.dispose();
  }
}
