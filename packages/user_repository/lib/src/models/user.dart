import 'package:user_repository/src/entities/user_entity.dart';

class MyUser {
  String userID;
  String email;
  String name;

  MyUser({
    required this.userID,
    required this.email,
    required this.name,
  });

  static final empty = MyUser(
    userID: '',
    email: '',
    name: '',
  );

  MyUserEntity toEntity(){
    return MyUserEntity(
      userID: userID,
      email: email,
      name: name,
    );
  }

  static MyUser fromEntity(MyUserEntity entity){
    return MyUser(
      userID: entity.userID,
      email: entity.email,
      name: entity.name,
    );
  }

  @override
  String toString() {
    return 'MyUser{userID: $userID, email: $email, name: $name}';
  }
}