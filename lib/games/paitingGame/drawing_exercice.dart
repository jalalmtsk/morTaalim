import 'dart:math';
import 'dart:ui' as ui;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import 'model_logic_page.dart';

// ─────────────────────────────────────────────────────────
//  STEP: holds instruction + a painter that draws the
//  "ghost guide" overlay on the canvas
// ─────────────────────────────────────────────────────────
typedef GuidePainter = void Function(Canvas canvas, Size size);

class ExerciseStep {
  final String instruction;
  final String emoji;
  final String hint;
  final Color brushColor;
  final double brushSize;
  /// Draws a faint reference shape the child traces over
  final GuidePainter? guidePainter;

  const ExerciseStep({
    required this.instruction,
    required this.emoji,
    required this.hint,
    this.brushColor = const Color(0xFFFF3B3B),
    this.brushSize = 8,
    this.guidePainter,
  });
}

// ─────────────────────────────────────────────────────────
//  EXERCISE MODEL
// ─────────────────────────────────────────────────────────
class Exercise {
  final String title;
  final String emoji;
  final String difficulty;
  final Color accent;
  final List<ExerciseStep> steps;

  const Exercise({
    required this.title,
    required this.emoji,
    required this.difficulty,
    required this.accent,
    required this.steps,
  });
}

// ─────────────────────────────────────────────────────────
//  GUIDE PAINTERS  (faint dashed ghost lines to trace)
// ─────────────────────────────────────────────────────────
Paint _ghost(Color c) => Paint()
  ..color = c.withOpacity(0.22)
  ..strokeWidth = 3
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round;

void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
  // Use PathMetrics to draw dashes
  for (final pm in path.computeMetrics()) {
    double d = 0;
    while (d < pm.length) {
      final seg = pm.extractPath(d, d + 10);
      canvas.drawPath(seg, paint);
      d += 20;
    }
  }
}

/// Circle guide centred on canvas
void guideCircle(Canvas c, Size s) {
  final cx = s.width / 2, cy = s.height * 0.42;
  final r = s.width * 0.28;
  final p = _ghost(const Color(0xFFFF9800));
  _drawDashedPath(c, Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)), p);
  // Label
  _paintGuideLabel(c, s, 'Trace the circle ⬆️', Offset(cx, cy + r + 22));
}

void guideSunRays(Canvas c, Size s) {
  guideCircle(c, s);
  final cx = s.width / 2, cy = s.height * 0.42;
  final r1 = s.width * 0.28, r2 = s.width * 0.42;
  final p = _ghost(const Color(0xFFFFCC02));
  for (int i = 0; i < 8; i++) {
    final angle = i * pi / 4 - pi / 2;
    _drawDashedPath(c, Path()
      ..moveTo(cx + cos(angle) * r1, cy + sin(angle) * r1)
      ..lineTo(cx + cos(angle) * r2, cy + sin(angle) * r2), p);
  }
  _paintGuideLabel(c, s, 'Add 8 rays ✨', Offset(cx, cy + r2 + 22));
}

void guideSmiley(Canvas c, Size s) {
  final cx = s.width / 2, cy = s.height * 0.42;
  final p = _ghost(const Color(0xFF333333));
  // eyes
  c.drawCircle(Offset(cx - 18, cy - 14), 5, p..style = PaintingStyle.fill);
  c.drawCircle(Offset(cx + 18, cy - 14), 5, p);
  // smile arc
  final smilePath = Path()
    ..addArc(Rect.fromCenter(center: Offset(cx, cy + 4), width: 48, height: 30), 0.2, pi - 0.4);
  _drawDashedPath(c, smilePath, p..style = PaintingStyle.stroke);
  _paintGuideLabel(c, s, 'Add a face 😊', Offset(cx, cy + 68));
}

