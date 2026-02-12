class MyUserEntity {
  String userID;
  String email;
  String name;

  MyUserEntity({
    required this.userID,
    required this.email,
    required this.name,
  });

  Map<String, Object?> toDocument(){
    return {
      'userID': userID,
      'email': email,
      'name': name,
    };
  }

  static MyUserEntity fromDocument(Map<String, dynamic> doc){
    return MyUserEntity(
      userID: doc['userID'],
      email: doc['email'],
      name: doc['name'],
    );
  }
}