import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';

import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';
import 'Tools/AnimatedHeart.dart';

// ═══════════════════════════════════════════════════════════════
//  THEME — ☀️ RAINBOW CARNIVAL
//  Vivid gradient sky, confetti colours, candy planet buttons,
//  answer reveal pop, asteroid burst on wrong.
// ═══════════════════════════════════════════════════════════════
class _S {
  // Sky gradient stops — tropical sunrise
  static const skyTop    = Color(0xFF6C63FF); // violet
  static const skyMid    = Color(0xFFFF6B9D); // hot pink
  static const skyBot    = Color(0xFFFFCC02); // golden yellow

  // Card / HUD glass
  static const glass     = Color(0x22FFFFFF);
  static const glassBdr  = Color(0x55FFFFFF);

  static const white     = Color(0xFFFFFFFF);
  static const dark      = Color(0xFF1A1235);

  // Feedback
  static const lime      = Color(0xFF39FF14);
  static const rose      = Color(0xFFFF2D55);
  static const gold      = Color(0xFFFFD700);

  // Number boxes in the sequence — each index a unique vivid hue
  static const List<Color> seqColors = [
    Color(0xFFFF6B9D), // pink
    Color(0xFF6C63FF), // violet
    Color(0xFF00D4AA), // mint
    Color(0xFFFF9500), // orange
    Color(0xFF32ADE6), // sky blue
  ];

  // Planet pad — 20 vivid colours
  static const List<Color> planets = [
    Color(0xFFFF2D55), Color(0xFFFF9500), Color(0xFFFFCC02),
    Color(0xFF34C759), Color(0xFF00C7BE), Color(0xFF32ADE6),
    Color(0xFF6C63FF), Color(0xFFBF5AF2), Color(0xFFFF6B9D),
    Color(0xFF00D4AA), Color(0xFFFF3A30), Color(0xFFFF6F00),
    Color(0xFF1CB841), Color(0xFF0A84FF), Color(0xFF5E5CE6),
    Color(0xFFFF2D55), Color(0xFFFF9500), Color(0xFFFFCC02),
    Color(0xFF34C759), Color(0xFF32ADE6),
  ];

  static const String font = 'Fredoka One';
}

// ═══════════════════════════════════════════════════════════════
//  WRAPPER
// ═══════════════════════════════════════════════════════════════
class MissingNumberGame extends StatelessWidget {
  const MissingNumberGame({super.key});
  @override
  Widget build(BuildContext context) => const MissingNumberExercise();
}

// ═══════════════════════════════════════════════════════════════
//  FUN AD LOADING OVERLAY  — spinning emoji carousel
// ═══════════════════════════════════════════════════════════════
class _FunLoader extends StatefulWidget {
  final String message;
  const _FunLoader({required this.message});
  @override State<_FunLoader> createState() => _FunLoaderState();
}
class _FunLoaderState extends State<_FunLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  final _icons = ['🎯','⭐','🎉','🌈','🚀','🎊'];
  int _ei = 0;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..repeat();
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return false;
      setState(() => _ei = (_ei + 1) % _icons.length);
      return true;
    });
  }
  @override void dispose() { _spin.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (_, v, child) =>
              Transform.scale(scale: v.clamp(0.0, 1.0), child: child),
          child: Container(
            width: 220,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.60),
                  blurRadius: 40, offset: const Offset(0, 12))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedBuilder(
                animation: _spin,
                builder: (_, __) => Transform.rotate(
                  angle: _spin.value * 2 * pi,
                  child: Text(_icons[_ei],
                      style: const TextStyle(fontSize: 52)),
                ),
              ),
              const SizedBox(height: 16),
              // Bouncing white dots
              AnimatedBuilder(
                animation: _spin,
                builder: (_, __) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final dy = sin((_spin.value * 2 * pi) - i * pi / 3) * 6;
                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: Container(
                        width: 10, height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              Text(widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: _S.font,
                      fontSize: 16, color: _S.white)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FLOATING CONFETTI PAINTER (background deco)
// ═══════════════════════════════════════════════════════════════
class _ConfettiData {
  final double x, y, size, speed, phase;
  final Color color;
  final bool isCircle;
  _ConfettiData(this.x, this.y, this.size, this.speed,
      this.phase, this.color, this.isCircle);
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final List<_ConfettiData> dots;
  _ConfettiPainter(this.t, this.dots);

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in dots) {
      final y = (d.y * size.height + t * d.speed * size.height) % size.height;
      final x = d.x * size.width + sin(t * 2 * pi + d.phase) * 12;
      final alpha = (180 + 75 * sin(t * 2 * pi + d.phase)).round().clamp(80, 255);
      final paint = Paint()..color = d.color.withAlpha(alpha);
      final r = d.size;
      if (d.isCircle) {
        canvas.drawCircle(Offset(x, y), r, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: r * 2, height: r),
            const Radius.circular(2),
          ),
          paint,
        );
      }
    }
  }
  @override bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

