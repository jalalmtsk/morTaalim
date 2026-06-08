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
//  🏖️  BEACH EXPLORER — Count Objects
//  Vivid sandy shore palette. Objects appear as items washed
//  up on the beach in animated wave-tile cards.
//  Answer pad = colourful seashell-shaped number buttons.
// ═══════════════════════════════════════════════════════════════
class _B {
  static const sand       = Color(0xFFFFF0CC);
  static const sandMid    = Color(0xFFFFD97D);
  static const ocean      = Color(0xFF0EA5E9);
  static const oceanLight = Color(0xFF7DD3FC);
  static const coral      = Color(0xFFFF6B6B);
  static const teal       = Color(0xFF14B8A6);
  static const white      = Color(0xFFFFFFFF);
  static const dark       = Color(0xFF1E3A5F);

  static const List<Color> shellColors = [
    Color(0xFFFF6B6B), Color(0xFF0EA5E9), Color(0xFFFFD97D),
    Color(0xFF14B8A6), Color(0xFF8B5CF6), Color(0xFFF97316),
    Color(0xFFEC4899), Color(0xFF22C55E), Color(0xFF6366F1),
    Color(0xFF06B6D4),
  ];

  static const List<String> objects = [
    "🐠","🐚","⭐","🦀","🐡","🦞","🐙","🦑","🐟","🌊",
    "🪸","🦭","🐬","🐳","🐋","🦈","🐊","🦦","🪨","🌴",
    "🍦","🏄","🩴","🏖️","⛱️","🌺","🦜","🐦","🐝","🦋",
  ];

  static const String font = 'Fredoka One';
}

// ═══════════════════════════════════════════════════════════════
//  WRAPPER
// ═══════════════════════════════════════════════════════════════
class CountObject extends StatelessWidget {
  const CountObject({super.key});
  @override Widget build(BuildContext context) => const CountExercise();
}

// ═══════════════════════════════════════════════════════════════
//  LOADING OVERLAY
// ═══════════════════════════════════════════════════════════════
class _WaveLoader extends StatefulWidget {
  final String message;
  const _WaveLoader({required this.message});
  @override State<_WaveLoader> createState() => _WaveLoaderState();
}
class _WaveLoaderState extends State<_WaveLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave;
  @override void initState() {
    super.initState();
    _wave = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..repeat();
  }
  @override void dispose() { _wave.dispose(); super.dispose(); }
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
            width: 230,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [BoxShadow(
                  color: _B.ocean.withOpacity(0.60), blurRadius: 40)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Wave animation
              AnimatedBuilder(animation: _wave,
                  builder: (_, __) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final dy = sin((_wave.value * 2 * pi) - i * 0.5) * 10;
                      return Transform.translate(
                        offset: Offset(0, dy),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Text('🌊',
                              style: TextStyle(fontSize: 26 + dy.abs() * 0.3)),
                        ),
                      );
                    }),
                  )),
              const SizedBox(height: 16),
              AnimatedBuilder(animation: _wave,
                  builder: (_, __) => Row(mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final dy = sin((_wave.value * 2 * pi) - i * pi / 3) * 6;
                        return Transform.translate(offset: Offset(0, dy),
                            child: Container(width: 10, height: 10,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.80),
                                    shape: BoxShape.circle)));
                      }))),
              const SizedBox(height: 12),
              Text(widget.message, textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: _B.font,
                      fontSize: 15, color: _B.white)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  WAVE PAINTER  (decorative animated ocean)
// ═══════════════════════════════════════════════════════════════
class _WavePainter extends CustomPainter {
  final double phase;
  _WavePainter(this.phase);
  @override
  void paint(Canvas canvas, Size size) {
    void drawWave(Color color, double yFactor, double amp, double phaseOff) {
      final paint = Paint()..color = color..style = PaintingStyle.fill;
      final path = Path()..moveTo(0, size.height);
      for (double x = 0; x <= size.width; x++) {
        path.lineTo(x,
            size.height * yFactor + sin(x / size.width * 2 * pi + phase + phaseOff) * amp);
      }
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }
    drawWave(_B.ocean.withOpacity(0.22), 0.55, 18, 0);
    drawWave(_B.oceanLight.withOpacity(0.18), 0.68, 12, 1.2);
    drawWave(_B.sandMid.withOpacity(0.30), 0.82, 8, 0.6);
  }
  @override bool shouldRepaint(_WavePainter old) => old.phase != phase;
}

