class ClaudeQuery {
  final String id;
  final String query;
  final String? response;
  final List<String> contextMessageIds;
  final DateTime timestamp;
  final bool isLoading;
  final String? error;

  ClaudeQuery({
    required this.id,
    required this.query,
    this.response,
    this.contextMessageIds = const [],
    required this.timestamp,
    this.isLoading = false,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'query': query,
      'response': response,
      'contextMessageIds': contextMessageIds,
      'timestamp': timestamp.toIso8601String(),
      'isLoading': isLoading,
      'error': error,
    };
  }

  factory ClaudeQuery.fromJson(Map<String, dynamic> json) {
    return ClaudeQuery(
      id: json['id'] as String,
      query: json['query'] as String,
      response: json['response'] as String?,
      contextMessageIds: (json['contextMessageIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      timestamp: DateTime.parse(json['timestamp'] as String),
      isLoading: json['isLoading'] as bool? ?? false,
      error: json['error'] as String?,
    );
  }

  ClaudeQuery copyWith({
    String? id,
    String? query,
    String? response,
    List<String>? contextMessageIds,
    DateTime? timestamp,
    bool? isLoading,
    String? error,
  }) {
    return ClaudeQuery(
      id: id ?? this.id,
      query: query ?? this.query,
      response: response ?? this.response,
      contextMessageIds: contextMessageIds ?? this.contextMessageIds,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
