import 'package:bloc/bloc.dart';
import 'package:diaryapp/app_view.dart';
import 'package:diaryapp/firebase_options.dart';
import 'package:diaryapp/firebase_user_repo.dart';
import 'package:diaryapp/simple_bloc_observer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:user_repository/user_repository.dart' hide FirebaseUserRepo;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'blocs/bloc/authentication_bloc.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase already initialized - this is fine for hot reload
  }
  
  Bloc.observer = SimpleBlocObserver();
  runApp(MyApp(FirebaseUserRepo()));
}

class MyApp extends StatelessWidget {
  final UserRepository userRepository;
  const MyApp(this.userRepository, {super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthenticationBloc>(
      create: (context) => AuthenticationBloc(
        userRepository: userRepository,
      ),
      child: MyAppView()
    );
  }
}

