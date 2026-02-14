import 'dart:io';
import 'package:diaryapp/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:diaryapp/services/firebase_storage_service.dart';


class NewDiary extends StatefulWidget{
  const NewDiary({super.key});

  @override
  State<NewDiary> createState() => _NewDiaryState();
}

class _NewDiaryState extends State<NewDiary> {
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  final _firestoreService = FirestoreService();
  final _firebaseStorageService = FirebaseStorageService();
  final _userId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _diaryController = TextEditingController();
  bool error = false;
  String errorMessage = "Failed to upload image";


  Future<List<String>> uploadImages() async {
    List<String> imageUrls = [];
    for (File image in _images) {
      String? url = await _firebaseStorageService.uploadImage(image, _userId);
      if (url != null) {
        imageUrls.add(url);
      }
      else {
        error = true;
      }
    }
    return imageUrls;
  }

  void createNewDiary(String context) async {
    try {
      await _firestoreService.createDiaryEntry(
        userId: _userId,
        context: context,
        imageUrls: await uploadImages(), // Add logic to upload images and get their URLs
      );
    } catch (e) {
      error = true;
    }
  }


  Future<void> pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isEmpty) {
      return;
    }

    setState(() {
      _images.addAll(pickedFiles.map((file) => File(file.path)));
    });
  }

  void removeImageAt(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  @override
  void dispose() {
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
                  Container(
                    padding: EdgeInsets.only(top: 15),
                    height: 40,
                    child: Center(
                      child: Text(
                        "Add Images",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontFamily: 'lobstertwo',
                        ),
                      ),
                    ),
                    ),
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
    return Container(
                  width: width,
                  child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: imagePickerHeight,
                            width: 300,
                            padding: EdgeInsets.only(top: 20, left: 15,right: 10),
                            child: _images.isEmpty
                                ? const Text(
                                  "No images selected",
                                  style: TextStyle(
                                    fontFamily: 'lobstertwo',
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),)
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _images.length,
                                    itemBuilder: (context, index) {
                                      return Stack(
                                        children: [
                                          Container(
                                            margin: EdgeInsets.only(right: 8),
                                            width: 100,
                                            height: 100,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.file(
                                                _images[index],
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () => removeImageAt(index),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.close,
                                                  size: 20,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      );
                                    },
                                  ),
                          ),
                          Container(
                            height: 130,
                            width: 70,
                            decoration: BoxDecoration(
                              color: Color(0xfff5f5f5),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xffe7eae5),
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
                                  thickness: 1,
                                  height: 1,
                                  color: Color(0xffe7eae5),
                                ),
                                Icon(Icons.camera)
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
                    color: Color(0xffF9F6EE),
                    borderRadius: BorderRadius.circular(10),
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
                              "date",
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
                            hintText: "Write your diary entry here...",
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
      shadowColor: Color(0xffEDEADE),
      elevation: 2,
      backgroundColor: Color(0xfffffaf0),
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
      actions: [
        Container(
          margin: EdgeInsets.only(right: 20),
          alignment: Alignment.center,
          width: 37,
          child: 
            IconButton(
              onPressed: () {
                createNewDiary(_diaryController.text);
                if (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
                  );
                }
                else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Diary entry created successfully!")),
                  );
                }

              }, 
              icon: Icon(
                Icons.save_alt_outlined,
                size: 28,
              ),
            )
        )
      ],
    );
  }
}