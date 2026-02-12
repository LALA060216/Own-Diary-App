import 'package:flutter/material.dart';
import 'newdiary_page.dart';

class Homepage extends StatelessWidget{
  const Homepage({super.key});

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
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            SizedBox(
              height: 50,
            ),
            new_diary_button(context),
            SizedBox(
              height: 60,
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
                                borderRadius: BorderRadius.circular(10), // Adjust the radius as needed
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
      ),
    );
  }

  SizedBox new_diary_button(BuildContext context) {
    return SizedBox(
            height: 180,
            width: 300,
            child: 
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NewDiary()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xffF9F6EE),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Adjust the radius as needed
                  ),
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