void guideRainbowArch(Canvas c, Size s) {
  final cx = s.width / 2, bottom = s.height * 0.75;
  final colors = [
    const Color(0xFFFF0000), const Color(0xFFFF7700),
    const Color(0xFFFFFF00), const Color(0xFF00CC00),
    const Color(0xFF0000FF), const Color(0xFF8B00FF),
  ];
  for (int i = 0; i < colors.length; i++) {
    final r = s.width * (0.48 - i * 0.06);
    _drawDashedPath(c,
      Path()..addArc(Rect.fromCenter(center: Offset(cx, bottom), width: r * 2, height: r * 1.1), pi, pi),
      _ghost(colors[i]),
    );
  }
  _paintGuideLabel(c, s, 'Trace each arch 🌈', Offset(cx, bottom - s.width * 0.52));
}

void guideClouds(Canvas c, Size s) {
  guideRainbowArch(c, s);
  final p = _ghost(const Color(0xFF90CAF9));
  void cloud(double cx, double cy) {
    final path = Path();
    for (final o in [Offset(-20, 0), Offset(0, -10), Offset(20, 0), Offset(10, 8), Offset(-10, 8)]) {
      path.addOval(Rect.fromCenter(center: Offset(cx + o.dx, cy + o.dy), width: 36, height: 28));
    }
    _drawDashedPath(c, path, p);
  }
  cloud(s.width * 0.12, s.height * 0.75);
  cloud(s.width * 0.88, s.height * 0.75);
  _paintGuideLabel(c, s, 'Add clouds at each end ☁️', Offset(s.width / 2, s.height * 0.88));
}

void guideCatHead(Canvas c, Size s) {
  final cx = s.width / 2, cy = s.height * 0.38;
  final r = s.width * 0.26;
  final p = _ghost(const Color(0xFFFF9800));
  _drawDashedPath(c, Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)), p);
  // ears
  for (final side in [-1.0, 1.0]) {
    final earPath = Path()
      ..moveTo(cx + side * r * 0.5, cy - r * 0.75)
      ..lineTo(cx + side * r * 0.9, cy - r * 1.35)
      ..lineTo(cx + side * r * 1.0, cy - r * 0.65)
      ..close();
    _drawDashedPath(c, earPath, p);
  }
  _paintGuideLabel(c, s, 'Draw the head + ears 🐱', Offset(cx, cy + r + 24));
}

void guideCatFace(Canvas c, Size s) {
  guideCatHead(c, s);
  final cx = s.width / 2, cy = s.height * 0.38;
  final p = _ghost(const Color(0xFF333333));
  // eyes
  c.drawOval(Rect.fromCenter(center: Offset(cx - 22, cy - 10), width: 22, height: 16), p..style = PaintingStyle.fill);
  c.drawOval(Rect.fromCenter(center: Offset(cx + 22, cy - 10), width: 22, height: 16), p);
  // nose triangle
  final nosePath = Path()
    ..moveTo(cx, cy + 4)
    ..lineTo(cx - 8, cy + 16)
    ..lineTo(cx + 8, cy + 16)
    ..close();
  _drawDashedPath(c, nosePath, p..style = PaintingStyle.stroke);
  // mouth
  _drawDashedPath(c, Path()
    ..moveTo(cx - 14, cy + 22)
    ..quadraticBezierTo(cx, cy + 30, cx + 14, cy + 22), p);
  _paintGuideLabel(c, s, 'Draw the face details 😸', Offset(cx, cy + 72));
}

void guideCatBody(Canvas c, Size s) {
  final cx = s.width / 2, cy = s.height * 0.65;
  final p = _ghost(const Color(0xFFFF9800));
  _drawDashedPath(c, Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: s.width * 0.44, height: s.height * 0.28)), p);
  // tail
  final tailPath = Path()
    ..moveTo(cx + s.width * 0.22, cy - 10)
    ..quadraticBezierTo(cx + s.width * 0.4, cy - 40, cx + s.width * 0.38, cy - 80);
  _drawDashedPath(c, tailPath, p);
  _paintGuideLabel(c, s, 'Add the body + tail 🐾', Offset(cx, cy + s.height * 0.16));
}