// ═══════════════════════════════════════════════════════════════
//  ANSWER REVEAL WIDGET — fills ? box with correct number + pop
// ═══════════════════════════════════════════════════════════════
class _AnswerReveal extends StatefulWidget {
  final int number;
  final Color color;
  final double width;
  final double height;
  const _AnswerReveal({
    required this.number,
    required this.color,
    required this.width,
    required this.height,
  });
  @override State<_AnswerReveal> createState() => _AnswerRevealState();
}
class _AnswerRevealState extends State<_AnswerReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.28), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.28, end: 0.95), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0),  weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _glow = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final glowRadius = 8.0 + _glow.value * 22;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(widget.color, Colors.white, 0.30)!,
                widget.color,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _S.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                  color: widget.color.withOpacity(0.70),
                  blurRadius: glowRadius,
                  spreadRadius: 2),
              BoxShadow(
                  color: Colors.white.withOpacity(0.40),
                  blurRadius: 6),
            ],
          ),
          alignment: Alignment.center,
          child: Transform.scale(
            scale: _scale.value.clamp(0.0, 1.3),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${widget.number}',
                  style: const TextStyle(
                      fontFamily: _S.font, fontSize: 26,
                      color: _S.white,
                      shadows: [Shadow(color: Colors.black26,
                          blurRadius: 6, offset: Offset(0, 2))])),
              const Text('✓', style: TextStyle(fontSize: 11,
                  color: Colors.white, fontWeight: FontWeight.bold)),
            ]),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ASTEROID BURST (wrong)
// ═══════════════════════════════════════════════════════════════
class _AsteroidBurst extends StatefulWidget {
  final VoidCallback onDone;
  const _AsteroidBurst({required this.onDone});
  @override State<_AsteroidBurst> createState() => _AsteroidBurstState();
}
class _AsteroidBurstState extends State<_AsteroidBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _ctrl.forward().then((_) => widget.onDone());
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Opacity(
          opacity: (1.0 - t * 1.4).clamp(0.0, 1.0),
          child: Stack(alignment: Alignment.center, children: [
            Transform.scale(
              scale: 1.0 + t * 3.0,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _S.rose.withOpacity((0.45 - t * 0.45).clamp(0, 1)),
                ),
              ),
            ),
            Text('💥', style: TextStyle(fontSize: 38 + t * 18)),
          ]),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MAIN EXERCISE
// ═══════════════════════════════════════════════════════════════
class MissingNumberExercise extends StatefulWidget {
  const MissingNumberExercise({super.key});
  @override State<MissingNumberExercise> createState() =>
      _MissingNumberExerciseState();
}

