import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PathPainter extends CustomPainter {
  final List<Offset> path;
  final double tileSize;

  PathPainter(this.path, this.tileSize);

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;
    final paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final points = path.map((offset) {
      final dx = offset.dy * tileSize + tileSize / 2;
      final dy = offset.dx * tileSize + tileSize / 2;
      return Offset(dx, dy);
    }).toList();

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) {
    return oldDelegate.path != path;
  }
}
