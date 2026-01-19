import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/conversation_message.dart';
import '../utils/constants.dart';

class ClaudeAPIService {
  final Dio _dio = Dio();

  ClaudeAPIService() {
    _configureDio();
  }

  void _configureDio() {
    _dio.options.baseUrl = AppConstants.claudeApiUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'x-api-key': AppConfig.claudeApiKey,
      'anthropic-version': '2023-06-01',
    };
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  // Build context from conversation messages
  String _buildContext(List<ConversationMessage> messages, {int limit = 10}) {
    if (messages.isEmpty) return '';

    // Take last N messages to keep context manageable
    final recentMessages = messages.length > limit
        ? messages.sublist(messages.length - limit)
        : messages;

    final buffer = StringBuffer();
    buffer.writeln('Recent conversation context:');
    buffer.writeln();

    for (var message in recentMessages) {
      final userName = message.userId == AppConstants.user1Id ? 'Traveler' : 'Local';
      final language = message.sourceLanguage;
      buffer.writeln('$userName ($language): "${message.originalText}"');
      buffer.writeln('Translation (${message.targetLanguage}): "${message.translatedText}"');
      buffer.writeln();
    }

    return buffer.toString();
  }

  // Send query to Claude API
  Future<String> sendQuery({
    required String query,
    List<ConversationMessage>? contextMessages,
  }) async {
    try {
      // Build context from recent messages
      final context = contextMessages != null && contextMessages.isNotEmpty
          ? _buildContext(contextMessages)
          : '';

      // Construct the full prompt
      final fullPrompt = context.isNotEmpty
          ? '''$context

User question: $query

Please provide a helpful and concise answer based on the conversation context above.'''
          : query;

      // Prepare request body
      final requestBody = {
        'model': AppConstants.claudeModel,
        'max_tokens': AppConstants.claudeMaxTokens,
        'messages': [
          {
            'role': 'user',
            'content': fullPrompt,
          }
        ],
      };

      // Make API request
      final response = await _dio.post(
        '',
        data: requestBody,
      );

      // Extract response
      if (response.statusCode == 200) {
        final content = response.data['content'] as List;
        if (content.isNotEmpty) {
          return content[0]['text'] as String;
        }
        throw Exception('Empty response from Claude API');
      } else {
        throw Exception('Claude API error: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorMessage = e.response?.data['error']?['message'] ??
            'Unknown API error';
        throw Exception('Claude API error: $errorMessage');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to query Claude: $e');
    }
  }

  // Test API connection
  Future<bool> testConnection() async {
    try {
      await sendQuery(query: 'Hello, can you hear me?');
      return true;
    } catch (e) {
      return false;
    }
  }

  // AI Feature Option 2: Analyze message for idioms, slang, and suggest better translations
  Future<String> analyzeMessage({
    required String originalText,
    required String translatedText,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final query = '''Analyze this translation from $sourceLanguage to $targetLanguage:

Original: "$originalText"
Translation: "$translatedText"

Please:
1. Check if there are any idioms, slang, or cultural expressions that might be lost in translation
2. Suggest if there's a more natural or contextually better translation
3. Provide any cultural tips that would help the traveler

Keep your response very concise (2-3 sentences max, friendly tone).''';

    return await sendQuery(query: query);
  }

  // AI Feature Option 3: Get conversation insights (summary, common phrases, cultural tips)
  Future<String> getConversationInsights({
    required List<ConversationMessage> messages,
  }) async {
    if (messages.isEmpty) {
      return 'No conversation yet. Start talking to get insights!';
    }

    final context = _buildContext(messages, limit: 15);
    final query = '''$context

Based on this conversation between a traveler and a local, provide:

1. **Summary** (1-2 sentences): What they discussed
2. **Common Phrases** (3 phrases): Key phrases that were used
3. **Cultural Tip** (1 tip): One helpful cultural insight for the traveler

Format your response clearly with emoji bullets (📝, 💬, 🌍) and keep it concise and travel-friendly.''';

    return await sendQuery(query: query);
  }

  // AI Feature Option 4: Quick help for specific situations
  Future<String> getQuickHelp({
    required String situation,
    required String userLanguage,
    required String localLanguage,
  }) async {
    final query = '''I'm a $userLanguage speaker traveling and trying to communicate with a $localLanguage speaker.

Situation: $situation

Please provide:
1. A helpful phrase in $localLanguage (with simple pronunciation guide)
2. When/how to use it
3. Any cultural tips

Keep it practical, concise, and travel-focused (3-4 sentences max).''';

    return await sendQuery(query: query);
  }

  // Get contextual suggestions for current conversation
  Future<String> getSuggestions({
    required List<ConversationMessage> messages,
    required String userLanguage,
    required String localLanguage,
  }) async {
    final context = _buildContext(messages, limit: 5);
    final query = '''$context

Based on this conversation, suggest 3 helpful phrases the traveler might want to say next in $localLanguage.
Format: Just the phrases with simple English pronunciation, nothing else. Keep it super brief.''';

    return await sendQuery(query: query);
  }
}
