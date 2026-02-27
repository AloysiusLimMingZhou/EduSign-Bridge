import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:video_player/video_player.dart';

import 'package:ai_voice_to_hand_signs_project/data/models/sign_video.dart';
import 'package:ai_voice_to_hand_signs_project/features/voice_to_text/controllers/voice_to_text_controller.dart';
import 'package:ai_voice_to_hand_signs_project/util/constants/colors.dart';

class VoiceToTextScreen extends StatefulWidget {
  const VoiceToTextScreen({super.key});

  @override
  State<VoiceToTextScreen> createState() => _VoiceToTextScreenState();
}

class _VoiceToTextScreenState extends State<VoiceToTextScreen> {
  late final VoiceToTextController _ctrl;
  late final TextEditingController _textController;

  VideoPlayerController? _videoController;
  List<SignVideo> _pendingQueue = [];
  bool _isPlayingSequence = false;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(VoiceToTextController());
    _textController = TextEditingController();

    // Sync text field with controller's RxString
    ever(_ctrl.transcribedText, (String value) {
      if (_textController.text != value) {
        _textController.text = value;
      }
    });

    // Watch the video queue — when the controller pushes new videos, start playing
    ever(_ctrl.videoQueue, (List<SignVideo> queue) {
      if (queue.isNotEmpty && !_isPlayingSequence) {
        _pendingQueue = List.from(queue);
        _playNext();
      }
    });

    // Watch stop signal from controller
    ever(_ctrl.isVideoPlaying, (bool playing) {
      if (!playing) {
        _stopPlayback();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Video playback — runs entirely on the main thread inside the widget
  // ---------------------------------------------------------------------------

  Future<void> _playNext() async {
    if (_pendingQueue.isEmpty || !_ctrl.isVideoPlaying.value) {
      _isPlayingSequence = false;
      _ctrl.onVideoSequenceFinished();
      return;
    }

    _isPlayingSequence = true;
    final video = _pendingQueue.removeAt(0);

    // Dispose previous controller
    if (_videoController != null) {
      await _videoController!.dispose();
      _videoController = null;
    }

    // Create & initialize new controller on the main thread
    final vc = VideoPlayerController.networkUrl(Uri.parse(video.videoUrl));
    try {
      await vc.initialize();
      if (!mounted || !_ctrl.isVideoPlaying.value) {
        await vc.dispose();
        _isPlayingSequence = false;
        return;
      }

      setState(() => _videoController = vc);
      vc.play();

      // Wait for the video to finish, then move on
      final duration = vc.value.duration;
      await Future.delayed(duration + const Duration(milliseconds: 200));

      if (mounted) _playNext(); // Recurse to next in queue
    } catch (e) {
      debugPrint('⛔ Video error for "${video.word}": $e');
      if (mounted) _playNext(); // Skip broken video, try next
    }
  }

  void _stopPlayback() {
    _pendingQueue.clear();
    _isPlayingSequence = false;
    _videoController?.pause();
    _videoController?.dispose();
    if (mounted) setState(() => _videoController = null);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Voice to Sign',
          style: TextStyle(color: TColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: TColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Status message
                      Obx(
                        () => Text(
                          _ctrl.statusMessage.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _ctrl.isRecording.value
                                ? TColors.error
                                : TColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Video player — only shown when initialized on this thread
                      if (_videoController != null &&
                          _videoController!.value.isInitialized)
                        _buildVideoPlayer(),

                      // Transcript card
                      Expanded(child: _buildTranscriptCard()),
                      const SizedBox(height: 30),

                      // Control buttons
                      _buildControlButtons(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: TColors.primary.withAlpha(50), width: 2),
            boxShadow: [
              BoxShadow(
                color: TColors.primary.withAlpha(20),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTranscriptCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TColors.darkContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TColors.grey.withAlpha(50)),
      ),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              maxLines: null,
              style: const TextStyle(
                color: TColors.textPrimary,
                fontSize: 18,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                hintText: 'Transcription will appear here...',
                hintStyle: TextStyle(color: TColors.textSecondary),
                border: InputBorder.none,
              ),
              onChanged: _ctrl.updateText,
            ),
          ),
          Obx(
            () => _ctrl.isProcessing.value
                ? const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    color: TColors.primary,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Speak (TTS)
        _buildActionButton(
          icon: Iconsax.volume_high,
          label: 'Speak',
          onTap: () => _ctrl.speakText(_textController.text),
          color: TColors.primary,
        ),

        // Record
        Obx(
          () => _buildRecordButton(
            isRecording: _ctrl.isRecording.value,
            onTap: () {
              if (_ctrl.isRecording.value) {
                _ctrl.stopRecording();
              } else {
                _ctrl.startRecording();
              }
            },
          ),
        ),

        // Clear
        _buildActionButton(
          icon: Iconsax.trash,
          label: 'Clear',
          onTap: () {
            _ctrl.clearAll();
            _textController.clear();
            _stopPlayback();
          },
          color: TColors.error,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(50)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: TColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRecordButton({
    required bool isRecording,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isRecording ? TColors.error : TColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isRecording ? TColors.error : TColors.primary).withAlpha(
                100,
              ),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isRecording ? Iconsax.stop : Iconsax.microphone,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }
}
