import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PostFontPreset {
  const PostFontPreset({
    required this.id,
    required this.label,
    required this.fontFamily,
    this.fontSizeScale = 1,
  });

  final String id;
  final String label;
  final String fontFamily;
  final double fontSizeScale;
}

class HourFontPreset {
  const HourFontPreset({
    required this.id,
    required this.label,
    required this.fontFamily,
    this.fontSizeScale = 1,
  });

  final String id;
  final String label;
  final String fontFamily;
  final double fontSizeScale;
}

class PostColorPreset {
  const PostColorPreset({required this.id, required this.colors});

  final String id;
  final List<Color> colors;
}

class PostTextStyleSelection {
  const PostTextStyleSelection({
    required this.fontId,
    required this.colorId,
    required this.hourFontId,
  });

  final String fontId;
  final String colorId;
  final String hourFontId;

  PostTextStyleSelection copyWith({
    String? fontId,
    String? colorId,
    String? hourFontId,
  }) {
    return PostTextStyleSelection(
      fontId: fontId ?? this.fontId,
      colorId: colorId ?? this.colorId,
      hourFontId: hourFontId ?? this.hourFontId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PostTextStyleSelection &&
        other.fontId == fontId &&
        other.colorId == colorId &&
        other.hourFontId == hourFontId;
  }

  @override
  int get hashCode => Object.hash(fontId, colorId, hourFontId);
}

class AppTypography {
  static const String defaultPostFontId = 'doHyeon';
  static const String defaultPostColorId = 'white';
  static const String defaultHourFontId = 'doHyeon';
  static const double defaultHourFontSize = 32;
  static const double defaultHourLineHeight = 0.95;
  static const Color defaultHourActiveColor = Colors.white;
  static const Color defaultHourEmptyColor = Colors.white10;
  static const PostTextStyleSelection defaultPostTextStyleSelection =
      PostTextStyleSelection(
        fontId: defaultPostFontId,
        colorId: defaultPostColorId,
        hourFontId: defaultHourFontId,
      );

  static const List<PostFontPreset> postFontPresets = [
    PostFontPreset(id: 'doHyeon', label: 'basic', fontFamily: 'Do Hyeon'),
    PostFontPreset(
      id: 'blacHanSans',
      label: 'bold',
      fontFamily: 'Black Han Sans',
    ),
    PostFontPreset(
      id: 'bagelfatOne',
      label: 'bagel',
      fontFamily: 'Bagel Fat One',
    ),
    PostFontPreset(
      id: 'nanumPenScript',
      label: 'hand',
      fontFamily: 'Nanum Pen Script',
      fontSizeScale: 1.22,
    ),
    PostFontPreset(
      id: 'silkscreen',
      label: 'Pixel',
      fontFamily: 'Silkscreen',
      fontSizeScale: 0.78,
    ),
    PostFontPreset(id: 'blackOpsOne', label: 'SF', fontFamily: 'Black Ops One'),
    PostFontPreset(
      id: 'noto serif kr',
      label: 'city',
      fontFamily: 'Noto Serif KR',
    ),
    PostFontPreset(
      id: 'gowunBatang',
      label: 'classic',
      fontFamily: 'Gowun Batang',
    ),
  ];

  static const List<HourFontPreset> hourFontPresets = [
    HourFontPreset(id: 'doHyeon', label: 'basic', fontFamily: 'Do Hyeon'),
    HourFontPreset(
      id: 'blacHanSans',
      label: 'bold',
      fontFamily: 'Black Han Sans',
    ),
    HourFontPreset(
      id: 'bagelfatOne',
      label: 'bagel',
      fontFamily: 'Bagel Fat One',
    ),
    HourFontPreset(id: 'fredoka', label: 'cute', fontFamily: 'Fredoka'),
    HourFontPreset(
      id: 'PressStart2P',
      label: 'pixel',
      fontFamily: 'Press Start 2P',
      fontSizeScale: 0.82,
    ),
    HourFontPreset(id: 'orbitron', label: 'SF', fontFamily: 'Orbitron'),
    HourFontPreset(
      id: 'playfairDisplay',
      label: 'city',
      fontFamily: 'Playfair Display',
    ),
    HourFontPreset(id: 'cinzel', label: 'classic', fontFamily: 'Cinzel'),
  ];

  static const List<PostColorPreset> postColorPresets = [
    PostColorPreset(id: 'white', colors: [Colors.white]),
    PostColorPreset(id: 'black', colors: [Colors.black]),
    PostColorPreset(id: 'mint', colors: [Color(0xFF48D6A2), Color(0xFF7CE6F0)]),
    PostColorPreset(id: 'pink', colors: [Color(0xFFFFB3C7), Color(0xFFE86BD5)]),
    PostColorPreset(
      id: 'sunset',
      colors: [Color(0xFFFFA142), Color(0xFFE64BDB)],
    ),
    PostColorPreset(id: 'blue', colors: [Color(0xFFB667FF), Color(0xFF2F8CFF)]),
    PostColorPreset(
      id: 'green',
      colors: [Color(0xFF8A43D3), Color(0xFF36D893)],
    ),
    PostColorPreset(
      id: 'mid Night',
      colors: [
        Color(0xFF443199),
        Color(0xFF792CA2),
        Color(0xFFC13383),
        Color(0xFFE05454),
      ],
    ),
  ];

