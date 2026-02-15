import 'package:diaryapp/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'newdiary_page.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});
  

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  FirestoreService firestoreService = FirestoreService();
  String userId = FirebaseAuth.instance.currentUser!.uid;
  String streak = '';

  @override
  void initState() {
    super.initState();
    _getStreak();
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
                height: 50,
              ),
              new_diary_button(context, width: maxWidth),
              SizedBox(
                height: 60,
              ),
              SizedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [ 
                      SizedBox(
                        width: maxWidth * 0.4,
                        height: maxWidth * 0.4,
                        child: 
                          Ink(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/images/simple_abstract_background_6819442.jpg'),
                                fit: BoxFit.contain,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30), // Adjust the radius as needed
                                ),
                              ), 
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_fire_department_rounded, color: const Color.fromARGB(255, 255, 255, 255), size: maxWidth * 0.18),
                                  Text(streak, style: TextStyle(fontSize: maxWidth * 0.1, color: const Color.fromARGB(255, 255, 255, 255))),
                                  Text('days', style: TextStyle(fontSize: maxWidth * 0.04, color: const Color.fromARGB(255, 255, 255, 255), height: -0.5)),
                                ],
                              )
                            ),
                          ), 
                      ),
                      SizedBox(
                        width: 40,
                      ),
                      SizedBox(
                        width: maxWidth * 0.4,
                        height: maxWidth * 0.6,
                        child: 
                          ElevatedButton(
                              onPressed: null, 
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10), 
                                ),
                              ),
                              child: Text('test'),
                          ),
                      ),
                    ]
                  
                ),
              ),
              SizedBox(
                height: 40,
              ),
              SizedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [ 
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: 
                          ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10), 
                                ),
                              ), 
                              child: Text('test')
                              
                              ), 
                      ),
                      SizedBox(
                        width: 40,
                      ),
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: 
                          ElevatedButton(
                              onPressed: null, 
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text('test'),
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
                  elevation: 6,
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
}