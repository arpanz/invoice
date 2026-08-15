import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A custom painted curved doodle arrow that gracefully points from a guidance
/// tooltip down to an action button (like the FloatingActionButton).
class DoodleArrow extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final double strokeWidth;

  const DoodleArrow({
    super.key,
    this.width = 44,
    this.height = 70,
    this.color = AppColors.accentCyan,
    this.strokeWidth = 2.2,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _DoodleArrowPainter(
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _DoodleArrowPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _DoodleArrowPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Start near the top left of the bounds (right under the tooltip)
    final startX = size.width * 0.15;
    final startY = 0.0;

    // Control point 1 to create an outward sweeping graceful curve
    final cpX = size.width * 0.95;
    final cpY = size.height * 0.45;

    // End point at the bottom center pointing directly down at the FAB
    final endX = size.width * 0.50;
    final endY = size.height;

    path.moveTo(startX, startY);
    path.quadraticBezierTo(cpX, cpY, endX, endY);

    canvas.drawPath(path, paint);

    // Draw Arrowhead pointing downwards at an angle
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Arrowhead left barb
    canvas.drawLine(
      Offset(endX, endY),
      Offset(endX - 9, endY - 10),
      arrowPaint,
    );

    // Arrowhead right barb
    canvas.drawLine(
      Offset(endX, endY),
      Offset(endX + 6, endY - 12),
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DoodleArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
