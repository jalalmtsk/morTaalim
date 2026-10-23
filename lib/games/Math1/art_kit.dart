import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'm1_kit.dart';
import 'm1_text.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Éducation artistique — shared pieces: paint colours, paint blobs & pots,
// paper pieces for collages, stamps for friezes, rhythm sounds, the gallery.
// ═══════════════════════════════════════════════════════════════════════════

const Map<String, Color> artColors = {
  'red': Color(0xFFE53935), 'yellow': Color(0xFFFDD835), 'blue': Color(0xFF1E63E9), 'green': Color(0xFF43A047),
  'orange': Color(0xFFFB8C00), 'purple': Color(0xFF8E24AA), 'pink': Color(0xFFF48FB1), 'lightblue': Color(0xFF90CAF9),
  'white': Color(0xFFFFFFFF), 'black': Color(0xFF333333), 'grey': Color(0xFF9E9E9E), 'brown': Color(0xFF8D5524),
};

Color artColor(String c) => artColors[c] ?? Colors.grey;

/// Pots that have a picture in the sheets.
const Set<String> _jarSprites = {'red', 'yellow', 'blue', 'green', 'orange', 'purple'};

/// A paint pot of colour [c].
class ArtJar extends StatelessWidget {
  final String c;
  final double size;
  const ArtJar({super.key, required this.c, this.size = 70});
  @override
  Widget build(BuildContext context) {
    if (_jarSprites.contains(c)) return Image.asset(m1('art_jar_$c'), width: size, height: size * 1.15, fit: BoxFit.contain);
    return SizedBox(width: size, height: size * 1.15, child: CustomPaint(painter: _JarPainter(artColor(c))));
  }
}

class _JarPainter extends CustomPainter {
  final Color c;
  _JarPainter(this.c);
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.12, h * 0.22, w * 0.76, h * 0.74), Radius.circular(w * 0.16));
    canvas.drawRRect(body.shift(const Offset(0, 3)), Paint()..color = Colors.black.withOpacity(0.15));
    canvas.drawRRect(body, Paint()..color = c);
    canvas.drawRRect(body, Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
    final lid = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.2, h * 0.08, w * 0.6, h * 0.17), Radius.circular(w * 0.06));
    canvas.drawRRect(lid, Paint()..color = Color.lerp(c, Colors.black, 0.15)!);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.22, h * 0.32, w * 0.12, h * 0.5), Radius.circular(w * 0.06)),
      Paint()..color = Colors.white.withOpacity(0.45),
    );
  }

  @override
  bool shouldRepaint(_JarPainter o) => o.c != c;
}

/// A wobbly paint blob (like a brush stroke of colour).
class ArtBlob extends StatelessWidget {
  final Color color;
  final double size;
  final int seed;
  const ArtBlob({super.key, required this.color, this.size = 80, this.seed = 1});
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size * 0.75, child: CustomPaint(painter: ArtBlobPainter(color, seed)));
}

