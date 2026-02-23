import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../services/firestore_service.dart';
import '../services/models/diary_entry_model.dart';
import 'details_diary.dart';

class _MomentCategory {
  final String key;
  final String label;
  final IconData icon;

  const _MomentCategory({
    required this.key,
    required this.label,
    required this.icon,
  });
}

class _MomentBucket {
  final _MomentCategory category;
  final List<_MomentStoryFrame> frames;

  const _MomentBucket({
    required this.category,
    required this.frames,
  });
}

class _MomentStoryFrame {
  final String diaryId;
  final int imageIndexInDiary;
  final String imageUrl;
  final String title;
  final DateTime created;
  final String categoryKey;
  final String categoryLabel;

  const _MomentStoryFrame({
    required this.diaryId,
    required this.imageIndexInDiary,
    required this.imageUrl,
    required this.title,
    required this.created,
    required this.categoryKey,
    required this.categoryLabel,
  });
}

class _MomentStoryPage extends StatefulWidget {
  final List<_MomentStoryFrame> frames;
  final int initialIndex;
  final DiaryEntryModel? Function(_MomentStoryFrame frame)? resolveDiary;

  const _MomentStoryPage({
    required this.frames,
    this.initialIndex = 0,
    this.resolveDiary,
  });

  @override
  State<_MomentStoryPage> createState() => _MomentStoryPageState();
}

