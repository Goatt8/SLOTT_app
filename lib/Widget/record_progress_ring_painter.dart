import 'dart:math' as math;
import 'package:flutter/material.dart';

class RecordProgressRingPainter extends CustomPainter {
  final double progress;

  const RecordProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final orbitPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final normalizedProgress = progress.clamp(0.0, 1.0);
    final startAngle = (-math.pi / 2) + (math.pi * 2 * normalizedProgress);
    const sweepAngle = math.pi / 5;
    canvas.drawArc(rect, startAngle, sweepAngle, false, orbitPaint);

    final beadAngle = startAngle + sweepAngle;
    final beadCenter =
        center +
        Offset(math.cos(beadAngle) * radius, math.sin(beadAngle) * radius);
    canvas.drawCircle(beadCenter, 3.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant RecordProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
