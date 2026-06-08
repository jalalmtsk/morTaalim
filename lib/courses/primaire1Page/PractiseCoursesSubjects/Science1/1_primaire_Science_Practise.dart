import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/PractiseGames/HeavyLight/HeavyLight.dart';
import 'package:mortaalim/PractiseGames/ScienceExercice/ColorMixing.dart';
import 'package:mortaalim/PractiseGames/ScienceExercice/ScienceQuizz.dart';
import 'package:mortaalim/PractiseGames/ChooseTheColor/ChooseTheColor.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import '../../../../main.dart';
import '../../../../widgets/GetReady__Widget.dart';

// ═══════════════════════════════════════════════════════════════
//  THEME  —  Deep-space lab: midnight navy + electric cyan + acid-lime
// ═══════════════════════════════════════════════════════════════
class _T {
  static const navy      = Color(0xFF0B1120);
  static const navyMid   = Color(0xFF131D30);
  static const cyan      = Color(0xFF00D4FF);
  static const cyanDim   = Color(0xFF0099BB);
  static const lime      = Color(0xFFB8FF00);
  static const white     = Color(0xFFFFFFFF);
  static const textSoft  = Color(0xFF8BA8C8);

  static const List<Color> cardGlows = [
    Color(0xFF00D4FF), // cyan
    Color(0xFFFF6B35), // solar orange
    Color(0xFF9B5DE5), // plasma purple
    Color(0xFF00F5A0), // bio green
  ];

  static const List<String> cardEmojis = ['⚖️', '🎨', '🔬', '🧪'];
}

// ═══════════════════════════════════════════════════════════════
//  PAGE
// ═══════════════════════════════════════════════════════════════
class IndexScience1Practise extends StatefulWidget {
  const IndexScience1Practise({super.key});

  @override
  State<IndexScience1Practise> createState() => _IndexScience1PractiseState();
}