// ═══════════════════════════════════════════════════════════════
//  OBJECT TILE  (bounces in on entry)
// ═══════════════════════════════════════════════════════════════
class _ObjectTile extends StatefulWidget {
  final String emoji;
  final int index;
  final double size;
  const _ObjectTile({required this.emoji, required this.index, required this.size});
  @override State<_ObjectTile> createState() => _ObjectTileState();
}
class _ObjectTileState extends State<_ObjectTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: Duration(milliseconds: 300 + widget.index * 50));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    Future.delayed(Duration(milliseconds: widget.index * 40), _ctrl.forward);
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _anim,
      child: Container(
        width: widget.size, height: widget.size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.80),
          borderRadius: BorderRadius.circular(widget.size * 0.28),
          border: Border.all(color: _B.sandMid.withOpacity(0.60), width: 1.5),
          boxShadow: [BoxShadow(
              color: _B.ocean.withOpacity(0.18), blurRadius: 8,
              offset: const Offset(0, 3))],
        ),
        alignment: Alignment.center,
        child: Text(widget.emoji,
            style: TextStyle(fontSize: widget.size * 0.52)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MAIN EXERCISE
// ═══════════════════════════════════════════════════════════════
class CountExercise extends StatefulWidget {
  const CountExercise({super.key});
  @override State<CountExercise> createState() => _CountExerciseState();
}

class _CountExerciseState extends State<CountExercise>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  static const int _targetScore = 10;
  static const int _maxLives    = 3;
  static const int _maxAnswer   = 10;

  final Random _rng = Random();

  late int    _correctCount;
  late String _currentObject;
  int  _score  = 0;
  int  _lives  = _maxLives;
  bool _showGameOver   = false;
  bool? _isAnswerCorrect;
  bool _showFinalCeleb = false;
  bool _isProcessing   = false;
  bool _showLoader     = false;
  String _loaderMsg    = '';

  late AnimationController _waveCtrl;
  late Animation<double>   _waveAnim;
  late AnimationController _entryCtrl;
  late Animation<double>   _entryFade;
  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;
  late AnimationController _padCtrl;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _waveCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 4))..repeat();
    _waveAnim = Tween<double>(begin: 0, end: 2 * pi).animate(_waveCtrl);

    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600))..forward();
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _shakeCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _padCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800))..forward();

    _generateNewQuestion();
    _loadBannerAd();
  }

  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _waveCtrl.dispose(); _entryCtrl.dispose();
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
    _currentObject = _B.objects[_rng.nextInt(_B.objects.length)];
    _correctCount  = _rng.nextInt(_maxAnswer) + 1;
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

    if (selected == _correctCount) {
      xp.addXP(1, context: context);
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
      _showGameOver = _showFinalCeleb = _isProcessing = _showLoader = false;
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
    _withLoader(message: '🌊 Next wave coming...',
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
                colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(
                color: _B.ocean.withOpacity(0.55), blurRadius: 30)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🏖️', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 10),
            Text(tr(context).areYouSureQuitGame, textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: _B.font,
                    fontSize: 20, color: _B.white)),
            const SizedBox(height: 6),
            Text(tr(context).youWillLoseYourProgress, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13,
                    color: Colors.white.withOpacity(0.75))),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: _BeachBtn(label: tr(context).cancel,
                  color: Colors.white.withOpacity(0.20),
                  borderColor: Colors.white.withOpacity(0.55),
                  onTap: () { audio.playEventSound('cancelButton');
                  Navigator.pop(ctx, false); })),
              const SizedBox(width: 12),
              Expanded(child: _BeachBtn(label: tr(context).ok,
                  color: _B.coral, onTap: () { audio.playEventSound('clickButton');
                  Navigator.pop(ctx, true); })),
            ]),
          ]),
        ),
      ),
    );
    if (shouldQuit ?? false) {
      await _withLoader(message: '👋 See you at the beach!',
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
        backgroundColor: _B.sand,
        bottomNavigationBar: context.watch<ExperienceManager>().adsEnabled
            ? _OceanBannerBar(bannerAd: _bannerAd, isLoaded: _isBannerAdLoaded)
            : null,
        body: Stack(children: [
          // Animated gradient BG
          AnimatedBuilder(
            animation: _waveAnim,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(const Color(0xFF7DD3FC),
                        const Color(0xFF38BDF8), sin(_waveAnim.value * 0.5 + 1) * 0.5 + 0.5)!,
                    const Color(0xFFFFF0CC),
                    Color.lerp(const Color(0xFFFFD97D),
                        const Color(0xFFFBBF24), sin(_waveAnim.value) * 0.5 + 0.5)!,
                  ],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Ocean waves at bottom
          Positioned(bottom: 0, left: 0, right: 0,
            child: AnimatedBuilder(animation: _waveAnim,
              builder: (_, __) => CustomPaint(
                painter: _WavePainter(_waveAnim.value),
                size: Size(MediaQuery.of(context).size.width, 140),
              ),
            ),
          ),
          // Floating deco
          ..._buildDeco(),

          SafeArea(
            child: _showGameOver ? _buildGameOver() :
            FadeTransition(opacity: _entryFade,
              child: Column(children: [
                const Padding(padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Userstatutbar()),
                const SizedBox(height: 6),
                _buildHUD(audio),
                const SizedBox(height: 10),
                // Object display
                _buildObjectDisplay(),
                const SizedBox(height: 10),
                // Answer pad
                Expanded(child: _buildAnswerPad()),
                const SizedBox(height: 6),
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
          if (_showLoader) _WaveLoader(message: _loaderMsg),
        ]),
      ),
    );
  }

  List<Widget> _buildDeco() => [
    Positioned(top: 40, left: 10, child: Opacity(opacity: 0.18,
        child: const Text('☀️', style: TextStyle(fontSize: 55)))),
    Positioned(top: 80, right: 15, child: Opacity(opacity: 0.14,
        child: const Text('🌴', style: TextStyle(fontSize: 40)))),
    Positioned(top: 35, right: 70, child: Opacity(opacity: 0.12,
        child: const Text('⛅', style: TextStyle(fontSize: 28)))),
  ];

  Widget _buildHUD(AudioManager audio) {
    final pct = (_score / _targetScore).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.60),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _B.ocean.withOpacity(0.40), width: 1.5),
        boxShadow: [BoxShadow(color: _B.ocean.withOpacity(0.15),
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
                    color: _B.ocean.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: _B.ocean.withOpacity(0.40), width: 1.5)),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 17, color: _B.ocean)),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: _B.ocean.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _B.ocean.withOpacity(0.40), width: 1.2)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('🏖️', style: TextStyle(fontSize: 14)),
              SizedBox(width: 5),
              Text('Beach Count!', style: TextStyle(fontFamily: _B.font,
                  fontSize: 13, color: _B.dark)),
            ]),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: _B.sandMid.withOpacity(0.40),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _B.sandMid.withOpacity(0.80), width: 1.2)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('⭐', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Text('$_score/$_targetScore',
                  style: const TextStyle(fontFamily: _B.font,
                      fontSize: 14, color: _B.dark)),
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
            Container(height: 10, color: _B.ocean.withOpacity(0.15)),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(height: 10,
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFF0EA5E9), Color(0xFF14B8A6),
                            Color(0xFFFFD97D)]))),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildObjectDisplay() {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) {
        final dx = sin(_shakeAnim.value * pi * 7) * 9 * (1 - _shakeAnim.value);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.65),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _isAnswerCorrect == true
                ? const Color(0xFF22C55E)
                : _isAnswerCorrect == false
                ? _B.coral : _B.ocean.withOpacity(0.40),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(color: _B.ocean.withOpacity(0.14),
                blurRadius: 12, offset: const Offset(0, 4)),
            if (_isAnswerCorrect == true)
              BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.40),
                  blurRadius: 22),
            if (_isAnswerCorrect == false)
              BoxShadow(color: _B.coral.withOpacity(0.40), blurRadius: 22),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Prompt chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
                color: _B.ocean.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _B.ocean.withOpacity(0.45), width: 1.2)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🔍', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                  AppLocalizations.of(context)?.howManyObjects(_currentObject) ??
                      'How many $_currentObject?',
                  style: const TextStyle(fontFamily: _B.font,
                      fontSize: 13, color: _B.dark)),
            ]),
          ),
          const SizedBox(height: 12),
          // Object tiles in a wrap
          LayoutBuilder(builder: (_, box) {
            final tileSize = (box.maxWidth / 5.5).clamp(44.0, 64.0);
            return Wrap(
              spacing: 6, runSpacing: 6,
              alignment: WrapAlignment.center,
              children: List.generate(_correctCount, (i) =>
                  _ObjectTile(
                      emoji: _currentObject, index: i, size: tileSize)),
            );
          }),
        ]),
      ),
    );
  }

  Widget _buildAnswerPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _maxAnswer,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 10, crossAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (_, i) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + i * 30),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Opacity(
              opacity: v.clamp(0.0, 1.0),
              child: Transform.scale(scale: v.clamp(0.01, 1.0), child: child)),
          child: _ShellBtn(
            number: i + 1,
            color: _B.shellColors[i % _B.shellColors.length],
            onTap: () => _checkAnswer(i + 1),
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
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                  color: win ? const Color(0xFF22C55E) : _B.coral, width: 2.5),
              boxShadow: [BoxShadow(
                  color: win ? const Color(0xFF22C55E).withOpacity(0.25)
                      : _B.coral.withOpacity(0.25),
                  blurRadius: 30, offset: const Offset(0, 10))],
            ),
            child: Column(children: [
              Text(win ? '🎉 ${tr(context).awesome}!'
                  : '💔 ${tr(context).gameOver}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: _B.font, fontSize: 30,
                      color: win ? const Color(0xFF15803D) : _B.coral)),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final lit = _score >= ((i+1)*(_targetScore/3)).round();
                    return Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(lit ? '⭐' : '☆',
                            style: TextStyle(fontSize: lit ? 38 : 30,
                                color: lit ? _B.sandMid : Colors.grey.shade300)));
                  })),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _BPill('⭐', tr(context).score, '$_score/$_targetScore', _B.sandMid),
                _BPill('❤️', tr(context).remainingLives, '$_lives/$_maxLives',
                    _lives > 0 ? const Color(0xFF22C55E) : _B.coral),
              ]),
              const SizedBox(height: 20),
              _BeachBtn(label: '🌊 ${tr(context).playAgain}',
                  color: _B.ocean, shadowColor: _B.ocean,
                  onTap: _onReplayPressed),
              const SizedBox(height: 10),
              _BeachBtn(label: '🏠 ${tr(context).back}',
                  color: Colors.white.withOpacity(0.40),
                  borderColor: _B.ocean.withOpacity(0.55),
                  onTap: () => Navigator.pop(context)),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Shell button ────────────────────────────────────────────────
