import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/ai_response.dart';
import 'package:flutter/foundation.dart';

class AiService {
  static const platform = MethodChannel('com.google.aidy/ai');
  static bool _modelInitialized = false;

  /// Initialize the Gemma model
  static Future<bool> initGemmaModel() async {
    if (_modelInitialized) return true;

    try {
      await platform.invokeMethod('initGemma');
      debugPrint('Gemma model initialized successfully');
      _modelInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Error initializing Gemma model: $e');
      return false;
    }
  }

  /// Run inference with the Gemma model using text and optional image
  static Future<AiResponse> runGemmaInference(String prompt,
      {String? imagePath}) async {
    if (!_modelInitialized) {
      final initialized = await initGemmaModel();
      if (!initialized) {
        throw Exception('Failed to initialize AI model');
      }
    }

    try {
      debugPrint(
          'Running Gemma inference with prompt: $prompt, imagePath: $imagePath');

      final Map<String, dynamic> arguments = {
        'textQuery': prompt,
      };

      if (imagePath != null) {
        arguments['imagePath'] = imagePath;
      }

      try {
        final String result =
            await platform.invokeMethod('runGemmaInference', arguments);
        debugPrint('Received raw result from native: $result');

        final Map<String, dynamic> jsonResponse = json.decode(result);
        return AiResponse.fromJson(jsonResponse);
      } catch (e) {
        debugPrint('Method channel inference failed: $e');

        // Fallback to simulated response if method channel fails
        final smsDraft =
            "Emergency! Need help with: ${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}... Location: [LATITUDE], [LONGITUDE]";

        final guidanceSteps = [
          "Assess the situation carefully",
          "Ensure your own safety first",
          "Call emergency services at 911",
          "If safe, provide basic first aid: ${prompt.substring(0, prompt.length > 20 ? 20 : prompt.length)}...",
          "Stay with the victim until help arrives",
          "Share your exact location with emergency responders"
        ];

        return AiResponse(
          smsDraft: smsDraft,
          guidanceSteps: guidanceSteps,
        );
      }
    } catch (e) {
      debugPrint('Error running Gemma inference: $e');
      throw Exception('Failed to process with AI: $e');
    }
  }
}

/// Mock implementation for testing purposes
class MockAiService {
  static Future<AiResponse> runMockInference(String prompt,
      {String? imagePath}) async {
    // Simulate processing time
    await Future.delayed(const Duration(seconds: 2));

    // Mock SMS draft with placeholder for coordinates
    final smsDraft =
        "Emergency. Possible medical situation. Details: $prompt. Location: [LATITUDE], [LONGITUDE]";

    // Mock first-aid guidance steps
    final guidanceSteps = [
      "Assess scene safety - ensure the area is safe for you and the victim",
      "Check for responsiveness - gently tap and ask if they're okay",
      "Call emergency services immediately - dial 911",
      "Begin CPR if needed - if person is unresponsive and not breathing",
      "Control bleeding - apply direct pressure with clean cloth",
      "Stay with victim - provide comfort and monitor until help arrives"
    ];

    return AiResponse(
      smsDraft: smsDraft,
      guidanceSteps: guidanceSteps,
    );
  }
}
