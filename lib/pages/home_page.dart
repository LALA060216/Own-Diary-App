import 'dart:convert';

import 'package:diaryapp/main.dart';
import 'package:diaryapp/services/firestore_service.dart';
import 'package:diaryapp/services/gemini_service.dart';
import 'package:diaryapp/services/models/ai_chat_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'newdiary_page.dart';

bool createdNewDiaryToday = false;
String streak = '';
List<int> status = [0,0];
String oldDiaryContext = '';
bool updatedDiary = true;

class Homepage extends StatefulWidget {
  const Homepage({super.key});
  

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with RouteAware{
  FirestoreService firestoreService = FirestoreService();
  String userId = FirebaseAuth.instance.currentUser!.uid;
  TextEditingController _previousDiaryController = TextEditingController();
  List<String> imageUrls = [];
  String? diaryId = '';
  bool isLoading = false;
  String prompt = 'You are a sentiment analyzer. Analyze the diary entry and select the best matching index (0-19) from the two lists below.\n'+
  'Health Statuses (0-19):\n'+
  '["Healthy", "Infected", "Feverish", "Chills", "Painful", "Fatigued", "Dizzy", "Depressed", "Nauseous", "Active", "Bedridden", "Energetic", "Weak", "Immobile", "Pregnant", "Frail", "Hospitalized", "Hygienic", "Overweight", "Critical"]\n'+
  'Emotion Statuses (0-19):\n'+
  '["Happy", "Overjoyed", "Loved", "Neutral", "Sad", "Depressed", "Angry", "Furious", "Annoyed", "Exhausted", "Embarrassed", "Shocked", "Awkward", "Confused", "Scared", "Stressed", "Heartbroken", "Gloomy", "Chill", "Terrible"]\n'+
  'Return ONLY two numbers separated by a space.\n'+
  '!!Important!! Follow these two Rules: '+
  '1) If the diary entry describes emotions but DOES NOT mention physical symptoms or health, default the health_index to 0'+
  '2) Do not include any other text, explanations, or formatting. Just the two numbers. Example: 5 10. Bad response: 08 06';
  late AIChatModel _chatModel = AIChatModel(prompt: prompt, model: 'gemma-3-27b-it');

  List<dynamic> healthIcons = [
    FontAwesomeIcons.heartPulse,
    FontAwesomeIcons.virus,
    FontAwesomeIcons.temperatureHigh,
    FontAwesomeIcons.faceGrimace,
    FontAwesomeIcons.faceTired,
    FontAwesomeIcons.faceDizzy,
    FontAwesomeIcons.faceSadTear,
    FontAwesomeIcons.faceRollingEyes,
    FontAwesomeIcons.personRunning,
    FontAwesomeIcons.bed,
    FontAwesomeIcons.batteryFull,
    FontAwesomeIcons.batteryQuarter,
    FontAwesomeIcons.wheelchair,
    FontAwesomeIcons.personPregnant,
    FontAwesomeIcons.personCane,
    FontAwesomeIcons.hospital,
    FontAwesomeIcons.handsBubbles,
    FontAwesomeIcons.weightScale,
    FontAwesomeIcons.skull
  ];
  List<String> healthStatuses = [
    "Healthy",
    "Infected",
    "Feverish",
    "Chills",
    "Painful",
    "Fatigued",
    "Dizzy",
    "Depressed",
    "Nauseous",
    "Active",
    "Bedridden",
    "Energetic",
    "Weak",
    "Immobile",
    "Pregnant",
    "Frail",
    "Hospitalized",
    "Hygienic",
    "Overweight",
    "Critical",
  ];

  List<dynamic> emotionIcons = [
    FontAwesomeIcons.faceSmile,      
    FontAwesomeIcons.faceLaughBeam,   
    FontAwesomeIcons.faceGrinHearts,  
    FontAwesomeIcons.faceMeh,         
    FontAwesomeIcons.faceFrown,       
    FontAwesomeIcons.faceSadTear,     
    FontAwesomeIcons.faceAngry,       
    FontAwesomeIcons.fire,            
    FontAwesomeIcons.faceRollingEyes, 
    FontAwesomeIcons.faceTired,       
    FontAwesomeIcons.faceFlushed,     
    FontAwesomeIcons.faceSurprise,    
    FontAwesomeIcons.faceGrimace,     
    FontAwesomeIcons.faceDizzy,       
    FontAwesomeIcons.ghost,           
    FontAwesomeIcons.bolt,            
    FontAwesomeIcons.heartCrack,      
    FontAwesomeIcons.cloudRain,       
    FontAwesomeIcons.peace,           
    FontAwesomeIcons.poo,             
  ];
  List<String> emotionStatus = [
    "Happy",
    "Overjoyed",
    "Loved",
    "Neutral",
    "Sad",
    "Depressed",
    "Angry",
    "Furious",
    "Annoyed",
    "Exhausted",
    "Embarrassed",
    "Shocked",
    "Awkward",
    "Confused",
    "Scared",
    "Stressed",
    "Heartbroken",
    "Gloomy",
    "Chill",
    "Terrible",
  ];

  @override
  void initState() {
    super.initState();
    _checkIfCreatedNewDiaryToday();
    _didUpdatedDiary().then((updated) {
      if (updated) {
        _refreshMood();
      }
    });
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
    _didUpdatedDiary().then((updated) {
      if (updated) {
        _refreshMood();
      }
    });
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
    final value = await firestoreService.getUserStreak(userId);
    if (!mounted) return;
    setState(() {
      streak = value.toString();
    });
  }

  Future<bool> _didUpdatedDiary() async {
    final newestDiary = await firestoreService.getNewestDiaryDetail(userId);
    String newestContext = newestDiary?.context ?? '';
    List<String> newestImageUrls = newestDiary?.imageUrls != null ? List<String>.from(newestDiary!.imageUrls) : [];
    if (newestContext != oldDiaryContext || !listEquals(newestImageUrls, imageUrls)) {
      oldDiaryContext = newestContext;
      imageUrls = newestImageUrls;
      return true;
    }
    return false;
  }

  Future<void> _refreshMood() async {
    isLoading = true;
    
    final newestDiary = await firestoreService.getNewestDiaryDetail(userId);
    String context = newestDiary?.context ?? '';
    await GeminiService(chatModel: _chatModel).getMoodAnalysis(context).then((value) {
      try {
        print(value);
        final numbers = RegExp(r'\d+').allMatches(value)
            .map((m) => int.parse(m.group(0)!))
            .toList();
        
        if (numbers.length >= 2) {
          setState(() {
            isLoading = false;
            status = [numbers[0], numbers[1]];
          });
        }
      } catch (e) {
        print("Error decoding mood analysis: $e");
        print("Response was: $value");
        setState(() {
          status = [0, 0];
        });
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    setState(() {
      createdNewDiaryToday = createdNewDiaryToday;
    });
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0, top: 50),
                  child: Text(
                    "Hello ${FirebaseAuth.instance.currentUser?.displayName ?? 'User'}!",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lobstertwo',
                    ),
                  ),
                ),
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 20.0, top: 40),
                child: streakContainer(streak != '' ? int.parse(streak) : 0),
              ),
              SizedBox(
                width: 1,
              )
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Divider(
            height: 0.1,
            color: Colors.grey,
            thickness: 2,
            indent: 20,
            endIndent: 20,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double maxWidth = constraints.maxWidth * 0.8;
                  return Center(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 5,
                        ),
                        newDiaryButton(context, width: maxWidth),
                        SizedBox(
                          height: 30,
                        ),
                        if (createdNewDiaryToday) 
                          editDiaryButton(context, width: maxWidth)
                        else
                          Text(
                            "You haven't created a diary today. Let's write one!",
                        style: TextStyle(fontSize: 16, color: Colors.red),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        moodBlocks(maxWidth, createdNewDiaryToday),
                      ],
                    ),
                  );
                }
              ),
            )
          )
        ],
      ),
    );
  }

  Container streakContainer(int streak) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromARGB(255, 250, 160, 160), width: 3),
        borderRadius: BorderRadius.circular(10)
      ),
      padding: EdgeInsets.all(8),
      height: 60,
      child:Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.local_fire_department_rounded, color: const Color.fromARGB(255, 237, 84, 84), size: 40),
          Text(streak.toString(), style: TextStyle(fontSize: 30, color: const Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.bold)),
        ],
      )
    );
  }

  Column moodBlocks(double maxWidth, bool createdNewDiaryToday) {
    return Column(
      children:[
        Text(
          "Moods",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(
          height: 20,
        ),
        SizedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [ 
              // button for health
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
                      color: createdNewDiaryToday ? Color.fromARGB(255, 38, 255, 0) : Color.fromARGB(255, 100, 100, 100),
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
                      child: isLoading ? CircularProgressIndicator(color: Colors.white) : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(healthIcons[status[0]], color: const Color.fromARGB(255, 255, 255, 255), size: maxWidth * 0.15), 
                          Padding(padding:  EdgeInsets.only(bottom: maxWidth * 0.02)), 
                          Text(healthStatuses[status[0]], style: TextStyle(fontSize: maxWidth * 0.06, color: const Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold)),
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
                      child: isLoading ? CircularProgressIndicator(color: Colors.white) :Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(emotionIcons[status[1]], color: const Color.fromARGB(255, 255, 255, 255), size: maxWidth * 0.15), 
                          Padding(padding:  EdgeInsets.only(bottom: maxWidth * 0.02)), 
                          Text(emotionStatus[status[1]], style: TextStyle(fontSize: maxWidth * 0.06, color: const Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold)),
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
          height: 150,
        ),
      ]
    );
  }

  SizedBox newDiaryButton(BuildContext context, {required double width}) {
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

  SizedBox editDiaryButton(BuildContext context, {required double width}) {
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