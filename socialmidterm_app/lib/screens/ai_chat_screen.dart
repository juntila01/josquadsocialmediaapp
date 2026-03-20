import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '/services/gemini_ai_service.dart'; // Connection: Imports the custom wrapper for Gemini API calls

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({Key? key}) : super(key: key);

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  // Logic: Controller for the user's input text field
  final TextEditingController _controller = TextEditingController();

  // Connection: Instance of the service that interacts with the Gemini model
  final AiService _aiService = AiService();

  // Logic: The ChatSession object is provided by the google_generative_ai package.
  // It automatically tracks the 'history' of the conversation so the AI remembers previous prompts.
  late ChatSession _chatSession;

  // UI: Local list to keep track of the messages for the ListView display
  final List<Map<String, String>> _messages = [];

  // UI: Tracks the API's loading state to show a progress bar
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Logic: Initialize the session on screen load. This prepares the model for multi-turn chat.
    _chatSession = _aiService.startChat();
  }

  // Logic: The main function to send user input and receive a response
  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // UI: Immediately add the user's message to the list and show the loader
    setState(() {
      _messages.add({"role": "user", "text": text});
      _isLoading = true;
    });
    _controller.clear();

    // Connection: Passes the current session and new text to the service.
    // The session is updated internally by the SDK with the new content.
    final response = await _aiService.getAiResponse(_chatSession, text);

    // UI: Add the AI's response to the list and hide the loader
    setState(() {
      _messages.add({"role": "model", "text": response});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("AI Assistant")),
      body: Column(
        children: [
          // 1. LIST OF MESSAGES
          // UI: Displays the conversation in bubbles, alternating sides based on the 'role'
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final isUser = _messages[i]['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    // UI: Constrains the bubble width so it doesn't span the whole screen
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.indigo : theme.cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: Radius.circular(isUser ? 15 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 15),
                      ),
                    ),
                    child: Text(
                      _messages[i]['text']!,
                      style: TextStyle(color: isUser ? Colors.white : theme.textTheme.bodyLarge?.color),
                    ),
                  ),
                );
              },
            ),
          ),

          // UI: Visual feedback while the Gemini model is generating a response
          if (_isLoading) const LinearProgressIndicator(),

          // 2. INPUT AREA
          // UI: A stylized text field and send button for user interaction
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _handleSend(), // Logic: Allows sending by pressing "Enter"
                    decoration: InputDecoration(
                      hintText: "Ask AI...",
                      filled: true,
                      fillColor: theme.cardColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _handleSend
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Logic: Standard cleanup of the text controller resource
    _controller.dispose();
    super.dispose();
  }
}