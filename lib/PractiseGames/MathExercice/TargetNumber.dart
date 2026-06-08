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
//  🧪 MAD SCIENTIST LAB — Target Number
//  Pick numbered potions that add up to the target!
//  If you go over → explosion! Visual progress flask.
//  Vivid purple + acid-green + electric teal palette.
// ═══════════════════════════════════════════════════════════════
class _L {
  static const lab      = Color(0xFF0F0A1E);
  static const labMid   = Color(0xFF1A1035);
  static const purple   = Color(0xFF9B5DE5);
  static const acid     = Color(0xFF39FF14);
  static const teal     = Color(0xFF00F5FF);
  static const yellow   = Color(0xFFFFE566);
  static const red      = Color(0xFFFF2D55);
  static const white    = Color(0xFFFFFFFF);

  // Potion colors — each option bottle is different
  static const List<Color> potions = [
    Color(0xFF9B5DE5), Color(0xFF00F5FF), Color(0xFF39FF14),
    Color(0xFFFF6B9D), Color(0xFFFFE566), Color(0xFFFF6B35),
  ];

  static const String font = 'Fredoka One';
}

// ═══════════════════════════════════════════════════════════════
//  WRAPPER
// ═══════════════════════════════════════════════════════════════
class TargetNumberGame extends StatelessWidget {
  const TargetNumberGame({super.key});
  @override Widget build(BuildContext context) => const TargetNumberExercise();
}

// ═══════════════════════════════════════════════════════════════
//  LOADING OVERLAY
// ═══════════════════════════════════════════════════════════════
class _LabLoader extends StatefulWidget {
  final String message;
  const _LabLoader({required this.message});
  @override State<_LabLoader> createState() => _LabLoaderState();
}
class _LabLoaderState extends State<_LabLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bubble;
  @override void initState() {
    super.initState();
    _bubble = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800))..repeat();
  }
  @override void dispose() { _bubble.dispose(); super.dispose(); }
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
                  colors: [Color(0xFF1A1035), Color(0xFF0F0A1E)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: _L.acid.withOpacity(0.55), width: 2),
              boxShadow: [BoxShadow(
                  color: _L.acid.withOpacity(0.35), blurRadius: 40)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Bubbling flasks
              AnimatedBuilder(animation: _bubble,
                  builder: (_, __) {
                    final t = _bubble.value;
                    return Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (i) {
                          final dy = sin((t * 2 * pi) - i * pi / 3) * 8;
                          return Transform.translate(offset: Offset(0, dy),
                              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
                                  child: Text(['⚗️','🧪','🔬'][i],
                                      style: const TextStyle(fontSize: 34))));
                        }));
                  }),
              const SizedBox(height: 16),
              AnimatedBuilder(animation: _bubble,
                  builder: (_, __) => Row(mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final dy = sin((_bubble.value*2*pi) - i*pi/3) * 6;
                        return Transform.translate(offset: Offset(0, dy),
                            child: Container(width: 10, height: 10,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                    color: _L.potions[i].withOpacity(0.90),
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(
                                        color: _L.potions[i].withOpacity(0.80),
                                        blurRadius: 6)])));
                      }))),
              const SizedBox(height: 12),
              Text(widget.message, textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: _L.font,
                      fontSize: 15, color: _L.white)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FLASK PROGRESS WIDGET
//  Fills up as currentSum approaches targetNumber.
//  Green → yellow → red as it nears overflow.
// ═══════════════════════════════════════════════════════════════
class _FlaskProgress extends StatefulWidget {
  final int currentSum;
  final int target;
  const _FlaskProgress({required this.currentSum, required this.target});
  @override State<_FlaskProgress> createState() => _FlaskProgressState();
}
class _FlaskProgressState extends State<_FlaskProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bubble;
  @override void initState() {
    super.initState();
    _bubble = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }
  @override void dispose() { _bubble.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.currentSum / widget.target).clamp(0.0, 1.0);
    final fluidColor = pct < 0.5
        ? Color.lerp(_L.acid, _L.yellow, pct * 2)!
        : Color.lerp(_L.yellow, _L.red, (pct - 0.5) * 2)!;

    return AnimatedBuilder(
      animation: _bubble,
      builder: (_, __) {
        final bubbleOff = _bubble.value * 4;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 70, height: 130,
            child: CustomPaint(
              painter: _FlaskPainter(
                fillPct: pct,
                fluidColor: fluidColor,
                bubbleOffset: bubbleOff,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('${widget.currentSum} / ${widget.target}',
              style: TextStyle(fontFamily: _L.font, fontSize: 16,
                  color: fluidColor,
                  shadows: [BoxShadow(color: fluidColor.withOpacity(0.80),
                      blurRadius: 8) as Shadow])),
        ]);
      },
    );
  }
}

