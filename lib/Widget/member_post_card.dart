import 'package:flutter/material.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Model/app_user.dart';
import 'package:bababam_app/Helper/ui_presets.dart';
import 'package:bababam_app/Widget/video_player.dart';

class MemberPostCard extends StatefulWidget {
  final AppUser member;
  final Post? post;
  final int hourSlot;
  final double videoAspectRatio;
  final double cardRadius;
  final double cardOuterMargin;
  final CachedVideoPlayerPlusController? externalVideoController;

  const MemberPostCard({
    super.key,
    required this.member,
    required this.hourSlot,
    this.videoAspectRatio = 4 / 3,
    this.cardRadius = 24,
    this.cardOuterMargin = 4,
    this.externalVideoController,
    this.post,
  });

  @override
  State<MemberPostCard> createState() => _MemberPostCardState();
}

class _MemberPostCardState extends State<MemberPostCard> {
  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    final Color timeTextColor = post == null ? Colors.white10 : Colors.white;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(widget.cardOuterMargin),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(widget.cardRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.cardRadius),
        child: Stack(
          children: [
            if (post != null)
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    children: [
                      //MARK: Video Url
                      Positioned.fill(
                        child: VideoPlayerWidget(
                          key: ValueKey(post.videoUrl), // <- 이 줄을 추가해 줍니다!
                          videoUrl: post.videoUrl,
                          externalController: widget.externalVideoController,
                        ),
                      ),
                      const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white24,
                          size: 50,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.hourSlot}:00',
                    style: AppTypography.hourOverlay(
                      color: timeTextColor,
                      fontSize: 40,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (post != null && post.comment.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        post.comment,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            //MARK: Profil image
            Positioned(
              top: 15,
              left: 15,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[700],
                    radius: 15,
                    backgroundImage: widget.member.profileUrl != null
                        ? NetworkImage(widget.member.profileUrl!)
                        : null,
                    child: widget.member.profileUrl == null
                        ? Text(
                            widget.member.name[0],
                            style: TextStyle(fontSize: 10),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  //MARK: MemberName
                  Text(
                    widget.member.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
