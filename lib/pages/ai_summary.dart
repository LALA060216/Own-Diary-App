import 'package:flutter/material.dart';

class AiSummary extends StatelessWidget {
  const AiSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xfff5f5f5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        shadowColor: Color(0xffEDEADE),
        elevation: 2,
        backgroundColor: Color(0xfffffaf0),
        title: Text('AI Summary',
          style: TextStyle(
            fontSize: 24,
            color: Colors.black,
            fontFamily: 'lobstertwo',
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Text('This is the AI Summary Page'),
      ),
    );
  }
}