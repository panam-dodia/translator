import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/conversation_message.dart';
import '../models/user_profile.dart';
import '../utils/constants.dart';

class ConversationProvider extends ChangeNotifier {
  final List<ConversationMessage> _messages = [];
  String _activeUserId = AppConstants.user1Id;
  bool _isProcessing = false;
  UserProfile? _user1Profile;
  UserProfile? _user2Profile;

  final _uuid = const Uuid();

  // Getters
  List<ConversationMessage> get messages => List.unmodifiable(_messages);
  String get activeUserId => _activeUserId;
  bool get isProcessing => _isProcessing;
  UserProfile? get user1Profile => _user1Profile;
  UserProfile? get user2Profile => _user2Profile;

  // Get messages for specific user (their view)
  List<ConversationMessage> getMessagesForUser(String userId) {
    return _messages.where((msg) {
      // Show all messages, but the user will see their original and others' translations
      return true;
    }).toList();
  }

  // Get the other user's ID
  String getOtherUserId(String userId) {
    return userId == AppConstants.user1Id
        ? AppConstants.user2Id
        : AppConstants.user1Id;
  }

  // Set user profiles
  void setUserProfiles(UserProfile user1, UserProfile user2) {
    _user1Profile = user1;
    _user2Profile = user2;
    notifyListeners();
  }

  // Update user profile
  void updateUserProfile(UserProfile profile) {
    if (profile.userId == AppConstants.user1Id) {
      _user1Profile = profile;
    } else {
      _user2Profile = profile;
    }
    notifyListeners();
  }

  // Get profile for user
  UserProfile? getProfileForUser(String userId) {
    return userId == AppConstants.user1Id ? _user1Profile : _user2Profile;
  }

  // Switch active user
  void switchActiveUser() {
    _activeUserId = getOtherUserId(_activeUserId);
    notifyListeners();
  }

  // Set active user
  void setActiveUser(String userId) {
    _activeUserId = userId;
    notifyListeners();
  }

  // Add message to conversation
  void addMessage(ConversationMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  // Create and add message
  ConversationMessage createMessage({
    required String originalText,
    required String translatedText,
    required String userId,
    required String sourceLanguage,
    required String targetLanguage,
  }) {
    final message = ConversationMessage(
      id: _uuid.v4(),
      originalText: originalText,
      translatedText: translatedText,
      userId: userId,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      timestamp: DateTime.now(),
    );

    addMessage(message);
    return message;
  }

  // Set processing state
  void setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  // Clear conversation history
  void clearHistory() {
    _messages.clear();
    notifyListeners();
  }

  // Get recent messages for Claude context
  List<ConversationMessage> getRecentMessages({int limit = 20}) {
    if (_messages.length <= limit) {
      return List.from(_messages);
    }
    return _messages.sublist(_messages.length - limit);
  }

  // Get message count
  int get messageCount => _messages.length;
}
