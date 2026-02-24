import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/firebase_storage_service.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../services/models/ai_chat_model.dart';
import '../services/models/diary_entry_model.dart';
import 'ai_content_options_dialog.dart';
import 'full_screen_image_page.dart';

class DetailsDiary extends StatefulWidget {
  final DiaryEntryModel diary;
  final int? focusImageIndex;

  const DetailsDiary({
    super.key,
    required this.diary,
    this.focusImageIndex,
  });

  @override
  State<DetailsDiary> createState() => _DetailsDiaryState();
}

class _DetailsDiaryState extends State<DetailsDiary> {
  static final RegExp _inlineImageTokenPattern = RegExp(r'\[img:(\d+)\]');
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _focusTokenKey = GlobalKey();

  late final TextEditingController _titleController;
  late final TextEditingController _contextController;

  late String _currentTitle;
  late String _currentContext;
  late List<String> _imageUrls;
  final List<File> _newImages = [];

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isGeneratingDiaryContent = false;
  bool _didAutoScrollToFocusToken = false;
  int _focusScrollAttempt = 0;
  bool _highlightFocusToken = false;

  List<String> _allImagePaths() {
    return [
      ..._imageUrls,
      ..._newImages.map((file) => file.path),
    ];
  }

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.diary.title;
    _currentContext = widget.diary.context;
    _imageUrls = List<String>.from(widget.diary.imageUrls);

