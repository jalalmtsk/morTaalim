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
import '../../l10n/app_localizations.dart';
import '../../tools/Ads_Manager.dart';
import 'Tools/AnimatedHeart.dart';

// ═══════════════════════════════════════════════════════════════
//  🎡 CARNIVAL WHEEL — Even / Odd
//  A big spinning ferris-wheel-style number in the centre.
//  Two large funfair booths: EVEN (pink) and ODD (violet).
//  Tap the right booth!  Bright carnival palette.
// ═══════════════════════════════════════════════════════════════
class _C {
  static const pink    = Color(0xFFFF6B9D);
  static const violet  = Color(0xFF7B2FFF);
  static const yellow  = Color(0xFFFFE566);
  static const teal    = Color(0xFF00D4AA);
  static const white   = Color(0xFFFFFFFF);
  static const dark    = Color(0xFF1A0A2E);
  static const cream   = Color(0xFFFFF8F0);

  static const String font = 'Fredoka One';
}

// ═══════════════════════════════════════════════════════════════
//  WRAPPER
// ═══════════════════════════════════════════════════════════════
class EvenOddGame extends StatelessWidget {
  const EvenOddGame({super.key});
  @override Widget build(BuildContext context) => const EvenOddExercise();
}

// ═══════════════════════════════════════════════════════════════
//  LOADING OVERLAY
// ═══════════════════════════════════════════════════════════════
class _CarnivalLoader extends StatefulWidget {
  final String message;
  const _CarnivalLoader({required this.message});
  @override State<_CarnivalLoader> createState() => _CarnivalLoaderState();
}
class _CarnivalLoaderState extends State<_CarnivalLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  @override void initState() {
    super.initState();
    _spin = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))..repeat();
  }
  @override void dispose() { _spin.dispose(); super.dispose(); }
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
            width: 230,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFF7B2FFF)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [BoxShadow(
                  color: _C.pink.withOpacity(0.60), blurRadius: 40)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedBuilder(animation: _spin,
                  builder: (_, __) => Transform.rotate(
                      angle: _spin.value * 2 * pi,
                      child: const Text('🎡', style: TextStyle(fontSize: 56)))),
              const SizedBox(height: 16),
              AnimatedBuilder(animation: _spin,
                  builder: (_, __) => Row(mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final dy = sin((_spin.value * 2 * pi) - i * pi / 3) * 6;
                        return Transform.translate(offset: Offset(0, dy),
                            child: Container(width: 10, height: 10,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.85),
                                    shape: BoxShape.circle)));
                      }))),
              const SizedBox(height: 12),
              Text(widget.message, textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: _C.font,
                      fontSize: 15, color: _C.white)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SPINNING NUMBER WHEEL  (the main visual)
// ═══════════════════════════════════════════════════════════════
class _NumberWheel extends StatefulWidget {
  final int number;
  final bool isEven;
  const _NumberWheel({required this.number, required this.isEven});
  @override State<_NumberWheel> createState() => _NumberWheelState();
}
class _NumberWheelState extends State<_NumberWheel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;
  late final Animation<double>   _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _scale  = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _rotate = Tween<double>(begin: -0.1, end: 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_NumberWheel old) {
    super.didUpdateWidget(old);
    if (old.number != widget.number) { _ctrl.reset(); _ctrl.forward(); }
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.isEven ? _C.pink : _C.violet;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value.clamp(0.0, 1.1),
        child: Transform.rotate(angle: _rotate.value,
          child: Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.35),
                  radius: 0.85,
                  colors: [
                    Color.lerp(color, Colors.white, 0.30)!,
                    color,
                    Color.lerp(color, Colors.black, 0.22)!,
                  ], stops: const [0.0, 0.55, 1.0]),
              border: Border.all(color: _C.yellow, width: 5),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.70),
                    blurRadius: 28, offset: const Offset(0, 8)),
                BoxShadow(color: _C.yellow.withOpacity(0.50), blurRadius: 16),
              ],
            ),
            child: Stack(alignment: Alignment.center, children: [
              // Shine
              Positioned(top: 18, left: 24,
                  child: Container(width: 36, height: 20,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.30),
                          borderRadius: BorderRadius.circular(12)))),
              Text('${widget.number}',
                  style: const TextStyle(
                    fontFamily: _C.font, fontSize: 68,
                    color: _C.white,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 10,
                        offset: Offset(0, 4))],
                  )),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  BOOTH BUTTON  (Even / Odd)
