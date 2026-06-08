import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import '../model_logic_page.dart';

/// Renders the background sketch image plus all user drawing strokes
/// on top of it, with full brush-type support.
class ColoringPainter extends CustomPainter {
  final List<DrawPoint?> points;
  final ui.Image sketchImage;
  final _rng = Random();

  ColoringPainter({required this.points, required this.sketchImage});

  @override
  void paint(Canvas canvas, Size size) {
    _paintSketch(canvas, size);
    for (int i = 0; i < points.length - 1; i++) {
      final cur = points[i];
      final nxt = points[i + 1];
      if (cur != null && nxt != null) {
        _renderSegment(canvas, cur, nxt);
      } else if (cur != null && nxt == null) {
        canvas.drawPoints(ui.PointMode.points, [cur.points], cur.paint);
      }
    }
  }

  void _paintSketch(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawImageRect(
      sketchImage,
      Rect.fromLTWH(0, 0, sketchImage.width.toDouble(), sketchImage.height.toDouble()),
      Offset.zero & size,
      paint,
    );
  }

  void _renderSegment(Canvas canvas, DrawPoint cur, DrawPoint nxt) {
    switch (cur.brushType) {
      case BrushType.dashed:
        _drawDashed(canvas, cur.points, nxt.points, cur.paint);
        break;
      case BrushType.rainbow:
        final rp = Paint()
          ..shader = LinearGradient(
            colors: const [
              Color(0xFFFF0000), Color(0xFFFF7700), Color(0xFFFFFF00),
              Color(0xFF00FF00), Color(0xFF0000FF), Color(0xFF8B00FF),
            ],
          ).createShader(Rect.fromPoints(cur.points, nxt.points))
          ..strokeWidth = cur.paint.strokeWidth
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(cur.points, nxt.points, rp);
        break;
      case BrushType.glitter:
        canvas.drawLine(cur.points, nxt.points, cur.paint);
        _spawnGlitter(canvas, cur.points, nxt.points, cur.paint.strokeWidth);
        break;
      case BrushType.glow:
        for (final spread in [8.0, 4.0, 1.0]) {
          final gp = Paint()
            ..color = cur.paint.color.withOpacity(0.12)
            ..strokeWidth = cur.paint.strokeWidth + spread * 3
            ..strokeCap = StrokeCap.round
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, spread * 2);
          canvas.drawLine(cur.points, nxt.points, gp);
        }
        canvas.drawLine(cur.points, nxt.points, cur.paint);
        break;
      case BrushType.chalk:
        _drawChalk(canvas, cur.points, nxt.points, cur.paint);
        break;
      default:
        canvas.drawLine(cur.points, nxt.points, cur.paint);
    }
  }

  void _drawDashed(Canvas canvas, Offset a, Offset b, Paint p) {
    const double dw = 6, ds = 5;
    final dx = b.dx - a.dx, dy = b.dy - a.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) return;
    final count = (dist / (dw + ds)).floor();
    final ux = dx / dist * dw, uy = dy / dist * dw;
    final sx = dx / dist * ds, sy = dy / dist * ds;
    double x = a.dx, y = a.dy;
    for (int i = 0; i < count; i++) {
      canvas.drawLine(Offset(x, y), Offset(x + ux, y + uy), p);
      x += ux + sx; y += uy + sy;
    }
  }

  void _spawnGlitter(Canvas canvas, Offset a, Offset b, double sw) {
    final starPaint = Paint()..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final t = i / 4.0;
      final cx = a.dx + (b.dx - a.dx) * t + (_rng.nextDouble() - 0.5) * sw * 3;
      final cy = a.dy + (b.dy - a.dy) * t + (_rng.nextDouble() - 0.5) * sw * 3;
      starPaint
        ..color = [
          const Color(0xFFFFD700), const Color(0xFFFF69B4),
          const Color(0xFF00FFFF), const Color(0xFF7FFF00),
        ][_rng.nextInt(4)]
        ..strokeWidth = 2;
      canvas.drawPoints(ui.PointMode.points, [Offset(cx, cy)], starPaint);
    }
  }

  void _drawChalk(Canvas canvas, Offset a, Offset b, Paint p) {
    final r = Random(a.dx.toInt() ^ b.dy.toInt());
    for (int i = 0; i < 5; i++) {
      final off = Offset(
        (r.nextDouble() - 0.5) * p.strokeWidth * 0.6,
        (r.nextDouble() - 0.5) * p.strokeWidth * 0.6,
      );
      final cp = Paint()
        ..color = p.color.withOpacity(0.3 + r.nextDouble() * 0.5)
        ..strokeWidth = p.strokeWidth * (0.3 + r.nextDouble() * 0.6)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(a + off, b + off, cp);
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) => true;
}