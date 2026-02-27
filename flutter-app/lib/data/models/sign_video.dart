/// A sign video entry stored at /signVideoCatalog/<word> or /fingerspelling/<letter>
class SignVideo {
  final String word; // The word or letter this video represents
  final String videoUrl; // Cloud Storage path (gs://) or download URL
  final String? thumbnailUrl;
  final double duration; // Duration in seconds
  final int? addedAt;

  SignVideo({
    required this.word,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.duration,
    this.addedAt,
  });

  factory SignVideo.fromJson(String word, Map<dynamic, dynamic> json) {
    return SignVideo(
      word: word,
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      duration: (json['duration'] ?? 0).toDouble(),
      addedAt: json['addedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      if (addedAt != null) 'addedAt': addedAt,
    };
  }
}
