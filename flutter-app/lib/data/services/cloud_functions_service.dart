import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:ai_voice_to_hand_signs_project/data/models/sign_video.dart';

/// Service class for calling Firebase Cloud Functions.
/// Register via Get.put(CloudFunctionsService()) in main.dart.
class CloudFunctionsService extends GetxService {
  final Logger _logger = Logger();
  late final FirebaseFunctions _functions;

  // Cloud Functions region — must match the deployed region
  static const String _region = 'asia-southeast1';

  @override
  void onInit() {
    super.onInit();
    _functions = FirebaseFunctions.instanceFor(region: _region);
    _logger.i('CloudFunctionsService initialized (region: $_region)');
  }

  // ---------------------------------------------------------------------------
  // AI — Gemini Translation
  // ---------------------------------------------------------------------------

  /// Convert gloss words to a natural sentence using Gemini.
  /// Example: ["HELLO", "HOW", "YOU"] → "Hello, how are you?"
  Future<String> glossToSentence(
    List<String> glossWords, {
    String lang = 'en',
    String? emotion,
  }) async {
    try {
      final callable = _functions.httpsCallable('glossToSentence');
      final result = await callable.call<Map<String, dynamic>>({
        'glossWords': glossWords,
        'lang': lang,
        if (emotion != null) 'emotion': emotion,
      });
      final sentence = result.data['sentence'] as String? ?? '';
      _logger.i('glossToSentence: ${glossWords.join(" ")} → "$sentence"');
      return sentence;
    } on FirebaseFunctionsException catch (e) {
      _logger.e('glossToSentence error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Convert a natural sentence to gloss words using Gemini.
  /// Example: "How are you doing today?" → ["HOW", "YOU", "TODAY"]
  Future<List<String>> sentenceToGloss(
    String sentence, {
    String lang = 'en',
  }) async {
    try {
      final callable = _functions.httpsCallable('sentenceToGloss');
      final result = await callable.call<Map<String, dynamic>>({
        'sentence': sentence,
        'lang': lang,
      });
      final glossWords = List<String>.from(result.data['glossWords'] ?? []);
      _logger.i('sentenceToGloss: "$sentence" → [${glossWords.join(", ")}]');
      return glossWords;
    } on FirebaseFunctionsException catch (e) {
      _logger.e('sentenceToGloss error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Sign Video Lookup
  // ---------------------------------------------------------------------------

  /// Look up sign videos for gloss words. Returns video URLs with
  /// fingerspelling fallback for unknown words.
  Future<List<SignVideo>> lookupSignVideos(List<String> glossWords) async {
    try {
      final callable = _functions.httpsCallable('lookupSignVideos');
      final result = await callable.call<Map<String, dynamic>>({
        'glossWords': glossWords,
      });

      final videosData = List<Map<String, dynamic>>.from(
        result.data['videos'] ?? [],
      );

      final videos = videosData
          .map(
            (v) => SignVideo(
              word: v['word'] as String,
              videoUrl: v['videoUrl'] as String,
              duration: (v['duration'] as num).toDouble(),
            ),
          )
          .toList();

      _logger.i(
        'lookupSignVideos: ${glossWords.length} words → ${videos.length} videos',
      );
      return videos;
    } on FirebaseFunctionsException catch (e) {
      _logger.e('lookupSignVideos error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Speech-to-Text / Text-to-Speech
  // ---------------------------------------------------------------------------

  /// Transcribe audio to text using Google Cloud STT.
  /// [audioBase64] — base64-encoded audio data.
  /// Returns the transcribed text.
  Future<String> speechToText(
    String audioBase64, {
    String lang = 'en-US',
    String encoding = 'LINEAR16',
    int sampleRateHertz = 16000,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'speechToText',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
      );
      final result = await callable.call<Map<String, dynamic>>({
        'audioBase64': audioBase64,
        'lang': lang,
        'encoding': encoding,
        'sampleRateHertz': sampleRateHertz,
      });
      final text = result.data['text'] as String? ?? '';
      _logger.i(
        'speechToText [${lang}]: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."',
      );
      return text;
    } on FirebaseFunctionsException catch (e) {
      _logger.e('speechToText error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Generate speech audio from text using Google Cloud TTS.
  /// Returns base64-encoded MP3 audio.
  Future<String> textToSpeech(
    String text, {
    String lang = 'en',
    String? emotion,
  }) async {
    try {
      final callable = _functions.httpsCallable('textToSpeech');
      final result = await callable.call<Map<String, dynamic>>({
        'text': text,
        'lang': lang,
        if (emotion != null) 'emotion': emotion,
      });
      final audioBase64 = result.data['audioBase64'] as String? ?? '';
      _logger.i(
        'textToSpeech [$lang]: "${text.substring(0, text.length > 30 ? 30 : text.length)}..." → ${audioBase64.length} chars',
      );
      return audioBase64;
    } on FirebaseFunctionsException catch (e) {
      _logger.e('textToSpeech error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Translation
  // ---------------------------------------------------------------------------

  /// Translate text between languages using Google Cloud Translation.
  /// [sourceLang] is optional (auto-detect if omitted).
  Future<String> translateText(
    String text, {
    String? sourceLang,
    required String targetLang,
  }) async {
    try {
      final callable = _functions.httpsCallable('translateText');
      final result = await callable.call<Map<String, dynamic>>({
        'text': text,
        'sourceLang': sourceLang,
        'targetLang': targetLang,
      });
      final translatedText = result.data['translatedText'] as String? ?? '';
      _logger.i('translateText → $targetLang: "$translatedText"');
      return translatedText;
    } on FirebaseFunctionsException catch (e) {
      _logger.e('translateText error: ${e.code} - ${e.message}');
      rethrow;
    }
  }
}