class _ShellBtn extends StatefulWidget {
  final int number; final Color color; final VoidCallback onTap;
  const _ShellBtn({required this.number, required this.color, required this.onTap});
  @override State<_ShellBtn> createState() => _ShellBtnState();
}
class _ShellBtnState extends State<_ShellBtn>
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
      onTapDown: (_) => _p.forward(), onTapUp: (_) => _p.reverse(),
      onTapCancel: () => _p.reverse(), onTap: widget.onTap,
      child: AnimatedBuilder(animation: _s,
        builder: (_, child) => Transform.scale(scale: _s.value, child: child),
        child: Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                  center: const Alignment(-0.30, -0.32), radius: 0.80,
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
                fontFamily: _B.font, fontSize: 18, color: _B.white,
                shadows: [Shadow(color: Colors.black38, blurRadius: 5,
                    offset: Offset(0, 2))])),
            Positioned(top: 5, left: 7, child: Container(width: 7, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(3)))),
          ]),
        ),
      ),
    );
  }
}

class _BPill extends StatelessWidget {
  final String emoji, label, value; final Color color;
  const _BPill(this.emoji, this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.50), width: 1.5)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontFamily: _B.font, fontSize: 10, color: color)),
        Text(value, style: TextStyle(fontFamily: _B.font, fontSize: 15,
            fontWeight: FontWeight.w700, color: color)),
      ]));
}

