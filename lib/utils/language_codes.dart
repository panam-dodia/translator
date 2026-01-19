import 'package:google_mlkit_translation/google_mlkit_translation.dart';

// Language mappings for speech recognition, translation, and TTS

class LanguageInfo {
  final String name;
  final String code; // For speech_to_text and flutter_tts
  final TranslateLanguage mlKitLanguage; // For ML Kit translation

  const LanguageInfo({
    required this.name,
    required this.code,
    required this.mlKitLanguage,
  });
}

class LanguageCodes {
  // Map of supported languages
  // Note: Not all languages support all features (speech recognition, TTS, translation)
  static const Map<String, LanguageInfo> supportedLanguages = {
    'en': LanguageInfo(
      name: 'English',
      code: 'en-US',
      mlKitLanguage: TranslateLanguage.english,
    ),
    'es': LanguageInfo(
      name: 'Spanish',
      code: 'es-ES',
      mlKitLanguage: TranslateLanguage.spanish,
    ),
    'fr': LanguageInfo(
      name: 'French',
      code: 'fr-FR',
      mlKitLanguage: TranslateLanguage.french,
    ),
    'de': LanguageInfo(
      name: 'German',
      code: 'de-DE',
      mlKitLanguage: TranslateLanguage.german,
    ),
    'it': LanguageInfo(
      name: 'Italian',
      code: 'it-IT',
      mlKitLanguage: TranslateLanguage.italian,
    ),
    'pt': LanguageInfo(
      name: 'Portuguese',
      code: 'pt-PT',
      mlKitLanguage: TranslateLanguage.portuguese,
    ),
    'zh': LanguageInfo(
      name: 'Chinese',
      code: 'zh-CN',
      mlKitLanguage: TranslateLanguage.chinese,
    ),
    'ja': LanguageInfo(
      name: 'Japanese',
      code: 'ja-JP',
      mlKitLanguage: TranslateLanguage.japanese,
    ),
    'ko': LanguageInfo(
      name: 'Korean',
      code: 'ko-KR',
      mlKitLanguage: TranslateLanguage.korean,
    ),
    'ar': LanguageInfo(
      name: 'Arabic',
      code: 'ar-SA',
      mlKitLanguage: TranslateLanguage.arabic,
    ),
    'ru': LanguageInfo(
      name: 'Russian',
      code: 'ru-RU',
      mlKitLanguage: TranslateLanguage.russian,
    ),
    'hi': LanguageInfo(
      name: 'Hindi',
      code: 'hi-IN',
      mlKitLanguage: TranslateLanguage.hindi,
    ),
  };

  // Get language info by code
  static LanguageInfo? getLanguageInfo(String code) {
    return supportedLanguages[code];
  }

  // Get all language names for dropdown
  static List<String> getLanguageNames() {
    return supportedLanguages.values.map((info) => info.name).toList()..sort();
  }

  // Get language code from name
  static String? getLanguageCodeByName(String name) {
    for (var entry in supportedLanguages.entries) {
      if (entry.value.name == name) {
        return entry.key;
      }
    }
    return null;
  }

  // Get all language codes
  static List<String> getLanguageCodes() {
    return supportedLanguages.keys.toList();
  }
}
