import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../services/hybrid_translation_service.dart';

class TranslationProvider extends ChangeNotifier {
  final HybridTranslationService _translationService = HybridTranslationService();

  bool _isTranslating = false;
  bool _isDownloadingModels = false;
  String? _error;
  Map<String, bool> _downloadedModels = {};
  Map<String, double> _downloadProgress = {};

  // Getters
  bool get isTranslating => _isTranslating;
  bool get isDownloadingModels => _isDownloadingModels;
  String? get error => _error;
  Map<String, bool> get downloadedModels => Map.unmodifiable(_downloadedModels);
  Map<String, double> get downloadProgress => Map.unmodifiable(_downloadProgress);

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

  // Download ONNX models for a language pair
  Future<bool> downloadOnnxModels({
    required TranslateLanguage sourceLanguage,
    required TranslateLanguage targetLanguage,
  }) async {
    try {
      _isDownloadingModels = true;
      _error = null;
      notifyListeners();

      final sourceLangCode = _getLanguageCode(sourceLanguage);
      final targetLangCode = _getLanguageCode(targetLanguage);

      print('[TRANS_PROVIDER] Starting download for $sourceLangCode-$targetLangCode');

      // Download both directions for two-way conversation
      // Download source→target (e.g., en→hi)
      print('[TRANS_PROVIDER] Downloading direction 1: $sourceLangCode->$targetLangCode');
      await _translationService.downloadOnnxModels(
        sourceLanguage: sourceLangCode,
        targetLanguage: targetLangCode,
        onProgress: (modelKey, progress) {
          _downloadProgress[modelKey] = progress;
          notifyListeners();
        },
      );
      print('[TRANS_PROVIDER] Direction 1 complete');

      // Download target→source (e.g., hi→en)
      print('[TRANS_PROVIDER] Downloading direction 2: $targetLangCode->$sourceLangCode');
      await _translationService.downloadOnnxModels(
        sourceLanguage: targetLangCode,
        targetLanguage: sourceLangCode,
        onProgress: (modelKey, progress) {
          _downloadProgress[modelKey] = progress;
          notifyListeners();
        },
      );
      print('[TRANS_PROVIDER] Direction 2 complete');

      _isDownloadingModels = false;
      _downloadProgress.clear();
      notifyListeners();
      print('[TRANS_PROVIDER] All downloads complete for $sourceLangCode-$targetLangCode');
      return true;
    } catch (e) {
      print('[TRANS_PROVIDER] Download error: $e');
      _isDownloadingModels = false;
      _downloadProgress.clear();
      _setError(e.toString());
      return false;
    }
  }

  // Check if ONNX models are available (both directions)
  Future<bool> areOnnxModelsDownloaded(TranslateLanguage sourceLanguage, TranslateLanguage targetLanguage) async {
    final sourceLangCode = _getLanguageCode(sourceLanguage);
    final targetLangCode = _getLanguageCode(targetLanguage);

    print('[TRANS_PROVIDER] Checking models for $sourceLangCode-$targetLangCode');

    // Check both directions
    final direction1 = await _translationService.areOnnxModelsDownloaded(sourceLangCode, targetLangCode);
    print('[TRANS_PROVIDER] Direction $sourceLangCode->$targetLangCode: $direction1');

    final direction2 = await _translationService.areOnnxModelsDownloaded(targetLangCode, sourceLangCode);
    print('[TRANS_PROVIDER] Direction $targetLangCode->$sourceLangCode: $direction2');

    final bothDownloaded = direction1 && direction2;
    print('[TRANS_PROVIDER] Both directions downloaded: $bothDownloaded');

    return bothDownloaded;
  }

  // Check if ML Kit models are available
  Future<bool> areMLKitModelsDownloaded(TranslateLanguage sourceLanguage, TranslateLanguage targetLanguage) async {
    return await _translationService.areMLKitModelsDownloaded(sourceLanguage, targetLanguage);
  }

  // Get current translation method
  Future<String> getCurrentTranslationMethod(TranslateLanguage sourceLanguage, TranslateLanguage targetLanguage) async {
    return await _translationService.getCurrentMethod(sourceLanguage, targetLanguage);
  }

  // Convert TranslateLanguage to language code string
  String _getLanguageCode(TranslateLanguage language) {
    if (language == TranslateLanguage.english) return 'en';
    if (language == TranslateLanguage.hindi) return 'hi';
    if (language == TranslateLanguage.spanish) return 'es';
    if (language == TranslateLanguage.french) return 'fr';
    if (language == TranslateLanguage.german) return 'de';
    if (language == TranslateLanguage.chinese) return 'zh';
    if (language == TranslateLanguage.japanese) return 'ja';
    if (language == TranslateLanguage.korean) return 'ko';
    if (language == TranslateLanguage.arabic) return 'ar';
    if (language == TranslateLanguage.russian) return 'ru';
    if (language == TranslateLanguage.italian) return 'it';
    if (language == TranslateLanguage.portuguese) return 'pt';
    return 'en'; // Default
  }

  // Toggle ONNX preference
  void setPreferOnnx(bool prefer) {
    _translationService.setPreferOnnx(prefer);
    notifyListeners();
  }

  // Check if ONNX is preferred
  bool get prefersOnnx => _translationService.prefersOnnx;

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
