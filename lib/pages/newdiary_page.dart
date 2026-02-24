import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:diaryapp/bottom_menu.dart';
import 'package:diaryapp/services/firebase_storage_service.dart';
import 'package:diaryapp/services/firestore_service.dart';
import 'package:diaryapp/services/gemini_service.dart';
import 'package:diaryapp/services/models/ai_chat_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'ai_content_options_dialog.dart';
import 'full_screen_image_page.dart';

class NewDiary extends StatefulWidget{
  final XFile? imageFile;
  final TextEditingController? previousDiaryController;
  final List<String>? previousImageUrls;
  final String? diaryId;
  final String? previousTitle;
  const NewDiary({super.key, this.imageFile, this.previousDiaryController, this.previousImageUrls, this.diaryId, this.previousTitle});

  @override
  State<NewDiary> createState() => _NewDiaryState();
}

class _NewDiaryState extends State<NewDiary> {
  static final RegExp _inlineImageTokenPattern = RegExp(r'\[img:(\d+)\]');
  static const int _maxImagesPerDiary = 3;

  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();

  final _firestoreService = FirestoreService();
  final _firebaseStorageService = FirebaseStorageService();
  final _userId = FirebaseAuth.instance.currentUser!.uid;

  final DateTime date = DateTime.now();
  final TextEditingController _diaryController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  bool isLoading = false;
  List<String> imageUrls = [];
  List<File> pickedImages = [];
  String _id = '';
  bool cam = false;
  bool created = false;
  List<String> previousImageUrls = [];
  bool error = false;
  String errorMessage = 'Failed to upload image';
  final chatModel = AIChatModel(
      prompt: 'You are a helpful assistant that generates keywords based on the diary entry. Extract between 1 to 5 numbers of keywords from the following diary entry and return them ONLY as a JSON array of strings with no additional text or explanation. Example format: ["keyword1", "keyword2", "keyword3", "keyword4", "keyword5"]\nIf have any forbidden content, just return a empty list\n',
      model: 'gemma-3-27b-it'
    );
  final titleChatModel = AIChatModel(
      prompt: 'Generate one short diary title based on the diary content. Keep it natural, specific, and between 3 to 8 words. Return ONLY the title text without quotes, labels, markdown, or extra explanation.',
      model: 'gemma-3-27b-it'
    );

  Timer? _titleDebounceTimer;
  bool _isGeneratingTitle = false;
  bool _isGeneratingDiaryContent = false;
  bool _isApplyingAiTitle = false;
  bool _isTitleManuallyEdited = false;
  bool _isDisposed = false;
  bool _isImageLimitCooldown = false;