class ArtBlobPainter extends CustomPainter {
  final Color color;
  final int seed;
  ArtBlobPainter(this.color, this.seed);
  @override
  void paint(Canvas canvas, Size s) {
    final r = Random(seed);
    final c = s.center(Offset.zero);
    final path = Path();
    const n = 14;
    for (var i = 0; i <= n; i++) {
      final a = i / n * 2 * pi;
      final k = 0.82 + r.nextDouble() * 0.22;
      final p = c + Offset(cos(a) * s.width * 0.46 * k, sin(a) * s.height * 0.44 * k);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    final smooth = _smooth(path);
    canvas.drawPath(smooth.shift(const Offset(0, 3)), Paint()..color = Colors.black.withOpacity(0.12));
    canvas.drawPath(smooth, Paint()..color = color);
    if (color.computeLuminance() > 0.85) {
      canvas.drawPath(smooth, Paint()
        ..color = const Color(0xFFD9CFC0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }
    canvas.drawOval(Rect.fromCenter(center: c + Offset(-s.width * 0.14, -s.height * 0.14), width: s.width * 0.28, height: s.height * 0.16),
        Paint()..color = Colors.white.withOpacity(0.35));
  }

  Path _smooth(Path p) {
    final m = p.computeMetrics().first;
    final pts = [for (var d = 0.0; d < m.length; d += m.length / 40) m.getTangentForOffset(d)!.position];
    final out = Path()..moveTo((pts[0].dx + pts[1].dx) / 2, (pts[0].dy + pts[1].dy) / 2);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i], b = pts[(i + 1) % pts.length];
      out.quadraticBezierTo(a.dx, a.dy, (a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    }
    return out..close();
  }

  @override
  bool shouldRepaint(ArtBlobPainter o) => o.color != color || o.seed != seed;
}

// ── stamps (motifs) ─────────────────────────────────────────────────────────

const List<String> artStampShapes = ['circle', 'triangle', 'square', 'flower', 'diamond', 'star'];
const List<String> artStampColors = ['orange', 'teal', 'purple', 'pink', 'green'];
const Map<String, Color> _stampColor = {
  'orange': Color(0xFFF7811E), 'teal': Color(0xFF14A9B8), 'purple': Color(0xFF7B3FE4), 'pink': Color(0xFFE5408A), 'green': Color(0xFF43A047),
};

/// A stamp like "flower:purple".
class ArtStamp extends StatelessWidget {
  final String id;
  final double size;
  const ArtStamp({super.key, required this.id, this.size = 50});
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size, child: CustomPaint(painter: ArtStampPainter(id)));
}

class ArtStampPainter extends CustomPainter {
  final String id;
  ArtStampPainter(this.id);
  @override
  void paint(Canvas canvas, Size s) {
    final parts = id.split(':');
    final shape = parts[0];
    final col = _stampColor[parts.length > 1 ? parts[1] : 'orange'] ?? Colors.orange;
    final p = Paint()..color = col;
    final c = s.center(Offset.zero);
    final r = s.shortestSide * 0.42;
    final path = artShapePath(shape, c, r);
    canvas.drawPath(path.shift(const Offset(0, 2)), Paint()..color = Colors.black.withOpacity(0.12));
    canvas.drawPath(path, p);
    if (shape == 'flower') canvas.drawCircle(c, r * 0.28, Paint()..color = const Color(0xFFFFE07A));
  }

  @override
  bool shouldRepaint(ArtStampPainter o) => o.id != id;
}

Path artShapePath(String shape, Offset c, double r) {
  switch (shape) {
    case 'circle':
      return Path()..addOval(Rect.fromCircle(center: c, radius: r));
    case 'triangle':
      return Path()
        ..moveTo(c.dx, c.dy - r)
        ..lineTo(c.dx + r * 1.05, c.dy + r * 0.8)
        ..lineTo(c.dx - r * 1.05, c.dy + r * 0.8)
        ..close();
    case 'square':
      return Path()..addRRect(RRect.fromRectAndRadius(Rect.fromCircle(center: c, radius: r * 0.85), Radius.circular(r * 0.12)));
    case 'diamond':
      return Path()
        ..moveTo(c.dx, c.dy - r)
        ..lineTo(c.dx + r * 0.75, c.dy)
        ..lineTo(c.dx, c.dy + r)
        ..lineTo(c.dx - r * 0.75, c.dy)
        ..close();
    case 'star':
      final p = Path();
      for (var i = 0; i < 10; i++) {
        final a = -pi / 2 + i * pi / 5;
        final rr = i.isEven ? r : r * 0.45;
        final q = c + Offset(cos(a) * rr, sin(a) * rr);
        if (i == 0) {
          p.moveTo(q.dx, q.dy);
        } else {
          p.lineTo(q.dx, q.dy);
        }
      }
      return p..close();
    default: // flower
      var p = Path();
      for (var i = 0; i < 6; i++) {
        final a = i * pi / 3;
        p = Path.combine(PathOperation.union, p, Path()..addOval(Rect.fromCircle(center: c + Offset(cos(a), sin(a)) * r * 0.55, radius: r * 0.42)));
      }
      return p;
  }
}

// ── paper pieces (collages) ─────────────────────────────────────────────────

class ArtPieceType {
  final String id;
  final Color color;
  final double w, h; // default size, fraction of the board width
  const ArtPieceType(this.id, this.color, this.w, this.h);
}

const Map<String, ArtPieceType> artPieces = {
  'wall': ArtPieceType('wall', Color(0xFFF4E7CF), 0.44, 0.34),
  'roof': ArtPieceType('roof', Color(0xFFE5483C), 0.56, 0.26),
  'door': ArtPieceType('door', Color(0xFF7B3FE4), 0.1, 0.16),
  'window': ArtPieceType('window', Color(0xFF2E86E8), 0.11, 0.11),
  'grass': ArtPieceType('grass', Color(0xFF59B847), 0.96, 0.1),
  'sun': ArtPieceType('sun', Color(0xFFF9C623), 0.16, 0.16),
  'trunk': ArtPieceType('trunk', Color(0xFF7A4B26), 0.07, 0.3),
  'crown': ArtPieceType('crown', Color(0xFF3C9E3A), 0.3, 0.3),
  'flower': ArtPieceType('flower', Color(0xFF9B4BE0), 0.14, 0.14),
  'flower2': ArtPieceType('flower2', Color(0xFFE85C9E), 0.14, 0.14),
  'cloud': ArtPieceType('cloud', Color(0xFFFFFFFF), 0.26, 0.12),
  'sea': ArtPieceType('sea', Color(0xFF2E9BE0), 0.98, 0.2),
  'hull': ArtPieceType('hull', Color(0xFF9A5B2E), 0.5, 0.12),
  'sail': ArtPieceType('sail', Color(0xFFFFFDF5), 0.26, 0.32),
  'sail2': ArtPieceType('sail2', Color(0xFFF7811E), 0.16, 0.22),
  'fish': ArtPieceType('fish', Color(0xFFF7811E), 0.12, 0.08),
};

/// A cut-paper piece of [type], [w] × [h] pixels.
class ArtPiece extends StatelessWidget {
  final String type;
  final double w, h;
  final bool ghost; // dashed outline only (where it goes)
  final bool lit;
  const ArtPiece({super.key, required this.type, required this.w, required this.h, this.ghost = false, this.lit = false});
  @override
  Widget build(BuildContext context) => SizedBox(width: w, height: h, child: CustomPaint(painter: ArtPiecePainter(type, ghost: ghost, lit: lit)));
}

class ArtPiecePainter extends CustomPainter {
  final String type;
  final bool ghost, lit;
  ArtPiecePainter(this.type, {this.ghost = false, this.lit = false});

  Path shapeOf(Size s) {
    final w = s.width, h = s.height;
    switch (type) {
      case 'roof':
      case 'sail':
      case 'sail2':
        return Path()
          ..moveTo(w / 2, 0)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close();
      case 'sun':
      case 'crown':
        return Path()..addOval(Offset.zero & s);
      case 'cloud':
        var p = Path()..addOval(Rect.fromLTWH(0, h * 0.35, w * 0.5, h * 0.65));
        p = Path.combine(PathOperation.union, p, Path()..addOval(Rect.fromLTWH(w * 0.22, 0, w * 0.5, h * 0.9)));
        return Path.combine(PathOperation.union, p, Path()..addOval(Rect.fromLTWH(w * 0.5, h * 0.3, w * 0.5, h * 0.7)));
      case 'hull':
        return Path()
          ..moveTo(0, 0)
          ..lineTo(w, 0)
          ..lineTo(w * 0.82, h)
          ..lineTo(w * 0.18, h)
          ..close();
      case 'sea':
        final p = Path()..moveTo(0, h * 0.25);
        for (var i = 0; i < 6; i++) {
          final x0 = w * i / 6;
          p.quadraticBezierTo(x0 + w / 12, 0, x0 + w / 6, h * 0.25);
        }
        return p
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close();
      case 'grass':
        final p = Path()..moveTo(0, h);
        for (var i = 0; i <= 12; i++) {
          p.lineTo(w * i / 12, i.isEven ? h * 0.15 : h * 0.4);
        }
        return p
          ..lineTo(w, h)
          ..close();
      case 'flower':
      case 'flower2':
        return artShapePath('flower', s.center(Offset.zero), s.shortestSide / 2);
      case 'fish':
        return Path()
          ..addOval(Rect.fromLTWH(0, 0, w * 0.75, h))
          ..moveTo(w * 0.7, h / 2)
          ..lineTo(w, 0)
          ..lineTo(w, h)
          ..close();
      default:
        return Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(min(w, h) * 0.06)));
    }
  }

