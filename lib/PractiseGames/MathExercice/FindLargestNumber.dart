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
//  THEME  —  Carnival Balloon Pop 🎈
// ═══════════════════════════════════════════════════════════════
class _T {
  static const List<Color> balloons = [
    Color(0xFFFF4D6D), // hot pink
    Color(0xFF06D6A0), // mint green
    Color(0xFFFFB703), // sunny yellow
    Color(0xFF8338EC), // grape purple
    Color(0xFFFF6B35), // tangerine
    Color(0xFF3A86FF), // bright blue
  ];
  static const List<Color> balloonHighlights = [
    Color(0xFFFF8FA3),
    Color(0xFF64DFBF),
    Color(0xFFFFD166),
    Color(0xFFB08BF5),
    Color(0xFFFF9E73),
    Color(0xFF74AEFF),
  ];
  static const String fontTitle = 'Fredoka One';
}

// ═══════════════════════════════════════════════════════════════
//  AD LOADING OVERLAY  (fun balloon spinner, no boring spinner)
// ═══════════════════════════════════════════════════════════════
class _AdLoadingOverlay extends StatefulWidget {
  const _AdLoadingOverlay();
  @override
  State<_AdLoadingOverlay> createState() => _AdLoadingOverlayState();
}

class _AdLoadingOverlayState extends State<_AdLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() { _spin.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.72),
      child: Center(
        child: Container(
          width: 200, height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spinning balloon ring
              AnimatedBuilder(
                animation: _spin,
                builder: (_, __) {
                  return SizedBox(
                    width: 80, height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: List.generate(6, (i) {
                        final angle = (i / 6) * 2 * pi + _spin.value * 2 * pi;
                        final x = cos(angle) * 28.0;
                        final y = sin(angle) * 28.0;
                        final color = _T.balloons[i];
                        final scale = 0.55 + 0.45 * ((sin(_spin.value * 2 * pi + i) + 1) / 2);
                        return Transform.translate(
                          offset: Offset(x, y),
                          child: Transform.scale(
                            scale: scale,
                            child: Text('🎈', style: TextStyle(fontSize: 18 * scale)),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
              const Text('Almost ready!',
                  style: TextStyle(
                    fontFamily: _T.fontTitle, fontSize: 18,
                    color: Color(0xFF3A86FF),
                  )),
              const SizedBox(height: 6),
              const Text('✨ One moment ✨',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the fun loading overlay while an interstitial ad loads, then
/// dismisses it automatically once the ad takes over (or fails).
Future<void> _showAdWithLoadingOverlay({
  required BuildContext context,
  VoidCallback? onDismissed,
}) async {
  // Push the overlay as a route so it truly covers everything.
  final overlayRoute = PageRouteBuilder<void>(
    opaque: false,
    barrierDismissible: false,
    pageBuilder: (_, __, ___) => const _AdLoadingOverlay(),
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
  );
  Navigator.of(context).push(overlayRoute);

  await AdHelper.showInterstitialAd(
    context: context,
    onDismissed: () {
      // Pop the overlay if still showing, then run callback.
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      onDismissed?.call();
    },
  );
}

// ═══════════════════════════════════════════════════════════════
//  BALLOON EXPLOSION PARTICLE
// ═══════════════════════════════════════════════════════════════
class _ExplosionParticle {
  final double angle;
  final double speed;
  final double size;
  final Color  color;
  // Shape computed once at spawn — never re-rolled inside build()
  final bool   isCircle;
  final double cornerRadius;

  _ExplosionParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.isCircle,
    required this.cornerRadius,
  });
}

// ═══════════════════════════════════════════════════════════════
//  ENTRY POINT
// ═══════════════════════════════════════════════════════════════
class FindLargestNumberGame extends StatelessWidget {
  const FindLargestNumberGame({super.key});
  @override
  Widget build(BuildContext context) => const FindLargestNumberExercise();
}

class FindLargestNumberExercise extends StatefulWidget {
  const FindLargestNumberExercise({super.key});
  @override
  State<FindLargestNumberExercise> createState() =>
      _FindLargestNumberExerciseState();
}

class _FindLargestNumberExerciseState
    extends State<FindLargestNumberExercise>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  static const int _targetScore = 10;
  static const int _maxLives    = 3;

  final Random _rng = Random();

  late List<int>   _numbers;
  late int         _correctAnswer;
  late List<Color> _balloonColors;
  late List<Color> _balloonHighlights;

  int   _score             = 0;
  int   _lives             = _maxLives;
  bool  _showGameOver      = false;
  bool? _isAnswerCorrect;
  bool  _showFinalCelebration = false;
  bool  _isProcessingAnswer   = false;

  // Which balloons are exploded (wrong taps) — stays until next question
  final Set<int> _explodedIndices = {};
  // Which balloon index is currently animating its explosion
  int? _explodingIndex;

  // Per-balloon: idle wiggle
  late List<AnimationController> _wiggleCtrl;
  late List<Animation<double>>   _wiggleAnim;

  // Per-balloon: explosion animation (scale + opacity)
  late List<AnimationController> _explodeCtrl;
  late List<Animation<double>>   _explodeScale;
  late List<Animation<double>>   _explodeFade;

  // Cloud drift
  late AnimationController _cloudCtrl;
  late Animation<double>   _cloudAnim;

  // Spark (correct answer)
  late AnimationController _sparkCtrl;
  late Animation<double>   _sparkAnim;

  // Bounce-in for new question
  late AnimationController _bounceCtrl;
  late Animation<double>   _bounceAnim;

  // Correct balloon pop scale
  late AnimationController _correctPopCtrl;
  late Animation<double>   _correctPopScale;
  int? _correctPoppedIndex;

  // Particles per balloon slot
  final List<List<_ExplosionParticle>> _particles =
  List.generate(4, (_) => []);

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // lifecycle for ad reload

    // Idle wiggle
    _wiggleCtrl = List.generate(4, (i) => AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1100 + i * 230),
    )..repeat(reverse: true));
    _wiggleAnim = _wiggleCtrl.map((c) =>
        Tween<double>(begin: -0.07, end: 0.07)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();

    // Explosion: scale 1 → 1.6 → 0, fade 1 → 0
    _explodeCtrl = List.generate(4, (_) =>
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500)));
    _explodeScale = _explodeCtrl.map((c) =>
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.55), weight: 35),
          TweenSequenceItem(tween: Tween(begin: 1.55, end: 0.0), weight: 65),
        ]).animate(CurvedAnimation(parent: c, curve: Curves.easeIn)))
        .toList();
    _explodeFade = _explodeCtrl.map((c) =>
        TweenSequence<double>([
          TweenSequenceItem(tween: ConstantTween(1.0), weight: 25),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 75),
        ]).animate(c))
        .toList();

    // Correct pop scale
    _correctPopCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _correctPopScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _correctPopCtrl, curve: Curves.easeOutBack));

    // Cloud
    _cloudCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 18))
      ..repeat();
    _cloudAnim = Tween<double>(begin: 0, end: 1).animate(_cloudCtrl);

    // Spark
    _sparkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _sparkAnim = CurvedAnimation(parent: _sparkCtrl, curve: Curves.easeOut);

    // Bounce-in
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _bounceAnim = CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut);

    _generateNewQuestion();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _isBannerAdLoaded = false;
    // Only load if ads are enabled — mirrors Index logic
    if (!mounted) return;
    final adsEnabled =
        Provider.of<ExperienceManager>(context, listen: false).adsEnabled;
    if (!adsEnabled) return;

    _bannerAd = AdHelper.getBannerAd(() {
      if (mounted) setState(() => _isBannerAdLoaded = true);
    });
  }

  /// Reload banner on app resume, exactly as Index does.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadBannerAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final c in _wiggleCtrl) c.dispose();
    for (final c in _explodeCtrl) c.dispose();
    _correctPopCtrl.dispose();
    _cloudCtrl.dispose();
    _sparkCtrl.dispose();
    _bounceCtrl.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  void _generateNewQuestion() {
    _numbers = List.generate(4, (_) => _rng.nextInt(99) + 1);
    _correctAnswer = _numbers.reduce(max);
    _isAnswerCorrect = null;
    _explodedIndices.clear();
    _explodingIndex = null;
    _correctPoppedIndex = null;

    for (int i = 0; i < 4; i++) {
      _particles[i] = [];
      _explodeCtrl[i].reset();
      _wiggleCtrl[i].repeat(reverse: true);
    }

    final pool  = List.of(_T.balloons)..shuffle(_rng);
    final hPool = List.of(_T.balloonHighlights)..shuffle(_rng);
    _balloonColors      = pool.take(4).toList();
    _balloonHighlights  = hPool.take(4).toList();

    _bounceCtrl.reset();
    _bounceCtrl.forward();
    setState(() {});
  }

  /// Builds N random particles for slot [index] — all shape data fixed at spawn.
  void _spawnParticles(int index) {
    final color = _balloonColors[index];
    _particles[index] = List.generate(16, (_) {
      final circle = _rng.nextBool();
      return _ExplosionParticle(
        angle:        _rng.nextDouble() * 2 * pi,
        speed:        28 + _rng.nextDouble() * 60,
        size:         5  + _rng.nextDouble() * 11,
        color:        Color.lerp(color, Colors.white, _rng.nextDouble() * 0.45)!,
        isCircle:     circle,
        cornerRadius: circle ? 0 : (_rng.nextDouble() * 4),
      );
    });
  }

  Future<void> _checkAnswer(int selected, int index) async {
    if (_isProcessingAnswer || _showGameOver) return;
    if (_explodedIndices.contains(index)) return; // already blown up
    _isProcessingAnswer = true;

    final xpManager    = Provider.of<ExperienceManager>(context, listen: false);
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    HapticFeedback.heavyImpact();

    if (selected == _correctAnswer) {
      // ── CORRECT ───────────────────────────────────────────────
      xpManager.addXP(1, context: context);
      await audioManager.playSfx('assets/audios/QuizGame_Sounds/correct.mp3');

      _correctPoppedIndex = index;
      _correctPopCtrl.reset();
      _correctPopCtrl.forward();
      _sparkCtrl.reset();
      _sparkCtrl.forward();

      setState(() { _score++; _isAnswerCorrect = true; });

      Future.delayed(const Duration(milliseconds: 950), () {
        if (!mounted) return;
        if (_score >= _targetScore) {
          if (_lives >= 1) {
            xpManager.addTokenBanner(context, 1);
            audioManager.playSfx('assets/audios/UI_Audio/SFX_Audio/VictoryOrchestral_SFX.mp3');
            audioManager.playSfx('assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3');
          }
          setState(() {
            _showGameOver = _showFinalCelebration = true;
            _isAnswerCorrect = null;
            _isProcessingAnswer = false;
          });
        } else {
          setState(() => _isProcessingAnswer = false);
          _generateNewQuestion();
        }
      });

    } else {
      // ── WRONG: EXPLODE that balloon ───────────────────────────
      await audioManager.playSfx('assets/audios/QuizGame_Sounds/incorrect.mp3');
      HapticFeedback.vibrate();

      _spawnParticles(index);
      _wiggleCtrl[index].stop();
      _explodingIndex = index;

      setState(() {
        _lives = (_lives > 0) ? _lives - 1 : 0;
        _isAnswerCorrect = false;
      });

      _explodeCtrl[index].reset();
      _explodeCtrl[index].forward().whenComplete(() {
        if (!mounted) return;
        setState(() {
          _explodedIndices.add(index);
          _explodingIndex = null;
        });
      });

      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        if (_lives == 0) {
          audioManager.playSfx("assets/audios/UI_Audio/SFX_Audio/FailMeme_SFX.mp3");
          setState(() {
            _showGameOver = true;
            _isAnswerCorrect = null;
            _isProcessingAnswer = false;
          });
        } else {
          setState(() { _isAnswerCorrect = null; _isProcessingAnswer = false; });
        }
      });
    }
  }

  void _resetGame() {
    setState(() {
      _score = 0;
      _lives = _maxLives;
      _showGameOver = _showFinalCelebration = false;
      _isProcessingAnswer = false;
    });
    _generateNewQuestion();
  }

  void _onReplayPressed() {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playEventSound('cancelButton');
    _showAdWithLoadingOverlay(context: context, onDismissed: _resetGame);
  }

  Future<bool> _confirmQuit() async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    final shouldQuit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🐥', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text(tr(context).areYouSureQuitGame,
                  style: const TextStyle(fontFamily: _T.fontTitle, fontSize: 22),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(tr(context).youWillLoseYourProgress,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        audioManager.playEventSound('cancelButton');
                        Navigator.pop(ctx, false);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(tr(context).cancel,
                          style: const TextStyle(fontSize: 16, fontFamily: _T.fontTitle)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        audioManager.playEventSound('clickButton');
                        Navigator.pop(ctx, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4D6D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 4,
                      ),
                      child: Text(tr(context).ok,
                          style: const TextStyle(
                              fontSize: 16, fontFamily: _T.fontTitle, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldQuit ?? false) {
      // Show fun loading overlay while interstitial loads
      await _showAdWithLoadingOverlay(
        context: context,
        onDismissed: () => Navigator.pop(context, true),
      );
      return true;
    }
    return false;
  }

  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    return WillPopScope(
      onWillPop: () async {
        final quit = await _confirmQuit();
        if (quit && mounted) audioManager.playEventSound("cancelButton");
        return quit;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // ── SKY GRADIENT ─────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF48B4E0), Color(0xFF87CEEB), Color(0xFFB8E4F9), Color(0xFFF0F8FF)],
                  stops: [0.0, 0.35, 0.70, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // ── DRIFTING CLOUDS ──────────────────────────────────
            AnimatedBuilder(
              animation: _cloudAnim,
              builder: (_, __) {
                final t = _cloudAnim.value;
                final w = MediaQuery.of(context).size.width;
                return Stack(children: [
                  _Cloud(left: -120 + (w + 140) * t,                       top: 60,  size: 1.0),
                  _Cloud(left: -80  + (w + 100) * ((t + 0.4) % 1.0),       top: 130, size: 0.7),
                  _Cloud(left: -60  + (w + 80)  * ((t + 0.7) % 1.0),       top: 30,  size: 0.5),
                ]);
              },
            ),

            // ── STAR DECO ────────────────────────────────────────
            ..._buildStarDeco(),

            // ── MAIN CONTENT ─────────────────────────────────────
            SafeArea(
              child: _showGameOver ? _buildGameOver() : _buildGame(context),
            ),

            // ── ANSWER LOTTIE OVERLAY ────────────────────────────
            if (_isAnswerCorrect != null)
              IgnorePointer(
                child: Container(
                  color: Colors.black.withOpacity(0.28),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 200, height: 200,
                        child: Lottie.asset(
                          _isAnswerCorrect!
                              ? 'assets/animations/QuizzGame_Animation/DoneAnimation.json'
                              : 'assets/animations/QuizzGame_Animation/wrong.json',
                          repeat: false,
                        ),
                      ),
                      if (_isAnswerCorrect!)
                        AnimatedBuilder(
                          animation: _sparkAnim,
                          builder: (_, __) => Opacity(
                            opacity: (1 - _sparkAnim.value).clamp(0.0, 1.0),
                            child: const Text('⭐ ✨ 🌟 ✨ ⭐',
                                style: TextStyle(fontSize: 32)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        // context.watch mirrors Index: rebuilds automatically when adsEnabled changes.
        bottomNavigationBar: context.watch<ExperienceManager>().adsEnabled
            ? _BannerAdBar(bannerAd: _bannerAd, isLoaded: _isBannerAdLoaded)
            : null,
      ),
    );
  }

  // ── GAME SCREEN ──────────────────────────────────────────────
  Widget _buildGame(BuildContext context) {
    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  if (await _confirmQuit() && mounted) {
                    Provider.of<AudioManager>(context, listen: false)
                        .playEventSound("cancelButton");
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                        color: Colors.blue.shade200.withOpacity(0.50),
                        blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: Color(0xFF3A86FF)),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(child: Userstatutbar()),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Score + Lives
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(
                      color: Colors.blue.shade200.withOpacity(0.40),
                      blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text('$_score / $_targetScore',
                        style: const TextStyle(
                          fontFamily: _T.fontTitle, fontSize: 20,
                          color: Color(0xFF3A86FF),
                        )),
                  ],
                ),
              ),
              Row(
                children: List.generate(_maxLives, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: AnimatedHeart(lost: i >= _lives),
                )),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Rainbow progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Container(height: 18, color: Colors.white.withOpacity(0.60)),
                FractionallySizedBox(
                  widthFactor: (_score / _targetScore).clamp(0.0, 1.0),
                  child: Container(
                    height: 18,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF4D6D), Color(0xFFFFB703), Color(0xFF06D6A0)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Question banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.90),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(
                color: const Color(0xFFFFB703).withOpacity(0.40),
                blurRadius: 20, offset: const Offset(0, 6))],
            border: Border.all(
                color: const Color(0xFFFFB703).withOpacity(0.60), width: 2.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  "${tr(context).findLargestNumber} ?",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: _T.fontTitle, fontSize: 24,
                    color: Color(0xFF1A1A2E), height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text('🔍', style: TextStyle(fontSize: 28)),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Balloon grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedBuilder(
              animation: _bounceAnim,
              builder: (_, child) => Transform.scale(
                scale: _bounceAnim.value.clamp(0.01, 1.02),
                child: child,
              ),
              child: GridView.count(
                crossAxisCount: 2,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.82,
                children: List.generate(4, (i) => _buildBalloonSlot(i)),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  // ── ONE BALLOON SLOT ─────────────────────────────────────────
  Widget _buildBalloonSlot(int i) {
    // Already fully exploded — show empty ghost
    if (_explodedIndices.contains(i)) {
      return _GhostSlot(color: _balloonColors[i]);
    }

    // Currently exploding
    if (_explodingIndex == i) {
      return AnimatedBuilder(
        animation: _explodeCtrl[i],
        builder: (_, child) {
          final t = _explodeCtrl[i].value;
          return OverflowBox(
            // Allow particles to paint up to 80px outside the cell on every side
            // without touching the layout of sibling widgets.
            maxWidth:  double.infinity,
            maxHeight: double.infinity,
            alignment: Alignment.center,
            child: SizedBox(
              // Fixed canvas — large enough for particles to fly into
              width:  260,
              height: 260,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Exploding balloon (scale + fade)
                  Transform.scale(
                    scale: _explodeScale[i].value,
                    child: Opacity(
                      opacity: _explodeFade[i].value.clamp(0.0, 1.0),
                      child: SizedBox(width: 140, height: 160, child: child),
                    ),
                  ),

                  // Particle burst — positions pre-computed in _spawnParticles
                  ..._particles[i].map((p) {
                    final dist    = p.speed * t;
                    final dx      = cos(p.angle) * dist;
                    final dy      = sin(p.angle) * dist;
                    final opacity = (1.0 - t * 1.2).clamp(0.0, 1.0);
                    final sz      = (p.size * (1.0 - t * 0.5)).clamp(1.0, 20.0);
                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: sz, height: sz,
                          decoration: BoxDecoration(
                            color: p.color,
                            // shape is fixed at spawn time, not re-rolled every frame
                            shape: p.isCircle ? BoxShape.circle : BoxShape.rectangle,
                            borderRadius: p.isCircle
                                ? null
                                : BorderRadius.circular(p.cornerRadius),
                          ),
                        ),
                      ),
                    );
                  }),

                  // 💥 emoji flash — fades out in first half of animation
                  Opacity(
                    opacity: (1.0 - t * 2.2).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 1.0 + t * 1.4,
                      child: const Text('💥', style: TextStyle(fontSize: 42)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: _BalloonContent(
          number:    _numbers[i],
          color:     _balloonColors[i],
          highlight: _balloonHighlights[i],
        ),
      );
    }

    // Normal wiggling balloon (possibly with correct-pop scale)
    return AnimatedBuilder(
      animation: _wiggleAnim[i],
      builder: (_, child) => Transform.rotate(
        angle: _wiggleAnim[i].value,
        child: child,
      ),
      child: (_correctPoppedIndex == i)
          ? AnimatedBuilder(
        animation: _correctPopScale,
        builder: (_, child) =>
            Transform.scale(scale: _correctPopScale.value, child: child),
        child: GestureDetector(
          onTap: () => _checkAnswer(_numbers[i], i),
          child: _BalloonContent(
              number: _numbers[i],
              color: _balloonColors[i],
              highlight: _balloonHighlights[i]),
        ),
      )
          : GestureDetector(
        onTap: () => _checkAnswer(_numbers[i], i),
        child: _BalloonContent(
            number: _numbers[i],
            color: _balloonColors[i],
            highlight: _balloonHighlights[i]),
      ),
    );
  }

  // ── GAME OVER ────────────────────────────────────────────────
  Widget _buildGameOver() {
    final win = _score >= _targetScore && _lives > 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: (win ? const Color(0xFFFFB703) : const Color(0xFFFF4D6D))
                    .withOpacity(0.35),
                blurRadius: 36, offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 220, height: 220,
                child: Lottie.asset(
                  win
                      ? 'assets/animations/QuizzGame_Animation/Champion.json'
                      : 'assets/animations/QuizzGame_Animation/CuteTigerCrying.json',
                  repeat: true,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                win ? '🎉 ${tr(context).awesome} !' : '💔 ${tr(context).gameOver}',
                style: TextStyle(
                  fontFamily: _T.fontTitle, fontSize: 36,
                  color: win ? const Color(0xFFFFB703) : const Color(0xFFFF4D6D),
                ),
              ),
              const SizedBox(height: 12),
              // 3-star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final lit = _score >= ((i + 1) * (_targetScore / 3)).round();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      lit ? '⭐' : '☆',
                      style: TextStyle(
                          fontSize: lit ? 40 : 32,
                          color: lit ? const Color(0xFFFFB703) : Colors.grey.shade300),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text('${tr(context).score} : $_score / $_targetScore',
                  style: const TextStyle(
                      fontFamily: _T.fontTitle, fontSize: 22,
                      color: Color(0xFF3A86FF))),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_maxLives, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(i < _lives ? '❤️' : '🖤',
                      style: const TextStyle(fontSize: 26)),
                )),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: _onReplayPressed,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFFB703)]),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(
                        color: const Color(0xFFFFB703).withOpacity(0.50),
                        blurRadius: 18, offset: const Offset(0, 6))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎈', style: TextStyle(fontSize: 26)),
                      const SizedBox(width: 10),
                      Text(tr(context).playAgain,
                          style: const TextStyle(
                              fontFamily: _T.fontTitle, fontSize: 24,
                              color: Colors.white)),
                      const SizedBox(width: 10),
                      const Text('🎈', style: TextStyle(fontSize: 26)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStarDeco() => [
    const Positioned(top: 80,  left: 20,  child: Text('✦', style: TextStyle(fontSize: 14, color: Color(0x99FFFFFF)))),
    const Positioned(top: 160, right: 30, child: Text('✦', style: TextStyle(fontSize: 10, color: Color(0x88FFFFFF)))),
    const Positioned(top: 40,  right: 80, child: Text('✦', style: TextStyle(fontSize: 18, color: Color(0x77FFFFFF)))),
    const Positioned(top: 220, left: 50,  child: Text('✦', style: TextStyle(fontSize: 8,  color: Color(0x66FFFFFF)))),
  ];
}

// ═══════════════════════════════════════════════════════════════
//  BALLOON CONTENT  (pure visual, no gesture)
// ═══════════════════════════════════════════════════════════════
class _BalloonContent extends StatelessWidget {
  final int   number;
  final Color color;
  final Color highlight;

  const _BalloonContent({
    required this.number,
    required this.color,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BalloonPainter(color: color, highlight: highlight),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$number',
              style: TextStyle(
                fontFamily: _T.fontTitle,
                fontSize: 52,
                color: Colors.white,
                shadows: [
                  Shadow(color: color.withOpacity(0.60),
                      blurRadius: 12, offset: const Offset(0, 4)),
                  const Shadow(color: Colors.black26,
                      blurRadius: 6, offset: Offset(0, 3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  GHOST SLOT  (shown after balloon is fully exploded)
// ═══════════════════════════════════════════════════════════════
class _GhostSlot extends StatelessWidget {
  final Color color;
  const _GhostSlot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: color.withOpacity(0.25), width: 2, style: BorderStyle.solid),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💨', style: TextStyle(fontSize: 36, color: color.withOpacity(0.40))),
            const SizedBox(height: 6),
            Text('Pop!',
                style: TextStyle(
                    fontFamily: _T.fontTitle, fontSize: 18,
                    color: color.withOpacity(0.35))),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  BALLOON PAINTER
// ═══════════════════════════════════════════════════════════════
class _BalloonPainter extends CustomPainter {
  final Color color;
  final Color highlight;
  const _BalloonPainter({required this.color, required this.highlight});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.40;
    final rx = w * 0.44;
    final ry = h * 0.41;

    // Balloon body
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.35),
        radius: 0.75,
        colors: [highlight, color, color.withOpacity(0.85)],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.85));
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
        bodyPaint);

    // Knot
    final knotPaint = Paint()
      ..color = color.withOpacity(0.90)
      ..style = PaintingStyle.fill;
    final kx = cx;
    final ky = cy + ry;
    final knotPath = Path()
      ..moveTo(kx - 7, ky)
      ..quadraticBezierTo(kx - 5, ky + 14, kx, ky + 10)
      ..quadraticBezierTo(kx + 5, ky + 14, kx + 7, ky)
      ..close();
    canvas.drawPath(knotPath, knotPaint);

    // String
    final stringPaint = Paint()
      ..color = color.withOpacity(0.65)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final stringPath = Path()
      ..moveTo(kx, ky + 10)
      ..quadraticBezierTo(kx - 10, ky + 30, kx + 6, ky + 50)
      ..quadraticBezierTo(kx + 16, ky + 70, kx, h * 0.97);
    canvas.drawPath(stringPath, stringPaint);

    // Shine
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - rx * 0.28, cy - ry * 0.30),
          width: rx * 0.38,
          height: ry * 0.28),
      Paint()..color = Colors.white.withOpacity(0.55),
    );
  }

  @override
  bool shouldRepaint(_BalloonPainter old) => old.color != color;
}

// ═══════════════════════════════════════════════════════════════
//  CLOUD WIDGET
// ═══════════════════════════════════════════════════════════════
class _Cloud extends StatelessWidget {
  final double left;
  final double top;
  final double size;
  const _Cloud({required this.left, required this.top, required this.size});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left, top: top,
      child: Opacity(
        opacity: 0.75 * size,
        child: CustomPaint(
          painter: _CloudPainter(),
          size: Size(120 * size, 55 * size),
        ),
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    canvas.drawOval(Rect.fromCenter(center: Offset(w * .50, h * .62), width: w * .55, height: h * .70), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * .30, h * .70), width: w * .40, height: h * .55), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * .70, h * .70), width: w * .38, height: h * .50), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * .50, h * .45), width: w * .38, height: h * .52), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * .35, h * .52), width: w * .30, height: h * .40), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * .65, h * .52), width: w * .30, height: h * .40), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════
//  BANNER AD BAR
//  Shimmer skeleton while loading → real AdWidget once ready.
//  Height is stable so the layout never jumps.
// ═══════════════════════════════════════════════════════════════
class _BannerAdBar extends StatefulWidget {
  final BannerAd? bannerAd;
  final bool      isLoaded;
  const _BannerAdBar({required this.bannerAd, required this.isLoaded});

