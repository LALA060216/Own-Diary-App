import 'package:flutter/material.dart';

class viewDiary extends StatelessWidget {
  const viewDiary({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diary Summary'),
        centerTitle: true,
      ),
      body: Center(
        child: Text('This is the Diary Summary Page'),
      ),
    );
  }
}