import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'onnx_translation_service.dart';

/// Hybrid translation service that uses ONNX (OPUS-MT) with ML Kit fallback
class HybridTranslationService {
  final OnnxTranslationService _onnxService = OnnxTranslationService();

  // ML Kit components (fallback)
  final Map<String, OnDeviceTranslator> _mlkitTranslators = {};
  final OnDeviceTranslatorModelManager _mlkitModelManager =
      OnDeviceTranslatorModelManager();

  final Map<String, String> _translationCache = {};
  bool _isInitialized = false;
  bool _preferOnnx = true; // User can toggle this

  /// Initialize the service
  Future<void> initialize() async {
    try {
      await _onnxService.initialize();
      _isInitialized = true;
    } catch (e) {
      print('ONNX initialization failed, using ML Kit only: $e');
      _preferOnnx = false;
      _isInitialized = true;
    }
  }

  /// Translate text using best available method
  Future<String> translate({
    required String text,
    required TranslateLanguage sourceLanguage,
    required TranslateLanguage targetLanguage,
  }) async {
    if (!_isInitialized) await initialize();

    if (text.trim().isEmpty) return '';

    final processedText = _preprocessText(text);
    final sourceLangCode = _getLanguageCode(sourceLanguage);
    final targetLangCode = _getLanguageCode(targetLanguage);
    final cacheKey = '${sourceLangCode}_${targetLangCode}_$processedText';

    // Check cache
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }

    // Always use ONNX (no ML Kit fallback - user wants to see what happens)
    try {
      print('[HYBRID] Attempting ONNX translation...');

      // Check if models are downloaded
      final modelsAvailable = await _onnxService.areModelsDownloaded(sourceLangCode, targetLangCode);
      if (!modelsAvailable) {
        throw Exception(
          'ONNX models not downloaded for $sourceLangCode-$targetLangCode. '
          'Please download models first from Settings.'
        );
      }

      // Use ONNX directly
      final translatedText = await _onnxService.translate(
        text: processedText,
        sourceLang: sourceLangCode,
        targetLang: targetLangCode,
      );

      print('[HYBRID] ONNX translation successful: "$translatedText"');

      // Cache result
      _translationCache[cacheKey] = translatedText;
      return translatedText;
    } catch (e, stackTrace) {
      print('[HYBRID] ONNX translation failed: $e');
      print('[HYBRID] Stack trace: $stackTrace');
      throw Exception('ONNX translation failed: $e');
    }
  }

  /// Translate using ML Kit (fallback method)
  Future<String> _translateWithMLKit(
    String text,
    TranslateLanguage sourceLanguage,
    TranslateLanguage targetLanguage,
  ) async {
    // Download models if needed
    await _downloadMLKitModel(sourceLanguage);
    await _downloadMLKitModel(targetLanguage);

    // Get or create translator
    final translator = _getMLKitTranslator(sourceLanguage, targetLanguage);
    return await translator.translateText(text);
  }

  /// Download ML Kit model if not already downloaded
  Future<bool> _downloadMLKitModel(TranslateLanguage language) async {
    try {
      final isDownloaded = await _mlkitModelManager.isModelDownloaded(language.bcpCode);
      if (!isDownloaded) {
        return await _mlkitModelManager.downloadModel(language.bcpCode);
      }
      return true;
    } catch (e) {
      throw Exception('Failed to download ML Kit model: $e');
    }
  }

  /// Get or create ML Kit translator
  OnDeviceTranslator _getMLKitTranslator(
    TranslateLanguage source,
    TranslateLanguage target,
  ) {
    final key = '${source.bcpCode}_${target.bcpCode}';
    if (!_mlkitTranslators.containsKey(key)) {
      _mlkitTranslators[key] = OnDeviceTranslator(
        sourceLanguage: source,
        targetLanguage: target,
      );
    }
    return _mlkitTranslators[key]!;
  }

  /// Convert TranslateLanguage to language code string
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

  /// Pre-process text for better translation
  String _preprocessText(String text) {
    String processed = text.trim();
    processed = processed.replaceAll(RegExp(r'\s+'), ' ');
    processed = processed.replaceAll(RegExp(r'\s+([,\.!?;:])'), r'$1');
    processed = processed.replaceAll(RegExp(r'([,\.!?;:])([^\s])'), r'$1 $2');
    return processed;
  }

  /// Download ONNX models for a language pair
  Future<void> downloadOnnxModels({
    required String sourceLanguage,
    required String targetLanguage,
    Function(String, double)? onProgress,
  }) async {
    if (!_isInitialized) await initialize();
    await _onnxService.downloadModels(
      sourceLang: sourceLanguage,
      targetLang: targetLanguage,
      onProgress: onProgress,
    );
  }

  /// Check if ONNX models are downloaded
  Future<bool> areOnnxModelsDownloaded(String sourceLanguage, String targetLanguage) async {
    if (!_isInitialized) await initialize();
    return await _onnxService.areModelsDownloaded(sourceLanguage, targetLanguage);
  }

  /// Check if ML Kit models are downloaded
  Future<bool> areMLKitModelsDownloaded(TranslateLanguage sourceLanguage, TranslateLanguage targetLanguage) async {
    final sourceDownloaded = await _mlkitModelManager.isModelDownloaded(sourceLanguage.bcpCode);
    final targetDownloaded = await _mlkitModelManager.isModelDownloaded(targetLanguage.bcpCode);

    return sourceDownloaded && targetDownloaded;
  }

  /// Get current translation method
  Future<String> getCurrentMethod(TranslateLanguage sourceLanguage, TranslateLanguage targetLanguage) async {
    final sourceLangCode = _getLanguageCode(sourceLanguage);
    final targetLangCode = _getLanguageCode(targetLanguage);

    if (_preferOnnx && await _onnxService.areModelsDownloaded(sourceLangCode, targetLangCode)) {
      return 'OPUS-MT (Neural)';
    }
    return 'ML Kit (Basic)';
  }

  /// Toggle ONNX preference
  void setPreferOnnx(bool prefer) {
    _preferOnnx = prefer;
  }

  /// Check if ONNX is preferred
  bool get prefersOnnx => _preferOnnx;

  /// Check if ML Kit model is downloaded (for backwards compatibility)
  Future<bool> isModelDownloaded(TranslateLanguage language) async {
    return await _mlkitModelManager.isModelDownloaded(language.bcpCode);
  }

  /// Download ML Kit model (for backwards compatibility)
  Future<bool> downloadLanguageModel(TranslateLanguage language) async {
    try {
      final isDownloaded = await _mlkitModelManager.isModelDownloaded(language.bcpCode);
      if (!isDownloaded) {
        return await _mlkitModelManager.downloadModel(language.bcpCode);
      }
      return true;
    } catch (e) {
      throw Exception('Failed to download language model: $e');
    }
  }

  /// Get downloaded models (returns empty for now)
  Future<List<String>> getDownloadedModels() async {
    return [];
  }

  /// Delete ML Kit language model
  Future<bool> deleteLanguageModel(TranslateLanguage language) async {
    try {
      return await _mlkitModelManager.deleteModel(language.bcpCode);
    } catch (e) {
      return false;
    }
  }

  /// Clear translation cache
  void clearCache() {
    _translationCache.clear();
    _onnxService.clearCache();
  }

  /// Dispose all resources
  void dispose() {
    _onnxService.dispose();

    for (var translator in _mlkitTranslators.values) {
      translator.close();
    }
    _mlkitTranslators.clear();
    _translationCache.clear();
  }
}
