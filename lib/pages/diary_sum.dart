import 'package:flutter/material.dart';

class Diaries extends StatefulWidget {
  const Diaries({super.key});

  @override
  State<Diaries> createState() => _DiariesState();
}

class _DiariesState extends State<Diaries> {
  DateTime selectedDate = DateTime.now();
  List<String> diaryData = [
  "Went to gym",
  "Study Flutter",
  "Met friends",
  "Had a great day",
  "Watched a movie",
  "Cooked dinner",
  "Read a book",
  "Went for a walk",
  "Learned something new",
  "Had a relaxing day",
  "This is a sample diary entry for the selected month. You can replace this with actual diary data from your database or API.",
  "Another diary entry for the selected month. This is just placeholder text to demonstrate how the diary entries will be displayed in the app."];


void previousMonth() {
  setState(() {
    selectedDate = DateTime(
      selectedDate.year,
      selectedDate.month - 1,
    );
  });
}

void nextMonth() {
  setState(() {
    selectedDate = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
    );
  });
}

String monthName(int month) {
  const months = [
    "January","February","March","April",
    "May","June","July","August",
    "September","October","November","December"
  ];

  return months[month - 1];
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
        title: Text('Diary Summary',
          style: TextStyle(
            fontSize: 24,
            color: Colors.black,
            fontFamily: 'lobstertwo',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey,
                      ),
                      SizedBox(height: 5),
                      Text("Event $index"),
                    ],
                  ),
                );
              },
            ),
          ),
          
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_left),
                onPressed: previousMonth,
              ),

              SizedBox(width: 10),

              Text(
                "${monthName(selectedDate.month)} ${selectedDate.year}",
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold),
              ),

              Spacer(),

              IconButton(
                icon: Icon(Icons.calendar_month),
                onPressed: () async{
                  DateTime? pickedDate = await showDatePicker(
                    context: context, 
                    initialDate: selectedDate, 
                    firstDate: DateTime(2000), 
                    lastDate: DateTime(2100)
                  );

                  if(pickedDate != null){
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
              ),

              IconButton(
                icon: Icon(Icons.arrow_right),
                onPressed: nextMonth,
              ),
            ],
          ),

          Expanded(
            child: ListView.builder(
              itemCount: diaryData.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Text(diaryData[index]),
                );
              },
            ),
          ),
        ],
      )
    );
  }
}