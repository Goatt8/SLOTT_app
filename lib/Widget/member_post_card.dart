import 'package:flutter/material.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Model/app_user.dart';
import 'package:bababam_app/Widget/post_comment_overlay.dart';
import 'package:bababam_app/Widget/video_player.dart';

class MemberPostCard extends StatefulWidget {
  final AppUser member;
  final Post? post;
  final int hourSlot;
  final double videoAspectRatio;
  final double cardRadius;
  final double cardOuterMargin;
  final CachedVideoPlayerPlusController? externalVideoController;
  final Future<void> Function(String comment)? onSaveComment;

  const MemberPostCard({
    super.key,
    required this.member,
    required this.hourSlot,
    this.videoAspectRatio = 4 / 3,
    this.cardRadius = 24,
    this.cardOuterMargin = 4,
    this.externalVideoController,
    this.onSaveComment,
    this.post,
  });

  @override
  State<MemberPostCard> createState() => _MemberPostCardState();
}

class _MemberPostCardState extends State<MemberPostCard> {
  late final TextEditingController _commentController;
  bool _isEditingComment = false;
  bool _isSavingComment = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(
      text: widget.post?.comment ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant MemberPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isEditingComment && oldWidget.post?.comment != widget.post?.comment) {
      _commentController.text = widget.post?.comment ?? '';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _startEditingComment() {
    _commentController.text = widget.post?.comment ?? '';
    setState(() {
      _isEditingComment = true;
    });
  }

  Future<void> _saveEditingComment() async {
    if (_isSavingComment) return;

    final updatedComment = _commentController.text.trim();
    if (updatedComment == widget.post?.comment) {
      setState(() {
        _isEditingComment = false;
      });
      return;
    }

    setState(() {
      _isSavingComment = true;
    });

    try {
      await widget.onSaveComment?.call(updatedComment);
      if (!mounted) return;
      setState(() {
        _isEditingComment = false;
      });
    } catch (_) {
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isSavingComment = false;
        });
      }
    }
  }

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
            //MARK: IsEditing switch
            Positioned.fill(
              child: _isEditingComment
                  ? PostCommentOverlay.editable(
                      hourText: '${widget.hourSlot}:00',
                      controller: _commentController,
                    )
                  : PostCommentOverlay.readOnly(
                      hourText: '${widget.hourSlot}:00',
                      comment: post?.comment ?? '',
                      hourTextColor: timeTextColor,
                    ),
            ),
            if (!_isEditingComment)
              Positioned(top: 15, left: 15, child: _buildProfile()),
            if (post != null && widget.onSaveComment != null)
              Positioned(
                right: 14,
                bottom: 14,
                child: _isEditingComment
                    ? _buildCompleteCommentButton()
                    : _buildEditCommentButton(_startEditingComment),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    return Row(
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
                  style: const TextStyle(fontSize: 10),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          widget.member.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
          ),
        ),
      ],
    );
  }

  Widget _buildEditCommentButton(VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      tooltip: '텍스트 수정',
      icon: const Icon(Icons.edit, color: Colors.white, size: 22),
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildCompleteCommentButton() {
    return IconButton(
      onPressed: _isSavingComment ? null : _saveEditingComment,
      tooltip: '텍스트 저장',
      icon: _isSavingComment
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.check, color: Colors.white, size: 24),
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
