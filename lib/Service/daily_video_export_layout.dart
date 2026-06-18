import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:bababam_app/Helper/ui_presets.dart';

class DailyVideoExportLayoutBuilder {
  const DailyVideoExportLayoutBuilder();

  static const Size renderSize = Size(1080, 1920);
  static const double _screenDesignWidth = 390;

  double get _scale => renderSize.width / _screenDesignWidth;

  List<Map<String, Object?>> buildPages({
    required int slotCount,
    required bool useDiceLayout,
    required PostTextStyleSelection textStyleSelection,
    required List<Map<String, Object?>> pages,
  }) {
    final preset = AppLayoutPolicy.presetFor(
      memberCount: slotCount,
      useDiceLayout: useDiceLayout,
    );
    final rects = _buildSlotRects(slotCount: slotCount, preset: preset);

    return pages.map((page) {
      final hour = page['hour'] as int;
      final slots = page['slots'] as List<Map<String, Object?>>;

      return {
        'hour': hour,
        'slots': slots.map((slot) {
          final slotIndex = slot['slotIndex'] as int;
          final rect = rects[slotIndex];
          final hasVideo = (slot['videoPath'] as String?)?.isNotEmpty == true;
          final textSpecs = _buildTextSpecs(
            rect: rect,
            hour: hour,
            hasVideo: hasVideo,
            comment: slot['comment'] as String? ?? '',
            preset: preset,
            textStyleSelection: textStyleSelection,
          );

          return {
            ...slot,
            'videoRect': _rectToMap(rect),
            'hourText': textSpecs.hourText,
            'hourRect': _rectToMap(textSpecs.hourRect),
            'hourFontId': textStyleSelection.hourFontId,
            'hourFontSize': textSpecs.hourFontSize,
            'hourColor': _colorToArgb(textSpecs.hourColor),
            'commentText': textSpecs.commentText,
            'commentRect': _rectToMap(textSpecs.commentRect),
            'commentFontId': textStyleSelection.fontId,
            'commentFontSize': textSpecs.commentFontSize,
            'commentColor': _colorToArgb(textSpecs.commentColor),
            'maxCommentLines': textSpecs.maxCommentLines,
          };
        }).toList(),
      };
    }).toList();
  }

  List<Rect> _buildSlotRects({
    required int slotCount,
    required GroupUiPreset preset,
  }) {
    final layoutSpec = preset.layoutSpec;

    if (!layoutSpec.useGrid) {
      final margin = preset.cardOuterMargin * _scale;
      final slotHeight = renderSize.height / slotCount;
      return List.generate(slotCount, (index) {
        return Rect.fromLTWH(
          margin,
          slotHeight * index + margin,
          renderSize.width - margin * 2,
          slotHeight - margin * 2,
        );
      });
    }

    final gridSlotCount = layoutSpec.fixedSlotCount ?? slotCount;
    final columns = layoutSpec.crossAxisCount;
    final rows = (gridSlotCount / columns).ceil();
    final horizontalPadding = preset.gridHorizontalPadding * _scale;
    final verticalPadding = preset.gridVerticalPadding * _scale;
    final spacing = preset.gridSpacing * _scale;
    final tileWidth =
        (renderSize.width - horizontalPadding * 2 - spacing * (columns - 1)) /
        columns;
    final tileHeight =
        (renderSize.height - verticalPadding * 2 - spacing * (rows - 1)) / rows;

    return List.generate(slotCount, (index) {
      final row = index ~/ columns;
      final column = index % columns;
      return Rect.fromLTWH(
        horizontalPadding + column * (tileWidth + spacing),
        verticalPadding + row * (tileHeight + spacing),
        tileWidth,
        tileHeight,
      );
    });
  }

  _DailyVideoSlotTextSpecs _buildTextSpecs({
    required Rect rect,
    required int hour,
    required bool hasVideo,
    required String comment,
    required GroupUiPreset preset,
    required PostTextStyleSelection textStyleSelection,
  }) {
    final hourSpec = preset.hourOverlaySpec.copyWith(
      fontId: textStyleSelection.hourFontId,
    );
    final postFontPreset = AppTypography.postFontPreset(
      textStyleSelection.fontId,
    );
    final hourFontPreset = AppTypography.hourFontPreset(
      textStyleSelection.hourFontId,
    );

    final hourFontSize =
        hourSpec.fontSize * hourFontPreset.fontSizeScale * _scale;
    final commentFontSize = 20 * postFontPreset.fontSizeScale * _scale;
    final commentText = hasVideo ? comment.trim() : 'Zzz';
    final commentLines = hasVideo ? 2 : 1;
    final hourHeight = hourFontSize * hourSpec.lineHeight;
    final commentHeight = commentFontSize * commentLines * 1.15;
    final totalHeight = hourHeight + commentHeight;
    final top = rect.center.dy - totalHeight / 2;
    final horizontalPadding = 40 * _scale;

    return _DailyVideoSlotTextSpecs(
      hourText: '$hour:00',
      hourRect: Rect.fromLTWH(rect.left, top, rect.width, hourHeight),
      hourFontSize: hourFontSize,
      hourColor: hasVideo ? hourSpec.activeColor : hourSpec.emptyColor,
      commentText: commentText,
      commentRect: Rect.fromLTWH(
        rect.left + horizontalPadding,
        top + hourHeight,
        rect.width - horizontalPadding * 2,
        commentHeight,
      ),
      commentFontSize: commentFontSize,
      commentColor: hasVideo
          ? AppTypography.postTextColor(textStyleSelection)
          : const Color(0xDD1F78DB),
      maxCommentLines: commentLines,
    );
  }

  Map<String, double> _rectToMap(Rect rect) {
    return {
      'x': rect.left,
      'y': rect.top,
      'width': rect.width,
      'height': rect.height,
    };
  }

  int _colorToArgb(Color color) {
    final a = (color.a * 255).round() & 0xff;
    final r = (color.r * 255).round() & 0xff;
    final g = (color.g * 255).round() & 0xff;
    final b = (color.b * 255).round() & 0xff;
    return (a << 24) | (r << 16) | (g << 8) | b;
  }
}

class _DailyVideoSlotTextSpecs {
  const _DailyVideoSlotTextSpecs({
    required this.hourText,
    required this.hourRect,
    required this.hourFontSize,
    required this.hourColor,
    required this.commentText,
    required this.commentRect,
    required this.commentFontSize,
    required this.commentColor,
    required this.maxCommentLines,
  });

  final String hourText;
  final Rect hourRect;
  final double hourFontSize;
  final Color hourColor;
  final String commentText;
  final Rect commentRect;
  final double commentFontSize;
  final Color commentColor;
  final int maxCommentLines;
}
