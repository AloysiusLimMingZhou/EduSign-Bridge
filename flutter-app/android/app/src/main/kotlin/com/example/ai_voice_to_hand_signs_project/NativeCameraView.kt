package com.example.ai_voice_to_hand_signs_project

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.view.View
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.util.concurrent.Executors

class NativeCameraView(
    private val context: Context,
    messenger: BinaryMessenger,
    id: Int,
    creationParams: Any?
) : PlatformView, MethodChannel.MethodCallHandler {

    private val methodChannel: MethodChannel = MethodChannel(messenger, "sign_language_camera_$id")
    private val previewView: PreviewView = PreviewView(context)
    private val executor = Executors.newSingleThreadExecutor()
    
    private var signLanguageAnalyzer: SignLanguageAnalyzer? = null
    private var emotionAnalyzer: EmotionAnalyzer? = null

    init {
        methodChannel.setMethodCallHandler(this)
        setupCamera()
    }

    private fun setupCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)

        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()
            bindPreview(cameraProvider)
        }, ContextCompat.getMainExecutor(context))
        
        // Initialize analyzers
        signLanguageAnalyzer = SignLanguageAnalyzer(context) { label, score ->
            val args = mapOf("label" to label, "score" to score)
            // Send to Flutter on UI thread
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                methodChannel.invokeMethod("onResult", args)
            }
        }
        
        emotionAnalyzer = EmotionAnalyzer(context) { label, score ->
            val args = mapOf("label" to label, "score" to score)
             // Send to Flutter on UI thread
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                methodChannel.invokeMethod("onEmotionResult", args)
            }
        }
    }

    private fun bindPreview(cameraProvider: ProcessCameraProvider) {
        val preview = Preview.Builder().build()
        val cameraSelector = CameraSelector.Builder()
            .requireLensFacing(CameraSelector.LENS_FACING_FRONT)
            .build()

        val imageAnalysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
            .build()

        imageAnalysis.setAnalyzer(executor) { imageProxy ->
            processImage(imageProxy)
        }

        preview.setSurfaceProvider(previewView.surfaceProvider)
        
        // Unbind use cases before rebinding
        cameraProvider.unbindAll()

        // Bind use cases to camera
        val lifecycleOwner = getLifecycleOwner(context)
        
        if (lifecycleOwner != null) {
             try {
                cameraProvider.bindToLifecycle(
                    lifecycleOwner, 
                    cameraSelector, 
                    preview, 
                    imageAnalysis
                )
             } catch(exc: Exception) {
                 exc.printStackTrace()
             }
        } else {
            // Fallback: try ProcessLifecycleOwner or search context hierarchy deeper
            // But usually this means we are not in an Activity context yet
            android.util.Log.e("NativeCameraView", "Could not find LifecycleOwner for camera!")
        }
    }

    private fun getLifecycleOwner(context: Context): LifecycleOwner? {
        var curContext = context
        while (curContext is android.content.ContextWrapper) {
            if (curContext is LifecycleOwner) {
                return curContext
            }
            curContext = curContext.baseContext
        }
        return null
    }
    
    private fun processImage(imageProxy: ImageProxy) {
        val bitmap = imageProxy.toBitmap()
        
        // Fix rotation if needed
        val rotationDegrees = imageProxy.imageInfo.rotationDegrees
        val rotatedBitmap = if (rotationDegrees != 0) {
            rotateBitmap(bitmap, rotationDegrees.toFloat())
        } else {
            bitmap
        }
        
        // Run analyzers
        signLanguageAnalyzer?.analyzeFromBitmap(rotatedBitmap)
        emotionAnalyzer?.analyze(rotatedBitmap)
        
        imageProxy.close()
    }
    
    private fun rotateBitmap(source: Bitmap, angle: Float): Bitmap {
        val matrix = Matrix()
        matrix.postRotate(angle)
        return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
    }

    override fun getView(): View {
        return previewView
    }

    override fun dispose() {
        methodChannel.setMethodCallHandler(null)
        executor.shutdown()
        // emotionAnalyzer?.close() // If it has a close method
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            else -> result.notImplemented()
        }
    }
}