// ═══════════════════════════════════════════════════════════════
class _BoothBtn extends StatefulWidget {
  final String label;
  final String emoji;
  final Color color;
  final bool isCorrect;    // revealed after tap
  final bool isWrong;
  final VoidCallback onTap;
  const _BoothBtn({required this.label, required this.emoji,
    required this.color, required this.isCorrect,
    required this.isWrong, required this.onTap});
  @override State<_BoothBtn> createState() => _BoothBtnState();
}
class _BoothBtnState extends State<_BoothBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double>   _scale;
  @override void initState() {
    super.initState();
    _press = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 90));
    _scale = Tween<double>(begin: 1.0, end: 0.90)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }
  @override void dispose() { _press.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    Color border = widget.color.withOpacity(0.55);
    if (widget.isCorrect) border = const Color(0xFF39FF14);
    if (widget.isWrong)   border = const Color(0xFFFF2D55);

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
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [
                  Color.lerp(widget.color, Colors.white, 0.15)!,
                  widget.color,
                  Color.lerp(widget.color, Colors.black, 0.28)!,
                ], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: border, width: 3.5),
            boxShadow: [
              BoxShadow(color: widget.color.withOpacity(0.55),
                  blurRadius: 20, offset: const Offset(0, 8)),
              if (widget.isCorrect)
                BoxShadow(color: const Color(0xFF39FF14).withOpacity(0.55),
                    blurRadius: 28),
              if (widget.isWrong)
                BoxShadow(color: const Color(0xFFFF2D55).withOpacity(0.50),
                    blurRadius: 22),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            Text(widget.label,
                style: const TextStyle(fontFamily: _C.font,
                    fontSize: 26, color: _C.white,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 6)])),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: widget.isCorrect
                  ? const Text('✓ YES!', key: ValueKey('y'),
                  style: TextStyle(fontFamily: _C.font, fontSize: 14,
                      color: Color(0xFF39FF14)))
                  : widget.isWrong
                  ? const Text('✗ NOPE', key: ValueKey('n'),
                  style: TextStyle(fontFamily: _C.font, fontSize: 14,
                      color: Color(0xFFFF2D55)))
                  : Text('TAP ME!', key: const ValueKey('t'),
                  style: TextStyle(fontFamily: _C.font, fontSize: 13,
                      color: Colors.white.withOpacity(0.65))),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PENNANT PAINTER  (string of carnival flags)
// ═══════════════════════════════════════════════════════════════
class _PennantPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.5 ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, 12), Offset(size.width, 12), linePaint);

    final colors = [_C.pink, _C.yellow, _C.violet, _C.teal,
      _C.pink, _C.yellow, _C.violet, _C.teal];
    final count = size.width ~/ 26;
    for (int i = 0; i < count; i++) {
      final x = i * (size.width / count) + size.width / count / 2;
      final paint = Paint()
        ..color = colors[i % colors.length].withOpacity(0.75)
        ..style = PaintingStyle.fill;
      final path = Path()
        ..moveTo(x - 8, 0)..lineTo(x + 8, 0)..lineTo(x, 20)..close();
      canvas.drawPath(path, paint);
    }
  }
  @override bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════
//  MAIN EXERCISE
// ═══════════════════════════════════════════════════════════════
class EvenOddExercise extends StatefulWidget {
  const EvenOddExercise({super.key});
  @override State<EvenOddExercise> createState() => _EvenOddExerciseState();
}