  @override
  void paint(Canvas canvas, Size s) {
    final path = shapeOf(s);
    if (ghost) {
      canvas.drawPath(path, Paint()..color = (lit ? const Color(0xFF39B8F2) : const Color(0xFF7B3FE4)).withOpacity(0.08));
      final st = Paint()
        ..color = lit ? const Color(0xFF39B8F2) : const Color(0xFF9C86C9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lit ? 3 : 2;
      for (final m in path.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 10) {
          canvas.drawPath(m.extractPath(d, d + 6), st);
        }
      }
      return;
    }
    final col = artPieces[type]?.color ?? Colors.grey;
    canvas.drawPath(path.shift(const Offset(1.5, 2.5)), Paint()..color = Colors.black.withOpacity(0.16));
    canvas.drawPath(path, Paint()..color = col);
    // paper fibres
    canvas.save();
    canvas.clipPath(path);
    final r = Random(type.hashCode);
    final f = Paint()
      ..color = Colors.white.withOpacity(0.13)
      ..strokeWidth = 1;
    for (var i = 0; i < (s.width * s.height / 120).clamp(8, 90); i++) {
      final a = Offset(r.nextDouble() * s.width, r.nextDouble() * s.height);
      canvas.drawLine(a, a + Offset(r.nextDouble() * 8 - 4, r.nextDouble() * 8 - 4), f);
    }
    canvas.restore();
    canvas.drawPath(path, Paint()
      ..color = Color.lerp(col, Colors.black, 0.18)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    // details
    final w = s.width, h = s.height;
    if (type == 'window') {
      final l = Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..strokeWidth = max(1.5, w * 0.08);
      canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), l);
      canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), l);
    } else if (type == 'door') {
      canvas.drawCircle(Offset(w * 0.72, h * 0.55), max(1.5, w * 0.08), Paint()..color = const Color(0xFF3B1388));
    } else if (type == 'flower' || type == 'flower2') {
      canvas.drawCircle(s.center(Offset.zero), s.shortestSide * 0.16, Paint()..color = const Color(0xFFFFD84A));
    } else if (type == 'fish') {
      canvas.drawCircle(Offset(w * 0.2, h * 0.4), max(1.0, h * 0.1), Paint()..color = Colors.black87);
    }
  }

  @override
  bool shouldRepaint(ArtPiecePainter o) => o.type != type || o.ghost != ghost || o.lit != lit;
}

