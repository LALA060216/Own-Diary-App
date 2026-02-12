part of 'authentication_bloc.dart';

@immutable
sealed class AuthenticationEvent {
  const AuthenticationEvent();


}

class AuthenticationUserChanged extends AuthenticationEvent {
  final MyUser? user;
  const AuthenticationUserChanged(this.user);
  
}

