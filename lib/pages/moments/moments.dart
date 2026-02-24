import 'package:diaryapp/services/firestore_service.dart';
import 'package:diaryapp/services/gemini_service.dart';
import 'package:diaryapp/services/models/ai_chat_model.dart';


class MomentFunctions {
  final String userId;
  final FirestoreService firestoreService;
  final String diaryId;
  final String diaryContext;
  final List<String> diaryImageUrls;

  MomentFunctions({
    required this.userId,
    required this.firestoreService,
    required this.diaryId,
    required this.diaryContext,
    required this.diaryImageUrls,
  });

  Future<String> classifyMomentWithAi() async {
    if (diaryImageUrls.isEmpty) return _classifyMomentFromTextOnly();

    // ALWAYS prioritize image classification when images are present
    // Ignore text content completely to ensure food images go to food_buddy
    try {
      final imageCategory = await _classifyMomentFromImageOnly();
      return imageCategory;
    } catch (_) {
      // Only fall back to text if image classification completely fails
      return _classifyMomentFromTextOnly();
    }
  }

  Future<String> _classifyMomentFromImageOnly() async {
    if (diaryImageUrls.isEmpty) return 'moments';

    final imageClassifierModel = AIChatModel(
      prompt: GeminiService.classificationPrompt,
      model: 'gemini-2.5-flash',
    );

    final rawText = await GeminiService(chatModel: imageClassifierModel)
        .classifyDiaryImage(diaryImageUrls);
    if (rawText.trim().isEmpty) {
      print('AI classification empty response for diary $diaryId');
      return 'moments';
    }
    print('AI classification for diary $diaryId: $rawText');
    return _extractCategoryFromAiResponse(rawText);
  }

  String _classifyMomentFromTextOnly() {
    final combined = [
      diaryContext,
    ].join(' ').trim();
    if (combined.isEmpty) return 'moments';
    final scoredCategory = _categoryFromKeywordScore(combined);
    return scoredCategory;
  }

  String _extractCategoryFromAiResponse(String raw) {
    final lower = raw.toLowerCase().trim();

    for (final key in _classifiableMomentKeys) {
      final pattern = RegExp(
        '(?:^|[^a-z])${RegExp.escape(key).replaceAll('_', r'[\\s_-]*')}(?:[^a-z]|\$)',
        caseSensitive: false,
      );
      if (pattern.hasMatch(lower)) {
        return key;
      }
    }

    final normalized = _normalizeAiCategory(lower);
    if (_classifiableMomentKeys.contains(normalized)) {
      return normalized;
    }

    return 'moments';
  }

  int _scoreTextAgainstTerms(String text, List<String> terms) {
    int score = 0;
    for (final term in terms) {
      if (_containsTerm(text, term)) {
        score++;
      }
    }
    return score;
  }

  static const Map<String, List<String>> _categoryKeywords = {
    'food_buddy': ['food', 'meal', 'restaurant', 'cafe', 'dinner', 'lunch', 'breakfast', 'snack', 'cook', 'coffee'],
    'funny_moment': ['funny', 'lol', 'joke', 'laugh', 'humor', 'hilarious'],
    'travel_memory': ['travel', 'trip', 'vacation', 'flight', 'hotel', 'beach', 'journey', 'tour'],
    'study_day': ['study', 'school', 'class', 'exam', 'homework', 'assignment', 'campus', 'lecture'],
    'work_life': ['work', 'office', 'meeting', 'deadline', 'project', 'client', 'business', 'job'],
    'fitness': ['gym', 'workout', 'fitness', 'run', 'running', 'sport', 'exercise', 'training'],
    'family_time': ['family', 'mom', 'dad', 'parents', 'sister', 'brother', 'home'],
    'friend_vibes': ['friend', 'bestie', 'hangout', 'buddy', 'crew'],
    'romance': ['love', 'date', 'romance', 'boyfriend', 'girlfriend', 'partner'],
    'pet_time': ['pet', 'dog', 'cat', 'puppy', 'kitten'],
    'night_thoughts': ['night', 'midnight', 'late', 'insomnia'],
    'music_movie': ['music', 'song', 'movie', 'film', 'cinema', 'playlist'],
    'nature_walk': ['nature', 'park', 'mountain', 'hike', 'forest', 'sunset'],
    'self_growth': ['goal', 'growth', 'improve', 'discipline', 'habit', 'progress'],
  };


  static const List<String> _classifiableMomentKeys = [
    'food_buddy',
    'funny_moment',
    'travel_memory',
    'study_day',
    'work_life',
    'fitness',
    'family_time',
    'friend_vibes',
    'romance',
    'pet_time',
    'night_thoughts',
    'music_movie',
    'nature_walk',
    'self_growth',
    'moments',
  ];

  bool _containsTerm(String text, String term) {
    final escaped = RegExp.escape(term.toLowerCase());
    final expression = term.contains(' ')
        ? escaped.replaceAll(r'\ ', r'\s+')
        : '\\b$escaped\\b';
    return RegExp(expression, caseSensitive: false).hasMatch(text);
  }

  String _categoryFromKeywordScore(String raw) {
    final text = raw.toLowerCase();
    String bestCategory = 'moments';
    int bestScore = 0;
    bool hasTie = false;

    for (final entry in _categoryKeywords.entries) {
      final score = _scoreTextAgainstTerms(text, entry.value);
      if (score > bestScore) {
        bestScore = score;
        bestCategory = entry.key;
        hasTie = false;
      } else if (score > 0 && score == bestScore) {
        hasTie = true;
      }
    }

    if (bestScore == 0 || hasTie) return 'moments';
    return bestCategory;
  }

  String _normalizeAiCategory(String raw) {
    return raw
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[\s-]+'), '_')
      .replaceAll(RegExp(r'[^a-z_]'), '')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  }

}