    _titleController = TextEditingController(text: _currentTitle);
    _contextController = TextEditingController(text: _currentContext);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToFocusTokenIfNeeded();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  void _scrollToFocusTokenIfNeeded() {
    if (!mounted) return;
    if (_didAutoScrollToFocusToken) return;
    if (_isEditing) return;
    final targetIndex = widget.focusImageIndex;
    if (targetIndex == null || targetIndex < 0) return;

    final focusContext = _focusTokenKey.currentContext;
    if (focusContext == null) {
      if (_focusScrollAttempt >= 8) return;
      _focusScrollAttempt++;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFocusTokenIfNeeded();
      });
      return;
    }

    _didAutoScrollToFocusToken = true;
    _highlightFocusToken = true;
    setState(() {});
    Scrollable.ensureVisible(
      focusContext,
      alignment: 0.2,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      setState(() {
        _highlightFocusToken = false;
      });
    });
  }

  Future<void> _pickImages() async {
    if (!_isEditing) return;
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isEmpty) return;
    final startIndex = _imageUrls.length + _newImages.length;
    if (!mounted) return;
    setState(() {
      _newImages.addAll(pickedFiles.map((file) => File(file.path)));
    });
    for (var i = 0; i < pickedFiles.length; i++) {
      _insertImageTokenAtCursor(startIndex + i);
    }
  }

  Future<void> _openCameraAndPick() async {
    if (!_isEditing) return;
    final XFile? capturedImage = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );

    if (capturedImage == null || !mounted) return;
    final imageIndex = _imageUrls.length + _newImages.length;
    setState(() {
      _newImages.add(File(capturedImage.path));
    });
    _insertImageTokenAtCursor(imageIndex);
  }

  void _insertImageTokenAtCursor(int imageIndex) {
    final token = '[img:$imageIndex]';
    final text = _contextController.text;
    final selection = _contextController.selection;
    if (!selection.isValid || selection.start < 0 || selection.end < 0) {
      _contextController.text = text.isEmpty ? token : '$text $token';
      _contextController.selection = TextSelection.fromPosition(
        TextPosition(offset: _contextController.text.length),
      );
      return;
    }

    final start = selection.start;
    final end = selection.end;
    final replacement = token;
    final newText = text.replaceRange(start, end, replacement);
    _contextController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
  }

  void _rewriteImageTokensAfterRemove(int removedIndex) {
    final original = _contextController.text;
    final rewritten = original.replaceAllMapped(_inlineImageTokenPattern, (match) {
      final raw = match.group(1);
      final parsed = int.tryParse(raw ?? '');
      if (parsed == null) return match.group(0) ?? '';
      if (parsed == removedIndex) return '';
      if (parsed > removedIndex) return '[img:${parsed - 1}]';
      return '[img:$parsed]';
    });

    if (rewritten == original) return;
    _contextController.value = _contextController.value.copyWith(
      text: rewritten,
      selection: TextSelection.collapsed(
        offset: rewritten.length.clamp(0, rewritten.length),
      ),
      composing: TextRange.empty,
    );
  }

  Future<void> _removeImageAt(int index, bool isExistingImage) async {
    if (!_isEditing || _isSaving) return;

    try {
      if (isExistingImage) {
        if (index < 0 || index >= _imageUrls.length) return;
        final imageUrl = _imageUrls[index];
        await _storageService.deleteImage(imageUrl);
        if (!mounted) return;
        setState(() {
          _imageUrls.removeAt(index);
        });
        _rewriteImageTokensAfterRemove(index);
        await _firestoreService.updateDiaryEntryImageUrls(
          entryId: widget.diary.id,
          newImageUrls: List<String>.from(_imageUrls),
        );
      } else {
        final localIndex = index - _imageUrls.length;
        if (localIndex < 0 || localIndex >= _newImages.length) return;
        if (!mounted) return;
        setState(() {
          _newImages.removeAt(localIndex);
        });
        _rewriteImageTokensAfterRemove(index);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete image. Please try again.')),
      );
    }
  }

  void _toggleEditMode() {
    if (_isSaving) return;
    setState(() {
      if (_isEditing) {
        _titleController.text = _currentTitle;
        _contextController.text = _currentContext;
        _newImages.clear();
      }
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveDiary() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final trimmedTitle = _titleController.text.trim();
      final newContext = _contextController.text;
      final uploadedUrls = List<String>.from(_imageUrls);

      for (final file in _newImages) {
        final url = await _storageService.uploadImage(file, widget.diary.userId, widget.diary.id);
        if (url != null) {
          uploadedUrls.add(url);
        }
      }

      await _firestoreService.updateDiaryEntryTitle(
        entryId: widget.diary.id,
        newTitle: trimmedTitle,
      );
      await _firestoreService.updateDiaryEntryContext(
        entryId: widget.diary.id,
        newContext: newContext,
      );
      await _firestoreService.updateDiaryEntryImageUrls(
        entryId: widget.diary.id,
        newImageUrls: uploadedUrls,
      );

      if (!mounted) return;
      setState(() {
        _currentTitle = trimmedTitle;
        _currentContext = newContext;
        _imageUrls = uploadedUrls;
        _newImages.clear();
        _isEditing = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showAiOptionsAndGenerate() async {
    if (_isGeneratingDiaryContent) return;

    final options = await showDialog<AiContentOptions>(
      context: context,
      builder: (_) => AiContentOptionsDialog(
        currentTitle: _titleController.text,
        currentContext: _contextController.text,
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
      if (options.photoIsImportant && (_imageUrls.isNotEmpty || _newImages.isNotEmpty)) {
        final imageSource = <String>[
          ..._imageUrls,
          ..._newImages.map((file) => file.path),
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
        prompt: 'You are a helpful diary writing assistant.',
        model: 'gemini-2.5-flash-lite',
      );

      generated = await GeminiService(chatModel: chatModelForGeneration).sendMessage(promptInput);

      final aiText = _sanitizeGeneratedContent(generated);
      if (aiText.isEmpty) return;

      _contextController.text = aiText;
      _contextController.selection = TextSelection.fromPosition(
        TextPosition(offset: _contextController.text.length),
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

  InlineSpan _buildInlineContextSpan(String text) {
    final spans = <InlineSpan>[];
    int cursor = 0;
    bool attachedFocusKey = false;
    final focusIndex = widget.focusImageIndex;

    for (final match in _inlineImageTokenPattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: text.substring(cursor, match.start),
            style: const TextStyle(fontSize: 18, color: Colors.black87),
          ),
        );
      }

      final index = int.tryParse(match.group(1) ?? '');
      if (index != null && index >= 0 && index < _imageUrls.length) {
        final shouldAttachFocusKey =
            !attachedFocusKey && focusIndex != null && index == focusIndex;
        if (shouldAttachFocusKey) {
          attachedFocusKey = true;
        }
        final shouldHighlightFocusedToken =
            shouldAttachFocusKey && _highlightFocusToken;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImagePage(
                      imageUrls: _imageUrls,
                      initialIndex: index,
                    ),
                  ),
                );
              },
              child: AnimatedScale(
                scale: shouldHighlightFocusedToken ? 1.04 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: AnimatedContainer(
                  key: shouldAttachFocusKey ? _focusTokenKey : null,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: shouldHighlightFocusedToken
                        ? const Color(0xFFBDBDBD)
                        : const Color(0xFFEDEADE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'image',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: match.group(0),
            style: const TextStyle(fontSize: 18, color: Colors.black54),
          ),
        );
      }

      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(cursor),
          style: const TextStyle(fontSize: 18, color: Colors.black87),
        ),
      );
    }

    if (spans.isEmpty) {
      spans.add(
        const TextSpan(
          text: '',
          style: TextStyle(fontSize: 18, color: Colors.black87),
        ),
      );
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: const Color(0xffffffff),
        surfaceTintColor: const Color(0xffffffff),
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          _isEditing ? 'Edit Diary' : 'Diary Details',
          style: const TextStyle(
            fontSize: 30,
            fontFamily: 'Lobstertwo',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : (_isEditing ? _saveDiary : _toggleEditMode),
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            tooltip: _isEditing ? 'Save' : 'Edit',
          ),
        ],
      ),
      body: _isEditing ? _buildEditingBody() : _buildDetailsBody(),
    );
  }

  Widget _buildDetailsBody() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentTitle.trim().isEmpty ? 'Untitled' : _currentTitle,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('dd MMM yyyy').format(widget.diary.created),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (_imageUrls.isNotEmpty) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imageUrls.length,
                itemBuilder: (context, index) {
                  final imageUrl = _imageUrls[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImagePage(
                              imageUrls: _imageUrls,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: imageUrl,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: MediaQuery.of(context).size.width * 0.8,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),
          RichText(
            text: _buildInlineContextSpan(_currentContext),
          ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildEditingBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double containerHeight = constraints.maxHeight * 0.65;
        final double imagePickerHeight = constraints.maxHeight * 0.25;
        final double width = constraints.maxWidth * 0.95;

        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _editingTextField(containerHeight, width),
                const SizedBox(height: 20),
                _editingImagePicker(width, imagePickerHeight),
              ],
            ),
          ),
        );
      },
    );
  }

  Container _editingImagePicker(double width, double imagePickerHeight) {
    final allPaths = _allImagePaths();
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: imagePickerHeight,
            width: width * 0.80,
            padding: const EdgeInsets.only(left: 15, right: 10),
            child: allPaths.isEmpty
                ? const Text(
                    'No images selected',
                    style: TextStyle(
                      fontFamily: 'lobstertwo',
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: allPaths.length,
                    itemBuilder: (context, index) {
                      final bool isExisting = index < _imageUrls.length;
                      final String tag = allPaths[index];
                      final double itemWidth = 100;
                      final double itemHeight = imagePickerHeight * 0.6;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Hero(
                          tag: tag,
                          child: _buildEditableImageTile(
                            imageUrl: isExisting ? _imageUrls[index] : null,
                            imageFile: isExisting ? null : _newImages[index - _imageUrls.length],
                            width: itemWidth,
                            height: itemHeight,
                            index: index,
                            isExistingImage: isExisting,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            height: imagePickerHeight * 0.7,
            width: width * 0.20,
            decoration: BoxDecoration(
              color: const Color(0xffF9F6EE),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
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
                  onTap: _isSaving ? null : _pickImages,
                  child: const Icon(Icons.add),
                ),
                const Divider(
                  thickness: 2,
                  height: 1,
                  color: Color(0xffEDEADE),
                ),
                GestureDetector(
                  onTap: _isSaving ? null : _openCameraAndPick,
                  child: const Icon(Icons.camera_alt, size: 30, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container _editingTextField(double containerHeight, double width) {
    return Container(
      width: width,
      height: containerHeight,
      decoration: BoxDecoration(
        color: const Color(0xffF9F6EE),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0xffEDEADE),
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
                hintText: 'Add a title...',
                hintStyle: TextStyle(
                  color: Color(0xFFB0B0B0),
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1.5,
            color: Color(0xfff1e9d2),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Date: ',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy-MM-dd').format(widget.diary.created),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: (_isGeneratingDiaryContent || _isSaving) ? null : _showAiOptionsAndGenerate,
                  icon: _isGeneratingDiaryContent
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(_isGeneratingDiaryContent ? 'Generating...' : _isSaving ? 'Saving...' : 'AI Draft'),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1.5,
            color: Color(0xfff1e9d2),
          ),
          Expanded(
            child: TextField(
              controller: _contextController,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                hintText: 'Write here...',
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_allImagePaths().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(_allImagePaths().length, (index) {
                  return OutlinedButton(
                    onPressed: () => _insertImageTokenAtCursor(index),
                    child: Text('Insert img ${index + 1}'),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Stack _buildEditableImageTile({
    required String? imageUrl,
    required File? imageFile,
    required double width,
    required double height,
    required int index,
    required bool isExistingImage,
  }) {
    final allPaths = _allImagePaths();
    return Stack(
      children: [
        GestureDetector(
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
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isExistingImage
                  ? Image.network(imageUrl!, fit: BoxFit.cover)
                  : Image.file(imageFile!, fit: BoxFit.cover),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: width * 0.1,
          child: GestureDetector(
            onTap: _isSaving ? null : () => _removeImageAt(index, isExistingImage),
            child: Container(
              height: 20,
              width: 20,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white)
                  : const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
