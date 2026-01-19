import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Load environment variables
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
  }

  // Get Claude API key from environment
  static String get claudeApiKey {
    final apiKey = dotenv.env['CLAUDE_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_api_key_here') {
      throw Exception(
        'CLAUDE_API_KEY not found in .env file. Please add your API key to the .env file.',
      );
    }
    return apiKey;
  }

  // Check if Claude API is configured
  static bool get isClaudeConfigured {
    try {
      final apiKey = dotenv.env['CLAUDE_API_KEY'];
      return apiKey != null &&
             apiKey.isNotEmpty &&
             apiKey != 'your_api_key_here';
    } catch (e) {
      return false;
    }
  }
}
