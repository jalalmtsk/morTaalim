import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/PractiseGames/MatchTheImage/MatchTheImage.dart';
import '../../../../PractiseGames/DragAndDrop/DragAndDrop.dart';
import '../../../../PractiseGames/PlayTheWord/PlayTheWord.dart';
import '../../../../PractiseGames/practiseWords.dart';
import '../../../../main.dart';
import '../../../../widgets/userStatutBar.dart';
import '../../../../widgets/GetReady__Widget.dart';

// ═══════════════════════════════════════════════════════════════
//  THEME  —  Parisian Chic: cobalt blue + rouge red + cream
// ═══════════════════════════════════════════════════════════════
class _T {
  static const cobalt      = Color(0xFF1C3FAA);
  static const cobaltLight = Color(0xFF2563EB);
  static const cobaltSoft  = Color(0xFFEFF6FF);
  static const rouge       = Color(0xFFDC2626);
  static const rougeSoft   = Color(0xFFFEE2E2);
  static const cream       = Color(0xFFFFFBF0);
  static const gold        = Color(0xFFF4C542);
  static const white       = Color(0xFFFFFFFF);
  static const textDark    = Color(0xFF1E293B);
  static const textSoft    = Color(0xFF64748B);

  static const List<Color> cardAccents = [
    Color(0xFF2563EB), // cobalt
    Color(0xFFDC2626), // rouge
    Color(0xFF059669), // vert parisien
  ];

  static const List<String> cardEmojis = ['🗣️', '🖼️', '🔗'];
}

// ═══════════════════════════════════════════════════════════════
//  PAGE
// ═══════════════════════════════════════════════════════════════
class IndexFrench1Practise extends StatefulWidget {
  const IndexFrench1Practise({super.key});

  @override
  State<IndexFrench1Practise> createState() => _IndexFrench1PractiseState();
}

