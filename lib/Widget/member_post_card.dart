import 'package:flutter/material.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Model/user.dart';

class MemberPostCard extends StatefulWidget {
  final User member;
  final Post? post;
  final int hourSlot;

  const MemberPostCard({
    super.key,
    required this.member,
    required this.hourSlot,
    this.post,
  });

  @override
  State<MemberPostCard> createState() => _MemberPostCardState();
}

class _MemberPostCardState extends State<MemberPostCard> {
  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Container(
      width: double.infinity,
      height: 450,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.hourSlot}:00',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  post?.comment ?? '아직 이 시간대 포스트가 없어요',
                  style: TextStyle(
                    color: post == null ? Colors.white54 : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
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