void guideHouseBox(Canvas c, Size s) {
  final l = s.width * 0.15, r2 = s.width * 0.85;
  final top = s.height * 0.38, bottom = s.height * 0.80;
  final p = _ghost(const Color(0xFF795548));
  _drawDashedPath(c, Path()
    ..moveTo(l, top)..lineTo(r2, top)..lineTo(r2, bottom)..lineTo(l, bottom)..close(), p);
  _paintGuideLabel(c, s, 'Draw the walls ⬛', Offset(s.width / 2, s.height * 0.88));
}

void guideHouseRoof(Canvas c, Size s) {
  guideHouseBox(c, s);
  final cx = s.width / 2;
  final p = _ghost(const Color(0xFFFF5722));
  _drawDashedPath(c, Path()
    ..moveTo(s.width * 0.08, s.height * 0.38)
    ..lineTo(cx, s.height * 0.12)
    ..lineTo(s.width * 0.92, s.height * 0.38), p);
  _paintGuideLabel(c, s, 'Add the roof 🔺', Offset(cx, s.height * 0.06));
}

void guideHouseDoorWindows(Canvas c, Size s) {
  guideHouseRoof(c, s);
  final cx = s.width / 2;
  final p = _ghost(const Color(0xFF1565C0));
  // door
  _drawDashedPath(c, Path()
    ..addRect(Rect.fromLTWH(cx - 22, s.height * 0.56, 44, s.height * 0.24)), p);
  // windows
  for (final wx in [s.width * 0.26, s.width * 0.74]) {
    _drawDashedPath(c, Path()
      ..addRect(Rect.fromCenter(center: Offset(wx, s.height * 0.55), width: 44, height: 40)), p);
  }
  _paintGuideLabel(c, s, 'Add door + windows 🪟', Offset(cx, s.height * 0.88));
}

void guideButterflybody(Canvas c, Size s) {
  final cx = s.width / 2, cy = s.height * 0.5;
  final p = _ghost(const Color(0xFF7B1FA2));
  _drawDashedPath(c, Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: 22, height: 70)), p);
  _paintGuideLabel(c, s, 'Draw the body 🫘', Offset(cx, cy + 52));
}

void guideButterflyWings(Canvas c, Size s) {
  guideButterflybody(c, s);
  final cx = s.width / 2, cy = s.height * 0.5;
  final p = _ghost(const Color(0xFFE91E63));
  for (final side in [-1.0, 1.0]) {
    // top wing
    _drawDashedPath(c, Path()
      ..moveTo(cx, cy - 20)
      ..quadraticBezierTo(cx + side * s.width * 0.42, cy - 70, cx + side * s.width * 0.40, cy + 5)
      ..quadraticBezierTo(cx + side * s.width * 0.15, cy + 15, cx, cy - 10), p);
    // bottom wing
    _drawDashedPath(c, Path()
      ..moveTo(cx, cy + 10)
      ..quadraticBezierTo(cx + side * s.width * 0.32, cy + 60, cx + side * s.width * 0.24, cy + 85)
      ..quadraticBezierTo(cx + side * s.width * 0.1, cy + 70, cx, cy + 20), p);
  }
  _paintGuideLabel(c, s, 'Add the wings 🦋', Offset(cx, s.height * 0.08));
}

void _paintGuideLabel(Canvas canvas, Size s, String text, Offset pos) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: const TextStyle(
      fontSize: 13, color: Color(0x99555555), fontWeight: FontWeight.bold,
    )),
    textDirection: ui.TextDirection.ltr,
  )..layout(maxWidth: s.width - 20);
  tp.paint(canvas, Offset((s.width - tp.width) / 2, pos.dy.clamp(4, s.height - 20)));
}

