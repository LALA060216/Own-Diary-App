import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget{
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xfffffaf0),
        shadowColor: Color(0xffEDEADE),
        elevation: 5,
        title: Text(
          'Profile', 
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Lobstertwo',
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: 
              IconButton(
                onPressed: null, 
                icon: Icon(
                  Icons.settings,
                  size: 28,
                ),
              )
          )
        ],

      ),
      backgroundColor: Color(0xfff5f5f5),
      body: Column(
        children: [
          Container(
        
            padding: EdgeInsets.only(left: 10),
            height: 170,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xffdbe9f4),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xffddd6e1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  height: 85,
                  width: 85,
                    child: Icon(
                      Icons.person,
                      size: 34,
                    ),
                  ),
                  
                  Container(
                    width: 250,
                    height: 80,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("username",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Lobstertwo"
                          ),
                        ),
                        Text("username",
                          style: TextStyle(
                            fontSize: 20,
                            
                            fontFamily: "Lobstertwo"
                          ),
                        ),
                      ],
                    ),
                  )
              ],
            ),
          )
        ],
      ),

    );
  }
}