/// Type of transcript entry in the pipeline
enum TranscriptType {
  rawGloss, // Raw gloss words from hand sign detection
  polishedText, // Gemini-polished natural sentence
  sttText, // Speech-to-text output from lecturer audio
  translated, // Translated text in target language
}

/// Who produced this transcript entry
enum SpeakerRole {
  deafUser, // The deaf user performing hand signs
  lecturer, // The hearing person speaking
}

/// A single transcript entry stored at /transcripts/<sessionId>/<entryId>
/// Used for live captions and translation history
class TranscriptEntry {
  final String? entryId; // Firebase push key, null before saving
  final TranscriptType type;
  final String content;
  final String language;
  final int timestamp;
  final SpeakerRole speakerRole;

  TranscriptEntry({
    this.entryId,
    required this.type,
    required this.content,
    this.language = 'en',
    required this.timestamp,
    required this.speakerRole,
  });

  factory TranscriptEntry.fromJson(String entryId, Map<dynamic, dynamic> json) {
    return TranscriptEntry(
      entryId: entryId,
      type: _parseType(json['type'] as String? ?? 'raw_gloss'),
      content: json['content'] ?? '',
      language: json['language'] ?? 'en',
      timestamp: json['timestamp'] ?? 0,
      speakerRole: json['speakerRole'] == 'lecturer'
          ? SpeakerRole.lecturer
          : SpeakerRole.deafUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': _typeToString(type),
      'content': content,
      'language': language,
      'timestamp': timestamp,
      'speakerRole': speakerRole == SpeakerRole.lecturer
          ? 'lecturer'
          : 'deaf_user',
    };
  }

  static TranscriptType _parseType(String value) {
    switch (value) {
      case 'polished_text':
        return TranscriptType.polishedText;
      case 'stt_text':
        return TranscriptType.sttText;
      case 'translated':
        return TranscriptType.translated;
      case 'raw_gloss':
      default:
        return TranscriptType.rawGloss;
    }
  }

  static String _typeToString(TranscriptType type) {
    switch (type) {
      case TranscriptType.rawGloss:
        return 'raw_gloss';
      case TranscriptType.polishedText:
        return 'polished_text';
      case TranscriptType.sttText:
        return 'stt_text';
      case TranscriptType.translated:
        return 'translated';
    }
  }
}