// ─────────────────────────────────────────────────────────
//  EXERCISE DATA
// ─────────────────────────────────────────────────────────
final exercises = [
  Exercise(
    title: 'Draw a Sunshine!', emoji: '☀️', difficulty: 'Easy',
    accent: const Color(0xFFFFCC02),
    steps: [
      ExerciseStep(
        instruction: 'Trace the circle in the middle.',
        emoji: '⭕', hint: 'Follow the dashed line — go slow!',
        brushColor: Color(0xFFFFD600), brushSize: 10,
        guidePainter: guideCircle,
      ),
      ExerciseStep(
        instruction: 'Draw 8 rays going outward.',
        emoji: '✨', hint: 'Start from the circle edge and draw outward lines!',
        brushColor: Color(0xFFFF9800), brushSize: 9,
        guidePainter: guideSunRays,
      ),
      ExerciseStep(
        instruction: 'Add a smiley face to your sun.',
        emoji: '😊', hint: 'Two dots for eyes, a curved line for the smile!',
        brushColor: Color(0xFFFF6D00), brushSize: 7,
        guidePainter: guideSmiley,
      ),
    ],
  ),
  Exercise(
    title: 'Draw a Rainbow!', emoji: '🌈', difficulty: 'Easy',
    accent: const Color(0xFFE040FB),
    steps: [
      ExerciseStep(
        instruction: 'Trace the 6 rainbow arches.',
        emoji: '〰️', hint: 'Each arch is a different color — follow them one by one!',
        brushColor: Color(0xFFFF3B3B), brushSize: 10,
        guidePainter: guideRainbowArch,
      ),
      ExerciseStep(
        instruction: 'Add fluffy clouds at both ends.',
        emoji: '☁️', hint: 'Draw overlapping circles to make a cloud!',
        brushColor: Color(0xFF90CAF9), brushSize: 8,
        guidePainter: guideClouds,
      ),
    ],
  ),
  Exercise(
    title: 'Draw a Cute Cat!', emoji: '🐱', difficulty: 'Medium',
    accent: const Color(0xFFFF9800),
    steps: [
      ExerciseStep(
        instruction: 'Trace the head and pointy ears.',
        emoji: '🐾', hint: 'Follow the circle, then add the two triangles on top!',
        brushColor: Color(0xFFFF9800), brushSize: 9,
        guidePainter: guideCatHead,
      ),
      ExerciseStep(
        instruction: 'Draw the eyes, nose and mouth.',
        emoji: '😺', hint: 'Two ovals for eyes, a small triangle for the nose!',
        brushColor: Color(0xFF333333), brushSize: 7,
        guidePainter: guideCatFace,
      ),
      ExerciseStep(
        instruction: 'Add the body and curly tail.',
        emoji: '🐈', hint: 'Big oval for the body, curvy line for the tail!',
        brushColor: Color(0xFFFF9800), brushSize: 9,
        guidePainter: guideCatBody,
      ),
    ],
  ),
  Exercise(
    title: 'Draw a House!', emoji: '🏠', difficulty: 'Medium',
    accent: const Color(0xFF43A047),
    steps: [
      ExerciseStep(
        instruction: 'Trace the square walls.',
        emoji: '⬜', hint: 'Four straight lines — keep it tall!',
        brushColor: Color(0xFF795548), brushSize: 9,
        guidePainter: guideHouseBox,
      ),
      ExerciseStep(
        instruction: 'Add the triangle roof.',
        emoji: '🔺', hint: 'Two lines meeting at a point above the walls!',
        brushColor: Color(0xFFFF5722), brushSize: 9,
        guidePainter: guideHouseRoof,
      ),
      ExerciseStep(
        instruction: 'Draw the door and windows.',
        emoji: '🪟', hint: 'Rectangle door in the centre, square windows on the sides!',
        brushColor: Color(0xFF1565C0), brushSize: 7,
        guidePainter: guideHouseDoorWindows,
      ),
    ],
  ),
  Exercise(
    title: 'Draw a Butterfly!', emoji: '🦋', difficulty: 'Hard',
    accent: const Color(0xFFE91E63),
    steps: [
      ExerciseStep(
        instruction: 'Draw the thin oval body.',
        emoji: '🫘', hint: 'Tall and narrow — like a bean standing up!',
        brushColor: Color(0xFF7B1FA2), brushSize: 8,
        guidePainter: guideButterflybody,
      ),
      ExerciseStep(
        instruction: 'Add the four wings.',
        emoji: '🦋', hint: 'Top wings are bigger, bottom wings are rounder!',
        brushColor: Color(0xFFE91E63), brushSize: 9,
        guidePainter: guideButterflyWings,
      ),
    ],
  ),
];

