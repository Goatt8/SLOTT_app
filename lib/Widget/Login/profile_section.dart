import 'package:bababam_app/Widget/custom_text_field.dart';
import 'package:flutter/material.dart';

class ProfileSection extends StatefulWidget {
  const ProfileSection({
    super.key,
    required this.onProfileChanged,
  });

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
  Widget build(BuildContext context) {
    return CustomTextField(
      hint: "닉네임 입력",
      controller: _nicknameController,
      onChanged: (value) => widget.onProfileChanged(value.trim().isNotEmpty),
    );
  }
}
