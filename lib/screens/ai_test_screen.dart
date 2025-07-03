import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_test_provider.dart';
import '../widgets/emergency_input_card.dart';
import '../widgets/response_display_card.dart';
import '../widgets/model_status_card.dart';

class AiTestScreen extends ConsumerStatefulWidget {
  const AiTestScreen({super.key});

  @override
  ConsumerState<AiTestScreen> createState() => _AiTestScreenState();
}

class _AiTestScreenState extends ConsumerState<AiTestScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the model when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiTestProvider.notifier).initializeModel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiTestProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aidy - Emergency AI'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(aiTestProvider.notifier).initializeModel();
            },
            tooltip: 'Reinitialize Model',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome message
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.medical_services,
                      size: 48,
                      color: Colors.red[700],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Emergency AI Companion',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Describe your emergency situation and get instant AI-powered assistance with SMS drafts and guidance steps.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Model status card
            const ModelStatusCard(),
            
            const SizedBox(height: 16),
            
            // Emergency input card
            const EmergencyInputCard(),
            
            const SizedBox(height: 16),
            
            // Response display card
            if (state.lastResponse != null || state.error != null)
              const ResponseDisplayCard(),
            
            const SizedBox(height: 80), // Extra space for better scrolling
          ],
        ),
      ),
      
      // Floating action button for quick emergency call
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isModelInitialized && state.textInput.isNotEmpty
            ? () => ref.read(aiTestProvider.notifier).runInference()
            : null,
        backgroundColor: state.isModelInitialized && state.textInput.isNotEmpty
            ? Colors.red[700]
            : Colors.grey,
        icon: state.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.emergency),
        label: Text(state.isLoading ? 'Analyzing...' : 'Analyze Scenario'),
      ),
    );
  }
}
