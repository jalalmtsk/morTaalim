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
import '../../tools/AD_Tools/adLabel.dart';
import '../../tools/Ads_Manager.dart';
import 'Tools/AnimatedHeart.dart';

// ═══════════════════════════════════════════════════════════════
//  🚂 TRAIN CONDUCTOR SUBTRACTION
//  Theme: A train with N cars. Some cars "uncouple" and leave.
//  How many remain? Industrial amber + steel blue palette.
//  All best practices: WidgetsBindingObserver, context.watch,
//  fun loader, lifecycle-aware banner, shake on wrong.
// ═══════════════════════════════════════════════════════════════
class _T {
  static const steel      = Color(0xFF334155); // dark slate
  static const steelMid   = Color(0xFF475569);
  static const amber      = Color(0xFFFFB300); // warm amber
  static const amberLight = Color(0xFFFFF8E1);
  static const rust       = Color(0xFFEF4444); // danger red
  static const sky        = Color(0xFF38BDF8);
  static const white      = Color(0xFFFFFFFF);
  static const chalk      = Color(0xFFF1F5F9);

  // Answer button colours
  static const List<Color> btnColors = [
    Color(0xFFFFB300), Color(0xFF3B82F6), Color(0xFFEF4444),
    Color(0xFF22C55E), Color(0xFF8B5CF6), Color(0xFF06B6D4),
    Color(0xFFF97316), Color(0xFF10B981), Color(0xFF6366F1),
    Color(0xFFEC4899), Color(0xFFFFB300), Color(0xFF3B82F6),
    Color(0xFFEF4444), Color(0xFF22C55E), Color(0xFF8B5CF6),
    Color(0xFF06B6D4), Color(0xFFF97316), Color(0xFF10B981),
    Color(0xFF6366F1), Color(0xFFEC4899),
  ];

  static const String font = 'Fredoka One';
}

// ═══════════════════════════════════════════════════════════════
//  WRAPPER
// ═══════════════════════════════════════════════════════════════
class MathSubtractionGame extends StatelessWidget {
  const MathSubtractionGame({super.key});
  @override Widget build(BuildContext context) => const MathSubtractionExercise();
}

// ═══════════════════════════════════════════════════════════════
//  LOADING OVERLAY  — animated train puffing smoke
// ═══════════════════════════════════════════════════════════════
class _TrainLoader extends StatefulWidget {
  final String message;
  const _TrainLoader({required this.message});
  @override State<_TrainLoader> createState() => _TrainLoaderState();
}
class _TrainLoaderState extends State<_TrainLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _puff;
  @override void initState() {
    super.initState();
    _puff = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700))..repeat();
  }
  @override void dispose() { _puff.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.68),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (_, v, child) =>
              Transform.scale(scale: v.clamp(0.0, 1.0), child: child),
          child: Container(
            width: 240,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF334155), Color(0xFF1E293B)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: _T.amber.withOpacity(0.60), width: 2),
              boxShadow: [BoxShadow(
                  color: _T.amber.withOpacity(0.35), blurRadius: 40)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Puffing smoke + train
              AnimatedBuilder(animation: _puff,
                  builder: (_, __) {
                    final t = _puff.value;
                    return SizedBox(height: 80,
                      child: Stack(alignment: Alignment.center, children: [
                        // Smoke puffs
                        ...List.generate(3, (i) {
                          final offset = (t + i * 0.33) % 1.0;
                          final size = 10.0 + offset * 22;
                          final op = (1.0 - offset).clamp(0.0, 0.6);
                          return Positioned(
                              bottom: 38 + offset * 28,
                              left: 40.0 - i * 6,
                              child: Opacity(opacity: op,
                                  child: Container(width: size, height: size,
                                      decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.55),
                                          shape: BoxShape.circle))));
                        }),
                        const Positioned(bottom: 0,
                            child: Text('🚂', style: TextStyle(fontSize: 46))),
                      ]),
                    );
                  }),
              const SizedBox(height: 14),
              // Bouncing dots
              AnimatedBuilder(animation: _puff,
                  builder: (_, __) => Row(mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final dy = sin((_puff.value * 2 * pi) - i * pi / 3) * 6;
                        return Transform.translate(offset: Offset(0, dy),
                            child: Container(width: 10, height: 10,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                    color: _T.amber.withOpacity(0.90),
                                    shape: BoxShape.circle)));
                      }))),
              const SizedBox(height: 12),
              Text(widget.message, textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: _T.font,
                      fontSize: 15, color: _T.white)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  RAIL TRACK PAINTER  (decorative horizontal track lines)
