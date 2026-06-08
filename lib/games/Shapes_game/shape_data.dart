import 'dart:math';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
//  SHAPE DATA  — each shape has a painter, name, colour + fun fact
// ═══════════════════════════════════════════════════════════════

class ShapeData {
  final String  name;
  final String  emoji;
  final String  funFact;   // educational blurb shown on match
  final Color   color;
  final Color   glow;
  final ShapePainterType painterType;

  const ShapeData({
    required this.name,
    required this.emoji,
    required this.funFact,
    required this.color,
    required this.glow,
    required this.painterType,
  });
}

enum ShapePainterType { circle, square, triangle, star, heart, hexagon, pentagon, diamond, oval, cross }

/// All shapes in learning order (simple → complex)
const List<ShapeData> kAllShapes = [
  ShapeData(
    name: 'Circle',      emoji: '🔵',
    funFact: 'A circle has NO corners — it goes round and round forever! 🌀',
    color: Color(0xFFEF4444), glow: Color(0xFFFF8080),
    painterType: ShapePainterType.circle,
  ),
  ShapeData(
    name: 'Square',      emoji: '🟥',
    funFact: 'A square has 4 equal sides and 4 corners. Boxes are squares! 📦',
    color: Color(0xFF3B82F6), glow: Color(0xFF80B4FF),
    painterType: ShapePainterType.square,
  ),
  ShapeData(
    name: 'Triangle',    emoji: '🔺',
    funFact: 'A triangle has 3 sides. Pyramids are made of triangles! 🔺',
    color: Color(0xFF22C55E), glow: Color(0xFF80E8A0),
    painterType: ShapePainterType.triangle,
  ),
  ShapeData(
    name: 'Star',        emoji: '⭐',
    funFact: 'Stars have 5 points! The sky is full of real stars at night! ✨',
    color: Color(0xFFFFB703), glow: Color(0xFFFFDD80),
    painterType: ShapePainterType.star,
  ),
  ShapeData(
    name: 'Heart',       emoji: '❤️',
    funFact: 'A heart shape has 2 bumps on top and a point at the bottom! 💕',
    color: Color(0xFFEC4899), glow: Color(0xFFFF80C0),
    painterType: ShapePainterType.heart,
  ),
  ShapeData(
    name: 'Hexagon',     emoji: '🔷',
    funFact: 'A hexagon has 6 sides. Honey bees build hexagons in their hive! 🐝',
    color: Color(0xFF8B5CF6), glow: Color(0xFFBC80FF),
    painterType: ShapePainterType.hexagon,
  ),
  ShapeData(
    name: 'Pentagon',    emoji: '⬠',
    funFact: 'A pentagon has 5 sides. The US Pentagon building has 5 sides! 🏛️',
    color: Color(0xFF06B6D4), glow: Color(0xFF80E4FF),
    painterType: ShapePainterType.pentagon,
  ),
  ShapeData(
    name: 'Diamond',     emoji: '💎',
    funFact: 'A diamond (rhombus) is like a square tilted sideways! 💎',
    color: Color(0xFF14B8A6), glow: Color(0xFF80E0D8),
    painterType: ShapePainterType.diamond,
  ),
  ShapeData(
    name: 'Oval',        emoji: '🥚',
    funFact: 'An oval is like a stretched circle. Eggs are oval shaped! 🥚',
    color: Color(0xFFF97316), glow: Color(0xFFFFB080),
    painterType: ShapePainterType.oval,
  ),
  ShapeData(
    name: 'Cross',       emoji: '✚',
    funFact: 'A cross has 4 arms going up, down, left and right! ➕',
    color: Color(0xFF84CC16), glow: Color(0xFFBCE880),
    painterType: ShapePainterType.cross,
  ),
];

// ── LEVELS ────────────────────────────────────────────────────
class ShapeLevel {
  final String name;
  final String emoji;
  final String subtitle;
  final int    shapeCount;
  final int    timeSeconds;    // 0 = no timer (easiest)
  final Color  color;
  final Color  glow;

  const ShapeLevel({
    required this.name, required this.emoji, required this.subtitle,
    required this.shapeCount, required this.timeSeconds,
    required this.color, required this.glow,
  });
}

