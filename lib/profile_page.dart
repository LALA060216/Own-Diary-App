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
          profile_pic_and_username_display(),
          Divider(
            height: 1,
            thickness: 1,
            color: Color(0xffe0e0e0),
          ),
          SizedBox(height: 35),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 1,
                child: 
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: 130,
                      height: 50,
                      color: Color(0xffF9F6EE),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.star_rate,
                            color: Colors.black,
                          ),
                          Text(
                            "Streak:",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "0",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: 130,
                      height: 50,
                      color: Colors.green,
                    ),
                  )
                ],
              ),
        ],
      )
    

    );
  }

  Container profile_pic_and_username_display() {
    return Container(
          color: Color(0xfff7fcfe),
          padding: EdgeInsets.only(left: 10),
          height: 150,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xfff5fffa),
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
        );
  }
}