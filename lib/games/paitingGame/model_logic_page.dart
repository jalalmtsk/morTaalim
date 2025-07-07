import 'dart:ui';

import 'package:flutter/cupertino.dart';

class DrawPoint {
  final Offset points;
  final Paint paint;

  DrawPoint({required this.points, required this.paint});
}

class DrawingPainter extends CustomPainter {
  final List<DrawPoint?> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      if (current != null && next != null) {
        canvas.drawLine(current.points, next.points, current.paint);
      } else if (current != null && next == null) {
        canvas.drawPoints(PointMode.points, [current.points], current.paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}

/// Utility function from flutter_colorpicker to determine text color based on background color
bool useWhiteForeground(Color backgroundColor, {double bias = 0.0}) {
  int v = (0.299 * backgroundColor.red * backgroundColor.red +
      0.587 * backgroundColor.green * backgroundColor.green +
      0.114 * backgroundColor.blue * backgroundColor.blue)
      .round();
  return v < 130 + bias;
}
