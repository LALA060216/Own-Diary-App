import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryEntryModel {
  final String id; 
  final String userId;
  final String title;
  final String context;
  final List<String> imageUrls;
  final DateTime created;
  final DateTime updatedAt;
  final List<String> keywords;  

  DiaryEntryModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.context,
    required this.imageUrls,
    required this.created,
    required this.updatedAt,
    required this.keywords,
  });

  // FireStore data -> DiaryEntryModel
  factory DiaryEntryModel.fromFirestore(DocumentSnapshot doc){
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DiaryEntryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      context: data['context'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      keywords: List<String>.from(data['keywords'] ?? []),
      created: (data['created'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // DiaryEntryModel -> FireStore data
  Map<String, dynamic> toFireStore() {
    return {
      'userId': userId,
      'title': title,
      'context': context,
      'imageUrls': imageUrls,
      'created': Timestamp.fromDate(created),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'keywords': keywords,
    };
  }

  DiaryEntryModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? context,
    List<String>? imageUrls,
    DateTime? created,
    DateTime? updatedAt,
    List<String>? keywords,
  }) {
    return DiaryEntryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      context: context ?? this.context,
      imageUrls: imageUrls ?? this.imageUrls,
      keywords: keywords ?? this.keywords,
      created: created ?? this.created,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}