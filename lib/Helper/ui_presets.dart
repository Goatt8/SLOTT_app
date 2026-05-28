import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PostFontPreset {
  const PostFontPreset({
    required this.id,
    required this.label,
    required this.fontFamily,
  });

  final String id;
  final String label;
  final String fontFamily;
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
  });

  final String fontId;
  final String colorId;

  PostTextStyleSelection copyWith({
    String? fontId,
    String? colorId,
  }) {
    return PostTextStyleSelection(
      fontId: fontId ?? this.fontId,
      colorId: colorId ?? this.colorId,
    );
  }
}

class AppTypography {
  static const double postOverlayHourLineHeight = 0.95;
  static const PostTextStyleSelection defaultPostTextStyleSelection =
      PostTextStyleSelection(
        fontId: 'londrina',
        colorId: 'white',
      );

  static const List<PostFontPreset> postFontPresets = [
    PostFontPreset(
      id: 'londrina',
      label: 'Londrina',
      fontFamily: 'Londrina Solid',
    ),
    PostFontPreset(id: 'fredoka', label: 'Fredoka', fontFamily: 'Fredoka'),
    PostFontPreset(id: 'gugi', label: 'Gugi', fontFamily: 'Gugi'),
    PostFontPreset(id: 'bagel', label: 'Bagel', fontFamily: 'Bagel Fat One'),
    PostFontPreset(id: 'gaegu', label: 'Gaegu', fontFamily: 'Gaegu'),
    PostFontPreset(id: 'press', label: 'Pixel', fontFamily: 'Press Start 2P'),
    PostFontPreset(
      id: 'blackhan',
      label: 'Black Han',
      fontFamily: 'Black Han Sans',
    ),
    PostFontPreset(id: 'serif', label: 'Serif', fontFamily: 'Noto Serif KR'),
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
  ];

  static TextStyle hourOverlay({
    Color color = Colors.white,
    double fontSize = 40,
  }) {
    return GoogleFonts.londrinaSolid(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
    );
  }

  static TextStyle postCommentOverlay({
    PostTextStyleSelection selection = defaultPostTextStyleSelection,
    double fontSize = 20,
  }) {
    final color = postTextColor(selection);

    return GoogleFonts.getFont(
      postFontPreset(selection.fontId).fontFamily,
      fontSize: fontSize,
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

  static PostColorPreset postColorPreset(String id) {
    return postColorPresets.firstWhere(
      (preset) => preset.id == id,
      orElse: () => postColorPresets.first,
    );
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

class GroupUiPreset {
  const GroupUiPreset({
    required this.layoutSpec,
    required this.cardRadius,
    required this.cardOuterMargin,
    required this.gridHorizontalPadding,
    required this.gridVerticalPadding,
    required this.gridSpacing,
    required this.fillGridViewport,
  });

  final GroupVideoLayoutSpec layoutSpec;
  final double cardRadius;
  final double cardOuterMargin;
  final double gridHorizontalPadding;
  final double gridVerticalPadding;
  final double gridSpacing;
  final bool fillGridViewport;
}

class AppLayoutPolicy {
  static const double previewVideoAspectRatio = 16 / 9;

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
        videoAspectRatio: 16 / 9,
        compactVerticalCards: true,
      );
    }

    return const GroupVideoLayoutSpec(
      useGrid: false,
      crossAxisCount: 1,
      gridChildAspectRatio: 1,
      videoAspectRatio: 9 / 16,
      compactVerticalCards: false,
    );
  }

  static GroupVideoLayoutSpec diceSpecByMemberCount(int memberCount) {
    if (memberCount == 3 || memberCount == 4) {
      return const GroupVideoLayoutSpec(
        useGrid: true,
        crossAxisCount: 2,
        gridChildAspectRatio: 0.56,
        videoAspectRatio: 9 / 16,
        compactVerticalCards: false,
        fixedSlotCount: 4,
      );
    }

    if (memberCount == 6) {
      return const GroupVideoLayoutSpec(
        useGrid: true,
        crossAxisCount: 2,
        gridChildAspectRatio: 0.56,
        videoAspectRatio: 9 / 16,
        compactVerticalCards: false,
        fixedSlotCount: 6,
      );
    }

    if (memberCount == 7 || memberCount == 8) {
      return const GroupVideoLayoutSpec(
        useGrid: true,
        crossAxisCount: 2,
        gridChildAspectRatio: 0.56,
        videoAspectRatio: 9 / 16,
        compactVerticalCards: false,
        fixedSlotCount: 8,
      );
    }

    if (memberCount == 9) {
      return const GroupVideoLayoutSpec(
        useGrid: true,
        crossAxisCount: 3,
        gridChildAspectRatio: 0.56,
        videoAspectRatio: 9 / 16,
        compactVerticalCards: false,
        fixedSlotCount: 9,
      );
    }

    return const GroupVideoLayoutSpec(
      useGrid: true,
      crossAxisCount: 3,
      gridChildAspectRatio: 0.56,
      videoAspectRatio: 9 / 16,
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

    final bool fillGridViewport = willUseDice && memberCount >= 6;
    final double radius = willUseDice ? 16 : 24;

    return GroupUiPreset(
      layoutSpec: layoutSpec,
      cardRadius: radius,
      cardOuterMargin: willUseDice ? 0 : 4,
      gridHorizontalPadding: 8,
      gridVerticalPadding: 8,
      gridSpacing: 8,
      fillGridViewport: fillGridViewport,
    );
  }
}
