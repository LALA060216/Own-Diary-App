import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';


class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImage(File imageFile, String userId) async {
    try {
      // Create a reference to the Firebase Storage folder
      final storageRef = _storage
          .ref()
          .child('user_images')  // folder name
          .child('$userId-${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }
}

