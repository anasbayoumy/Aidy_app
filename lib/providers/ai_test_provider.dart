import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ai_response.dart';
import '../services/ai_service.dart';

// State for the AI test functionality
class AiTestState {
  final bool isLoading;
  final bool isModelInitialized;
  final String? error;
  final AiResponse? lastResponse;
  final String textInput;
  final File? selectedImage;

  const AiTestState({
    this.isLoading = false,
    this.isModelInitialized = false,
    this.error,
    this.lastResponse,
    this.textInput = '',
    this.selectedImage,
  });

  AiTestState copyWith({
    bool? isLoading,
    bool? isModelInitialized,
    String? error,
    AiResponse? lastResponse,
    String? textInput,
    File? selectedImage,
    bool clearError = false,
    bool clearResponse = false,
    bool clearImage = false,
  }) {
    return AiTestState(
      isLoading: isLoading ?? this.isLoading,
      isModelInitialized: isModelInitialized ?? this.isModelInitialized,
      error: clearError ? null : (error ?? this.error),
      lastResponse: clearResponse ? null : (lastResponse ?? this.lastResponse),
      textInput: textInput ?? this.textInput,
      selectedImage: clearImage ? null : (selectedImage ?? this.selectedImage),
    );
  }
}

// Notifier for managing AI test state
class AiTestNotifier extends StateNotifier<AiTestState> {
  AiTestNotifier() : super(const AiTestState());

  final ImagePicker _imagePicker = ImagePicker();

  /// Initialize the AI model
  Future<void> initializeModel() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final success = await AiService.initGemmaModel();
      state = state.copyWith(
        isLoading: false,
        isModelInitialized: success,
        error: success ? null : 'Failed to initialize AI model',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isModelInitialized: false,
        error: 'Error initializing model: $e',
      );
    }
  }

  /// Run inference with current input
  Future<void> runInference() async {
    if (state.textInput.trim().isEmpty) {
      state = state.copyWith(error: 'Please enter an emergency situation description');
      return;
    }

    if (!state.isModelInitialized) {
      state = state.copyWith(error: 'Model not initialized. Please wait for initialization to complete.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await AiService.runGemmaInference(
        state.textInput,
        imagePath: state.selectedImage?.path,
      );

      if (response != null) {
        state = state.copyWith(
          isLoading: false,
          lastResponse: response,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to get response from AI model',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error during inference: $e',
      );
    }
  }

  /// Update text input
  void updateTextInput(String text) {
    state = state.copyWith(textInput: text, clearError: true);
  }

  /// Pick an image from gallery
  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        state = state.copyWith(selectedImage: File(image.path));
      }
    } catch (e) {
      state = state.copyWith(error: 'Error picking image: $e');
    }
  }

  /// Pick an image from camera
  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        state = state.copyWith(selectedImage: File(image.path));
      }
    } catch (e) {
      state = state.copyWith(error: 'Error taking photo: $e');
    }
  }

  /// Remove selected image
  void removeImage() {
    state = state.copyWith(clearImage: true);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear last response
  void clearResponse() {
    state = state.copyWith(clearResponse: true);
  }

  /// Reset all state
  void reset() {
    state = const AiTestState();
  }
}

// Provider for the AI test functionality
final aiTestProvider = StateNotifierProvider<AiTestNotifier, AiTestState>((ref) {
  return AiTestNotifier();
});
