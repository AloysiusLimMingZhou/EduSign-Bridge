/// User profile stored at /users/<uid> in Realtime Database
class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String preferredLanguage;
  final int createdAt;
  final int lastActiveAt;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.preferredLanguage = 'en',
    required this.createdAt,
    required this.lastActiveAt,
  });

  /// Supported languages for translation
  static const List<String> supportedLanguages = [
    'en', // English
    'zh', // Chinese
    'ms', // Malay
    'ta', // Tamil
    'ja', // Japanese
    'ko', // Korean
    'it', // Italian
    'ru', // Russian
    'pl', // Polish
    'fr', // French
    'de', // German
    'es', // Spanish
  ];

  /// Human-readable language names
  static const Map<String, String> languageNames = {
    'en': 'English',
    'zh': 'Chinese',
    'ms': 'Malay',
    'ta': 'Tamil',
    'ja': 'Japanese',
    'ko': 'Korean',
    'it': 'Italian',
    'ru': 'Russian',
    'pl': 'Polish',
    'fr': 'French',
    'de': 'German',
    'es': 'Spanish',
  };

  factory UserProfile.fromJson(String uid, Map<dynamic, dynamic> json) {
    return UserProfile(
      uid: uid,
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'],
      preferredLanguage: json['preferredLanguage'] ?? 'en',
      createdAt: json['createdAt'] ?? 0,
      lastActiveAt: json['lastActiveAt'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'preferredLanguage': preferredLanguage,
      'createdAt': createdAt,
      'lastActiveAt': lastActiveAt,
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    String? preferredLanguage,
    int? lastActiveAt,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}
