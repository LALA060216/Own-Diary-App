import 'package:flutter/material.dart';
import 'bottom_menu.dart';

class NewDiary extends StatefulWidget{
  const NewDiary({super.key});

  @override
  State<NewDiary> createState() => _NewDiaryState();
}

class _NewDiaryState extends State<NewDiary> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      resizeToAvoidBottomInset: false,
      appBar: appbar(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double containerHeight = constraints.maxHeight * 0.7;

          return Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: 30),
              child: Container(
                width: 360,
                height: containerHeight,
                decoration: BoxDecoration(
                  color: Color(0xffF9F6EE),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xffEDEADE),
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "Date: ",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "date",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 1.5,
                      color: Color(0xfff1e9d2),
                    ),
                    Expanded(
                      child: TextField(
                        maxLines: null,
                        expands: true,
                        decoration: InputDecoration(
                          hintText: "Write your diary entry here...",
                          contentPadding: EdgeInsets.all(16),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.large(
        
        onPressed: null,
        shape: CircleBorder(),
        backgroundColor: Color(0xffF9F6EE),
        elevation: 2,
        child: Icon(Icons.camera),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  AppBar appbar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      shadowColor: Color(0xffEDEADE),
      elevation: 2,
      backgroundColor: Color(0xfffffaf0),
      centerTitle: true,
      title: Text(
        'New Diary', 
        style: TextStyle(
          fontSize: 30,
          fontFamily: 'Lobstertwo'
        ),
      ), 
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BottomMenu()),
          );
        },
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 20),
          alignment: Alignment.center,
          width: 37,
          child: 
            IconButton(
              onPressed: null, 
              icon: Icon(
                Icons.save_alt_outlined,
                size: 28,
              ),
            )
        )
      ],
    );
  }
}