  static TextStyle hourOverlay({
    Color color = Colors.white,
    double fontSize = defaultHourFontSize,
    double lineHeight = defaultHourLineHeight,
    String fontId = defaultHourFontId,
  }) {
    final preset = hourFontPreset(fontId);

    return GoogleFonts.getFont(
      preset.fontFamily,
      color: color,
      fontSize: fontSize * preset.fontSizeScale,
      fontWeight: FontWeight.w800,
      height: lineHeight,
    );
  }

  static HourFontPreset hourFontPreset(String id) {
    return hourFontPresets.firstWhere(
      (preset) => preset.id == id,
      orElse: () => hourFontPresets.first,
    );
  }

  static TextStyle postCommentOverlay({
    PostTextStyleSelection selection = defaultPostTextStyleSelection,
    double fontSize = 20,
  }) {
    final color = postTextColor(selection);
    final preset = postFontPreset(selection.fontId);

    return GoogleFonts.getFont(
      preset.fontFamily,
      fontSize: fontSize * preset.fontSizeScale,
      fontWeight: FontWeight.w700,
      height: 1,
      color: color,
    );
  }

  static PostFontPreset postFontPreset(String id) {
    return postFontPresets.firstWhere(
      (preset) => preset.id == id,
      orElse: () => postFontPresets.first,
    );
  }

  static PostTextStyleSelection postTextStyleSelection({
    String? fontId,
    String? colorId,
    String? hourFontId,
  }) {
    return PostTextStyleSelection(
      fontId: postFontPreset(fontId ?? defaultPostFontId).id,
      colorId: postColorPreset(colorId ?? defaultPostColorId).id,
      hourFontId: hourFontPreset(hourFontId ?? defaultHourFontId).id,
    );
  }

  static String postFontLabel(String? fontId) {
    return postFontPreset(fontId ?? defaultPostFontId).label;
  }

  static PostColorPreset postColorPreset(String id) {
    return postColorPresets.firstWhere(
      (preset) => preset.id == id,
      orElse: () => postColorPresets.first,
    );
  }

  static String postColorLabel(String? colorId) {
    return postColorPreset(colorId ?? defaultPostColorId).id;
  }

  static String hourFontLabel(String? hourFontId) {
    return hourFontPreset(hourFontId ?? defaultHourFontId).label;
  }

  static Color postTextColor(PostTextStyleSelection selection) {
    final colors = postColorPreset(selection.colorId).colors;
    return colors.first;
  }

  static LinearGradient? postTextGradient(PostTextStyleSelection selection) {
    final colors = postColorPreset(selection.colorId).colors;
    if (colors.length < 2) return null;
    return LinearGradient(colors: colors);
  }

  static TextStyle brandTitle({double fontSize = 20}) {
    return GoogleFonts.londrinaSolid(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
    );
  }
}

class AppAccentColor {
  static const Color defaultColor = Color(0xFF7C3AED);

  static Color fromColorId(String? colorId) {
    if (colorId == null ||
        colorId == AppTypography.defaultPostColorId ||
        colorId == 'black') {
      return defaultColor;
    }

    return AppTypography.postColorPreset(colorId).colors.first;
  }
}

class GroupVideoLayoutSpec {
  const GroupVideoLayoutSpec({
    required this.useGrid,
    required this.crossAxisCount,
    required this.gridChildAspectRatio,
    required this.videoAspectRatio,
    required this.compactVerticalCards,
    this.fixedSlotCount,
  });

  final bool useGrid;
  final int crossAxisCount;
  final double gridChildAspectRatio;
  final double videoAspectRatio;
  final bool compactVerticalCards;
  final int? fixedSlotCount;
}

class GroupHourOverlaySpec {
  const GroupHourOverlaySpec({
    required this.fontId,
    required this.fontSize,
    required this.lineHeight,
    required this.activeColor,
    required this.emptyColor,
  });

  final String fontId;
  final double fontSize;
  final double lineHeight;
  final Color activeColor;
  final Color emptyColor;

  GroupHourOverlaySpec copyWith({
    String? fontId,
    double? fontSize,
    double? lineHeight,
    Color? activeColor,
    Color? emptyColor,
  }) {
    return GroupHourOverlaySpec(
      fontId: fontId ?? this.fontId,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      activeColor: activeColor ?? this.activeColor,
      emptyColor: emptyColor ?? this.emptyColor,
    );
  }
}

class GroupUiPreset {
  const GroupUiPreset({
    required this.layoutSpec,
    required this.hourOverlaySpec,
    required this.cardRadius,
    required this.cardOuterMargin,
    required this.gridHorizontalPadding,
    required this.gridVerticalPadding,
    required this.gridSpacing,
    required this.fillGridViewport,
  });