/// A piece placed on a board: centre (fractions of the board width / height), scale, turn.
class ArtPlaced {
  final String type;
  double x, y, scale, turn;
  ArtPlaced(this.type, this.x, this.y, {this.scale = 1, this.turn = 0});
  Map<String, dynamic> toJson() => {'t': type, 'x': x, 'y': y, 's': scale, 'r': turn};
  static ArtPlaced from(Map m) => ArtPlaced(m['t'], (m['x'] as num).toDouble(), (m['y'] as num).toDouble(),
      scale: (m['s'] as num).toDouble(), turn: (m['r'] as num).toDouble());
}

/// A collage board (paper background + pieces), drawn at width [w].
Widget artCollage(List<ArtPlaced> pieces, double w, {double ratio = 0.9}) {
  final h = w * ratio;
  return Container(
    width: w,
    height: h,
    decoration: BoxDecoration(color: const Color(0xFFFFF8EA), borderRadius: BorderRadius.circular(w * 0.03)),
    clipBehavior: Clip.antiAlias,
    child: Stack(children: [
      for (final p in pieces)
        () {
          final t = artPieces[p.type]!;
          final pw = t.w * w * p.scale, ph = t.h * w * p.scale;
          return Positioned(
            left: p.x * w - pw / 2,
            top: p.y * h - ph / 2,
            child: Transform.rotate(angle: p.turn, child: ArtPiece(type: p.type, w: pw, h: ph)),
          );
        }(),
    ]),
  );
}

