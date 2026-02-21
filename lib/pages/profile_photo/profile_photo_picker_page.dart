import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'profile_photo_crop_page.dart';

class ProfilePhotoPickerPage extends StatefulWidget {
  final String userId;
  final String? currentPhotoUrl;

  const ProfilePhotoPickerPage({
    super.key,
    required this.userId,
    this.currentPhotoUrl,
  });

  @override
  State<ProfilePhotoPickerPage> createState() => _ProfilePhotoPickerPageState();
}

class _ProfilePhotoPickerPageState extends State<ProfilePhotoPickerPage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndGoCrop(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 95,
    );
    if (picked == null || !mounted) return;

    final didSave = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePhotoCropPage(
          userId: widget.userId,
          initialFile: File(picked.path),
        ),
      ),
    );

    if (didSave == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        backgroundColor: const Color(0xfffffaf0),
        title: const Text(
          'Choose Picture',
          style: TextStyle(fontFamily: 'Lobstertwo'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xfff5fffa),
                  border: Border.all(color: const Color(0xffddd6e1), width: 2),
                ),
                child: ClipOval(
                  child: widget.currentPhotoUrl != null
                      ? Image.network(widget.currentPhotoUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.person, size: 80),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _pickAndGoCrop(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose From Gallery'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _pickAndGoCrop(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Take Photo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
