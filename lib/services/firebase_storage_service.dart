import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';


class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadImage(File imageFile, String userId, String id) async {
    try {
      // Create a reference to the Firebase Storage folder
      final storageRef = _storage
          .ref()
          .child(userId)  // folder name
          .child(id)
          .child('$userId-$id-${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      rethrow;
    }
  }

}