  final GroupVideoLayoutSpec layoutSpec;
  final GroupHourOverlaySpec hourOverlaySpec;
  final double cardRadius;
  final double cardOuterMargin;
  final double gridHorizontalPadding;
  final double gridVerticalPadding;
  final double gridSpacing;
  final bool fillGridViewport;
}

class AppLayoutPolicy {
  static const double previewVideoAspectRatio = 16 / 9;
  static const double diceVideoAspectRatio = 9 / 16;

  static bool supportsVerticalLayout(int memberCount) {
    return memberCount == 2 ||
        memberCount == 3 ||
        memberCount == 4 ||
        memberCount == 5 ||
        memberCount == 6;
  }

  static bool supportsDiceLayout(int memberCount) {
    return memberCount == 3 ||
        memberCount == 4 ||
        memberCount == 6 ||
        memberCount == 7 ||
        memberCount == 8 ||
        memberCount == 9 ||
        memberCount == 10;
  }

  static bool isDiceOnlyMemberCount(int memberCount) {
    return memberCount == 7 ||
        memberCount == 8 ||
        memberCount == 9 ||
        memberCount == 10;
  }

  static GroupVideoLayoutSpec verticalSpecByMemberCount(int memberCount) {
    if (memberCount == 2) {
      return const GroupVideoLayoutSpec(
        useGrid: false,
        crossAxisCount: 1,
        gridChildAspectRatio: 1,
        videoAspectRatio: previewVideoAspectRatio,
        compactVerticalCards: true,
      );
    }

    return const GroupVideoLayoutSpec(
      useGrid: false,
      crossAxisCount: 1,
      gridChildAspectRatio: 1,
      videoAspectRatio: previewVideoAspectRatio,
      compactVerticalCards: false,
    );
  }

  static GroupVideoLayoutSpec diceSpecByMemberCount(int memberCount) {
    if (memberCount == 3 || memberCount == 4) {
      return const GroupVideoLayoutSpec(
        useGrid: true,
        crossAxisCount: 2,
        gridChildAspectRatio: diceVideoAspectRatio,
        videoAspectRatio: diceVideoAspectRatio,
        compactVerticalCards: false,
        fixedSlotCount: 4,
      );
    }

    if (memberCount == 6) {
      return const GroupVideoLayoutSpec(
        useGrid: true,
        crossAxisCount: 2,
        gridChildAspectRatio: diceVideoAspectRatio,
        videoAspectRatio: diceVideoAspectRatio,
        compactVerticalCards: false,
        fixedSlotCount: 6,
      );
    }

    if (memberCount == 7 || memberCount == 8) {
      return const GroupVideoLayoutSpec(
        useGrid: true,
        crossAxisCount: 2,
        gridChildAspectRatio: diceVideoAspectRatio,
        videoAspectRatio: diceVideoAspectRatio,
        compactVerticalCards: false,
        fixedSlotCount: 8,
      );
    }

    if (memberCount == 9) {
      return const GroupVideoLayoutSpec(
        useGrid: true,
        crossAxisCount: 3,
        gridChildAspectRatio: diceVideoAspectRatio,
        videoAspectRatio: diceVideoAspectRatio,
        compactVerticalCards: false,
        fixedSlotCount: 9,
      );
    }

    return const GroupVideoLayoutSpec(
      useGrid: true,
      crossAxisCount: 3,
      gridChildAspectRatio: diceVideoAspectRatio,
      videoAspectRatio: diceVideoAspectRatio,
      compactVerticalCards: false,
      fixedSlotCount: 12,
    );
  }

  static GroupUiPreset presetFor({
    required int memberCount,
    required bool useDiceLayout,
  }) {
    final bool allowDice = supportsDiceLayout(memberCount);
    final bool allowVertical = supportsVerticalLayout(memberCount);
    final bool forceDice = isDiceOnlyMemberCount(memberCount);

    final bool willUseDice =
        forceDice ||
        (useDiceLayout && allowDice) ||
        (!allowVertical && allowDice);

    final layoutSpec = willUseDice
        ? diceSpecByMemberCount(memberCount)
        : verticalSpecByMemberCount(memberCount);

    final double radius = willUseDice ? 16 : 24;

    return GroupUiPreset(
      layoutSpec: layoutSpec,
      hourOverlaySpec: const GroupHourOverlaySpec(
        fontId: AppTypography.defaultHourFontId,
        fontSize: AppTypography.defaultHourFontSize,
        lineHeight: AppTypography.defaultHourLineHeight,
        activeColor: AppTypography.defaultHourActiveColor,
        emptyColor: AppTypography.defaultHourEmptyColor,
      ),
      cardRadius: radius,
      cardOuterMargin: willUseDice ? 0 : 1,
      gridHorizontalPadding: 2,
      gridVerticalPadding: 2,
      gridSpacing: 2,
      fillGridViewport: false,
    );
  }
}
