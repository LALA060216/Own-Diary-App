import 'package:google_generative_ai/google_generative_ai.dart';
import 'models/ai_chat_model.dart';

class GeminiService {
  late final GenerativeModel _model;
  final AIChatModel _chatModel;

  GeminiService({required AIChatModel chatModel})
    : _chatModel = chatModel {
    _model = GenerativeModel(
      model: _chatModel.model,
      apiKey: 'AIzaSyCcLIyQT03Skh9Cr4l-b7acBDF8pfjgwiw'
    );
  }

  /// Sends a message and returns AI response
  Future<String> sendMessage(String userMessage) async {
    try {
      final chat = _model.startChat(
        history: [Content.text(_chatModel.prompt)],
      );

      final response = await chat.sendMessage(Content.text(userMessage));
      return response.text ?? "Sorry, I couldn't generate a response.";
    } catch (e) {
      return "Error: $e";
    }
  }

  /// Sends a message with chat history
  Future<String> sendMessageWithHistory(
    String userMessage, 
    List<Content> history
  ) async {
    try {
      final chat = _model.startChat(
        history: history,
      );

      final response = await chat.sendMessage(Content.text(userMessage));
      return response.text ?? "Sorry, I couldn't generate a response.";
    } catch (e) {
      return "Error: $e";
    }
  }
}