Color _diffColor(String d) {
  switch (d) {
    case 'Easy': return const Color(0xFF43E97B);
    case 'Medium': return const Color(0xFFFFCC02);
    default: return const Color(0xFFFF6584);
  }
}

// ─────────────────────────────────────────────────────────
//  EXERCISES LIST PAGE
// ─────────────────────────────────────────────────────────
class DrawingExercisesPage extends StatelessWidget {
  const DrawingExercisesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      body: CustomScrollView(slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          expandedHeight: 130, pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('✏️ Drawing Exercises',
                style: TextStyle(fontFamily: 'ComicSansMS', fontSize: 17, fontWeight: FontWeight.w900)),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3F8EFC)]),
              ),
              child: const Center(child: Text('🎓', style: TextStyle(fontSize: 50))),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (ctx, i) {
              final ex = exercises[i];
              return _ExerciseCard(exercise: ex, index: i,
                onTap: () => Navigator.push(ctx, MaterialPageRoute(
                  builder: (_) => ExerciseDrawPage(exercise: ex),
                )),
              );
            },
            childCount: exercises.length,
          )),
        ),
      ]),
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final int index;
  final VoidCallback onTap;
  const _ExerciseCard({required this.exercise, required this.index, required this.onTap});
  @override State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0.25, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: 80 * widget.index), () { if (mounted) _anim.forward(); });
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => FadeTransition(opacity: _fade, child: SlideTransition(position: _slide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 110),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: ex.accent.withOpacity(0.3), width: 1.5),
                boxShadow: [BoxShadow(color: ex.accent.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(children: [
                Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    color: ex.accent.withOpacity(0.12), shape: BoxShape.circle,
                  ),
                  child: Center(child: Text(ex.emoji, style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ex.title, style: const TextStyle(
                    fontFamily: 'ComicSansMS', fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF2D2D2D),
                  )),
                  const SizedBox(height: 5),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: _diffColor(ex.difficulty).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(ex.difficulty, style: TextStyle(
                        fontFamily: 'ComicSansMS', fontSize: 11, fontWeight: FontWeight.bold,
                        color: _diffColor(ex.difficulty),
                      )),
                    ),
                    const SizedBox(width: 8),
                    Text('${ex.steps.length} steps', style: const TextStyle(
                      fontFamily: 'ComicSansMS', fontSize: 11, color: Color(0xFF888888),
                    )),
                  ]),
                ])),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: ex.accent.withOpacity(0.6)),
              ]),
            ),
          ),
        ),
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  EXERCISE DRAW PAGE  — the child actually draws here
// ─────────────────────────────────────────────────────────
class ExerciseDrawPage extends StatefulWidget {
  final Exercise exercise;
  const ExerciseDrawPage({required this.exercise, Key? key}) : super(key: key);
  @override State<ExerciseDrawPage> createState() => _ExerciseDrawPageState();
}

