import 'dart:math' as math;

import 'package:flutter/material.dart';

// ======= BACKGROUND PAINTER =======
class BlobBackgroundPainter extends CustomPainter {
  BlobBackgroundPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final gradient1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment(0.2, 1),
        end: Alignment(1, 0.8),
        colors: [
          Color(0xFF5B86E5),
          Color(0xFF36D1DC),
        ],
      ).createShader(Offset.zero & size);

    final gradient2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment(1, -1),
        end: Alignment(-1, 1),
        colors: [
          Color(0xFFFF9966),
          Color(0xFFFF5E62),
        ],
      ).createShader(Offset.zero & size);

    // Base gradient background
    canvas.drawRect(Offset.zero & size, gradient1);

    // Animated blobs
    final p = (math.sin(progress * math.pi) + 1) / 2; // 0..1

    _drawBlob(
      canvas,
      size,
      center: Offset(size.width * (0.2 + 0.15 * p), size.height * 0.25),
      baseR: 140,
      wobble: 18,
      paint: gradient2..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      opacity: 0.35,
    );

    _drawBlob(
      canvas,
      size,
      center: Offset(size.width * (0.85 - 0.2 * p), size.height * 0.8),
      baseR: 180,
      wobble: 22,
      paint: gradient2..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
      opacity: 0.25,
    );
  }

  void _drawBlob(
      Canvas canvas,
      Size size, {
        required Offset center,
        required double baseR,
        required double wobble,
        required Paint paint,
        required double opacity,
      }) {
    final path = Path();
    for (int i = 0; i < 360; i += 5) {
      final rad = i * math.pi / 180;
      final r = baseR + math.sin(rad * 3 + progress * math.pi * 2) * wobble;
      final x = center.dx + math.cos(rad) * r;
      final y = center.dy + math.sin(rad) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint..color = paint.color.withOpacity(opacity));
  }


  @override
  bool shouldRepaint(covariant BlobBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ======= SMALL UTILS =======
double? lerpDouble(num a, num b, double t) => a + (b - a) * t;
