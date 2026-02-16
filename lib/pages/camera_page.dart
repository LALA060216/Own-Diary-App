import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:diaryapp/main.dart';
import 'package:diaryapp/pages/newdiary_page.dart' ;

class CameraPage extends StatefulWidget {
  final bool? fromNewDiary;
  const CameraPage({super.key, this.fromNewDiary});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
 
    



  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      cameras[0], 
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Camera',
          style: TextStyle(
            fontSize: 30,
            fontFamily: 'Lobstertwo',
          ),
        ),
        backgroundColor: Color(0xffF9F6EE),
        centerTitle: true ,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.large(
        backgroundColor: Color(0xffF9F6EE),
        shape: CircleBorder(),
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();
            if (!mounted) return;
            if (widget.fromNewDiary != null) {
              Navigator.pop(context, image);
            }else{
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(
                builder: (context) => NewDiary(imageFile: image)
              )
            );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error capturing image: $e')),
            );
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
      body: Stack(
        children: [
          cameraView(),
          Positioned(
            top: 60,
            left: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Container(
                    height: 20,
                    width: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  Container(
                    height: 90,
                    width: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ],
              )
              )
          ),
          Positioned(
            bottom: 120,
            right: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 20,
                      right: 0,
                      child: Container(
                        height: 20,
                        width: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        height: 90,
                        width: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              )
          ),
          Positioned(
            top: 60,
            right: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        height: 20,
                        width: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        height: 90,
                        width: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              )
          ),
          Positioned(
            bottom: 120,
            left: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 20,
                      left: 0,
                      child: Container(
                        height: 20,
                        width: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        height: 90,
                        width: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
              )
          )
        
        
        ],
      ),
      
    );
  }

  FutureBuilder<void> cameraView() {
    return FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              final previewSize = _controller.value.previewSize;
              if (previewSize == null) {
                return const SizedBox.expand();
              }
              return SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: previewSize.height,
                    height: previewSize.width,
                    child: CameraPreview(_controller),
                  ),
                ),
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        );
  }
}