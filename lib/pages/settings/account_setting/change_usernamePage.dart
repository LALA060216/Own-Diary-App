import 'package:flutter/material.dart';

class ChangeUsernamePage extends StatelessWidget {
  ChangeUsernamePage({super.key});

  final TextEditingController _usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Username'),
        centerTitle: true,
      ),
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
                backgroundColor: Color(0xfff8f4ff),
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