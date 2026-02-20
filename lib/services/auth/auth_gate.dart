import 'package:diaryapp/bottom_menu.dart';
import 'package:diaryapp/services/auth/auth_service.dart';
import 'package:diaryapp/services/auth/pages/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.pageIfNotConnected});
  final Widget? pageIfNotConnected;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthService>(
      valueListenable: authService,
      builder: (context, authService, child) {
        return StreamBuilder<User?>(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            final user = snapshot.data;
            if (user != null) {
              return const BottomMenu();
            } else {
              return pageIfNotConnected ?? const WelcomePage();
            }
          },
        );
      },
    );
  }
}
