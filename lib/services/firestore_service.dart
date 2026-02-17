import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'models/diary_entry_model.dart';
import 'models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // User collection reference
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      firestore.collection('users');

  // Diary Entries collection reference
  CollectionReference<Map<String, dynamic>> get diaryEntriesCollection =>
      firestore.collection('diaryEntries');

  CollectionReference<Map<String, dynamic>> get unfinishDiaryEntriesCollection =>
      firestore.collection('unfinishDiaryEntries');

  // ==================== USER OPERATIONS ====================

  /// Create a new user document when they sign up
  Future<void> createUserDocument({
    required String uid,
    required String email,
    String? username,
  }) async {
    try {
      await usersCollection.doc(uid).set(
        UserModel(
          uid: uid,
          email: email,
          username: username ?? 'User',
          createdAt: DateTime.now(),
          streak: 0,
          totalDiaryPosted: 0,
          lastPostDate: null,
        ).toFirestore(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Stream of user data (real-time updates)
  Stream<UserModel?> getUserDataStream(String uid) {
    return usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Update user profile (username, etc.)
  Future<void> updateUserProfile({
    required String uid,
    required String username,
  }) async {
    try {
      await usersCollection.doc(uid).update({
        'username': username,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Update user streak and total diary posted
  Future<void> updateStreak({
    required String uid,
    required DateTime date,
  }) async {
    try {
      final userData = await getUserData(uid);
      if (userData?.lastPostDate == null){
        await incrementUserStreak(uid);
      } else {
        final lastPostDate = userData!.lastPostDate;
        bool isSameDay = lastPostDate != null && DateUtils.isSameDay(date, lastPostDate);
          if (!isSameDay) {
          final differenceInDays = date.difference(lastPostDate!).inDays;
          if (differenceInDays == 1) {
            await incrementUserStreak(uid);
          } 
          else if (differenceInDays > 1) {
            await resetUserStreak(uid);
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Increment total diary posted count (call when user creates a new diary entry)
  Future<void> incrementDiaryPostCount(String uid) async {
    try {
      await usersCollection.doc(uid).update({
        'totalDiaryPosted': FieldValue.increment(1),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Reset user streak to zero
  Future<void> resetUserStreak(String uid) async {
    try {
      await usersCollection.doc(uid).update({
        'streak': 0,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getUserStreak(String uid) async {
    try{
      final userData = await getUserData(uid);
      return userData?.streak ?? 0;
    } catch (e) {
      rethrow;
    }
  }

  /// Decrement total diary posted count (call when user deletes a diary entry)
  Future<void> decrementDiaryPostCount(String uid) async {
    try {
      await usersCollection.doc(uid).update({
        'totalDiaryPosted': FieldValue.increment(-1),
      });
    } catch (e) {
      rethrow;
    }
  }


  // increment user streak by 1
  Future<void> incrementUserStreak(String uid) async {
    try {
      await usersCollection.doc(uid).update({
        'streak': FieldValue.increment(1),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Delete user document
  Future<void> deleteUserDocument(String uid) async {
    try {
      await usersCollection.doc(uid).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateLastPostDate(String uid, DateTime date) async {
    try {
      await usersCollection.doc(uid).update({
        'lastPostDate': Timestamp.fromDate(date),
      });
    } catch (e) {
      rethrow;
    }
  }


  // ==================== DIARY ENTRIES OPERATIONS ====================

  /// Add a new diary entry
  Future<String> addDiaryEntry(DiaryEntryModel entry, DateTime date) async {
    try {
      final docRef = await diaryEntriesCollection.add(entry.toFireStore());
      // update user's last post date
      await updateLastPostDate(entry.userId, date);
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all diary entries for a user
  Future<List<DiaryEntryModel>> getUserDiaryEntries(String userId) async {
    try {
      final snapshot = await diaryEntriesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('created', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => DiaryEntryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream of user's diary entries (real-time updates)
  Stream<List<DiaryEntryModel>> getUserDiaryEntriesStream(String userId) {
    return diaryEntriesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('created', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DiaryEntryModel.fromFirestore(doc))
            .toList());
  }

  /// Delete a diary entry
  Future<void> deleteDiaryEntry(String entryId, String userId) async {
    try {
      await diaryEntriesCollection.doc(entryId).delete();
      await decrementDiaryPostCount(userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> createDiaryEntry({
    required String userId,
    required String context,
    required DateTime date,
    List<String> imageUrls = const [],
  }) async {
    final newEntry = DiaryEntryModel(
      id: '',
      userId: userId,
      context: context,
      imageUrls: imageUrls,
      created: date,
      updatedAt: date,
    );
    return await addDiaryEntry(newEntry, date);
  }

  /// Update diary entry context
  Future<void> updateDiaryEntryContext({
    required String entryId,
    required String newContext,
  }) async {
    try {
      await diaryEntriesCollection.doc(entryId).update({
        'context': newContext,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Update diary entry image URLs
  Future<void> updateDiaryEntryImageUrls({
    required String entryId,
    required List<String> newImageUrls
  }) async {
    try{
      await diaryEntriesCollection.doc(entryId).update({
        'imageUrls': newImageUrls,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<DateTime?> getNewestDiaryDate(String userId) async {
    try {
      final snapshot = await diaryEntriesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('created', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final newestDiary = DiaryEntryModel.fromFirestore(snapshot.docs.first);
        return newestDiary.created;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}