class _MomentStoryPageState extends State<_MomentStoryPage>
  with TickerProviderStateMixin {
  late final PageController _controller;
  late final AnimationController _progressController;
  int _index = 0;
  DateTime? _pressStartedAt;
  bool _isDraggingHorizontally = false;
  bool _isOpeningDetails = false;
  double _horizontalDragDelta = 0;
  static const Duration _tapMaxDuration = Duration(milliseconds: 220);
  static const double _swipeDistanceThreshold = 40;
  static const double _swipeVelocityThreshold = 250;

  void _restartProgress() {
    if (!mounted) return;
    _progressController
      ..stop()
      ..forward(from: 0);
  }

  void _pauseProgress() {
    if (!mounted) return;
    _progressController.stop();
  }

  void _resumeProgress() {
    if (!mounted) return;
    if (_progressController.isAnimating || _progressController.value >= 1) {
      return;
    }
    _progressController.forward();
  }

  void _handleTapNavigation(TapUpDetails details) {
    final startedAt = _pressStartedAt;
    _pressStartedAt = null;
    if (startedAt == null || _isDraggingHorizontally) return;

    final pressedDuration = DateTime.now().difference(startedAt);
    if (pressedDuration > _tapMaxDuration) {
      return;
    }

    final width = MediaQuery.of(context).size.width;
    if (details.localPosition.dx < width * 0.5) {
      _prev();
    } else {
      _next();
    }
  }

  List<String> _orderedCategoryKeys() {
    final keys = <String>[];
    for (final frame in widget.frames) {
      if (!keys.contains(frame.categoryKey)) {
        keys.add(frame.categoryKey);
      }
    }
    return keys;
  }

  void _jumpToCategory({required bool next}) {
    if (widget.frames.isEmpty) return;
    final currentKey = widget.frames[_index].categoryKey;
    final orderedKeys = _orderedCategoryKeys();
    final currentCategoryIndex = orderedKeys.indexOf(currentKey);
    if (currentCategoryIndex == -1) return;

    final targetCategoryIndex =
        next ? currentCategoryIndex + 1 : currentCategoryIndex - 1;
    if (targetCategoryIndex < 0) return;
    if (targetCategoryIndex >= orderedKeys.length) {
      Navigator.pop(context);
      return;
    }

    final targetKey = orderedKeys[targetCategoryIndex];
    final targetFrameIndex =
        widget.frames.indexWhere((frame) => frame.categoryKey == targetKey);
    if (targetFrameIndex == -1) return;

    // Jump instantly to next category (no animation through all moments)
    _controller.jumpToPage(targetFrameIndex);
  }

  bool _isNetworkUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          _next();
        }
      });
    _restartProgress();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index >= widget.frames.length - 1) {
      Navigator.pop(context);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  void _prev() {
    if (_index == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openCurrentDiaryFromFrame() async {
    if (_isOpeningDetails || widget.frames.isEmpty) return;
    final resolver = widget.resolveDiary;
    if (resolver == null) return;

    final frame = widget.frames[_index];
    final diary = resolver(frame);
    if (diary == null || !mounted) return;

    _isOpeningDetails = true;
    _pauseProgress();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailsDiary(
          diary: diary,
          focusImageIndex: frame.imageIndexInDiary,
        ),
      ),
    );
    _isOpeningDetails = false;
    _resumeProgress();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.frames.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox.shrink(),
      );
    }

    final currentFrame = widget.frames[_index];
    final currentCategoryKey = currentFrame.categoryKey;
    final currentCategoryFrames = widget.frames
        .where((frame) => frame.categoryKey == currentCategoryKey)
        .toList(growable: false);
    final currentCategoryIndices = <int>[];
    for (var i = 0; i < widget.frames.length; i++) {
      if (widget.frames[i].categoryKey == currentCategoryKey) {
        currentCategoryIndices.add(i);
      }
    }
    final localIndex = currentCategoryIndices.indexOf(_index);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) {
                _pressStartedAt = DateTime.now();
                _pauseProgress();
              },
              onTapUp: (details) {
                _resumeProgress();
                _handleTapNavigation(details);
              },
              onTapCancel: () {
                _pressStartedAt = null;
                _resumeProgress();
              },
              onHorizontalDragStart: (_) {
                _isDraggingHorizontally = true;
                _pressStartedAt = null;
                _horizontalDragDelta = 0;
                _pauseProgress();
              },
              onHorizontalDragUpdate: (details) {
                _horizontalDragDelta += details.primaryDelta ?? 0;
              },
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                final distance = _horizontalDragDelta;
                _isDraggingHorizontally = false;
                _resumeProgress();
                _horizontalDragDelta = 0;

                final isValidSwipe =
                    velocity.abs() >= _swipeVelocityThreshold ||
                    distance.abs() >= _swipeDistanceThreshold;
                if (!isValidSwipe) return;

                if (velocity < 0 || (velocity == 0 && distance < 0)) {
                  _jumpToCategory(next: true); // Swipe left = go to next category
                } else {
                  _jumpToCategory(next: false); // Swipe right = go to previous category
                }
              },
              onVerticalDragEnd: (details) async {
                final velocity = details.primaryVelocity;
                if (velocity == null) return;
                if (velocity > 550) {
                  Navigator.pop(context);
                  return;
                }
                if (velocity < -550) {
                  await _openCurrentDiaryFromFrame();
                }
              },
              child: PageView.builder(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.frames.length,
                onPageChanged: (value) {
                  setState(() {
                    _index = value;
                  });
                  _restartProgress();
                },
                itemBuilder: (context, index) {
                  final frame = widget.frames[index];
                  final isNetwork = _isNetworkUrl(frame.imageUrl);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      isNetwork
                          ? Image.network(
                              frame.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Center(
                                child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.image, color: Colors.white54, size: 48),
                            ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 26,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                frame.title.trim().isEmpty ? 'Untitled' : frame.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('dd MMM yyyy').format(frame.created),
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: IgnorePointer(
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 10,
              child: Row(
                children: List.generate(currentCategoryFrames.length, (i) {
                  final done = i < localIndex;
                  final active = i == localIndex;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: done
                              ? Container(color: Colors.white)
                              : active
                                  ? AnimatedBuilder(
                                      animation: _progressController,
                                      child: Container(color: Colors.white),
                                      builder: (_, child) {
                                        return FractionallySizedBox(
                                          widthFactor: _progressController.value,
                                          alignment: Alignment.centerLeft,
                                          child: child,
                                        );
                                      },
                                    )
                                  : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              top: 22,
              left: 16,
              right: 16,
              child: Text(
                currentFrame.categoryLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Diaries extends StatefulWidget {
  const Diaries({super.key});

  @override
  State<Diaries> createState() => _DiariesState();
}

class _DiariesState extends State<Diaries> {
  static const List<_MomentCategory> _momentCategories = [
    _MomentCategory(key: 'today_memory', label: 'This Day Past', icon: Icons.history),
    _MomentCategory(key: 'food_buddy', label: 'Food Buddy', icon: Icons.restaurant),
    _MomentCategory(key: 'funny_moment', label: 'Funny Moment', icon: Icons.sentiment_very_satisfied),
    _MomentCategory(key: 'travel_memory', label: 'Travel Memory', icon: Icons.flight_takeoff),
    _MomentCategory(key: 'study_day', label: 'Study Day', icon: Icons.menu_book),
    _MomentCategory(key: 'work_life', label: 'Work Life', icon: Icons.work),
    _MomentCategory(key: 'fitness', label: 'Fitness', icon: Icons.fitness_center),
    _MomentCategory(key: 'family_time', label: 'Family Time', icon: Icons.home),
    _MomentCategory(key: 'friend_vibes', label: 'Friend Vibes', icon: Icons.groups),
    _MomentCategory(key: 'romance', label: 'Romance', icon: Icons.favorite),
    _MomentCategory(key: 'pet_time', label: 'Pet Time', icon: Icons.pets),
    _MomentCategory(key: 'night_thoughts', label: 'Night Thoughts', icon: Icons.nightlight),
    _MomentCategory(key: 'music_movie', label: 'Music & Movie', icon: Icons.movie),
    _MomentCategory(key: 'nature_walk', label: 'Nature Walk', icon: Icons.park),
    _MomentCategory(key: 'self_growth', label: 'Self Growth', icon: Icons.trending_up),
    _MomentCategory(key: 'moments', label: 'Moments', icon: Icons.auto_awesome),
  ];

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

  DateTime selectedDate = DateTime.now();
  DateTime? selectedDay;
  String titleQuery = '';
  bool isSearchOpen = false;
  bool _isProgrammaticSearchUpdate = false;
  final TextEditingController _searchController = TextEditingController();

  final FirestoreService firestoreService = FirestoreService();
  final GenerativeModel _visionModel = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: 'AIzaSyB7fyWwmbbFQEV_0IYTXBV6EZ0uUsELFj8',
    generationConfig: GenerationConfig(temperature: 0.2, topP: 0.8),
  );

  String? userId;
  Stream<List<DiaryEntryModel>>? diaryStream;
  StreamSubscription<List<DiaryEntryModel>>? _momentsSubscription;
  List<DiaryEntryModel> _allDiaries = [];
  final Map<String, String> _aiMomentByDiaryId = {};
  final Set<String> _classifyingDiaryIds = {};
  bool _isClassifyingMoments = false;
  bool _classificationRerunRequested = false;

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(fn);
      });
    } else {
      setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      userId = user.uid;
      diaryStream =
      firestoreService.getUserDiaryEntriesStream(userId!);
      _momentsSubscription = diaryStream!.listen((entries) {
        if (!mounted) return;
        _safeSetState(() {
          _allDiaries = entries;
        });
        unawaited(_classifyImageMoments(entries));
      }, onError: (_) {
        if (!mounted) return;
        _safeSetState(() {
          _allDiaries = [];
        });
      });
    }
  }

  /// Downloads image from URL, downscales to 512px, and compresses to JPEG
  /// Returns compressed bytes suitable for Gemini API (reduces payload size dramatically)
  Future<Uint8List?> _downloadAndDownscaleForGemini(String imageUrl) async {
    try {
      // Download with timeout
      final response = await http.get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 7));
      
      if (response.statusCode != 200) return null;
      
      // Decode image
      img.Image? image = img.decodeImage(response.bodyBytes);
      if (image == null) return null;
      
      // Resize: longest side to 512px for speed
      const maxDimension = 512;
      if (image.width > maxDimension || image.height > maxDimension) {
        if (image.width > image.height) {
          image = img.copyResize(image, width: maxDimension);
        } else {
          image = img.copyResize(image, height: maxDimension);
        }
      }
      
      // Compress to JPEG quality 70 (balance of size/quality)
      final compressed = img.encodeJpg(image, quality: 70);
      return Uint8List.fromList(compressed);
    } catch (_) {
      return null;
    }
  }

  bool _isNetworkUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
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

  bool _containsTerm(String text, String term) {
    final escaped = RegExp.escape(term.toLowerCase());
    final expression = term.contains(' ')
        ? escaped.replaceAll(r'\ ', r'\s+')
        : '\\b$escaped\\b';
    return RegExp(expression, caseSensitive: false).hasMatch(text);
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

  String _mapLooseCategoryFromText(String raw) {
    final text = raw.toLowerCase();
    final extraTerms = <String, List<String>>{
      'food_buddy': ['food', 'meal', 'restaurant', 'cafe', 'dining'],
      'funny_moment': ['funny', 'humor', 'joke', 'laugh'],
      'travel_memory': ['travel', 'trip', 'vacation', 'tour', 'journey'],
      'study_day': ['study', 'school', 'exam', 'homework', 'assignment'],
      'work_life': ['work', 'office', 'business', 'coding', 'developer', 'project'],
      'fitness': ['fitness', 'gym', 'workout', 'exercise', 'sport'],
      'family_time': ['family', 'parents', 'siblings'],
      'friend_vibes': ['friend', 'friends', 'bestie', 'hangout'],
      'romance': ['romance', 'love', 'date', 'partner'],
      'pet_time': ['pet', 'dog', 'cat', 'puppy', 'kitten'],
      'night_thoughts': ['night', 'midnight', 'late night'],
      'music_movie': ['music', 'song', 'movie', 'film', 'cinema'],
      'nature_walk': ['nature', 'park', 'forest', 'mountain', 'hike'],
      'self_growth': ['growth', 'goal', 'discipline', 'improve', 'progress'],
    };

    String bestCategory = 'moments';
    int bestScore = 0;
    bool hasTie = false;

    for (final key in _classifiableMomentKeys.where((k) => k != 'moments')) {
      final terms = [
        ...(_categoryKeywords[key] ?? const <String>[]),
        ...(extraTerms[key] ?? const <String>[]),
      ];
      final score = _scoreTextAgainstTerms(text, terms);
      if (score > bestScore) {
        bestScore = score;
        bestCategory = key;
        hasTie = false;
      } else if (score > 0 && score == bestScore) {
        hasTie = true;
      }
    }

    if (bestScore == 0 || hasTie) return 'moments';
    return bestCategory;
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

    return _mapLooseCategoryFromText(lower);
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

  String _classifyMomentFromTextOnly(DiaryEntryModel diary) {
    final combined = [
      diary.title,
      diary.context,
      diary.keywords.join(' '),
    ].join(' ').trim();
    if (combined.isEmpty) return 'moments';
    final scoredCategory = _categoryFromKeywordScore(combined);
    if (scoredCategory != 'moments') return scoredCategory;
    return _mapLooseCategoryFromText(combined);
  }

  Future<String> _classifyMomentFromImageOnly(DiaryEntryModel diary) async {
    if (diary.imageUrls.isEmpty) return 'moments';

    final parts = <Part>[
      TextPart(
        'You are an image classifier for diary moments. '
        'Look at the image and classify what you see. '
        'Return exactly ONE category from: '
        'food_buddy (for food, meals, restaurants, cooking), '
        'funny_moment (for humor, jokes), '
        'travel_memory (for travel, trips, vacation), '
        'study_day (for studying, school), '
        'work_life (for work, office), '
        'fitness (for exercise, sports, gym), '
        'family_time (for family photos), '
        'friend_vibes (for friends hanging out), '
        'romance (for couples, dates), '
        'pet_time (for pets, animals), '
        'night_thoughts (for nighttime), '
        'music_movie (for concerts, movies), '
        'nature_walk (for nature, outdoors), '
        'self_growth (for personal development), '
        'moments (only if image does not match any category). '
        'Be confident - if you see food in the image, return food_buddy. '
        'Output only the category key, no explanation.'
        'if image cannot be processed, return HelloWorld',
      ),
    ];

    // Process only 1 image for speed (reduced from 2)
    final imageUrls = diary.imageUrls
        .where((u) => _isNetworkUrl(u) && u.trim().isNotEmpty)
        .take(1);
    
    for (final imageUrl in imageUrls) {
      final compressedBytes = await _downloadAndDownscaleForGemini(imageUrl);
      print('Compressed bytes for image $imageUrl: ${compressedBytes?.length ?? 0}');
      if (compressedBytes != null) {
        parts.add(DataPart('image/jpeg', compressedBytes));
        break; // Only use first successfully downloaded image
      }
    }

    if (parts.length == 1) return 'moments';

    final response = await _visionModel.generateContent([
      Content.multi(parts),
    ]);
    final rawText = response.text ?? '';
    if (rawText.trim().isEmpty) {
      print('AI classification empty response for diary ${diary.id}');
    }
    print('AI classification for diary ${diary.id}: $rawText');
    return _extractCategoryFromAiResponse(rawText);
  }

  Future<String> _classifyMomentWithAi(DiaryEntryModel diary) async {
    if (diary.imageUrls.isEmpty) return _classifyMomentFromTextOnly(diary);

    // ALWAYS prioritize image classification when images are present
    // Ignore text content completely to ensure food images go to food_buddy
    try {
      final imageCategory = await _classifyMomentFromImageOnly(diary);
      return imageCategory;
    } catch (_) {
      // Only fall back to text if image classification completely fails
      return _classifyMomentFromTextOnly(diary);
    }
  }

  Future<void> _classifyImageMoments(List<DiaryEntryModel> diaries) async {
    if (_isClassifyingMoments) {
      _classificationRerunRequested = true;
      return;
    }
    _isClassifyingMoments = true;
    try {
      while (true) {
        final candidates = <DiaryEntryModel>[];
        for (final diary in diaries) {
          if (_aiMomentByDiaryId.containsKey(diary.id) ||
              _classifyingDiaryIds.contains(diary.id)) {
            continue;
          }

          if (!diary.imageUrls.any((imageUrl) => imageUrl.trim().isNotEmpty)) {
            continue;
          }

          candidates.add(diary);
          if (candidates.length >= 12) break;
        }

        if (candidates.isEmpty) break;

        // Process 2 diaries concurrently at a time for speed
        for (var i = 0; i < candidates.length; i += 2) {
          if (!mounted) return;
          
          final batch = candidates.skip(i).take(2).toList();
          final futures = <Future<void>>[];
          
          for (final diary in batch) {
            _classifyingDiaryIds.add(diary.id);
            
            futures.add(
              _classifyMomentWithAi(diary).then((category) {
                _classifyingDiaryIds.remove(diary.id);
                if (mounted) {
                  _safeSetState(() {
                    _aiMomentByDiaryId[diary.id] = category;
                  });
                }
              }).catchError((_) {
                _classifyingDiaryIds.remove(diary.id);
                if (mounted) {
                  _safeSetState(() {
                    _aiMomentByDiaryId[diary.id] = 'moments';
                  });
                }
              })
            );
          }
          
          // Wait for current batch to complete before starting next batch
          await Future.wait(futures);
        }
      }
    } catch (_) {
      return;
    } finally {
      _isClassifyingMoments = false;
      if (_classificationRerunRequested && mounted) {
        _classificationRerunRequested = false;
        unawaited(_classifyImageMoments(_allDiaries));
      }
    }
  }

  String _resolveMomentKey(DiaryEntryModel diary) {
    final now = DateTime.now();
    if (diary.created.year < now.year &&
        diary.created.month == now.month &&
        diary.created.day == now.day) {
      return 'today_memory';
    }

    return _aiMomentByDiaryId[diary.id] ?? 'moments';
  }

  List<_MomentBucket> _buildMomentBuckets(List<DiaryEntryModel> diaries) {
    final buckets = <String, List<_MomentStoryFrame>>{};
    final categoryByKey = {
      for (final category in _momentCategories) category.key: category,
    };

    for (final diary in diaries) {
      if (!diary.imageUrls.any((u) => u.trim().isNotEmpty)) continue;
      final key = _resolveMomentKey(diary);
      final categoryLabel = categoryByKey[key]?.label ?? 'Moments';
      final frames = buckets.putIfAbsent(key, () => []);
      for (final entry in diary.imageUrls.asMap().entries) {
        final imageIndex = entry.key;
        final imageUrl = entry.value;
        if (imageUrl.trim().isEmpty) continue;
        frames.add(
          _MomentStoryFrame(
            diaryId: diary.id,
            imageIndexInDiary: imageIndex,
            imageUrl: imageUrl,
            title: diary.title,
            created: diary.created,
            categoryKey: key,
            categoryLabel: categoryLabel,
          ),
        );
      }
    }

    final result = <_MomentBucket>[];
    for (final category in _momentCategories) {
      final frameList = buckets[category.key] ?? [];
      if (frameList.isEmpty) continue;
      result.add(_MomentBucket(category: category, frames: frameList));
    }
    return result;
  }

  void previousMonth() {
    _safeSetState(() {
      selectedDay = null;
      selectedDate =
          DateTime(selectedDate.year, selectedDate.month - 1);
    });
  }

  void nextMonth() {
    _safeSetState(() {
      selectedDay = null;
      selectedDate =
          DateTime(selectedDate.year, selectedDate.month + 1);
    });
  }

  Future<void> pickDateFromSearch() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDay ?? selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      _safeSetState(() {
        selectedDay = pickedDate;
        selectedDate = pickedDate;
      });
    }
  }

  void _clearAllFilters() {
    _isProgrammaticSearchUpdate = true;
    _searchController.clear();
    _isProgrammaticSearchUpdate = false;
    if (!mounted) return;
    _safeSetState(() {
      titleQuery = '';
      selectedDay = null;
    });
  }

  @override
  void dispose() {
    _momentsSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String monthName(int month) {
    const months = [
      "January","February","March","April",
      "May","June","July","August",
      "September","October","November","December"
    ];
    return months[month - 1];
  }

  List<DiaryEntryModel> _applyDiaryFilters(List<DiaryEntryModel> allDiaries) {
    final normalizedTitleQuery = titleQuery.toLowerCase();
    return allDiaries.where((d) {
      final hasBody = d.context.trim().isNotEmpty;
      final hasImages = d.imageUrls.isNotEmpty;
      final hasSavableContent = hasBody || hasImages;
      final titleMatches = normalizedTitleQuery.isEmpty ||
          d.title.toLowerCase().contains(normalizedTitleQuery);
      final monthMatches = selectedDay == null
          ? (d.created.month == selectedDate.month &&
              d.created.year == selectedDate.year)
          : true;
      final dateMatches = selectedDay != null
          ? DateUtils.isSameDay(d.created, selectedDay)
          : true;
        return monthMatches && hasSavableContent && titleMatches && dateMatches;
    }).toList();
  }

  DiaryEntryModel? _resolveDiaryForFrame(_MomentStoryFrame frame) {
    for (final diary in _allDiaries) {
      if (diary.id == frame.diaryId) {
        return diary;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null || diaryStream == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

Future<bool?> showDeleteConfirmationDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true, // allow tap outside to dismiss
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: const Color(0xFFF5F5F5), // subtle off‑white
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Delete diary?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'This diary entry will be permanently deleted.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 1),
            // Row with two actions and vertical divider
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  height: 55,
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                          ),
                            onTap: () =>
                                Navigator.of(context).pop(false),
                            child: const Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                        ),
                      ),

                        Container(
                          width: 1,
                          height: double.infinity,
                          color: Colors.grey.shade300,
                        ),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero, 
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: InkWell(
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(12),
                            ),
                            onTap:() => 
                              Navigator.of(context).pop(true),
                            child: const Center(
                              child: Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.red, 
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ),
            ),
          ],
        ),
      );
    },
  );
}

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 2,
        backgroundColor: const Color(0xfffffaf0),
        title: const Text(
          'Diary Summary',
          style: TextStyle(
            fontSize: 24,
            color: Colors.black,
            fontFamily: 'lobstertwo',
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [

          SizedBox(
            height: 124,
            child: _allDiaries.isEmpty
                ? const Center(child: Text('No moments yet'))
                : Builder(
                    builder: (context) {
                      final buckets = _buildMomentBuckets(_allDiaries);
                      if (buckets.isEmpty) {
                        return const Center(child: Text('No moments yet'));
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: buckets.length,
                        itemBuilder: (context, index) {
                          final bucket = buckets[index];
                          final cover = bucket.frames.first.imageUrl;
                          final coverIsNetwork = _isNetworkUrl(cover);

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
                            child: GestureDetector(
                              onTap: () {
                                // Build all frames in order from all buckets
                                final allFrames = <_MomentStoryFrame>[];
                                for (final b in buckets) {
                                  allFrames.addAll(b.frames);
                                }
                                if (allFrames.isEmpty) return;
                                
                                // Find the index of the first frame in the clicked bucket
                                final startIndex = allFrames.indexWhere(
                                  (f) => f.categoryKey == bucket.category.key
                                );
                                
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _MomentStoryPage(
                                      frames: allFrames,
                                      initialIndex: startIndex >= 0 ? startIndex : 0,
                                      resolveDiary: _resolveDiaryForFrame,
                                    ),
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: 78,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const LinearGradient(
                                          colors: [Color(0xff9c7cd6), Color(0xfff0a6ca)],
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.white,
                                        backgroundImage: coverIsNetwork
                                            ? NetworkImage(cover)
                                            : null,
                                        child: !coverIsNetwork
                                            ? Icon(bucket.category.icon, color: Colors.black54)
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${bucket.category.label} (${bucket.frames.length})',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),

          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: previousMonth,
              ),

              const SizedBox(width: 10),

              Text(
                "${monthName(selectedDate.month)} ${selectedDate.year}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              IconButton(
                icon: Icon(isSearchOpen ? Icons.close : Icons.search),
                onPressed: () {
                  if (isSearchOpen) {
                    _clearAllFilters();
                    if (!mounted) return;
                    _safeSetState(() {
                      isSearchOpen = false;
                    });
                  } else {
                    _safeSetState(() {
                      isSearchOpen = true;
                    });
                  }
                },
              ),

              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: nextMonth,
              ),
            ],
          ),

          if (isSearchOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEFEF),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          if (_isProgrammaticSearchUpdate || !mounted) return;
                          _safeSetState(() {
                            titleQuery = value.trim();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search title',
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search, color: Colors.black54),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_month, color: Colors.black54),
                            onPressed: pickDateFromSearch,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),

          if (selectedDay != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEDED),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy').format(selectedDay!),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            _safeSetState(() {
                              selectedDay = null;
                            });
                          },
                          child: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: StreamBuilder<List<DiaryEntryModel>>(
              stream: diaryStream,
              builder: (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text("No diaries yet"));
                }

                final diaries = _applyDiaryFilters(snapshot.data!);

                if (diaries.isEmpty) {
                  if (selectedDay != null) {
                    return const Center(
                      child: Text('No diary was created on this day'),
                    );
                  }
                  if (titleQuery.isNotEmpty) {
                    return const Center(
                      child: Text('No diary matched your search'),
                    );
                  }
                  return const Center(
                      child:
                          Text("No diaries this month"));
                }

                return ListView.builder(
                  itemCount: diaries.length,
                  itemBuilder: (context, index) {
                    final diary = diaries[index];

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      // only margin; no decoration here so ripple isn't hidden
                      child: Material(
                        // Material provides the surface for the ripple
                        color: Colors.white,
                        elevation: 2, // replaces the BoxShadow on Container
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                          highlightColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailsDiary(diary: diary),
                              ),
                            );
                          },
                          onLongPress: () async {
                            // handle long‑press actions if needed
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat("dd MMM yyyy").format(diary.created),
                                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Color(0xFF483D3C)),
                                      onPressed: () async {
                                        final bool? confirm = await showDeleteConfirmationDialog(context);
                                        if (confirm == true) {
                                          await firestoreService.deleteDiaryEntry(diary.id, userId!);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                Text(
                                  diary.title.trim().isEmpty ? 'Untitled' : diary.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  diary.context,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
