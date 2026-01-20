import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/conversation_session.dart';
import '../models/conversation_message.dart';

class HistoryProvider extends ChangeNotifier {
  final List<ConversationSession> _sessions = [];
  final _uuid = const Uuid();
  static const String _storageKey = 'conversation_sessions';

  List<ConversationSession> get sessions => List.unmodifiable(_sessions);

  // Load sessions from storage
  Future<void> loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString(_storageKey);

      if (sessionsJson != null) {
        final List<dynamic> decoded = jsonDecode(sessionsJson);
        _sessions.clear();
        _sessions.addAll(
          decoded.map((json) => ConversationSession.fromJson(json)).toList(),
        );
        // Sort by last updated (most recent first)
        _sessions.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
        notifyListeners();
      }
    } catch (e) {
      print('Error loading sessions: $e');
    }
  }

  // Save sessions to storage
  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = jsonEncode(
        _sessions.map((session) => session.toJson()).toList(),
      );
      await prefs.setString(_storageKey, sessionsJson);
    } catch (e) {
      print('Error saving sessions: $e');
    }
  }

  // Create a new session from current conversation
  Future<ConversationSession> saveCurrentConversation({
    required List<ConversationMessage> messages,
    required String user1Language,
    required String user2Language,
    String? customTitle,
  }) async {
    if (messages.isEmpty) {
      throw Exception('Cannot save empty conversation');
    }

    // Generate title from first message or use custom title
    final title = customTitle ??
        _generateTitle(messages.first.originalText, user1Language, user2Language);

    final session = ConversationSession(
      id: _uuid.v4(),
      title: title,
      startTime: messages.first.timestamp,
      lastUpdated: DateTime.now(),
      messages: List.from(messages),
      user1Language: user1Language,
      user2Language: user2Language,
    );

    _sessions.insert(0, session); // Add at beginning (most recent first)
    await _saveSessions();
    notifyListeners();

    return session;
  }

  // Generate a title from the first message
  String _generateTitle(String firstMessage, String lang1, String lang2) {
    final cleanMessage = firstMessage.trim();
    final preview = cleanMessage.length > 30
        ? '${cleanMessage.substring(0, 30)}...'
        : cleanMessage;
    return '$lang1-$lang2: $preview';
  }

  // Update session title
  Future<void> updateSessionTitle(String sessionId, String newTitle) async {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      _sessions[index] = _sessions[index].copyWith(
        title: newTitle,
        lastUpdated: DateTime.now(),
      );
      await _saveSessions();
      notifyListeners();
    }
  }

  // Delete session
  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    await _saveSessions();
    notifyListeners();
  }

  // Clear all sessions
  Future<void> clearAllSessions() async {
    _sessions.clear();
    await _saveSessions();
    notifyListeners();
  }

  // Get session by ID
  ConversationSession? getSession(String sessionId) {
    try {
      return _sessions.firstWhere((s) => s.id == sessionId);
    } catch (e) {
      return null;
    }
  }

  // Get all messages from all sessions (for chat context)
  List<ConversationMessage> getAllMessages() {
    final allMessages = <ConversationMessage>[];
    for (var session in _sessions) {
      allMessages.addAll(session.messages);
    }
    // Sort by timestamp
    allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return allMessages;
  }

  // Search sessions by text
  List<ConversationSession> searchSessions(String query) {
    if (query.isEmpty) return sessions;

    final lowerQuery = query.toLowerCase();
    return _sessions.where((session) {
      // Search in title
      if (session.title.toLowerCase().contains(lowerQuery)) return true;

      // Search in messages
      return session.messages.any((message) =>
          message.originalText.toLowerCase().contains(lowerQuery) ||
          message.translatedText.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}
