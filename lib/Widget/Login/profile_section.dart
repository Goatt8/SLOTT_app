import 'package:bababam_app/Widget/custom_text_field.dart';
import 'package:flutter/material.dart';

class ProfileSection extends StatefulWidget {
  const ProfileSection({super.key, required this.onProfileChanged});

  final ValueChanged<bool> onProfileChanged;

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
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
                ),
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              ),
              //MARK: Camera Button
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        CustomTextField(hint: '닉네임', controller: _nicknameController),
      ],
    );
  }
}
