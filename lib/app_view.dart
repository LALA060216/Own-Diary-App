import 'package:diaryapp/blocs/bloc/authentication_bloc.dart';
import 'package:diaryapp/bottom_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:diaryapp/screens/auth/views/welcome_screen.dart';
import 'package:diaryapp/screens/home/views/home_screen.dart';

class MyAppView extends StatelessWidget {
  const MyAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diary App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData( 
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xfffffaf0)),
      ),
      home: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        builder: (context, state) {
          if(state.status == AuthenticationStatus.authenticated){
            return BottomMenu();
          }else{
            return WelcomeScreen();
          }
        }
      )
    );
  }
}