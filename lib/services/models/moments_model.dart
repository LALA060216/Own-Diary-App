import 'package:cloud_firestore/cloud_firestore.dart';

class MomentsModel {
  final String id; // Firestore document ID
  final String diaryId; // Reference to diary entry
  final String userId;
  final String imageUrl; // Single image URL
  final String moments; // Category this image belongs to

  MomentsModel({
    required this.id,
    required this.diaryId,
    required this.userId,
    required this.imageUrl,
    required this.moments,
  });

  // FireStore data -> MomentsModel
  factory MomentsModel.fromFirestore(DocumentSnapshot doc){
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MomentsModel(
      id: doc.id,
      diaryId: data['diaryId'] ?? '',
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      moments: data['moments'] ?? '',
    );
  }

  // MomentsModel -> FireStore data
  Map<String, dynamic> toFireStore() {
    return {
      'diaryId': diaryId,
      'userId': userId,
      'imageUrl': imageUrl,
      'moments': moments,
    };
  }
}