// ── rhythm sounds ───────────────────────────────────────────────────────────

void artBeat(BuildContext c, String b) {
  if (b == 'clap') m1Sfx(c, 'art_clap.wav');
  if (b == 'boum') m1Sfx(c, 'art_boum.wav');
}

/// One beat card: clap / boum / silence.
class ArtBeatCard extends StatelessWidget {
  final String beat;
  final double size;
  final bool lit;
  final bool label;
  const ArtBeatCard({super.key, required this.beat, this.size = 64, this.lit = false, this.label = true});
  @override
  Widget build(BuildContext context) {
    final icon = switch (beat) {
      'boum' => Image.asset(m1('art_drum'), fit: BoxFit.contain),
      'clap' => const FittedBox(child: Text('👏', style: TextStyle(fontSize: 40))),
      _ => const FittedBox(child: Text('✋', style: TextStyle(fontSize: 40))),
    };
    final col = switch (beat) { 'boum' => m1Orange, 'clap' => m1Purple, _ => const Color(0xFF9C9C9C) };
    return AnimatedScale(
      scale: lit ? 1.15 : 1,
      duration: const Duration(milliseconds: 150),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size * (label ? 1.15 : 1),
        padding: EdgeInsets.all(size * 0.1),
        decoration: BoxDecoration(
          color: lit ? Color.lerp(m1Cream, col, 0.25) : m1Cream,
          borderRadius: BorderRadius.circular(size * 0.22),
          border: Border.all(color: lit ? col : m1Line, width: lit ? 3.5 : 2),
          boxShadow: [
            BoxShadow(color: const Color(0xFFC49A52).withOpacity(0.4), offset: const Offset(0, 3)),
            if (lit) BoxShadow(color: col.withOpacity(0.5), blurRadius: 12),
          ],
        ),
        child: Column(children: [
          Expanded(child: icon),
          if (label) FittedBox(child: Text(m1T(context, 'rt_$beat'), style: m1Text(size * 0.2))),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GALLERY
// ═══════════════════════════════════════════════════════════════════════════

class ArtCreation {
  final String id, kind; // drawing · coloring · collage · motif · rhythm
  String name;
  final Map<String, dynamic> data;
  final int time;
  ArtCreation(this.id, this.kind, this.name, this.data, this.time);
  Map<String, dynamic> toJson() => {'id': id, 'k': kind, 'n': name, 'd': data, 't': time};
  static ArtCreation from(Map m) => ArtCreation(m['id'], m['k'], m['n'], Map<String, dynamic>.from(m['d'] as Map), m['t']);
}

class ArtGallery {
  static const _k = 'art_gallery';
  static Future<List<ArtCreation>> all() async {
    final raw = (await SharedPreferences.getInstance()).getString(_k);
    if (raw == null) return [];
    try {
      return [for (final m in jsonDecode(raw) as List) ArtCreation.from(m as Map)];
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(List<ArtCreation> l) async =>
      (await SharedPreferences.getInstance()).setString(_k, jsonEncode([for (final c in l) c.toJson()]));

  static Future<void> add(ArtCreation c) async {
    final l = await all();
    l.insert(0, c);
    await _save(l.take(60).toList());
  }

  static Future<void> rename(String id, String name) async {
    final l = await all();
    for (final c in l) {
      if (c.id == id) c.name = name;
    }
    await _save(l);
  }

  static Future<void> remove(String id) async {
    final l = await all()
      ..removeWhere((c) => c.id == id);
    await _save(l);
  }
}

/// Asks for a name and saves the creation. Returns true when saved.
Future<bool> artSaveDialog(BuildContext context, String kind, Map<String, dynamic> data, String defaultName) async {
  final ctrl = TextEditingController(text: defaultName);
  final ok = await m1Dialog<bool>(
    context,
    M1Frame(
      child: Center(
        child: Material(
          type: MaterialType.transparency,
          child: M1Card(
            width: 330,
            radius: 26,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(m1T(context, 'art_keep'), style: m1Text(22, color: m1Purple)),
              const SizedBox(height: 8),
              SizedBox(height: 120, child: Center(child: ArtThumb(creation: ArtCreation('x', kind, '', data, 0), width: 150))),
              const SizedBox(height: 8),
              Align(alignment: AlignmentDirectional.centerStart, child: Text(m1T(context, 'art_name'), style: m1Text(14))),
              const SizedBox(height: 4),
              TextField(
                controller: ctrl,
                maxLength: 24,
                style: m1Text(17),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF9CD3FA))),
                ),
              ),
              const SizedBox(height: 12),
              M1OrangeButton(label: m1T(context, 'art_save'), icon: Icons.save_rounded, onTap: () => Navigator.of(context).pop(true), width: 260, height: 52),
              const SizedBox(height: 8),
              M1Press(onTap: () => Navigator.of(context).pop(false), child: Text(m1T(context, 'art_nosave'), style: m1Text(14, color: m1InkSoft))),
            ]),
          ),
        ),
      ),
    ),
    dismissible: false,
  );
  if (ok == true) {
    final name = ctrl.text.trim().isEmpty ? defaultName : ctrl.text.trim();
    await ArtGallery.add(ArtCreation('${DateTime.now().millisecondsSinceEpoch}', kind, name, data, DateTime.now().millisecondsSinceEpoch));
    return true;
  }
  return false;
}

/// Small picture of a creation.
class ArtThumb extends StatelessWidget {
  final ArtCreation creation;
  final double width;
  const ArtThumb({super.key, required this.creation, required this.width});
  @override
  Widget build(BuildContext context) {
    final d = creation.data;
    switch (creation.kind) {
      case 'collage':
        return artCollage([for (final m in (d['p'] as List)) ArtPlaced.from(m as Map)], width);
      case 'motif':
        final items = List<String>.from(d['m'] as List);
        return Container(
          width: width,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: const Color(0xFFFFF8EA), borderRadius: BorderRadius.circular(10), border: Border.all(color: m1Line)),
          child: Wrap(alignment: WrapAlignment.center, children: [for (final s in items) ArtStamp(id: s, size: (width - 10) / max(4, min(8, items.length)))]),
        );
      case 'rhythm':
        final beats = List<String>.from(d['b'] as List);
        return SizedBox(
          width: width,
          child: Wrap(alignment: WrapAlignment.center, spacing: 3, runSpacing: 3, children: [
            for (final b in beats) ArtBeatCard(beat: b, size: (width - 20) / max(4, beats.length), label: false),
          ]),
        );
      case 'coloring':
        return SizedBox(
          width: width,
          height: width,
          child: CustomPaint(painter: ArtColoringPainter(d['pic'] as String, Map<String, String>.from(d['f'] as Map), null, 0)),
        );
      default:
        return Container(
          width: width,
          height: width * 0.75,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: m1Line)),
          child: CustomPaint(painter: ArtStrokesPainter(ArtStroke.list(d['s'] as List))),
        );
    }
  }
}

