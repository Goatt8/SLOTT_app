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

class AppLayoutPolicy {
  static const double previewVideoAspectRatio = 16 / 9;

  static GroupVideoLayoutSpec groupSpecByMemberCount(int memberCount) {
    if (memberCount <= 2) {
      return const GroupVideoLayoutSpec(
        useGrid: false,
        crossAxisCount: 1,
        gridChildAspectRatio: 1,
        videoAspectRatio: 16 / 9,
        compactVerticalCards: true,
      );
    }

    if (memberCount <= 6) {
      return const GroupVideoLayoutSpec(
        useGrid: false,
        crossAxisCount: 1,
        gridChildAspectRatio: 1,
        videoAspectRatio: 9 / 16,
        compactVerticalCards: false,
      );
    }

    if (memberCount <= 8) {
      return const GroupVideoLayoutSpec(
        useGrid: true,
        crossAxisCount: 2,
        gridChildAspectRatio: 0.58,
        videoAspectRatio: 9 / 16,
        compactVerticalCards: false,
        fixedSlotCount: 8,
      );
    }

    return const GroupVideoLayoutSpec(
      useGrid: true,
      crossAxisCount: 3,
      gridChildAspectRatio: 0.56,
      videoAspectRatio: 9 / 16,
      compactVerticalCards: false,
      fixedSlotCount: 9,
    );
  }
}
