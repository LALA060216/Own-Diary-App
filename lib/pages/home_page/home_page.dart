import 'dart:convert';
import 'package:diaryapp/main.dart';
import 'package:diaryapp/services/firestore_service.dart';
import 'package:diaryapp/services/gemini_service.dart';
import 'package:diaryapp/services/models/ai_chat_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:diaryapp/pages/home_page/ai/ai_prompt.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../newdiary_page.dart';

bool createdNewDiaryToday = false;
bool updatedDiary = true;
bool hasLoadedInitial = false;
String streak = '';
String oldDiaryContext = '';
int analyseIndex = 0;
List<List<int>> mood = [[0,0], [0,0]]; 
List<Map<String, int>> attentionData = [{},{}];
TextEditingController previousDiaryController = TextEditingController();

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with RouteAware{
  late final FirestoreService firestoreService = FirestoreService();
  late final String userId = FirebaseAuth.instance.currentUser!.uid;
  late final AIChatModel _moodModel = AIChatModel(prompt: promptForMood, model: 'gemini-2.5-flash');
  late final AIChatModel _attentionModel = AIChatModel(prompt: promptForAnalyse, model: 'gemini-2.5-flash');

  List<String> imageUrls = [];
  String? diaryId = '';
  bool isLoading = false;
  bool isloadingAttention = false;
  DateTime now = DateTime.now();

  static const _moodTitleStyle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    fontFamily: 'Lobstertwo',
    color: Colors.black87,
  );
  String previousTitle = '';

  @override
  void initState() {
    super.initState();
    _checkIfCreatedNewDiaryToday();
    _getStreak();
    if (!hasLoadedInitial){
      if (now.weekday == DateTime.monday) {
        _updateWeeklyMoodAndAttention(requestAi: true);
      } else {
        _updateWeeklyMoodAndAttention(requestAi: false);
      }
      hasLoadedInitial = true;
    }
    _didUpdatedDiary().then((updated) {
      if (updated) {
        _updateDailyMoodAndAttention(requestAi: true);
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
            isloadingAttention = false;
          });
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _checkIfCreatedNewDiaryToday() async {
    final newestDiary = await firestoreService.getNewestDiaryDetail(userId);
    DateTime? newestDate = newestDiary?.created;
    previousDiaryController.text = newestDiary?.context ?? '';
    imageUrls = newestDiary?.imageUrls ?? [];
    diaryId = newestDiary?.id;
    previousTitle = newestDiary?.title ?? '';

    if (!mounted) return ;
    setState(() {
      createdNewDiaryToday = newestDate != null && DateUtils.isSameDay(newestDate, DateTime.now());
    });
  }

  Future<String> _getDiaryContext(String contextType) async {
    if (contextType == 'daily') {
      final newestDiary = await firestoreService.getNewestDiaryDetail(userId);
      return newestDiary?.context ?? '';
    } else if (contextType == 'weekly') {
      return await firestoreService.getUserDiaryContextPastWeek(userId);
    }
    return '';
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

  Future<void> _refreshMood(String context, {int? index, bool requestAi = true}) async {
    final analyseIndexMood = index ?? analyseIndex;
    
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    
    if (requestAi) {
      await GeminiService(chatModel: _moodModel).getMoodAnalysis(context).then((value) {
        try {
          final match = RegExp(r'^\s*(\d+)\s+(\d+)\s*$').firstMatch(value);

          if (match == null) {
            if (!mounted) return;
            setState(() {
              isLoading = false;
              mood[analyseIndexMood] = [0, 0];
            });
            return;
          }

          final healthIndex = int.parse(match.group(1)!)
              .clamp(0, healthStatuses.length - 1);
          final emotionIndex = int.parse(match.group(2)!)
              .clamp(0, emotionStatuses.length - 1);

          if (!mounted) return;
          setState(() {
            isLoading = false;
            mood[analyseIndexMood] = [healthIndex, emotionIndex];
          });

          if (index == 0) {
            firestoreService.updateDailyMood(userId, '$healthIndex-$emotionIndex');
          } else if (index == 1) {
            firestoreService.updateWeeklyMood(userId, '$healthIndex-$emotionIndex');
          }

        } catch (e) {
          if (!mounted) return;
          setState(() {
            isLoading = false;
            mood[analyseIndexMood] = [0, 0];
          });
        }
      });
    } else {
      try {
        final storedMoodIndex = await firestoreService.getuserMood(userId, index == 0 ? 'dailyMood' : 'weeklyMood');
        if (storedMoodIndex.contains('-')) {
          final moodIndices = storedMoodIndex.split('-'); 
          if (moodIndices.length == 2) {
            final healthIndex = int.parse(moodIndices[0])
                .clamp(0, healthStatuses.length - 1);
            final emotionIndex = int.parse(moodIndices[1])
                .clamp(0, emotionStatuses.length - 1);
            
            if (!mounted) return;
            setState(() {
              isLoading = false;
              mood[analyseIndexMood] = [healthIndex, emotionIndex];
            });
          }
        }
      } catch (e) {
        print('Error loading stored mood: $e');
        if (!mounted) return;
        setState(() {
          isLoading = false;
          mood[analyseIndexMood] = [0, 0];
        });
      }
    }
  }

  Future<void> _refreshAttention(String context, {int? index, bool requestAi = true}) async {
    final analyseIndexAttention = index ?? analyseIndex;

    if (!mounted) return;
    setState(() {
      isloadingAttention = true;
    });
    
    if (requestAi) {
      await GeminiService(chatModel: _attentionModel).getAttentionAnalysis(context).then((value) {
        print(value);
        try {
          Map<String, int> parsedData = {};
          String cleanedValue = value.trim();
          if (cleanedValue.startsWith('```')) {
            cleanedValue = cleanedValue
                .replaceAll(RegExp(r'```json\s*'), '')
                .replaceAll(RegExp(r'```\s*'), '')
                .trim();
          }
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
          if (!mounted) return;
          setState(() {
            isloadingAttention = false;
            attentionData[analyseIndexAttention] = parsedData;
          });

          if (index == 0) {
            firestoreService.updateDailyAttention(userId, '$parsedData');
          } else if (index == 1) {
            firestoreService.updateWeeklyAttention(userId, '$parsedData');
          }

        } catch (e) {
          print("Error decoding attention analysis: $e");
          print("Response was: $value");
          if (!mounted) return;
          setState(() {
            isloadingAttention = false;
            attentionData[analyseIndexAttention] = {};
          });
        }
      });
    } else {
      try {
        final storedAttention = await firestoreService.getUserAttention(userId, index == 0 ? 'dailyAttention' : 'weeklyAttention');
        if (storedAttention.isNotEmpty){
          Map<String, int> parsedData = {};
          String cleanedValue = storedAttention.trim();
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
          if (!mounted) return;
          setState(() {
            isloadingAttention = false;
            attentionData[analyseIndexAttention] = parsedData;
          });
        }
      } catch (e) {
        print('Error loading stored attention: $e');
        if (!mounted) return;
        setState(() {
          isloadingAttention = false;
          attentionData[analyseIndexAttention] = {};
        });
      }
    }
  }

  Future<void> _updateWeeklyMoodAndAttention({bool requestAi = true}) async {
    try {
      final context = await _getDiaryContext('weekly');
      if (!mounted) return;
      // Run mood and attention analysis in parallel instead of sequentially
      await Future.wait([
        _refreshMood(context, index: 1, requestAi: requestAi),
        _refreshAttention(context, index: 1, requestAi: requestAi),
      ]);
    } catch (e) {
      print('Error updating weekly mood and attention: $e');
    }
  }

  Future<void> _updateDailyMoodAndAttention({bool requestAi = true}) async {
    try {
      final context = await _getDiaryContext('daily');
      if (!mounted) return;
      // Run mood and attention analysis in parallel instead of sequentially
      await Future.wait([
        _refreshMood(context, index: 0, requestAi: requestAi),
        _refreshAttention(context, index: 0, requestAi: requestAi),
      ]);
    } catch (e) {
      print('Error updating daily mood and attention: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff0f0f0),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            color: Color(0xffffffff),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 15,
                        ),
                        diaryButton(context, height: 180, width: maxWidth, text: "New Diary"),
                        SizedBox(
                          height: 30,
                        ),
                        if (createdNewDiaryToday) 
                          diaryButton(context, height: 110, width: maxWidth, text: "Edit Previous Diary")
                        else
                          Container(
                            width: maxWidth,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Color(0xffffffff),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xffe6e6e6),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "You haven't created a diary today",
                                style: TextStyle(fontSize: 16, color: Colors.black54),
                              ),
                            ),
                          ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          width: constraints.maxWidth * 0.95,
                          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                          padding: EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  Center(
                                    child: const Text(
                                      "Mood",
                                      style: _moodTitleStyle,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end, 
                                    children: [
                                      _rangeButton(
                                        "1D",
                                        isSelected: analyseIndex == 0,
                                        onPressed: () => {setState(() => analyseIndex = 0)},
                                      ),
                                      SizedBox(width: 4),
                                      _rangeButton(
                                        "1W",
                                        isSelected: analyseIndex == 1,
                                        onPressed: () => {setState(() => analyseIndex = 1)},
                                      ),
                                    ]
                                  ),
                                ]
                              ),
                              SizedBox(height: 20),
                              moodBlocks(maxWidth, createdNewDiaryToday),
                              SizedBox(height: 20),
                              if (isloadingAttention)
                                CircularProgressIndicator()
                              else
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
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.local_fire_department_rounded, color: Color.fromARGB(255, 237, 84, 84), size: 40),
          SizedBox(width:5),
          Text(streak.toString(), style: const TextStyle(fontSize: 30, color: Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.bold)),
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
                    color: (createdNewDiaryToday && analyseIndex == 0) || (analyseIndex == 1 && attentionData[1].isNotEmpty) ? healthColors[mood[analyseIndex][0]]: Color.fromARGB(255, 100, 100, 100) ,
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
                            FaIcon((createdNewDiaryToday && analyseIndex == 0) || (analyseIndex == 1 && attentionData[1].isNotEmpty) ? healthIcons[mood[analyseIndex][0]] : Icons.question_mark, color: const Color.fromARGB(255, 255, 255, 255), size: maxWidth * 0.15), 
                            Padding(padding:  EdgeInsets.only(bottom: maxWidth * 0.02)), 
                            Text((createdNewDiaryToday && analyseIndex == 0) || (analyseIndex == 1 && attentionData[1].isNotEmpty) ? healthStatuses[mood[analyseIndex][0]] : "No data", style: TextStyle(fontSize: maxWidth * 0.05, color: const Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: maxWidth * 0.105,
              ),
              SizedBox(
                width: maxWidth * 0.45,
                height: maxWidth * 0.45,
                child: Container(
                  decoration: BoxDecoration(
                    color: (createdNewDiaryToday && analyseIndex == 0) || (analyseIndex == 1 && attentionData[1].isNotEmpty) ? emotionColors[mood[analyseIndex][1]] : Color.fromARGB(255, 100, 100, 100),
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
                            FaIcon((createdNewDiaryToday && analyseIndex == 0) || (analyseIndex == 1 && attentionData[1].isNotEmpty) ? emotionIcons[mood[analyseIndex][1]] : Icons.question_mark, color: const Color.fromARGB(255, 255, 255, 255), size: maxWidth * 0.15), 
                            Padding(padding:  EdgeInsets.only(bottom: maxWidth * 0.02)), 
                            Text((createdNewDiaryToday && analyseIndex == 0) || (analyseIndex == 1 && attentionData[1].isNotEmpty) ? emotionStatuses[mood[analyseIndex][1]] : "No data", style: TextStyle(fontSize: maxWidth * 0.05, color: const Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold)),
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

  Widget _rangeButton(
    String label, {
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 40,
      width: 35,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? const Color.fromARGB(255, 0, 0, 0)
              : const Color.fromARGB(255, 233, 233, 233),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildAttentionChart(){
    if (attentionData.length <= analyseIndex || attentionData[analyseIndex] == {'Error': 0} || attentionData[analyseIndex].isEmpty) {
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
    List<PieChartSectionData> sections = [];
    List<MapEntry<String, int>> sortedAttentionData = {'No Data': 100}.entries.toList();
    // sort attentionData by value in descending order 
    if (!createdNewDiaryToday && analyseIndex == 0) {
      sections = [
        PieChartSectionData(
          value: 100,
          color: Colors.grey.shade300,
          radius: 80,
          title: '',
          titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black45,
          )
        )
      ];
    } else {
      sortedAttentionData = attentionData[analyseIndex].entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      sections = sortedAttentionData.map((entry) {
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
    }

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
                          color: data.key != 'No Data' ? color : Colors.grey.shade300,
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
                          fontSize: 10,
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

  SizedBox diaryButton(BuildContext context, {required double height, required double width, required String text}) {
    return SizedBox(
      height: height,
      width: width,
      child: 
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => text == 'New Diary' ? NewDiary() : NewDiary(previousDiaryController: previousDiaryController, previousImageUrls: imageUrls, diaryId: diaryId, previousTitle: previousTitle)),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xffffffff),
            foregroundColor: const Color.fromARGB(255, 61, 61, 61),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Adjust the radius as needed
            ),
            elevation: 5,
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
                text,
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