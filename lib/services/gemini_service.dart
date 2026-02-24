import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'models/ai_chat_model.dart';

class GeminiService {
  final AIChatModel _chatModel;

  GeminiService({required AIChatModel chatModel}) : _chatModel = chatModel;

  // ---------------------------------------------------------------------------
  // Static constants & helpers
  // ---------------------------------------------------------------------------

  static const String _cloudFunctionBaseUrl =
      'https://us-central1-diary-app-1c552.cloudfunctions.net';

  /// Downscales to 512 px on the longest side and compresses to JPEG quality 70
  /// to reduce Gemini API payload size.
  static Uint8List? _downscaleToJpeg(Uint8List bytes) {
    img.Image? image = img.decodeImage(bytes);
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
  }

  /// Downloads an image from [imageUrl] and prepares it for Gemini.
  static Future<Uint8List?> _downloadAndDownscaleForGemini(
      String imageUrl) async {
    try {
      final response = await http
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 7));
      if (response.statusCode != 200) return null;
      return _downscaleToJpeg(response.bodyBytes);
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _loadLocalAndDownscaleForGemini(
      String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return _downscaleToJpeg(bytes);
    } catch (_) {
      return null;
    }
  }

  static bool _isNetworkUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  // Classification prompt
  static final String classificationPrompt =
      'You are an image classifier for diary moments. '
      'Look at the image and classify what you see. '
      'Return exactly ONE category from: '
      'food_buddy, funny_moment, travel_memory, study_day, '
      'work_life, fitness, family_time, friend_vibes, romance, '
      'pet_time, night_thoughts, music_movie, nature_walk, '
      'self_growth, or moments. Be confident. '
      'Output only the category key, no explanation.';

  // ---------------------------------------------------------------------------
  // Instance methods
  // ---------------------------------------------------------------------------

  /// Classifies a diary entry's images using the Cloud Function.
  ///
  /// Accepts a list of image URLs, downloads and downscales them,
  /// then calls the Cloud Function to classify using Gemini.
  /// Returns the category key or description. Returns an empty string when no
  /// suitable image is available.
  Future<String> classifyDiaryImage(List<String> imageUrls) async {
    final trimmedSources = imageUrls
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toList();

    if (trimmedSources.isEmpty) return '';

    try {
      // Process all images and combine their descriptions
      final List<String> descriptions = [];
      
      for (int i = 0; i < trimmedSources.length; i++) {
        final source = trimmedSources[i];
        
        final imageData = _isNetworkUrl(source)
            ? await _downloadAndDownscaleForGemini(source)
            : await _loadLocalAndDownscaleForGemini(source);
        
        if (imageData == null) continue;

        // Convert to base64
        final base64Image = base64Encode(imageData);

        // Call Cloud Function with image data
        final response = await http.post(
          Uri.parse('$_cloudFunctionBaseUrl/classifyDiaryImage'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'imageData': base64Image,
            'mimeType': 'image/jpeg',
            'prompt': _chatModel.prompt,
            'model': _chatModel.model,
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          final result = jsonResponse['category'] ?? '';
          if (result.isNotEmpty) {
            descriptions.add(result);
          }
        } else {
          print('Cloud Function error for image $i: ${response.statusCode}');
        }
      }
      
      // Combine all descriptions
      if (descriptions.isEmpty) return '';
      if (descriptions.length == 1) return descriptions.first;
      
      // For multiple images, combine with numbering
      return descriptions.asMap().entries.map((entry) {
        return 'Image ${entry.key + 1}: ${entry.value}';
      }).join('\n\n');
      
    } catch (e) {
      print('Error calling Cloud Function: $e');
      return '';
    }
  }

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