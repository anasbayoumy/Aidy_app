package com.example.myapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.location.Location
import android.location.LocationManager
import android.location.LocationListener
import android.os.Bundle
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugins.GeneratedPluginRegistrant
import android.util.Log
import java.io.File
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import com.google.mediapipe.tasks.genai.llminference.GraphOptions
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import com.google.mediapipe.tasks.genai.llminference.LlmInferenceSession
import java.util.concurrent.Executors
// MediaPipe imports (to be added when wiring up real inference)
// import com.google.mediapipe.tasks.genai.llminference.LlmInference
// import com.google.mediapipe.tasks.genai.llminference.LlmInferenceSession

class MainActivity : FlutterActivity() {
    private val CHANNEL = "location_service"
    private lateinit var locationManager: LocationManager
    private var currentLocation: Location? = null

    // LLM instance and session
    private var llmInference: LlmInference? = null
    private var llmSession: LlmInferenceSession? = null
    private var modelLoaded: Boolean = false
    private val llmLock = Any()
    private val executor = Executors.newSingleThreadExecutor()

    private fun printLog(msg: String) {
        Log.d("LLM", msg)
    }

    private fun getModelFilePath(context: Context): String {
        // 1. Check external files dir for gemma-3n-E2B-it-int4.task
        val extDir = context.getExternalFilesDir(null)
        val extFile = java.io.File(extDir, "gemma-3n-E2B-it-int4.task")
        if (extFile.exists()) {
            printLog("[getModelFilePath] Found model in external files: ${extFile.absolutePath}")
            return extFile.absolutePath
        }
        // 2. Fallback: check assets (copy to cache if needed)
        val assetFileName = "gemma-3n-E2B-it-int4.task"
        val cacheFile = java.io.File(context.cacheDir, assetFileName)
        if (!cacheFile.exists()) {
            printLog("[getModelFilePath] Copying model from assets to cache: $assetFileName")
            context.assets.open(assetFileName).use { input ->
                cacheFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
        }
        printLog("[getModelFilePath] Using model from cache: ${cacheFile.absolutePath}")
        return cacheFile.absolutePath
    }

    private fun initLlmModel(context: Context, result: MethodChannel.Result) {
        executor.execute {
            printLog("[initLlmModel] Called")
            synchronized(llmLock) {
                try {
                    val modelPath = getModelFilePath(context)
                    val file = java.io.File(modelPath)
                    printLog("[initLlmModel] Checking for model file at: $modelPath")
                    if (!file.exists()) {
                        printLog("[initLlmModel] Model file not found: $modelPath")
                        Handler(Looper.getMainLooper()).post {
                            result.error("MODEL_NOT_FOUND", "Model file not found at $modelPath", null)
                        }
                        return@execute
                    }
                    printLog("[initLlmModel] Model file found: $modelPath, size: ${file.length()}")
                    val options = LlmInference.LlmInferenceOptions.builder()
                        .setModelPath(modelPath)
                        .setMaxTokens(256) // Lower for faster response
                        .setMaxNumImages(1)
                        .setMaxTopK(40)
                        .setPreferredBackend(LlmInference.Backend.CPU)
                        .build()
                    printLog("[initLlmModel] Building LlmInference with options: $options")
                    llmInference = LlmInference.createFromOptions(context, options)
                    val sessionOptions = LlmInferenceSession.LlmInferenceSessionOptions.builder()
                        .setTopK(64)
                        .setTopP(0.95f)
                        .setTemperature(1.0f)
                        .setGraphOptions(GraphOptions.builder().setEnableVisionModality(true).build())
                        .build()
                    printLog("[initLlmModel] Building LlmInferenceSession with options: $sessionOptions")
                    llmSession = LlmInferenceSession.createFromOptions(llmInference, sessionOptions)
                    modelLoaded = true
                    printLog("[initLlmModel] Model initialized successfully")
                    Handler(Looper.getMainLooper()).post {
                        result.success(true)
                    }
                } catch (e: Exception) {
                    printLog("[initLlmModel] Error: ${e.message}")
                    Handler(Looper.getMainLooper()).post {
                        result.error("INIT_ERROR", e.message, null)
                    }
                }
            }
        }
    }

    private fun runLlmInference(context: Context, args: Map<*, *>, result: MethodChannel.Result) {
        executor.execute {
            printLog("[runLlmInference] Called with args: $args")
            synchronized(llmLock) {
                if (!modelLoaded || llmInference == null || llmSession == null) {
                    printLog("[runLlmInference] Model not initialized")
                    Handler(Looper.getMainLooper()).post {
                        result.error("MODEL_NOT_INITIALIZED", "Model not initialized", null)
                    }
                    return@execute
                }
                try {
                    val text = args["text"] as? String
                    val imagePath = args["imagePath"] as? String
                    val audioPath = args["audioPath"] as? String
                    val session = llmSession!!
                    printLog("[runLlmInference] Session ready. text=$text, imagePath=$imagePath, audioPath=$audioPath")
                    if (!text.isNullOrBlank()) {
                        printLog("[runLlmInference] Adding text chunk: $text")
                        session.addQueryChunk(text)
                    } else {
                        printLog("[runLlmInference] No text chunk provided")
                    }
                    if (!imagePath.isNullOrBlank()) {
                        printLog("[runLlmInference] Adding image: $imagePath")
                        val imgFile = java.io.File(imagePath)
                        if (imgFile.exists()) {
                            val bitmap = BitmapFactory.decodeFile(imagePath)
                            session.addImage(com.google.mediapipe.framework.image.BitmapImageBuilder(bitmap).build())
                            printLog("[runLlmInference] Image added to session")
                        } else {
                            printLog("[runLlmInference] Image file not found: $imagePath")
                        }
                    } else {
                        printLog("[runLlmInference] No image provided")
                    }
                    if (!audioPath.isNullOrBlank()) {
                        printLog("[runLlmInference] Adding audio: $audioPath")
                        val audioFile = java.io.File(audioPath)
                        if (audioFile.exists()) {
                            try {
                                val audioBytes = audioFile.readBytes()
                                // Use reflection to call addAudio if it exists
                                try {
                                    val addAudioMethod = session.javaClass.getMethod("addAudio", ByteArray::class.java)
                                    addAudioMethod.invoke(session, audioBytes)
                                    printLog("[runLlmInference] Audio added to session (reflection)")
                                } catch (e: NoSuchMethodException) {
                                    printLog("[runLlmInference] addAudio method not found in LlmInferenceSession. Audio not supported in this version.")
                                } catch (e: Exception) {
                                    printLog("[runLlmInference] Error invoking addAudio (reflection): ${e.message}")
                                }
                            } catch (e: Exception) {
                                printLog("[runLlmInference] Error reading audio file: ${e.message}")
                            }
                        } else {
                            printLog("[runLlmInference] Audio file not found: $audioPath")
                        }
                    } else {
                        printLog("[runLlmInference] No audio provided")
                    }
                    printLog("[runLlmInference] Generating response...")
                    val startTime = System.currentTimeMillis()
                    val responseBuilder = StringBuilder()
                    val latch = java.util.concurrent.CountDownLatch(1)
                    session.generateResponseAsync({ partial, done ->
                        printLog("[runLlmInference] Partial: $partial, done: $done")
                        responseBuilder.append(partial)
                        if (done) {
                            val endTime = System.currentTimeMillis()
                            printLog("[runLlmInference] Inference complete, final response length: ${responseBuilder.length}")
                            printLog("[runLlmInference] Inference took ${endTime - startTime} ms")
                            latch.countDown()
                        }
                    })
                    latch.await() // Wait for completion
                    val response = responseBuilder.toString()
                    printLog("[runLlmInference] Final response: $response")
                    Handler(Looper.getMainLooper()).post {
                        result.success(response)
                    }
                } catch (e: Exception) {
                    printLog("[runLlmInference] Error: ${e.message}")
                    Handler(Looper.getMainLooper()).post {
                        result.error("INFERENCE_ERROR", e.message, null)
                    }
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        
        // Existing location channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCurrentLocation" -> {
                    getCurrentLocation(result)
                }
                "isLocationServiceEnabled" -> {
                    isLocationServiceEnabled(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // New LLM channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.myapp/llm").setMethodCallHandler { call, result ->
            when (call.method) {
                "initModel" -> {
                    printLog("[MethodChannel] initModel called")
                    initLlmModel(this, result)
                }
                "runLlmInference" -> {
                    printLog("[MethodChannel] runLlmInference called")
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                    runLlmInference(this, args, result)
                }
                else -> result.notImplemented()
            }
        }

        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }

    private fun getCurrentLocation(result: MethodChannel.Result) {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED &&
            ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "Location permission not granted", null)
            return
        }

        try {
            // Try to get last known location first (faster)
            var bestLocation: Location? = null
            val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER, LocationManager.PASSIVE_PROVIDER)
            
            for (provider in providers) {
                if (locationManager.isProviderEnabled(provider)) {
                    val location = locationManager.getLastKnownLocation(provider)
                    if (location != null) {
                        if (bestLocation == null || location.accuracy < bestLocation.accuracy) {
                            bestLocation = location
                        }
                    }
                }
            }

            if (bestLocation != null) {
                val resultMap = mapOf(
                    "success" to true,
                    "latitude" to bestLocation.latitude,
                    "longitude" to bestLocation.longitude,
                    "accuracy" to bestLocation.accuracy
                )
                result.success(resultMap)
            } else {
                // If no last known location, try to get a fresh location
                var locationReceived = false
                val locationListener = object : LocationListener {
                    override fun onLocationChanged(location: Location) {
                        if (!locationReceived) {
                            locationReceived = true
                            val resultMap = mapOf(
                                "success" to true,
                                "latitude" to location.latitude,
                                "longitude" to location.longitude,
                                "accuracy" to location.accuracy
                            )
                            result.success(resultMap)
                            locationManager.removeUpdates(this)
                        }
                    }

                    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                    override fun onProviderEnabled(provider: String) {}
                    override fun onProviderDisabled(provider: String) {}
                }

                // Try GPS first, then network provider
                var providerFound = false
                for (provider in providers) {
                    if (locationManager.isProviderEnabled(provider)) {
                        try {
                            locationManager.requestLocationUpdates(provider, 0L, 0f, locationListener)
                            providerFound = true
                            break
                        } catch (e: Exception) {
                            // Continue to next provider
                        }
                    }
                }

                if (!providerFound) {
                    result.error("NO_PROVIDER", "No location provider available", null)
                    return
                }
                
                // Set a timeout in case location doesn't come quickly
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                    if (!locationReceived) {
                        locationManager.removeUpdates(locationListener)
                        result.error("TIMEOUT", "Location request timed out", null)
                    }
                }, 15000) // 15 second timeout
            }
        } catch (e: Exception) {
            result.error("LOCATION_ERROR", "Failed to get location: ${e.message}", null)
        }
    }

    private fun isLocationServiceEnabled(result: MethodChannel.Result) {
        try {
            val isEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
            result.success(isEnabled)
        } catch (e: Exception) {
            result.error("SERVICE_ERROR", "Failed to check location service: ${e.message}", null)
        }
    }
}