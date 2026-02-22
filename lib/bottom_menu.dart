
import 'package:diaryapp/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/diary_sum.dart';
import 'pages/ai_summary.dart';
import 'pages/camera_page.dart';

class BottomMenu extends StatefulWidget{
  const BottomMenu({super.key});

  @override
  State<BottomMenu> createState() => _Bottommenustate();
}

class _Bottommenustate extends State<BottomMenu>{
  int cindex = 0;
  final FirestoreService firestoreService = FirestoreService();
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  Widget _navbutton({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String title,
  }){
    final bool isActive = cindex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            cindex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          transform: Matrix4.translationValues(0, isActive ? -8 : 0, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: isActive ? 28 : 26,
                color: isActive ? Theme.of(context).primaryColor : Colors.grey,
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isActive ? 1.0 : 0.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: isActive ? 16 : 0,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Offstage(
            offstage: cindex != 1,
            child: Diaries(),
          ),
          Offstage(
            offstage: cindex != 3,
            child: AISummaryPage(),
          ),
          Offstage(
            offstage: cindex != 4,
            child: ProfilePage(),
          ),
          if (cindex == 0) Homepage(),
          if (cindex == 2) CameraPage(),
        ],
      ),
      bottomNavigationBar: 
            BottomAppBar(
              elevation: 15,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              height: 80,
              color: Color(0xfffffaf0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  _navbutton(
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    title: 'Home'
                  ),
                  _navbutton(
                    index: 1,
                    icon: Icons.data_exploration_outlined,
                    activeIcon: Icons.data_exploration,
                    title: 'Diaries'
                  ),
                  _navbutton(
                    index: 2,
                    icon: Icons.camera_alt_outlined,
                    activeIcon: Icons.camera_alt,
                    title: 'Camera'
                  ),
                  _navbutton(
                    index: 3, 
                    icon: Icons.note_alt_outlined,
                    activeIcon: Icons.note_alt,
                    title: 'AI Summary'
                  ),
                  _navbutton(
                    index: 4,
                    icon: Icons.person_outlined,
                    activeIcon: Icons.person,
                    title: 'Profile'
                  ),
                ],
            ),
    ),
    );
    
  }
}

