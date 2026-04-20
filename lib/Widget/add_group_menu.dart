import 'package:flutter/material.dart';

class AddGroupMenu extends StatelessWidget {
  final VoidCallback onCreatePressed;

  const AddGroupMenu({super.key, required this.onCreatePressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 240,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuButton(
                context,
                '그룹 만들기',
                Icons.add_circle_outline,
                onCreatePressed,
              ),
              const Divider(color: Colors.white10, height: 1),
              _buildMenuButton(
                context,
                '그룹 참여하기',
                Icons.group_add_outlined,
                () => print('아직 미구현'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTapAction,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        print('$title 클릭됨');
        onTapAction();
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
