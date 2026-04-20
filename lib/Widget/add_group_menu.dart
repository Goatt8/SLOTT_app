import 'package:flutter/material.dart';

class AddGroupMenu extends StatelessWidget {
  const AddGroupMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      // Dialog의 바깥 여백을 없애기 위해 사용
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 240, // 미니뷰 가로폭
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // 진한 그레이
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10), // 아주 미세한 테두리
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 내용물 크기에 맞게 세로 길이 조절
            children: [
              _buildMenuButton(context, '로그 만들기', Icons.add_circle_outline),
              const Divider(color: Colors.white10, height: 1), // 구분선
              _buildMenuButton(context, '로그 참여하기', Icons.group_add_outlined),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, IconData icon) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // 메뉴 닫기 (Swift의 dismiss)
        print('$title 클릭됨');
      },
      borderRadius: BorderRadius.circular(20), // 클릭 피드백 범위
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
