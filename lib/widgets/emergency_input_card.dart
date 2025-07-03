import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_test_provider.dart';

class EmergencyInputCard extends ConsumerWidget {
  const EmergencyInputCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiTestProvider);
    final notifier = ref.read(aiTestProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_note,
                  color: Colors.red[700],
                ),
                const SizedBox(width: 8),
                Text(
                  'Emergency Situation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Text input field
            TextField(
              onChanged: notifier.updateTextInput,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe the emergency situation in detail...\n\nExample: "Person fell down stairs, conscious but complaining of back pain, cannot move legs"',
                border: OutlineInputBorder(),
              ),
              enabled: state.isModelInitialized,
            ),
            
            const SizedBox(height: 16),
            
            // Image section
            Row(
              children: [
                Icon(
                  Icons.camera_alt,
                  color: Colors.red[700],
                ),
                const SizedBox(width: 8),
                Text(
                  'Optional Image',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            if (state.selectedImage != null) ...[
              // Display selected image
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    state.selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Image selected',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green[600],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: notifier.removeImage,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[600],
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Image picker buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.isModelInitialized
                          ? notifier.pickImageFromCamera
                          : null,
                      icon: const Icon(Icons.camera),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.isModelInitialized
                          ? notifier.pickImageFromGallery
                          : null,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Quick emergency examples
            Text(
              'Quick Examples:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _QuickExampleChip(
                  text: 'Car accident',
                  onTap: () => notifier.updateTextInput('Car accident with possible injuries, person trapped in vehicle'),
                  enabled: state.isModelInitialized,
                ),
                _QuickExampleChip(
                  text: 'Heart attack',
                  onTap: () => notifier.updateTextInput('Person experiencing chest pain, difficulty breathing, possible heart attack'),
                  enabled: state.isModelInitialized,
                ),
                _QuickExampleChip(
                  text: 'Severe bleeding',
                  onTap: () => notifier.updateTextInput('Deep cut on arm with severe bleeding that won\'t stop'),
                  enabled: state.isModelInitialized,
                ),
                _QuickExampleChip(
                  text: 'Allergic reaction',
                  onTap: () => notifier.updateTextInput('Person having severe allergic reaction, swelling, difficulty breathing'),
                  enabled: state.isModelInitialized,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickExampleChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool enabled;

  const _QuickExampleChip({
    required this.text,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(text),
      onPressed: enabled ? onTap : null,
      backgroundColor: enabled ? Colors.red[50] : Colors.grey[100],
      side: BorderSide(
        color: enabled ? Colors.red[200]! : Colors.grey[300]!,
      ),
    );
  }
}
