import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  // 1. Keep the key in one place (or better yet, use an .env file later)
  static const String _apiKey = ' ';

  // 2. Initialize the model
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: _apiKey,
  );

  // 3. Start a fresh chat session
  ChatSession startChat() {
    return _model.startChat();
  }

  // 4. Helper to send messages
  Future<String> getAiResponse(ChatSession session, String message) async {
    try {
      final response = await session.sendMessage(Content.text(message));
      return response.text ?? "I couldn't generate a response.";
    } catch (e) {
      return "Error connecting to AI: $e";
    }
  }
}