  @override
  State<_BannerAdBar> createState() => _BannerAdBarState();
}

class _BannerAdBarState extends State<_BannerAdBar>
    with SingleTickerProviderStateMixin {

  late final AnimationController _shimmerCtrl;
  late final Animation<double>   _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _shimmerAnim = CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _shimmerCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final adH = (widget.bannerAd?.size.height ?? 50).toDouble();

    return SafeArea(
      top: false,
      child: Container(
        height: adH + 10,
        decoration: BoxDecoration(
          // Same sky palette as the game background
          gradient: const LinearGradient(
            colors: [Color(0xFFB8E4F9), Color(0xFFF0F8FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(
            top: BorderSide(
              color: const Color(0xFF3A86FF).withOpacity(0.20),
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF48B4E0).withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: widget.isLoaded && widget.bannerAd != null
        // ── Real ad ──────────────────────────────────────────
            ? Center(
          child: SizedBox(
            height: adH,
            width:  widget.bannerAd!.size.width.toDouble(),
            child:  AdWidget(ad: widget.bannerAd!),
          ),
        )
        // ── Shimmer skeleton while the ad loads ───────────────
            : AnimatedBuilder(
          animation: _shimmerAnim,
          builder: (_, __) {
            final t = _shimmerAnim.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  // Balloon deco left
                  Opacity(
                    opacity: 0.4 + t * 0.4,
                    child: const Text('🎈', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 10),
                  // Animated shimmer bar
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              const Color(0xFF3A86FF).withOpacity(0.18 + t * 0.22),
                              const Color(0xFF87CEEB).withOpacity(0.35 + t * 0.30),
                              const Color(0xFF3A86FF).withOpacity(0.18 + t * 0.22),
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '✨  Advertisement loading…  ✨',
                          style: TextStyle(
                            fontFamily: 'Fredoka One',
                            fontSize: 12,
                            color: const Color(0xFF3A86FF).withOpacity(0.55 + t * 0.30),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Balloon deco right
                  Opacity(
                    opacity: 0.4 + t * 0.4,
                    child: const Text('🎈', style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}