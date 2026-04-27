import 'package:flutter/material.dart';
import 'package:bababam_app/Model/user.dart';

class MemberPostCard extends StatefulWidget {
  final User member;

  const MemberPostCard({super.key, required this.member});

  @override
  State<MemberPostCard> createState() => _MemberPostCardState();
}

class _MemberPostCardState extends State<MemberPostCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 450,
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(
              Icons.play_circle_outline,
              color: Colors.white,
              size: 50,
            ),
          ),

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
