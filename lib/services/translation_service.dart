import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  // Cache of translators for different language pairs
  final Map<String, OnDeviceTranslator> _translators = {};
  final Map<String, String> _translationCache = {};
  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  // Download language model if not already downloaded
  Future<bool> downloadLanguageModel(TranslateLanguage language) async {
    try {
      final isDownloaded = await _modelManager.isModelDownloaded(language.bcpCode);
      if (!isDownloaded) {
        final success = await _modelManager.downloadModel(language.bcpCode);
        return success;
      }
      return true;
    } catch (e) {
      throw Exception('Failed to download language model: $e');
    }
  }

  // Check if language model is downloaded
  Future<bool> isModelDownloaded(TranslateLanguage language) async {
    try {
      return await _modelManager.isModelDownloaded(language.bcpCode);
    } catch (e) {
      return false;
    }
  }

  // Get or create translator for language pair
  OnDeviceTranslator _getTranslator(
    TranslateLanguage source,
    TranslateLanguage target,
  ) {
    final key = '${source.bcpCode}_${target.bcpCode}';

    if (!_translators.containsKey(key)) {
      _translators[key] = OnDeviceTranslator(
        sourceLanguage: source,
        targetLanguage: target,
      );
    }

    return _translators[key]!;
  }

  // Translate text
  Future<String> translate({
    required String text,
    required TranslateLanguage sourceLanguage,
    required TranslateLanguage targetLanguage,
  }) async {
    if (text.trim().isEmpty) {
      return '';
    }

    // Check cache first
    final cacheKey = '${sourceLanguage.bcpCode}_${targetLanguage.bcpCode}_$text';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }

    try {
      // Ensure models are downloaded
      await downloadLanguageModel(sourceLanguage);
      await downloadLanguageModel(targetLanguage);

      // Get translator and translate
      final translator = _getTranslator(sourceLanguage, targetLanguage);
      final translatedText = await translator.translateText(text);

      // Cache the result
      _translationCache[cacheKey] = translatedText;

      return translatedText;
    } catch (e) {
      throw Exception('Translation failed: $e');
    }
  }

  // Get available (downloaded) models
  // Note: ML Kit doesn't provide a direct method to list all downloaded models
  // We track downloaded models through isModelDownloaded checks instead
  Future<List<String>> getDownloadedModels() async {
    return [];
  }

  // Delete language model
  Future<bool> deleteLanguageModel(TranslateLanguage language) async {
    try {
      return await _modelManager.deleteModel(language.bcpCode);
    } catch (e) {
      return false;
    }
  }

  // Clear translation cache
  void clearCache() {
    _translationCache.clear();
  }

  // Close all translators
  void dispose() {
    for (var translator in _translators.values) {
      translator.close();
    }
    _translators.clear();
    _translationCache.clear();
  }
}
