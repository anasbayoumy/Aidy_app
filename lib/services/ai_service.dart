import '../models/ai_response.dart';

class MockAiService {
  static Future<AiResponse> runMockInference(String prompt,
      {String? imagePath}) async {
    // Simulate processing time
    await Future.delayed(const Duration(seconds: 2));

    // Mock SMS draft with placeholder for coordinates
    final smsDraft =
        "Emergency. Possible medical situation. Details: $prompt. Location: [LATITUDE], [LONGITUDE]";

    // Mock first-aid guidance steps
    final guidanceSteps = [
      "Assess scene safety - ensure the area is safe for you and the victim",
      "Check for responsiveness - gently tap and ask if they're okay",
      "Call emergency services immediately - dial 911",
      "Begin CPR if needed - if person is unresponsive and not breathing",
      "Control bleeding - apply direct pressure with clean cloth",
      "Stay with victim - provide comfort and monitor until help arrives"
    ];

    return AiResponse(
      smsDraft: smsDraft,
      guidanceSteps: guidanceSteps,
    );
  }
}
