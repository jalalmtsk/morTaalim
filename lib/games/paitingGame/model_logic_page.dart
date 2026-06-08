import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
//  BRUSH TYPES
// ─────────────────────────────────────────────────────────
enum BrushType { normal, dashed, rainbow, glitter, glow, chalk }

// ─────────────────────────────────────────────────────────
//  DRAW STROKE  (a complete stroke = list of points + style)
//  We store strokes, not individual points, for efficient undo
// ─────────────────────────────────────────────────────────
class DrawStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final BrushType brushType;
  final bool isEraser;

  const DrawStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.brushType,
    required this.isEraser,
  });
}

// ─────────────────────────────────────────────────────────
//  INCREMENTAL PAINTER
//  Key idea: keep a cached ui.Picture of all committed strokes.
//  On each frame only render the ACTIVE (in-progress) stroke
//  on top. This avoids O(n) repaint of the full history.
// ─────────────────────────────────────────────────────────
class DrawingPainter extends CustomPainter {
  /// All finished strokes rendered into one cached picture
  final ui.Picture? cachedPicture;
  /// The stroke currently being drawn (not yet committed)
  final DrawStroke? activeStroke;
  final Color backgroundColor;
  final Size canvasSize;

  DrawingPainter({
    this.cachedPicture,
    this.activeStroke,
    required this.backgroundColor,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = backgroundColor,
    );
    // 2. Cached committed strokes
    if (cachedPicture != null) {
      canvas.drawPicture(cachedPicture!);
    }
    // 3. Active stroke only
    if (activeStroke != null && activeStroke!.points.isNotEmpty) {
      _paintStroke(canvas, activeStroke!);
    }
  }

  /// Paint a single stroke onto any canvas
  static void paintStrokeOnCanvas(Canvas canvas, DrawStroke stroke) {
    _paintStrokeStatic(canvas, stroke);
  }

  static final _rng = Random();

  void _paintStroke(Canvas canvas, DrawStroke stroke) =>
      _paintStrokeStatic(canvas, stroke);

  static void _paintStrokeStatic(Canvas canvas, DrawStroke stroke) {
    final pts = stroke.points;
    if (pts.isEmpty) return;

    final basePaint = Paint()
      ..color = stroke.isEraser
          ? Colors.white
          : stroke.color.withOpacity(stroke.brushType == BrushType.chalk ? 0.7 : 1.0)
      ..strokeWidth = stroke.isEraser ? stroke.strokeWidth * 1.5 : stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (pts.length == 1) {
      final dotPaint = Paint()
        ..color = basePaint.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pts[0], stroke.strokeWidth / 2, dotPaint);
      return;
    }

