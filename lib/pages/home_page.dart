import 'dart:convert';

import 'package:diaryapp/main.dart';
import 'package:diaryapp/services/firestore_service.dart';
import 'package:diaryapp/services/gemini_service.dart';
import 'package:diaryapp/services/models/ai_chat_model.dart';
import 'package:diaryapp/services/models/diary_entry_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'newdiary_page.dart';

bool createdNewDiaryToday = false;
String streak = '';
List<int> status = [0,0];
String oldDiaryContext = '';
bool updatedDiary = true;
Map<String, int> attentionData = {};

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
  bool isloadingAttention = false;

  String promptForMood = 'You are a sentiment analyzer. Analyze the diary entry and select the best matching index (0-19) from the two lists below.\nHealth Statuses (0-19):\n["Healthy", "Infected", "Feverish", "Chills", "Painful", "Fatigued", "Dizzy", "Depressed", "Nauseous", "Active", "Bedridden", "Energetic", "Weak", "Immobile", "Pregnant", "Frail", "Hospitalized", "Hygienic", "Overweight", "Critical"]\nEmotion Statuses (0-19):\n["Happy", "Overjoyed", "Loved", "Neutral", "Sad", "Depressed", "Angry", "Furious", "Annoyed", "Exhausted", "Embarrassed", "Shocked", "Awkward", "Confused", "Scared", "Stressed", "Heartbroken", "Gloomy", "Chill", "Terrible"]\nReturn ONLY two numbers separated by a space.\n!!Important!! Follow these two Rules: 1) If the diary entry describes emotions but DOES NOT mention physical symptoms or health, default the health_index to 0. 2) Do not include any other text, explanations, or formatting. Just the two numbers. Example: 5 10. Bad response: 08 06';
  String promptForAnalyse = '''Analyze this diary entry and identify what the user is paying ATTENTION to - the main TOPICS, SUBJECTS, or FOCUS AREAS mentioned.

IMPORTANT RULES:
1. Extract meaningful topics/subjects the person focused on: work, family, friends, school, exercise, health, projects, hobbies, relationships, travel, learning, etc.
2. DO NOT extract vague words like: time, day, today, things, stuff, moment, situation, life, feelings, emotions
3. DO NOT extract people names - use their relationship instead (e.g., "mom" instead of "Sarah")
4. Values are percentages (integers) that must sum to exactly 100
5. Include 2-5 topics maximum, based on what the diary entry emphasizes

EXAMPLES:
- Diary: "Had a great day with family, went to the gym, then did some work emails" -> {"family": 40, "exercise": 30, "work": 30}
- Diary: "Studied for my exam, went to school, met friends for lunch" -> {"school": 45, "study": 35, "friends": 20}
- Diary: "Worked on my project all day, it's going well" -> {"work": 60, "project": 40}

Return ONLY a JSON object with no other text:''';
  
  late AIChatModel _chatModel = AIChatModel(prompt: promptForMood, model: 'gemma-3-27b-it');
  late AIChatModel _analyseChatModel = AIChatModel(prompt: promptForAnalyse, model: 'gemma-3-27b-it');
  String previousTitle = '';

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

  List<Color> healthColors = [
  Colors.green,              // Healthy
  Colors.purpleAccent,       // Infected (Virus color)
  Colors.deepOrange,         // Feverish (Hot)
  Colors.cyan,               // Chills (Cold)
  Colors.red,                // Painful
  Colors.brown.shade300,     // Fatigued
  Colors.blueGrey,           // Dizzy
  Colors.indigo,             // Depressed (Health context)
  Colors.lime.shade800,      // Nauseous (Sickly green)
  Colors.teal,               // Active
  Colors.blueGrey.shade200,  // Bedridden
  Colors.amber,              // Energetic
  Colors.amber.shade100,     // Weak
  Colors.grey,               // Immobile
  Colors.pinkAccent.shade100,// Pregnant
  Colors.brown.shade100,     // Frail
  Colors.lightBlue.shade100, // Hospitalized (Sterile blue)
  Colors.lightBlue,          // Hygienic
  Colors.orange.shade800,    // Overweight
  Colors.red.shade900,       // Critical
];
  List<Color> emotionColors = [
  Colors.yellow.shade700,    // Happy
  Colors.orangeAccent,       // Overjoyed
  Colors.pink,               // Loved
  Colors.grey.shade400,      // Neutral
  Colors.blue,               // Sad
  Colors.blueGrey.shade900,  // Depressed
  Colors.redAccent,          // Angry
  Colors.red.shade900,       // Furious
  Colors.deepOrangeAccent,   // Annoyed
  Colors.brown.shade200,     // Exhausted
  Colors.deepOrange.shade100,// Embarrassed (Blush)
  Colors.purpleAccent,       // Shocked
  Colors.lime,               // Awkward
  Colors.tealAccent,         // Confused
  Colors.deepPurple,         // Scared
  Colors.amber.shade900,     // Stressed
  Colors.pink.shade900,      // Heartbroken
  Colors.blueGrey,           // Gloomy
  Colors.cyanAccent,         // Chill
  Colors.brown,              // Terrible
];

  @override
  void initState() {
    super.initState();
    _checkIfCreatedNewDiaryToday();
    _didUpdatedDiary().then((updated) {
      if (updated) {
        String context = oldDiaryContext;
        _refreshMood(context);
        _refreshAttention(context);
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
        String context = oldDiaryContext;
        _refreshMood(context);
        _refreshAttention(context);
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
    previousTitle = newestDiary?.title ?? '';

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

  Future<void> _refreshMood(String context) async {
    isLoading = true;
    await GeminiService(chatModel: _chatModel).getMoodAnalysis(context).then((value) {
      try {
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
        if (!mounted) return;
        setState(() {
          status = [0, 0];
        });
      }
    });
  }

  Future<void> _refreshAttention(String context) async {
    isloadingAttention = true;
    
    await GeminiService(chatModel: _analyseChatModel).getAttentionAnalysis(context).then((value) {
      try {
        Map<String, int> parsedData = {};
        String cleanedValue = value.trim();
        if (cleanedValue.startsWith('```')) {
          cleanedValue = cleanedValue
              .replaceAll(RegExp(r'```json\s*'), '')
              .replaceAll(RegExp(r'```\s*'), '')
              .trim();
        }
        // Try to parse as JSON
        try {
          final Map<String, dynamic> jsonData = jsonDecode(cleanedValue);
          jsonData.forEach((key, value) {
            parsedData[key] = value is int ? value : int.tryParse(value.toString()) ?? 0;
          });
        } catch (jsonError) {
          String cleaned = cleanedValue.replaceAll(RegExp(r'[{}]'), '').trim();
          List<String> pairs = cleaned.split(',');

          for (String pair in pairs) {
            List<String> keyValue = pair.split(':');
            if (keyValue.length == 2) {
              String key = keyValue[0].trim().replaceAll('"', '');
              int val = int.tryParse(keyValue[1].trim()) ?? 0;
              parsedData[key] = val;
            }
          }
        }


        setState(() {
          isloadingAttention = false;
          attentionData = parsedData;
        });

      } catch (e) {
        print("Error decoding attention analysis: $e");
        print("Response was: $value");
        if (!mounted) return;
        setState(() {
          isloadingAttention = false;
          attentionData = {};
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
          Container(
            color: Color(0xfff5f5f5),
            child: Column(
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
              ],
            ),
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
                        if (createdNewDiaryToday)
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                            padding: EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "Mood",
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Lobstertwo',
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 20),
                                moodBlocks(maxWidth, createdNewDiaryToday),
                                SizedBox(height: 20),
                                if (isloadingAttention)
                                  CircularProgressIndicator()
                                else if (attentionData.isNotEmpty)
                                  _buildAttentionChart(),
                              ],
                            ),
                          ),
                        SizedBox(
                          height: 20,
                        ),
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
        borderRadius: BorderRadius.circular(25)
      ),
      padding: EdgeInsets.all(8),
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
                    color: createdNewDiaryToday ? healthColors[status[0]] : Color.fromARGB(255, 100, 100, 100),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      onTap: null,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: isLoading ? Center(child: CircularProgressIndicator(color: Colors.white)) : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(healthIcons[status[0]], color: const Color.fromARGB(255, 255, 255, 255), size: maxWidth * 0.15), 
                            Padding(padding:  EdgeInsets.only(bottom: maxWidth * 0.02)), 
                            Text(healthStatuses[status[0]], style: TextStyle(fontSize: maxWidth * 0.06, color: const Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
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
                    color: createdNewDiaryToday ? emotionColors[status[1]] : Color.fromARGB(255, 100, 100, 100),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      onTap: null,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: isLoading ? Center(child: CircularProgressIndicator(color: Colors.white)) : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(emotionIcons[status[1]], color: const Color.fromARGB(255, 255, 255, 255), size: maxWidth * 0.15), 
                            Padding(padding:  EdgeInsets.only(bottom: maxWidth * 0.02)), 
                            Text(emotionStatus[status[1]], style: TextStyle(fontSize: maxWidth * 0.05, color: const Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ),
            ]
          ),
        ),
      ]
    );
  }

  Widget _buildAttentionChart(){
    if (attentionData.isEmpty) {
      return SizedBox.shrink();
    }
    
    // More vibrant and appealing colors
    List<Color> chartColors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEC4899), // Pink
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFEF4444), // Red
      const Color(0xFF14B8A6), // Teal
    ];

    int colorIndex = 0;
    // sort attentionData by value in descending order 
    var sortedAttentionData = attentionData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    List<PieChartSectionData> sections = sortedAttentionData.map((entry) {
      final section = PieChartSectionData(
        value: entry.value.toDouble(),
        color: chartColors[colorIndex % chartColors.length],
        radius: 80,
        title: '${entry.value}%',
        titleStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        )
      );
      colorIndex++;
      return section;
    }).toList();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      padding: EdgeInsets.all(25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Attention Focus',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Lobstertwo',
            ),
          ),
          SizedBox(height: 50),
          SizedBox(
            height: 240,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 65,
                sectionsSpace: 10,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          SizedBox(height: 30),
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Wrap(
              spacing: 15,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: sortedAttentionData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final color = chartColors[index % chartColors.length];

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withOpacity(0.3), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        data.key,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${data.value}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
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
              MaterialPageRoute(builder: (context) => NewDiary(previousDiaryController: _previousDiaryController, previousImageUrls: imageUrls, diaryId: diaryId, previousTitle: previousTitle)),
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