class _EvenOddExerciseState extends State<EvenOddExercise>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  static const int _targetScore = 10;
  static const int _maxLives    = 3;

  final Random _rng = Random();

  int  _targetNumber = 1;
  bool _isEven       = false;
  bool? _isAnswerCorrect;
  bool? _selectedEven; // tracks which booth was tapped

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
  late AnimationController _lightCtrl; // carnival lights blink

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
    _lightCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800))..repeat(reverse: true);

    _generateNewQuestion();
    _loadBannerAd();
  }

  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgCtrl.dispose(); _entryCtrl.dispose(); _lightCtrl.dispose();
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
    _targetNumber    = _rng.nextInt(50) + 1;
    _isEven          = _targetNumber % 2 == 0;
    _isAnswerCorrect = null;
    _selectedEven    = null;
    setState(() {});
  }

  Future<void> _checkAnswer(bool selectedEven) async {
    if (_isProcessing || _showGameOver) return;
    _isProcessing = true;

    final xp    = Provider.of<ExperienceManager>(context, listen: false);
    final audio = Provider.of<AudioManager>(context, listen: false);
    HapticFeedback.selectionClick();

    setState(() { _selectedEven = selectedEven; });

    if (selectedEven == _isEven) {
      xp.addXP(1, context: context);
      audio.playSfx('assets/audios/QuizGame_Sounds/correct.mp3');
      HapticFeedback.lightImpact();
      setState(() { _score++; _isAnswerCorrect = true; });

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
          _isAnswerCorrect = null; _isProcessing = false;
        });
      } else {
        setState(() { _isAnswerCorrect = null; _isProcessing = false; });
        _generateNewQuestion();
      }
    } else {
      audio.playSfx('assets/audios/QuizGame_Sounds/incorrect.mp3');
      HapticFeedback.heavyImpact();
      setState(() {
        _lives = (_lives > 0) ? _lives - 1 : 0;
        _isAnswerCorrect = false;
      });

      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;

      if (_lives == 0) {
        audio.playSfx("assets/audios/UI_Audio/SFX_Audio/FailMeme_SFX.mp3");
        setState(() {
          _showGameOver = true; _isAnswerCorrect = null; _isProcessing = false;
        });
      } else {
        setState(() {
          _isAnswerCorrect = null; _selectedEven = null; _isProcessing = false;
        });
      }
    }
  }

  void _resetGame() {
    setState(() {
      _score = 0; _lives = _maxLives;
      _showGameOver = _showFinalCeleb = _isProcessing = _showLoader = false;
      _selectedEven = null;
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
    _withLoader(message: '🎡 Spinning up next round...',
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
                colors: [Color(0xFFFF6B9D), Color(0xFF7B2FFF)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(
                color: _C.pink.withOpacity(0.55), blurRadius: 30)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎡', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 10),
            Text(tr(context).areYouSureQuitGame, textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: _C.font,
                    fontSize: 20, color: _C.white)),
            const SizedBox(height: 6),
            Text(tr(context).youWillLoseYourProgress, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13,
                    color: Colors.white.withOpacity(0.75))),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: _CarnBtn(label: tr(context).cancel,
                  color: Colors.white.withOpacity(0.20),
                  borderColor: Colors.white.withOpacity(0.55),
                  onTap: () { audio.playEventSound('cancelButton');
                  Navigator.pop(ctx, false); })),
              const SizedBox(width: 12),
              Expanded(child: _CarnBtn(label: tr(context).ok,
                  color: const Color(0xFFFF2D55),
                  onTap: () { audio.playEventSound('clickButton');
                  Navigator.pop(ctx, true); })),
            ]),
          ]),
        ),
      ),
    );
    if (shouldQuit ?? false) {
      await _withLoader(message: '👋 Thanks for playing!',
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
        backgroundColor: _C.dark,
        bottomNavigationBar: context.watch<ExperienceManager>().adsEnabled
            ? _CarnBannerBar(bannerAd: _bannerAd, isLoaded: _isBannerAdLoaded)
            : null,
        body: Stack(children: [
          // Animated gradient BG
          AnimatedBuilder(animation: _bgCtrl,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [
                        Color.lerp(const Color(0xFF1A0A2E), const Color(0xFF0D0120),
                            _bgCtrl.value)!,
                        Color.lerp(const Color(0xFF2D0A4E), const Color(0xFF1A0A3E),
                            _bgCtrl.value)!,
                        Color.lerp(const Color(0xFF0A1A3E), const Color(0xFF050D2A),
                            _bgCtrl.value)!,
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            ),
          ),

          // Carnival light dots deco
          AnimatedBuilder(animation: _lightCtrl, builder: (_, __) {
            final t = _lightCtrl.value;
            return Stack(children: [
              ..._lightDots(t),
            ]);
          }),

          // Pennant flags at top
          Positioned(top: 0, left: 0, right: 0,
              child: SizedBox(height: 28,
                  child: CustomPaint(painter: _PennantPainter()))),

          SafeArea(
            child: _showGameOver ? _buildGameOver() :
            FadeTransition(opacity: _entryFade,
              child: Column(children: [
                const Padding(padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Userstatutbar()),
                const SizedBox(height: 4),
                _buildHUD(audio),
                const SizedBox(height: 12),
                // The spinning number
                Center(child: _NumberWheel(
                    number: _targetNumber, isEven: _isEven)),
                const SizedBox(height: 8),
                // Hint label
                Text(
                  AppLocalizations.of(context)?.isNumberEvenOrOdd(_targetNumber) ??
                      'Is $_targetNumber even or odd?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: _C.font,
                      fontSize: 18, color: _C.white),
                ),
                const SizedBox(height: 16),
                // Two booth buttons
                Expanded(child: _buildBooths()),
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
          if (_showLoader) _CarnivalLoader(message: _loaderMsg),
        ]),
      ),
    );
  }

  List<Widget> _lightDots(double t) {
    final positions = [
      [0.05, 0.12], [0.20, 0.08], [0.50, 0.06], [0.75, 0.10], [0.92, 0.14],
      [0.10, 0.90], [0.30, 0.95], [0.60, 0.92], [0.85, 0.88],
    ];
    final colors = [_C.pink, _C.yellow, _C.teal, _C.violet,
      _C.pink, _C.yellow, _C.teal, _C.violet, _C.pink];
    final size = MediaQuery.of(context).size;
    return List.generate(positions.length, (i) {
      final blink = (i % 2 == 0) ? t : 1 - t;
      return Positioned(
        left: positions[i][0] * size.width - 6,
        top:  positions[i][1] * size.height - 6,
        child: Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              color: colors[i % colors.length].withOpacity(0.30 + blink * 0.55),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: colors[i % colors.length].withOpacity(blink * 0.70),
                  blurRadius: 8)],
            )),
      );
    });
  }

  Widget _buildHUD(AudioManager audio) {
    final pct = (_score / _targetScore).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.pink.withOpacity(0.30), width: 1.5),
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
                    color: _C.pink.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: _C.pink.withOpacity(0.40), width: 1.5)),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 17, color: _C.pink)),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: _C.pink.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.pink.withOpacity(0.40), width: 1.2)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('🎡', style: TextStyle(fontSize: 14)),
              SizedBox(width: 5),
              Text('Even or Odd?', style: TextStyle(fontFamily: _C.font,
                  fontSize: 13, color: _C.white)),
            ]),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: _C.yellow.withOpacity(0.20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.yellow.withOpacity(0.60), width: 1.2)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('⭐', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text('$_score/$_targetScore',
                  style: const TextStyle(fontFamily: _C.font,
                      fontSize: 14, color: _C.yellow)),
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
              widthFactor: pct,
              child: Container(height: 8,
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFFFF6B9D), Color(0xFFFFE566),
                            Color(0xFF7B2FFF)]))),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildBooths() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(child: _BoothBtn(
            label: AppLocalizations.of(context)?.even ?? 'EVEN',
            emoji: '🎀',
            color: _C.pink,
            isCorrect: _selectedEven == true && _isEven,
            isWrong:   _selectedEven == true && !_isEven,
            onTap: () => _checkAnswer(true),
          )),
          const SizedBox(width: 14),
          Expanded(child: _BoothBtn(
            label: AppLocalizations.of(context)?.odd ?? 'ODD',
            emoji: '⚡',
            color: _C.violet,
            isCorrect: _selectedEven == false && !_isEven,
            isWrong:   _selectedEven == false && _isEven,
            onTap: () => _checkAnswer(false),
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
                  color: win ? _C.yellow : const Color(0xFFFF2D55), width: 2.5),
              boxShadow: [BoxShadow(
                  color: win ? _C.yellow.withOpacity(0.25)
                      : const Color(0xFFFF2D55).withOpacity(0.25),
                  blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Column(children: [
              Text(win ? '🎉 ${tr(context).awesome}!'
                  : '💔 ${tr(context).gameOver}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: _C.font, fontSize: 30,
                      color: win ? _C.yellow : const Color(0xFFFF2D55))),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final lit = _score >= ((i+1)*(_targetScore/3)).round();
                    return Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(lit ? '⭐' : '☆',
                            style: TextStyle(fontSize: lit ? 38 : 30,
                                color: lit ? _C.yellow : Colors.white24)));
                  })),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _CPill('⭐', tr(context).score, '$_score/$_targetScore', _C.yellow),
                _CPill('❤️', tr(context).remainingLives,
                    '$_lives/$_maxLives',
                    _lives > 0 ? _C.teal : const Color(0xFFFF2D55)),
              ]),
              const SizedBox(height: 20),
              _CarnBtn(label: '🎡 ${tr(context).playAgain}',
                  color: _C.pink, shadowColor: _C.pink,
                  onTap: _onReplayPressed),
              const SizedBox(height: 10),
              _CarnBtn(label: '🏠 ${tr(context).back}',
                  color: Colors.white.withOpacity(0.10),
                  borderColor: _C.pink.withOpacity(0.40),
                  onTap: () => Navigator.pop(context)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _CPill extends StatelessWidget {
  final String emoji, label, value; final Color color;
  const _CPill(this.emoji, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.50), width: 1.5)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontFamily: _C.font, fontSize: 10, color: color)),
        Text(value, style: TextStyle(fontFamily: _C.font, fontSize: 15,
            fontWeight: FontWeight.w700, color: color)),
      ]));
}

