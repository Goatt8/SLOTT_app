import 'package:flutter/material.dart';
import 'package:bababam_app/Helper/ui_presets.dart';

class PostCommentOverlay extends StatelessWidget {
  const PostCommentOverlay.editable({
    super.key,
    required this.hourText,
    required this.controller,
    this.hourTextColor = Colors.white,
    this.styleSelection = AppTypography.defaultPostTextStyleSelection,
  }) : comment = null,
       isEditable = true;

  const PostCommentOverlay.readOnly({
    super.key,
    required this.hourText,
    required this.comment,
    this.hourTextColor = Colors.white,
    this.styleSelection = AppTypography.defaultPostTextStyleSelection,
  }) : controller = null,
       isEditable = false;

  final String hourText;
  final Color hourTextColor;
  final TextEditingController? controller;
  final String? comment;
  final bool isEditable;
  final PostTextStyleSelection styleSelection;

  @override
  Widget build(BuildContext context) {
    return Center(child: _buildTimeComment());
  }

  Widget _buildTimeComment() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          hourText,
          style: AppTypography.hourOverlay(
            color: hourTextColor,
            fontSize: 40,
          ).copyWith(height: AppTypography.postOverlayHourLineHeight),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: isEditable ? _buildTextField() : _buildCommentLabel(),
        ),
      ],
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: controller,
      autofocus: true,
      showCursor: true,
      cursorColor: Colors.white,
      cursorHeight: 24,
      cursorWidth: 2,
      style: AppTypography.postCommentOverlay(
        selection: styleSelection,
      ),
      maxLines: null,
      textAlign: TextAlign.center,
      maxLength: 50,
      decoration: const InputDecoration(
        counterText: "",
        filled: false,
        border: InputBorder.none,
        isCollapsed: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildCommentLabel() {
    final text = comment?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    final textWidget = Text(
      text,
      style: AppTypography.postCommentOverlay(selection: styleSelection),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );

    final gradient = AppTypography.postTextGradient(styleSelection);
    if (gradient == null) return textWidget;

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: textWidget,
    );
  }
}
