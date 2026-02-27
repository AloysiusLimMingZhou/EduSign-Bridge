package com.example.ai_voice_to_hand_signs_project

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarkerResult
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.util.LinkedList
import org.json.JSONObject

/**
 * EmotionAnalyzer — FaceLandmarker + TFLite emotion classifier
 *
 * Mirrors SignLanguageAnalyzer.kt but for facial emotion detection:
 *   1. MediaPipe FaceLandmarker extracts 52 blendshape scores
 *   2. TFLite model (distilled from SVM) classifies the scores → emotion
 *   3. Temporal smoothing via majority vote over last N predictions
 *
 * Calls [onResult] with (emotionLabel, confidence) when emotion changes
 * or every EMIT_INTERVAL_MS milliseconds.
 */
class EmotionAnalyzer(
    private val context: Context,
    private val onResult: (String, Float) -> Unit
) {
    companion object {
        private const val TAG = "EmotionAnalyzer"
        private const val FACE_LANDMARKER_MODEL = "face_landmarker.task"
        private const val EMOTION_TFLITE_MODEL = "emotion_classifier.tflite"
        private const val EMOTION_LABELS_FILE = "emotion_classifier_labels.json"
        private const val SMOOTHING_WINDOW = 8
        private const val EMIT_INTERVAL_MS = 3000L  // Emit at least every 3 seconds
    }

    private var faceLandmarker: FaceLandmarker? = null
    private var tflite: Interpreter? = null
    private var labels: List<String> = emptyList()

    // Temporal smoothing
    private val predictionHistory = LinkedList<Pair<String, Float>>()
    private var lastEmittedEmotion: String? = null
    private var lastEmitTime: Long = 0L

    init {
        setupFaceLandmarker()
        setupTFLite()
        loadLabels()
    }

    // ── Setup ──

    private fun setupFaceLandmarker() {
        try {
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath(FACE_LANDMARKER_MODEL)
                .build()

            val options = FaceLandmarker.FaceLandmarkerOptions.builder()
                .setBaseOptions(baseOptions)
                .setOutputFaceBlendshapes(true)
                .setNumFaces(1)
                .setMinFaceDetectionConfidence(0.5f)
                .setMinFacePresenceConfidence(0.5f)
                .setMinTrackingConfidence(0.5f)
                .setRunningMode(RunningMode.IMAGE)
                .build()

            faceLandmarker = FaceLandmarker.createFromOptions(context, options)
            Log.i(TAG, "FaceLandmarker initialized")
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing FaceLandmarker: ${e.message}")
        }
    }

    private fun setupTFLite() {
        try {
            val modelBuffer = loadModelFile(EMOTION_TFLITE_MODEL)
            val options = Interpreter.Options()
            options.setUseXNNPACK(true)
            tflite = Interpreter(modelBuffer, options)
            Log.i(TAG, "TFLite emotion model loaded")
        } catch (e: Exception) {
            Log.e(TAG, "Error loading TFLite model: ${e.message}")
        }
    }

    private fun loadLabels() {
        try {
            val jsonStr = context.assets.open(EMOTION_LABELS_FILE)
                .bufferedReader().use { it.readText() }
            val json = JSONObject(jsonStr)
            val labelsArr = json.getJSONArray("labels")
            labels = (0 until labelsArr.length()).map { labelsArr.getString(it) }
            Log.i(TAG, "Emotion labels: $labels")
        } catch (e: Exception) {
            Log.e(TAG, "Error loading labels: ${e.message}")
            // Fallback
            labels = listOf("angry", "confused", "down", "happy", "neutral", "questioning")
        }
    }

    private fun loadModelFile(filename: String): ByteBuffer {
        val fileDescriptor = context.assets.openFd(filename)
        val inputStream = FileInputStream(fileDescriptor.fileDescriptor)
        val fileChannel = inputStream.channel
        return fileChannel.map(
            FileChannel.MapMode.READ_ONLY,
            fileDescriptor.startOffset,
            fileDescriptor.declaredLength
        )
    }

    // ── Analysis ──

    /**
     * Analyze a camera frame for facial emotion.
     * Call this from the ImageAnalysis.Analyzer callback alongside SignLanguageAnalyzer.
     */
    fun analyze(bitmap: Bitmap) {
        if (faceLandmarker == null || tflite == null) return

        try {
            val mpImage = BitmapImageBuilder(bitmap).build()
            val result = faceLandmarker?.detect(mpImage) ?: return
            processResult(result)
        } catch (e: Exception) {
            Log.e(TAG, "Analysis error: ${e.message}")
        }
    }

    private fun processResult(result: FaceLandmarkerResult) {
        val blendshapes = result.faceBlendshapes()
        if (blendshapes.isEmpty() || blendshapes.get()[0] == null) return

        val faceBlendshapes = blendshapes.get()[0]

        // Extract 52 blendshape scores (skip _neutral at index 0)
        val scores = FloatArray(52)
        var scoreIdx = 0
        for (bs in faceBlendshapes) {
            if (bs.categoryName() == "_neutral") continue
            if (scoreIdx < 52) {
                scores[scoreIdx] = bs.score()
                scoreIdx++
            }
        }

        // Pad if fewer than 52
        while (scoreIdx < 52) {
            scores[scoreIdx] = 0f
            scoreIdx++
        }

        // Run TFLite inference
        val input = Array(1) { scores }
        val output = Array(1) { FloatArray(labels.size) }

        try {
            tflite?.run(input, output)
        } catch (e: Exception) {
            Log.e(TAG, "TFLite inference error: ${e.message}")
            return
        }

        // Get prediction
        val probs = output[0]
        val maxIdx = probs.indices.maxByOrNull { probs[it] } ?: 0
        val label = if (maxIdx < labels.size) labels[maxIdx] else "neutral"
        val confidence = probs[maxIdx]

        // Add to smoothing history
        predictionHistory.add(Pair(label, confidence))
        if (predictionHistory.size > SMOOTHING_WINDOW) {
            predictionHistory.removeFirst()
        }

        // Get smoothed prediction (majority vote)
        val smoothed = getSmoothedPrediction()

        // Emit if emotion changed or interval elapsed
        val currentTime = System.currentTimeMillis()
        if (smoothed.first != lastEmittedEmotion ||
            currentTime - lastEmitTime > EMIT_INTERVAL_MS) {
            onResult(smoothed.first, smoothed.second)
            lastEmittedEmotion = smoothed.first
            lastEmitTime = currentTime
        }
    }

    private fun getSmoothedPrediction(): Pair<String, Float> {
        if (predictionHistory.isEmpty()) return Pair("neutral", 0f)

        val votes = mutableMapOf<String, Int>()
        val confs = mutableMapOf<String, MutableList<Float>>()

        for ((label, conf) in predictionHistory) {
            votes[label] = (votes[label] ?: 0) + 1
            confs.getOrPut(label) { mutableListOf() }.add(conf)
        }

        val best = votes.maxByOrNull { it.value }?.key ?: "neutral"
        val avgConf = confs[best]?.average()?.toFloat() ?: 0f

        return Pair(best, avgConf)
    }

    fun close() {
        faceLandmarker?.close()
        tflite?.close()
        Log.i(TAG, "EmotionAnalyzer closed")
    }
}
