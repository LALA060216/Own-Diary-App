import 'package:diaryapp/services/auth/auth_service.dart';
import 'package:diaryapp/bottom_menu.dart';
import 'package:diaryapp/services/auth/pages/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:diaryapp/services/firestore_service.dart';

void updateStreak(FirestoreService firestoreService, FirebaseAuth firebaseAuth) async {
  final user = firebaseAuth.currentUser;
  if (user == null) return;

  final userData = await firestoreService.getUserData(user.uid);
  if (userData?.lastPostDate == null){
    await firestoreService.incrementUserStreak(user.uid);
  } else {
    final lastPostDate = userData!.lastPostDate!;
    final differenceInDays = DateTime.now().difference(lastPostDate).inDays;

    if (differenceInDays == 1) {
      await firestoreService.incrementUserStreak(user.uid);
    } 
    else if (differenceInDays > 1) {
      await firestoreService.resetUserStreak(user.uid);
    }
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.pageIfNotConnected});
  final Widget? pageIfNotConnected;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(valueListenable: authService, 
    builder: (context, authService, child){
      return StreamBuilder(
        stream: authService.authStateChanges,
        builder: (context, snapshot){
          Widget widget;
          if (snapshot.hasData){
            widget = BottomMenu();
          }
          else{
            widget = pageIfNotConnected ?? WelcomePage();
          }
          updateStreak(authService.firestoreService, authService.firebaseAuth);
          return widget;
        });
    });
  }
}