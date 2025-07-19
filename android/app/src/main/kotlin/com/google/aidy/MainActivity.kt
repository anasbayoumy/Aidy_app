package com.google.aidy

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.google.aidy/ai"
    private lateinit var aiEngine: AIEngine

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        aiEngine = AIEngine(applicationContext)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initGemma" -> {
                    aiEngine.initializeModel { success, message ->
                        if (success) {
                            result.success("Model initialized successfully")
                        } else {
                            result.error("INIT_ERROR", message ?: "Unknown error", null)
                        }
                    }
                }
                "runGemmaInference" -> {
                    val textQuery = call.argument<String>("textQuery") ?: ""
                    val imagePath = call.argument<String>("imagePath")
                    
                    aiEngine.runGemmaInference(textQuery, imagePath) { success, response ->
                        if (success) {
                            result.success(response)
                        } else {
                            result.error("INFERENCE_ERROR", response ?: "Unknown error", null)
                        }
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