class _IndexFrench1PractiseState extends State<IndexFrench1Practise>
    with SingleTickerProviderStateMixin {

  late final AnimationController _headerCtrl;
  late final Animation<double>   _headerFade;
  late final Animation<Offset>   _headerSlide;

  final List<PractiseWords> wordList = [
    PractiseWords(word: 'Bonjour', emoji: '👋', imagePath: 'assets/images/PractiseImage/bonjour.jpg',   audioPath: 'assets/audios/tts_female/bonjour_female.mp3'),
    PractiseWords(word: 'Chat',    emoji: '🐱', imagePath: 'assets/images/PractiseImage/cat.jpg',       audioPath: 'assets/audios/tts_female/chat_female.mp3'),
    PractiseWords(word: 'Chien',   emoji: '🐶', imagePath: 'assets/images/PractiseImage/chien.png',       audioPath: 'assets/audios/tts_female/chien_female.mp3'),
    PractiseWords(word: 'Maison',  emoji: '🏠', imagePath: 'assets/images/PractiseImage/maison.jpg',     audioPath: 'assets/audios/tts_female/maison_female.mp3'),
    PractiseWords(word: 'Pomme',   emoji: '🍎', imagePath: 'assets/images/PractiseImage/pomme.jpg',     audioPath: 'assets/audios/tts_female/pomme_female.mp3'),
    PractiseWords(word: 'Voiture', emoji: '🚗', imagePath: 'assets/images/PractiseImage/voiture.jpg',   audioPath: 'assets/audios/tts_female/voiture_female.mp3'),
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
      'title': tr(ctx).playTheWord,
      'image': 'assets/images/UI/BackGrounds/GamePractise_BG/Frennch_bg/playTheWordFrench.jpg',
      'page':  GetReadyPage(onReadyComplete: () => Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => PlayTheWord(words: wordList)))),
    },
    {
      'title': tr(ctx).chooseTheImage,
      'image': 'assets/images/UI/BackGrounds/GamePractise_BG/Frennch_bg/chooseTheImageFrench.jpg',
      'page':  GetReadyPage(onReadyComplete: () => Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => MatchWordToImage(words: wordList)))),
    },
    {
      'title': tr(ctx).matchTheWord,
      'image': 'assets/images/UI/BackGrounds/GamePractise_BG/Frennch_bg/matchTheWordFrench.jpg',
      'page':  GetReadyPage(onReadyComplete: () => Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => DragDropGame(items: wordList)))),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final exercises = _exercises(context);
    return Scaffold(
      backgroundColor: _T.cream,
      body: Stack(
        children: [
          // Diagonal stripe texture — très français
          Positioned.fill(child: CustomPaint(painter: _DiagonalStripePainter())),

          // Cobalt wash top-right
          Positioned(top: -70, right: -70,
              child: Container(
                width: 250, height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _T.cobalt.withOpacity(0.10),
                    Colors.transparent,
                  ]),
                ),
              )),

          // Rouge blush bottom-left
          Positioned(bottom: -50, left: -50,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _T.rouge.withOpacity(0.09),
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
                      const Text('🥐', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        tr(context).exercices,
                        style: const TextStyle(
                          fontFamily: 'Fredoka One', fontSize: 17, color: _T.cobalt,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _T.rouge.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _T.rouge.withOpacity(0.30), width: 1),
                        ),
                        child: Text(
                          '${exercises.length} ${tr(context).games}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _T.rouge),
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
                    itemBuilder: (ctx, i) => _FrenchCard(
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
          colors: [Color(0xFF1C3FAA), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: _T.cobalt.withOpacity(0.42), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); Navigator.pop(context); },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
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
                  tr(context).frenchPractise,
                  style: const TextStyle(
                    fontFamily: 'Fredoka One', fontSize: 18, color: _T.white,
                    shadows: [Shadow(color: Color(0x55000000), blurRadius: 6)],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '🗼  Écoute · Parle · Apprends',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: _T.gold.withOpacity(0.90)),
                ),
              ],
            ),
          ),
          // Eiffel badge
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(color: _T.gold.withOpacity(0.50), width: 1.5),
            ),
            alignment: Alignment.center,
            child: const Text('🇫🇷', style: TextStyle(fontSize: 26)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FRENCH CARD
// ═══════════════════════════════════════════════════════════════
class _FrenchCard extends StatefulWidget {
  final String       title;
  final String       image;
  final Color        accent;
  final String       emoji;
  final int          index;
  final VoidCallback onTap;

  const _FrenchCard({
    required this.title, required this.image, required this.accent,
    required this.emoji, required this.index, required this.onTap,
  });

  @override
  State<_FrenchCard> createState() => _FrenchCardState();
}

class _FrenchCardState extends State<_FrenchCard> with SingleTickerProviderStateMixin {
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
              border: Border.all(color: widget.accent.withOpacity(0.30), width: 1.5),
              boxShadow: [
                BoxShadow(color: widget.accent.withOpacity(0.24), blurRadius: 18, offset: const Offset(0, 6)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(widget.image, fit: BoxFit.cover),

                  // Tricolore-inspired gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.70),
                          widget.accent.withOpacity(0.32),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),

                  // Gold top-left accent flourish
                  Positioned(
                    top: 10, left: 10,
                    child: Text('✦', style: TextStyle(fontSize: 10, color: _T.gold.withOpacity(0.80))),
                  ),

                  // Play badge
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: _T.cream.withOpacity(0.92),
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
                      // Rounded-square emoji container (like a French stamp)
                      Container(
                        width: 58, height: 58,
                        decoration: BoxDecoration(
                          color: _T.cream.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: widget.accent.withOpacity(0.40), width: 1.5),
                          boxShadow: [BoxShadow(color: widget.accent.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 4))],
                        ),
                        alignment: Alignment.center,
                        child: Text(widget.emoji, style: const TextStyle(fontSize: 28)),
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
                          color: widget.accent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: widget.accent.withOpacity(0.40), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Text(
                          tr(context).startGame,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _T.white),
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
//  DIAGONAL STRIPE PAINTER (subtle Art-Deco texture)
// ═══════════════════════════════════════════════════════════════
class _DiagonalStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1C3FAA).withOpacity(0.028)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const spacing = 32.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}