class _ExerciseDrawPageState extends State<ExerciseDrawPage> with TickerProviderStateMixin {
  int _step = 0;
  bool _done = false;
  late ConfettiController _confetti;
  late CanvasController _canvas;
  late AnimationController _stepAnim;
  late Animation<double> _stepFade;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _canvas = CanvasController(backgroundColor: Colors.white);
    _stepAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _stepFade = CurvedAnimation(parent: _stepAnim, curve: Curves.easeOut);
    _stepAnim.forward();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _canvas.dispose();
    _stepAnim.dispose();
    super.dispose();
  }

  ExerciseStep get _cur => widget.exercise.steps[_step];

  void _next() {
    if (_step < widget.exercise.steps.length - 1) {
      setState(() {
        _step++;
        // Keep the drawing — child keeps everything they drew
        _stepAnim.reset();
        _stepAnim.forward();
      });
    } else {
      setState(() => _done = true);
      _confetti.play();
    }
  }

  void _prev() {
    if (_step > 0) {
      setState(() {
        _step--;
        _stepAnim.reset();
        _stepAnim.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    return Scaffold(
      backgroundColor: Colors.white,
      body: _done ? _buildDone(ex) : _buildLesson(ex),
    );
  }

  Widget _buildLesson(Exercise ex) {
    return Stack(children: [
      // ── Confetti ──────────────────────────────────────
      Align(alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 35,
          colors: [Colors.pink, Colors.yellow, Colors.cyan, Colors.purple, Colors.green],
        ),
      ),

      Column(children: [
        // ── Header ─────────────────────────────────────
        SafeArea(child: _buildHeader(ex)),
        // ── Progress bar ───────────────────────────────
        _buildProgress(ex),
        const SizedBox(height: 6),
        // ── Instruction card ───────────────────────────
        FadeTransition(opacity: _stepFade, child: _buildInstruction()),
        const SizedBox(height: 8),
        // ── Canvas ─────────────────────────────────────
        Expanded(child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: _buildCanvas(),
        )),
        // ── Bottom controls ────────────────────────────
        _buildControls(ex),
      ]),
    ]);
  }

  Widget _buildHeader(Exercise ex) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ex.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.arrow_back_ios_new, size: 18, color: ex.accent),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${ex.emoji} ${ex.title}', style: const TextStyle(
            fontFamily: 'ComicSansMS', fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF2D2D2D),
          )),
          Text('Step ${_step + 1} of ${ex.steps.length}', style: const TextStyle(
            fontFamily: 'ComicSansMS', fontSize: 11, color: Color(0xFF999999),
          )),
        ])),
        // Stars
        Row(children: List.generate(ex.steps.length, (i) => Icon(
          i <= _step ? Icons.star_rounded : Icons.star_border_rounded,
          color: const Color(0xFFFFCC02), size: 20,
        ))),
      ]),
    );
  }

  Widget _buildProgress(Exercise ex) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: (_step + 1) / ex.steps.length,
          backgroundColor: Colors.black.withOpacity(0.07),
          valueColor: AlwaysStoppedAnimation(ex.accent),
          minHeight: 7,
        ),
      ),
    );
  }

  Widget _buildInstruction() {
    final step = _cur;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: widget.exercise.accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: widget.exercise.accent.withOpacity(0.25), width: 1.5),
        ),
        child: Row(children: [
          Text(step.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(step.instruction, style: const TextStyle(
              fontFamily: 'ComicSansMS', fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF2D2D2D),
            )),
            const SizedBox(height: 3),
            Row(children: [
              const Text('💡 ', style: TextStyle(fontSize: 12)),
              Expanded(child: Text(step.hint, style: TextStyle(
                fontFamily: 'ComicSansMS', fontSize: 11,
                color: widget.exercise.accent, fontWeight: FontWeight.w700,
              ))),
            ]),
          ])),
        ]),
      ),
    );
  }

  Widget _buildCanvas() {
    final step = _cur;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.exercise.accent.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: LayoutBuilder(builder: (ctx, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          _canvas.setSize(size);
          return GestureDetector(
            onPanStart: (d) => _canvas.beginStroke(
              color: step.brushColor, strokeWidth: step.brushSize,
              brushType: BrushType.normal, isEraser: false,
              point: d.localPosition,
            ),
            onPanUpdate: (d) => _canvas.addPoint(d.localPosition),
            onPanEnd: (_) => _canvas.endStroke(),
            child: AnimatedBuilder(
              animation: _canvas,
              builder: (_, __) => CustomPaint(
                painter: _GuidedCanvasPainter(
                  cachedPicture: _canvas.cachedPicture,
                  activeStroke: _canvas.activeStroke,
                  guidePainter: step.guidePainter,
                ),
                size: size,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildControls(Exercise ex) {
    final isLast = _step == ex.steps.length - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).padding.bottom + 12),
      child: Row(children: [
        // Undo
        GestureDetector(
          onTap: () => setState(() => _canvas.undo()),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _canvas.canUndo ? const Color(0xFF6C63FF) : Colors.grey.shade200,
              shape: BoxShape.circle,
              boxShadow: _canvas.canUndo
                  ? [const BoxShadow(color: Color(0x556C63FF), blurRadius: 8)]
                  : [],
            ),
            child: Icon(Icons.undo_rounded,
                color: _canvas.canUndo ? Colors.white : Colors.grey.shade400, size: 22),
          ),
        ),
        const SizedBox(width: 8),
        // Clear this step
        GestureDetector(
          onTap: () => setState(() => _canvas.clear()),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.orange.shade100, shape: BoxShape.circle,
            ),
            child: Icon(Icons.refresh_rounded, color: Colors.orange.shade700, size: 22),
          ),
        ),
        const Spacer(),
        if (_step > 0) ...[
          _NavBtn(label: '← Back', color: Colors.grey.shade200, textColor: const Color(0xFF555555), onTap: _prev),
          const SizedBox(width: 10),
        ],
        _NavBtn(
          label: isLast ? '🎉 Finish!' : 'Next →',
          color: ex.accent,
          textColor: Colors.white,
          onTap: _next,
          wide: true,
        ),
      ]),
    );
  }

  Widget _buildDone(Exercise ex) {
    return Stack(children: [
      Align(alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 50,
          colors: [Colors.pink, Colors.yellow, Colors.cyan, Colors.purple, Colors.green, Colors.orange],
        ),
      ),
      Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(ex.emoji, style: const TextStyle(fontSize: 90)),
          const SizedBox(height: 18),
          const Text('🎉 Amazing!', style: TextStyle(
            fontFamily: 'ComicSansMS', fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF2D2D2D),
          )),
          const SizedBox(height: 8),
          Text('You drew: ${ex.title}', style: const TextStyle(
            fontFamily: 'ComicSansMS', fontSize: 17, color: Color(0xFF666666),
          )),
          const SizedBox(height: 22),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) =>
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + i * 220),
                curve: Curves.elasticOut,
                builder: (_, v, __) => Transform.scale(scale: v,
                    child: const Padding(padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.star_rounded, color: Color(0xFFFFCC02), size: 56))),
              ),
          )),
          const SizedBox(height: 32),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _NavBtn(label: '🎨 Try Another!', color: ex.accent, textColor: Colors.white,
                onTap: () => Navigator.pop(context), wide: true),
          ]),
        ]),
      )),
    ]);
  }
}