// ── free drawing ────────────────────────────────────────────────────────────

class ArtStroke {
  final String color;
  final double width; // fraction of the canvas width
  final List<Offset> pts; // fractions of the canvas
  ArtStroke(this.color, this.width, this.pts);
  Map<String, dynamic> toJson() => {'c': color, 'w': width, 'p': [for (final p in pts) ...[(p.dx * 1000).round(), (p.dy * 1000).round()]]};
  static List<ArtStroke> list(List raw) => [
        for (final m in raw)
          () {
            final p = List<num>.from((m as Map)['p'] as List);
            return ArtStroke(m['c'], (m['w'] as num).toDouble(), [for (var i = 0; i + 1 < p.length; i += 2) Offset(p[i] / 1000, p[i + 1] / 1000)]);
          }(),
      ];
}

class ArtStrokesPainter extends CustomPainter {
  final List<ArtStroke> strokes;
  ArtStrokesPainter(this.strokes);
  @override
  void paint(Canvas canvas, Size s) {
    for (final st in strokes) {
      if (st.pts.isEmpty) continue;
      final p = Paint()
        ..color = artColor(st.color)
        ..strokeWidth = st.width * s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (st.pts.length == 1) {
        canvas.drawCircle(Offset(st.pts[0].dx * s.width, st.pts[0].dy * s.height), p.strokeWidth / 2, Paint()..color = p.color);
        continue;
      }
      final path = Path()..moveTo(st.pts[0].dx * s.width, st.pts[0].dy * s.height);
      for (final q in st.pts.skip(1)) {
        path.lineTo(q.dx * s.width, q.dy * s.height);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(ArtStrokesPainter o) => true;
}

// ── coloring pictures ───────────────────────────────────────────────────────

/// Regions of a picture in a 100 × 100 box, drawn in order (last = on top).
List<(String, Path)> artPicture(String id) {
  Path oval(double x, double y, double w, double h) => Path()..addOval(Rect.fromLTWH(x, y, w, h));
  Path rect(double x, double y, double w, double h) => Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(1.5)));
  switch (id) {
    case 'house':
      return [
        ('sky_sun', oval(76, 6, 18, 18)),
        ('grass', rect(2, 82, 96, 16)),
        ('wall', rect(22, 44, 56, 40)),
        ('roof', Path()
          ..moveTo(50, 14)
          ..lineTo(86, 46)
          ..lineTo(14, 46)
          ..close()),
        ('door', rect(43, 60, 14, 24)),
        ('window', Path.combine(PathOperation.union, rect(27, 52, 12, 12), rect(61, 52, 12, 12))),
      ];
    case 'butterfly':
      return [
        ('wings_top', Path.combine(PathOperation.union, oval(10, 14, 38, 38), oval(52, 14, 38, 38))),
        ('wings_bottom', Path.combine(PathOperation.union, oval(18, 48, 30, 30), oval(52, 48, 30, 30))),
        ('body', oval(45, 18, 10, 64)),
        ('dots', Path.combine(PathOperation.union, oval(22, 26, 12, 12), oval(66, 26, 12, 12))),
      ];
    default: // flower
      var petals = Path();
      for (var i = 0; i < 6; i++) {
        final a = i * pi / 3;
        petals = Path.combine(PathOperation.union, petals, oval(50 + cos(a) * 15 - 10, 32 + sin(a) * 15 - 10, 20, 20));
      }
      return [
        ('pot', Path()
          ..moveTo(32, 78)
          ..lineTo(68, 78)
          ..lineTo(62, 98)
          ..lineTo(38, 98)
          ..close()),
        ('stem', rect(48, 44, 4, 36)),
        ('leaf', Path.combine(PathOperation.union, oval(28, 56, 20, 9), oval(52, 62, 20, 9))),
        ('petals', petals),
        ('center', oval(42, 24, 16, 16)),
      ];
  }
}

const List<String> artPictureIds = ['flower', 'house', 'butterfly'];

class ArtColoringPainter extends CustomPainter {
  final String pic;
  final Map<String, String> fills;
  final String? target; // pulsing outline
  final double t;
  ArtColoringPainter(this.pic, this.fills, this.target, this.t);

  @override
  void paint(Canvas canvas, Size s) {
    final k = s.shortestSide / 100;
    canvas.save();
    canvas.translate((s.width - 100 * k) / 2, (s.height - 100 * k) / 2);
    canvas.scale(k);
    for (final (id, path) in artPicture(pic)) {
      canvas.drawPath(path, Paint()..color = fills.containsKey(id) ? artColor(fills[id]!) : Colors.white);
      canvas.drawPath(path, Paint()
        ..color = const Color(0xFF3A2A4A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1);
      if (id == target) {
        canvas.drawPath(path, Paint()
          ..color = const Color(0xFF39B8F2).withOpacity(0.5 + 0.5 * sin(t * 2 * pi * 4).abs())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6);
      }
    }
    canvas.restore();
  }

  /// Which region is under [p] (canvas pixels), top-most first.
  static String? hit(String pic, Size s, Offset p) {
    final k = s.shortestSide / 100;
    final q = Offset((p.dx - (s.width - 100 * k) / 2) / k, (p.dy - (s.height - 100 * k) / 2) / k);
    for (final (id, path) in artPicture(pic).reversed) {
      if (path.contains(q)) return id;
    }
    return null;
  }

  @override
  bool shouldRepaint(ArtColoringPainter o) => true;
}
