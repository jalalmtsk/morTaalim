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
//  🥊 BOXING RING — Number Comparison
//  Two giant numbers face off in a neon boxing ring.
//  Tap the bigger fighter to win the round!
//  Vibrant red + gold + charcoal palette.
// ═══════════════════════════════════════════════════════════════
class _X {
  static const ring    = Color(0xFF1A1A2E);
  static const ringMid = Color(0xFF16213E);
  static const red     = Color(0xFFEF4444);
  static const gold    = Color(0xFFFFD700);
  static const blue    = Color(0xFF3B82F6);
  static const lime    = Color(0xFF39FF14);
  static const white   = Color(0xFFFFFFFF);
  static const chalk   = Color(0xFFF8FAFC);

  // Corner colors for the two fighters
  static const cornerA = Color(0xFFEF4444); // red corner
  static const cornerB = Color(0xFF3B82F6); // blue corner

  static const String font = 'Fredoka One';
}

// ═══════════════════════════════════════════════════════════════
//  WRAPPER
// ═══════════════════════════════════════════════════════════════
class NumberComparisonGame extends StatelessWidget {
  const NumberComparisonGame({super.key});
  @override Widget build(BuildContext context) => const NumberComparisonExercise();
}

// ═══════════════════════════════════════════════════════════════
//  LOADING OVERLAY
// ═══════════════════════════════════════════════════════════════
class _BoxingLoader extends StatefulWidget {
  final String message;
  const _BoxingLoader({required this.message});
  @override State<_BoxingLoader> createState() => _BoxingLoaderState();
}
class _BoxingLoaderState extends State<_BoxingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _punch;
  @override void initState() {
    super.initState();
    _punch = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }
  @override void dispose() { _punch.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.72),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (_, v, child) =>
              Transform.scale(scale: v.clamp(0.0, 1.0), child: child),
          child: Container(
            width: 230,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: _X.gold.withOpacity(0.60), width: 2),
              boxShadow: [BoxShadow(
                  color: _X.gold.withOpacity(0.35), blurRadius: 40)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedBuilder(animation: _punch,
                  builder: (_, __) {
                    final t = _punch.value;
                    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Transform.translate(offset: Offset(t * 12, 0),
                          child: const Text('🥊', style: TextStyle(fontSize: 38))),
                      const SizedBox(width: 16),
                      Transform.translate(offset: Offset(-(t * 12), 0),
                          child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(pi),
                              child: const Text('🥊', style: TextStyle(fontSize: 38)))),
                    ]);
                  }),
              const SizedBox(height: 16),
              AnimatedBuilder(animation: _punch,
                  builder: (_, __) => Row(mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final dy = sin((_punch.value * 2 * pi) - i * pi / 3) * 6;
                        return Transform.translate(offset: Offset(0, dy),
                            child: Container(width: 10, height: 10,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                    color: _X.gold.withOpacity(0.85),
                                    shape: BoxShape.circle)));
                      }))),
              const SizedBox(height: 12),
              Text(widget.message, textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: _X.font,
                      fontSize: 15, color: _X.white)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  RING ROPES PAINTER
// ═══════════════════════════════════════════════════════════════
class _RopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ropePaint = Paint()
      ..strokeWidth = 4.5 ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void rope(Color c, double yFrac) {
      ropePaint.color = c;
      canvas.drawLine(Offset(0, size.height * yFrac),
          Offset(size.width, size.height * yFrac), ropePaint);
    }
    rope(_X.red.withOpacity(0.70), 0.20);
    rope(_X.white.withOpacity(0.50), 0.50);
    rope(_X.blue.withOpacity(0.70), 0.80);

    // Corner posts
    final postPaint = Paint()
      ..color = _X.gold.withOpacity(0.60) ..strokeWidth = 10
      ..style = PaintingStyle.stroke ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(6, 0), Offset(6, size.height), postPaint);
    canvas.drawLine(Offset(size.width-6, 0),
        Offset(size.width-6, size.height), postPaint);
  }
  @override bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════
