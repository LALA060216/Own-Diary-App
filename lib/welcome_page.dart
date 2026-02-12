import 'package:diaryapp/bottom_menu.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/auth/auth_service.dart';
import 'package:flutter/material.dart';

bool hasUppercase = false;
bool hasLowercase = false;
bool hasNumber = false;
bool hasSpecialChar = false;
bool hasMinLength = false;

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool isSignIn = true;
  bool showPassword = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  String errorMessage = '';



  @override
  void initState() {
    super.initState();
    passwordController.addListener(() {
      updatePasswordRequirements(passwordController.text);
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
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

  void register() async {
    // Validate inputs
    if (emailController.text.isEmpty) {
      setState(() {
        errorMessage = 'Email cannot be empty';
      });
      return;
    }
    if (passwordController.text.isEmpty) {
      setState(() {
        errorMessage = 'Password cannot be empty';
      });
      return;
    }
    if (nameController.text.isEmpty) {
      setState(() {
        errorMessage = 'Name cannot be empty';
      });
      return;
    }

    try {
      await authService.value.signUp(email: emailController.text, password: passwordController.text);
      // Update display name
      await authService.value.updateUsername(username: nameController.text);
      popPage();
    } catch (e) {
      setState(() {
        errorMessage = 'Registration failed';
      });
    }
  }

  void signIn() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() {
        errorMessage = 'Email and password cannot be empty';
      });
      return;
    }

    try {
      await authService.value.signIn(email: emailController.text, password: passwordController.text);
      popPage();
    } catch (e) {
      setState(() {
        errorMessage = 'Email or password is incorrect';
      });
    }
  }


  void popPage(){
    setState(() {
      Navigator.push(context, MaterialPageRoute(builder: (context) => BottomMenu()));
    });
  }

  void resetPassword() async {
    if (emailController.text.isEmpty) {
      setState(() {
        errorMessage = 'Email cannot be empty';
      });
      return;
    }

    try {
      await authService.value.resetPassword(email: emailController.text);
      setState(() {
        errorMessage = 'Password reset email sent';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to send password reset email';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF5C7F5F),
                  const Color(0xFF8B9D6F),
                  const Color(0xFFC4B078),
                ],
              ),
            ),
          ),
          // Main content
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                // Logo or title area
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                // Tab selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isSignIn = true;
                            errorMessage = '';
                          });
                        },
                        child: Column(
                          children: [
                            Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: isSignIn
                                    ? Colors.black87
                                    : Colors.black54,
                              ),
                            ),
                            if (isSignIn)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                height: 3,
                                width: 80,
                                color: const Color(0xFFD4A574),
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isSignIn = false;
                            errorMessage = '';
                          });
                        },
                        child: Column(
                          children: [
                            Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: !isSignIn
                                    ? Colors.black87
                                    : Colors.black54,
                              ),
                            ),
                            if (!isSignIn)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                height: 3,
                                width: 80,
                                color: const Color(0xFFD4A574),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                // Form fields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      // Email field
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(Icons.email_outlined,
                              color: Colors.grey[600]),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
                      ),
                      SizedBox(height: 20),
                      // Password field
                      TextField(
                        controller: passwordController,
                        obscureText: !showPassword,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(Icons.lock_outlined,
                              color: Colors.grey[600]),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                showPassword = !showPassword;
                              });
                            },
                            child: Icon(
                              showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey[600],
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
                      ),
                      // Password requirements for Sign Up
                      if (!isSignIn)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      // Name field (Sign Up only)
                      if (!isSignIn)
                        Column(
                          children: [
                            TextField(
                              controller: nameController,
                              decoration: InputDecoration(
                                hintText: 'Name',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: Icon(Icons.person_outline,
                                    color: Colors.grey[600]),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                              ),
                            ),
                            SizedBox(height: 30),
                          ],
                        ),
                      // Error message display
                      if (errorMessage.isNotEmpty)
                        Text(
                          errorMessage,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                      SizedBox(height: 20),
                      // Sign In / Sign Up button
                      ElevatedButton(
                        onPressed: () {
                          if (isSignIn) {
                            signIn();
                          } else {
                            register();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7A8B4A),
                          minimumSize: Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          isSignIn ? 'Sign In' : 'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RequirementItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isMet;

  RequirementItem({
    required this.icon,
    required this.text,
    required this.isMet,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isMet ? Colors.black : Colors.grey[400],
        ),
        SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isMet ? Colors.black : Colors.grey[400],
          ),
        ),
      ],
    );
  }
}
