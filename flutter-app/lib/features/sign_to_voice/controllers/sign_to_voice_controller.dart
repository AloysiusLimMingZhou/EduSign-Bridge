import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:ai_voice_to_hand_signs_project/data/services/database_service.dart';
import 'package:ai_voice_to_hand_signs_project/data/services/cloud_functions_service.dart';
import 'package:ai_voice_to_hand_signs_project/data/models/session.dart';
import 'package:ai_voice_to_hand_signs_project/data/models/transcript_entry.dart';
import 'package:ai_voice_to_hand_signs_project/data/models/emotion_data.dart';

/// Controller for Sign-to-Voice feature
/// Manages detection results from Native Camera and integrates with RTDB
class SignToVoiceController extends GetxController {
  final Logger _logger = Logger();
  final DatabaseService _dbService = Get.find<DatabaseService>();
  final CloudFunctionsService _cfService = Get.find<CloudFunctionsService>();

  // Observable state
  final RxBool isInitialized = true.obs;
  final RxBool isRecording = false.obs;
  final RxBool isProcessing = false.obs;
  final RxBool isSending = false.obs; // AI pipeline active
  final RxString currentWord = ''.obs;
  final RxDouble confidence = 0.0.obs;
  final RxList<String> detectedWords = <String>[].obs;
  final RxString errorMessage = ''.obs;
  final RxString aiSentence = ''.obs; // Gemini-polished sentence

  // Emotion detection state
  final Rx<EmotionData?> currentEmotion = Rx<EmotionData?>(null);
  final RxList<EmotionData> emotionHistory = <EmotionData>[].obs;

  // Session management
  String? _currentSessionId;
  String? get currentSessionId => _currentSessionId;

  // Audio player for TTS
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Debounce/Logic control
  DateTime? _lastWordTime;
  DateTime? _lastEmotionTime;
  static const wordDebounce = Duration(seconds: 1);
  static const emotionDebounce = Duration(seconds: 3);

  @override
  void onInit() {
    super.onInit();
    _logger.i('Sign-to-Voice controller initialized');
  }

  @override
  void onClose() {
    if (_currentSessionId != null && isRecording.value) {
      stopRecording();
    }
    _audioPlayer.dispose();
    super.onClose();
  }