//  FIGHTER CARD  — presses in on tap
// ═══════════════════════════════════════════════════════════════
class _FighterCard extends StatefulWidget {
  final int number;
  final Color color;
  final String label;    // "RED CORNER" / "BLUE CORNER"
  final String emoji;
  final bool isWinner;
  final bool isLoser;
  final VoidCallback onTap;
  const _FighterCard({
    required this.number, required this.color, required this.label,
    required this.emoji, required this.isWinner, required this.isLoser,
    required this.onTap,
  });
  @override State<_FighterCard> createState() => _FighterCardState();
}
class _FighterCardState extends State<_FighterCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double>   _scale;
  @override void initState() {
    super.initState();
    _press = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.90)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }
  @override void dispose() { _press.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    Color borderColor = widget.color.withOpacity(0.50);
    if (widget.isWinner) borderColor = _X.lime;
    if (widget.isLoser)  borderColor = _X.red.withOpacity(0.80);

    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp:   (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [
                  Color.lerp(widget.color, Colors.black, 0.55)!,
                  Color.lerp(widget.color, Colors.black, 0.35)!,
                ], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 3),
            boxShadow: [
              BoxShadow(color: widget.color.withOpacity(0.55),
                  blurRadius: 20, offset: const Offset(0, 8)),
              if (widget.isWinner)
                BoxShadow(color: _X.lime.withOpacity(0.60), blurRadius: 28),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Corner label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: widget.color.withOpacity(0.70), width: 1)),
              child: Text(widget.label,
                  style: const TextStyle(fontFamily: _X.font,
                      fontSize: 10, color: _X.white,
                      letterSpacing: 1.0)),
            ),
            const SizedBox(height: 12),
            // Fighter emoji
            Text(widget.emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            // The BIG number
            Text('${widget.number}',
                style: TextStyle(
                  fontFamily: _X.font, fontSize: 60,
                  color: widget.isWinner ? _X.lime : _X.white,
                  shadows: [
                    Shadow(color: widget.color, blurRadius: 16, offset: const Offset(0, 4)),
                    const Shadow(color: Colors.black54, blurRadius: 8),
                  ],
                )),
            const SizedBox(height: 8),
            // Status badge
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: widget.isWinner
                  ? Container(key: const ValueKey('win'),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                      color: _X.lime.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _X.lime, width: 1.5)),
                  child: const Text('🏆 WINNER!',
                      style: TextStyle(fontFamily: _X.font,
                          fontSize: 14, color: _X.lime)))
                  : widget.isLoser
                  ? Container(key: const ValueKey('lose'),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                      color: _X.red.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _X.red, width: 1.5)),
                  child: const Text('😵 OUT!',
                      style: TextStyle(fontFamily: _X.font,
                          fontSize: 14, color: _X.red)))
                  : Container(key: const ValueKey('tap'),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                      color: _X.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _X.white.withOpacity(0.30), width: 1)),
                  child: const Text('TAP TO PICK',
                      style: TextStyle(fontFamily: _X.font,
                          fontSize: 12, color: _X.white))),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MAIN EXERCISE
// ═══════════════════════════════════════════════════════════════
class NumberComparisonExercise extends StatefulWidget {
  const NumberComparisonExercise({super.key});
  @override State<NumberComparisonExercise> createState() =>
      _NumberComparisonExerciseState();
}

