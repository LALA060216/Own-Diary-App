import 'package:diaryapp/main.dart';
import 'package:diaryapp/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'newdiary_page.dart';

bool createdNewDiaryToday = false;
String streak = '';
class Homepage extends StatefulWidget {
  const Homepage({super.key});
  

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with RouteAware{
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  FirestoreService firestoreService = FirestoreService();
  String userId = FirebaseAuth.instance.currentUser!.uid;
  TextEditingController _previousDiaryController = TextEditingController();
  List<String> imageUrls = [];
  String? diaryId = '';

  @override
  void initState() {
    super.initState();
    _checkIfCreatedNewDiaryToday();
    _getStreak();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override 
  void didPopNext() {
    _checkIfCreatedNewDiaryToday();
    _getStreak();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _checkIfCreatedNewDiaryToday() async {
    final newestDiary = await firestoreService.getNewestDiaryDetail(userId);
    DateTime? newestDate = newestDiary?.created;
    _previousDiaryController.text = newestDiary?.context ?? '';
    imageUrls = newestDiary?.imageUrls ?? [];
    diaryId = newestDiary?.id;

    if (!mounted) return ;
    setState(() {
      createdNewDiaryToday = newestDate != null && DateUtils.isSameDay(newestDate, DateTime.now());
    });
  }

  Future<void> _getStreak() async {
    final value  = await firestoreService.getUserStreak(userId);
    if (!mounted) return;
    setState(() {
      streak = value.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      createdNewDiaryToday = createdNewDiaryToday;
    });
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        shadowColor: Color(0xffEDEADE),
        elevation: 2,
        backgroundColor: Color(0xfffffaf0),
        
        title: Text(
          'TheDiary', 
          style: TextStyle(
            fontSize: 40,
            fontFamily: 'Lobstertwo'
          ),
        ), 
        centerTitle: true
      
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth * 0.8;
          return SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
              SizedBox(
                height: 30,
              ),
              new_diary_button(context, width: maxWidth),
              SizedBox(
                height: 30,
              ),
              if (createdNewDiaryToday) 
                edit_diary_button(context, width: maxWidth)
              else
                Text(
                  "You haven't created a diary today. Let's write one!",
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              SizedBox(
                height: 40,
              ),
              SizedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [ 
                      SizedBox(
                        width: maxWidth * 0.45,
                        height: maxWidth * 0.45,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromARGB(80, 162, 74, 30),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/images/simple_abstract_background_6819442.jpg'),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ), 
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_fire_department_rounded, color: const Color.fromARGB(255, 255, 255, 255), size: maxWidth * 0.18),
                                  Text(streak, style: TextStyle(fontSize: maxWidth * 0.1, color: const Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold)),
                                ],
                              )
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                      ),
                      SizedBox(
                        width: maxWidth * 0.45,
                        height: maxWidth * 0.45,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromARGB(97, 40, 40, 40),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Color.fromARGB(80, 100, 200, 150),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/images/green_background.jpg'),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ), 
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(FontAwesomeIcons.heartPulse, color: const Color.fromARGB(255, 255, 255, 255), size: maxWidth * 0.15), 
                                  Padding(padding:  EdgeInsets.only(bottom: maxWidth * 0.02)), 
                                  Text('Good', style: TextStyle(fontSize: maxWidth * 0.1, color: const Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold)),
                                ],
                              )
                            ),
                          ),
                        ),
                      ),
                    ]
                ),
              ),
              SizedBox(
                height: 20,
              ),
              SizedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [ 
                      SizedBox(
                        width: maxWidth * 0.45,
                        height: maxWidth * 0.45,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromARGB(100, 0, 0, 0),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Color.fromARGB(80, 150, 100, 200),
                                blurRadius: 15,
                                spreadRadius: 1,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/images/purple_background.jpg'),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                backgroundColor: Colors.transparent,
                              ), 
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(FontAwesomeIcons.sadTear, color: const Color.fromARGB(255, 255, 255, 255), size: maxWidth * 0.15), 
                                  Padding(padding:  EdgeInsets.only(bottom: maxWidth * 0.02)), 
                                  Text('Sad', style: TextStyle(fontSize: maxWidth * 0.1, color: const Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold)),
                                ],
                              )
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                      ),
                      SizedBox(
                        width: maxWidth * 0.45,
                        height: maxWidth * 0.45,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromARGB(100, 0, 0, 0),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Color.fromARGB(80, 200, 180, 100),
                                blurRadius: 15,
                                spreadRadius: 1,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/images/gold_background.jpg'),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                backgroundColor: Colors.transparent,
                              ), 
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(FontAwesomeIcons.moneyBills, color: const Color.fromARGB(255, 255, 255, 255), size: maxWidth * 0.15), 
                                  Padding(padding:  EdgeInsets.only(bottom: maxWidth * 0.02)), 
                                  Text('Wealth', style: TextStyle(fontSize: maxWidth * 0.09, color: const Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold)),
                                ],
                              )
                            ),
                          ),
                        ),
                      ),
                    ]
                  ),
                ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  SizedBox new_diary_button(BuildContext context, {required double width}) {
    return SizedBox(
      height: 180,
      width: width,
      child: 
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NewDiary()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xfffffaf0),
            foregroundColor: const Color.fromARGB(255, 61, 61, 61),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Adjust the radius as needed
            ),
            elevation: 10,
            shadowColor: Color.fromARGB(255, 161, 161, 161)
          ),
          child:Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 60,
              ),
              Text(
                'New Diary',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: "Lobstertwo"
                ),
              ),
            ],
          ),
        ),
    );
  }

  SizedBox edit_diary_button(BuildContext context, {required double width}) {
    return SizedBox(
      height: 110,
      width: width,
      child: 
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NewDiary(previousDiaryController: _previousDiaryController, previousImageUrls: imageUrls, diaryId: diaryId)),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xfffffaf0),
            foregroundColor: const Color.fromARGB(255, 61, 61, 61),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Adjust the radius as needed
            ),
            elevation: 10,
            shadowColor: Color.fromARGB(255, 161, 161, 161)
          ),
          child:Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.edit,
                size: 50,
              ),
              Text(
                'Edit Previous Diary',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: "Lobstertwo"
                ),
              ),
            ],
          ),
        ),
    );
  }
}