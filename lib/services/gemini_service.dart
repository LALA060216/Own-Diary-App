import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'models/ai_chat_model.dart';

class GeminiService {
  late final GenerativeModel _model;
  final AIChatModel _chatModel;

  GeminiService({required AIChatModel chatModel})
    : _chatModel = chatModel {
    _model = GenerativeModel(
      model: _chatModel.model,
      apiKey: 'AIzaSyB7fyWwmbbFQEV_0IYTXBV6EZ0uUsELFj8',
      generationConfig: GenerationConfig(
        temperature: 0.6,
        topP: 0.9,
      ),
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

  Future<String> getMoodAnalysis(String diaryEntry) async {
    try{
      final trimmedEntry = diaryEntry.trim();
      if (trimmedEntry.isEmpty) {
        return "Error: Empty diary entry";
      }

      final response = await _model.generateContent([
        Content.text('${_chatModel.prompt}\nDiary entry:\n$trimmedEntry'),
      ]);
      return response.text ?? "";
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<String> getAttentionAnalysis(String diaryEntry) async {
    try{
      final trimmedEntry = diaryEntry.trim();
      if (trimmedEntry.isEmpty) {
        return "Error: Empty diary entry";
      }

      final fullPrompt = '${_chatModel.prompt}\nDiary entry:\n$trimmedEntry';
      
      final response = await _model.generateContent([
        Content.text(fullPrompt),
      ]);
      
      return response.text ?? "{}";
    } catch (e) {
      print("=== GEMINI ERROR ===");
      print("Error: $e");
      return "Error: $e";
    }
  }

  Future<String> sendMessageWithDiaryEntry(String userMessage, List<Content> previousMessage, List<String> contexts) async {
    try {
      final diaries = <Content>[Content.text(_chatModel.prompt)];
      for (final context in contexts) {
        diaries.add(Content.text('Diary entry: $context'));
      }

      final chat = _model.startChat(history: diaries);

      final response = await chat.sendMessage(Content.text('Previous message: $previousMessage\nCurrent message: $userMessage'));
      return response.text ?? "Sorry, I couldn't generate a response.";
    } catch (e) {
      return "Error: $e";
    }
  }
}