class _BeachBtn extends StatelessWidget {
  final String label; final VoidCallback onTap; final Color color;
  final Color? borderColor, shadowColor;
  const _BeachBtn({required this.label, required this.onTap,
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
          child: Text(label, style: const TextStyle(fontFamily: _B.font,
              fontSize: 18, color: _B.white,
              shadows: [Shadow(color: Colors.black26, blurRadius: 4)]))));
}

class _OceanBannerBar extends StatefulWidget {
  final BannerAd? bannerAd; final bool isLoaded;
  const _OceanBannerBar({required this.bannerAd, required this.isLoaded});
  @override State<_OceanBannerBar> createState() => _OceanBannerBarState();
}
class _OceanBannerBarState extends State<_OceanBannerBar>
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
              gradient: LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)])),
          child: widget.isLoaded && widget.bannerAd != null
              ? Center(child: SizedBox(height: adH,
              width: widget.bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: widget.bannerAd!)))
              : AnimatedBuilder(animation: _a, builder: (_, __) {
            final t = _a.value;
            return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(children: [
                  Opacity(opacity: 0.5+t*0.5, child: const Text('🌊', style: TextStyle(fontSize: 18))),
                  const SizedBox(width: 10),
                  Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12),
                      child: Container(height: 28,
                          color: Colors.white.withOpacity(0.18+t*0.18),
                          alignment: Alignment.center,
                          child: Text('✨  Advertisement  ✨',
                              style: TextStyle(fontFamily: _B.font, fontSize: 12,
                                  color: Colors.white.withOpacity(0.60+t*0.30)))))),
                  const SizedBox(width: 10),
                  Opacity(opacity: 0.5+t*0.5, child: const Text('🌊', style: TextStyle(fontSize: 18))),
                ]));
          }),
        ));
  }
}