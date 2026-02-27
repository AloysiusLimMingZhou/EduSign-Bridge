import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

/// Service class for Firebase Cloud Storage operations.
/// Handles sign video and fingerspelling video retrieval.
class StorageService extends GetxService {
  final Logger _logger = Logger();
  late final FirebaseStorage _storage;

  @override
  void onInit() {
    super.onInit();
    _storage = FirebaseStorage.instance;
    _logger.i('StorageService initialized');
  }

  // ---------------------------------------------------------------------------
  // Download URLs
  // ---------------------------------------------------------------------------

  /// Get a download URL for a sign video by word.
  /// Path format: signs/<word>.mp4
  Future<String?> getSignVideoUrl(String word) async {
    try {
      final ref = _storage.ref('signs/${word.toLowerCase()}.mp4');
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      _logger.w('Sign video not found for "$word": ${e.code}');
      return null;
    }
  }

  /// Get a download URL for a fingerspelling video by letter.
  /// Path format: fingerspelling/<letter>.mp4
  Future<String?> getFingerspellingUrl(String letter) async {
    try {
      final ref = _storage.ref('fingerspelling/${letter.toLowerCase()}.mp4');
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      _logger.w('Fingerspelling video not found for "$letter": ${e.code}');
      return null;
    }
  }

  /// Get a download URL for a thumbnail.
  /// Path format: thumbnails/<word>.jpg
  Future<String?> getThumbnailUrl(String word) async {
    try {
      final ref = _storage.ref('thumbnails/${word.toLowerCase()}.jpg');
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      _logger.w('Thumbnail not found for "$word": ${e.code}');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Upload (Admin / Future Use)
  // ---------------------------------------------------------------------------

  /// Upload a sign video file. For admin or future recording features.
  Future<String?> uploadSignVideo(String word, File videoFile) async {
    try {
      final ref = _storage.ref('signs/${word.toLowerCase()}.mp4');
      final uploadTask = await ref.putFile(
        videoFile,
        SettableMetadata(contentType: 'video/mp4'),
      );
      final url = await uploadTask.ref.getDownloadURL();
      _logger.i('Uploaded sign video for "$word"');
      return url;
    } on FirebaseException catch (e) {
      _logger.e('Upload failed for "$word": ${e.code}');
      return null;
    }
  }

  /// List all available sign videos in the bucket.
  Future<List<String>> listAvailableSigns() async {
    try {
      final result = await _storage.ref('signs/').listAll();
      return result.items.map((ref) {
        // Remove .mp4 extension to get the word
        return ref.name.replaceAll('.mp4', '');
      }).toList();
    } on FirebaseException catch (e) {
      _logger.e('Failed to list signs: ${e.code}');
      return [];
    }
  }
}
