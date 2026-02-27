package com.example.ai_voice_to_hand_signs_project

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.SystemClock
import android.util.Log
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import kotlin.math.sqrt

/**
 * Rule-based ASL Fingerspelling Analyzer
 * ========================================
 * Replaces the previous LSTM + TFLite inference pipeline with a zero-model,
 * single-frame geometric rule engine ([FingerspellingClassifier]).
 *
 * No .tflite asset required. No 60-frame sliding window.
 * Supported letters: A–Z (J and Z excluded — they require motion).
 */
class SignLanguageAnalyzer(
    private val context: Context,
    private val onResult: (String, Float) -> Unit
) : ImageAnalysis.Analyzer {

    private var handLandmarker: HandLandmarker? = null

    // Debounce: only send a new prediction to Flutter if the letter changes
    // or at least DEBOUNCE_MS milliseconds have passed.
    private var lastLabel: String? = null
    private var lastSentTime: Long = 0L
    private val DEBOUNCE_MS = 800L

    companion object {
        private const val TAG = "SignLanguageAnalyzer"
        private const val NUM_FEATURES = 63 // 21 landmarks × 3 coords
        private const val MIN_CONFIDENCE = 0.55f
    }

    init {
        setupMediaPipe()
    }

    private fun setupMediaPipe() {
        try {
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath("hand_landmarker.task")
                .build()

            val options = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setNumHands(1)
                .setMinHandDetectionConfidence(0.5f)
                .setMinHandPresenceConfidence(0.5f)
                .setMinTrackingConfidence(0.5f)
                .setRunningMode(RunningMode.IMAGE)
                .build()

            handLandmarker = HandLandmarker.createFromOptions(context, options)
            Log.i(TAG, "MediaPipe HandLandmarker initialised (rule-based mode — no TFLite)")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialise HandLandmarker: ${e.message}")
        }
    }

    // ── Public API ────────────────────────────────────────────────────────────

    override fun analyze(imageProxy: ImageProxy) {
        val bitmap = imageProxy.toBitmap()
        val rotationDegrees = imageProxy.imageInfo.rotationDegrees
        val rotated = if (rotationDegrees != 0) rotateBitmap(bitmap, rotationDegrees.toFloat())
                      else bitmap
        analyzeFromBitmap(rotated)
        imageProxy.close()
    }

    /**
     * Public entry point used by [NativeCameraView] to share a pre-rotated
     * Bitmap between sign and emotion analyzers.
     */
    fun analyzeFromBitmap(bitmap: Bitmap) {
        val lm = handLandmarker ?: return
        val mpImage = BitmapImageBuilder(bitmap).build()
        val result = lm.detect(mpImage)
        processResult(result)
    }

    // ── Internal processing ───────────────────────────────────────────────────

    private fun processResult(result: HandLandmarkerResult?) {
        val rawLandmarks = result?.landmarks()

        if (rawLandmarks.isNullOrEmpty()) {
            // No hand detected — optionally send a "null" signal to Flutter
            return
        }

        val firstHand = rawLandmarks[0]
        val normalised = normalizeLandmarks(firstHand)

        // Rule-based single-frame classification
        val classification = FingerspellingClassifier.classify(normalised, MIN_CONFIDENCE)

        if (classification.letter == null) {
            Log.d(TAG, "No confident match (best score ${classification.confidence})")
            return
        }

        val label = classification.letter.toString()
        val score = classification.confidence
        Log.d(TAG, "Classified: $label  confidence=${String.format("%.2f", score)}")

        // Debounce before forwarding to Flutter
        val now = SystemClock.uptimeMillis()
        if (label != lastLabel || now - lastSentTime > DEBOUNCE_MS) {
            lastLabel = label
            lastSentTime = now
            onResult(label, score)
        }
    }

    /**
     * Normalise 21 landmarks: centre on wrist, scale by max distance from wrist.
     * Matches the Python `normalize_landmarks()` function exactly.
     */
    fun normalizeLandmarks(
        landmarks: List<com.google.mediapipe.tasks.components.containers.NormalizedLandmark>
    ): FloatArray {
        val out = FloatArray(NUM_FEATURES)
        val wristX = landmarks[0].x()
        val wristY = landmarks[0].y()
        val wristZ = landmarks[0].z()

        var maxDist = 0f
        for (i in 0 until 21) {
            val lm = landmarks[i]
            val cx = lm.x() - wristX
            val cy = lm.y() - wristY
            val cz = lm.z() - wristZ
            out[i * 3]     = cx
            out[i * 3 + 1] = cy
            out[i * 3 + 2] = cz
            val d = sqrt(cx * cx + cy * cy + cz * cz)
            if (d > maxDist) maxDist = d
        }

        if (maxDist > 0f) {
            for (i in out.indices) out[i] /= maxDist
        }
        return out
    }

    private fun rotateBitmap(source: Bitmap, angle: Float): Bitmap {
        val matrix = Matrix().also { it.postRotate(angle) }
        return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
    }
}