class _FlaskPainter extends CustomPainter {
  final double fillPct;
  final Color fluidColor;
  final double bubbleOffset;
  _FlaskPainter({required this.fillPct, required this.fluidColor,
    required this.bubbleOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;

    // Flask outline
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.30)
      ..style = PaintingStyle.stroke ..strokeWidth = 2.5;
    final flaskPath = _flaskPath(w, h);
    canvas.drawPath(flaskPath, outlinePaint);

    // Fluid fill
    if (fillPct > 0) {
      final fluidPaint = Paint()
        ..color = fluidColor.withOpacity(0.75) ..style = PaintingStyle.fill;
      final fluidTop = h * (1 - fillPct * 0.75);
      final clipPath = Path()
        ..moveTo(0, fluidTop)..lineTo(w, fluidTop)
        ..lineTo(w, h)..lineTo(0, h)..close();
      canvas.save();
      canvas.clipPath(clipPath);
      canvas.drawPath(_flaskPath(w, h), fluidPaint);
      // Bubble
      canvas.drawCircle(
          Offset(w * 0.4, fluidTop + 10 - bubbleOffset),
          4, Paint()..color = Colors.white.withOpacity(0.40));
      canvas.restore();
    }

    // Glow
    final glowPaint = Paint()
      ..color = fluidColor.withOpacity(0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
    canvas.drawPath(_flaskPath(w, h), glowPaint);
  }

  Path _flaskPath(double w, double h) {
    final path = Path();
    path.moveTo(w * 0.35, 0);
    path.lineTo(w * 0.65, 0);
    path.lineTo(w * 0.65, h * 0.30);
    path.quadraticBezierTo(w * 1.05, h * 0.45, w * 1.0, h * 0.80);
    path.arcToPoint(Offset(0, h * 0.80),
        radius: Radius.circular(w * 0.55), clockwise: false);
    path.quadraticBezierTo(-w * 0.05, h * 0.45, w * 0.35, h * 0.30);
    path.close();
    return path;
  }

  @override bool shouldRepaint(_FlaskPainter old) =>
      old.fillPct != fillPct || old.fluidColor != fluidColor ||
          old.bubbleOffset != bubbleOffset;
}

// ═══════════════════════════════════════════════════════════════
//  POTION BUTTON
// ═══════════════════════════════════════════════════════════════
class _PotionBtn extends StatefulWidget {
  final int number; final Color color; final VoidCallback onTap;
  final bool isUsed;
  const _PotionBtn({required this.number, required this.color,
    required this.onTap, required this.isUsed});
  @override State<_PotionBtn> createState() => _PotionBtnState();
}
class _PotionBtnState extends State<_PotionBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double>   _scale;
  @override void initState() {
    super.initState();
    _press = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 85));
    _scale = Tween<double>(begin: 1.0, end: 0.82)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }
  @override void dispose() { _press.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { if (!widget.isUsed) _press.forward(); },
      onTapUp:   (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      onTap: widget.isUsed ? null : widget.onTap,
      child: AnimatedBuilder(animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedOpacity(
          opacity: widget.isUsed ? 0.35 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              gradient: widget.isUsed ? null : LinearGradient(
                  colors: [
                    Color.lerp(widget.color, Colors.white, 0.25)!,
                    widget.color,
                    Color.lerp(widget.color, Colors.black, 0.30)!,
                  ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              color: widget.isUsed ? Colors.white.withOpacity(0.08) : null,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: widget.isUsed
                      ? Colors.white.withOpacity(0.15)
                      : widget.color.withOpacity(0.75),
                  width: widget.isUsed ? 1 : 2),
              boxShadow: widget.isUsed ? null : [
                BoxShadow(color: widget.color.withOpacity(0.60),
                    blurRadius: 12, offset: const Offset(0, 4)),
                BoxShadow(color: widget.color.withOpacity(0.25),
                    blurRadius: 20, spreadRadius: 2),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(widget.isUsed ? '✓' : '⚗️',
                  style: TextStyle(fontSize: 22,
                      color: widget.isUsed
                          ? Colors.white.withOpacity(0.40) : null)),
              const SizedBox(height: 4),
              Text('${widget.number}',
                  style: TextStyle(
                      fontFamily: _L.font, fontSize: 22,
                      color: widget.isUsed
                          ? Colors.white.withOpacity(0.30) : _L.white,
                      shadows: widget.isUsed ? null : [
                        Shadow(color: widget.color, blurRadius: 8,
                            offset: const Offset(0, 2)),
                        const Shadow(color: Colors.black38, blurRadius: 4),
                      ])),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CHOSEN FORMULA DISPLAY
// ═══════════════════════════════════════════════════════════════
class _FormulaDisplay extends StatelessWidget {
  final List<int> chosen;
  final int currentSum;
  final int target;
  const _FormulaDisplay({required this.chosen, required this.currentSum,
    required this.target});
  @override
  Widget build(BuildContext context) {
    final overflow = currentSum > target;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: overflow ? _L.red.withOpacity(0.70)
              : currentSum == target
              ? _L.acid.withOpacity(0.70)
              : Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: overflow ? [BoxShadow(
            color: _L.red.withOpacity(0.35), blurRadius: 16)] : null,
      ),
      child: chosen.isEmpty
          ? Text(tr(context).noNumberChosen,
          style: TextStyle(fontFamily: _L.font, fontSize: 14,
              color: Colors.white.withOpacity(0.45)))
          : Wrap(spacing: 4, runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            ...chosen.asMap().entries.map((e) => Row(mainAxisSize: MainAxisSize.min,
                children: [
                  if (e.key > 0)
                    Text(' + ', style: TextStyle(fontFamily: _L.font,
                        fontSize: 18, color: Colors.white.withOpacity(0.60))),
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: _L.potions[e.key % _L.potions.length].withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _L.potions[e.key % _L.potions.length]
                                  .withOpacity(0.55), width: 1)),
                      child: Text('${e.value}',
                          style: TextStyle(fontFamily: _L.font, fontSize: 18,
                              color: _L.potions[e.key % _L.potions.length]))),
                ])),
            Text(' = ${overflow ? "💥 TOO MUCH!" : currentSum == target ? "✓ $currentSum" : currentSum}',
                style: TextStyle(fontFamily: _L.font, fontSize: 18,
                    color: overflow ? _L.red
                        : currentSum == target ? _L.acid
                        : Colors.white.withOpacity(0.70))),
          ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MAIN EXERCISE
// ═══════════════════════════════════════════════════════════════
class TargetNumberExercise extends StatefulWidget {
  const TargetNumberExercise({super.key});
  @override State<TargetNumberExercise> createState() =>
      _TargetNumberExerciseState();
}

class _TargetNumberExerciseState extends State<TargetNumberExercise>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  static const int _targetScore = 10;
  static const int _maxLives    = 3;
  static const int _maxOptions  = 6;

  final Random _rng = Random();

  int       _targetNumber = 0;
  int       _currentSum   = 0;
  List<int> _chosen       = [];
  List<int> _options      = [];
  List<bool> _usedOptions = [];

  int  _score  = 0;
  int  _lives  = _maxLives;
  bool _showGameOver   = false;
  bool _showFinalCeleb = false;
  bool _isProcessing   = false;
  bool _showLoader     = false;
  bool? _isAnswerCorrect;
  String _loaderMsg    = '';

  late AnimationController _bgCtrl;
  late AnimationController _entryCtrl;
  late Animation<double>   _entryFade;
  late AnimationController _targetPulse; // target number glows when reached
  late Animation<double>   _targetAnim;
  late AnimationController _explodeCtrl;
  late Animation<double>   _explodeAnim;
  bool _showExplosion = false;

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
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _targetPulse = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400))..repeat(reverse: true);
    _targetAnim = Tween<double>(begin: 1.0, end: 1.12)
        .animate(CurvedAnimation(parent: _targetPulse, curve: Curves.easeInOut));

    _explodeCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _explodeAnim = CurvedAnimation(parent: _explodeCtrl, curve: Curves.easeOut);

    _generateNewTarget();
    _loadBannerAd();
  }

  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgCtrl.dispose(); _entryCtrl.dispose();
    _targetPulse.dispose(); _explodeCtrl.dispose();
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

  List<int> _generateOptions() {
    final opts = <int>[];
    while (opts.length < _maxOptions) {
      final n = _rng.nextInt(15) + 1;
      if (!opts.contains(n)) opts.add(n);
    }
    return opts;
  }

  void _generateNewTarget() {
    _options = _generateOptions();
    final subset = (List.of(_options)..shuffle(_rng))
        .take(2 + _rng.nextInt(2)).toList();
    _targetNumber = subset.reduce((a, b) => a + b);
    _currentSum   = 0;
    _chosen       = [];
    _usedOptions  = List.filled(_maxOptions, false);
    _isAnswerCorrect = null;
    _showExplosion = false;
    setState(() {});
  }

  Future<void> _checkAnswer(int selected, int optIndex) async {
    if (_isProcessing || _showGameOver) return;
    if (_usedOptions[optIndex]) return;
    _isProcessing = true;

    final xp    = Provider.of<ExperienceManager>(context, listen: false);
    final audio = Provider.of<AudioManager>(context, listen: false);
    HapticFeedback.selectionClick();

    final newSum = _currentSum + selected;

    if (newSum == _targetNumber) {
      // ── CORRECT ──────────────────────────────────────────
      xp.addXP(1, context: context);
      audio.playSfx('assets/audios/QuizGame_Sounds/correct.mp3');
      HapticFeedback.lightImpact();
      setState(() {
        _score++;
        _currentSum = newSum;
        _chosen.add(selected);
        _usedOptions[optIndex] = true;
        _isAnswerCorrect = true;
      });

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
        _generateNewTarget();
      }

    } else if (newSum > _targetNumber) {
      // ── OVERFLOW → EXPLOSION ──────────────────────────────
      audio.playSfx('assets/audios/QuizGame_Sounds/incorrect.mp3');
      HapticFeedback.heavyImpact();
      setState(() {
        _lives = (_lives > 0) ? _lives - 1 : 0;
        _isAnswerCorrect = false;
        _currentSum = newSum;
        _chosen.add(selected);
        _showExplosion = true;
      });
      _explodeCtrl.reset(); _explodeCtrl.forward();

      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;

      if (_lives == 0) {
        audio.playSfx("assets/audios/UI_Audio/SFX_Audio/FailMeme_SFX.mp3");
        setState(() {
          _showGameOver = true; _isAnswerCorrect = null; _isProcessing = false;
        });
      } else {
        setState(() {
          _isAnswerCorrect = null; _showExplosion = false; _isProcessing = false;
        });
        // Reset sum (don't change question)
        setState(() { _currentSum = 0; _chosen = []; _usedOptions = List.filled(_maxOptions, false); });
      }

    } else {
      // ── PARTIAL (still under target) ──────────────────────
      setState(() {
        _currentSum = newSum;
        _chosen.add(selected);
        _usedOptions[optIndex] = true;
        _isProcessing = false;
      });
    }
  }

  void _resetGame() {
    setState(() {
      _score = 0; _lives = _maxLives;
      _showGameOver = _showFinalCeleb = _isProcessing =
          _showLoader = _showExplosion = false;
    });
    _generateNewTarget();
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
    _withLoader(message: '🧪 Mixing next experiment...',
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
                colors: [Color(0xFF1A1035), Color(0xFF0F0A1E)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: _L.acid.withOpacity(0.50), width: 2),
            boxShadow: [BoxShadow(
                color: _L.acid.withOpacity(0.25), blurRadius: 30)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('⚗️', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 10),
            Text(tr(context).areYouSureQuitGame, textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: _L.font,
                    fontSize: 20, color: _L.white)),
            const SizedBox(height: 6),
            Text(tr(context).youWillLoseYourProgress, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13,
                    color: Colors.white.withOpacity(0.65))),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: _LabBtn(label: tr(context).cancel,
                  color: Colors.white.withOpacity(0.12),
                  borderColor: Colors.white.withOpacity(0.35),
                  onTap: () { audio.playEventSound('cancelButton');
                  Navigator.pop(ctx, false); })),
              const SizedBox(width: 12),
              Expanded(child: _LabBtn(label: tr(context).ok,
                  color: _L.red, onTap: () { audio.playEventSound('clickButton');
                  Navigator.pop(ctx, true); })),
            ]),
          ]),
        ),
      ),
    );
    if (shouldQuit ?? false) {
      await _withLoader(message: '🧑‍🔬 Experiment cancelled!',
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
        backgroundColor: _L.lab,
        bottomNavigationBar: context.watch<ExperienceManager>().adsEnabled
            ? _LabBannerBar(bannerAd: _bannerAd, isLoaded: _isBannerAdLoaded)
            : null,
        body: Stack(children: [
          // Animated dark BG
          AnimatedBuilder(animation: _bgCtrl,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [
                        Color.lerp(const Color(0xFF0F0A1E), const Color(0xFF1A0A2E),
                            _bgCtrl.value)!,
                        Color.lerp(const Color(0xFF1A1035), const Color(0xFF0A1A1E),
                            _bgCtrl.value)!,
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
            ),
          ),

          // Floating lab deco
          ..._labDeco(),

          SafeArea(
            child: _showGameOver ? _buildGameOver() :
            FadeTransition(opacity: _entryFade,
              child: Column(children: [
                const Padding(padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Userstatutbar()),
                const SizedBox(height: 6),
                _buildHUD(audio),
                const SizedBox(height: 8),
                // Target + flask + formula row
                _buildLabBench(),
                const SizedBox(height: 8),
                // Potion options
                Expanded(child: _buildPotionGrid()),
                const SizedBox(height: 6),
              ]),
            ),
          ),

          // Explosion overlay
          if (_showExplosion)
            AnimatedBuilder(animation: _explodeAnim, builder: (_, __) {
              final t = _explodeAnim.value;
              return IgnorePointer(child: Container(
                color: _L.red.withOpacity((0.35 - t * 0.35).clamp(0, 1)),
                alignment: Alignment.center,
                child: Transform.scale(scale: 1.0 + t * 2.0,
                    child: Opacity(opacity: (1.0 - t).clamp(0, 1),
                        child: const Text('💥',
                            style: TextStyle(fontSize: 80)))),
              ));
            }),

          if (_isAnswerCorrect == true)
            IgnorePointer(child: Container(
              color: Colors.black.withOpacity(0.25),
              alignment: Alignment.center,
              child: SizedBox(width: 200, height: 200,
                  child: Lottie.asset(
                      'assets/animations/QuizzGame_Animation/DoneAnimation.json',
                      repeat: false)),
            )),

          if (_showLoader) _LabLoader(message: _loaderMsg),
        ]),
      ),
    );
  }

  List<Widget> _labDeco() => [
    Positioned(top: 50, left: 10, child: Opacity(opacity: 0.12,
        child: const Text('🔬', style: TextStyle(fontSize: 44)))),
    Positioned(top: 80, right: 12, child: Opacity(opacity: 0.10,
        child: const Text('⚗️', style: TextStyle(fontSize: 36)))),
    Positioned(bottom: 120, left: 8, child: Opacity(opacity: 0.08,
        child: const Text('🧬', style: TextStyle(fontSize: 32)))),
  ];

  Widget _buildHUD(AudioManager audio) {
    final pct = (_score / _targetScore).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _L.acid.withOpacity(0.22), width: 1.5),
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
                    color: _L.acid.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: _L.acid.withOpacity(0.35), width: 1.5)),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 17, color: _L.acid)),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: _L.acid.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _L.acid.withOpacity(0.30), width: 1.2)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('🧪', style: TextStyle(fontSize: 14)),
              SizedBox(width: 5),
              Text('Mad Lab', style: TextStyle(fontFamily: _L.font,
                  fontSize: 13, color: _L.white)),
            ]),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: _L.yellow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _L.yellow.withOpacity(0.50), width: 1.2)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('⭐', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text('$_score/$_targetScore',
                  style: const TextStyle(fontFamily: _L.font,
                      fontSize: 14, color: _L.yellow)),
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
                          colors: [Color(0xFF9B5DE5), Color(0xFF39FF14),
                            Color(0xFF00F5FF)]))),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildLabBench() {
    final reached = _currentSum == _targetNumber;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
            color: reached ? _L.acid.withOpacity(0.80)
                : _L.purple.withOpacity(0.35), width: 1.8),
        boxShadow: reached ? [BoxShadow(
            color: _L.acid.withOpacity(0.40), blurRadius: 22)] : null,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flask
          _FlaskProgress(currentSum: _currentSum, target: _targetNumber),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target label
              Row(children: [
                const Text('🎯', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(tr(context).reachTheNumber,
                    style: TextStyle(fontFamily: _L.font, fontSize: 13,
                        color: Colors.white.withOpacity(0.60))),
              ]),
              const SizedBox(height: 4),
              // Target number (pulses when reached)
              AnimatedBuilder(animation: _targetAnim,
                builder: (_, child) => Transform.scale(
                    scale: reached ? _targetAnim.value : 1.0,
                    child: child),
                child: Text('$_targetNumber',
                    style: TextStyle(
                      fontFamily: _L.font, fontSize: 52,
                      color: reached ? _L.acid : _L.purple,
                      shadows: [Shadow(
                          color: (reached ? _L.acid : _L.purple)
                              .withOpacity(0.80),
                          blurRadius: 16, offset: const Offset(0, 4))],
                    )),
              ),
              const SizedBox(height: 8),
              // Formula
              _FormulaDisplay(
                  chosen: _chosen, currentSum: _currentSum,
                  target: _targetNumber),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildPotionGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _maxOptions,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10, crossAxisSpacing: 10,
          childAspectRatio: 0.90,
        ),
        itemBuilder: (_, i) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + i * 50),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Opacity(
              opacity: v.clamp(0.0, 1.0),
              child: Transform.scale(scale: v.clamp(0.01, 1.0), child: child)),
          child: _PotionBtn(
            number:  _options[i],
            color:   _L.potions[i % _L.potions.length],
            isUsed:  _usedOptions[i],
            onTap:   () => _checkAnswer(_options[i], i),
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
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                  color: win ? _L.acid : _L.red, width: 2.5),
              boxShadow: [BoxShadow(
                  color: win ? _L.acid.withOpacity(0.25)
                      : _L.red.withOpacity(0.25),
                  blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Column(children: [
              Text(win ? '🎉 ${tr(context).awesome}!'
                  : '💔 ${tr(context).gameOver}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: _L.font, fontSize: 30,
                      color: win ? _L.acid : _L.red)),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final lit = _score >= ((i+1)*(_targetScore/3)).round();
                    return Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(lit ? '⭐' : '☆',
                            style: TextStyle(fontSize: lit ? 38 : 30,
                                color: lit ? _L.yellow : Colors.white24)));
                  })),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _LPill('⭐', tr(context).score, '$_score/$_targetScore', _L.yellow),
                _LPill('❤️', tr(context).remainingLives,
                    '$_lives/$_maxLives',
                    _lives > 0 ? _L.acid : _L.red),
              ]),
              const SizedBox(height: 20),
              _LabBtn(label: '🧪 ${tr(context).playAgain}',
                  color: _L.purple, shadowColor: _L.purple,
                  onTap: _onReplayPressed),
              const SizedBox(height: 10),
              _LabBtn(label: '🏠 ${tr(context).back}',
                  color: Colors.white.withOpacity(0.08),
                  borderColor: _L.acid.withOpacity(0.40),
                  onTap: () => Navigator.pop(context)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _LPill extends StatelessWidget {
  final String emoji, label, value; final Color color;
  const _LPill(this.emoji, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.50), width: 1.5)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontFamily: _L.font, fontSize: 10, color: color)),
        Text(value, style: TextStyle(fontFamily: _L.font, fontSize: 15,
            fontWeight: FontWeight.w700, color: color)),
      ]));
}

