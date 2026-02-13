import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final DateTime createdAt;
  final int streak;
  final int totalDiaryPosted;
  final DateTime? lastPostDate;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.createdAt,
    this.streak = 0,
    this.totalDiaryPosted = 0,
    this.lastPostDate,
  });

  // Firestore data -> UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      streak: data['streak'] ?? 0,
      totalDiaryPosted: data['totalDiaryPosted'] ?? 0,
      lastPostDate: data['lastPostDate'] != null
          ? (data['lastPostDate'] as Timestamp).toDate()
          : null,
    );
  }

  // UserModel -> Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'createdAt': Timestamp.fromDate(createdAt),
      'streak': streak,
      'totalDiaryPosted': totalDiaryPosted,
      'lastPostDate': lastPostDate != null ? Timestamp.fromDate(lastPostDate!) : null,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    DateTime? createdAt,
    int? streak,
    int? totalDiaryPosted,
    DateTime? lastPostDate,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      streak: streak ?? this.streak,
      totalDiaryPosted: totalDiaryPosted ?? this.totalDiaryPosted,
      lastPostDate: lastPostDate ?? this.lastPostDate,
    );
  }
}
