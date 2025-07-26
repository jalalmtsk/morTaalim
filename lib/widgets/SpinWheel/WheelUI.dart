import 'dart:math';
import 'package:flutter/material.dart';

class WheelPainter extends CustomPainter {
  final List<String> rewards;
  WheelPainter(this.rewards);

  @override
  void paint(Canvas canvas, Size size) {
    final sweepAngle = 2 * pi / rewards.length;
    final radius = size.width / 2;
    final center = Offset(radius, radius);

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
      ],
    );

    for (int i = 0; i < rewards.length; i++) {
      final startAngle = sweepAngle * i;

      final paint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: [
            i.isEven ? Colors.purple.shade300 : Colors.deepPurple.shade400,
            i.isEven ? Colors.purple.shade700 : Colors.deepPurple.shade700,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      final textPainter = TextPainter(
        text: TextSpan(text: rewards[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final angle = startAngle + sweepAngle / 2;
      final offset = Offset(
        center.dx + radius * 0.65 * cos(angle) - textPainter.width / 2,
        center.dy + radius * 0.65 * sin(angle) - textPainter.height / 2,
      );

      textPainter.paint(canvas, offset);
    }

    // Draw border
    canvas.drawCircle(center, radius, borderPaint);

    // Optional: Add central decoration
    final centerCircle = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.1, centerCircle);
    canvas.drawCircle(center, radius * 0.08, Paint()..color = Colors.deepPurple);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class TrianglePointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepOrange
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0) // Top point
      ..lineTo(0, size.height)    // Bottom left
      ..lineTo(size.width, size.height) // Bottom right
      ..close();

    canvas.drawShadow(path, Colors.black, 2, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
