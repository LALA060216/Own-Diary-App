import 'package:diaryapp/services/auth_service.dart';
import 'package:diaryapp/services/auth/pages/welcome_page.dart';
import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() {
      updatePasswordRequirements(_newPasswordController.text);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void updatePasswordRequirements(String value) {
    setState(() {
      hasUppercase = value.contains(RegExp(r'[A-Z]'));
      hasLowercase = value.contains(RegExp(r'[a-z]'));
      hasNumber = value.contains(RegExp(r'[0-9]'));
      hasSpecialChar =
          value.contains(RegExp(r"[!@#$%^&*()_+\-=\[\]{};:'\,.<>?/\\|`~]"));
      hasMinLength = value.length >= 8;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password'),
        centerTitle: true,
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
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _currentPasswordController,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),

          ),
          if(errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RequirementItem(
                      icon: Icons.check_circle,
                      text: '1 uppercase',
                      isMet: hasUppercase,
                    ),
                    SizedBox(height: 8),
                    RequirementItem(
                      icon: Icons.check_circle,
                      text: '1 lowercase',
                      isMet: hasLowercase,
                    ),
                    SizedBox(height: 8),
                    RequirementItem(
                      icon: Icons.check_circle,
                      text: '1 number',
                      isMet: hasNumber,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RequirementItem(
                      icon: Icons.check_circle,
                      text: '1 special character',
                      isMet: hasSpecialChar,
                    ),
                    SizedBox(height: 8),
                    RequirementItem(
                      icon: Icons.check_circle,
                      text: '8 minimum character',
                      isMet: hasMinLength,
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                  authService.value.updatePassword(currentPassword: _currentPasswordController.text, newPassword: _newPasswordController.text, email: _emailController.text);
                } catch (e) {
                  setState(() {
                    errorMessage = e.toString();
                  });
                }
              },
              child: Text('Save Changes'),
            ),
          ),
        ],

      )
    );
  }
}