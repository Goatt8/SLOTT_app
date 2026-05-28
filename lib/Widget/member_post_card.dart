import 'package:flutter/material.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:bababam_app/Helper/ui_presets.dart';
import 'package:bababam_app/Model/post.dart';
import 'package:bababam_app/Model/app_user.dart';
import 'package:bababam_app/Widget/post_comment_overlay.dart';
import 'package:bababam_app/Widget/post_text_style_picker_dialog.dart';
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
  final GlobalKey _editButtonKey = GlobalKey();
  PostTextStyleSelection _textStyleSelection =
      AppTypography.defaultPostTextStyleSelection;
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

  Future<void> _showEditOptions() async {
    final buttonContext = _editButtonKey.currentContext;
    final buttonBox = buttonContext?.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonOffset =
        buttonBox?.localToGlobal(Offset.zero, ancestor: overlayBox) ??
        Offset(overlayBox.size.width - 72, overlayBox.size.height - 72);

    const menuWidth = 168.0;
    const menuHeight = 105.0;
    final menuLeft = (buttonOffset.dx - menuWidth + 44)
        .clamp(12.0, overlayBox.size.width - menuWidth - 12)
        .toDouble();
    final menuTop = (buttonOffset.dy - menuHeight - 8)
        .clamp(12.0, overlayBox.size.height - menuHeight - 12)
        .toDouble();

    final action = await showGeneralDialog<_PostEditAction>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              left: menuLeft,
              top: menuTop,
              child: _EditOptionsPopup(
                width: menuWidth,
                onTextTap: () {
                  Navigator.of(dialogContext).pop(_PostEditAction.text);
                },
                onStyleTap: () {
                  Navigator.of(dialogContext).pop(_PostEditAction.style);
                },
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _PostEditAction.text:
        _startEditingComment();
      case _PostEditAction.style:
        await _showTextStylePicker();
    }
  }

  Future<void> _showTextStylePicker() async {
    final selection = await showDialog<PostTextStyleSelection>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.08),
      builder: (context) {
        return PostTextStylePickerDialog(initialSelection: _textStyleSelection);
      },
    );

    if (!mounted || selection == null) return;

    setState(() {
      _textStyleSelection = selection;
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
                      Positioned.fill(
                        child: VideoPlayerWidget(
                          key: ValueKey(post.videoUrl),
                          videoUrl: post.videoUrl,
                          externalController: widget.externalVideoController,
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
                      styleSelection: _textStyleSelection,
                    )
                  : PostCommentOverlay.readOnly(
                      hourText: '${widget.hourSlot}:00',
                      comment: post?.comment ?? '',
                      hourTextColor: timeTextColor,
                      styleSelection: _textStyleSelection,
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
                    : _buildEditCommentButton(
                        _showEditOptions,
                        key: _editButtonKey,
                      ),
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

  Widget _buildEditCommentButton(VoidCallback onPressed, {Key? key}) {
    return IconButton(
      key: key,
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

enum _PostEditAction { text, style }

class _EditOptionsPopup extends StatelessWidget {
  const _EditOptionsPopup({
    required this.width,
    required this.onTextTap,
    required this.onStyleTap,
  });

  final double width;
  final VoidCallback onTextTap;
  final VoidCallback onStyleTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xCC242428),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EditOptionTile(
              icon: Icons.text_fields,
              label: '텍스트',
              onTap: onTextTap,
            ),
            Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
              indent: 12,
              endIndent: 12,
            ),
            _EditOptionTile(
              icon: Icons.style,
              label: '폰트 스타일',
              onTap: onStyleTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditOptionTile extends StatelessWidget {
  const _EditOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.92), size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
