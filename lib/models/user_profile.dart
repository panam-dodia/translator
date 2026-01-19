class UserProfile {
  final String userId;
  final String languageCode;
  final String? preferredVoice;
  final double speechRate;
  final double pitch;

  UserProfile({
    required this.userId,
    required this.languageCode,
    this.preferredVoice,
    this.speechRate = 0.5,
    this.pitch = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'languageCode': languageCode,
      'preferredVoice': preferredVoice,
      'speechRate': speechRate,
      'pitch': pitch,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String,
      languageCode: json['languageCode'] as String,
      preferredVoice: json['preferredVoice'] as String?,
      speechRate: (json['speechRate'] as num?)?.toDouble() ?? 0.5,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
    );
  }

  UserProfile copyWith({
    String? userId,
    String? languageCode,
    String? preferredVoice,
    double? speechRate,
    double? pitch,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      languageCode: languageCode ?? this.languageCode,
      preferredVoice: preferredVoice ?? this.preferredVoice,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
    );
  }
}
