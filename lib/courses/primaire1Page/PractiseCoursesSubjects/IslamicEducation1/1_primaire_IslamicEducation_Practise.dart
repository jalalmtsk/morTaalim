import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/PractiseGames/MatchTheImage/MatchTheImage.dart';
import '../../../../PractiseGames/IslamExercice/WuduGame.dart';
import '../../../../PractiseGames/PlayTheWord/PlayTheWord.dart';
import '../../../../PractiseGames/practiseWords.dart';
import '../../../../main.dart';
import '../../../../widgets/userStatutBar.dart';
import '../../../../widgets/GetReady__Widget.dart';

// ═══════════════════════════════════════════════════════════════
//  THEME  —  Sacred geometry: deep emerald + warm gold + ivory
// ═══════════════════════════════════════════════════════════════
class _T {
  static const emerald     = Color(0xFF064E3B);
  static const emeraldMid  = Color(0xFF065F46);
  static const emeraldSoft = Color(0xFF0F7A5A);
  static const gold        = Color(0xFFD4A017);
  static const goldLight   = Color(0xFFF5D97E);
  static const ivory       = Color(0xFFFFFBF2);
  static const ivoryDim    = Color(0xFFF0EAD6);
  static const white       = Color(0xFFFFFFFF);
  static const textSoft    = Color(0xFF9DB8A4);

  static const List<Color> cardAccents = [
    Color(0xFF0D9488), // teal-emerald
    Color(0xFFD4A017), // gold
    Color(0xFF7C3AED), // deep violet
  ];

  static const List<String> cardEmojis = ['🤲', '📖', '🕌'];
}

// ═══════════════════════════════════════════════════════════════
//  PAGE
// ═══════════════════════════════════════════════════════════════
class IndexIslamicEducation1Practise extends StatefulWidget {
  const IndexIslamicEducation1Practise({super.key});

  @override
  State<IndexIslamicEducation1Practise> createState() =>
      _IndexIslamicEducation1PractiseState();
}

