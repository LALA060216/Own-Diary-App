import 'package:user_repository/src/models/user.dart';

abstract class UserRepository{
  Stream<MyUser?> get user;

  Future<MyUser> signUp(MyUser myuser, String password);

  Future<void> setUserData(MyUser user);

  Future<void> signIn(String email, String password);

  Future<void> signOut();


}