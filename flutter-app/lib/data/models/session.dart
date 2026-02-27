/// Session types for the bidirectional translator
enum SessionType {
  signToVoice, // Deaf user → hand signs → text/speech
  voiceToSign, // Lecturer speech → text → hand sign videos
}

/// Session status
enum SessionStatus { active, completed }

/// Recording session stored at /sessions/<uid>/<sessionId>
class Session {
  final String sessionId;
  final SessionType type;
  final SessionStatus status;
  final String language;
  final int startedAt;
  final int? endedAt;

  Session({
    required this.sessionId,
    required this.type,
    this.status = SessionStatus.active,
    this.language = 'en',
    required this.startedAt,
    this.endedAt,
  });

  factory Session.fromJson(String sessionId, Map<dynamic, dynamic> json) {
    return Session(
      sessionId: sessionId,
      type: json['type'] == 'sign_to_voice'
          ? SessionType.signToVoice
          : SessionType.voiceToSign,
      status: json['status'] == 'completed'
          ? SessionStatus.completed
          : SessionStatus.active,
      language: json['language'] ?? 'en',
      startedAt: json['startedAt'] ?? 0,
      endedAt: json['endedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type == SessionType.signToVoice
          ? 'sign_to_voice'
          : 'voice_to_sign',
      'status': status == SessionStatus.completed ? 'completed' : 'active',
      'language': language,
      'startedAt': startedAt,
      'endedAt': endedAt,
    };
  }
}
