import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
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
        forceDice || (useDiceLayout && allowDice) || (!allowVertical && allowDice);

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
