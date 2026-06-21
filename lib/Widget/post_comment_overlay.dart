// ignore_for_file: avoid_init_to_null

import 'package:flutter/material.dart';
import 'package:bababam_app/Helper/ui_presets.dart';

class PostCommentOverlay extends StatelessWidget {
  const PostCommentOverlay.editable({
    super.key,
    required this.hourText,
    required this.controller,
    this.autofocusDelay = Duration.zero,
    this.hourOverlaySpec,
    this.hourTextColor = Colors.white,
    this.styleSelection = AppTypography.defaultPostTextStyleSelection,
    this.comment = null,
    this.isEditable = true,
    this.emptyAssetPath = null,
    this.emptyAssetSize = 50,
    this.emptyAssetOpacity = 0.6,
    this.showEmptyIndicator = false,
  });

  const PostCommentOverlay.readOnly({
    super.key,
    required this.hourText,
    required this.comment,
    this.hourOverlaySpec,
    this.hourTextColor = Colors.white,
    this.styleSelection = AppTypography.defaultPostTextStyleSelection,
    this.controller = null,
    this.autofocusDelay = Duration.zero,
    this.isEditable = false,
    this.emptyAssetPath = null,
    this.emptyAssetSize = 50,
    this.emptyAssetOpacity = 0.6,
    this.showEmptyIndicator = false,
  });

  const PostCommentOverlay.empty({
    super.key,
    required this.hourText,
    this.hourOverlaySpec,
    this.hourTextColor = Colors.white10,
    this.emptyAssetPath = null,
    this.emptyAssetSize = 36,
    this.emptyAssetOpacity = 0.6,
    this.showEmptyIndicator = true,
    this.controller = null,
    this.autofocusDelay = Duration.zero,
    this.comment = null,
    this.isEditable = false,
    this.styleSelection = AppTypography.defaultPostTextStyleSelection,
  });

  final String hourText;
  final GroupHourOverlaySpec? hourOverlaySpec;
  final Color hourTextColor;
  final TextEditingController? controller;
  final Duration autofocusDelay;
  final String? comment;
  final bool isEditable;
  final PostTextStyleSelection styleSelection;
  final String? emptyAssetPath;
  final double emptyAssetSize;
  final double emptyAssetOpacity;
  final bool showEmptyIndicator;

  @override
  Widget build(BuildContext context) {
    return Center(child: _buildTimeComment());
  }

  Widget _buildTimeComment() {
    final overlaySpec = hourOverlaySpec;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          hourText,
          style: AppTypography.hourOverlay(
            color: hourTextColor,
            fontSize:
                overlaySpec?.fontSize ?? AppTypography.defaultHourFontSize,
            lineHeight:
                overlaySpec?.lineHeight ?? AppTypography.defaultHourLineHeight,
            fontId: overlaySpec?.fontId ?? AppTypography.defaultHourFontId,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (isEditable) return _buildTextField();
    if (emptyAssetPath != null) return _buildEmptyAsset();
    if (showEmptyIndicator) return _buildEmptyIndicator();
    return _buildCommentLabel();
  }

  Widget _buildTextField() {
    if (autofocusDelay > Duration.zero) {
      return _DelayedAutofocusTextField(
        controller: controller,
        delay: autofocusDelay,
        styleSelection: styleSelection,
      );
    }

    return TextField(
      controller: controller,
      autofocus: true,
      showCursor: true,
      cursorColor: Colors.white,
      cursorHeight: 24,
      cursorWidth: 2,
      style: AppTypography.postCommentOverlay(selection: styleSelection),
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

  Widget _buildEmptyAsset() {
    return Opacity(
      opacity: emptyAssetOpacity,
      child: Image.asset(
        emptyAssetPath!,
        width: emptyAssetSize,
        height: emptyAssetSize,
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(width: emptyAssetSize, height: emptyAssetSize);
        },
      ),
    );
  }

  Widget _buildEmptyIndicator() {
    return Opacity(
      opacity: emptyAssetOpacity,
      child: SizedBox(
        width: emptyAssetSize,
        height: emptyAssetSize,
        child: const FittedBox(
          fit: BoxFit.contain,
          child: Text('💤', style: TextStyle(fontSize: 32)),
        ),
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

class _DelayedAutofocusTextField extends StatefulWidget {
  const _DelayedAutofocusTextField({
    required this.controller,
    required this.delay,
    required this.styleSelection,
  });

  final TextEditingController? controller;
  final Duration delay;
  final PostTextStyleSelection styleSelection;

  @override
  State<_DelayedAutofocusTextField> createState() =>
      _DelayedAutofocusTextFieldState();
}

class _DelayedAutofocusTextFieldState
    extends State<_DelayedAutofocusTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(widget.delay, () {
        if (!mounted) return;
        _focusNode.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      autofocus: false,
      showCursor: true,
      cursorColor: Colors.white,
      cursorHeight: 24,
      cursorWidth: 2,
      style: AppTypography.postCommentOverlay(selection: widget.styleSelection),
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
}
