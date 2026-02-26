import 'package:flutter/material.dart';

class ChangeUsernamePage extends StatelessWidget {
  ChangeUsernamePage({super.key});

  final TextEditingController _usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xffffffff),
        elevation: 0,
        title: Text('Change Username'),
        centerTitle: true,
      ),
      backgroundColor: Color(0xfff5f5f5),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'New Username',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(height: 20),
          Container(
            height: 50,
            width: 180,
            padding: EdgeInsets.only(left: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xfffffaf0),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                // Handle username change logic here
              },
              child: Text('Save Changes'),
            ),
          ),
        ],

      )
    );
  }
}