  // initialize controller listenable
  @override
  void initState() {
    super.initState();
    _titleController.addListener(() async {
      try {
        if (!_isApplyingAiTitle) {
          _isTitleManuallyEdited = true;
          _titleDebounceTimer?.cancel();
        }
        if (_id.isEmpty) return;

        await _firestoreService.updateDiaryEntryTitle(
          entryId: _id,
          newTitle: _titleController.text,
        );
      } catch (_) {
        // Ignore transient write failures from listener updates.
      }
    });

    _id = widget.diaryId ?? '';
    if (widget.previousDiaryController != null) {
      _diaryController.text = widget.previousDiaryController!.text;
      created = true;
    }
    if (widget.previousTitle != null) {
      _titleController.text = widget.previousTitle!;
      if (widget.previousTitle!.trim().isNotEmpty) {
        _isTitleManuallyEdited = true;
      }
    }
    if (widget.previousImageUrls != null) {
      previousImageUrls = widget.previousImageUrls!;
    }
    if (widget.imageFile != null) {
        _images.add(File(widget.imageFile!.path));
        pickedImages.add(File(widget.imageFile!.path));
      createDiaryFromCam().catchError((error) {
        print('Error creating diary from camera: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating diary: $error')),
        );
      });
    }
    _diaryController.addListener(() async {
      try {
        if (_images.isEmpty && _diaryController.text.isEmpty && previousImageUrls.isEmpty) {
          await deleteDiary();
          return;
        }
        _scheduleAiTitleGeneration();
        await waitDiaryCreate();
        await aupdateDiary(_diaryController.text);
      } catch (_) {
        // Ignore listener-driven transient failures.
      }
    });
  }

  void _scheduleAiTitleGeneration() {
    if (_isTitleManuallyEdited) return;
    _titleDebounceTimer?.cancel();
    final diaryText = _diaryController.text.trim();
    if (diaryText.length < 10) return;
    _titleDebounceTimer = Timer(const Duration(seconds: 2), () {
      _generateAiTitleIfNeeded();
    });
  }

  String _sanitizeGeneratedTitle(String rawTitle) {
    String title = rawTitle.trim();
    if (title.startsWith('Error:')) return '';
    title = title.split('\n').first.trim();
    title = title.replaceAll(RegExp(r'^"|"$'), '');
    title = title.replaceAll(RegExp(r"^'|'$"), '');
    if (title.length > 70) {
      title = title.substring(0, 70).trim();
    }
    return title;
  }

  Future<void> _generateAiTitleIfNeeded() async {
    if (!mounted || _isDisposed) return;
    if (_isGeneratingTitle) return;
    if (_isTitleManuallyEdited) return;
    if (_titleController.text.trim().isNotEmpty) return;
    final diaryText = _diaryController.text.trim();
    if (diaryText.length < 10) return;

    _isGeneratingTitle = true;
    try {
      final shortenedInput = diaryText.length > 500 ? diaryText.substring(0, 500) : diaryText;
      final generated = await GeminiService(chatModel: titleChatModel).sendMessage(shortenedInput);
      final title = _sanitizeGeneratedTitle(generated);
      if (title.isEmpty) return;
      if (!mounted || _isDisposed) return;
      if (_titleController.text.trim().isNotEmpty) return;
      _isApplyingAiTitle = true;
      _titleController.text = title;
      _titleController.selection = TextSelection.fromPosition(
        TextPosition(offset: _titleController.text.length),
      );
      _isApplyingAiTitle = false;
    } finally {
      _isGeneratingTitle = false;
      _isApplyingAiTitle = false;
    }
  }

  Future<void> _showAiOptionsAndGenerate() async {
    if (_isGeneratingDiaryContent) return;

    final options = await showDialog<AiContentOptions>(
      context: context,
      builder: (_) => AiContentOptionsDialog(
        currentTitle: _titleController.text,
        currentContext: _diaryController.text,
      ),
    );

    if (options == null || !mounted) return;

    setState(() {
      _isGeneratingDiaryContent = true;
    });

    try {
      String generated;
      String? imageDescription;
      
      // Step 1: If user wants photo context, first get image description
      if (options.photoIsImportant && (_images.isNotEmpty || imageUrls.isNotEmpty || previousImageUrls.isNotEmpty)) {
        final imageSource = <String>[
          ..._images.map((file) => file.path),
          ...imageUrls,
          ...previousImageUrls,
        ];
      
      const imgDescriptionPrompt = 
          'You are describing an image for a personal diary entry. '
          'Describe what you see in natural, flowing language as if telling a friend. '
          'Focus on: what objects/people are in the image, the setting, colors, mood, and atmosphere. '
          'Use complete sentences and descriptive words. '
          'DO NOT use category labels like "food_buddy", "study_day", "funny_moment" etc. '
          'DO NOT output single words or classifications. '
          'Write 2-4 sentences describing the scene naturally. '
          'Example: "A plate of colorful pasta sits on a wooden table with a glass of red wine beside it. '
          'Warm afternoon sunlight streams through a nearby window, creating soft shadows."';
        
        final chatModelForDescription = AIChatModel(
          prompt: imgDescriptionPrompt,
          model: 'gemini-2.5-flash',
        );
        
        imageDescription = await GeminiService(chatModel: chatModelForDescription)
          .classifyDiaryImage(imageSource);
        
        // Clean the image description
        imageDescription = imageDescription.trim();
        if (imageDescription.startsWith('Error:')) {
          imageDescription = null;
        }
      }
      
      // Step 2: Generate diary content with or without image description
      final promptInput = options.buildPrompt(imageDescription: imageDescription);
      final chatModelForGeneration = AIChatModel(
        prompt: promptInput,
        model: 'gemini-2.5-flash',
      );

      generated = await GeminiService(chatModel: chatModelForGeneration).sendMessage(promptInput);

      final aiText = _sanitizeGeneratedContent(generated);
      if (aiText.isEmpty) return;

      _diaryController.text = aiText;
      _diaryController.selection = TextSelection.fromPosition(
        TextPosition(offset: _diaryController.text.length),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isGeneratingDiaryContent = false;
      });
    }
  }

  String _sanitizeGeneratedContent(String rawText) {
    var cleaned = rawText.trim();
    if (cleaned.startsWith('Error:')) return '';
    cleaned = cleaned
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
        .trim();
    return cleaned;
  }

  //---------------------- Diary Creation and Delete ------------------//

  Future<void> deleteDiary() async {
    if (_id.isEmpty) return;
    await _firestoreService.deleteDiaryEntry(_id, _userId);
    created = false;
    if (!mounted) return;
    setState(() {
      _id = '';
    });
  }

  Future<void> waitDiaryCreate() async {
    if (_id.isNotEmpty) return;
    if (created) return;
    if (_images.isEmpty && _diaryController.text.trim().isEmpty) return;
    created = true;
    await createNewDiary();
  }

  Future<void> createDiaryFromCam() async {
    await createNewDiary();
    await uploadImages();
  }

  Future<void> createNewDiary() async {
    try {
      await _firestoreService.incrementDiaryPostCount(_userId);
      _id = await _firestoreService.createDiaryEntry(
        userId: _userId,
        title: _titleController.text.trim(),
        context: '',
        imageUrls: [],
        date: date,
      );
      await _firestoreService.updateStreak(_userId, DateTime.now());
    } catch (e) {
      error = true;
      rethrow;
    }
  }

  //---------------------- Diary Update and Image Upload ------------------//

  Future<void> aupdateDiary(String context) async {
    if (_images.isNotEmpty && _id.isNotEmpty || _diaryController.text.trim().isNotEmpty && _id.isNotEmpty) {
      try {
        await _firestoreService.updateDiaryEntryContext(
          entryId: _id,
          newContext: context,
        );
      } catch (e) {
        error = true;
      }
    }
  }

  Future<void> pickImages() async {
    final currentImageCount = previousImageUrls.length + _images.length;
    
    if (currentImageCount >= _maxImagesPerDiary) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $_maxImagesPerDiary images per diary')),
      );
      // Set cooldown to prevent spam clicking
      setState(() {
        _isImageLimitCooldown = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isImageLimitCooldown = false;
          });
        }
      });
      return;
    }
    
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isEmpty) return;
    
    final remainingSlots = _maxImagesPerDiary - currentImageCount;
    final filesToAdd = pickedFiles.take(remainingSlots).toList();
    
    if (pickedFiles.length > remainingSlots && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only $remainingSlots more image(s) allowed (max $_maxImagesPerDiary per diary)')),
      );
    }
    
    final startIndex = previousImageUrls.length + _images.length;
    final picked = filesToAdd.map((file) => File(file.path)).toList();
    if (!mounted) return;
    setState(() {
      _images.addAll(picked);
    });
    pickedImages = picked;
    for (var i = 0; i < picked.length; i++) {
      _insertImageTokenAtCursor(startIndex + i);
    }
    waitDiaryCreate().then((_) => uploadImages());
  }

  Future<void> openCameraPageAndUpload() async {
    final currentImageCount = previousImageUrls.length + _images.length;
    
    if (currentImageCount >= _maxImagesPerDiary) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $_maxImagesPerDiary images per diary')),
      );
      // Set cooldown to prevent spam clicking
      setState(() {
        _isImageLimitCooldown = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isImageLimitCooldown = false;
          });
        }
      });
      return;
    }
    
    final XFile? capturedImage = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );

    if (capturedImage != null) {
      final imageIndex = previousImageUrls.length + _images.length;
      if (!mounted) return;
      setState(() {
        _images.add(File(capturedImage.path));  
      });
      pickedImages.add(File(capturedImage.path)); 
      _insertImageTokenAtCursor(imageIndex);
      waitDiaryCreate().then((_) => uploadImages());
    }
  }

  Future<void> uploadImages() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    for (final file in pickedImages) {
      final url = await _firebaseStorageService.uploadImage(file, _userId, _id);
      if (url != null) {
        imageUrls.add(url);
      }
    }
    pickedImages.clear();
    await updateImageUrls();
  }

  Future<void> updateImageUrls() async {
    try {
      await _firestoreService.updateDiaryEntryImageUrls(
        entryId: _id,
        newImageUrls: [...previousImageUrls, ...imageUrls],
      );
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeImageAt(int index, bool isPreviousImage) async {
    final localIndex = isPreviousImage ? index : index - previousImageUrls.length;
    if (!isPreviousImage && (localIndex < 0 || localIndex >= imageUrls.length)) {
      return;
    }
    final targetUrl = isPreviousImage ? previousImageUrls[index] : imageUrls[localIndex];
    await _firebaseStorageService.deleteImage(targetUrl);
    if (mounted) {
      setState(() {
        if (isPreviousImage) {
          previousImageUrls.removeAt(index);
        } else {
          _images.removeAt(localIndex);
          imageUrls.removeAt(localIndex);
        }
      });
    } else {
      if (isPreviousImage) {
        previousImageUrls.removeAt(index);
      } else {
        _images.removeAt(localIndex);
        imageUrls.removeAt(localIndex);
      }
    }
    _rewriteImageTokensAfterRemove(index);
    await updateImageUrls();
    if (_images.isEmpty && _diaryController.text.trim().isEmpty && previousImageUrls.isEmpty) {
        await deleteDiary();
    }
  }

  List<String> _allImagePaths() {
    return [
      ...previousImageUrls,
      ..._images.map((file) => file.path),
    ];
  }

  void _insertImageTokenAtCursor(int imageIndex) {
    final token = '[img:$imageIndex]';
    final text = _diaryController.text;
    final selection = _diaryController.selection;
    if (!selection.isValid || selection.start < 0 || selection.end < 0) {
      _diaryController.text = text.isEmpty ? token : '$text $token';
      _diaryController.selection = TextSelection.fromPosition(
        TextPosition(offset: _diaryController.text.length),
      );
      return;
    }

    final start = selection.start;
    final end = selection.end;
    final replacement = token;
    final newText = text.replaceRange(start, end, replacement);
    _diaryController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
  }

  void _rewriteImageTokensAfterRemove(int removedIndex) {
    final original = _diaryController.text;
    final rewritten = original.replaceAllMapped(_inlineImageTokenPattern, (match) {
      final raw = match.group(1);
      final parsed = int.tryParse(raw ?? '');
      if (parsed == null) return match.group(0) ?? '';
      if (parsed == removedIndex) return '';
      if (parsed > removedIndex) return '[img:${parsed - 1}]';
      return '[img:$parsed]';
    });

    if (rewritten == original) return;
    _diaryController.value = _diaryController.value.copyWith(
      text: rewritten,
      selection: TextSelection.collapsed(
        offset: rewritten.length.clamp(0, rewritten.length),
      ),
      composing: TextRange.empty,
    );
  }


  @override
  void dispose() {
    _isDisposed = true;
    final diaryTextAtDispose = _diaryController.text.trim();
    final titleAtDispose = _titleController.text.trim();
    final entryIdAtDispose = _id;

    // Generate title in background without touching disposed controllers
    _titleDebounceTimer?.cancel();
    if (!_isTitleManuallyEdited && diaryTextAtDispose.length >= 20 && titleAtDispose.isEmpty) {
      GeminiService(chatModel: titleChatModel).sendMessage(diaryTextAtDispose).then((generated) async {
        final title = _sanitizeGeneratedTitle(generated);
        if (title.isEmpty) return;
        if (_isTitleManuallyEdited) return;

        if (entryIdAtDispose.isNotEmpty) {
          await _firestoreService.updateDiaryEntryTitle(
            entryId: entryIdAtDispose,
            newTitle: title,
          );
        }
      });
    }

    _titleController.dispose();
    if (entryIdAtDispose.isNotEmpty && diaryTextAtDispose.isNotEmpty) {
      GeminiService(chatModel: chatModel).sendMessage(diaryTextAtDispose).then((keywords) async {
        try {
          // Parse the JSON array response
          List<dynamic> keywordList = jsonDecode(keywords);
          List<String> parsedKeywords = keywordList.map((k) => k.toString().trim()).toList();
          
          await _firestoreService.updateDiaryEntryKeywords(
            entryId: entryIdAtDispose,
            newKeywords: parsedKeywords
          );
        } catch (e) {
          // Fallback to comma-separated parsing if JSON fails
          await _firestoreService.updateDiaryEntryKeywords(
            entryId: entryIdAtDispose,
            newKeywords: keywords.split(',').map((k) => k.trim()).toList()
          );
        }
      });
    }
    
    _diaryController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      resizeToAvoidBottomInset: false,
      appBar: appbar(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double containerHeight = constraints.maxHeight * 0.65;
          final double imagePickerHeight = constraints.maxHeight * 0.25;
          final double width = constraints.maxWidth * 0.95;

          return Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  textfield(containerHeight, width),
                  Container(height: 20),
                  imagePicker(width, imagePickerHeight)
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Container imagePicker(double width, double imagePickerHeight) {
    final List<String> allPaths = [
      ...previousImageUrls,
      ..._images.map((file) => file.path),
    ];
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: imagePickerHeight,
            width: width * 0.80,
            padding: EdgeInsets.only(left: 15,right: 10),
            child: _images.isEmpty && previousImageUrls.isEmpty
                ? const Text(
                  "No images selected",
                  style: TextStyle(
                    fontFamily: 'lobstertwo',
                    fontSize: 16,
                    color: Colors.black,
                  ),)
                :
                ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: allPaths.length,
                  itemBuilder: (context, index) {
                    final bool isUrl = index < previousImageUrls.length;
                    final String tag = allPaths[index];
                    final double itemWidth = 100;
                    final double itemHeight = imagePickerHeight * 0.6;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenImagePage(
                                imageUrls: allPaths,
                                initialIndex: index,
                              ),
                            ),
                          );
                        },
                        child: Hero(
                          tag: tag,
                          child: getImages(
                            url: isUrl ? previousImageUrls[index] : null,
                            file: isUrl ? null : _images[index - previousImageUrls.length],
                            width: itemWidth,
                            height: itemHeight,
                            index: index,
                            getImagesUrl: isUrl,
                          ),
                        ),
                      ),
                    );
                  },
                ),                  
          ),
          Container(
            height: imagePickerHeight*0.7,
            width: width * 0.20,
            decoration: BoxDecoration(
              color: Color(0xffF9F6EE),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Color(0xffEDEADE),
                  spreadRadius: 2,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: _isImageLimitCooldown ? null : pickImages,
                  child: Icon(Icons.add),
                ),
                Divider(
                  thickness: 2,
                  height: 1,
                  color: Color(0xffEDEADE),
                ),
                GestureDetector(
                  onTap: _isImageLimitCooldown ? null : openCameraPageAndUpload,
                  child: Icon(Icons.camera_alt, size: 30, color: Colors.black54),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container textfield(double containerHeight, double width) {
    return Container(
      width: width,
      height: containerHeight,
      decoration: BoxDecoration(
        color: const Color(0xffF9F6EE),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffEDEADE),
            spreadRadius: 2,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: "Add a title...",
                hintStyle: TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1.5,
            color: Color(0xfff1e9d2),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Date: ",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                  ),
                    Text(
                      date.toString().substring(0, 10),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: (_isGeneratingDiaryContent || isLoading) ? null : _showAiOptionsAndGenerate,
                  icon: _isGeneratingDiaryContent
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(_isGeneratingDiaryContent ? 'Generating...' : isLoading ? 'Uploading...' : 'AI Draft'),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1.5,
            color: Color(0xfff1e9d2),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: TextField(
                    controller: _diaryController,
                    maxLines: null,
                    expands: true,
                    decoration: InputDecoration(
                      hintText: "Write here...",
                      contentPadding: EdgeInsets.all(16),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_allImagePaths().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceEvenly,
                children: List.generate(_allImagePaths().length, (index) {
                  return OutlinedButton(
                    onPressed: () => _insertImageTokenAtCursor(index),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Insert img ${index + 1}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  AppBar appbar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xffffffff),
      centerTitle: true,
      title: Text(
        'New Diary', 
        style: TextStyle(
          fontSize: 30,
          fontFamily: 'Lobstertwo'
        ),
      ), 
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomMenu()));
        },
      ),
    );
  }

  Stack getImages({
    required String? url, 
    required File? file, 
    required double width, 
    required double height, 
    required int index, 
    required bool getImagesUrl
  }) {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(right: 8),
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: 
            getImagesUrl ? Image.network(url!,fit: BoxFit.cover,): Image.file(file!, fit:BoxFit.cover)
          ),
        ),
        Positioned(
          top: 4,
          right: width * 0.1,
          child: GestureDetector(
            onTap: isLoading ? null : () => removeImageAt(index, getImagesUrl),
            child: Container(
              height: 20,
              width: 20,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: isLoading ?
                const CircularProgressIndicator(
                  strokeWidth: 1.5, 
                  color: Colors.white
                )

                : const Icon( 
                  Icons.close,
                  size: 20,
                  color: Colors.white,
                ),
            ),
          ),
        )
      ],
    );
  }
}