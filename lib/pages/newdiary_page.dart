import 'dart:io';
import 'dart:convert';
import 'package:diaryapp/services/firestore_service.dart';
import 'package:diaryapp/services/gemini_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:diaryapp/services/firebase_storage_service.dart';
import 'camera_page.dart';
import 'full_screen_image_page.dart';
import 'package:diaryapp/services/models/ai_chat_model.dart';
// 魔丸

class NewDiary extends StatefulWidget{
  final XFile? imageFile;
  final TextEditingController? previousDiaryController;
  final List<String>? previousImageUrls;
  final String? diaryId;
  const NewDiary({super.key, this.imageFile, this.previousDiaryController, this.previousImageUrls, this.diaryId});

  @override
  State<NewDiary> createState() => _NewDiaryState();
}

class _NewDiaryState extends State<NewDiary> {

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
  final chatModel = AIChatModel(
      prompt: 'You are a helpful assistant that generates keywords based on a diary entry. Extract the most essential keywords, using between 1 to 5 keywords depending on the complexity of the text. Do not force the output to 5 keywords; if 2 keywords are enough to describe the event, only return 2. \nReturn the result ONLY as a JSON array of strings. If forbidden content is detected, return an empty list.\n Example format: ["keyword1", "keyword2"]',
      model: 'gemma-3-27b-it'
    );



  // initialize controller listenable
  @override
  void initState() {
    super.initState();

    
    _id = widget.diaryId ?? '';
    if (widget.previousDiaryController != null) {
      _diaryController.text = widget.previousDiaryController!.text;
      created = true;
    }
    if (widget.previousImageUrls != null) {
      previousImageUrls = widget.previousImageUrls!;
    }
    if (widget.imageFile != null) {
        _images.add(File(widget.imageFile!.path));
        pickedImages.add(File(widget.imageFile!.path));
      createDiaryFromCam();
    }
    _diaryController.addListener(() async {
    if (_images.isEmpty && _diaryController.text.isEmpty && previousImageUrls.isEmpty) {
        await deleteDiary();
        return;
      }
      await waitDiaryCreate();
      await aupdateDiary(_diaryController.text);
    });
      
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
    if (_images.isEmpty && _diaryController.text.isEmpty) return;
    created = true;
    await createNewDiary();
    
  }

  Future<void> createDiaryFromCam() async {
    await createNewDiary();
    await uploadImages();
  }

  Future<void> createNewDiary() async {
    try {
      _firestoreService.incrementDiaryPostCount(_userId);
      _id = await _firestoreService.createDiaryEntry(
        userId: _userId,
        context: '',
        imageUrls: [],
        date: date,
      );
      await _firestoreService.updateStreak(_userId, DateTime.now());
    } catch (e) {
      error = true;
    }
  }



  //---------------------- Diary Update and Image Upload ------------------//
  
  Future<void> aupdateDiary(String context) async {
    if (_images.isNotEmpty && _id.isNotEmpty || _diaryController.text.isNotEmpty && _id.isNotEmpty) {
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
    if (!mounted) return;
    setState(() {
      _images.addAll(pickedFiles.map((file) => File(file.path)));
    });
    pickedImages = pickedFiles.map((file) => File(file.path)).toList();
    waitDiaryCreate().then((_) => uploadImages());
  }

  Future<void> openCameraPageAndUpload() async {
    final capturedImage = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraPage(fromNewDiary: true),
      ),
    );

    if (capturedImage != null) {
      if (!mounted) return;
      setState(() {
        _images.add(File(capturedImage.path));  
      });
      pickedImages.add(File(capturedImage.path)); 
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
    await _firebaseStorageService.deleteImage(isPreviousImage ? previousImageUrls[index] : imageUrls[index]);
    if (mounted) {
      setState(() {
        if (isPreviousImage) {
          previousImageUrls.removeAt(index);
        } else {
          _images.removeAt(index);
          imageUrls.removeAt(index);
        }
      });
    } else {
      if (isPreviousImage) {
        previousImageUrls.removeAt(index);
      } else {
        _images.removeAt(index);
        imageUrls.removeAt(index);
      }
    }
    await updateImageUrls();
    if (_images.isEmpty && _diaryController.text.isEmpty) {
        await deleteDiary();
    }
  }



  @override
  void dispose() {
    // Generate keywords in the background without blocking dispose
    if (_id.isNotEmpty && _diaryController.text.isNotEmpty) {
      GeminiService(chatModel: chatModel).sendMessage(_diaryController.text).then((keywords) async {
        try {
          // Parse the JSON array response
          List<dynamic> keywordList = jsonDecode(keywords);
          List<String> parsedKeywords = keywordList.map((k) => k.toString().trim()).toList();
          
          await _firestoreService.updateDiaryEntryKeywords(
            entryId: _id,
            newKeywords: parsedKeywords
          );
        } catch (e) {
          // Fallback to comma-separated parsing if JSON fails
          await _firestoreService.updateDiaryEntryKeywords(
            entryId: _id,
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
    );
  }

  AppBar appbar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      shadowColor: const Color(0xffEDEADE),
      elevation: 2,
      backgroundColor: const Color(0xfffffaf0),
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
          Navigator.pop(context);
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