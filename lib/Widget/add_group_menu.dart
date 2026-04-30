import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';

class AddGroupMenu extends StatelessWidget {
  final VoidCallback onCreatePressed;

  const AddGroupMenu({super.key, required this.onCreatePressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GlassContainer(
        height: 120,
        width: 200,
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.015),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderGradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.1),
            Colors.purpleAccent.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        blur: 8,
        borderWidth: 1.2,
        elevation: 20,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuButton(
              context,
              '그룹 만들기',
              Icons.add_circle_outline,
              onCreatePressed,
            ),
            Divider(
              color: Colors.white.withValues(alpha: 0.08),
              height: 1,
              indent: 15,
              endIndent: 15,
            ),
            _buildMenuButton(
              context,
              '그룹 참여하기',
              Icons.group_add_outlined,
              () => print('아직 미구현'),
            ),
          ],
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
        onTapAction();
      },
      // 클릭 시에도 유리 질감을 유지하는 하이라이트
      highlightColor: Colors.white.withValues(alpha: 0.05),
      splashColor: Colors.white.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
