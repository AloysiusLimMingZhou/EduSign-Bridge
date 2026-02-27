import 'package:flutter/material.dart';
import 'package:ai_voice_to_hand_signs_project/data/models/emotion_data.dart';
import 'package:ai_voice_to_hand_signs_project/util/constants/colors.dart';

/// Widget to display current emotion detection result
class EmotionIndicator extends StatelessWidget {
  final EmotionData? emotionData;
  final bool isRecording;

  const EmotionIndicator({
    super.key,
    this.emotionData,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    if (!isRecording || emotionData == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: TColors.darkContainer.withAlpha(180),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TColors.grey.withAlpha(50)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.face, color: TColors.textSecondary, size: 20),
            SizedBox(width: 8),
            Text(
              'No emotion detected',
              style: TextStyle(color: TColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: _getEmotionGradient(emotionData!.emotion),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getEmotionColor(emotionData!.emotion).withAlpha(100),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emotionData!.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emotionData!.label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${(emotionData!.confidence * 100).toStringAsFixed(0)}% confidence',
                style: TextStyle(
                  color: Colors.white.withAlpha(200),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getEmotionColor(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return const Color(0xFFFFC107); // Amber
      case EmotionType.angry:
        return const Color(0xFFF44336); // Red
      case EmotionType.down:
        return const Color(0xFF2196F3); // Blue
      case EmotionType.confused:
        return const Color(0xFFFF9800); // Orange
      case EmotionType.questioning:
        return const Color(0xFF9C27B0); // Purple
      case EmotionType.neutral:
        return TColors.grey;
    }
  }

  LinearGradient _getEmotionGradient(EmotionType emotion) {
    final color = _getEmotionColor(emotion);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color, color.withAlpha(200)],
    );
  }
}