class _NumberComparisonExerciseState extends State<NumberComparisonExercise>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  static const int _targetScore = 10;
  static const int _maxLives    = 3;
  static const int _maxNumber   = 20;

  final Random _rng = Random();

  int  _numberA = 0;
  int  _numberB = 0;
  bool? _isAnswerCorrect;
  int? _winnerNumber;   // revealed after answer

  int  _score  = 0;
  int  _lives  = _maxLives;
  bool _showGameOver   = false;
  bool _showFinalCeleb = false;
  bool _isProcessing   = false;
  bool _showLoader     = false;
  String _loaderMsg    = '';

  late AnimationController _bgCtrl;
  late AnimationController _entryCtrl;
  late Animation<double>   _entryFade;
  late AnimationController _bellCtrl;  // bell ring on new question
  late Animation<double>   _bellScale;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _bgCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 5))..repeat(reverse: true);

    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600))..forward();
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _bellCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _bellScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0),  weight: 60),
    ]).animate(CurvedAnimation(parent: _bellCtrl, curve: Curves.easeOut));

    _generateNewQuestion();
    _loadBannerAd();
  }

  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgCtrl.dispose(); _entryCtrl.dispose(); _bellCtrl.dispose();
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
    _numberA = _rng.nextInt(_maxNumber) + 1;
    do { _numberB = _rng.nextInt(_maxNumber) + 1; } while (_numberB == _numberA);
    _isAnswerCorrect = null;
    _winnerNumber    = null;
    _bellCtrl.reset(); _bellCtrl.forward();
    setState(() {});
  }

  Future<void> _checkAnswer(int selected) async {
    if (_isProcessing || _showGameOver) return;
    _isProcessing = true;

    final xp    = Provider.of<ExperienceManager>(context, listen: false);
    final audio = Provider.of<AudioManager>(context, listen: false);
    HapticFeedback.selectionClick();

    final correct = _numberA > _numberB ? _numberA : _numberB;

    if (selected == correct) {
      xp.addXP(1, context: context);
      audio.playSfx('assets/audios/QuizGame_Sounds/correct.mp3');
      HapticFeedback.lightImpact();
      setState(() { _score++; _isAnswerCorrect = true; _winnerNumber = correct; });

      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;

      if (_score >= _targetScore) {
        if (_lives >= 1) {
          xp.addTokenBanner(context, 1);
          audio.playSfx('assets/audios/UI_Audio/SFX_Audio/VictoryOrchestral_SFX.mp3');
          audio.playSfx('assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3');
        }
        setState(() {
          _showGameOver = _showFinalCeleb = true;
          _isAnswerCorrect = null; _winnerNumber = null; _isProcessing = false;
        });
      } else {
        setState(() { _isAnswerCorrect = null; _winnerNumber = null; _isProcessing = false; });
        _generateNewQuestion();
      }
    } else {
      audio.playSfx('assets/audios/QuizGame_Sounds/incorrect.mp3');
      HapticFeedback.heavyImpact();
      setState(() {
        _lives = (_lives > 0) ? _lives - 1 : 0;
        _isAnswerCorrect = false; _winnerNumber = correct;
      });

      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;

      if (_lives == 0) {
        audio.playSfx("assets/audios/UI_Audio/SFX_Audio/FailMeme_SFX.mp3");
        setState(() {
          _showGameOver = true; _isAnswerCorrect = null;
          _winnerNumber = null; _isProcessing = false;
        });
      } else {
        setState(() {
          _isAnswerCorrect = null; _winnerNumber = null; _isProcessing = false;
        });
        _generateNewQuestion();
      }
    }
  }

  void _resetGame() {
    setState(() {
      _score = 0; _lives = _maxLives;
      _showGameOver = _showFinalCeleb = _isProcessing = _showLoader = false;
      _winnerNumber = null;
    });
    _generateNewQuestion();
  }

  Future<void> _withLoader({required String message,
    required Future<void> Function() action}) async {
    setState(() { _showLoader = true; _loaderMsg = message; });
    await Future.delayed(const Duration(milliseconds: 300));
    await action();
    if (mounted) setState(() => _showLoader = false);
  }

  void _onReplayPressed() {
    Provider.of<AudioManager>(context, listen: false).playEventSound('cancelButton');
    _withLoader(message: '🥊 Next round loading...',
        action: () => AdHelper.showInterstitialAd(
            onDismissed: _resetGame, context: context));
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
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: _X.gold.withOpacity(0.55), width: 2),
            boxShadow: [BoxShadow(
                color: _X.gold.withOpacity(0.25), blurRadius: 30)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🥊', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 10),
            Text(tr(context).areYouSureQuitGame, textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: _X.font,
                    fontSize: 20, color: _X.white)),
            const SizedBox(height: 6),
            Text(tr(context).youWillLoseYourProgress, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13,
                    color: Colors.white.withOpacity(0.65))),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: _RingBtn(label: tr(context).cancel,
                  color: Colors.white.withOpacity(0.15),
                  borderColor: Colors.white.withOpacity(0.40),
                  onTap: () { audio.playEventSound('cancelButton');
                  Navigator.pop(ctx, false); })),
              const SizedBox(width: 12),
              Expanded(child: _RingBtn(label: tr(context).ok,
                  color: _X.red, onTap: () { audio.playEventSound('clickButton');
                  Navigator.pop(ctx, true); })),
            ]),
          ]),
        ),
      ),
    );
    if (shouldQuit ?? false) {
      await _withLoader(message: '🔔 Fight over!',
          action: () => AdHelper.showInterstitialAd(
              onDismissed: () { if (mounted) Navigator.pop(context, true); },
              context: context));
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioManager>(context, listen: false);
    return WillPopScope(
      onWillPop: () async {
        final q = await _confirmQuit();
        if (q && mounted) audio.playEventSound("cancelButton");
        return q;
      },
      child: Scaffold(
        backgroundColor: _X.ring,
        bottomNavigationBar: context.watch<ExperienceManager>().adsEnabled
            ? _RingBannerBar(bannerAd: _bannerAd, isLoaded: _isBannerAdLoaded)
            : null,
        body: Stack(children: [
          // Animated dark BG
          AnimatedBuilder(animation: _bgCtrl,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [
                        Color.lerp(const Color(0xFF1A1A2E), const Color(0xFF0F0F23),
                            _bgCtrl.value)!,
                        Color.lerp(const Color(0xFF16213E), const Color(0xFF1A0A2E),
                            _bgCtrl.value)!,
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            ),
          ),

          // Ring ropes band
          Positioned(left: 0, right: 0, top: 160, height: 180,
              child: CustomPaint(painter: _RopePainter())),

          // Spotlight effects
          ..._spotlights(),

          SafeArea(
            child: _showGameOver ? _buildGameOver() :
            FadeTransition(opacity: _entryFade,
              child: Column(children: [
                const Padding(padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Userstatutbar()),
                const SizedBox(height: 6),
                _buildHUD(audio),
                const SizedBox(height: 12),
                // ROUND bell
                _buildBellRow(),
                const SizedBox(height: 12),
                // The two fighters
                Expanded(child: _buildFighters()),
              ]),
            ),
          ),

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
          if (_showLoader) _BoxingLoader(message: _loaderMsg),
        ]),
      ),
    );
  }

  List<Widget> _spotlights() => [
    Positioned(top: -80, left: -80,
        child: Container(width: 300, height: 300,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _X.gold.withOpacity(0.07), Colors.transparent])))),
    Positioned(top: -80, right: -80,
        child: Container(width: 280, height: 280,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _X.red.withOpacity(0.06), Colors.transparent])))),
  ];

  Widget _buildHUD(AudioManager audio) {
    final pct = (_score / _targetScore).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _X.gold.withOpacity(0.22), width: 1.5),
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
                    color: _X.gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: _X.gold.withOpacity(0.40), width: 1.5)),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 17, color: _X.gold)),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: _X.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _X.gold.withOpacity(0.35), width: 1.2)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('🥊', style: TextStyle(fontSize: 14)),
              SizedBox(width: 5),
              Text('Boxing Ring', style: TextStyle(fontFamily: _X.font,
                  fontSize: 13, color: _X.white)),
            ]),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: _X.gold.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _X.gold.withOpacity(0.55), width: 1.2)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('⭐', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text('$_score/$_targetScore',
                  style: const TextStyle(fontFamily: _X.font,
                      fontSize: 14, color: _X.gold)),
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
            Container(height: 8, color: Colors.white.withOpacity(0.08)),
            FractionallySizedBox(
              widthFactor: (_score / _targetScore).clamp(0.0, 1.0),
              child: Container(height: 8,
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFEF4444),
                            Color(0xFF3B82F6)]))),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildBellRow() {
    return ScaleTransition(
      scale: _bellScale,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🔔', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _X.gold.withOpacity(0.40), width: 1.5),
          ),
          child: Text(tr(context).whichIsTheLargestNumber,
              style: const TextStyle(fontFamily: _X.font,
                  fontSize: 16, color: _X.white)),
        ),
        const SizedBox(width: 10),
        const Text('🔔', style: TextStyle(fontSize: 22)),
      ]),
    );
  }

  Widget _buildFighters() {
    final correct = _numberA > _numberB ? _numberA : _numberB;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Expanded(child: _FighterCard(
            number: _numberA,
            color:  _X.cornerA,
            label:  'RED CORNER',
            emoji:  '🥊',
            isWinner: _winnerNumber == _numberA,
            isLoser:  _winnerNumber != null && _winnerNumber != _numberA,
            onTap: () => _checkAnswer(_numberA),
          )),
          // VS separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                  boxShadow: [BoxShadow(
                      color: _X.gold.withOpacity(0.60), blurRadius: 14)],
                ),
                alignment: Alignment.center,
                child: Text(tr(context).or ?? 'VS',
                    style: const TextStyle(fontFamily: _X.font,
                        fontSize: 14, color: _X.ring)),
              ),
            ]),
          ),
          Expanded(child: _FighterCard(
            number: _numberB,
            color:  _X.cornerB,
            label:  'BLUE CORNER',
            emoji:  '🥊',
            isWinner: _winnerNumber == _numberB,
            isLoser:  _winnerNumber != null && _winnerNumber != _numberB,
            onTap: () => _checkAnswer(_numberB),
          )),
        ],
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
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                  color: win ? _X.lime : _X.red, width: 2.5),
              boxShadow: [BoxShadow(
                  color: win ? _X.lime.withOpacity(0.25) : _X.red.withOpacity(0.25),
                  blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Column(children: [
              Text(win ? '🏆 ${tr(context).awesome}!'
                  : '💔 ${tr(context).gameOver}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: _X.font, fontSize: 30,
                      color: win ? _X.lime : _X.red)),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final lit = _score >= ((i+1)*(_targetScore/3)).round();
                    return Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(lit ? '⭐' : '☆',
                            style: TextStyle(fontSize: lit ? 38 : 30,
                                color: lit ? _X.gold : Colors.white24)));
                  })),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _XPill('⭐', tr(context).score, '$_score/$_targetScore', _X.gold),
                _XPill('❤️', tr(context).remainingLives,
                    '$_lives/$_maxLives',
                    _lives > 0 ? _X.lime : _X.red),
              ]),
              const SizedBox(height: 20),
              _RingBtn(label: '🥊 ${tr(context).playAgain}',
                  color: _X.gold.withOpacity(0.90),
                  shadowColor: _X.gold, onTap: _onReplayPressed),
              const SizedBox(height: 10),
              _RingBtn(label: '🏠 ${tr(context).back}',
                  color: Colors.white.withOpacity(0.10),
                  borderColor: _X.gold.withOpacity(0.40),
                  onTap: () => Navigator.pop(context)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _XPill extends StatelessWidget {
  final String emoji, label, value; final Color color;
  const _XPill(this.emoji, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.50), width: 1.5)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontFamily: _X.font, fontSize: 10, color: color)),
        Text(value, style: TextStyle(fontFamily: _X.font, fontSize: 15,
            fontWeight: FontWeight.w700, color: color)),
      ]));
}

