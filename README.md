# Aidy - Your On-Device AI Emergency Companion

## Table of Contents
1. [Project Overview](#project-overview)
2. [Core Technologies & Architecture](#core-technologies--architecture)
3. [Key Features](#key-features)
4. [Technical Architecture & Flow](#technical-architecture--flow)
5. [Build Process & Setup](#build-process--setup)
6. [Running the App](#running-the-app)
7. [Production Considerations](#production-considerations)

## Project Overview

**Aidy** is an innovative mobile emergency companion that leverages on-device AI to provide rapid, intelligent assistance during critical situations. The application processes multimodal input (text and optional images) to generate structured emergency responses including SMS drafts and first-aid guidance.

### Mission
Aidy's mission is to provide rapid, intelligent assistance during emergencies using cutting-edge on-device AI technology, ensuring privacy, offline capability, and low latency through local AI processing.

### Key Advantages
- **Privacy-First**: All AI processing happens locally on the device
- **Offline Capability**: Works without internet connectivity once model is downloaded
- **Low Latency**: Immediate responses through local inference
- **Multimodal Input**: Supports both text descriptions and optional image analysis

## Core Technologies & Architecture

### Frontend (User Interface)
- **Flutter (Dart)** for cross-platform UI (Android/iOS focus)
- **Flutter Riverpod** for state management
- **Material Design 3** for modern, accessible UI

### On-Device AI Engine (Backend - Kotlin Focus)
- **Android Kotlin** implementation
- **MediaPipe LLM Inference SDK** for AI processing
- **OkHttp** for model downloading
- **Kotlin Coroutines** for asynchronous operations

### AI Model
- **Gemma 3n E2B LiteRT** (approximately 3.14 GB)
- Optimized for on-device efficiency
- Dynamic download from local HTTP server

### Inter-Layer Communication
- **Flutter MethodChannel** (`com.google.aidy/ai`) for seamless communication between Flutter UI and native Android AI engine

## Key Features

### 1. Multimodal Input
- Text-based emergency situation descriptions
- Optional image capture/selection for visual context
- Quick example scenarios for rapid input

### 2. On-Device AI Inference
- Gemma 3n model runs locally for privacy
- Offline capability after initial download
- Low latency responses

### 3. Structured Output
- **SMS Draft**: Concise emergency message (≤160 characters)
- **Guidance Steps**: Step-by-step first aid or safety instructions

### 4. User-Friendly Interface
- Simple, intuitive Flutter UI
- Emergency-focused design with red color scheme
- Copy-to-clipboard functionality for easy sharing

### 5. Efficient Model Management
- Dynamic model download from `http://192.168.1.5:8000/gemma3n.task`
- Storage in device's internal storage (`context.filesDir`)
- One-time download with local persistence

## Technical Architecture & Flow

### A. Model Acquisition and Storage (Dynamic Download)

The `gemma3n.task` file is hosted on a local HTTP server at `http://192.168.1.5:8000/gemma3n.task`. The Kotlin `AIEngine.kt` handles:

1. **Download Check**: Verifies if model exists in `context.filesDir`
2. **Download Process**: If not present, downloads from server using OkHttp
3. **Storage**: Saves to internal storage for future use
4. **Validation**: Ensures successful download before proceeding

### B. Application Flow (Flutter ↔ Kotlin)

#### App Launch (Flutter `main.dart`)
1. Flutter UI initializes with Riverpod state management
2. `AiTestNotifier` calls `AiService.initGemmaModel()`
3. MethodChannel communication initiated

#### Model Initialization (Kotlin `AIEngine.kt`)
```kotlin
fun initializeModel(callback: (Boolean, String) -> Unit) {
    scope.launch {
        // Check if model exists locally
        val modelFile = File(context.filesDir, MODEL_FILENAME)
        
        if (!modelFile.exists()) {
            // Download model from server
            val downloadSuccess = downloadModel(modelFile)
            if (!downloadSuccess) {
                callback(false, "Failed to download model")
                return@launch
            }
        }
        
        // Create LLM inference options pointing to local file
        val options = LlmInferenceOptions.builder()
            .setModelPath(modelFile.absolutePath)
            .setMaxTokens(1024)
            .setTemperature(0.7f)
            .build()
        
        // Initialize the model
        llmInference = LlmInference.createFromOptions(context, options)
        callback(true, "Model loaded successfully")
    }
}
```

## Build Process & Setup

### Prerequisites
- **Flutter SDK** (3.24.6 or newer)
- **Android Studio** with Android SDK
- **Kotlin** 1.9.0+
- **Kaggle API** (for initial model acquisition)

### Step 1: Acquire Model File
```bash
# Use kagglehub to download the model
pip install kagglehub
python -c "import kagglehub; kagglehub.model_download('google/gemma-3/tfLite/2b-it', 'gemma3n.task')"

# Host the model on local server
python -m http.server 8000 --directory /path/to/model/directory
# Model should be accessible at http://192.168.1.5:8000/gemma3n.task
```

### Step 2: Project Structure
```
android/app/libs/
├── tasks-genai-0.10.25.aar      # MediaPipe GenAI AAR
└── tasks-vision-0.10.21.aar     # MediaPipe Vision AAR

android/app/model_allowlist.json  # Model allowlist configuration
android/app/src/main/kotlin/com/google/aidy/
├── MainActivity.kt               # Flutter Activity with MethodChannel
└── AIEngine.kt                   # Core AI inference engine
```

### Step 3: Build Commands
```bash
# Install dependencies
flutter pub get

# Generate code
flutter pub run build_runner build

# Build for Android
flutter build apk --release
```

## Running the App

### Local Development & Testing

1. **Connect Device/Start Emulator**
   - Physical device recommended for better performance
   - Emulator may have limitations with large AI models

2. **Ensure Model Server is Running**
   ```bash
   # Start local HTTP server hosting the model
   python -m http.server 8000 --directory /path/to/model
   # Verify accessibility at http://192.168.1.5:8000/gemma3n.task
   ```

3. **Build and Run**
   ```bash
   flutter run --debug
   ```

4. **Grant Permissions**
   - Allow camera access for image capture
   - Allow storage permissions for file access

5. **Initial Model Download & Loading**
   - First launch will download 3.14 GB model
   - Download time depends on network speed
   - Model loading may take 30-60 seconds
   - Progress shown in app's Model Status Card

6. **Test Inference**
   - Enter emergency situation description
   - Optionally add image for context
   - Tap "Analyze Scenario" button
   - Review structured SMS draft and guidance steps

## Production Considerations & Future Enhancements

### Security Enhancements
- **HTTPS Model Distribution**: Replace HTTP with HTTPS for secure downloads
- **Model Checksums**: Verify file integrity with SHA-256 checksums
- **Certificate Pinning**: Implement SSL certificate pinning

### Performance Optimization
- **Adaptive Model Sizing**: Choose model variants based on device capabilities
- **Background Processing**: Pre-load models during idle time
- **Memory Management**: Implement smart model unloading/reloading

### Advanced Features
- **Voice Input**: Speech-to-text for hands-free operation
- **Location Integration**: GPS coordinates in emergency messages
- **Direct SMS Sending**: Automatic emergency contact messaging
- **Offline Maps**: Emergency services location mapping

---

## Architecture Summary

Aidy represents a sophisticated approach to emergency AI assistance, combining:
- **Flutter's cross-platform capabilities** for consistent UX
- **Kotlin's powerful native integration** for complex AI processing
- **MediaPipe's optimized inference** for efficient on-device AI
- **Thoughtful UX design** for emergency scenarios

The dynamic model distribution strategy ensures privacy while maintaining flexibility for updates and testing. The structured output format (SMS + Guidance) provides immediately actionable information for emergency responders and civilians alike. embedded in an offline emergency app companion

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
#   A i d y _ a p p 
 
 