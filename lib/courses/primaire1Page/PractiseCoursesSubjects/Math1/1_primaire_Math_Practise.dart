import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/PractiseGames/MathExercice/CountObject.dart';
import 'package:mortaalim/PractiseGames/MathExercice/FindLargestNumber.dart';
import 'package:mortaalim/PractiseGames/MathExercice/MathAddition.dart';
import 'package:mortaalim/PractiseGames/MathExercice/MathSubstraction.dart';
import 'package:mortaalim/PractiseGames/MathExercice/MissingNumber.dart';
import 'package:mortaalim/PractiseGames/MathExercice/NumberComparison.dart';
import 'package:mortaalim/PractiseGames/MathExercice/OddNumbers.dart';
import 'package:mortaalim/PractiseGames/MathExercice/TargetNumber.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';

import '../../../../main.dart';
import '../../../../widgets/GetReady__Widget.dart';

// ═══════════════════════════════════════════════════════════════
//  THEME
// ═══════════════════════════════════════════════════════════════
class _T {
  static const orange      = Color(0xFFEA580C);
  static const orangeLight = Color(0xFFFFF7ED);
  static const orangeMid   = Color(0xFFFDBA74);
  static const amber       = Color(0xFFF59E0B);
  static const teal        = Color(0xFF0D9488);
  static const white       = Color(0xFFFFFFFF);

  static const List<Color> cardAccents = [
    Color(0xFF8B5CF6),
    Color(0xFFF97316),
    Color(0xFF3B82F6),
    Color(0xFF0D9488),
    Color(0xFFEC4899),
    Color(0xFF22C55E),
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
  ];

  static const List<String> cardEmojis = [
    '❓', '🏆', '➕', '➖', '🔢', '⚖️', '🔀', '🎯',
  ];
}

// ═══════════════════════════════════════════════════════════════
//  PAGE
// ═══════════════════════════════════════════════════════════════
class IndexMath1Practise extends StatefulWidget {
  const IndexMath1Practise({super.key});

  @override
  State<IndexMath1Practise> createState() => _IndexMath1PractiseState();
}

