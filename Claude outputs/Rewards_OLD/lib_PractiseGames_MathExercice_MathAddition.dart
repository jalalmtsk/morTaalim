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
//  🍎 FRUIT MARKET ADDITION
//  Theme: Two colourful baskets of fruit — count them together!
//  Vivid green-lime + sunny yellow + hot coral palette.
//  Streak mechanic preserved + visual streak fire indicator.
// ═══════════════════════════════════════════════════════════════
class _A {
  static const green      = Color(0xFF22C55E);
  static const greenDark  = Color(0xFF15803D);
  static const greenLight = Color(0xFFDCFCE7);
  static const yellow     = Color(0xFFFFD700);
  static const coral      = Color(0xFFFF6B6B);
  static const sky        = Color(0xFF38BDF8);
  static const white      = Color(0xFFFFFFFF);
  static const dark       = Color(0xFF14532D);

  // Answer button colours — 4-colour cycle
  static const List<Color> btnColors = [
    Color(0xFF22C55E), Color(0xFF3B82F6), Color(0xFFFF6B6B), Color(0xFFFFD700),
    Color(0xFF8B5CF6), Color(0xFF06B6D4), Color(0xFFF97316), Color(0xFF10B981),
    Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFF22C55E), Color(0xFF3B82F6),
    Color(0xFFFF6B6B), Color(0xFFFFD700), Color(0xFF8B5CF6), Color(0xFF06B6D4),
    Color(0xFFF97316), Color(0xFF10B981), Color(0xFF6366F1), Color(0xFFEC4899),
  ];

  // Fruit emojis per basket number (0-indexed, 1–10)
  static const List<String> fruits = [
    '🍎','🍊','🍋','🍇','🍓','🥝','🍑','🍒','🥭','🍍',
  ];

  static const String font = 'Fredoka One';
}

// ═══════════════════════════════════════════════════════════════
//  WRAPPER
// ═══════════════════════════════════════════════════════════════
class MathAdditionGame extends StatelessWidget {
  const MathAdditionGame({super.key});
  @override Widget build(BuildContext context) => const MathAdditionExercise();
}

// ═══════════════════════════════════════════════════════════════
//  LOADING OVERLAY
// ═══════════════════════════════════════════════════════════════
class _FruitLoader extends StatefulWidget {
  final String message;
  const _FruitLoader({required this.message});
  @override State<_FruitLoader> createState() => _FruitLoaderState();
}
class _FruitLoaderState extends State<_FruitLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  int _fi = 0;
  @override void initState() {
    super.initState();
    _spin = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800))..repeat();
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 320));
      if (!mounted) return false;
      setState(() => _fi = (_fi + 1) % _A.fruits.length);
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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [BoxShadow(
                  color: _A.green.withOpacity(0.60), blurRadius: 40)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedBuilder(animation: _spin,
                  builder: (_, __) => Transform.rotate(
                    angle: _spin.value * 2 * pi,
                    child: Text(_A.fruits[_fi],
                        style: const TextStyle(fontSize: 52)),
                  )),
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
                  style: const TextStyle(fontFamily: _A.font,
                      fontSize: 16, color: _A.white)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  GRASS WAVE PAINTER  (decorative bottom)
// ═══════════════════════════════════════════════════════════════
class _GrassPainter extends CustomPainter {
  final double phase;
  _GrassPainter(this.phase);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF16A34A).withOpacity(0.18)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 1) {
      path.lineTo(x, size.height * 0.6 +
          sin((x / size.width * 3 * pi) + phase) * size.height * 0.12);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = const Color(0xFF22C55E).withOpacity(0.13)
      ..style = PaintingStyle.fill;
    final path2 = Path();
    path2.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 1) {
      path2.lineTo(x, size.height * 0.72 +
          sin((x / size.width * 4 * pi) + phase + 1.2) * size.height * 0.08);
    }
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }
  @override bool shouldRepaint(_GrassPainter old) => old.phase != phase;
}