class _CarnBtn extends StatelessWidget {
  final String label; final VoidCallback onTap; final Color color;
  final Color? borderColor, shadowColor;
  const _CarnBtn({required this.label, required this.onTap,
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
          child: Text(label, style: const TextStyle(fontFamily: _C.font,
              fontSize: 18, color: _C.white,
              shadows: [Shadow(color: Colors.black26, blurRadius: 4)]))));
}

class _CarnBannerBar extends StatefulWidget {
  final BannerAd? bannerAd; final bool isLoaded;
  const _CarnBannerBar({required this.bannerAd, required this.isLoaded});
  @override State<_CarnBannerBar> createState() => _CarnBannerBarState();
}
class _CarnBannerBarState extends State<_CarnBannerBar>
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
                  colors: [Color(0xFFFF6B9D), Color(0xFF7B2FFF)])),
          child: widget.isLoaded && widget.bannerAd != null
              ? Center(child: SizedBox(height: adH,
              width: widget.bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: widget.bannerAd!)))
              : AnimatedBuilder(animation: _a, builder: (_, __) {
            final t = _a.value;
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(children: [
                  Opacity(opacity: 0.5+t*0.5, child: const Text('🎡', style: TextStyle(fontSize: 18))),
                  const SizedBox(width: 10),
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12),
                      child: Container(height: 28,
                          color: Colors.white.withOpacity(0.18+t*0.18),
                          alignment: Alignment.center,
                          child: Text('✨  Advertisement  ✨',
                              style: TextStyle(fontFamily: _C.font, fontSize: 12,
                                  color: Colors.white.withOpacity(0.60+t*0.30)))))),
                  const SizedBox(width: 10),
                  Opacity(opacity: 0.5+t*0.5, child: const Text('🎡', style: TextStyle(fontSize: 18))),
                ]));
          }),
        ));
  }
}