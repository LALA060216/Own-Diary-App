import 'dart:convert';
import 'dart:async';
import 'package:diaryapp/bottom_menu.dart';
import 'package:diaryapp/services/firestore_service.dart';
import 'package:diaryapp/services/gemini_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:diaryapp/services/firebase_storage_service.dart';
import 'full_screen_image_page.dart';
import 'package:diaryapp/services/models/ai_chat_model.dart';
// 魔丸

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

  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();

  final _firestoreService = FirestoreService();
  final _firebaseStorageService = FirebaseStorageService();
  final _userId = FirebaseAuth.instance.currentUser!.uid;


  
  
  final DateTime date = DateTime.now();
  bool isLoading = false;
  List<String> imageUrls = [];
  List<File> pickedImages = [];
  String _id =  '';
  bool cam = false;
  bool created = false;
  List<String> previousImageUrls = [];
  


  final TextEditingController _diaryController = TextEditingController();
  bool error = false;
  String errorMessage = "Failed to upload image";
  final TextEditingController _titleController = TextEditingController();
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
  bool _isApplyingAiTitle = false;
  bool _isTitleManuallyEdited = false;
  bool _isDisposed = false;

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
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isEmpty) return;
    final startIndex = previousImageUrls.length + _images.length;
    final picked = pickedFiles.map((file) => File(file.path)).toList();
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

  InlineSpan _buildInlinePreviewSpan(String text, List<String> allPaths) {
    final spans = <InlineSpan>[];
    int cursor = 0;
    for (final match in _inlineImageTokenPattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: text.substring(cursor, match.start),
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        );
      }

      final index = int.tryParse(match.group(1) ?? '');
      if (index != null && index >= 0 && index < allPaths.length) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
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
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEADE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.photo, size: 14, color: Colors.black54),
                    SizedBox(width: 4),
                    Text(
                      'image',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: match.group(0),
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        );
      }
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(cursor),
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      );
    }

    if (spans.isEmpty) {
      spans.add(
        const TextSpan(
          text: '',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      );
    }

    return TextSpan(children: spans);
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
                  onTap: pickImages,
                  child: Icon(Icons.add),
                ),
                Divider(
                  thickness: 2,
                  height: 1,
                  color: Color(0xffEDEADE),
                ),
                GestureDetector(
                  onTap: () async {
                    await openCameraPageAndUpload();
                  },
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
    final allPaths = _allImagePaths();
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
              mainAxisAlignment: MainAxisAlignment.start,
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
                if (_diaryController.text.contains('[img:'))
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xfff1e9d2), width: 1),
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: RichText(
                        text: _buildInlinePreviewSpan(
                          _diaryController.text,
                          allPaths,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (allPaths.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(allPaths.length, (index) {
                  return OutlinedButton.icon(
                    onPressed: () => _insertImageTokenAtCursor(index),
                    icon: const Icon(Icons.photo, size: 16),
                    label: Text('Insert img ${index + 1}'),
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