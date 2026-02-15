import 'dart:async';
import 'package:diaryapp/services/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'setting_page.dart';
import 'package:diaryapp/services/firestore_service.dart';

class ProfilePage extends StatefulWidget{
  ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();

}

class _ProfilePageState extends State<ProfilePage> {

  final FirestoreService _firestoreService = FirestoreService();
  UserModel? currentUserModel;
  StreamSubscription<UserModel?>? _userSubscription;
  
  Stream<UserModel?> fetchUserData() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.value(null);
    }
    return _firestoreService.getUserDataStream(userId);
  }
  @override
  void initState() {
    super.initState();
    _userSubscription = fetchUserData().listen((userModel) {
      if (!mounted) {
        return;
      }
      setState(() {
        currentUserModel = userModel;
      });
    });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  @override
  
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xfffffaf0),
        shadowColor: Color(0xffEDEADE),
        elevation: 2,
        title: Text(
          'Profile', 
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Lobstertwo',
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: 
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingPage()),
                  );
                },
                icon: Icon(
                  Icons.settings_outlined,
                  size: 28,
                ),
              )
          )
        ],
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Color(0xfff5f5f5),
      body: Column(
        children: [
          profile_pic_and_username_display(),
          Divider(
            height: 1,
            thickness: 2,
            color: Color(0xffe0e0e0),
          ),
          SizedBox(height: 30),
          streak_and_post(),
          SizedBox(height: 30),
          AI_overview(),
        ],
      )
    

    );
  }




  Container AI_overview() {
    return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Color(0xffF9F6EE),
            boxShadow: [
              BoxShadow(
                color: Color(0xffddd6e1),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          height: 350,
          width: 308,
          child: Column(
            children: [
              Text(
                "AI Overview:",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
  }

  Row streak_and_post() {
    return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0.5,
              child: 
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    width: 130,
                    height: 50,
                    color: Color(0xffF9F6EE),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_rate,
                          color: Colors.black,
                        ),
                        Text(
                          "Streak:",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currentUserModel?.streak.toString() ?? "-",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0.5,
              child: 
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    width: 130,
                    height: 50,
                    color: Color(0xffF9F6EE),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          color: Colors.black,
                        ),
                        Text(
                          "Post:",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currentUserModel?.totalDiaryPosted.toString() ?? "-",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ),
          ],
        );
  }

  Container profile_pic_and_username_display() {
    return Container(
          
          padding: EdgeInsets.only(left: 10),
          height: 150,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xfff5fffa),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xffddd6e1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                height: 85,
                width: 85,
                  child: Icon(
                    Icons.person,
                    size: 34,
                  ),
                ),
                
                Container(
                  width: 250,
                  height: 80,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentUserModel?.username ?? "Guest",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Lobstertwo"
                        ),
                      ),
                      Text(currentUserModel?.email ?? "",
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: "Lobstertwo"
                        ),
                      ),
                    ],
                  ),
                )
            ],
          ),
        );
  }
}