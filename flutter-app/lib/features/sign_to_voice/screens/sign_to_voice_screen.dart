import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../util/constants/colors.dart';
import '../controllers/sign_to_voice_controller.dart';
import '../widgets/native_sign_language_camera.dart';
import '../widgets/emotion_indicator.dart';

class SignToVoiceScreen extends StatelessWidget {
  const SignToVoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SignToVoiceController());

    return Scaffold(
      backgroundColor: TColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Sign to Voice',
          style: TextStyle(color: TColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: TColors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(
            () => controller.detectedWords.isNotEmpty
                ? IconButton(
                    icon: const Icon(Iconsax.trash, color: TColors.white),
                    onPressed: controller.clearWords,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera Preview Section
          Expanded(flex: 3, child: Obx(() => _buildCameraPreview(controller))),

          // Emotion Detection Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Obx(
              () => EmotionIndicator(
                emotionData: controller.currentEmotion.value,
                isRecording: controller.isRecording.value,
              ),
            ),
          ),

          // Current Detection Display
          Obx(() => _buildCurrentDetection(controller)),

          // Detected Words Section
          Expanded(flex: 2, child: Obx(() => _buildDetectedWords(controller))),

          // Control Buttons
          _buildControlButtons(controller),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(SignToVoiceController controller) {
    if (controller.errorMessage.value.isNotEmpty) {
      return _buildErrorState(controller.errorMessage.value);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: controller.isRecording.value
              ? TColors.success.withAlpha(150)
              : TColors.grey,
          width: 3,
        ),
        boxShadow: controller.isRecording.value
            ? [
                BoxShadow(
                  color: TColors.success.withAlpha(50),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Native Camera View — with both sign + emotion callbacks
            NativeSignLanguageCamera(
              onResult: controller.onResult,
              onEmotionResult: (label, score) {
                controller.onEmotionDetected(label, score);
              },
            ),

            // Recording indicator
            if (controller.isRecording.value)
              Positioned(top: 16, right: 16, child: _buildRecordingIndicator()),

            // Processing indicator
            if (controller.isProcessing.value)
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: TColors.darkContainer.withAlpha(200),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: TColors.primary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Processing...',
                        style: TextStyle(
                          color: TColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: TColors.error.withAlpha(200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.record, color: TColors.white, size: 14),
          SizedBox(width: 6),
          Text(
            'REC',
            style: TextStyle(
              color: TColors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentDetection(SignToVoiceController controller) {
    final word = controller.currentWord.value;
    final conf = controller.confidence.value;

    if (word.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: const Text(
          'Start recording to detect signs',
          style: TextStyle(color: TColors.textSecondary, fontSize: 14),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: TColors.linearGradient,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: TColors.primary.withAlpha(80),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              word,
              style: const TextStyle(
                color: TColors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(conf * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: TColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedWords(SignToVoiceController controller) {
    final words = controller.detectedWords;

    if (words.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TColors.darkContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TColors.grey.withAlpha(50)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.message_text,
                size: 40,
                color: TColors.textSecondary,
              ),
              SizedBox(height: 12),
              Text(
                'Detected words will appear here',
                style: TextStyle(color: TColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColors.darkContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TColors.grey.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Iconsax.text, size: 18, color: TColors.primary),
              SizedBox(width: 8),
              Text(
                'Detected Signs',
                style: TextStyle(
                  color: TColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: words.asMap().entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: TColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TColors.primary.withAlpha(100)),
                  ),
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      color: TColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Sentence preview — shows AI sentence if available
          Obx(() {
            final displayText = controller.aiSentence.value.isNotEmpty
                ? controller.aiSentence.value
                : controller.getSentence();
            final isAI = controller.aiSentence.value.isNotEmpty;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAI
                    ? TColors.primary.withAlpha(30)
                    : TColors.grey.withAlpha(100),
                borderRadius: BorderRadius.circular(12),
                border: isAI
                    ? Border.all(color: TColors.primary.withAlpha(80))
                    : null,
              ),
              child: Row(
                children: [
                  if (isAI) ...[
                    const Icon(
                      Iconsax.magic_star,
                      size: 16,
                      color: TColors.primary,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      displayText,
                      style: TextStyle(
                        color: TColors.textPrimary,
                        fontSize: 16,
                        fontStyle: isAI ? FontStyle.normal : FontStyle.italic,
                        fontWeight: isAI ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildControlButtons(SignToVoiceController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Record/Stop Button
          Obx(() => _buildMainButton(controller)),

          // Send to AI Button
          Obx(
            () => controller.detectedWords.isNotEmpty
                ? _buildSendButton(controller)
                : const SizedBox(width: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton(SignToVoiceController controller) {
    final isRecording = controller.isRecording.value;

    return GestureDetector(
      onTap: isRecording ? controller.stopRecording : controller.startRecording,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isRecording ? null : TColors.linearGradient,
          color: isRecording ? TColors.error : null,
          boxShadow: [
            BoxShadow(
              color: (isRecording ? TColors.error : TColors.primary).withAlpha(
                100,
              ),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isRecording ? Iconsax.stop : Iconsax.video,
          color: TColors.white,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildSendButton(SignToVoiceController controller) {
    final isSending = controller.isSending.value;

    return GestureDetector(
      onTap: isSending ? null : controller.sendToAI,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSending ? TColors.grey : TColors.success,
          boxShadow: [
            BoxShadow(
              color: (isSending ? TColors.grey : TColors.success).withAlpha(
                100,
              ),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: isSending
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: TColors.white,
                ),
              )
            : const Icon(Iconsax.send_1, color: TColors.white, size: 24),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColors.darkContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TColors.error.withAlpha(100)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.warning_2, size: 48, color: TColors.error),
              const SizedBox(height: 16),
              const Text(
                'Error',
                style: TextStyle(
                  color: TColors.error,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(color: TColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
