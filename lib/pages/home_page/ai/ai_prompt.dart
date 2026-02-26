import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

String promptForMood = 'You are a sentiment analyzer. Analyze the diary entry and select the best matching index (0-19) from the two lists below.\nHealth Statuses (0-19):\n["Healthy", "Infected", "Feverish", "Chills", "Painful", "Fatigued", "Dizzy", "Depressed", "Nauseous", "Active", "Bedridden", "Energetic", "Weak", "Immobile", "Pregnant", "Frail", "Hospitalized", "Hygienic", "Overweight", "Critical"]\nEmotion Statuses (0-19):\n["Happy", "Overjoyed", "Loved", "Neutral", "Sad", "Depressed", "Angry", "Furious", "Annoyed", "Exhausted", "Embarrassed", "Shocked", "Awkward", "Confused", "Scared", "Stressed", "Heartbroken", "Gloomy", "Chill", "Terrible"]\nReturn ONLY two numbers separated by a space.\n!!Important!! Follow these two Rules: 1) If the diary entry describes emotions but DOES NOT mention physical symptoms or health, default the health_index to 0. 2) Do not include any other text, explanations, or formatting. Just the two numbers. Example: 5 10. Bad response: 08 06';
String promptForAnalyse = '''Analyze this diary entry and identify what the user is paying ATTENTION to - the main TOPICS, SUBJECTS, or FOCUS AREAS mentioned.

IMPORTANT RULES:
1. Extract meaningful topics/subjects the person focused on: work, family, friends, school, exercise, health, projects, hobbies, relationships, travel, learning, etc.
2. DO NOT extract vague words like: time, day, today, things, stuff, moment, situation, life, feelings, emotions
3. DO NOT extract people names - use their relationship instead (e.g., "mom" instead of "Sarah")
4. Values are percentages (integers) that must sum to exactly 100
5. Include 2-5 topics maximum, based on what the diary entry emphasizes
6. Do not extract more than 20 alphabet characters for each topic - be concise and specific

EXAMPLES:
- Diary: "Had a great day with family, went to the gym, then did some work emails" -> {"family": 40, "exercise": 30, "work": 30}
- Diary: "Studied for my exam, went to school, met friends for lunch" -> {"school": 45, "study": 35, "friends": 20}
- Diary: "Worked on my project all day, it's going well" -> {"work": 60, "project": 40}

Return ONLY a JSON object with no other text:''';

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
List<String> emotionStatuses = [
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