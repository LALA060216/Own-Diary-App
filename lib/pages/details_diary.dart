import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../services/firebase_storage_service.dart';
import '../services/firestore_service.dart';
import '../services/models/diary_entry_model.dart';
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
  bool _didAutoScrollToFocusToken = false;
  int _focusScrollAttempt = 0;
  bool _highlightFocusToken = false;

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
    if (!mounted) return;
    setState(() {
      _newImages.addAll(pickedFiles.map((file) => File(file.path)));
    });
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
                      Icon(
                        Icons.photo,
                        size: 14,
                        color: shouldHighlightFocusedToken
                            ? const Color(0xFF8A6A00)
                            : Colors.black54,
                      ),
                      const SizedBox(width: 4),
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
      appBar: AppBar(
        title: const Text('Diary Details'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _isSaving ? null : _pickImages,
              icon: const Icon(Icons.add),
              tooltip: 'Add Image',
            ),
          IconButton(
            onPressed: _isSaving ? null : (_isEditing ? _saveDiary : _toggleEditMode),
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            tooltip: _isEditing ? 'Save' : 'Edit',
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _isEditing
                ? TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Add a title...',
                      border: InputBorder.none,
                    ),
                  )
                : Text(
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
            const SizedBox(height: 20),
            const SizedBox(height: 16),
            _isEditing
                ? TextField(
                    controller: _contextController,
                    minLines: 6,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Write here...',
                      border: OutlineInputBorder(),
                    ),
                  )
                : RichText(
                    text: _buildInlineContextSpan(_currentContext),
                  ),
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
