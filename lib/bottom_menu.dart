
import 'package:diaryapp/pages/newdiary_page.dart';
import 'package:diaryapp/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'pages/home_page/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/diary_sum.dart';
import 'pages/ai_summary.dart';

class BottomMenu extends StatefulWidget{
  const BottomMenu({super.key});

  @override
  State<BottomMenu> createState() => _Bottommenustate();
}

class _Bottommenustate extends State<BottomMenu>{
  int cindex = 0;
  final FirestoreService firestoreService = FirestoreService();
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  Future<void> _cameraPage() async {
    final XFile? captured = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );
    setState(() {
      cindex = 0;
    });  
    if (captured != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewDiary(
            imageFile: captured,
          ),
        ),
      );
    }
  }

  Future<void> _checkIfCreatedNewDiaryToday() async {
    final newestDiary = await firestoreService.getNewestDiaryDetail(userId!);
    DateTime? newestDate = newestDiary?.created;
    previousDiaryController.text = newestDiary?.context ?? '';

    if (!mounted) return ;
    setState(() {
      createdNewDiaryToday = newestDate != null && DateUtils.isSameDay(newestDate, DateTime.now());
    });
  }

  Widget _navbutton({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String title,
  }){
    final bool isActive = cindex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() {
            cindex = index;
          });
          if (index == 2) {
            _cameraPage();
          }
          if (index == 0) {
            _checkIfCreatedNewDiaryToday();
          }
        },
        child: SizedBox.expand(
          child: Align(
            alignment: Alignment.center,
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
                    size: 27,
                    color: isActive ? Color(0xff4a4a4a) : Colors.black,
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
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            child: ExcludeFocus(
              excluding: cindex != 1,
              child: Diaries(),
            ),
          ),
          Offstage(
            offstage: cindex != 3,
            child: ExcludeFocus(
              excluding: cindex != 3,
              child: AISummaryPage(),
            ),
          ),
          Offstage(
            offstage: cindex != 4,
            child: ExcludeFocus(
              excluding: cindex != 4,
              child: ProfilePage(),
            ),
          ),
          Offstage(
            offstage: cindex != 0,
            child: ExcludeFocus(
              excluding: cindex != 0,
              child: Homepage(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: 
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xffbdbdbd), width: 2),
                ),
              ),
              child: BottomAppBar(
                elevation: 15,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                height: 80,
                color: Color(0xffffffff),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  
                  children: [
                  _navbutton(
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    title: 'Home'
                  ),
                  _navbutton(
                    index: 1,
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart,
                    title: 'Diaries'
                  ),
                  _navbutton(
                    index: 2,
                    icon: Icons.camera_rounded,
                    activeIcon: Icons.camera_rounded,
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
      ),
    );
  }
}