// ─────────────────────────────────────────────────────────
//  GUIDED CANVAS PAINTER
// ─────────────────────────────────────────────────────────
class _GuidedCanvasPainter extends CustomPainter {
  final ui.Picture? cachedPicture;
  final DrawStroke? activeStroke;
  final GuidePainter? guidePainter;

  const _GuidedCanvasPainter({this.cachedPicture, this.activeStroke, this.guidePainter});

  @override
  void paint(Canvas canvas, Size size) {
    // White background
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    // Ghost guide underneath
    if (guidePainter != null) guidePainter!(canvas, size);
    // Committed strokes
    if (cachedPicture != null) canvas.drawPicture(cachedPicture!);
    // Active stroke
    if (activeStroke != null && activeStroke!.points.isNotEmpty) {
      DrawingPainter.paintStrokeOnCanvas(canvas, activeStroke!);
    }
  }

  @override
  bool shouldRepaint(_GuidedCanvasPainter old) =>
      old.cachedPicture != cachedPicture ||
          old.activeStroke != activeStroke ||
          old.guidePainter != guidePainter;
}

// ─────────────────────────────────────────────────────────
//  NAV BUTTON
// ─────────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final String label;
  final Color color, textColor;
  final VoidCallback onTap;
  final bool wide;
  const _NavBtn({required this.label, required this.color, required this.textColor,
    required this.onTap, this.wide = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: wide ? 160 : null,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Center(child: Text(label, style: TextStyle(
        fontFamily: 'ComicSansMS', fontSize: 15, fontWeight: FontWeight.w900, color: textColor,
      ))),
    ),
  );
}