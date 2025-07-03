import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/ai_response.dart';

class AiService {
  static const MethodChannel _channel = MethodChannel('com.google.aidy/ai');

  /// Initialize the Gemma model
  /// This will download the model from the server if not present locally
  static Future<bool> initGemmaModel() async {
    try {
      final result = await _channel.invokeMethod('initGemma');
      debugPrint('Model initialization result: $result');
      return true;
    } on PlatformException catch (e) {
      debugPrint('Error initializing model: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error: $e');
      return false;
    }
  }

  /// Run inference with the Gemma model
  /// [textQuery] - The emergency situation description
  /// [imagePath] - Optional image file path for multimodal input
  static Future<AiResponse?> runGemmaInference(
    String textQuery, {
    String? imagePath,
  }) async {
    try {
      final arguments = <String, dynamic>{
        'textQuery': textQuery,
        if (imagePath != null) 'imagePath': imagePath,
      };

      final result = await _channel.invokeMethod('runGemmaInference', arguments);
      
      if (result is String) {
        final jsonData = json.decode(result) as Map<String, dynamic>;
        return AiResponse.fromJson(jsonData);
      }
      
      return null;
    } on PlatformException catch (e) {
      debugPrint('Error running inference: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Unexpected error during inference: $e');
      return null;
    }
  }

  /// Check if the device can run the AI model efficiently
  static Future<bool> checkDeviceCapabilities() async {
    try {
      // Basic device capability check
      // In a production app, you might check RAM, CPU, etc.
      return !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    } catch (e) {
      return false;
    }
  }
}
