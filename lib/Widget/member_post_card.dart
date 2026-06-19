import 'package:flutter/material.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  final GroupHourOverlaySpec? hourOverlaySpec;
  final CachedVideoPlayerPlusController? externalVideoController;
  final PostTextStyleSelection initialStyleSelection;
  final ValueChanged<PostTextStyleSelection>? onStyleSelectionChanged;
  final bool isAudioEnabled;
  final VoidCallback? onToggleAudio;
  final Future<void> Function(String comment)? onSaveComment;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;

  const MemberPostCard({
    super.key,
    required this.member,
    required this.hourSlot,
    this.videoAspectRatio = 4 / 3,
    this.cardRadius = 24,
    this.cardOuterMargin = 4,
    this.hourOverlaySpec,
    this.externalVideoController,
    this.initialStyleSelection = AppTypography.defaultPostTextStyleSelection,
    this.onStyleSelectionChanged,
    this.isAudioEnabled = false,
    this.onToggleAudio,
    this.onSaveComment,
    this.onReport,
    this.onBlock,
    this.post,
  });

  @override
  State<MemberPostCard> createState() => _MemberPostCardState();
}

class _MemberPostCardState extends State<MemberPostCard> {
  late final TextEditingController _commentController;
  final GlobalKey _editButtonKey = GlobalKey();
  final GlobalKey _safetyButtonKey = GlobalKey();
  late PostTextStyleSelection _textStyleSelection;
  bool _isEditingComment = false;
  bool _isSavingComment = false;

  @override
  void initState() {
    super.initState();
    _textStyleSelection = widget.initialStyleSelection;
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

    if (oldWidget.initialStyleSelection != widget.initialStyleSelection) {
      _textStyleSelection = widget.initialStyleSelection;
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

    final hasAudioAction = widget.post != null && widget.onToggleAudio != null;
    const menuWidth = 168.0;
    final menuHeight = hasAudioAction ? 158.0 : 105.0;
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
                audioEnabled: widget.isAudioEnabled,
                onAudioTap: hasAudioAction
                    ? () {
                        Navigator.of(dialogContext).pop(_PostEditAction.audio);
                      }
                    : null,
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
      case _PostEditAction.audio:
        widget.onToggleAudio?.call();
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
    widget.onStyleSelectionChanged?.call(selection);
  }

  Future<void> _showSafetyOptions() async {
    final buttonContext = _safetyButtonKey.currentContext;
    final buttonBox = buttonContext?.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonOffset =
        buttonBox?.localToGlobal(Offset.zero, ancestor: overlayBox) ??
        Offset(overlayBox.size.width - 72, overlayBox.size.height - 72);

    const menuWidth = 190.0;
    final menuHeight = widget.onReport == null ? 54.0 : 109.0;
    final menuLeft = (buttonOffset.dx - menuWidth + 44)
        .clamp(12.0, overlayBox.size.width - menuWidth - 12)
        .toDouble();
    final menuTop = (buttonOffset.dy - menuHeight - 8)
        .clamp(12.0, overlayBox.size.height - menuHeight - 12)
        .toDouble();

    final action = await showGeneralDialog<_SafetyAction>(
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
              child: _SafetyOptionsPopup(
                width: menuWidth,
                showReport: widget.onReport != null,
                onReportTap: () =>
                    Navigator.of(dialogContext).pop(_SafetyAction.report),
                onBlockTap: () =>
                    Navigator.of(dialogContext).pop(_SafetyAction.block),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || action == null) return;
    switch (action) {
      case _SafetyAction.report:
        widget.onReport?.call();
      case _SafetyAction.block:
        widget.onBlock?.call();
    }
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
    final hourOverlaySpec = widget.hourOverlaySpec?.copyWith(
      fontId: _textStyleSelection.hourFontId,
    );

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
                          initializeWhenExternalMissing: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            //MARK: IsEditing switch
            Positioned.fill(
              child: post != null
                  ? (_isEditingComment
                        ? PostCommentOverlay.editable(
                            hourText: '${widget.hourSlot}:00',
                            hourOverlaySpec: hourOverlaySpec,
                            hourTextColor:
                                hourOverlaySpec?.activeColor ?? Colors.white,
                            controller: _commentController,
                            styleSelection: _textStyleSelection,
                          )
                        : PostCommentOverlay.readOnly(
                            hourText: '${widget.hourSlot}:00',
                            hourOverlaySpec: hourOverlaySpec,
                            hourTextColor:
                                hourOverlaySpec?.activeColor ?? Colors.white,
                            comment: post.comment,
                            styleSelection: _textStyleSelection,
                          ))
                  : PostCommentOverlay.empty(
                      hourText: '${widget.hourSlot}:00',
                      hourOverlaySpec: hourOverlaySpec,
                      hourTextColor:
                          hourOverlaySpec?.emptyColor ?? Colors.white10,
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
            if (!_isEditingComment &&
                widget.onSaveComment == null &&
                widget.onBlock != null)
              Positioned(
                right: 14,
                bottom: 14,
                child: IconButton(
                  key: _safetyButtonKey,
                  onPressed: _showSafetyOptions,
                  tooltip: '신고 및 차단',
                  icon: const Icon(
                    Icons.more_horiz,
                    color: Colors.white,
                    size: 26,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
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
              ? CachedNetworkImageProvider(widget.member.profileUrl!)
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
      tooltip: '영상 도구',
      icon: const Icon(Icons.more_horiz, color: Colors.white, size: 26),
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

enum _PostEditAction { text, style, audio }

enum _SafetyAction { report, block }

class _EditOptionsPopup extends StatelessWidget {
  const _EditOptionsPopup({
    required this.width,
    required this.onTextTap,
    required this.onStyleTap,
    required this.audioEnabled,
    this.onAudioTap,
  });

  final double width;
  final VoidCallback onTextTap;
  final VoidCallback onStyleTap;
  final bool audioEnabled;
  final VoidCallback? onAudioTap;

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
              label: '슬롯 채우기',
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
            if (onAudioTap != null) ...[
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.08),
                indent: 12,
                endIndent: 12,
              ),
              _EditOptionTile(
                icon: audioEnabled
                    ? Icons.volume_up_outlined
                    : Icons.volume_off_outlined,
                label: audioEnabled ? '음성 OFF' : '음성 ON',
                onTap: onAudioTap!,
              ),
            ],
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

class _SafetyOptionsPopup extends StatelessWidget {
  const _SafetyOptionsPopup({
    required this.width,
    required this.showReport,
    required this.onReportTap,
    required this.onBlockTap,
  });

  final double width;
  final bool showReport;
  final VoidCallback onReportTap;
  final VoidCallback onBlockTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xEE242428),
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
            if (showReport) ...[
              _EditOptionTile(
                icon: Icons.flag_outlined,
                label: '콘텐츠 신고',
                onTap: onReportTap,
              ),
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.08),
                indent: 12,
                endIndent: 12,
              ),
            ],
            _EditOptionTile(
              icon: Icons.block,
              label: '사용자 차단',
              onTap: onBlockTap,
            ),
          ],
        ),
      ),
    );
  }
}
