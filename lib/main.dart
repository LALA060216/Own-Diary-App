import 'package:diaryapp/services/auth/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:camera/camera.dart';

late List<CameraDescription> cameras;
final routeObserver = RouteObserver<PageRoute>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

  try{
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  // Keep moment images in cache across page navigations
  PaintingBinding.instance.imageCache.maximumSizeBytes = 300 * 1024 * 1024; // 300 MB
  PaintingBinding.instance.imageCache.maximumSize = 2000; // 2000 images

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
      navigatorObservers: [routeObserver],
    );
  }
}

