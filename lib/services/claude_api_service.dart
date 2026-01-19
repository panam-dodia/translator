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
  String _buildContext(List<ConversationMessage> messages) {
    if (messages.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('Recent conversation context:');
    buffer.writeln();

    for (var message in messages) {
      final userName = message.userId == 'user1' ? 'User 1' : 'User 2';
      final language = message.sourceLanguage;
      buffer.writeln('$userName ($language): "${message.originalText}"');
      buffer.writeln('Translation: "${message.translatedText}"');
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
}
