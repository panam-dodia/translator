import 'conversation_message.dart';

class ConversationSession {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime lastUpdated;
  final List<ConversationMessage> messages;
  final String user1Language;
  final String user2Language;

  ConversationSession({
    required this.id,
    required this.title,
    required this.startTime,
    required this.lastUpdated,
    required this.messages,
    required this.user1Language,
    required this.user2Language,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'user1Language': user1Language,
      'user2Language': user2Language,
    };
  }

  factory ConversationSession.fromJson(Map<String, dynamic> json) {
    return ConversationSession(
      id: json['id'] as String,
      title: json['title'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      messages: (json['messages'] as List)
          .map((m) => ConversationMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      user1Language: json['user1Language'] as String,
      user2Language: json['user2Language'] as String,
    );
  }

  ConversationSession copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? lastUpdated,
    List<ConversationMessage>? messages,
    String? user1Language,
    String? user2Language,
  }) {
    return ConversationSession(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      messages: messages ?? this.messages,
      user1Language: user1Language ?? this.user1Language,
      user2Language: user2Language ?? this.user2Language,
    );
  }

  // Get a summary of the conversation
  String getSummary() {
    if (messages.isEmpty) return 'No messages';
    if (messages.length == 1) return messages.first.originalText;

    final firstMessage = messages.first.originalText;
    return firstMessage.length > 50
        ? '${firstMessage.substring(0, 50)}...'
        : firstMessage;
  }

  // Get message count
  int get messageCount => messages.length;
}
