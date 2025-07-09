import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class SmsDialogWidget {
  static Future<void> showSmsDialog(
    BuildContext context,
    String smsDraft,
    VoidCallback onDecline,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.emergency, color: Color(0xFFE53935)),
              const SizedBox(width: 8),
              Expanded(
                child: const Text('Confirm Emergency SMS'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This message will be sent to emergency services with your precise location:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Text(
                  smsDraft,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDecline();
              },
              child: const Text('Decline'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _sendSms(smsDraft, context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _sendSms(String smsDraft, BuildContext context) async {
    try {
      // Mock SMS sending for now
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Mock SMS sent to ${AppConstants.emergencyNumber}: $smsDraft'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending SMS: $e'),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    }
  }
}
