import 'package:flutter/material.dart';
import 'package:bababam_app/Model/user.dart';

class MemberPostCard extends StatefulWidget {
  final User member;
  // final Post? post; // 나중에 포스트 데이터도 받을 예정

  const MemberPostCard({super.key, required this.member});

  @override
  State<MemberPostCard> createState() => _MemberPostCardState();
}

class _MemberPostCardState extends State<MemberPostCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 450, // 혹은 AspectRatio 사용
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // 1. 영상 레이어 (나중에 추가)
          const Center(
            child: Icon(
              Icons.play_circle_outline,
              color: Colors.white,
              size: 50,
            ),
          ),

          // 2. 정보 레이어 (이름, 프로필 등)
          Positioned(
            top: 15,
            left: 15,
            child: Row(
              children: [
                CircleAvatar(backgroundColor: Colors.grey[700], radius: 15),
                const SizedBox(width: 8),
                Text(
                  widget.member.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
