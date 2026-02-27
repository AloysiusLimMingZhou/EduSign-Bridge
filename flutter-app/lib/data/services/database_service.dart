import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:ai_voice_to_hand_signs_project/data/models/user_profile.dart';
import 'package:ai_voice_to_hand_signs_project/data/models/session.dart';
import 'package:ai_voice_to_hand_signs_project/data/models/transcript_entry.dart';
import 'package:ai_voice_to_hand_signs_project/data/models/sign_video.dart';

/// Service class for all Firebase Realtime Database operations.
/// Register via Get.put(DatabaseService()) in main.dart.
class DatabaseService extends GetxService {
  final Logger _logger = Logger();
  late final DatabaseReference _db;

  @override
  void onInit() {
    super.onInit();
    // Must specify the regional URL for non-US databases (Singapore = asia-southeast1)
    _db = FirebaseDatabase.instanceFor(
      app: FirebaseDatabase.instance.app,
      databaseURL:
          'https://ai-real-time-voice-to-sign-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref();
    _logger.i('DatabaseService initialized (asia-southeast1)');
  }

  // ---------------------------------------------------------------------------
  // User Profile
  // ---------------------------------------------------------------------------

  /// Create or update user profile on login.
  /// Call this after successful authentication.
  Future<void> saveUserProfile(User firebaseUser) async {
    final uid = firebaseUser.uid;
    final ref = _db.child('users/$uid');

    // Check if profile already exists
    final snapshot = await ref.get();
    if (snapshot.exists) {
      // Just update lastActiveAt
      await ref.update({
        'lastActiveAt': ServerValue.timestamp,
        // Update display name / photo in case they changed
        'displayName': firebaseUser.displayName ?? '',
        'photoUrl': firebaseUser.photoURL,
      });
      _logger.i('Updated lastActiveAt for user $uid');
    } else {
      // Create new profile
      final profile = UserProfile(
        uid: uid,
        displayName: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
        preferredLanguage: 'en',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        lastActiveAt: DateTime.now().millisecondsSinceEpoch,
      );
      await ref.set(profile.toJson());
      _logger.i('Created new profile for user $uid');
    }
  }

  /// Get user profile
  Future<UserProfile?> getUserProfile(String uid) async {
    final snapshot = await _db.child('users/$uid').get();
    if (!snapshot.exists || snapshot.value == null) return null;
    return UserProfile.fromJson(uid, snapshot.value as Map<dynamic, dynamic>);
  }

  /// Update preferred language
  Future<void> updatePreferredLanguage(String uid, String languageCode) async {
    await _db.child('users/$uid').update({'preferredLanguage': languageCode});
    _logger.i('Updated preferred language to $languageCode for user $uid');
  }

  // ---------------------------------------------------------------------------
  // Sessions
  // ---------------------------------------------------------------------------

  /// Create a new recording session. Returns the generated session ID.
  Future<String> createSession(
    String uid,
    SessionType type, {
    String language = 'en',
  }) async {
    final ref = _db.child('sessions/$uid').push();
    final session = Session(
      sessionId: ref.key!,
      type: type,
      status: SessionStatus.active,
      language: language,
      startedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await ref.set(session.toJson());
    _logger.i('Created session ${ref.key} for user $uid');
    return ref.key!;
  }

  /// End a session (set status=completed and endedAt timestamp)
  Future<void> endSession(String uid, String sessionId) async {
    await _db.child('sessions/$uid/$sessionId').update({
      'status': 'completed',
      'endedAt': ServerValue.timestamp,
    });
    _logger.i('Ended session $sessionId');
  }

  /// Get all sessions for a user
  Future<List<Session>> getUserSessions(String uid) async {
    final snapshot = await _db.child('sessions/$uid').get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final map = snapshot.value as Map<dynamic, dynamic>;
    return map.entries
        .map(
          (e) => Session.fromJson(
            e.key as String,
            e.value as Map<dynamic, dynamic>,
          ),
        )
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt)); // newest first
  }