// ═══════════════════════════════════════════════════════════════
//  FRUIT BASKET WIDGET
// ═══════════════════════════════════════════════════════════════
class _FruitBasket extends StatefulWidget {
  final int count;
  final Color color;
  final String emoji;
  final bool isRight;
  const _FruitBasket({required this.count, required this.color,
    required this.emoji, required this.isRight});
  @override State<_FruitBasket> createState() => _FruitBasketState();
}
class _FruitBasketState extends State<_FruitBasket>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  late final Animation<double>   _scaleAnim;
  @override void initState() {
    super.initState();
    _bounce = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500))..forward();
    _scaleAnim = CurvedAnimation(parent: _bounce, curve: Curves.elasticOut);
  }
  @override void dispose() { _bounce.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: widget.color.withOpacity(0.55), width: 2.5),
          boxShadow: [BoxShadow(
              color: widget.color.withOpacity(0.30), blurRadius: 16,
              offset: const Offset(0, 6))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Basket emoji + count badge
          Stack(alignment: Alignment.topRight, children: [
            const Text('🧺', style: TextStyle(fontSize: 44)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(
                    color: widget.color.withOpacity(0.50), blurRadius: 6)],
              ),
              child: Text('${widget.count}',
                  style: const TextStyle(fontFamily: _A.font,
                      fontSize: 15, color: _A.white)),
            ),
          ]),
          const SizedBox(height: 6),
          // Fruit row — up to 5 per row, max 10 shown
          Wrap(
            spacing: 2, runSpacing: 2, alignment: WrapAlignment.center,
            children: List.generate(widget.count.clamp(0, 10), (_) =>
                Text(widget.emoji,
                    style: const TextStyle(fontSize: 18))),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  STREAK FIRE WIDGET
// ═══════════════════════════════════════════════════════════════
class _StreakFire extends StatefulWidget {
  final int streak;
  const _StreakFire({required this.streak});
  @override State<_StreakFire> createState() => _StreakFireState();
}
class _StreakFireState extends State<_StreakFire>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flicker;
  late final Animation<double>   _scale;
  @override void initState() {
    super.initState();
    _flicker = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400))..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _flicker, curve: Curves.easeInOut));
  }
  @override void dispose() { _flicker.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFFD700)]),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.55),
              blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('🔥', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text('× ${widget.streak}',
              style: const TextStyle(fontFamily: _A.font,
                  fontSize: 18, color: _A.white,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MAIN EXERCISE
// ═══════════════════════════════════════════════════════════════
class MathAdditionExercise extends StatefulWidget {
  const MathAdditionExercise({super.key});
  @override State<MathAdditionExercise> createState() =>
      _MathAdditionExerciseState();
}

class _MathAdditionExerciseState extends State<MathAdditionExercise>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  static const int _targetScore = 10;
  static const int _maxLives    = 3;
  static const int _maxAnswers  = 20;

  final Random _rng = Random();

  int _firstNumber  = 0;
  int _secondNumber = 0;
  int _correctAnswer = 0;
  String _fruit1 = '🍎';
  String _fruit2 = '🍊';

  int  _score   = 0;
  int  _lives   = _maxLives;
  int  _streak  = 0;
  bool _showGameOver   = false;
  bool? _isAnswerCorrect;
  bool _showFinalCeleb = false;
  bool _isProcessing   = false;
  bool _showLoader     = false;
  String _loaderMsg    = '';

  // animations
  late AnimationController _bgCtrl;   // background wave
  late Animation<double>   _bgAnim;
  late AnimationController _entryCtrl;
  late Animation<double>   _entryFade;
  late Animation<Offset>   _entrySlide;
  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;
  late AnimationController _padCtrl;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _bgCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 5))..repeat();
    _bgAnim = Tween<double>(begin: 0, end: 2 * pi).animate(_bgCtrl);

    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600))..forward();
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _shakeCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 380));
    _shakeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _padCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800))..forward();

    _generateNewQuestion();
    _loadBannerAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgCtrl.dispose(); _entryCtrl.dispose();
    _shakeCtrl.dispose(); _padCtrl.dispose();
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
    final maxN = 10 + (_score ~/ 3);
    _firstNumber  = _rng.nextInt(maxN) + 1;
    _secondNumber = _rng.nextInt(maxN) + 1;
    _correctAnswer = _firstNumber + _secondNumber;

    // Pick two different fruit emojis for the baskets
    final idx1 = _rng.nextInt(_A.fruits.length);
    int idx2 = _rng.nextInt(_A.fruits.length);
    while (idx2 == idx1) idx2 = _rng.nextInt(_A.fruits.length);
    _fruit1 = _A.fruits[idx1];
    _fruit2 = _A.fruits[idx2];

    _isAnswerCorrect = null;
    _padCtrl.reset(); _padCtrl.forward();
    setState(() {});
  }

  Future<void> _checkAnswer(int selected) async {
    if (_isProcessing || _showGameOver) return;
    _isProcessing = true;

    final xp    = Provider.of<ExperienceManager>(context, listen: false);
    final audio = Provider.of<AudioManager>(context, listen: false);
    HapticFeedback.selectionClick();

    if (selected == _correctAnswer) {
      _streak++;
      int xpGain = 1;
      if (_streak >= 3) xpGain += 1;
      if (_streak >= 5) xpGain += 2;
      xp.addXP(xpGain, context: context);
      audio.playSfx('assets/audios/QuizGame_Sounds/correct.mp3');
      HapticFeedback.lightImpact();
      setState(() { _score++; _isAnswerCorrect = true; });

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
          _isAnswerCorrect = null; _isProcessing = false;
        });
      } else {
        setState(() { _isAnswerCorrect = null; _isProcessing = false; });
        _generateNewQuestion();
      }
    } else {
      _streak = 0;
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
      _score = 0; _lives = _maxLives; _streak = 0;
      _showGameOver = _showFinalCeleb = _isProcessing = _showLoader = false;
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
      message: '🍎 Loading next round...',
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
                colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(
                color: _A.green.withOpacity(0.55), blurRadius: 30)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🧺', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 10),
            Text(tr(context).areYouSureQuitGame,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: _A.font,
                    fontSize: 20, color: _A.white)),
            const SizedBox(height: 6),
            Text(tr(context).youWillLoseYourProgress,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13,
                    color: Colors.white.withOpacity(0.75))),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: _MktBtn(label: tr(context).cancel,
                  color: Colors.white.withOpacity(0.22),
                  borderColor: Colors.white.withOpacity(0.55),
                  onTap: () { audio.playEventSound('cancelButton');
                  Navigator.pop(ctx, false); })),
              const SizedBox(width: 12),
              Expanded(child: _MktBtn(label: tr(context).ok,
                  color: const Color(0xFFFF6B6B),
                  onTap: () { audio.playEventSound('clickButton');
                  Navigator.pop(ctx, true); })),
            ]),
          ]),
        ),
      ),
    );
    if (shouldQuit ?? false) {
      await _withLoader(
        message: '👋 See you at the market!',
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
        backgroundColor: const Color(0xFFDCFCE7),
        bottomNavigationBar: context.watch<ExperienceManager>().adsEnabled
            ? FamilyAdBanner(bannerAd: _bannerAd, isLoaded: _isBannerAdLoaded)
            : null,
        body: Stack(children: [
          // ── ANIMATED BACKGROUND ──────────────────────────
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (_, __) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF86EFAC), Color(0xFFDCFCE7),
                    Color(0xFFFEF9C3), Color(0xFFBBF7D0)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Animated grass waves at bottom
          Positioned(bottom: 0, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _bgAnim,
              builder: (_, __) => CustomPaint(
                painter: _GrassPainter(_bgAnim.value),
                size: Size(MediaQuery.of(context).size.width, 120),
              ),
            ),
          ),
          // Floating fruit deco
          ..._fruitDeco(),

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
                  const SizedBox(height: 8),
                  // Streak indicator
                  if (_streak >= 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _StreakFire(streak: _streak),
                    ),
                  const SizedBox(height: 8),
                  // Baskets
                  _buildBaskets(),
                  const SizedBox(height: 10),
                  // Plus sign + question
                  _buildEquation(),
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
          if (_showLoader) _FruitLoader(message: _loaderMsg),
        ]),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  List<Widget> _fruitDeco() {
    const items = ['🌿','🌸','🍀','🌻','🌱'];
    return [
      Positioned(top: 60,  left: 10,  child: Opacity(opacity: 0.25,
          child: Text(items[0], style: const TextStyle(fontSize: 36)))),
      Positioned(top: 140, right: 12, child: Opacity(opacity: 0.20,
          child: Text(items[3], style: const TextStyle(fontSize: 30)))),
      Positioned(top: 50,  right: 50, child: Opacity(opacity: 0.18,
          child: Text(items[2], style: const TextStyle(fontSize: 24)))),
    ];
  }

  Widget _buildHUD(AudioManager audio) {
    final pct = (_score / _targetScore).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _A.green.withOpacity(0.40), width: 1.5),
        boxShadow: [BoxShadow(color: _A.green.withOpacity(0.18),
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
                    color: _A.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: _A.green.withOpacity(0.40), width: 1.5)),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 17, color: _A.green)),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: _A.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _A.green.withOpacity(0.40), width: 1.2)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(width: 2),
            ]),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: _A.yellow.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _A.yellow.withOpacity(0.60), width: 1.2)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('⭐', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text('$_score/$_targetScore',
                  style: const TextStyle(fontFamily: _A.font,
                      fontSize: 14, color: _A.dark)),
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
                color: _A.green.withOpacity(0.15)),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(height: 10,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFFFFD700),
                          Color(0xFFFF6B6B)]),
                  )),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildBaskets() {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) {
        final dx = sin(_shakeAnim.value * pi * 7) * 9 * (1 - _shakeAnim.value);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _FruitBasket(
                count: _firstNumber, color: _A.green,
                emoji: _fruit1, isRight: false)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _A.coral.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: _A.coral.withOpacity(0.55), width: 2),
                  boxShadow: [BoxShadow(
                      color: _A.coral.withOpacity(0.30), blurRadius: 10)],
                ),
                alignment: Alignment.center,
                child: const Text('+',
                    style: TextStyle(fontFamily: _A.font,
                        fontSize: 28, color: _A.coral)),
              ),
            ),
            Expanded(child: _FruitBasket(
                count: _secondNumber, color: _A.sky,
                emoji: _fruit2, isRight: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildEquation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isAnswerCorrect == true
              ? const Color(0xFF22C55E)
              : _isAnswerCorrect == false
              ? _A.coral
              : _A.green.withOpacity(0.40),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(color: _A.green.withOpacity(0.15),
              blurRadius: 12, offset: const Offset(0, 4)),
          if (_isAnswerCorrect == true)
            BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.40),
                blurRadius: 20),
          if (_isAnswerCorrect == false)
            BoxShadow(color: _A.coral.withOpacity(0.40), blurRadius: 20),
        ],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🛒', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Text('$_firstNumber + $_secondNumber = ?',
            style: const TextStyle(fontFamily: _A.font,
                fontSize: 28, color: _A.dark,
                shadows: [Shadow(color: Colors.black12, blurRadius: 4)])),
        const SizedBox(width: 10),
        const Text('🛒', style: TextStyle(fontSize: 24)),
      ]),
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
          child: _NumBtn(
            number: i + 1,
            color:  _A.btnColors[i % _A.btnColors.length],
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
              color: Colors.white.withOpacity(0.70),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                  color: win ? _A.green : _A.coral, width: 2.5),
              boxShadow: [BoxShadow(
                  color: win ? _A.green.withOpacity(0.25) : _A.coral.withOpacity(0.25),
                  blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Column(children: [
              Text(win ? '🎉 ${tr(context).awesome}!'
                  : '💔 ${tr(context).gameOver}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: _A.font, fontSize: 30,
                      color: win ? _A.greenDark : _A.coral)),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final lit = _score >= ((i+1) * (_targetScore/3)).round();
                    return Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(lit ? '⭐' : '☆',
                            style: TextStyle(fontSize: lit ? 38 : 30,
                                color: lit ? _A.yellow : Colors.grey.shade300)));
                  })),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _RPill('⭐', tr(context).score,
                    '$_score/$_targetScore', _A.yellow),
                _RPill('❤️', tr(context).remainingLives,
                    '$_lives/$_maxLives',
                    _lives > 0 ? _A.green : _A.coral),
                _RPill('🔥', 'Best streak', '$_streak', _A.coral),
              ]),
              const SizedBox(height: 20),
              _MktBtn(label: '🍎 ${tr(context).playAgain}',
                  color: _A.green, shadowColor: _A.green,
                  onTap: _onReplayPressed),
              const SizedBox(height: 10),
              _MktBtn(label: '🏠 ${tr(context).back}',
                  color: Colors.white.withOpacity(0.40),
                  borderColor: _A.green.withOpacity(0.55),
                  onTap: () => Navigator.pop(context)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Shared small widgets ────────────────────────────────────────
class _NumBtn extends StatefulWidget {
  final int number; final Color color; final VoidCallback onTap;
  const _NumBtn({required this.number, required this.color, required this.onTap});
  @override State<_NumBtn> createState() => _NumBtnState();
}
class _NumBtnState extends State<_NumBtn> with SingleTickerProviderStateMixin {
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
      onTapUp:   (_) => _p.reverse(),
      onTapCancel: () => _p.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(animation: _s,
        builder: (_, child) => Transform.scale(scale: _s.value, child: child),
        child: Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                  center: const Alignment(-0.30, -0.30), radius: 0.80,
                  colors: [
                    Color.lerp(widget.color, Colors.white, 0.38)!,
                    widget.color,
                    Color.lerp(widget.color, Colors.black, 0.22)!,
                  ], stops: const [0.0, 0.55, 1.0]),
              boxShadow: [
                BoxShadow(color: widget.color.withOpacity(0.65),
                    blurRadius: 10, offset: const Offset(0, 4)),
                BoxShadow(color: widget.color.withOpacity(0.28),
                    blurRadius: 18, spreadRadius: 2),
              ]),
          child: Stack(alignment: Alignment.center, children: [
            Text('${widget.number}', style: const TextStyle(
                fontFamily: _A.font, fontSize: 18, color: _A.white,
                shadows: [Shadow(color: Colors.black38, blurRadius: 5,
                    offset: Offset(0, 2))])),
            Positioned(top: 5, left: 7,
                child: Container(width: 7, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(3)))),
          ]),
        ),
      ),
    );
  }
}

class _RPill extends StatelessWidget {
  final String emoji, label, value; final Color color;
  const _RPill(this.emoji, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.50), width: 1.5)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontFamily: _A.font,
            fontSize: 10, color: color)),
        Text(value, style: TextStyle(fontFamily: _A.font,
            fontSize: 15, fontWeight: FontWeight.w700, color: color)),
      ]));
}

class _MktBtn extends StatelessWidget {
  final String label; final VoidCallback onTap;
  final Color color;
  final Color? borderColor, shadowColor;
  const _MktBtn({required this.label, required this.onTap,
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
        child: Text(label, style: const TextStyle(fontFamily: _A.font,
            fontSize: 18, color: _A.white,
            shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
      ));
}

