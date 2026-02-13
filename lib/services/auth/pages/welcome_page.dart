import 'package:diaryapp/bottom_menu.dart';
import 'package:diaryapp/services/auth/pages/reset_password_page.dart';
import '../../auth_service.dart';
import 'package:flutter/material.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool hasUppercase = false;
  bool hasLowercase = false;
  bool hasNumber = false;
  bool hasSpecialChar = false;
  bool hasMinLength = false;
  
  bool isSignIn = true;
  bool showPassword = false;
  bool isLoading = false;

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

    setState(() => isLoading = true); // START loading

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

    setState(() => isLoading = false); // STOP loading

  }

  void signIn() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() {
        errorMessage = 'Email and password cannot be empty';
      });
      return;
    }

    setState(() => isLoading = true); // START loading
    
    try {
      await authService.value.signIn(email: emailController.text, password: passwordController.text);
      popPage();
    } catch (e) {
      setState(() {
        errorMessage = 'Email or password is incorrect';
      });
    }

    setState(() => isLoading = false); // STOP loading

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
          backgroundcolor(),
          // Main content
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                // Logo or title area
                logo(),
                SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                // Tab selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      switchSignIn(),
                      switchSignUp(),
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
                      inputEmail(),
                      SizedBox(height: 20),
                      // Password field
                      inputPassword(),
                      // Password requirements for Sign Up
                      if (!isSignIn)
                        passRequirement(),
                      // Name field (Sign Up only)
                      if (!isSignIn)
                        inputUsername(),
                      // Error message display
                      if (errorMessage.isNotEmpty)
                        SizedBox(height: 10),
                        Text(
                          errorMessage,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                      SizedBox(height: 10),
                      // Sign In / Sign Up button
                      signInSignUpButton(),
                      if (isSignIn)
                        forrgetPassButton(),
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

  Row forrgetPassButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ResetPasswordPage()),
            );
          },
          child: Text(
            'Forgot Password?',
            style: TextStyle(
              color: Colors.red,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  ElevatedButton signInSignUpButton() {
    return ElevatedButton(
      // disable button while loading to prevent double-taps
      onPressed: isLoading
          ? null
          : () {
              if (isSignIn) {
                signIn();
              } else {
                register();
              }
            },
      style: ElevatedButton.styleFrom(
        elevation: 2,
        backgroundColor: const Color(0xFFf4f8ff),
        minimumSize: Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
            )
          : Text(
              isSignIn ? 'Sign In' : 'Sign Up',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Column inputUsername() {
    return Column(
      children: [
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'Username',
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
    );
  }

  Padding passRequirement() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    );
  }

  TextField inputPassword() {
    return TextField(
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
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
            horizontal: 20, vertical: 16),
      ),
    );
  }

  TextField inputEmail() {
    return TextField(
      controller: emailController,
      decoration: InputDecoration(
        hintText: 'Email',
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(Icons.email_outlined,
            color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
            horizontal: 20, vertical: 16),
      ),
    );
  }

  GestureDetector switchSignUp() {
    return GestureDetector(
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
              color: Colors.white,
            ),
        ],
      ),
    );
  }

  GestureDetector switchSignIn() {
    return GestureDetector(
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
              color: Colors.white,
            ),
        ],
      ),
    );
  }

  Container logo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
        shape: BoxShape.circle,
        color: Colors.grey[400],
      ),
    );
  }

  Container backgroundcolor() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFddd6e1),
            const Color(0xFFdbe9f4),
            const Color(0xFFf0f8ff),
          ],
        ),
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