class _IndexMath1PractiseState extends State<IndexMath1Practise>
    with SingleTickerProviderStateMixin {

  late final AnimationController _headerCtrl;
  late final Animation<Offset>   _headerSlide;
  late final Animation<double>   _headerFade;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  void _go(BuildContext ctx, Widget page) {
    HapticFeedback.lightImpact();
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => page));
  }

  List<Map<String, dynamic>> _exercises(BuildContext ctx) => [
    {
      'title': tr(ctx).missingNumber,
      'image': 'assets/images/UI/BackGrounds/GamePractise_BG/Math_bg/MissingNumber_bg.png',
      'page': GetReadyPage(onReadyComplete: () {
        Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => MissingNumberExercise()));
      }),
    },
    {
      'title': tr(ctx).findLargest,
      'image': 'assets/images/UI/BackGrounds/GamePractise_BG/Math_bg/Largest_bg.png',
      'page': GetReadyPage(onReadyComplete: () {
        Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => FindLargestNumberExercise()));
      }),
    },
    {
      'title': tr(ctx).addition,
      'image': 'assets/images/UI/BackGrounds/GamePractise_BG/Math_bg/Addition_bg.png',
      'page': GetReadyPage(onReadyComplete: () {
        Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => MathAdditionExercise()));
      }),
    },
    {
      'title': tr(ctx).subtraction,
      'image': 'assets/images/UI/BackGrounds/GamePractise_BG/Math_bg/SubStraction_bg.png',
      'page': GetReadyPage(onReadyComplete: () {
        Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => MathSubtractionExercise()));
      }),
    },
    {
      'title': tr(ctx).countObjects,
      'image': 'assets/images/UI/BackGrounds/GamePractise_BG/Math_bg/CountObject_bg.png',
      'page': GetReadyPage(onReadyComplete: () {
        Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => CountExercise()));
      }),
    },
    {
      'title': tr(ctx).compareNumbers,
      'image': 'assets/images/UI/BackGrounds/GamePractise_BG/Math_bg/GreaterSmallerThan_bg.png',
      'page': GetReadyPage(onReadyComplete: () {
        Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => NumberComparisonGame()));
      }),
    },
    {
      'title': tr(ctx).oddNumbers,
      'image': 'assets/images/UI/BackGrounds/GamePractise_BG/Math_bg/OddNumber_bg.png',
      'page': GetReadyPage(onReadyComplete: () {
        Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => EvenOddExercise()));
      }),
    },
    {
      'title': tr(ctx).targetNumber,
      'image': 'assets/images/UI/BackGrounds/GamePractise_BG/Math_bg/TargetNumber_bg.png',
      'page': GetReadyPage(onReadyComplete: () {
        Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => TargetNumberExercise()));
      }),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final exercises = _exercises(context);

    return Scaffold(
      backgroundColor: _T.orangeLight,
      body: Stack(
        children: [
          // Decorative blobs — purely visual, pointer-events ignored
          Positioned(top: -50, right: -50,
              child: _Blob(size: 180, color: _T.amber.withOpacity(0.18))),
          Positioned(top: 200, left: -40,
              child: _Blob(size: 120, color: _T.teal.withOpacity(0.12))),
          Positioned(bottom: 60, right: -30,
              child: _Blob(size: 140, color: _T.orange.withOpacity(0.10))),

          SafeArea(
            child: Column(
              children: [
                // Animated header
                SlideTransition(
                  position: _headerSlide,
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: _buildHeader(context),
                  ),
                ),

                const SizedBox(height: 8),
                const Userstatutbar(),
                const SizedBox(height: 10),

                // Section label row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      const Text('🎮', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        tr(context).exercices,
                        style: const TextStyle(
                          fontFamily: 'Fredoka One',
                          fontSize: 18,
                          color: _T.orange,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _T.orangeMid.withOpacity(0.40),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${exercises.length} ${tr(context).games}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _T.orange,
                          ),
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
                    itemBuilder: (ctx, i) => _ExerciseCard(
                      title:  exercises[i]['title'] as String,
                      image:  exercises[i]['image'] as String,
                      page:   exercises[i]['page']  as Widget,
                      accent: _T.cardAccents[i % _T.cardAccents.length],
                      emoji:  _T.cardEmojis[i  % _T.cardEmojis.length],
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
          colors: [Color(0xFFF97316), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _T.orange.withOpacity(0.38),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: _T.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tr(context).letsPractiseMath}',
                  style: const TextStyle(
                    fontFamily: 'Fredoka One',
                    fontSize: 16,
                    color: _T.white,
                    shadows: [Shadow(color: Color(0x33000000), blurRadius: 6)],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tr(context).funGamesToBeStar,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.88),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🦁', style: TextStyle(fontSize: 28)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  EXERCISE CARD
//  - TweenAnimationBuilder for entry (self-contained, no dispose)
//  - One AnimationController for press-scale only
// ═══════════════════════════════════════════════════════════════
class _ExerciseCard extends StatefulWidget {
  final String       title;
  final String       image;
  final Widget       page;
  final Color        accent;
  final String       emoji;
  final int          index;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.title,
    required this.image,
    required this.page,
    required this.accent,
    required this.emoji,
    required this.index,
    required this.onTap,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard>
    with SingleTickerProviderStateMixin {

  late final AnimationController _pressCtrl;
  late final Animation<double>   _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TweenAnimationBuilder owns its own internal ticker — zero risk of leak.
    // Stagger is achieved by making the duration longer for later cards.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + widget.index * 55),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.scale(scale: v.clamp(0.01, 1.0), child: child),
      ),
      // child is built once and reused across animation frames
      child: GestureDetector(
        onTapDown:   (_) => _pressCtrl.forward(),
        onTapUp:     (_) => _pressCtrl.reverse(),
        onTapCancel: ()  => _pressCtrl.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pressScale,
          builder: (_, child) =>
              Transform.scale(scale: _pressScale.value, child: child),
          child: _CardContent(
            title:  widget.title,
            image:  widget.image,
            accent: widget.accent,
            emoji:  widget.emoji,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CARD VISUAL — pure StatelessWidget, nothing to dispose
// ═══════════════════════════════════════════════════════════════
class _CardContent extends StatelessWidget {
  final String title;
  final String image;
  final Color  accent;
  final String emoji;

  const _CardContent({
    required this.title,
    required this.image,
    required this.accent,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.asset(image, fit: BoxFit.cover),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.62),
                    accent.withOpacity(0.28),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),

            // Accent dot — top left
            Positioned(
              top: 10, left: 10,
              child: Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: accent.withOpacity(0.55), blurRadius: 6),
                  ],
                ),
              ),
            ),

            // Play button — top right
            Positioned(
              top: 8, right: 8,
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.88),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: accent.withOpacity(0.30), blurRadius: 8),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(Icons.play_arrow_rounded, size: 20, color: accent),
              ),
            ),

            // Centre content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Emoji circle
                Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.90),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.38),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),

                const SizedBox(height: 10),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                      fontFamily: 'Fredoka One',
                      fontSize: 16,
                      color: _T.white,
                      height: 1.15,
                      shadows: [
                        Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 5),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // "Play!" pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child:  Text(
                    tr(context).startGame,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _T.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════════
class _Blob extends StatelessWidget {
  final double size;
  final Color  color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}