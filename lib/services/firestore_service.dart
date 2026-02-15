import 'package:cloud_firestore/cloud_firestore.dart';
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
  Future<void> updateStreakAndDiaryCount({
    required String uid,
    required int streak,
    required int totalDiaryPosted,
    required DateTime lastPostDate,
  }) async {
    try {
      await usersCollection.doc(uid).update({
        'streak': streak,
        'totalDiaryPosted': totalDiaryPosted,
        'lastPostDate': Timestamp.fromDate(lastPostDate),
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

  // ==================== DIARY ENTRIES OPERATIONS ====================

  /// Add a new diary entry
  Future<String> addDiaryEntry(DiaryEntryModel entry, DateTime date) async {
    try {
      final user = await getUserData(entry.userId);
      final docRef = await diaryEntriesCollection.add(entry.toFireStore());

      await incrementDiaryPostCount(entry.userId);
      if (user?.lastPostDate == null){
        incrementDiaryPostCount(entry.userId);
      } else {
        final lastPostDate = user!.lastPostDate!;
        final differenceInDays = date.difference(lastPostDate).inDays;
        if (differenceInDays == 1) {
          await incrementUserStreak(entry.userId);
        } else if (differenceInDays > 1) {
          await resetUserStreak(entry.userId);
        }
      }
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
  Future<void> deleteDiaryEntry(String entryId) async {
    try {
      await diaryEntriesCollection.doc(entryId).delete();
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
}