class _MissingNumberExerciseState extends State<MissingNumberExercise>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  // ── Constants ────────────────────────────────────────────
  static const int _targetScore    = 10;
  static const int _maxLives       = 3;
  static const int _maxAnswers     = 20;
  static const int _seqLen         = 5;   // ← 5 numbers per sequence
  static const int _maxStart       = 14;

  final Random _rng = Random();

  // ── Question state ────────────────────────────────────────
  late List<int> _sequence;
  late int       _correctAnswer;
  int  _missingIndex = 2;

  // ── Game state ────────────────────────────────────────────
  int   _score           = 0;
  int   _lives           = _maxLives;
  bool  _showGameOver    = false;
  bool? _isAnswerCorrect;
  bool  _showFinalCeleb  = false;
  bool  _isProcessing    = false;
  bool  _showLoader      = false;
  bool  _showAsteroid    = false;
  // When correct: reveal the answer in the ? box before moving on
  bool  _revealAnswer    = false;
  String _loaderMsg      = '';

  // ── Confetti data (fixed seed) ────────────────────────────
  late List<_ConfettiData> _confetti;

  // ── Animation controllers ─────────────────────────────────
  late AnimationController _confettiCtrl; // bg confetti loop
  late AnimationController _seqEntryCtrl; // sequence bounce-in
  late Animation<double>   _seqEntry;
  late AnimationController _shakeCtrl;    // wrong card shake
  late Animation<double>   _shakeAnim;
  late AnimationController _entryCtrl;    // page entry
  late Animation<double>   _entryFade;
  late Animation<Offset>   _entrySlide;
  late AnimationController _padCtrl;      // pad stagger entry
  late AnimationController _bgCtrl;       // bg gradient pulse
  late Animation<double>   _bgAnim;

  // ── Banner ad ─────────────────────────────────────────────
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Generate confetti (fixed seed → stable positions)
    final rng2 = Random(7);
    final confettiColors = [
      _S.skyTop, _S.skyMid, _S.skyBot,
      _S.lime, _S.rose, _S.gold,
      Colors.cyan, Colors.pinkAccent, Colors.orangeAccent,
    ];
    _confetti = List.generate(55, (_) => _ConfettiData(
      rng2.nextDouble(), rng2.nextDouble(),
      3 + rng2.nextDouble() * 6,
      0.04 + rng2.nextDouble() * 0.09,
      rng2.nextDouble() * 2 * pi,
      confettiColors[rng2.nextInt(confettiColors.length)],
      rng2.nextBool(),
    ));

    _confettiCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 6))..repeat();

    _bgCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 4))..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _seqEntryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 550));
    _seqEntry = CurvedAnimation(parent: _seqEntryCtrl,
        curve: Curves.elasticOut);

    _shakeCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _shakeCtrl,
        curve: Curves.easeInOut));

    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600))..forward();
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _padCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..forward();

    _generateNewQuestion();
    _loadBannerAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiCtrl.dispose();
    _bgCtrl.dispose();
    _seqEntryCtrl.dispose();
    _shakeCtrl.dispose();
    _entryCtrl.dispose();
    _padCtrl.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _isBannerAdLoaded = false;
    if (!mounted) return;
    if (!Provider.of<ExperienceManager>(context, listen: false).adsEnabled) return;
    _bannerAd = AdHelper.getBannerAd(() {
      if (mounted) setState(() => _isBannerAdLoaded = true);
    });
  }

  // ── Generate question ─────────────────────────────────────
  void _generateNewQuestion() {
    final start = _rng.nextInt(_maxStart) + 1;
    final step  = _rng.nextBool() ? 1 : 2;
    _sequence      = List.generate(_seqLen, (i) => start + i * step);
    // missing can be any position except first/last
    _missingIndex  = 1 + _rng.nextInt(_seqLen - 2);
    _correctAnswer = _sequence[_missingIndex];
    _sequence[_missingIndex] = -1;
    _isAnswerCorrect = null;
    _revealAnswer    = false;
    _seqEntryCtrl.reset();
    _seqEntryCtrl.forward();
    _padCtrl.reset();
    _padCtrl.forward();
    setState(() {});
  }

  // ── Check answer ──────────────────────────────────────────
  Future<void> _checkAnswer(int selected) async {
    if (_isProcessing || _showGameOver) return;
    _isProcessing = true;

    final xp    = Provider.of<ExperienceManager>(context, listen: false);
    final audio = Provider.of<AudioManager>(context, listen: false);
    HapticFeedback.selectionClick();

    if (selected == _correctAnswer) {
      // ── CORRECT ──────────────────────────────────────────
      xp.addXP(1, context: context);
      await audio.playSfx('assets/audios/QuizGame_Sounds/correct.mp3');
      HapticFeedback.lightImpact();

      // 1. Reveal the answer in the ? box
      setState(() { _score++; _isAnswerCorrect = true; _revealAnswer = true; });

      // 2. Let children see the answer for 900 ms
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;

      if (_score >= _targetScore) {
        if (_lives >= 1) {
          xp.addTokenBanner(context, 1);
          audio.playSfx('assets/audios/UI_Audio/SFX_Audio/VictoryOrchestral_SFX.mp3');
          audio.playSfx('assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3');
        }
        setState(() {
          _showGameOver = _showFinalCeleb = true;
          _isAnswerCorrect = null; _revealAnswer = false; _isProcessing = false;
        });
      } else {
        setState(() { _isProcessing = false; });
        _generateNewQuestion(); // resets _revealAnswer inside
      }

    } else {
      // ── WRONG ────────────────────────────────────────────
      await audio.playSfx('assets/audios/QuizGame_Sounds/incorrect.mp3');
      HapticFeedback.heavyImpact();
      _shakeCtrl.forward(from: 0).then((_) => _shakeCtrl.reset());
      setState(() {
        _lives = (_lives > 0) ? _lives - 1 : 0;
        _isAnswerCorrect = false; _showAsteroid = true;
      });

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() { _showAsteroid = false; });

      if (_lives == 0) {
        audio.playSfx("assets/audios/UI_Audio/SFX_Audio/FailMeme_SFX.mp3");
        setState(() {
          _showGameOver = true; _isAnswerCorrect = null; _isProcessing = false;
        });
      } else {
        setState(() { _isAnswerCorrect = null; _isProcessing = false; });
      }
    }
  }

  // ── Reset / replay ────────────────────────────────────────
  void _resetGame() {
    setState(() {
      _score = 0; _lives = _maxLives;
      _showGameOver = _showFinalCeleb = _isProcessing =
          _showLoader = _showAsteroid = _revealAnswer = false;
    });
    _padCtrl.reset(); _padCtrl.forward();
    _generateNewQuestion();
  }

  Future<void> _withLoader({
    required String message,
    required Future<void> Function() action,
  }) async {
    setState(() { _showLoader = true; _loaderMsg = message; });
    await Future.delayed(const Duration(milliseconds: 300));
    await action();
    if (mounted) setState(() => _showLoader = false);
  }

  void _onReplayPressed() {
    final audio = Provider.of<AudioManager>(context, listen: false);
    audio.playEventSound('cancelButton');
    _withLoader(
      message: '🎉 Getting ready...',
      action: () => AdHelper.showInterstitialAd(
          onDismissed: _resetGame, context: context),
    );
  }

  Future<bool> _confirmQuit() async {
    final audio = Provider.of<AudioManager>(context, listen: false);
    final shouldQuit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.55),
                blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🤔', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 10),
            Text(tr(context).areYouSureQuitGame,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: _S.font,
                    fontSize: 20, color: _S.white)),
            const SizedBox(height: 6),
            Text(tr(context).youWillLoseYourProgress,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13,
                    color: Colors.white.withOpacity(0.75))),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: _FlatBtn(
                label: tr(context).cancel,
                color: Colors.white.withOpacity(0.22),
                borderColor: Colors.white.withOpacity(0.50),
                onTap: () { audio.playEventSound('cancelButton');
                Navigator.pop(ctx, false); },
              )),
              const SizedBox(width: 12),
              Expanded(child: _FlatBtn(
                label: tr(context).ok,
                color: _S.rose,
                onTap: () { audio.playEventSound('clickButton');
                Navigator.pop(ctx, true); },
              )),
            ]),
          ]),
        ),
      ),
    );
    if (shouldQuit ?? false) {
      await _withLoader(
        message: '👋 See you soon!',
        action: () => AdHelper.showInterstitialAd(
            onDismissed: () { if (mounted) Navigator.pop(context, true); },
            context: context),
      );
      return true;
    }
    return false;
  }

  // ══════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioManager>(context, listen: false);

    return WillPopScope(
      onWillPop: () async {
        final quit = await _confirmQuit();
        if (quit && mounted) audio.playEventSound("cancelButton");
        return quit;
      },
      child: Scaffold(
        // ── Banner ad bar ───────────────────────────────────
        bottomNavigationBar: context.watch<ExperienceManager>().adsEnabled
            ? _BannerBar(bannerAd: _bannerAd, isLoaded: _isBannerAdLoaded)
            : null,

        body: Stack(
          children: [
            // ── ANIMATED RAINBOW BACKGROUND ─────────────────
            AnimatedBuilder(
              animation: _bgAnim,
              builder: (_, __) {
                final t = _bgAnim.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(const Color(0xFF6C63FF),
                            const Color(0xFF32ADE6), t)!,
                        Color.lerp(const Color(0xFFFF6B9D),
                            const Color(0xFF6C63FF), t)!,
                        Color.lerp(const Color(0xFFFFCC02),
                            const Color(0xFFFF6B9D), t)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                );
              },
            ),

            // ── FLOATING CONFETTI ───────────────────────────
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) => CustomPaint(
                painter: _ConfettiPainter(
                    _confettiCtrl.value, _confetti),
                size: MediaQuery.of(context).size,
              ),
            ),

            // ── LARGE DECORATIVE BUBBLES ────────────────────
            ..._buildBubbles(),

            // ── CONTENT ────────────────────────────────────
            SafeArea(
              child: _showGameOver
                  ? _buildGameOver()
                  : FadeTransition(
                opacity: _entryFade,
                child: SlideTransition(
                  position: _entrySlide,
                  child: Column(children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
                      child: Userstatutbar(),
                    ),
                    const SizedBox(height: 6),
                    _buildHUD(audio),
                    const SizedBox(height: 10),
                    _buildSequenceCard(),
                    const SizedBox(height: 10),
                    Expanded(child: _buildPlanetPad()),
                    const SizedBox(height: 6),
                  ]),
                ),
              ),
            ),

            // ── ASTEROID BURST ──────────────────────────────
            if (_showAsteroid)
              Positioned.fill(child: IgnorePointer(
                child: Center(child: _AsteroidBurst(
                  onDone: () {
                    if (mounted) setState(() => _showAsteroid = false);
                  },
                )),
              )),

            // ── WRONG LOTTIE (no rocket, just lottie for wrong)
            if (_isAnswerCorrect == false && !_showAsteroid)
              IgnorePointer(child: Container(
                color: Colors.black.withOpacity(0.25),
                alignment: Alignment.center,
                child: SizedBox(width: 180, height: 180,
                    child: Lottie.asset(
                        'assets/animations/QuizzGame_Animation/wrong.json',
                        repeat: false)),
              )),

            // ── FUN LOADER ──────────────────────────────────
            if (_showLoader) _FunLoader(message: _loaderMsg),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  DECORATIVE BUBBLES (static, for depth)
  // ══════════════════════════════════════════════════════════
  List<Widget> _buildBubbles() => [
    Positioned(top: -55, right: -55,
        child: _Bubble(120, Colors.white.withOpacity(0.10))),
    Positioned(top: 180, left: -45,
        child: _Bubble(90,  Colors.white.withOpacity(0.08))),
    Positioned(bottom: 160, right: -35,
        child: _Bubble(100, Colors.white.withOpacity(0.09))),
    Positioned(bottom: -40, left: 60,
        child: _Bubble(80,  Colors.white.withOpacity(0.07))),
  ];

  // ══════════════════════════════════════════════════════════
  //  HUD
  // ══════════════════════════════════════════════════════════
  Widget _buildHUD(AudioManager audio) {
    final pct = (_score / _targetScore).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.50), width: 1.5),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.10), blurRadius: 12,
            offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Row(children: [
          // Back
          GestureDetector(
            onTap: () async {
              if (await _confirmQuit()) {
                audio.playEventSound("cancelButton");
                if (mounted) Navigator.pop(context);
              }
            },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.30),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                    color: Colors.white.withOpacity(0.60), width: 1.5),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 17, color: _S.white),
            ),
          ),
          const SizedBox(width: 10),
          // Title badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.28),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withOpacity(0.55), width: 1.2),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('❓', style: TextStyle(fontSize: 14)),
              SizedBox(width: 3),
            ]),
          ),
          const Spacer(),
          // Score pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _S.gold.withOpacity(0.30),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _S.gold.withOpacity(0.70), width: 1.2),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('⭐', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text('$_score/$_targetScore',
                  style: const TextStyle(
                      fontFamily: _S.font, fontSize: 14, color: _S.white)),
            ]),
          ),
          const SizedBox(width: 8),
          // Hearts
          Row(mainAxisSize: MainAxisSize.min,
              children: List.generate(_maxLives, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: AnimatedHeart(lost: i >= _lives),
              ))),
        ]),
        const SizedBox(height: 8),
        // Colorful progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(children: [
            Container(height: 10, color: Colors.white.withOpacity(0.25)),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                height: 10,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFCC02), Color(0xFF39FF14),
                      Color(0xFF00C7BE)],
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  SEQUENCE CARD  — 5 numbered boxes with constellation line
  // ══════════════════════════════════════════════════════════
  Widget _buildSequenceCard() {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) {
        final dx = sin(_shakeAnim.value * pi * 7) * 10 * (1 - _shakeAnim.value);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _isAnswerCorrect == true
                ? _S.lime.withOpacity(0.90)
                : _isAnswerCorrect == false
                ? _S.rose.withOpacity(0.90)
                : Colors.white.withOpacity(0.55),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.10),
                blurRadius: 16, offset: const Offset(0, 6)),
            if (_isAnswerCorrect == true)
              BoxShadow(color: _S.lime.withOpacity(0.45), blurRadius: 28),
            if (_isAnswerCorrect == false)
              BoxShadow(color: _S.rose.withOpacity(0.40), blurRadius: 28),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Prompt chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.white.withOpacity(0.70), width: 1.2),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🔍', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text('${tr(context).findMissingNumber}!',
                  style: const TextStyle(fontFamily: _S.font,
                      fontSize: 13, color: _S.white,
                      shadows: [Shadow(color: Colors.black26,
                          blurRadius: 4)])),
            ]),
          ),

          const SizedBox(height: 14),

          // 5-box sequence
          ScaleTransition(
            scale: _seqEntry,
            child: LayoutBuilder(builder: (ctx, box) {
              const gaps  = (_seqLen - 1) * 6.0;
              final boxW  = ((box.maxWidth - gaps) / _seqLen).floorToDouble();
              final boxH  = (boxW * 1.08).clamp(50.0, 70.0);

              return Stack(children: [
                // Dotted connector line
                Positioned(
                  top: boxH / 2 - 1, left: 0, right: 0,
                  child: CustomPaint(
                    painter: _DotLinePainter(_seqLen),
                    size: Size(box.maxWidth, 2),
                  ),
                ),

                Row(
                  children: _sequence.asMap().entries.map((e) {
                    final idx       = e.key;
                    final num       = e.value;
                    final isMissing = num == -1;
                    final boxColor  = _S.seqColors[idx % _S.seqColors.length];

                    // Reveal: show _AnswerReveal widget in the ? slot
                    if (isMissing && _revealAnswer) {
                      return _AnswerReveal(
                        number: _correctAnswer,
                        color:  boxColor,
                        width:  boxW,
                        height: boxH,
                      );
                    }

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 180 + idx * 70),
                      curve: Curves.easeOutBack,
                      builder: (_, v, child) => Opacity(
                        opacity: v.clamp(0.0, 1.0),
                        child: Transform.scale(
                            scale: v.clamp(0.01, 1.0), child: child),
                      ),
                      child: Container(
                        width:  boxW,
                        height: boxH,
                        margin: EdgeInsets.only(
                            right: idx < _seqLen - 1 ? 6 : 0),
                        decoration: BoxDecoration(
                          gradient: isMissing ? LinearGradient(
                            colors: [
                              boxColor,
                              Color.lerp(boxColor, Colors.white, 0.25)!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ) : null,
                          color: isMissing ? null : Colors.white.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isMissing
                                ? Colors.white.withOpacity(0.85)
                                : Colors.white.withOpacity(0.60),
                            width: isMissing ? 3.0 : 1.8,
                          ),
                          boxShadow: isMissing ? [
                            BoxShadow(color: boxColor.withOpacity(0.60),
                                blurRadius: 16, offset: const Offset(0, 4)),
                            BoxShadow(color: Colors.white.withOpacity(0.40),
                                blurRadius: 8),
                          ] : [
                            BoxShadow(color: Colors.black.withOpacity(0.08),
                                blurRadius: 6, offset: const Offset(0, 3)),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: isMissing
                            ? Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('?', style: const TextStyle(
                              fontFamily: _S.font, fontSize: 26,
                              color: _S.white,
                              shadows: [Shadow(color: Colors.black26,
                                  blurRadius: 6, offset: Offset(0, 2))])),
                          Text('✦', style: TextStyle(fontSize: 9,
                              color: Colors.white.withOpacity(0.80))),
                        ])
                            : Column(mainAxisSize: MainAxisSize.min, children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('$num',
                                style: TextStyle(
                                    fontFamily: _S.font, fontSize: 24,
                                    color: _S.dark,
                                    shadows: const [Shadow(
                                        color: Colors.black12,
                                        blurRadius: 4)])),
                          ),
                          Text('✦', style: TextStyle(fontSize: 8,
                              color: Colors.black.withOpacity(0.20))),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ]);
            }),
          ),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  PLANET NUMBER PAD  — 5 columns, candy planet buttons
  // ══════════════════════════════════════════════════════════
  Widget _buildPlanetPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _maxAnswers,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,      // ← 5 columns
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (_, i) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 350 + i * 22),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Opacity(
              opacity: v.clamp(0.0, 1.0),
              child: Transform.scale(
                  scale: v.clamp(0.01, 1.0), child: child),
            ),
            child: _PlanetButton(
              number: i + 1,
              color:  _S.planets[i % _S.planets.length],
              onTap:  () => _checkAnswer(i + 1),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  GAME OVER
  // ══════════════════════════════════════════════════════════
  Widget _buildGameOver() {
    final win = _score >= _targetScore && _lives > 0;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 210, height: 210,
              child: Lottie.asset(
                  win ? 'assets/animations/QuizzGame_Animation/Champion.json'
                      : 'assets/animations/QuizzGame_Animation/CuteTigerCrying.json',
                  repeat: true)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.28),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: win ? _S.lime.withOpacity(0.80)
                    : _S.rose.withOpacity(0.80),
                width: 2.5,
              ),
              boxShadow: [BoxShadow(
                color: win ? _S.lime.withOpacity(0.25)
                    : _S.rose.withOpacity(0.25),
                blurRadius: 30, offset: const Offset(0, 10),
              )],
            ),
            child: Column(children: [
              Text(
                win ? '🎉 ${tr(context).awesome}!'
                    : '💔 ${tr(context).gameOver}',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: _S.font, fontSize: 30,
                    color: win ? _S.lime : _S.rose,
                    shadows: const [Shadow(color: Colors.black26,
                        blurRadius: 6)]),
              ),
              const SizedBox(height: 14),
              // 3-star rating
              Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final lit = _score >= ((i + 1) * (_targetScore / 3)).round();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(lit ? '⭐' : '☆',
                          style: TextStyle(
                            fontSize: lit ? 38 : 30,
                            color: lit ? _S.gold : Colors.white38,
                          )),
                    );
                  })),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ResultPill('⭐', tr(context).score,
                        '$_score/$_targetScore', _S.gold),
                    _ResultPill('❤️', tr(context).remainingLives,
                        '$_lives/$_maxLives',
                        _lives > 0 ? _S.lime : _S.rose),
                  ]),
              const SizedBox(height: 20),
              _FlatBtn(
                label: '🎮 ${tr(context).playAgain}',
                color: const Color(0xFF6C63FF),
                shadowColor: const Color(0xFF6C63FF),
                onTap: _onReplayPressed,
              ),
              const SizedBox(height: 10),
              _FlatBtn(
                label: '🏠 ${tr(context).back}',
                color: Colors.white.withOpacity(0.30),
                borderColor: Colors.white.withOpacity(0.65),
                onTap: () => Navigator.pop(context),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  DOT LINE PAINTER  (constellation connector)
// ═══════════════════════════════════════════════════════════════
class _DotLinePainter extends CustomPainter {
  final int count;
  const _DotLinePainter(this.count);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.50)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final dash = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.2;
    final step = size.width / count;
    final cy   = size.height / 2;
    for (int i = 0; i < count - 1; i++) {
      double x = step * i + step * 0.72;
      final endX = step * (i + 1) + step * 0.28;
      while (x < endX) {
        canvas.drawLine(Offset(x, cy), Offset((x + 5).clamp(x, endX), cy), dash);
        x += 9;
      }
    }
  }
  @override bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════