  // ---------------------------------------------------------------------------
  // Transcripts (Live Captions)
  // ---------------------------------------------------------------------------

  /// Add a transcript entry to a session. Returns the entry ID.
  Future<String> addTranscriptEntry(
    String sessionId,
    TranscriptEntry entry,
  ) async {
    final ref = _db.child('transcripts/$sessionId').push();
    await ref.set(entry.toJson());
    _logger.d('Added transcript entry to session $sessionId');
    return ref.key!;
  }

  /// Stream transcript entries in real-time for live captions.
  /// Emits the full list of entries every time a new one is added.
  Stream<List<TranscriptEntry>> streamTranscripts(String sessionId) {
    final ref = _db.child('transcripts/$sessionId').orderByChild('timestamp');
    return ref.onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];

      final map = event.snapshot.value as Map<dynamic, dynamic>;
      return map.entries
          .map(
            (e) => TranscriptEntry.fromJson(
              e.key as String,
              e.value as Map<dynamic, dynamic>,
            ),
          )
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp)); // chronological
    });
  }

  /// Stream only new transcript entries added after subscribing (for live captions).
  Stream<TranscriptEntry> streamNewTranscripts(String sessionId) {
    final ref = _db.child('transcripts/$sessionId');
    return ref.onChildAdded.map((event) {
      return TranscriptEntry.fromJson(
        event.snapshot.key!,
        event.snapshot.value as Map<dynamic, dynamic>,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Sign Video Catalog
  // ---------------------------------------------------------------------------

  /// Characters not allowed in Firebase RTDB keys.
  static final RegExp _invalidKeyChars = RegExp(r'[.\$#\[\]/]');

  /// Sanitize a string to be safe as an RTDB path segment
  /// by stripping characters that RTDB forbids (. $ # [ ] /).
  String _sanitizeRtdbKey(String key) {
    return key.replaceAll(_invalidKeyChars, '').trim();
  }

  /// Convert a gs:// URL to a playable HTTPS download URL.
  /// If the URL is already an HTTPS URL, returns it unchanged.
  Future<String> _resolveVideoUrl(String url) async {
    if (!url.startsWith('gs://')) return url;
    try {
      final ref = FirebaseStorage.instance.refFromURL(url);
      return await ref.getDownloadURL();
    } catch (e) {
      _logger.e('Failed to resolve gs:// URL: $e');
      return url; // Return as-is; playback will likely fail but won't crash
    }
  }

  /// Look up a sign video by word. Returns null if not found.
  /// Tries RTDB first, then falls back to Cloud Storage direct lookup.
  Future<SignVideo?> lookupSignVideo(String word) async {
    final normalizedWord = word.toLowerCase().trim();
    final rtdbKey = _sanitizeRtdbKey(normalizedWord);

    if (rtdbKey.isEmpty) {
      _logger.w('Empty RTDB key after sanitization for: "$normalizedWord"');
      return null;
    }

    // 1. Try RTDB lookup
    try {
      final snapshot = await _db.child('signVideoCatalog/$rtdbKey').get();

      if (snapshot.exists && snapshot.value != null) {
        final value = snapshot.value;
        SignVideo? video;

        if (value is Map) {
          video = SignVideo.fromJson(rtdbKey, value as Map<dynamic, dynamic>);
        } else if (value is String) {
          video = SignVideo(word: rtdbKey, videoUrl: value, duration: 3.0);
        }

        if (video != null) {
          // Resolve gs:// to a playable download URL
          final resolvedUrl = await _resolveVideoUrl(video.videoUrl);
          _logger.i('Found sign video in RTDB for "$rtdbKey"');
          return SignVideo(
            word: video.word,
            videoUrl: resolvedUrl,
            thumbnailUrl: video.thumbnailUrl,
            duration: video.duration,
            addedAt: video.addedAt,
          );
        }
      }
    } catch (e) {
      _logger.e('Error looking up sign video in RTDB for "$rtdbKey": $e');
    }

    // 2. Fallback: try Cloud Storage directly at sign_videos/<word>.mp4
    try {
      final ref = FirebaseStorage.instance.ref(
        'sign_videos/$normalizedWord.mp4',
      );
      final downloadUrl = await ref.getDownloadURL();
      _logger.i('Found sign video in Storage for "$normalizedWord"');
      return SignVideo(
        word: normalizedWord,
        videoUrl: downloadUrl,
        duration: 3.0,
      );
    } on FirebaseException catch (_) {
      // Not found in Storage either — that's fine
    } catch (e) {
      _logger.e('Error looking up Storage for "$normalizedWord": $e');
    }

    return null;
  }

  /// Look up a fingerspelling video by letter.
  Future<SignVideo?> lookupFingerspelling(String letter) async {
    final normalizedLetter = letter.toLowerCase().trim();
    final rtdbKey = _sanitizeRtdbKey(normalizedLetter);

    if (rtdbKey.isEmpty) return null; // Skip punctuation, spaces, etc.

    try {
      final snapshot = await _db.child('fingerspelling/$rtdbKey').get();
      if (!snapshot.exists || snapshot.value == null) return null;

      final value = snapshot.value;
      SignVideo? video;

      if (value is Map) {
        video = SignVideo.fromJson(rtdbKey, value as Map<dynamic, dynamic>);
      } else if (value is String) {
        video = SignVideo(word: rtdbKey, videoUrl: value, duration: 1.0);
      }

      if (video != null) {
        final resolvedUrl = await _resolveVideoUrl(video.videoUrl);
        return SignVideo(
          word: video.word,
          videoUrl: resolvedUrl,
          thumbnailUrl: video.thumbnailUrl,
          duration: video.duration,
          addedAt: video.addedAt,
        );
      }
    } catch (e) {
      _logger.e('Error looking up fingerspelling for "$rtdbKey": $e');
    }
    return null;
  }

  /// Look up sign videos for a list of gloss words.
  /// For each word: returns the sign video if available, otherwise returns
  /// fingerspelling videos for each letter.
  Future<List<SignVideo>> lookupGlossSequence(List<String> glossWords) async {
    final List<SignVideo> result = [];

    for (final word in glossWords) {
      final signVideo = await lookupSignVideo(word);
      if (signVideo != null) {
        // Full sign video exists
        result.add(signVideo);
      } else {
        // Fallback to fingerspelling — only query alphabetic characters
        for (final letter in word.split('')) {
          if (!RegExp(r'[a-zA-Z]').hasMatch(letter)) continue;
          final fingerVideo = await lookupFingerspelling(letter);
          if (fingerVideo != null) {
            result.add(fingerVideo);
          }
        }
      }
    }

    return result;
  }

  /// Fetch sign videos directly from Cloud Storage paths, bypassing RTDB.
  /// Used for hardcoded test videos.
  /// [storagePaths] — e.g. ['sign_videos/class today, we learn math.mp4']
  Future<List<SignVideo>> lookupStorageDirect(List<String> storagePaths) async {
    final List<SignVideo> result = [];

    for (final path in storagePaths) {
      try {
        final ref = FirebaseStorage.instance.ref(path);
        final downloadUrl = await ref.getDownloadURL();

        // Derive a display label from the filename (strip folder + extension)
        final fileName = path.split('/').last;
        final word = fileName.contains('.')
            ? fileName.substring(0, fileName.lastIndexOf('.'))
            : fileName;

        _logger.i('lookupStorageDirect: resolved "$path"');
        result.add(SignVideo(word: word, videoUrl: downloadUrl, duration: 3.0));
      } on FirebaseException catch (e) {
        _logger.e('lookupStorageDirect: not found "$path" (${e.code})');
      } catch (e) {
        _logger.e('lookupStorageDirect: error for "$path": $e');
      }
    }

    return result;
  }
}
