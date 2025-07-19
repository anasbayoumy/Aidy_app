# Aidy - Your On-Device AI Emergency Companion

**Aidy** is an intelligent emergency response mobile application that leverages on-device AI to provide immediate assistance during critical situations. Built with Flutter and powered by Google's Gemma AI model, Aidy helps users quickly communicate emergencies and receive real-time first-aid guidance.

## Key Features

### Intelligent Emergency Detection
- **Voice Input**: Record voice descriptions of emergency situations using speech-to-text
- **Image Analysis**: Take photos of emergency scenes for AI-powered situation assessment
- **Text Input**: Type emergency descriptions directly into the app

### AI-Powered Emergency Response
- **Smart SMS Generation**: Automatically creates emergency SMS messages with situation details and location
- **First-Aid Guidance**: Provides step-by-step first-aid instructions tailored to the specific emergency
- **On-Device Processing**: Uses Google's Gemma 3B AI model running locally for privacy and offline capability

### Emergency Communication
- **Automatic Location Integration**: Includes GPS coordinates in emergency messages
- **Quick SMS Dispatch**: One-tap sending of emergency messages to contacts
- **Emergency Services Integration**: Direct connection to 911 emergency services

### Specialized Emergency Scenarios
The AI recognizes and provides tailored responses for:
- Car Accidents: Traffic safety, injury assessment, information collection
- Heart Attacks: CPR guidance, symptom recognition, immediate response
- Fire Emergencies: Evacuation procedures, safety protocols
- Fall Injuries: Spinal safety, movement restrictions, assessment
- Breathing Difficulties: Airway management, positioning, monitoring
- General Medical Emergencies: Basic first-aid, vital signs, emergency protocols

## Technical Architecture

### Frontend
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **UI**: Material Design 3 with custom emergency-focused interface
- **Platform**: Android (API 26+)

### AI Engine
- **Model**: Google Gemma 3B (gemma-3n-E2B-it-int4.task)
- **Runtime**: TensorFlow Lite with MediaPipe Tasks
- **Processing**: On-device inference for privacy and offline capability
- **Model Size**: Optimized INT4 quantization for mobile deployment

### Core Services
- **Speech Recognition**: Real-time voice-to-text conversion
- **Location Services**: GPS integration for emergency positioning
- **Image Processing**: Camera integration for visual emergency assessment
- **Model Management**: Automatic model download and caching

## Getting Started

### Prerequisites
- Flutter SDK (3.5.0+)
- Android Studio with Android SDK (API 26+)
- Kotlin support
- Device with at least 4GB RAM (for AI model)

### Installation

1. Clone the repository
   `
   git clone https://github.com/anasbayoumy/Aidy_app.git
   cd aidy
   `

2. Install dependencies
   `
   flutter pub get
   `

3. Build and run
   `
   flutter run
   `

### First Launch
On first launch, Aidy will:
1. Request necessary permissions (microphone, camera, location, SMS)
2. Download the Gemma AI model (~2GB) - requires internet connection
3. Initialize the AI engine for on-device processing

## Privacy & Security

- **On-Device Processing**: All AI inference happens locally - no data sent to external servers
- **Offline Capability**: Core emergency features work without internet connection
- **Minimal Permissions**: Only requests essential permissions for emergency functionality
- **Local Storage**: Emergency data and AI models stored securely on device

## Permissions Required

- **Microphone**: Voice recording for emergency descriptions
- **Location**: GPS coordinates for emergency services
- **Camera**: Photo capture for emergency scene analysis
- **SMS**: Sending emergency messages to contacts
- **Storage**: Caching AI model and temporary files

## Use Cases

### Personal Emergencies
- Medical emergencies (heart attack, stroke, severe injury)
- Accidents (car crashes, falls, burns)
- Breathing difficulties or choking
- Severe allergic reactions

### Witnessed Emergencies
- Helping others in emergency situations
- Providing first-aid guidance for bystanders
- Coordinating emergency response

### Emergency Preparedness
- Learning first-aid procedures
- Understanding emergency protocols
- Quick access to emergency services

## Important Disclaimer

**Aidy is designed to assist in emergency situations but should not replace professional medical training or emergency services. Always call 911 or your local emergency number for serious emergencies. The AI guidance provided is for informational purposes and should not substitute professional medical advice.**

## Emergency Services

- **United States**: 911
- **International**: Contact your local emergency services
- **Poison Control**: 1-800-222-1222 (US)

---

**Aidy - Because every second counts in an emergency.**
