package com.google.aidy

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.core.graphics.drawable.toBitmap
import com.google.gson.Gson

import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage

import com.google.mediapipe.tasks.genai.llminference.LlmInference
import com.google.mediapipe.tasks.genai.llminference.LlmInferenceOptions
import com.google.mediapipe.tasks.genai.llminference.LlmInferenceSession
import kotlinx.coroutines.*
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class AIEngine(private val context: Context) {
    private var llmInference: LlmInference? = null
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    companion object {
        private const val MODEL_FILENAME = "gemma3n.task"
        private const val TAG = "AIEngine"
    }

    /**
     * Initialize the Gemma model - copies from assets if necessary, then loads into memory
     */
    fun initializeModel(callback: (Boolean, String) -> Unit) {
        scope.launch {
            try {
                val modelFile = File(context.filesDir, MODEL_FILENAME)
                
                // Copy the model from assets to internal storage if it doesn't exist
                if (!modelFile.exists()) {
                    copyModelFromAssets(modelFile)
                }
                
                // Create LLM inference options
                val options = LlmInferenceOptions.builder()
                    .setModelPath(modelFile.absolutePath)
                    .setMaxTokens(1024)
                    .setTemperature(0.7f)
                    .setRandomSeed(42)
                    .build()
                
                // Initialize the model
                llmInference = LlmInference.createFromOptions(context, options)
                callback(true, "Model loaded successfully")
                
            } catch (e: Exception) {
                callback(false, "Error initializing model: ${e.message}")
            }
        }
    }

    /**
     * Copy the Gemma model from the assets folder to internal storage
     */
    private suspend fun copyModelFromAssets(destinationFile: File) = withContext(Dispatchers.IO) {
        try {
            context.assets.open(MODEL_FILENAME).use { inputStream ->
                FileOutputStream(destinationFile).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
            }
        } catch (e: IOException) {
            android.util.Log.e(TAG, "Error copying model from assets: ${e.message}")
            throw e // rethrow to be caught by the calling coroutine
        }
    }

    /**
     * Run inference with text query and optional image
     */
    fun runGemmaInference(textQuery: String, imagePath: String?, callback: (Boolean, String) -> Unit) {
        if (llmInference == null) {
            callback(false, "Model not initialized. Please initialize first.")
            return
        }
        
        scope.launch {
            try {
                val result = runGemmaInferenceInternal(textQuery, imagePath)
                callback(true, result)
            } catch (e: Exception) {
                callback(false, "Inference error: ${e.message}")
            }
        }
    }

    /**
     * Internal inference execution with coroutines
     */
    private suspend fun runGemmaInferenceInternal(textQuery: String, imagePath: String?): String = withContext(Dispatchers.IO) {
        val session = llmInference!!.createSession()
        
        // Add image to session if provided
        imagePath?.let { path ->
            val bitmap = BitmapFactory.decodeFile(path)
            bitmap?.let {
                val mpImage = BitmapImageBuilder(it).build()
                session.addQueryImage(mpImage)
            }
        }
        
        // Create emergency-focused prompt
        val emergencyPrompt = createEmergencyPrompt(textQuery)
        
        // Run inference
        val responseBuilder = StringBuilder()
        val responseListener = object : LlmInference.LlmInferenceSession.ResponseListener {
            override fun onResponse(partialResult: String, done: Boolean) {
                responseBuilder.append(partialResult)
                if (done) {
                    // Parsing will be handled after this callback
                }
            }
        }
        
        // Generate response
        session.generateResponseAsync(emergencyPrompt, responseListener)
        
        // Wait for completion (simplified - in production, use proper async handling)
        delay(5000) // Allow time for response generation
        
        val fullResponse = responseBuilder.toString()
        
        // Parse and structure the response
        return@withContext parseGemmaOutputToJson(fullResponse)
    }

    /**
     * Create emergency-focused prompt for better structured output
     */
    private fun createEmergencyPrompt(userQuery: String): String {
        return """
You are an emergency AI assistant. Analyze the following emergency situation and provide:

1. A concise SMS draft for emergency contacts (max 160 characters)
2. Step-by-step first aid or safety guidance

Emergency Situation: $userQuery

Please format your response as:

SMS Draft: [Your emergency SMS here]

Guidance Steps:
1. [First step]
2. [Second step]
3. [Third step]
[Continue as needed]

Keep the SMS brief but informative. Focus on immediate safety and actionable steps.
        """.trimIndent()
    }

    /**
     * Parse the AI response into structured JSON format
     */
    private fun parseGemmaOutputToJson(rawResponse: String): String {
        return try {
            val lines = rawResponse.lines()
            var smsDraft = ""
            val guidanceSteps = mutableListOf<String>()
            
            var currentSection = ""
            
            for (line in lines) {
                val trimmedLine = line.trim()
                
                when {
                    trimmedLine.startsWith("SMS Draft:", ignoreCase = true) -> {
                        currentSection = "sms"
                        smsDraft = trimmedLine.substringAfter("SMS Draft:").trim()
                    }
                    trimmedLine.startsWith("Guidance Steps:", ignoreCase = true) -> {
                        currentSection = "guidance"
                    }
                    trimmedLine.matches(Regex("^\\d+\\..*")) && currentSection == "guidance" -> {
                        guidanceSteps.add(trimmedLine.substringAfter(". ").trim())
                    }
                    trimmedLine.isNotEmpty() && currentSection == "sms" && smsDraft.isEmpty() -> {
                        smsDraft = trimmedLine
                    }
                }
            }
            
            // Fallback parsing if structured format not found
            if (smsDraft.isEmpty() && guidanceSteps.isEmpty()) {
                // Simple fallback - take first 160 chars as SMS, rest as guidance
                val words = rawResponse.split(" ")
                val smsWords = mutableListOf<String>()
                var charCount = 0
                
                for (word in words) {
                    if (charCount + word.length + 1 <= 160) {
                        smsWords.add(word)
                        charCount += word.length + 1
                    } else {
                        break
                    }
                }
                
                smsDraft = smsWords.joinToString(" ")
                guidanceSteps.add("Assess the situation carefully")
                guidanceSteps.add("Call emergency services if needed")
                guidanceSteps.add("Follow basic safety protocols")
            }
            
            val response = AiResponse(
                smsDraft = smsDraft.ifEmpty { "Emergency assistance needed. Please help." },
                guidanceSteps = guidanceSteps.ifEmpty { listOf("Stay calm", "Assess situation", "Seek help") }
            )
            
            Gson().toJson(response)
            
        } catch (e: Exception) {
            // Return default emergency response
            val defaultResponse = AiResponse(
                smsDraft = "Emergency situation requires assistance. Please help.",
                guidanceSteps = listOf(
                    "Stay calm and assess the situation",
                    "Ensure your immediate safety",
                    "Call emergency services if needed",
                    "Follow basic first aid if applicable"
                )
            )
            Gson().toJson(defaultResponse)
        }
    }

    /**
     * Clean up resources
     */
    fun cleanup() {
        scope.cancel()
        llmInference?.close()
    }
}

/**
 * Data class for structured AI response
 */
data class AiResponse(
    val smsDraft: String,
    val guidanceSteps: List<String>
)
