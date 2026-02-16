import 'package:diaryapp/services/auth/auth_service.dart';
import 'package:diaryapp/bottom_menu.dart';
import 'package:diaryapp/services/auth/pages/welcome_page.dart';
import 'package:flutter/material.dart';


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
          authService.firestoreService.updateStreak(uid: authService.currentUser!.uid, date: DateTime.now());
          return widget;
        });
    });
  }
}