  /// Start recording (listening to results) and create a session in RTDB
  Future<void> startRecording() async {
    detectedWords.clear();
    currentWord.value = '';
    emotionHistory.clear();
    currentEmotion.value = null;
    aiSentence.value = '';
    isRecording.value = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentSessionId = await _dbService.createSession(
          user.uid,
          SessionType.signToVoice,
        );
        _logger.i('Recording started - Session: $_currentSessionId');
      } else {
        _logger.w('Recording started without authenticated user');
      }
    } catch (e) {
      _logger.e('Failed to create session: $e');
      errorMessage.value = 'Failed to start session';
    }
  }

  /// Stop recording and end the session
  Future<void> stopRecording() async {
    isRecording.value = false;
    currentWord.value = '';

    try {
      if (_currentSessionId != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _dbService.endSession(user.uid, _currentSessionId!);
          _logger.i('Recording stopped - Session ended: $_currentSessionId');
        }
        _currentSessionId = null;
      }
    } catch (e) {
      _logger.e('Failed to end session: $e');
    }
  }

  /// Handle sign detection result from Native Camera
  void onResult(String label, double score) {
    if (!isRecording.value) return;

    currentWord.value = label;
    confidence.value = score;
    isProcessing.value = true;

    // if (score > 0.6) { // Removed threshold
    final now = DateTime.now();

    // We want to allow the user to spell words with double letters (e.g., L-L in HELLO).
    // If it's a new word/letter, we use a quick debounce.
    // If it's the SAME word/letter, we require a slightly longer hold or drop-re-raise before registering it again.

    final bool isNewWord = detectedWords.isEmpty || detectedWords.last != label;
    final Duration requiredDebounce = isNewWord
        ? wordDebounce
        : const Duration(milliseconds: 1500);

    if (_lastWordTime == null ||
        now.difference(_lastWordTime!) > requiredDebounce) {
      detectedWords.add(label);
      _lastWordTime = now;
      _logger.i('Detected: $label (${(score * 100).toStringAsFixed(1)}%)');

      _saveDetectedWord(label, score);
    }
    // }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!isClosed) isProcessing.value = false;
    });
  }

  /// Handle emotion detection result from Native Camera
  void onEmotionDetected(String emotionLabel, double conf) {
    if (!isRecording.value) return;

    final now = DateTime.now();

    if (_lastEmotionTime == null ||
        now.difference(_lastEmotionTime!) > emotionDebounce) {
      final emotionType = _parseEmotionType(emotionLabel);
      final emotionData = EmotionData(
        emotion: emotionType,
        confidence: conf,
        timestamp: now.millisecondsSinceEpoch,
      );

      currentEmotion.value = emotionData;
      emotionHistory.add(emotionData);
      _lastEmotionTime = now;

      _logger.i(
        'Emotion detected: ${emotionData.label} (${(conf * 100).toStringAsFixed(1)}%)',
      );

      _saveEmotionData(emotionData);
    }
  }

  EmotionType _parseEmotionType(String label) {
    switch (label.toLowerCase()) {
      case 'happy':
        return EmotionType.happy;
      case 'angry':
        return EmotionType.angry;
      case 'down':
      case 'sad':
        return EmotionType.down;
      case 'confused':
        return EmotionType.confused;
      case 'questioning':
        return EmotionType.questioning;
      default:
        return EmotionType.neutral;
    }
  }

  /// Send detected signs + emotion to AI pipeline
  /// 1. glossToSentence (Gemini) — converts gloss words to natural sentence
  /// 2. textToSpeech (Vertex TTS) — generates emotion-toned audio
  /// 3. Play audio
  Future<void> sendToAI() async {
    if (detectedWords.isEmpty) return;
    if (isSending.value) return;

    isSending.value = true;
    final emotion = getDominantEmotion()?.name ?? 'neutral';

    try {
      // Step 1: Convert gloss to natural sentence with emotion context
      _logger.i(
        'Sending to Gemini: ${detectedWords.join(" ")} [emotion: $emotion]',
      );
      final sentence = await _cfService.glossToSentence(
        detectedWords.toList(),
        lang: 'en',
        emotion: emotion,
      );
      aiSentence.value = sentence;
      _logger.i('Gemini response: "$sentence"');

      // Save polished sentence to RTDB
      if (_currentSessionId != null) {
        final entry = TranscriptEntry(
          type: TranscriptType.polishedText,
          content: sentence,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          speakerRole: SpeakerRole.deafUser,
        );
        await _dbService.addTranscriptEntry(_currentSessionId!, entry);
      }

      // Step 2: Text to Speech with emotion tone
      _logger.i('Generating TTS with emotion: $emotion');
      final audioBase64 = await _cfService.textToSpeech(
        sentence,
        lang: 'en',
        emotion: emotion,
      );

      // Step 3: Play the audio
      if (audioBase64.isNotEmpty) {
        final bytes = base64Decode(audioBase64);
        await _audioPlayer.play(BytesSource(Uint8List.fromList(bytes)));
        _logger.i('Playing TTS audio (${bytes.length} bytes)');
      }

      Get.snackbar(
        '🗣️ Speaking',
        '$sentence ${currentEmotion.value?.emoji ?? ""}',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      _logger.e('AI pipeline error: $e');
      Get.snackbar(
        'Error',
        'Failed to process: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSending.value = false;
    }
  }

  /// Save detected word to RTDB as transcript entry
  Future<void> _saveDetectedWord(String word, double confidence) async {
    if (_currentSessionId == null) return;

    try {
      final emotionTag = currentEmotion.value != null
          ? ' [${currentEmotion.value!.label}]'
          : '';

      final entry = TranscriptEntry(
        type: TranscriptType.rawGloss,
        content: '$word$emotionTag',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        speakerRole: SpeakerRole.deafUser,
      );

      await _dbService.addTranscriptEntry(_currentSessionId!, entry);
      _logger.d('Saved word to RTDB: $word$emotionTag');
    } catch (e) {
      _logger.e('Failed to save word to RTDB: $e');
    }
  }

  /// Save emotion data to RTDB as transcript entry
  Future<void> _saveEmotionData(EmotionData emotionData) async {
    if (_currentSessionId == null) return;

    try {
      final entry = TranscriptEntry(
        type: TranscriptType.rawGloss,
        content:
            'Emotion: ${emotionData.label} ${emotionData.emoji} (${(emotionData.confidence * 100).toStringAsFixed(0)}%)',
        timestamp: emotionData.timestamp,
        speakerRole: SpeakerRole.deafUser,
      );

      await _dbService.addTranscriptEntry(_currentSessionId!, entry);
      _logger.d('Saved emotion to RTDB: ${emotionData.label}');
    } catch (e) {
      _logger.e('Failed to save emotion to RTDB: $e');
    }
  }

  /// Clear detected words and emotion history
  void clearWords() {
    detectedWords.clear();
    currentWord.value = '';
    confidence.value = 0.0;
    emotionHistory.clear();
    currentEmotion.value = null;
    aiSentence.value = '';
  }

  /// Get sentence from detected words
  String getSentence() {
    return detectedWords.join(' ');
  }

  /// Get dominant emotion from history
  EmotionType? getDominantEmotion() {
    if (emotionHistory.isEmpty) return null;

    final counts = <EmotionType, int>{};
    for (final emotion in emotionHistory) {
      counts[emotion.emotion] = (counts[emotion.emotion] ?? 0) + 1;
    }

    EmotionType? dominant;
    int maxCount = 0;
    counts.forEach((emotion, count) {
      if (count > maxCount) {
        maxCount = count;
        dominant = emotion;
      }
    });

    return dominant;
  }

  /// Get average confidence of detected emotions
  double getAverageEmotionConfidence() {
    if (emotionHistory.isEmpty) return 0.0;

    final sum = emotionHistory.fold<double>(
      0.0,
      (sum, emotion) => sum + emotion.confidence,
    );

    return sum / emotionHistory.length;
  }
}