const List<ShapeLevel> kLevels = [
  ShapeLevel(name: 'Baby',    emoji: '🍼', subtitle: '3 shapes · No timer',
      shapeCount: 3, timeSeconds: 0,
      color: Color(0xFF22C55E), glow: Color(0xFF80E8A0)),
  ShapeLevel(name: 'Easy',    emoji: '🌱', subtitle: '4 shapes · 45 sec',
      shapeCount: 4, timeSeconds: 45,
      color: Color(0xFF3B82F6), glow: Color(0xFF80B4FF)),
  ShapeLevel(name: 'Medium',  emoji: '🚀', subtitle: '6 shapes · 35 sec',
      shapeCount: 6, timeSeconds: 35,
      color: Color(0xFFFFB703), glow: Color(0xFFFFDD80)),
  ShapeLevel(name: 'Hard',    emoji: '🌪️', subtitle: '8 shapes · 25 sec',
      shapeCount: 8, timeSeconds: 25,
      color: Color(0xFFEF4444), glow: Color(0xFFFF8080)),
  ShapeLevel(name: 'Expert',  emoji: '💀', subtitle: 'All shapes · 20 sec',
      shapeCount: 10, timeSeconds: 20,
      color: Color(0xFF8B5CF6), glow: Color(0xFFBC80FF)),
];

// ── CUSTOM SHAPE PAINTER ─────────────────────────────────────
class ShapeCustomPainter extends CustomPainter {
  final ShapePainterType type;
  final Color color;
  final Color glow;
  final double glowRadius;
  final bool  isGhost; // true = outline only (drop target)

  const ShapeCustomPainter({
    required this.type, required this.color, required this.glow,
    this.glowRadius = 0, this.isGhost = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = min(cx, cy) * 0.82;

    if (glowRadius > 0 && !isGhost) {
      canvas.drawCircle(Offset(cx, cy), r + glowRadius,
          Paint()
            ..color = glow.withOpacity(0.35)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius));
    }

    final paint = isGhost
        ? (Paint()
      ..color = color.withOpacity(0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeJoin = StrokeJoin.round)
        : (Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.85,
        colors: [
          Color.lerp(color, Colors.white, 0.35)!,
          color,
          Color.lerp(color, Colors.black, 0.25)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));

    final path = _buildPath(type, cx, cy, r, size);
    canvas.drawPath(path, paint);

    // Shine highlight
    if (!isGhost) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx - r * 0.28, cy - r * 0.28),
            width:  r * 0.42, height: r * 0.28),
        Paint()..color = Colors.white.withOpacity(0.45),
      );
    }
  }

  Path _buildPath(ShapePainterType t, double cx, double cy, double r, Size s) {
    switch (t) {
      case ShapePainterType.circle:
        return Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

      case ShapePainterType.square:
        return Path()..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: r*1.7, height: r*1.7),
            const Radius.circular(10)));

      case ShapePainterType.triangle:
        return Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r * cos(pi / 6), cy + r * 0.5)
          ..lineTo(cx - r * cos(pi / 6), cy + r * 0.5)
          ..close();

      case ShapePainterType.star:
        return _starPath(cx, cy, r, r * 0.42, 5);

      case ShapePainterType.heart:
        return _heartPath(cx, cy, r);

      case ShapePainterType.hexagon:
        return _polygonPath(cx, cy, r, 6, -pi/6);

      case ShapePainterType.pentagon:
        return _polygonPath(cx, cy, r, 5, -pi/2);

      case ShapePainterType.diamond:
        return Path()
          ..moveTo(cx,       cy - r)
          ..lineTo(cx + r*0.65, cy)
          ..lineTo(cx,       cy + r)
          ..lineTo(cx - r*0.65, cy)
          ..close();

      case ShapePainterType.oval:
        return Path()..addOval(
            Rect.fromCenter(center: Offset(cx, cy), width: r*2, height: r*1.35));

      case ShapePainterType.cross:
        final t2 = r * 0.35;
        return Path()
          ..addRect(Rect.fromCenter(center: Offset(cx, cy), width: t2*2, height: r*1.7))
          ..addRect(Rect.fromCenter(center: Offset(cx, cy), width: r*1.7, height: t2*2));
    }
  }

  Path _starPath(double cx, double cy, double outer, double inner, int points) {
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final a = (i * pi / points) - pi / 2;
      final rad = i.isEven ? outer : inner;
      final x = cx + rad * cos(a);
      final y = cy + rad * sin(a);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    return path..close();
  }

  Path _heartPath(double cx, double cy, double r) {
    final path = Path();
    path.moveTo(cx, cy + r * 0.8);
    path.cubicTo(cx - r * 1.2, cy + r * 0.2, cx - r * 1.2, cy - r * 0.6, cx, cy - r * 0.1);
    path.cubicTo(cx + r * 1.2, cy - r * 0.6, cx + r * 1.2, cy + r * 0.2, cx, cy + r * 0.8);
    return path;
  }

  Path _polygonPath(double cx, double cy, double r, int sides, double startAngle) {
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final a = startAngle + (2 * pi * i / sides);
      final x = cx + r * cos(a);
      final y = cy + r * sin(a);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    return path..close();
  }

  @override bool shouldRepaint(ShapeCustomPainter old) =>
      old.glowRadius != glowRadius || old.isGhost != isGhost;
}