import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import '../providers/home_provider.dart';
import '../widgets/sms_dialog_widget.dart';
// import '../widgets/permission_dialog_widget.dart';
import '../main.dart'; // Import for VoiceRecorderWidget

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String inputMode = 'text'; // 'text' or 'voice'
  String? lastVoicePath;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final notifier = ref.read(homeProvider.notifier);

    // Show permission dialog on first launch
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (state.shouldShowPermissionDialog) {
    //     notifier.hidePermissionDialog();
    //     PermissionDialogWidget.showPermissionDialog(context);
    //   }
    // });

    // Show SMS dialog when AI response is ready and not yet shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.aiResponse != null && !state.smsDialogShown) {
        notifier.markSmsDialogShown();
        SmsDialogWidget.showSmsDialog(
          context,
          state.aiResponse!.smsDraft,
          () {
            // onDecline callback - do nothing for now
          },
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFF3E5F5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emergency,
                        color: Color(0xFFE53935),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aidy',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          Text(
                            'Your AI Emergency Companion',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5C6BC0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Restart button - only show when AI response is available
                    if (state.aiResponse != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => notifier.restartRequest(),
                          icon: const Icon(
                            Icons.refresh,
                            color: Color(0xFF3F51B5),
                            size: 24,
                          ),
                          tooltip: 'Start New Emergency Request',
                        ),
                      ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.aiResponse == null) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Describe the Emergency',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Toggle buttons for input mode
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: Icon(Icons.text_fields,
                                          color: inputMode == 'text'
                                              ? Colors.white
                                              : Colors.blue),
                                      label: Text('Text'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: inputMode == 'text'
                                            ? Colors.blue
                                            : Colors.white,
                                        foregroundColor: inputMode == 'text'
                                            ? Colors.white
                                            : Colors.blue,
                                        side: BorderSide(color: Colors.blue),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        // If currently in voice mode and there's a voice recording, show confirmation dialog
                                        if (inputMode == 'voice' &&
                                            lastVoicePath != null) {
                                          _showVoiceToTextDialog();
                                        } else {
                                          setState(() {
                                            inputMode = 'text';
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      icon: Icon(Icons.mic,
                                          color: inputMode == 'voice'
                                              ? Colors.white
                                              : Colors.blue),
                                      label: Text('Voice'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: inputMode == 'voice'
                                            ? Colors.blue
                                            : Colors.white,
                                        foregroundColor: inputMode == 'voice'
                                            ? Colors.white
                                            : Colors.blue,
                                        side: BorderSide(color: Colors.blue),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          inputMode = 'voice';
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Show text field or voice recorder based on inputMode ONLY
                              if (inputMode == 'text')
                                TextFormField(
                                  initialValue: state.textInput,
                                  onChanged: notifier.updateTextInput,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Describe the emergency situation (e.g., "My neighbor collapsed and is bleeding from a head wound.")',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE0E0E0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF3F51B5), width: 2),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF5F5F5),
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                              if (inputMode == 'voice')
                                VoiceRecorderWidget(
                                  onRecordingComplete: (String? path) {
                                    setState(() {
                                      lastVoicePath = path;
                                    });
                                    if (path != null) {
                                      notifier.updateTextInput(
                                          'Voice recording saved: ${path.split('/').last}');
                                      notifier.updateAudioPath(
                                          path); // <-- Ensure audioPath is set
                                    } else {
                                      notifier.updateTextInput('');
                                      notifier.updateAudioPath(
                                          null); // <-- Clear audioPath if recording is cleared
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),

                        // Image Preview (outside the card so it's always visible)
                        if (state.imagePath != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFE0E0E0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: state.imagePath != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: kIsWeb
                                              ? Image.network(
                                                  state.imagePath!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return const Icon(
                                                      Icons.error,
                                                      color: Colors.red,
                                                    );
                                                  },
                                                )
                                              : Image.file(
                                                  File(state.imagePath!),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return const Icon(
                                                      Icons.error,
                                                      color: Colors.red,
                                                    );
                                                  },
                                                ),
                                        )
                                      : const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    state.imagePath != null
                                        ? 'Image selected: ${state.imagePath!.split('/').last}'
                                        : 'Image selected',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    debugPrint(
                                        'X button pressed, clearing image');
                                    await notifier.clearImage();
                                    debugPrint(
                                        'Image cleared, current state: ${ref.read(homeProvider).imagePath}');
                                  },
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Add Image Button (above Analyze Emergency button)
                        ElevatedButton.icon(
                          onPressed: state.isLoading
                              ? null
                              : () => _showImageSourceDialog(context, notifier),
                          icon: const Icon(Icons.image),
                          label: const Text('Add Image'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Analyze Button - only show when no AI response
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: state.isLoading ||
                                    state.textInput.trim().isEmpty
                                ? null
                                : () => notifier.analyzeScenario(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            child: state.isLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Analyzing...'),
                                    ],
                                  )
                                : const Text(
                                    'Analyze Emergency',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        // Error Message - only show when no AI response
                        if (state.errorMessage != null &&
                            state.aiResponse == null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.errorMessage!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ], // End of conditional for input section and analyze button

                      // AI Response Display - show when AI response is available
                      if (state.aiResponse != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.medical_services,
                                      color: Color(0xFF4CAF50)),
                                  SizedBox(width: 8),
                                  Text(
                                    'Emergency Response Guidance',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...state.aiResponse!.guidanceSteps
                                  .asMap()
                                  .entries
                                  .map(
                                    (entry) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF4CAF50),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${entry.key + 1}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              entry.value,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVoiceToTextDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Clear Voice Recording?'),
            ],
          ),
          content: const Text(
            'If you switch to text mode, your voice recording will be cleared. Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog without action
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Clear the voice recording and switch to text mode
                setState(() {
                  lastVoicePath = null;
                  inputMode = 'text';
                });
                // Also clear the text input that was set by voice recording
                ref.read(homeProvider.notifier).updateTextInput('');
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear & Switch'),
            ),
          ],
        );
      },
    );
  }

  void _showImageSourceDialog(BuildContext context, HomeNotifier notifier) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  notifier.setImagePath();
                },
              ),
              if (!kIsWeb) // Only show camera option on mobile
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    notifier.setImagePath(source: ImageSource.camera);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
