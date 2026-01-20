// App-wide constants

class AppConstants {
  // App Info
  static const String appName = 'Real-Time Translator';
  static const String appVersion = '1.0.0';

  // User IDs
  static const String user1Id = 'user1';
  static const String user2Id = 'user2';

  // Shared Preferences Keys
  static const String user1LanguageKey = 'user1_language';
  static const String user2LanguageKey = 'user2_language';
  static const String user1VoiceKey = 'user1_voice';
  static const String user2VoiceKey = 'user2_voice';
  static const String ttsSpeedKey = 'tts_speed';
  static const String ttsPitchKey = 'tts_pitch';
  static const String claudeEnabledKey = 'claude_enabled';

  // Claude API
  static const String claudeApiUrl = 'https://api.anthropic.com/v1/messages';
  static const String claudeModel = 'claude-sonnet-4-5-20250929';
  static const int claudeMaxTokens = 1024;
  static const int claudeContextMessageLimit = 20;

  // Speech Recognition
  static const Duration speechListenTimeout = Duration(seconds: 30);
  static const Duration speechPauseTimeout = Duration(seconds: 3);

  // UI
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double borderRadius = 12.0;
  static const double spacing = 16.0;
}