    switch (stroke.brushType) {
      case BrushType.normal:
        _drawSmooth(canvas, pts, basePaint);
        break;
      case BrushType.dashed:
        _drawDashedSmooth(canvas, pts, basePaint);
        break;
      case BrushType.rainbow:
        _drawRainbowSmooth(canvas, pts, stroke.strokeWidth);
        break;
      case BrushType.glitter:
        _drawSmooth(canvas, pts, basePaint);
        _drawGlitterOverlay(canvas, pts, stroke.strokeWidth);
        break;
      case BrushType.glow:
        _drawGlowSmooth(canvas, pts, stroke.color, stroke.strokeWidth);
        break;
      case BrushType.chalk:
        _drawChalkSmooth(canvas, pts, stroke.color, stroke.strokeWidth);
        break;
    }
  }

  // ── SMOOTH PATH (quadratic bezier through midpoints) ──
  static void _drawSmooth(Canvas canvas, List<Offset> pts, Paint paint) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final mid = (pts[i] + pts[i + 1]) / 2;
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    canvas.drawPath(path, paint);
  }

  // ── DASHED: draw segments spaced along the smooth path ──
  static void _drawDashedSmooth(Canvas canvas, List<Offset> pts, Paint paint) {
    const double dashLen = 8, gapLen = 6;
    double accumulated = 0;
    bool drawing = true;
    double budget = dashLen;

    for (int i = 0; i < pts.length - 1; i++) {
      final a = pts[i], b = pts[i + 1];
      final dx = b.dx - a.dx, dy = b.dy - a.dy;
      double segLen = sqrt(dx * dx + dy * dy);
      if (segLen < 0.001) continue;
      double t = 0;
      while (t < segLen) {
        final remaining = segLen - t;
        final step = remaining < budget ? remaining : budget;
        final t0 = t / segLen, t1 = (t + step) / segLen;
        if (drawing) {
          canvas.drawLine(
            Offset(a.dx + dx * t0, a.dy + dy * t0),
            Offset(a.dx + dx * t1, a.dy + dy * t1),
            paint,
          );
        }
        t += step;
        budget -= step;
        if (budget <= 0) {
          drawing = !drawing;
          budget = drawing ? dashLen : gapLen;
        }
      }
    }
  }

  // ── RAINBOW: hue shifts along the path ──
  static void _drawRainbowSmooth(Canvas canvas, List<Offset> pts, double sw) {
    if (pts.length < 2) return;
    final totalPts = pts.length;
    final paint = Paint()
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < totalPts - 1; i++) {
      final hue = (i / totalPts * 360) % 360;
      paint.color = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
      canvas.drawLine(pts[i], pts[i + 1], paint);
    }
  }

  // ── GLITTER: tiny dots scattered near the path, batch-drawn ──
  static void _drawGlitterOverlay(Canvas canvas, List<Offset> pts, double sw) {
    // Only scatter dots on every 3rd point to keep it fast
    final glitterColors = [
      const Color(0xFFFFD700), const Color(0xFFFF69B4),
      const Color(0xFF00FFFF), const Color(0xFF7FFF00),
      const Color(0xFFFFFFFF),
    ];
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < pts.length; i += 3) {
      final angle = _rng.nextDouble() * pi * 2;
      final dist = _rng.nextDouble() * sw * 1.5;
      final cx = pts[i].dx + cos(angle) * dist;
      final cy = pts[i].dy + sin(angle) * dist;
      paint.color = glitterColors[_rng.nextInt(glitterColors.length)];
      canvas.drawCircle(Offset(cx, cy), 1.5 + _rng.nextDouble() * 1.5, paint);
    }
  }

  // ── GLOW: single wide semi-transparent pass + solid core ──
  // No MaskFilter.blur — just two draws, very fast
  static void _drawGlowSmooth(Canvas canvas, List<Offset> pts, Color color, double sw) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final mid = (pts[i] + pts[i + 1]) / 2;
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    // Outer glow (thick, transparent)
    canvas.drawPath(path, Paint()
      ..color = color.withOpacity(0.25)
      ..strokeWidth = sw * 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke);
    // Mid glow
    canvas.drawPath(path, Paint()
      ..color = color.withOpacity(0.45)
      ..strokeWidth = sw * 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke);
    // Core
    canvas.drawPath(path, Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = sw * 0.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke);
  }

  // ── CHALK: 2 offset passes with varying opacity, no new Random per call ──
  static void _drawChalkSmooth(Canvas canvas, List<Offset> pts, Color color, double sw) {
    if (pts.length < 2) return;
    // Pre-seeded offsets — deterministic, no per-frame RNG
    final offsets = [
      const Offset(-1.5, -1.0),
      const Offset(1.0, 0.5),
      const Offset(-0.5, 1.5),
    ];
    final opacities = [0.55, 0.35, 0.25];
    final widths = [sw * 0.9, sw * 0.6, sw * 0.4];

    for (int pass = 0; pass < 3; pass++) {
      final path = Path()
        ..moveTo(pts[0].dx + offsets[pass].dx, pts[0].dy + offsets[pass].dy);
      for (int i = 0; i < pts.length - 1; i++) {
        final mid = (pts[i] + pts[i + 1]) / 2;
        path.quadraticBezierTo(
          pts[i].dx + offsets[pass].dx, pts[i].dy + offsets[pass].dy,
          mid.dx + offsets[pass].dx, mid.dy + offsets[pass].dy,
        );
      }
      canvas.drawPath(path, Paint()
        ..color = color.withOpacity(opacities[pass])
        ..strokeWidth = widths[pass]
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter old) =>
      old.cachedPicture != cachedPicture ||
          old.activeStroke != activeStroke ||
          old.backgroundColor != backgroundColor;
}

// ─────────────────────────────────────────────────────────
//  CANVAS CONTROLLER
//  Manages stroke history + incremental picture caching
// ─────────────────────────────────────────────────────────
class CanvasController extends ChangeNotifier {
  final List<DrawStroke> _strokes = [];
  DrawStroke? _activeStroke;
  ui.Picture? _cachedPicture;
  Size _size = Size.zero;
  Color backgroundColor;

  CanvasController({this.backgroundColor = Colors.white});

  List<DrawStroke> get strokes => List.unmodifiable(_strokes);
  DrawStroke? get activeStroke => _activeStroke;
  ui.Picture? get cachedPicture => _cachedPicture;
  bool get canUndo => _strokes.isNotEmpty;

  void setSize(Size s) {
    if (_size != s) {
      _size = s;
      _rebuildCache();
    }
  }

  // Start a new stroke
  void beginStroke({
    required Color color,
    required double strokeWidth,
    required BrushType brushType,
    required bool isEraser,
    required Offset point,
  }) {
    _activeStroke = DrawStroke(
      points: [point],
      color: color,
      strokeWidth: strokeWidth,
      brushType: brushType,
      isEraser: isEraser,
    );
    notifyListeners();
  }

  // Add point to active stroke
  void addPoint(Offset point) {
    if (_activeStroke == null) return;
    // Skip duplicate points (finger barely moved)
    final pts = _activeStroke!.points;
    if (pts.isNotEmpty) {
      final last = pts.last;
      final dx = point.dx - last.dx, dy = point.dy - last.dy;
      if (dx * dx + dy * dy < 1.5) return; // < ~1.2px, skip
    }
    _activeStroke = DrawStroke(
      points: [...pts, point],
      color: _activeStroke!.color,
      strokeWidth: _activeStroke!.strokeWidth,
      brushType: _activeStroke!.brushType,
      isEraser: _activeStroke!.isEraser,
    );
    notifyListeners();
  }

  // Commit stroke to history and update cache
  void endStroke() {
    if (_activeStroke == null) return;
    if (_activeStroke!.points.length >= 1) {
      _strokes.add(_activeStroke!);
      _appendToCache(_activeStroke!);
    }
    _activeStroke = null;
    notifyListeners();
  }

  void undo() {
    if (_strokes.isEmpty) return;
    _strokes.removeLast();
    _rebuildCache();
    notifyListeners();
  }

  void clear() {
    _strokes.clear();
    _cachedPicture?.dispose();
    _cachedPicture = null;
    _activeStroke = null;
    notifyListeners();
  }

  // Rebuild picture from scratch (used after undo / clear)
  void _rebuildCache() {
    if (_size == Size.zero) return;
    _cachedPicture?.dispose();
    if (_strokes.isEmpty) {
      _cachedPicture = null;
      return;
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (final stroke in _strokes) {
      DrawingPainter.paintStrokeOnCanvas(canvas, stroke);
    }
    _cachedPicture = recorder.endRecording();
  }

  // Append just the last stroke to cache (fast incremental update)
  void _appendToCache(DrawStroke stroke) {
    if (_size == Size.zero) return;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // Draw previous cache
    if (_cachedPicture != null) canvas.drawPicture(_cachedPicture!);
    // Draw new stroke
    DrawingPainter.paintStrokeOnCanvas(canvas, stroke);
    _cachedPicture?.dispose();
    _cachedPicture = recorder.endRecording();
  }

  @override
  void dispose() {
    _cachedPicture?.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────
//  SKETCH PAINTER  (background image + drawing)
// ─────────────────────────────────────────────────────────
class SketchPainter extends CustomPainter {
  final ui.Image sketchImage;
  final ui.Picture? cachedPicture;
  final DrawStroke? activeStroke;

  SketchPainter({
    required this.sketchImage,
    this.cachedPicture,
    this.activeStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sketch background, scaled to fill
    canvas.drawImageRect(
      sketchImage,
      Rect.fromLTWH(0, 0, sketchImage.width.toDouble(), sketchImage.height.toDouble()),
      Offset.zero & size,
      Paint(),
    );
    // 2. Committed strokes (cached)
    if (cachedPicture != null) canvas.drawPicture(cachedPicture!);
    // 3. Active stroke
    if (activeStroke != null && activeStroke!.points.isNotEmpty) {
      DrawingPainter.paintStrokeOnCanvas(canvas, activeStroke!);
    }
  }

  @override
  bool shouldRepaint(SketchPainter old) =>
      old.cachedPicture != cachedPicture ||
          old.activeStroke != activeStroke;
}

// ─────────────────────────────────────────────────────────
//  LEGACY COMPAT
// ─────────────────────────────────────────────────────────
class DrawPoint {
  final Offset points;
  final Paint paint;
  final BrushType brushType;
  DrawPoint({required this.points, required this.paint, this.brushType = BrushType.normal});
}

bool useWhiteForeground(Color bg, {double bias = 0.0}) {
  final v = (0.299 * bg.red * bg.red +
      0.587 * bg.green * bg.green +
      0.114 * bg.blue * bg.blue).round();
  return v < 130 + bias;
}