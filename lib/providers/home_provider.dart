import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import '../models/ai_response.dart';
import '../services/ai_service.dart';
import '../services/location_service.dart';

class HomeState {
  final String textInput;
  final String? imagePath;
  final bool isLoading;
  final AiResponse? aiResponse;
  final bool isListening;
  final String? errorMessage;
  final bool permissionsRequested;
  final bool smsDialogShown;
  final bool shouldShowPermissionDialog;
  final LocationData? currentLocation;
  final bool isLocationLoading;

  HomeState({
    this.textInput = '',
    this.imagePath,
    this.isLoading = false,
    this.aiResponse,
    this.isListening = false,
    this.errorMessage,
    this.permissionsRequested = false,
    this.smsDialogShown = false,
    this.shouldShowPermissionDialog = false,
    this.currentLocation,
    this.isLocationLoading = false,
  });

  HomeState copyWith({
    String? textInput,
    String? imagePath,
    bool? isLoading,
    AiResponse? aiResponse,
    bool? isListening,
    String? errorMessage,
    bool? permissionsRequested,
    bool? smsDialogShown,
    bool? shouldShowPermissionDialog,
    LocationData? currentLocation,
    bool? isLocationLoading,
  }) {
    return HomeState(
      textInput: textInput ?? this.textInput,
      imagePath: imagePath ?? this.imagePath,
      isLoading: isLoading ?? this.isLoading,
      aiResponse: aiResponse ?? this.aiResponse,
      isListening: isListening ?? this.isListening,
      errorMessage: errorMessage ?? this.errorMessage,
      permissionsRequested: permissionsRequested ?? this.permissionsRequested,
      smsDialogShown: smsDialogShown ?? this.smsDialogShown,
      shouldShowPermissionDialog:
          shouldShowPermissionDialog ?? this.shouldShowPermissionDialog,
      currentLocation: currentLocation ?? this.currentLocation,
      isLocationLoading: isLocationLoading ?? this.isLocationLoading,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final ImagePicker _imagePicker = ImagePicker();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

  HomeNotifier() : super(HomeState()) {
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait a moment to ensure the app is fully loaded
    await Future.delayed(const Duration(milliseconds: 500));

    if (!kIsWeb && !state.permissionsRequested) {
      // Show permission dialog first
      state = state.copyWith(shouldShowPermissionDialog: true);
      // Wait a bit more for the dialog to be triggered from UI
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      state = state.copyWith(permissionsRequested: true);
      return;
    }

    if (state.permissionsRequested) return;

    try {
      debugPrint('Requesting permissions...');

      // Request all permissions at once
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.camera,
        Permission.storage,
        Permission.photos,
        Permission.location,
        Permission.locationWhenInUse,
      ].request();

      state = state.copyWith(permissionsRequested: true);

      // Check microphone permission specifically for speech
      final micStatus = statuses[Permission.microphone];
      if (micStatus != null && micStatus.isGranted) {
        debugPrint('Microphone permission granted, initializing speech...');
        await _initializeSpeech();
      } else {
        debugPrint('Microphone permission denied: $micStatus');
        state = state.copyWith(
          errorMessage: 'Microphone permission is required for voice input.',
        );
      }

      // Check other permissions
      final cameraStatus = statuses[Permission.camera];
      if (cameraStatus != null && !cameraStatus.isGranted) {
        debugPrint('Camera permission denied: $cameraStatus');
      }

      // Check location permission
      final locationStatus = statuses[Permission.location];
      final locationWhenInUseStatus = statuses[Permission.locationWhenInUse];
      if ((locationStatus != null && locationStatus.isGranted) ||
          (locationWhenInUseStatus != null &&
              locationWhenInUseStatus.isGranted)) {
        debugPrint('Location permission granted, getting current location...');
        await _getCurrentLocation();
      } else {
        debugPrint(
            'Location permission denied - location: $locationStatus, whenInUse: $locationWhenInUseStatus');
      }
    } catch (e) {
      debugPrint('Failed to request permissions: $e');
      state = state.copyWith(
        errorMessage:
            'Failed to request permissions. Please check app settings.',
        permissionsRequested: true,
      );
    }
  }

  Future<void> _initializeSpeech() async {
    if (kIsWeb) {
      debugPrint('Speech recognition not supported on web');
      return;
    }

    try {
      debugPrint('Initializing speech recognition...');

      // Check if microphone permission is still granted
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        debugPrint('Microphone permission not granted');
        state = state.copyWith(
          errorMessage: 'Microphone permission required for voice input.',
        );
        return;
      }

      _speechEnabled = await _speechToText.initialize(
        onError: (errorNotification) {
          debugPrint('Speech error: ${errorNotification.errorMsg}');
          state = state.copyWith(
            errorMessage: 'Voice recognition error. Please try again.',
            isListening: false,
          );
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            state = state.copyWith(isListening: false);
          }
        },
        debugLogging: true,
      );

      debugPrint('Speech initialized successfully: $_speechEnabled');

      if (!_speechEnabled) {
        state = state.copyWith(
          errorMessage:
              'Voice recognition initialization failed. Please restart the app.',
        );
      }
    } catch (e) {
      debugPrint('Speech initialization failed: $e');
      _speechEnabled = false;
      state = state.copyWith(
        errorMessage: 'Voice recognition not available on this device.',
      );
    }
  }

  void updateTextInput(String text) {
    state = state.copyWith(textInput: text);
  }

  Future<void> setImagePath({ImageSource? source}) async {
    try {
      ImageSource imageSource = source ?? ImageSource.gallery;

      // On web, camera might not be available, so default to gallery
      if (kIsWeb && imageSource == ImageSource.camera) {
        imageSource = ImageSource.gallery;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: imageSource,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        state = state.copyWith(imagePath: image.path);
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to select image: $e',
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    if (kIsWeb) {
      debugPrint('Location services not supported on web');
      return;
    }

    try {
      state = state.copyWith(isLocationLoading: true);
      debugPrint('Getting current location...');

      // Check if location services are enabled
      bool serviceEnabled = await LocationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        state = state.copyWith(
          isLocationLoading: false,
          errorMessage:
              'Location services are disabled. Please enable them in device settings.',
        );
        return;
      }

      // Check and request location permission
      bool hasPermission = await LocationService.hasLocationPermission();
      if (!hasPermission) {
        hasPermission = await LocationService.requestLocationPermission();
        if (!hasPermission) {
          debugPrint('Location permissions are denied');
          state = state.copyWith(
            isLocationLoading: false,
            errorMessage: 'Location permissions are denied.',
          );
          return;
        }
      }

      // Get current position using our location service
      LocationData? position = await LocationService.getCurrentLocation();

      if (position != null) {
        debugPrint(
            'Location obtained: ${position.latitude}, ${position.longitude}');
        state = state.copyWith(
          currentLocation: position,
          isLocationLoading: false,
        );
      } else {
        state = state.copyWith(
          isLocationLoading: false,
          errorMessage: 'Failed to get current location.',
        );
      }
    } catch (e) {
      debugPrint('Failed to get location: $e');
      state = state.copyWith(
        isLocationLoading: false,
        errorMessage: 'Failed to get current location: $e',
      );
    }
  }

  void clearImage() {
    state = state.copyWith(imagePath: null);
  }

  Future<void> toggleListening() async {
    if (kIsWeb) {
      state = state.copyWith(
        errorMessage:
            'Voice input not available on web. Please type your emergency description.',
      );
      return;
    }

    // Clear any previous error messages
    state = state.copyWith(errorMessage: null);

    if (!_speechEnabled) {
      debugPrint('Speech not enabled, trying to reinitialize...');
      await _initializeSpeech();
      if (!_speechEnabled) {
        state = state.copyWith(
          errorMessage:
              'Voice recognition not available. Please check microphone permissions in settings.',
        );
        return;
      }
    }

    try {
      if (state.isListening) {
        debugPrint('Stopping speech recognition');
        await _speechToText.stop();
        state = state.copyWith(isListening: false);
      } else {
        debugPrint('Starting speech recognition');

        // Check if speech to text is available
        bool available = await _speechToText.hasPermission;
        if (!available) {
          state = state.copyWith(
            errorMessage:
                'Microphone permission not available. Please check app settings.',
          );
          return;
        }

        state = state.copyWith(isListening: true);

        bool success = await _speechToText.listen(
          onResult: (result) {
            debugPrint(
                'Speech result: ${result.recognizedWords}, final: ${result.finalResult}');

            if (result.finalResult && result.recognizedWords.isNotEmpty) {
              // Append to existing text if any, otherwise replace
              String newText = state.textInput.isEmpty
                  ? result.recognizedWords
                  : '${state.textInput} ${result.recognizedWords}';

              state = state.copyWith(
                textInput: newText,
                isListening: false,
              );
              debugPrint('Updated text input: $newText');
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          localeId: 'en_US',
        );

        if (!success) {
          state = state.copyWith(
            isListening: false,
            errorMessage:
                'Could not start voice recognition. Please try again.',
          );
        }
      }
    } catch (e) {
      debugPrint('Speech error: $e');
      state = state.copyWith(
        errorMessage:
            'Voice recognition failed. Please try again or type your emergency.',
        isListening: false,
      );
    }
  }

  Future<void> analyzeScenario() async {
    if (state.textInput.trim().isEmpty) {
      state = state.copyWith(
          errorMessage: 'Please describe the emergency situation');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Use real location if available, otherwise fallback to default
      double latitude = 40.7128; // Default to NYC
      double longitude = -74.0060;

      if (state.currentLocation != null) {
        latitude = state.currentLocation!.latitude;
        longitude = state.currentLocation!.longitude;
        debugPrint('Using real location: $latitude, $longitude');
      } else {
        debugPrint('Using fallback location: $latitude, $longitude');
        // Try to get location one more time if not available
        if (!kIsWeb) {
          await _getCurrentLocation();
          if (state.currentLocation != null) {
            latitude = state.currentLocation!.latitude;
            longitude = state.currentLocation!.longitude;
            debugPrint('Got location on retry: $latitude, $longitude');
          }
        }
      }

      // Run AI inference (still mocked as requested)
      final aiResponse = await MockAiService.runMockInference(state.textInput,
          imagePath: state.imagePath);

      // Inject coordinates into SMS draft
      final smsDraftWithLocation = aiResponse.smsDraft
          .replaceAll('[LATITUDE]', latitude.toStringAsFixed(6))
          .replaceAll('[LONGITUDE]', longitude.toStringAsFixed(6));

      state = state.copyWith(
        aiResponse: AiResponse(
          smsDraft: smsDraftWithLocation,
          guidanceSteps: aiResponse.guidanceSteps,
        ),
        isLoading: false,
        smsDialogShown: false, // Reset to allow dialog to show
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to analyze scenario: $e',
      );
    }
  }

  void clearState() {
    state = HomeState(
      permissionsRequested: state.permissionsRequested,
      currentLocation: state.currentLocation,
    );
  }

  void restartRequest() {
    state = HomeState(
      permissionsRequested: state.permissionsRequested,
      currentLocation: state.currentLocation,
    );
  }

  void markSmsDialogShown() {
    state = state.copyWith(smsDialogShown: true);
  }

  void hidePermissionDialog() {
    state = state.copyWith(shouldShowPermissionDialog: false);
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier();
});