// ═══════════════════════════════════════════════════════════════
class _RailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final railPaint = Paint()
      ..color = _T.steel.withOpacity(0.35)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    final tiePaint = Paint()
      ..color = _T.steelMid.withOpacity(0.25)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    // Two rails
    canvas.drawLine(Offset(0, size.height * 0.35),
        Offset(size.width, size.height * 0.35), railPaint);
    canvas.drawLine(Offset(0, size.height * 0.65),
        Offset(size.width, size.height * 0.65), railPaint);

    // Ties (sleepers)
    const tieSpacing = 32.0;
    for (double x = 0; x < size.width; x += tieSpacing) {
      canvas.drawLine(Offset(x, size.height * 0.28),
          Offset(x, size.height * 0.72), tiePaint);
    }
  }
  @override bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════
//  TRAIN CAR WIDGET
// ═══════════════════════════════════════════════════════════════
class _TrainCar extends StatefulWidget {
  final bool isRemoved;
  final int index;
  const _TrainCar({required this.isRemoved, required this.index});
  @override State<_TrainCar> createState() => _TrainCarState();
}
class _TrainCarState extends State<_TrainCar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset>   _slide;
  late final Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _slide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 1.5))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _fade = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl,
        curve: const Interval(0.4, 1.0)));
    if (widget.isRemoved) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_TrainCar old) {
    super.didUpdateWidget(old);
    if (widget.isRemoved && !old.isRemoved) _ctrl.forward();
    if (!widget.isRemoved && old.isRemoved) _ctrl.reset();
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Car body
          Container(
            width: 38, height: 28,
            decoration: BoxDecoration(
              color: widget.isRemoved
                  ? _T.rust.withOpacity(0.30)
                  : _T.amber.withOpacity(0.90),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: widget.isRemoved
                      ? _T.rust.withOpacity(0.60)
                      : _T.steel.withOpacity(0.60),
                  width: 1.5),
              boxShadow: widget.isRemoved ? null : [BoxShadow(
                  color: _T.amber.withOpacity(0.45), blurRadius: 6)],
            ),
            alignment: Alignment.center,
            child: Text(
                widget.isRemoved ? '💨' : '📦',
                style: const TextStyle(fontSize: 14)),
          ),
          // Wheels
          Row(mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(2, (i) => Container(
                  width: 10, height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                      color: widget.isRemoved
                          ? _T.steelMid.withOpacity(0.40)
                          : _T.steel,
                      shape: BoxShape.circle,
                      boxShadow: widget.isRemoved ? null : [
                        BoxShadow(color: _T.steel.withOpacity(0.50), blurRadius: 4)
                      ])))),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MAIN EXERCISE
// ═══════════════════════════════════════════════════════════════
class MathSubtractionExercise extends StatefulWidget {
  const MathSubtractionExercise({super.key});
  @override State<MathSubtractionExercise> createState() =>
      _MathSubtractionExerciseState();
}