class _IndexIslamicEducation1PractiseState
    extends State<IndexIslamicEducation1Practise>
    with SingleTickerProviderStateMixin {

  late final AnimationController _headerCtrl;
  late final Animation<double>   _headerFade;
  late final Animation<Offset>   _headerSlide;

  final List<PractiseWords> wuduStepsList = [
    PractiseWords(word: 'النية',       emoji: '🧠', imagePath: 'assets/images/PractiseImage/WuduImages/intention_wudu.png', audioPath: 'assets/audios/tts_female/Wudu/intention_female.mp3'),
    PractiseWords(word: 'غسل اليدين', emoji: '👐', imagePath: 'assets/images/PractiseImage/WuduImages/hands_wudu.png',     audioPath: 'assets/audios/tts_female/Wudu/hands_female.mp3'),
    PractiseWords(word: 'المضمضة',    emoji: '👄', imagePath: 'assets/images/PractiseImage/WuduImages/mouth_wudu.png',     audioPath: 'assets/audios/tts_female/Wudu/mouth_female.mp3'),
    PractiseWords(word: 'الاستنشاق',  emoji: '👃', imagePath: 'assets/images/PractiseImage/WuduImages/nose_wudu.png',      audioPath: 'assets/audios/tts_female/Wudu/nose_female.mp3'),
    PractiseWords(word: 'غسل الوجه',  emoji: '🧼', imagePath: 'assets/images/PractiseImage/WuduImages/face_wudu.png',      audioPath: 'assets/audios/tts_female/Wudu/face_female.mp3'),
    PractiseWords(word: 'غسل الذراعين',emoji:'💪', imagePath: 'assets/images/PractiseImage/WuduImages/arm_wudu.png',       audioPath: 'assets/audios/tts_female/Wudu/arms_female.mp3'),
    PractiseWords(word: 'مسح الرأس',  emoji: '🧴', imagePath: 'assets/images/PractiseImage/WuduImages/head_wudu.png',      audioPath: 'assets/audios/tts_female/Wudu/head_female.mp3'),
    PractiseWords(word: 'مسح الأذنين',emoji: '👂', imagePath: 'assets/images/PractiseImage/WuduImages/ear_wudu.png',       audioPath: 'assets/audios/tts_female/Wudu/ears_female.mp3'),
    PractiseWords(word: 'غسل الرجلين',emoji: '🦶', imagePath: 'assets/images/PractiseImage/WuduImages/feet_wudu.png',      audioPath: 'assets/audios/tts_female/Wudu/feet_female.mp3'),
  ];

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
      'title': tr(ctx).wudu,
      'image': 'assets/images/UI/BackGrounds/GamePractise_BG/IslamicEducation_bg/wudueExercice.jpg',
      'page':  GetReadyPage(onReadyComplete: () => Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => WuduGame()))),
    },
    {
      'title': tr(ctx).playTheWord,
      'image': 'assets/images/UI/BackGrounds/GamePractise_BG/IslamicEducation_bg/ChooseTheImageIslamic.jpg',
      'page':  GetReadyPage(onReadyComplete: () => Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => PlayTheWord(words: wuduStepsList)))),
    },
    {
      'title': tr(ctx).chooseTheImage,
      'image': 'assets/images/UI/BackGrounds/GamePractise_BG/IslamicEducation_bg/ChooseTheImageIslamic.jpg',
      'page':  GetReadyPage(onReadyComplete: () => Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => MatchWordToImage(words: wuduStepsList)))),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final exercises = _exercises(context);
    return Scaffold(
      backgroundColor: _T.ivory,
      body: Stack(
        children: [
          // Sacred geometric background pattern
          Positioned.fill(child: CustomPaint(painter: _GeometricPatternPainter())),

          // Soft green radial wash top
          Positioned(top: -80, left: -80,
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _T.emerald.withOpacity(0.12),
                    Colors.transparent,
                  ]),
                ),
              )),

          // Gold glow bottom right
          Positioned(bottom: -60, right: -60,
              child: Container(
                width: 240, height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _T.gold.withOpacity(0.14),
                    Colors.transparent,
                  ]),
                ),
              )),

          SafeArea(
            child: Column(
              children: [
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
                      const Text('🌙', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        tr(context).exercices,
                        style: const TextStyle(
                          fontFamily: 'Fredoka One', fontSize: 17, color: _T.emerald,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _T.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _T.gold.withOpacity(0.40), width: 1),
                        ),
                        child: Text(
                          '${exercises.length} ${tr(context).games}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _T.gold),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

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
                    itemBuilder: (ctx, i) => _IslamicCard(
                      title:  exercises[i]['title'] as String,
                      image:  exercises[i]['image'] as String,
                      accent: _T.cardAccents[i % _T.cardAccents.length],
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
          colors: [Color(0xFF064E3B), Color(0xFF065F46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: _T.emerald.withOpacity(0.45), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); Navigator.pop(context); },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _T.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context).islamicPractise,
                  style: const TextStyle(
                    fontFamily: 'Fredoka One', fontSize: 18, color: _T.white,
                    shadows: [Shadow(color: Color(0x55000000), blurRadius: 6)],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '🌿  Learn · Reflect · Grow',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: _T.goldLight.withOpacity(0.85)),
                ),
              ],
            ),
          ),
          // Gold crescent badge
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _T.gold.withOpacity(0.20),
              border: Border.all(color: _T.goldLight.withOpacity(0.55), width: 1.5),
            ),
            alignment: Alignment.center,
            child: const Text('☪️', style: TextStyle(fontSize: 26)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ISLAMIC CARD
// ═══════════════════════════════════════════════════════════════
class _IslamicCard extends StatefulWidget {
  final String       title;
  final String       image;
  final Color        accent;
  final String       emoji;
  final int          index;
  final VoidCallback onTap;

  const _IslamicCard({
    required this.title, required this.image, required this.accent,
    required this.emoji, required this.index, required this.onTap,
  });

  @override
  State<_IslamicCard> createState() => _IslamicCardState();
}

class _IslamicCardState extends State<_IslamicCard> with SingleTickerProviderStateMixin {
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
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: widget.accent.withOpacity(0.35), width: 1.5),
              boxShadow: [
                BoxShadow(color: widget.accent.withOpacity(0.22), blurRadius: 18, offset: const Offset(0, 6)),
                BoxShadow(color: _T.gold.withOpacity(0.08), blurRadius: 30, spreadRadius: 2),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(widget.image, fit: BoxFit.cover),

                  // Rich layered overlay: dark + accent tint + gold shimmer
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.70),
                          widget.accent.withOpacity(0.30),
                          _T.gold.withOpacity(0.08),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 0.70, 1.0],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),

                  // Star dot top-left
                  Positioned(
                    top: 10, left: 10,
                    child: Text('✦', style: TextStyle(fontSize: 12, color: _T.gold.withOpacity(0.80))),
                  ),

                  // Play badge top-right
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: _T.ivory.withOpacity(0.90),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: widget.accent.withOpacity(0.30), blurRadius: 8)],
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.play_arrow_rounded, size: 18, color: widget.accent),
                    ),
                  ),

                  // Content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 58, height: 58,
                        decoration: BoxDecoration(
                          color: _T.ivory.withOpacity(0.92),
                          shape: BoxShape.circle,
                          border: Border.all(color: _T.gold.withOpacity(0.55), width: 1.5),
                          boxShadow: [BoxShadow(color: widget.accent.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4))],
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
                          gradient: LinearGradient(colors: [_T.gold, _T.gold.withOpacity(0.80)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: _T.gold.withOpacity(0.40), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Text(
                          tr(context).startGame,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _T.emerald),
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
//  SACRED GEOMETRIC BACKGROUND PAINTER
// ═══════════════════════════════════════════════════════════════
class _GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF064E3B).withOpacity(0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const step = 60.0;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        _drawStar(canvas, Offset(x, y), 14, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final outerX = center.dx + r * math.cos(angle);
      final outerY = center.dy + r * math.sin(angle);
      final innerX = center.dx + (r * 0.4) * math.cos(angle + math.pi / 8);
      final innerY = center.dy + (r * 0.4) * math.sin(angle + math.pi / 8);
      if (i == 0) path.moveTo(outerX, outerY);
      else path.lineTo(outerX, outerY);
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}