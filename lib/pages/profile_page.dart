import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firestore_service.dart';
import '../services/models/user_model.dart';
import 'profile_photo/profile_photo_picker_page.dart';
import 'setting_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? currentUserModel;
  StreamSubscription<UserModel?>? _userSubscription;

  // Listen to user data from Firestore
  Stream<UserModel?> _fetchUserData() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return Stream.value(null);
    }
    return _firestoreService.getUserDataStream(userId);
  }

  @override
  void initState() {
    super.initState();
    _userSubscription = _fetchUserData().listen((userModel) {
      if (!mounted) return;
      setState(() {
        currentUserModel = userModel;
      });
    });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  // Show iOS-style action sheet to upload/remove profile photo
  void _showChangePhotoSheet() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text(
            'Profile Picture',
            style: TextStyle(
              fontSize: 20,
            ),
          ),
          message: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xfff5fffa),
                  border: Border.all(color: const Color(0xffddd6e1), width: 2),
                ),
                child: ClipOval(
                  child: currentUserModel?.photoUrl != null
                      ? Image.network(
                          currentUserModel!.photoUrl!,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.person, size: 56),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Choose an option:'),
            ],
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePhotoPickerPage(
                      userId: userId,
                      currentPhotoUrl: currentUserModel?.photoUrl,
                    ),
                  ),
                );
              },
              child: const Text('Change Photo'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(context);
                await _firestoreService.removeProfilePhoto(userId);
              },
              child: const Text('Remove Current Photo'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  // Avatar and username/email display
  Widget _profilePicAndUsernameDisplay(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight * 0.15,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showChangePhotoSheet,
            child: Container(
              height: 85,
              width: 85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xfff5fffa),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffddd6e1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: currentUserModel?.photoUrl != null
                    ? Image.network(
                        currentUserModel!.photoUrl!,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.person, size: 34),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUserModel?.username ?? "Guest",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lobstertwo',
                  ),
                ),
                Text(
                  currentUserModel?.email ?? "",
                  style: const TextStyle(
                    fontSize: 20,
                    fontFamily: 'Lobstertwo',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Display streak and post stats
  Widget _streakAndPost(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0.5,
              child: Container(
                height: screenHeight * 0.06,
                decoration: BoxDecoration(
                  color: const Color(0xffffffff),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Icon(Icons.star_rate, color: Colors.black),
                    const Text(
                      "Streak:",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currentUserModel?.streak.toString() ?? "-",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0.5,
              child: Container(
                height: screenHeight * 0.06,
                decoration: BoxDecoration(
                  color: const Color(0xffffffff),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Icon(Icons.bar_chart, color: Colors.black),
                    const Text(
                      "Post:",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currentUserModel?.totalDiaryPosted.toString() ?? "-",
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffffffff),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Lobstertwo',
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingPage(),
                  ),
                );
              },
              icon: const Icon(
                Icons.settings_outlined,
                size: 28,
              ),
            ),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      backgroundColor: const Color(0xfff5f5f5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _profilePicAndUsernameDisplay(context),
            const Divider(
              height: 1,
              thickness: 2,
              color: Color(0xffe0e0e0),
            ),
            const SizedBox(height: 30),
            _streakAndPost(context),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