class _MathSubtractionExerciseState extends State<MathSubtractionExercise>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  static const int _targetScore = 10;
  static const int _maxLives    = 3;
  static const int _maxAnswers  = 20;

  final Random _rng = Random();

  int _firstNumber   = 0;
  int _secondNumber  = 0;
  int _correctAnswer = 0;

  int  _score  = 0;
  int  _lives  = _maxLives;
  bool _showGameOver   = false;
  bool? _isAnswerCorrect;
  bool _showFinalCeleb = false;
  bool _isProcessing   = false;
  bool _showLoader     = false;
  bool _revealResult   = false; // show result in equation before moving on
  String _loaderMsg    = '';

  // animations
  late AnimationController _bgCtrl;   // subtle bg pulse
  late AnimationController _entryCtrl;
  late Animation<double>   _entryFade;
  late Animation<Offset>   _entrySlide;
  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;
  late AnimationController _padCtrl;
  late AnimationController _trainCtrl; // train arrival bounce

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _bgCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 6))..repeat(reverse: true);

    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600))..forward();
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _shakeCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _padCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 850))..forward();

    _trainCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));

    _generateNewQuestion();
    _loadBannerAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgCtrl.dispose(); _entryCtrl.dispose();
    _shakeCtrl.dispose(); _padCtrl.dispose(); _trainCtrl.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd?.dispose(); _isBannerAdLoaded = false;
    if (!mounted) return;
    if (!Provider.of<ExperienceManager>(context, listen: false).adsEnabled) return;
    _bannerAd = AdHelper.getBannerAd(
            () { if (mounted) setState(() => _isBannerAdLoaded = true); });
  }

  void _generateNewQuestion() {
    const maxN = 18;
    _firstNumber  = _rng.nextInt(maxN - 1) + 2; // 2..19
    _secondNumber = _rng.nextInt(_firstNumber - 1) + 1; // 1..(first-1)
    _correctAnswer = _firstNumber - _secondNumber;
    _isAnswerCorrect = null;
    _revealResult    = false;
    _padCtrl.reset(); _padCtrl.forward();
    _trainCtrl.reset(); _trainCtrl.forward();
    setState(() {});
  }

  Future<void> _checkAnswer(int selected) async {
    if (_isProcessing || _showGameOver) return;
    _isProcessing = true;

    final xp    = Provider.of<ExperienceManager>(context, listen: false);
    final audio = Provider.of<AudioManager>(context, listen: false);
    HapticFeedback.selectionClick();

    if (selected == _correctAnswer) {
      xp.addXP(1, context: context);
      audio.playSfx('assets/audios/QuizGame_Sounds/correct.mp3');
      HapticFeedback.lightImpact();
      // Show result in equation
      setState(() { _score++; _isAnswerCorrect = true; _revealResult = true; });

      await Future.delayed(const Duration(milliseconds: 950));
      if (!mounted) return;

      if (_score >= _targetScore) {
        if (_lives >= 1) {
          xp.addTokenBanner(context, 1);
          audio.playSfx('assets/audios/UI_Audio/SFX_Audio/VictoryOrchestral_SFX.mp3');
          audio.playSfx('assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3');
        }
        setState(() {
          _showGameOver = _showFinalCeleb = true;
          _isAnswerCorrect = null; _revealResult = false; _isProcessing = false;
        });
      } else {
        setState(() { _isAnswerCorrect = null; _isProcessing = false; });
        _generateNewQuestion();
      }
    } else {
      audio.playSfx('assets/audios/QuizGame_Sounds/incorrect.mp3');
      HapticFeedback.heavyImpact();
      _shakeCtrl.forward(from: 0).then((_) => _shakeCtrl.reset());
      setState(() {
        _lives = (_lives > 0) ? _lives - 1 : 0;
        _isAnswerCorrect = false;
      });

      await Future.delayed(const Duration(milliseconds: 850));
      if (!mounted) return;

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

  void _resetGame() {
    setState(() {
      _score = 0; _lives = _maxLives;
      _showGameOver = _showFinalCeleb = _isProcessing =
          _showLoader = _revealResult = false;
    });
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
    Provider.of<AudioManager>(context, listen: false).playEventSound('cancelButton');
    _withLoader(
      message: '🚂 All aboard!',
      action: () => AdHelper.showInterstitialAd(
          onDismissed: _resetGame, context: context),
    );
  }

  Future<bool> _confirmQuit() async {
    final audio = Provider.of<AudioManager>(context, listen: false);
    final shouldQuit = await showDialog<bool>(
      context: context, barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF334155), Color(0xFF1E293B)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: _T.amber.withOpacity(0.55), width: 2),
            boxShadow: [BoxShadow(
                color: _T.amber.withOpacity(0.30), blurRadius: 30)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🚂', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 10),
            Text(tr(context).areYouSureQuitGame,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: _T.font,
                    fontSize: 20, color: _T.white)),
            const SizedBox(height: 6),
            Text(tr(context).youWillLoseYourProgress,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13,
                    color: Colors.white.withOpacity(0.65))),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: _TrnBtn(label: tr(context).cancel,
                  color: Colors.white.withOpacity(0.15),
                  borderColor: Colors.white.withOpacity(0.40),
                  onTap: () { audio.playEventSound('cancelButton');
                  Navigator.pop(ctx, false); })),
              const SizedBox(width: 12),
              Expanded(child: _TrnBtn(label: tr(context).ok,
                  color: _T.rust,
                  onTap: () { audio.playEventSound('clickButton');
                  Navigator.pop(ctx, true); })),
            ]),
          ]),
        ),
      ),
    );
    if (shouldQuit ?? false) {
      await _withLoader(
        message: '🚋 Next stop — home!',
        action: () => AdHelper.showInterstitialAd(
            onDismissed: () { if (mounted) Navigator.pop(context, true); },
            context: context),
      );
      return true;
    }
    return false;
  }

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
        backgroundColor: _T.amberLight,
        bottomNavigationBar: context.watch<ExperienceManager>().adsEnabled
            ? FamilyAdBanner(bannerAd: _bannerAd, isLoaded: _isBannerAdLoaded)
            : null,
        body: Stack(children: [
          // ── ANIMATED BACKGROUND ──────────────────────────
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(const Color(0xFFFFF8E1), const Color(0xFFFFF3CD),
                        _bgCtrl.value)!,
                    Color.lerp(const Color(0xFFE0F2FE), const Color(0xFFBFE9FF),
                        _bgCtrl.value)!,
                    Color.lerp(const Color(0xFFFFF8E1), const Color(0xFFFEF3C7),
                        _bgCtrl.value)!,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // ── RAIL TRACK (decorative band) ─────────────────
          Positioned(
            bottom: 65, left: 0, right: 0,
            child: CustomPaint(
              painter: _RailPainter(),
              size: Size(MediaQuery.of(context).size.width, 55),
            ),
          ),

          // ── STEAM CLOUDS (deco) ───────────────────────────
          ..._steamDeco(),

          // ── CONTENT ──────────────────────────────────────
          SafeArea(
            child: _showGameOver ? _buildGameOver() :
            FadeTransition(opacity: _entryFade,
              child: SlideTransition(position: _entrySlide,
                child: Column(children: [
                  const Padding(padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
                      child: Userstatutbar()),
                  const SizedBox(height: 6),
                  _buildHUD(audio),
                  const SizedBox(height: 10),
                  // Train visualiser
                  _buildTrainVisualiser(),
                  const SizedBox(height: 10),
                  // Equation card
                  _buildEquationCard(),
                  const SizedBox(height: 10),
                  // Answer pad
                  Expanded(child: _buildAnswerPad()),
                  const SizedBox(height: 6),
                ]),
              ),
            ),
          ),

          // ── FEEDBACK OVERLAY ──────────────────────────────
          if (_isAnswerCorrect != null)
            IgnorePointer(child: Container(
              color: Colors.black.withOpacity(0.28),
              alignment: Alignment.center,
              child: SizedBox(width: 200, height: 200,
                  child: Lottie.asset(
                      _isAnswerCorrect!
                          ? 'assets/animations/QuizzGame_Animation/DoneAnimation.json'
                          : 'assets/animations/QuizzGame_Animation/wrong.json',
                      repeat: false)),
            )),

          // ── LOADER ───────────────────────────────────────
          if (_showLoader) _TrainLoader(message: _loaderMsg),
        ]),
      ),
    );
  }

  List<Widget> _steamDeco() => [
    Positioned(top: 30, left: 20, child: Opacity(opacity: 0.15,
        child: const Text('☁️', style: TextStyle(fontSize: 50)))),
    Positioned(top: 80, right: 30, child: Opacity(opacity: 0.12,
        child: const Text('☁️', style: TextStyle(fontSize: 36)))),
    Positioned(top: 20, right: 100, child: Opacity(opacity: 0.10,
        child: const Text('☁️', style: TextStyle(fontSize: 26)))),
  ];

  Widget _buildHUD(AudioManager audio) {
    final pct = (_score / _targetScore).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.70),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _T.amber.withOpacity(0.50), width: 1.5),
        boxShadow: [BoxShadow(color: _T.amber.withOpacity(0.18),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Row(children: [
          GestureDetector(
            onTap: () async {
              if (await _confirmQuit()) {
                audio.playEventSound("cancelButton");
                if (mounted) Navigator.pop(context);
              }
            },
            child: Container(width: 40, height: 40,
                decoration: BoxDecoration(
                    color: _T.amber.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: _T.amber.withOpacity(0.50), width: 1.5)),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 17, color: _T.steel)),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: _T.amber.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _T.amber.withOpacity(0.45), width: 1.2)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('🚂', style: TextStyle(fontSize: 14)),
            ]),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: _T.amber.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _T.amber.withOpacity(0.70), width: 1.2)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('⭐', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text('$_score/$_targetScore',
                  style: const TextStyle(fontFamily: _T.font,
                      fontSize: 14, color: _T.steel)),
            ]),
          ),
          const SizedBox(width: 8),
          Row(mainAxisSize: MainAxisSize.min,
              children: List.generate(_maxLives, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: AnimatedHeart(lost: i >= _lives)))),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(children: [
            Container(height: 10,
                color: _T.amber.withOpacity(0.18)),
            FractionallySizedBox(
              widthFactor: (_score / _targetScore).clamp(0.0, 1.0),
              child: Container(height: 10,
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFFFFB300), Color(0xFFFF6B35),
                            Color(0xFFEF4444)]))),
            ),
            // Tiny train icon at progress head
            Positioned(
              left: (MediaQuery.of(context).size.width - 24 - 24) *
                  (_score / _targetScore).clamp(0.0, 1.0),
              top: -4,
              child: const Text('🚂', style: TextStyle(fontSize: 18)),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── TRAIN VISUALISER: shows firstNumber cars, removes secondNumber ──
  Widget _buildTrainVisualiser() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _T.amber.withOpacity(0.40), width: 1.5),
        boxShadow: [BoxShadow(color: _T.amber.withOpacity(0.12),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Instruction chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
              color: _T.amber.withOpacity(0.20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.amber.withOpacity(0.55), width: 1.2)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎟️', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text('$_firstNumber cars — remove $_secondNumber',
                style: const TextStyle(fontFamily: _T.font,
                    fontSize: 13, color: _T.steel)),
          ]),
        ),
        const SizedBox(height: 12),

        // Locomotive + cars
        ScaleTransition(
          scale: CurvedAnimation(parent: _trainCtrl, curve: Curves.elasticOut),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Locomotive
                const Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('🚂', style: TextStyle(fontSize: 36)),
                  SizedBox(height: 6),
                ]),
                const SizedBox(width: 4),
                // Cars
                ...List.generate(_firstNumber.clamp(0, 18), (i) {
                  final isRemoved = i >= (_firstNumber - _secondNumber);
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _TrainCar(
                        isRemoved: isRemoved, index: i),
                  );
                }),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildEquationCard() {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) {
        final dx = sin(_shakeAnim.value * pi * 7) * 9 * (1 - _shakeAnim.value);
        return Transform.translate(offset: Offset(dx, 0), child: child!);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isAnswerCorrect == true
                ? const Color(0xFF22C55E)
                : _isAnswerCorrect == false
                ? _T.rust
                : _T.amber.withOpacity(0.55),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(color: _T.amber.withOpacity(0.18),
                blurRadius: 14, offset: const Offset(0, 5)),
            if (_isAnswerCorrect == true)
              BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.40),
                  blurRadius: 22),
            if (_isAnswerCorrect == false)
              BoxShadow(color: _T.rust.withOpacity(0.40), blurRadius: 22),
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🚂', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Text(
            _revealResult
                ? '$_firstNumber − $_secondNumber = $_correctAnswer ✓'
                : '$_firstNumber − $_secondNumber = ?',
            style: TextStyle(
              fontFamily: _T.font, fontSize: 26,
              color: _revealResult
                  ? const Color(0xFF15803D)
                  : _T.steel,
              shadows: const [Shadow(color: Colors.black12, blurRadius: 4)],
            ),
          ),
          const SizedBox(width: 10),
          const Text('🏁', style: TextStyle(fontSize: 24)),
        ]),
      ),
    );
  }

  Widget _buildAnswerPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _maxAnswers,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 9, crossAxisSpacing: 9,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (_, i) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + i * 18),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Opacity(
            opacity: v.clamp(0.0, 1.0),
            child: Transform.scale(scale: v.clamp(0.01, 1.0), child: child),
          ),
          child: _TrnNumBtn(
            number: i + 1,
            color:  _T.btnColors[i % _T.btnColors.length],
            onTap:  () => _checkAnswer(i + 1),
          ),
        ),
      ),
    );
  }

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
              color: Colors.white.withOpacity(0.80),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                  color: win ? const Color(0xFF22C55E) : _T.rust, width: 2.5),
              boxShadow: [BoxShadow(
                  color: win
                      ? const Color(0xFF22C55E).withOpacity(0.25)
                      : _T.rust.withOpacity(0.25),
                  blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Column(children: [
              Text(win ? '🎉 ${tr(context).awesome}!'
                  : '💔 ${tr(context).gameOver}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: _T.font, fontSize: 30,
                      color: win ? const Color(0xFF15803D) : _T.rust)),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final lit = _score >= ((i+1) * (_targetScore/3)).round();
                    return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(lit ? '⭐' : '☆',
                            style: TextStyle(fontSize: lit ? 38 : 30,
                                color: lit ? _T.amber : Colors.grey.shade300)));
                  })),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _TRPill('⭐', tr(context).score,
                    '$_score/$_targetScore', _T.amber),
                _TRPill('❤️', tr(context).remainingLives,
                    '$_lives/$_maxLives',
                    _lives > 0 ? const Color(0xFF22C55E) : _T.rust),
              ]),
              const SizedBox(height: 20),
              _TrnBtn(label: '🚂 ${tr(context).playAgain}',
                  color: _T.amber, shadowColor: _T.amber,
                  onTap: _onReplayPressed),
              const SizedBox(height: 10),
              _TrnBtn(label: '🏠 ${tr(context).back}',
                  color: Colors.white.withOpacity(0.40),
                  borderColor: _T.amber.withOpacity(0.55),
                  onTap: () => Navigator.pop(context)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Shared small widgets ────────────────────────────────────────
class _TrnNumBtn extends StatefulWidget {
  final int number; final Color color; final VoidCallback onTap;
  const _TrnNumBtn({required this.number, required this.color, required this.onTap});
  @override State<_TrnNumBtn> createState() => _TrnNumBtnState();
}
class _TrnNumBtnState extends State<_TrnNumBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _p;
  late final Animation<double> _s;
  @override void initState() {
    super.initState();
    _p = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _s = Tween<double>(begin: 1.0, end: 0.80)
        .animate(CurvedAnimation(parent: _p, curve: Curves.easeOut));
  }
  @override void dispose() { _p.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _p.forward(),
      onTapUp: (_) => _p.reverse(),
      onTapCancel: () => _p.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(animation: _s,
        builder: (_, child) => Transform.scale(scale: _s.value, child: child),
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                  colors: [
                    Color.lerp(widget.color, Colors.white, 0.30)!,
                    widget.color,
                  ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [
                BoxShadow(color: widget.color.withOpacity(0.55),
                    blurRadius: 8, offset: const Offset(0, 4)),
              ]),
          child: Stack(alignment: Alignment.center, children: [
            Text('${widget.number}', style: const TextStyle(
                fontFamily: _T.font, fontSize: 18, color: _T.white,
                shadows: [Shadow(color: Colors.black38, blurRadius: 5,
                    offset: Offset(0, 2))])),
            // Rivet dots — industrial feel
            Positioned(top: 5, left: 5, child: Container(width: 5, height: 5,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.45),
                    shape: BoxShape.circle))),
            Positioned(top: 5, right: 5, child: Container(width: 5, height: 5,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.45),
                    shape: BoxShape.circle))),
          ]),
        ),
      ),
    );
  }
}

class _TRPill extends StatelessWidget {
  final String emoji, label, value; final Color color;
  const _TRPill(this.emoji, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.50), width: 1.5)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontFamily: _T.font,
            fontSize: 10, color: color)),
        Text(value, style: TextStyle(fontFamily: _T.font,
            fontSize: 15, fontWeight: FontWeight.w700, color: color)),
      ]));
}

class _TrnBtn extends StatelessWidget {
  final String label; final VoidCallback onTap;
  final Color color;
  final Color? borderColor, shadowColor;
  const _TrnBtn({required this.label, required this.onTap,
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
              ? [BoxShadow(color: shadowColor!.withOpacity(0.45),
              blurRadius: 14, offset: const Offset(0, 5))] : null,
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontFamily: _T.font,
            fontSize: 18, color: _T.white,
            shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
      ));
}

