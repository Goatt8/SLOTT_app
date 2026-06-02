import 'package:flutter/material.dart';

class NavigationTriangleButton extends StatefulWidget {
  final bool isLeft;
  final bool enabled;
  final VoidCallback? onTap;

  const NavigationTriangleButton({
    super.key,
    required this.isLeft,
    required this.enabled,
    this.onTap,
  });

  @override
  State<NavigationTriangleButton> createState() =>
      _NavigationTriangleButtonState();
}

class _NavigationTriangleButtonState extends State<NavigationTriangleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color lineColor;
    if (!widget.enabled) {
      lineColor = Colors.white24;
    } else if (_isPressed) {
      lineColor = const Color(0xFF7C3AED);
    } else {
      lineColor = Colors.white54;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled
          ? (_) {
              setState(() {
                _isPressed = true;
              });
            }
          : null,
      onTapCancel: () {
        if (_isPressed) {
          setState(() {
            _isPressed = false;
          });
        }
      },
      onTapUp: widget.enabled
          ? (_) {
              setState(() {
                _isPressed = false;
              });
            }
          : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: SizedBox(
        width: 34,
        height: 32,
        child: Center(
          child: AnimatedScale(
            scale: _isPressed ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            child: CustomPaint(
              size: const Size(16, 16),
              painter: _TriangleOutlinePainter(
                color: lineColor,
                isLeft: widget.isLeft,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TriangleOutlinePainter extends CustomPainter {
  final Color color;
  final bool isLeft;

  const _TriangleOutlinePainter({required this.color, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    if (isLeft) {
      path
        ..moveTo(size.width * 0.78, size.height * 0.16)
        ..lineTo(size.width * 0.28, size.height * 0.50)
        ..lineTo(size.width * 0.78, size.height * 0.84)
        ..close();
    } else {
      path
        ..moveTo(size.width * 0.22, size.height * 0.16)
        ..lineTo(size.width * 0.72, size.height * 0.50)
        ..lineTo(size.width * 0.22, size.height * 0.84)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TriangleOutlinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isLeft != isLeft;
  }
}
