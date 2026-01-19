class ConversationMessage {
  final String id;
  final String originalText;
  final String translatedText;
  final String userId; // 'user1' or 'user2'
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime timestamp;

  ConversationMessage({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.userId,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalText': originalText,
      'translatedText': translatedText,
      'userId': userId,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'] as String,
      originalText: json['originalText'] as String,
      translatedText: json['translatedText'] as String,
      userId: json['userId'] as String,
      sourceLanguage: json['sourceLanguage'] as String,
      targetLanguage: json['targetLanguage'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  ConversationMessage copyWith({
    String? id,
    String? originalText,
    String? translatedText,
    String? userId,
    String? sourceLanguage,
    String? targetLanguage,
    DateTime? timestamp,
  }) {
    return ConversationMessage(
      id: id ?? this.id,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      userId: userId ?? this.userId,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
