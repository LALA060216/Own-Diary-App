import 'package:flutter/material.dart';
import 'package:diaryapp/auth/auth_service.dart';
import 'package:diaryapp/welcome_page.dart';


class DeleteAcc extends StatefulWidget {
  DeleteAcc({super.key});

  @override
  _DeleteAccState createState() => _DeleteAccState();
}

class _DeleteAccState extends State<DeleteAcc> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String error_message = '';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Delete Account"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
                ),
              
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.only(left: 16),
            height: 50,
            width: 200,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                try {
                  authService.value.deleteAccount(
                    email: emailController.text,
                    password: passwordController.text,
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => WelcomePage()),
                    (route) => false,
                  );
                } catch (e) {
                  // Handle error, e.g., show a snackbar or dialog
                  setState(() {
                    error_message = "Error deleting account: $e";
                  });
                }
              },
              child: Text("Delete Account"),
            ),
          ),
          if (error_message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                error_message,
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}