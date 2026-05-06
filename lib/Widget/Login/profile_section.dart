import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bababam_app/Model/app_user.dart';
import 'package:bababam_app/Service/firestore_service.dart';
import 'package:bababam_app/Service/firestorage_service.dart';
import 'package:bababam_app/Widget/custom_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSection extends StatefulWidget {
  const ProfileSection({super.key, required this.onProfileChanged});

  final ValueChanged<bool> onProfileChanged;

  @override
  State<ProfileSection> createState() => ProfileSectionState();
}

class ProfileSectionState extends State<ProfileSection> {
  final TextEditingController _nicknameController = TextEditingController();
  File? _pickedImage;

  bool get isReadyToSubmit {
    return _nicknameController.text.trim().isNotEmpty && _pickedImage != null;
  }

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(() {
      widget.onProfileChanged(isReadyToSubmit);
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
      widget.onProfileChanged(isReadyToSubmit);
    }
  }

  Future<void> createUserInProfileSection() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) return;

    String? imageUrl;

    if (_pickedImage != null) {
      imageUrl = await FireStorageService().uploadProfileImage(
        uid: authUser.uid,
        imageFile: _pickedImage!,
      );
    }
    final newUser = AppUser(
      id: authUser.uid,
      name: _nicknameController.text,
      phoneNumber: authUser.phoneNumber ?? "",
      profileUrl: imageUrl,
    );

    await FireStoreService().createUser(newUser);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //MARK: ImageView
        Center(
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.white24),
                  image: _pickedImage != null
                      ? DecorationImage(
                          image: FileImage(_pickedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _pickedImage == null
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
              //MARK: Camera Button
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue,
                    child: Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        CustomTextField(hint: '닉네임을 입력해주세요', controller: _nicknameController),
      ],
    );
  }
}
