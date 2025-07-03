import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_test_provider.dart';

class ModelStatusCard extends ConsumerWidget {
  const ModelStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiTestProvider);

    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDescription;

    if (state.isLoading && !state.isModelInitialized) {
      statusColor = Colors.orange;
      statusIcon = Icons.downloading;
      statusText = 'Initializing Model';
      statusDescription = 'Downloading and loading the AI model (3.14 GB). This may take several minutes on first run.';
    } else if (state.isModelInitialized) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Model Ready';
      statusDescription = 'AI model is loaded and ready for emergency analysis.';
    } else if (state.error != null) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'Model Error';
      statusDescription = state.error!;
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.pending;
      statusText = 'Model Not Loaded';
      statusDescription = 'Waiting to initialize the AI model.';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (state.isLoading && !state.isModelInitialized)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}
