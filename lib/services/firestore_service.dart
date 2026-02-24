import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diaryapp/services/firebase_storage_service.dart';
import 'package:flutter/material.dart';
import 'models/diary_entry_model.dart';
import 'models/user_model.dart';
import 'models/moments_model.dart';

class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _firebaseStorageService = FirebaseStorageService();

  // User collection reference
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      firestore.collection('users');

  // Diary Entries collection reference
  CollectionReference<Map<String, dynamic>> get diaryEntriesCollection =>
      firestore.collection('diaryEntries');

  CollectionReference<Map<String, dynamic>> get momentsCollection =>
      firestore.collection('moments');

  // ==================== MOMENTS OPERATIONS ====================

  /// Check if an image URL already has moments
  Future<MomentsModel?> getMomentByImageUrl(String userId, String imageUrl) async {
    try {
      final snapshot = await momentsCollection
          .where('userId', isEqualTo: userId)
          .where('imageUrl', isEqualTo: imageUrl)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return MomentsModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Create moments entry for an image
  Future<String> createMomentEntry({
    required String diaryId,
    required String userId,
    required String imageUrl,
    String moments = '',
  }) async {
    final newEntry = MomentsModel(
      id: '',
      diaryId: diaryId,
      userId: userId,
      imageUrl: imageUrl,
      moments: moments,
    );
    try {
      final docRef = await momentsCollection.add(newEntry.toFireStore());
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Update moments for an image
  Future<void> updateMomentEntry({
    required String momentId,
    required String moments,
  }) async {
    try {
      await momentsCollection.doc(momentId).update({
        'moments': moments,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Delete moments entry
  Future<void> deleteMomentEntry(String momentId) async {
    try {
      await momentsCollection.doc(momentId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete all moments for a diary entry
  Future<void> deleteMomentsForDiary(String diaryId) async {
    try {
      final snapshot = await momentsCollection
          .where('diaryId', isEqualTo: diaryId)
          .get();
      
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get all moments for a user
  Stream<List<MomentsModel>> getUserMomentsStream(String userId) {
    return momentsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MomentsModel.fromFirestore(doc))
            .toList());
  }

  /// Create or update moment entry for an image (only if not exists)
  Future<void> createOrUpdateMomentEntry({
    required String diaryId,
    required String userId,
    required String imageUrl,
    required String moments,
  }) async {
    try {
      // Check if moment already exists for this image
      final existing = await getMomentByImageUrl(userId, imageUrl);
      
      if (existing == null) {
        // Create new moment entry
        await createMomentEntry(
          diaryId: diaryId,
          userId: userId,
          imageUrl: imageUrl,
          moments: moments,
        );
      } else if (existing.moments.isEmpty && moments.isNotEmpty) {
        // Update only if existing has no moments and we have new ones
        await updateMomentEntry(
          momentId: existing.id,
          moments: moments,
        );
      }
      // If existing already has moments, don't change anything
    } catch (e) {
      rethrow;
    }
  }

  // ==================== USER OPERATIONS ====================
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

  Future<DateTime?> getUserLastPostDate(String uid) async {
    try {
      final userData = await getUserData(uid);
      return userData?.lastPostDate;
    } catch (e) {
      rethrow;
    }
  }

  Future<DateTime?> getUserLastStreakUpdateDate(String uid) async {
    try {
      final userData = await getUserData(uid);
      return userData?.lastStreakUpdateDate;
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

  Future<void> updateLastStreakUpdateDate(String uid, DateTime date) async {
    try {
      await usersCollection.doc(uid).update({
        'lastStreakUpdateDate': Timestamp.fromDate(date),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStreak(String uid, DateTime date) async {
    try {
      final userLastPostDate = await getUserLastPostDate(uid);
      final userLastStreakUpdateDate = await getUserLastStreakUpdateDate(uid);

      if (userLastPostDate != null) {
        if (userLastStreakUpdateDate == null){
          await incrementUserStreak(uid);
          await updateLastStreakUpdateDate(uid, date);
        } else {
          int differenceInDays = userLastStreakUpdateDate.difference(userLastPostDate).inDays;
          if (DateUtils.isSameDay(userLastStreakUpdateDate, userLastPostDate) == false) {
            // User posted yesterday, increment streak
            await incrementUserStreak(uid);
            await updateLastStreakUpdateDate(uid, date);

          } else if (differenceInDays > 1) {
            // User missed more than one day, reset streak
            await resetUserStreak(uid);
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDailyMood(String uid, String mood) async {
    try {
      await usersCollection.doc(uid).update({
        'dailyMood': mood,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDailyAttention(String uid, String attention) async {
    try {
      await usersCollection.doc(uid).update({
        'dailyAttention': attention,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateWeeklyMood(String uid, String mood) async {
    try {
      await usersCollection.doc(uid).update({
        'weeklyMood': mood,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateWeeklyAttention(String uid, String attention) async {
    try {
      await usersCollection.doc(uid).update({
        'weeklyAttention': attention,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getuserMood(String uid, String moodType) async {
    try {
      final userData = await getUserData(uid);
      if (moodType == 'dailyMood') {
        return userData?.dailyMood ?? '';
      } else if (moodType == 'weeklyMood') {
        return userData?.weeklyMood ?? '';
      } else {
        throw Exception('Invalid mood type');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getUserAttention(String uid, String attentionType) async {
    try {
      final userData = await getUserData(uid);
      if (attentionType == 'dailyAttention') {
        return userData?.dailyAttention ?? '';
      } else if (attentionType == 'weeklyAttention') {
        return userData?.weeklyAttention ?? '';
      } else {
        throw Exception('Invalid attention type');
      }
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

  Future<void> updateDiaryEntryTitle({
    required String entryId,
    required String newTitle,
  }) async {
    try {
      await diaryEntriesCollection.doc(entryId).update({
        'title': newTitle,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      rethrow;
    }
  }


  /// Update diary entry keywords
  Future<void> updateDiaryEntryKeywords({
    required String entryId,
    required List<String> newKeywords
  }) async {
    try {
      await diaryEntriesCollection.doc(entryId).update({
        'keywords': newKeywords,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get all diary entries in the past week
  Future<String> getUserDiaryContextPastWeek(String userId) async {
    try {
      final oneWeekAgo = DateTime.now().subtract(Duration(days: 7));
      final snapshot = await diaryEntriesCollection
        .where('userId', isEqualTo: userId)
        .where('created', isGreaterThanOrEqualTo: Timestamp.fromDate(oneWeekAgo))
        .orderBy('created', descending: true)
        .get();

      return snapshot.docs
        .map((doc) => DiaryEntryModel.fromFirestore(doc).context)
        .toList()
        .join('\n');
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getUserDiaryContextPastMonth(String userId) async {
    try {
      final oneMonthAgo = DateTime.now().subtract(Duration(days: 30));
      final snapshot = await diaryEntriesCollection
        .where('userId', isEqualTo: userId)
        .where('created', isGreaterThanOrEqualTo: Timestamp.fromDate(oneMonthAgo))
        .orderBy('created', descending: true)
        .get();

      return snapshot.docs
        .map((doc) => DiaryEntryModel.fromFirestore(doc).context)
        .toList()
        .join('\n');
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
    final DiaryEntryModel? entry = await diaryEntriesCollection.doc(entryId).get().then((doc) => DiaryEntryModel.fromFirestore(doc));
    try {
      await diaryEntriesCollection.doc(entryId).delete();
      await decrementDiaryPostCount(userId);
      if (entry != null && entry.imageUrls.isNotEmpty) {
        for (final imageUrl in entry.imageUrls) {
          await _firebaseStorageService.deleteImage(imageUrl);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> createDiaryEntry({
    required String userId,
    required String title,
    required String context,
    required DateTime date,
    List<String> imageUrls = const [],
    List<String> keywords = const [],
  }) async {
    final newEntry = DiaryEntryModel(
      id: '',
      userId: userId,
      title: title,
      context: context,
      imageUrls: imageUrls,
      keywords: keywords,
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

  Future<DiaryEntryModel?> getNewestDiaryDetail(String userId) async {
    try {
      final snapshot = await diaryEntriesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('created', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final newestDiary = DiaryEntryModel.fromFirestore(snapshot.docs.first);
        return newestDiary;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  //update profile photo url
  // In FirestoreService:
Future<void> updateProfilePhoto(String uid, File file) async {
  final url = await _firebaseStorageService.uploadProfilePhoto(file, uid);
  if (url != null) {
    await usersCollection.doc(uid).update({'photoUrl': url});
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid == uid) {
      await user.updatePhotoURL(url);
    }
  }
}

Future<void> removeProfilePhoto(String uid) async {
  await _firebaseStorageService.deleteProfilePhoto(uid);
  await usersCollection.doc(uid).update({'photoUrl': FieldValue.delete()});
  final user = FirebaseAuth.instance.currentUser;
  if (user != null && user.uid == uid) {
    await user.updatePhotoURL(null);
  }
}


}



