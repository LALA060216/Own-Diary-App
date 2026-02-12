import 'package:diaryapp/auth/auth_service.dart';
import 'package:flutter/material.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}


class _ResetPasswordPageState extends State<ResetPasswordPage> {
  String error_message = '';
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Color(0xfff0f8ff),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
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
                try{
                  authService.value.resetPassword(email: _emailController.text);
                } catch (e) {
                  // Handle error if needed
                  setState(() {
                    error_message = e.toString();
                  });
                }

              },
              child: Text('Send Reset Email'),
            ),
          ),
        ],

      )
    );
  }
}