//  PLANET BUTTON
// ═══════════════════════════════════════════════════════════════
class _PlanetButton extends StatefulWidget {
  final int number; final Color color; final VoidCallback onTap;
  const _PlanetButton({required this.number, required this.color,
    required this.onTap});
  @override State<_PlanetButton> createState() => _PlanetButtonState();
}
class _PlanetButtonState extends State<_PlanetButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double>   _scale;
  @override
  void initState() {
    super.initState();
    _press = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 85));
    _scale = Tween<double>(begin: 1.0, end: 0.80)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }
  @override void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _press.forward(),
      onTapUp:     (_) => _press.reverse(),
      onTapCancel: ()  => _press.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.30, -0.32),
              radius: 0.80,
              colors: [
                Color.lerp(widget.color, Colors.white, 0.38)!,
                widget.color,
                Color.lerp(widget.color, Colors.black, 0.22)!,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(color: widget.color.withOpacity(0.70),
                  blurRadius: 10, offset: const Offset(0, 4)),
              BoxShadow(color: widget.color.withOpacity(0.30),
                  blurRadius: 18, spreadRadius: 2),
            ],
          ),
          child: Stack(alignment: Alignment.center, children: [
            Text('${widget.number}',
                style: const TextStyle(
                    fontFamily: _S.font, fontSize: 18,
                    color: _S.white,
                    shadows: [Shadow(color: Colors.black38,
                        blurRadius: 5, offset: Offset(0, 2))])),
            // Shine
            Positioned(top: 5, left: 7,
                child: Container(width: 7, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(3),
                    ))),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  RESULT PILL
// ═══════════════════════════════════════════════════════════════
class _ResultPill extends StatelessWidget {
  final String emoji, label, value; final Color color;
  const _ResultPill(this.emoji, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
        color: color.withOpacity(0.20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.55), width: 1.5)),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(fontFamily: _S.font,
          fontSize: 11, color: color)),
      Text(value,  style: TextStyle(fontFamily: _S.font,
          fontSize: 16, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════
//  FLAT BUTTON
// ═══════════════════════════════════════════════════════════════
class _FlatBtn extends StatelessWidget {
  final String label; final VoidCallback onTap;
  final Color color;
  final Color? borderColor, shadowColor;
  const _FlatBtn({required this.label, required this.onTap,
    required this.color, this.borderColor, this.shadowColor});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.8) : null,
        boxShadow: shadowColor != null
            ? [BoxShadow(color: shadowColor!.withOpacity(0.50),
            blurRadius: 14, offset: const Offset(0, 5))] : null,
      ),
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(fontFamily: _S.font,
          fontSize: 18, color: _S.white,
          shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
//  BUBBLE DECORATION
// ═══════════════════════════════════════════════════════════════
class _Bubble extends StatelessWidget {
  final double size; final Color color;
  const _Bubble(this.size, this.color);
  @override
  Widget build(BuildContext context) => Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

// ═══════════════════════════════════════════════════════════════
//  BANNER AD BAR  — shimmer skeleton while loading
// ═══════════════════════════════════════════════════════════════
class _BannerBar extends StatefulWidget {
  final BannerAd? bannerAd; final bool isLoaded;
  const _BannerBar({required this.bannerAd, required this.isLoaded});
  @override State<_BannerBar> createState() => _BannerBarState();
}
class _BannerBarState extends State<_BannerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimCtrl;
  late final Animation<double>   _shimAnim;
  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _shimAnim = CurvedAnimation(parent: _shimCtrl, curve: Curves.easeInOut);
  }
  @override void dispose() { _shimCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final adH = (widget.bannerAd?.size.height ?? 50).toDouble();
    return SafeArea(
      top: false,
      child: Container(
        height: adH + 10,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
          ),
          boxShadow: [BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.40),
              blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: widget.isLoaded && widget.bannerAd != null
            ? Center(child: SizedBox(
            height: adH,
            width:  widget.bannerAd!.size.width.toDouble(),
            child:  AdWidget(ad: widget.bannerAd!)))
            : AnimatedBuilder(
          animation: _shimAnim,
          builder: (_, __) {
            final t = _shimAnim.value;
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              child: Row(children: [
                Opacity(opacity: 0.5 + t * 0.5,
                    child: const Text('🌈',
                        style: TextStyle(fontSize: 18))),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 28,
                      color: Colors.white.withOpacity(0.18 + t * 0.18),
                      alignment: Alignment.center,
                      child: Text('✨  Advertisement  ✨',
                          style: TextStyle(fontFamily: _S.font,
                              fontSize: 12,
                              color: Colors.white.withOpacity(
                                  0.60 + t * 0.30))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Opacity(opacity: 0.5 + t * 0.5,
                    child: const Text('🌈',
                        style: TextStyle(fontSize: 18))),
              ]),
            );
          },
        ),
      ),
    );
  }
}