class _LabBtn extends StatelessWidget {
  final String label; final VoidCallback onTap; final Color color;
  final Color? borderColor, shadowColor;
  const _LabBtn({required this.label, required this.onTap,
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
          child: Text(label, style: const TextStyle(fontFamily: _L.font,
              fontSize: 18, color: _L.white,
              shadows: [Shadow(color: Colors.black26, blurRadius: 4)]))));
}

class _LabBannerBar extends StatefulWidget {
  final BannerAd? bannerAd; final bool isLoaded;
  const _LabBannerBar({required this.bannerAd, required this.isLoaded});
  @override State<_LabBannerBar> createState() => _LabBannerBarState();
}
class _LabBannerBarState extends State<_LabBannerBar>
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
                  colors: [Color(0xFF9B5DE5), Color(0xFF1A1035)])),
          child: widget.isLoaded && widget.bannerAd != null
              ? Center(child: SizedBox(height: adH,
              width: widget.bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: widget.bannerAd!)))
              : AnimatedBuilder(animation: _a, builder: (_, __) {
            final t = _a.value;
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(children: [
                  Opacity(opacity: 0.5+t*0.5, child: const Text('🧪', style: TextStyle(fontSize: 18))),
                  const SizedBox(width: 10),
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12),
                      child: Container(height: 28,
                          color: _L.acid.withOpacity(0.10+t*0.12),
                          alignment: Alignment.center,
                          child: Text('✨  Advertisement  ✨',
                              style: TextStyle(fontFamily: _L.font, fontSize: 12,
                                  color: _L.acid.withOpacity(0.60+t*0.30)))))),
                  const SizedBox(width: 10),
                  Opacity(opacity: 0.5+t*0.5, child: const Text('🧪', style: TextStyle(fontSize: 18))),
                ]));
          }),
        ));
  }
}