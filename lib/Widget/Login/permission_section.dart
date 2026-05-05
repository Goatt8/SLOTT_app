import 'package:flutter/material.dart';

class PermissionSection extends StatefulWidget {
  const PermissionSection({
    super.key,
    required this.onPermissionChanged,
  });

  final ValueChanged<bool> onPermissionChanged;

  @override
  State<PermissionSection> createState() => _PermissionSectionState();
}

class _PermissionSectionState extends State<PermissionSection> {
  bool _cameraAgreed = false;
  bool _termsAgreed = false;

  void _notify() {
    widget.onPermissionChanged(_cameraAgreed && _termsAgreed);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _permissionRow(
          "카메라 권한 필수",
          _cameraAgreed,
          (value) {
            setState(() => _cameraAgreed = value ?? false);
            _notify();
          },
        ),
        _permissionRow(
          "이용약관 동의",
          _termsAgreed,
          (value) {
            setState(() => _termsAgreed = value ?? false);
            _notify();
          },
        ),
      ],
    );
  }

  Widget _permissionRow(
    String text,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: CheckboxListTile(
        dense: true,
        value: value,
        onChanged: onChanged,
        checkColor: Colors.black,
        activeColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}
