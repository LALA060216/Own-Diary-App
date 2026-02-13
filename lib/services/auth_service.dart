import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firestore_service.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirestoreService firestoreService = FirestoreService();

  User? get currentUser => firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Create user document in Firestore
    if (userCredential.user != null) {
      await firestoreService.createUserDocument(
        uid: userCredential.user!.uid,
        email: email,
        username: 'User',
      );
    }
    
    return userCredential;
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  } 

  Future<void> updateUsername({
    required String username,
  }) async {
    await currentUser!.updateDisplayName(username);
    // Also update Firestore
    if (currentUser != null) {
      await firestoreService.updateUserProfile(
        uid: currentUser!.uid,
        username: username,
      );
    }
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    
    // Delete user document from Firestore before deleting auth account
    if (currentUser != null) {
      await firestoreService.deleteUserDocument(currentUser!.uid);
    }
    
    await currentUser!.delete();
    await signOut();
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }
}