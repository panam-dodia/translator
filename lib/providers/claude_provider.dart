import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/claude_query.dart';
import '../models/conversation_message.dart';
import '../services/claude_api_service.dart';

class ClaudeProvider extends ChangeNotifier {
  final ClaudeAPIService _claudeService = ClaudeAPIService();
  final List<ClaudeQuery> _queries = [];
  final _uuid = const Uuid();

  bool _isEnabled = true;
  String? _error;

  // Getters
  List<ClaudeQuery> get queries => List.unmodifiable(_queries);
  bool get isEnabled => _isEnabled;
  String? get error => _error;
  bool get hasActiveQuery => _queries.any((q) => q.isLoading);

  // Get latest query
  ClaudeQuery? get latestQuery =>
      _queries.isNotEmpty ? _queries.last : null;

  // Enable/disable Claude assistant
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    notifyListeners();
  }

  // Send query to Claude
  Future<ClaudeQuery> sendQuery({
    required String queryText,
    List<ConversationMessage>? contextMessages,
  }) async {
    if (!_isEnabled) {
      throw Exception('Claude assistant is disabled');
    }

    // Create query object
    final query = ClaudeQuery(
      id: _uuid.v4(),
      query: queryText,
      timestamp: DateTime.now(),
      isLoading: true,
      contextMessageIds: contextMessages?.map((m) => m.id).toList() ?? [],
    );

    _queries.add(query);
    _error = null;
    notifyListeners();

    try {
      // Send request to Claude API
      final response = await _claudeService.sendQuery(
        query: queryText,
        contextMessages: contextMessages,
      );

      // Update query with response
      final updatedQuery = query.copyWith(
        response: response,
        isLoading: false,
      );

      _updateQuery(query.id, updatedQuery);

      return updatedQuery;
    } catch (e) {
      // Update query with error
      final errorQuery = query.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      _updateQuery(query.id, errorQuery);
      _setError(e.toString());

      rethrow;
    }
  }

  // Update query in list
  void _updateQuery(String queryId, ClaudeQuery updatedQuery) {
    final index = _queries.indexWhere((q) => q.id == queryId);
    if (index != -1) {
      _queries[index] = updatedQuery;
      notifyListeners();
    }
  }

  // Clear all queries
  void clearQueries() {
    _queries.clear();
    _error = null;
    notifyListeners();
  }

  // Remove specific query
  void removeQuery(String queryId) {
    _queries.removeWhere((q) => q.id == queryId);
    notifyListeners();
  }

  // Test API connection
  Future<bool> testConnection() async {
    try {
      return await _claudeService.testConnection();
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Set error
  void _setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