class _IndexScience1PractiseState extends State<IndexScience1Practise>
    with SingleTickerProviderStateMixin {

  late final AnimationController _headerCtrl;
  late final Animation<double>   _headerFade;
  late final Animation<Offset>   _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeIn);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() { _headerCtrl.dispose(); super.dispose(); }

  void _go(BuildContext ctx, Widget page) {
    HapticFeedback.lightImpact();
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => page));
  }

  List<Map<String, dynamic>> _exercises(BuildContext ctx) => [
    {
      'title': tr(ctx).heavyLight,
      'image': 'assets/images/UI/BackGrounds/GamePractise_BG/Science_bg/heavyandLight.jpg',
      'page':  GetReadyPage(onReadyComplete: () => Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => HeavyLightGame()))),
    },
    {
      'title': tr(ctx).findColor,
      'image': 'assets/images/UI/BackGrounds/GamePractise_BG/Science_bg/findTheColor.jpg',
      'page':  GetReadyPage(onReadyComplete: () => Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => ColorMatchingGame()))),
    },
    {
      'title': tr(ctx).scienceQuizz,
      'image': 'assets/images/UI/BackGrounds/GamePractise_BG/Science_bg/SciecneQuizz.jpg',
      'page':  GetReadyPage(onReadyComplete: () => Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => ScienceQuizExercise()))),
    },
    {
      'title': tr(ctx).colorMixing,
      'image': 'assets/images/UI/BackGrounds/GamePractise_BG/Science_bg/colorMixing.jpg',
      'page':  GetReadyPage(onReadyComplete: () => Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => ColorMixingExercise()))),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final exercises = _exercises(context);
    return Scaffold(
      backgroundColor: _T.navy,
      body: Stack(
        children: [
          // Ambient glow blobs
          Positioned(top: -60, right: -60,
              child: _GlowBlob(size: 220, color: _T.cyan.withOpacity(0.08))),
          Positioned(bottom: 80, left: -50,
              child: _GlowBlob(size: 180, color: _T.lime.withOpacity(0.06))),
          Positioned(top: 260, right: -40,
              child: _GlowBlob(size: 130, color: const Color(0xFF9B5DE5).withOpacity(0.09))),

          // Dot-grid texture overlay
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

          SafeArea(
            child: Column(
              children: [
                // Header
                SlideTransition(
                  position: _headerSlide,
                  child: FadeTransition(opacity: _headerFade, child: _buildHeader(context)),
                ),
                const SizedBox(height: 10),
                const Userstatutbar(),
                const SizedBox(height: 12),

                // Label row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      const Text('🧬', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        tr(context).exercices,
                        style: const TextStyle(
                          fontFamily: 'Fredoka One', fontSize: 17, color: _T.cyan,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _T.cyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _T.cyan.withOpacity(0.30), width: 1),
                        ),
                        child: Text(
                          '${exercises.length} ${tr(context).games}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _T.cyan),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Grid
                Expanded(
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: exercises.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.88,
                    ),
                    itemBuilder: (ctx, i) => _ScienceCard(
                      title:  exercises[i]['title'] as String,
                      image:  exercises[i]['image'] as String,
                      glow:   _T.cardGlows[i % _T.cardGlows.length],
                      emoji:  _T.cardEmojis[i % _T.cardEmojis.length],
                      index:  i,
                      onTap:  () => _go(ctx, exercises[i]['page'] as Widget),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1F3C), Color(0xFF122840)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _T.cyan.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(color: _T.cyan.withOpacity(0.20), blurRadius: 30, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); Navigator.pop(context); },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: _T.cyan.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _T.cyan.withOpacity(0.40), width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _T.cyan),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context).sciencePractise,
                  style: const TextStyle(
                    fontFamily: 'Fredoka One', fontSize: 18, color: _T.white,
                    shadows: [Shadow(color: Color(0x4400D4FF), blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '⚗️  Explore · Discover · Experiment',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _T.textSoft),
                ),
              ],
            ),
          ),
          // Animated flask icon badge
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _T.cyan.withOpacity(0.12),
              border: Border.all(color: _T.cyan.withOpacity(0.35), width: 1.5),
            ),
            alignment: Alignment.center,
            child: const Text('🔭', style: TextStyle(fontSize: 26)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SCIENCE CARD
// ═══════════════════════════════════════════════════════════════
class _ScienceCard extends StatefulWidget {
  final String       title;
  final String       image;
  final Color        glow;
  final String       emoji;
  final int          index;
  final VoidCallback onTap;

  const _ScienceCard({
    required this.title, required this.image, required this.glow,
    required this.emoji, required this.index, required this.onTap,
  });

  @override
  State<_ScienceCard> createState() => _ScienceCardState();
}

class _ScienceCardState extends State<_ScienceCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
        CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + widget.index * 70),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.scale(scale: v.clamp(0.01, 1.0), child: child),
      ),
      child: GestureDetector(
        onTapDown:   (_) => _pressCtrl.forward(),
        onTapUp:     (_) => _pressCtrl.reverse(),
        onTapCancel: ()  => _pressCtrl.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: widget.glow.withOpacity(0.45), width: 1.5),
              boxShadow: [
                BoxShadow(color: widget.glow.withOpacity(0.28), blurRadius: 20, offset: const Offset(0, 6)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // BG image
                  Image.asset(widget.image, fit: BoxFit.cover),

                  // Dark overlay with tinted gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _T.navy.withOpacity(0.82),
                          widget.glow.withOpacity(0.18),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),

                  // Top-left glow dot
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: widget.glow,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: widget.glow, blurRadius: 8)],
                      ),
                    ),
                  ),

                  // Scan-line top right badge
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: _T.navy.withOpacity(0.80),
                        shape: BoxShape.circle,
                        border: Border.all(color: widget.glow.withOpacity(0.60), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.play_arrow_rounded, size: 18, color: widget.glow),
                    ),
                  ),

                  // Content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Emoji in hexagon-ish shape
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: widget.glow.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: widget.glow.withOpacity(0.55), width: 1.5),
                          boxShadow: [BoxShadow(color: widget.glow.withOpacity(0.30), blurRadius: 14)],
                        ),
                        alignment: Alignment.center,
                        child: Text(widget.emoji, style: const TextStyle(fontSize: 26)),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(
                            fontFamily: 'Fredoka One', fontSize: 15, color: _T.white, height: 1.15,
                            shadows: [Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 6)],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: widget.glow.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: widget.glow.withOpacity(0.60), width: 1),
                        ),
                        child: Text(
                          tr(context).startGame,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: widget.glow),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  DOT GRID PAINTER (subtle lab-grid texture)
// ═══════════════════════════════════════════════════════════════
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withOpacity(0.04)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color  color;
  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: size * 0.5, spreadRadius: size * 0.1)],
    ),
  );
}