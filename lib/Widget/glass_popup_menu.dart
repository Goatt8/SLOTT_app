import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';

class GlassMenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  GlassMenuItem({required this.title, required this.icon, required this.onTap});
}

class GlassPopupMenu extends StatelessWidget {
  final List<GlassMenuItem> items;
  final double width;

  const GlassPopupMenu({super.key, required this.items, this.width = 220});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GlassContainer(
        height: (items.length * 56.0) + (items.length - 1) + 8.0,
        width: width,
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderGradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
        blur: 12,
        borderWidth: 1.2,
        elevation: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(items.length, (index) {
            final item = items[index];
            return Column(
              children: [
                _buildMenuButton(context, item),
                if (index != items.length - 1)
                  Divider(
                    color: Colors.white.withValues(alpha: 0.08),
                    height: 1,
                    indent: 15,
                    endIndent: 15,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, GlassMenuItem item) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        item.onTap();
      },
      highlightColor: Colors.white.withValues(alpha: 0.05),
      splashColor: Colors.white.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: Colors.white.withValues(alpha: 0.9),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