class _RingBtn extends StatelessWidget {
  final String label; final VoidCallback onTap; final Color color;
  final Color? borderColor, shadowColor;
  const _RingBtn({required this.label, required this.onTap,
    required this.color, this.borderColor, this.shadowColor});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(20),
              border: borderColor != null ? Border.all(color: borderColor!, width: 1.8) : null,
              boxShadow: shadowColor != null ? [BoxShadow(
                  color: shadowColor!.withOpacity(0.45), blurRadius: 14,
                  offset: const Offset(0, 5))] : null),
          alignment: Alignment.center,
          child: Text(label, style: const TextStyle(fontFamily: _X.font,
              fontSize: 18, color: _X.ring,
              shadows: [Shadow(color: Colors.black26, blurRadius: 4)]))));
}

class _RingBannerBar extends StatefulWidget {
  final BannerAd? bannerAd; final bool isLoaded;
  const _RingBannerBar({required this.bannerAd, required this.isLoaded});
  @override State<_RingBannerBar> createState() => _RingBannerBarState();
}
class _RingBannerBarState extends State<_RingBannerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _s;
  late final Animation<double> _a;
  @override void initState() {
    super.initState();
    _s = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _a = CurvedAnimation(parent: _s, curve: Curves.easeInOut);
  }
  @override void dispose() { _s.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final adH = (widget.bannerAd?.size.height ?? 50).toDouble();
    return SafeArea(top: false,
        child: Container(
          height: adH + 10,
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]),
              border: Border(top: BorderSide(
                  color: Color(0x55FFD700), width: 1.5))),
          child: widget.isLoaded && widget.bannerAd != null
              ? Center(child: SizedBox(height: adH,
              width: widget.bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: widget.bannerAd!)))
              : AnimatedBuilder(animation: _a, builder: (_, __) {
            final t = _a.value;
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(children: [
                  Opacity(opacity: 0.5+t*0.5, child: const Text('🥊', style: TextStyle(fontSize: 18))),
                  const SizedBox(width: 10),
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12),
                      child: Container(height: 28,
                          color: _X.gold.withOpacity(0.12+t*0.12),
                          alignment: Alignment.center,
                          child: Text('✨  Advertisement  ✨',
                              style: TextStyle(fontFamily: _X.font, fontSize: 12,
                                  color: _X.gold.withOpacity(0.60+t*0.30)))))),
                  const SizedBox(width: 10),
                  Opacity(opacity: 0.5+t*0.5, child: const Text('🥊', style: TextStyle(fontSize: 18))),
                ]));
          }),
        ));
  }
}