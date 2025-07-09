package com.google.aidy

import android.content.Context
import android.graphics.BitmapFactory
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import org.json.JSONObject
import java.io.*
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import org.tensorflow.lite.Interpreter
import android.graphics.Bitmap

data class ModelInput(val text: String?, val image: ByteArray?, val audio: ByteArray?)

class AIEngine(private val context: Context) {
    private lateinit var tflite: Interpreter
    private val coroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    private fun loadModel() {
        val assetFileDescriptor = context.assets.openFd("gemma3n.tflite")
        val fileInputStream = FileInputStream(assetFileDescriptor.fileDescriptor)
        val fileChannel = fileInputStream.channel
        val startOffset = assetFileDescriptor.startOffset
        val declaredLength = assetFileDescriptor.declaredLength
        val modelBuffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
        tflite = Interpreter(modelBuffer)
    }

    // Placeholder for input preprocessing
    private fun preprocessInput(prompt: String, imagePath: String?, audioPath: String?): ModelInput {
        // Text: always present
        val textInput = prompt.takeIf { it.isNotBlank() }

        // Image: load as byte array if present
        val imageInput: ByteArray? = if (!imagePath.isNullOrBlank()) {
            try {
                val bitmap = BitmapFactory.decodeFile(imagePath)
                if (bitmap != null) {
                    // Example: convert bitmap to JPEG byte array (replace with model-specific preprocessing)
                    val stream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 90, stream)
                    stream.toByteArray()
                } else null
            } catch (e: Exception) {
                null
            }
        } else null

        // Audio: load as byte array if present
        val audioInput: ByteArray? = if (!audioPath.isNullOrBlank()) {
            try {
                val file = File(audioPath)
                if (file.exists()) file.readBytes() else null
            } catch (e: Exception) {
                null
            }
        } else null

        return ModelInput(textInput, imageInput, audioInput)
    }

    // Placeholder for output postprocessing
    private fun postprocessOutput(output: Any): String {
        // Assume output is a String array: [smsDraft, guidanceStepsJoined]
        val arr = output as Array<String>
        val smsDraft = arr[0]
        val guidanceSteps = arr[1].split("\n").map { it.trim() }.filter { it.isNotEmpty() }
        val json = JSONObject()
        json.put("smsDraft", smsDraft)
        json.put("guidanceSteps", guidanceSteps)
        return json.toString()
    }

    // Placeholder for running inference
    private fun runTFLiteInference(input: Any): Any {
        // Placeholder: run inference using the TFLite Interpreter
        // Assume input is a String and output is a String array of size 2
        val inputArray = arrayOf(input as String)
        val outputArray = Array(1) { Array(2) { "" } } // 1 batch, 2 outputs
        tflite.run(inputArray, outputArray)
        return outputArray[0]
    }

    fun initializeModel(callback: (Boolean, String?) -> Unit) {
        coroutineScope.launch {
            try {
                loadModel()
                withContext(Dispatchers.Main) {
                    callback(true, null)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(false, e.message)
                }
            }
        }
    }

    fun runGemmaInference(prompt: String, imagePath: String?, audioPath: String?, callback: (Boolean, String?) -> Unit) {
        coroutineScope.launch {
            try {
                val input = preprocessInput(prompt, imagePath, audioPath)
                val output = runTFLiteInference(input)
                val resultJson = postprocessOutput(output)
                withContext(Dispatchers.Main) {
                    callback(true, resultJson)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    callback(false, e.message)
                }
            }
        }
    }
} 