import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

import '../model_logic_page.dart';

class ColoringPainter extends CustomPainter {
  final List<DrawPoint?> points;
  final ui.Image sketchImage;

  ColoringPainter({required this.points, required this.sketchImage});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the sketch image in the background
    paintSketch(canvas, size);

    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      if (current != null && next != null) {
        canvas.drawLine(current.points, next.points, current.paint);
      } else if (current != null && next == null) {
        canvas.drawPoints(ui.PointMode.points, [current.points], current.paint);
      }
    }
  }

  void paintSketch(Canvas canvas, Size size) {
    final paint = Paint();
    final rect = Offset.zero & size;
    canvas.drawImageRect(
      sketchImage,
      Rect.fromLTWH(0, 0, sketchImage.width.toDouble(), sketchImage.height.toDouble()),
      rect,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
