import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String? photoUrl; 
  final DateTime createdAt;
  final int streak;
  final int totalDiaryPosted;
  final DateTime? lastPostDate;
  final DateTime? lastStreakUpdateDate;
  final String? dailyMood;
  final String? dailyAttention;
  final String? weeklyMood;
  final String? weeklyAttention;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.createdAt,
    this.photoUrl,
    this.streak = 0,
    this.totalDiaryPosted = 0,
    this.lastPostDate,
    this.lastStreakUpdateDate,
    this.dailyMood,
    this.dailyAttention,
    this.weeklyMood,
    this.weeklyAttention
  });

  // Firestore data -> UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      photoUrl: data['photoUrl'],
      streak: data['streak'] ?? 0,
      totalDiaryPosted: data['totalDiaryPosted'] ?? 0,
      lastPostDate: data['lastPostDate'] != null
          ? (data['lastPostDate'] as Timestamp).toDate()
          : null,
      lastStreakUpdateDate: data['lastStreakUpdateDate'] != null
          ? (data['lastStreakUpdateDate'] as Timestamp).toDate()
          : null,
      dailyMood: data['dailyMood'] ?? '',
      dailyAttention: data['dailyAttention'] ?? '',
      weeklyMood: data['weeklyMood'] ?? '',
      weeklyAttention: data['weeklyAttention'] ?? ''
    );
  }

  // UserModel -> Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'createdAt': Timestamp.fromDate(createdAt),
      'photoUrl': photoUrl,
      'streak': streak,
      'totalDiaryPosted': totalDiaryPosted,
      'lastPostDate': lastPostDate != null ? Timestamp.fromDate(lastPostDate!) : null,
      'lastStreakUpdateDate': lastStreakUpdateDate != null ? Timestamp.fromDate(lastStreakUpdateDate!) : null,
      'dailyMood': dailyMood ?? '',
      'dailyAttention': dailyAttention ?? '',
      'weeklyMood': weeklyMood ?? '',
      'weeklyAttention': weeklyAttention ?? ''
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    DateTime? createdAt,
    String? photoUrl,
    int? streak,
    int? totalDiaryPosted,
    DateTime? lastPostDate,
    DateTime? lastStreakUpdateDate,
    String? dailyMood,
    String? dailyAttention,
    String? weeklyMood,
    String? weeklyAttention
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      streak: streak ?? this.streak,
      totalDiaryPosted: totalDiaryPosted ?? this.totalDiaryPosted,
      lastPostDate: lastPostDate ?? this.lastPostDate,
      lastStreakUpdateDate: lastStreakUpdateDate ?? this.lastStreakUpdateDate,
      dailyMood: dailyMood ?? this.dailyMood,
      dailyAttention: dailyAttention ?? this.dailyAttention,
      weeklyMood: weeklyMood ?? this.weeklyMood,
      weeklyAttention: weeklyAttention ?? this.weeklyAttention
    );
  }
}
