import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'models/ai_chat_model.dart';

class GeminiService {
  // Cloud Function URL - replace with your Firebase project URL
  static const String _cloudFunctionBaseUrl =
      "https://us-central1-diary-app-1c552.cloudfunctions.net";

  /// Downloads an image from [imageUrl], downscales to 512 px on the longest
  /// side, and compresses to JPEG quality 70 to reduce Gemini API payload size.
  static Future<Uint8List?> _downloadAndDownscaleForGemini(
      String imageUrl) async {
    try {
      final response = await http
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 7));
      if (response.statusCode != 200) return null;

      img.Image? image = img.decodeImage(response.bodyBytes);
      if (image == null) return null;

      const maxDimension = 512;
      if (image.width > maxDimension || image.height > maxDimension) {
        if (image.width > image.height) {
          image = img.copyResize(image, width: maxDimension);
        } else {
          image = img.copyResize(image, height: maxDimension);
        }
      }

      final compressed = img.encodeJpg(image, quality: 70);
      return Uint8List.fromList(compressed);
    } catch (_) {
      return null;
    }
  }

  static bool _isNetworkUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  /// Classifies a diary entry's images using the Cloud Function.
  ///
  /// Accepts a list of image URLs, downloads and downscales them,
  /// then calls the Cloud Function to classify using Gemini.
  /// Returns the category key. Returns an empty string when no
  /// suitable image is available.
  static Future<String> classifyImageMoment(List<String> imageUrls) async {
    final networkUrls = imageUrls
        .where((u) => _isNetworkUrl(u) && u.trim().isNotEmpty)
        .toList();

    if (networkUrls.isEmpty) return '';

    try {
      // Download and downscale the first image
      final imageData =
          await _downloadAndDownscaleForGemini(networkUrls[0]);
      if (imageData == null) return '';

      // Convert to base64
      final base64Image = base64Encode(imageData);

      // Call Cloud Function with image data
      final response = await http.post(
        Uri.parse('$_cloudFunctionBaseUrl/classifyDiaryImage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'imageData': base64Image,
          'mimeType': 'image/jpeg',
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['category'] ?? '';
      } else {
        print('Cloud Function error: ${response.statusCode}');
        return '';
      }
    } catch (e) {
      print('Error calling Cloud Function: $e');
      return '';
    }
  }

  final AIChatModel _chatModel;

  GeminiService({required AIChatModel chatModel}) : _chatModel = chatModel;

  /// Sends a message and returns AI response via Cloud Function
  Future<String> sendMessage(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse('$_cloudFunctionBaseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': userMessage,
          'prompt': _chatModel.prompt,
          'model': _chatModel.model,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['response'] ?? "Sorry, I couldn't generate a response.";
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  /// Sends a message with chat history via Cloud Function
  Future<String> sendMessageWithHistory(
    String userMessage, 
    List<dynamic> history,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_cloudFunctionBaseUrl/chatWithHistory'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': userMessage,
          'history': history,
          'prompt': _chatModel.prompt,
          'model': _chatModel.model,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['response'] ?? "Sorry, I couldn't generate a response.";
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  /// Gets mood analysis via Cloud Function
  Future<String> getMoodAnalysis(String diaryEntry) async {
    try {
      final trimmedEntry = diaryEntry.trim();
      if (trimmedEntry.isEmpty) {
        return "Error: Empty diary entry";
      }

      final response = await http.post(
        Uri.parse('$_cloudFunctionBaseUrl/moodAnalysis'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'diaryEntry': trimmedEntry,
          'prompt': _chatModel.prompt,
          'model': _chatModel.model,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['analysis'] ?? "";
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  /// Gets attention analysis via Cloud Function
  Future<String> getAttentionAnalysis(String diaryEntry) async {
    try {
      final trimmedEntry = diaryEntry.trim();
      if (trimmedEntry.isEmpty) {
        return "Error: Empty diary entry";
      }

      final response = await http.post(
        Uri.parse('$_cloudFunctionBaseUrl/attentionAnalysis'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'diaryEntry': trimmedEntry,
          'prompt': _chatModel.prompt,
          'model': _chatModel.model,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['analysis'] ?? "{}";
      } else {
        return "{}";
      }
    } catch (e) {
      print("=== CLOUD FUNCTION ERROR ===");
      print("Error: $e");
      return "{}";
    }
  }

  /// Sends message with diary entries via Cloud Function
  Future<String> sendMessageWithDiaryEntry(
    String userMessage,
    List<dynamic> previousMessage,
    List<String> contexts,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_cloudFunctionBaseUrl/chatWithDiaryEntry'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': userMessage,
          'previousMessage': previousMessage,
          'contexts': contexts,
          'prompt': _chatModel.prompt,
          'model': _chatModel.model,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['response'] ?? "Sorry, I couldn't generate a response.";
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }
}