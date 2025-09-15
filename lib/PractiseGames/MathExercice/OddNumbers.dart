import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import '../../XpSystem.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../tools/Ads_Manager.dart';
import 'Tools/AnimatedHeart.dart';

class EvenOddGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EvenOddExercise();
  }
}

class EvenOddExercise extends StatefulWidget {
  @override
  _EvenOddExerciseState createState() => _EvenOddExerciseState();
}

class _EvenOddExerciseState extends State<EvenOddExercise> {
  late int targetNumber;
  late bool isEven;

  static const int _targetScore = 10;
  static const int _maxLives = 3;

  int _score = 0;
  int _wrong = 0;
  int _lives = _maxLives;

  bool showGameOver = false;
  bool? _isAnswerCorrect;
  bool _showFinalCelebration = false;
  bool _isProcessingAnswer = false;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _generateNewQuestion();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _isBannerAdLoaded = false;
    _bannerAd = AdHelper.getBannerAd(() {
      if (mounted) setState(() => _isBannerAdLoaded = true);
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _generateNewQuestion() {
    targetNumber = _rng.nextInt(50) + 1;
    isEven = targetNumber % 2 == 0;
    _isAnswerCorrect = null;
    setState(() {});
  }

  Future<void> _checkAnswer(bool selectedEven) async {
    if (_isProcessingAnswer || showGameOver) return;
    _isProcessingAnswer = true;

    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    if (selectedEven == isEven) {
      xpManager.addXP(1, context: context);
      audioManager.playSfx('assets/audios/QuizGame_Sounds/correct.mp3');
      setState(() {
        _score++;
        _isAnswerCorrect = true;
      });

      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        if (_score >= _targetScore) {
          if (_lives > 0) xpManager.addTokenBanner(context, 1);
          setState(() {
            showGameOver = true;
            _isAnswerCorrect = null;
            _showFinalCelebration = true;
            _isProcessingAnswer = false;
          });
        } else {
          _isProcessingAnswer = false;
          _generateNewQuestion();
        }
      });
    } else {
      audioManager.playSfx('assets/audios/QuizGame_Sounds/incorrect.mp3');
      setState(() {
        _wrong++;
        _lives = (_lives > 0) ? _lives - 1 : 0;
        _isAnswerCorrect = false;
      });

      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        if (_lives == 0) {
          audioManager.playSfx("assets/audios/UI_Audio/SFX_Audio/FailMeme_SFX.mp3");
          setState(() {
            showGameOver = true;
            _isAnswerCorrect = null;
            _isProcessingAnswer = false;
          });
        } else {
          setState(() {
            _isAnswerCorrect = null;
            _isProcessingAnswer = false;
          });
        }
      });
    }
  }

  void _resetGame() {
    setState(() {
      _score = 0;
      _wrong = 0;
      _lives = _maxLives;
      showGameOver = false;
      _showFinalCelebration = false;
      _isProcessingAnswer = false;
    });
    _generateNewQuestion();
  }

  void _onReplayPressed() {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playEventSound('cancelButton');
    AdHelper.showInterstitialAd(
      context: context,
      onDismissed: _resetGame,
    );
  }

  Future<bool> _confirmQuit() async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final shouldQuit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text(tr(context).areYouSureQuitGame),
        content: Text(tr(context).youWillLoseYourProgress),
        actions: [
          TextButton(
            onPressed: () {
              audioManager.playEventSound('cancelButton');
              Navigator.pop(ctx, false);
            },
            child: Text(tr(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              audioManager.playEventSound('clickButton');
              Navigator.pop(ctx, true);
            },
            child: Text(tr(context).ok),
          ),
        ],
      ),
    );

    if (shouldQuit ?? false) {
      await AdHelper.showInterstitialAd(
        context: context,
        onDismissed: () => Navigator.pop(context, true),
      );
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.indigo.shade700;

    return WillPopScope(
      onWillPop: _confirmQuit,
      child: Scaffold(
        backgroundColor: Colors.indigo.shade50,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: showGameOver ? _buildGameOver(themeColor) : _buildGameUI(themeColor),
              ),
              if (_isAnswerCorrect != null)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Lottie.asset(
                      _isAnswerCorrect!
                          ? 'assets/animations/QuizzGame_Animation/DoneAnimation.json'
                          : 'assets/animations/QuizzGame_Animation/wrong.json',
                      repeat: false,
                    ),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: Provider.of<ExperienceManager>(context).adsEnabled &&
            _bannerAd != null &&
            _isBannerAdLoaded
            ? SafeArea(
          child: SizedBox(
            height: _bannerAd!.size.height.toDouble(),
            width: _bannerAd!.size.width.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        )
            : null,
      ),
    );
  }

  Widget _buildGameUI(Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(flex: 1,
              child: IconButton(
                onPressed: () async {
                  if (await _confirmQuit()) {
                    audioManager.playEventSound("cancelButton");
                    if (mounted) Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            const Expanded(
                flex: 16,
                child: Userstatutbar()),
          ],

        ),        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatCard(label: '${tr(context).score}', value: '$_score / $_targetScore', color: themeColor),
            Row(
              children: List.generate(_maxLives, (index) {
                final lost = index >= _lives;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedHeart(lost: lost),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 40),
        Text(
          AppLocalizations.of(context)!.isNumberEvenOrOdd(targetNumber),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: themeColor,
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _optionButton(true, AppLocalizations.of(context)!.even, themeColor),
            _optionButton(false, AppLocalizations.of(context)!.odd, themeColor),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildGameOver(Color themeColor) {
    final win = _score >= _targetScore && _lives > 0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            win
                ? 'assets/animations/QuizzGame_Animation/Champion.json'
                : 'assets/animations/QuizzGame_Animation/CuteTigerCrying.json',
            width: 300,
            repeat: true,
          ),
          const SizedBox(height: 16),
          Text(
            win ? "🎉 ${tr(context).awesome} !" : "💔 ${tr(context).gameOver}",
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: themeColor),
          ),
          const SizedBox(height: 10),
          Text("${tr(context).score} : $_score / $_targetScore", style: const TextStyle(fontSize: 24)),
          Text("${tr(context).remainingLives} : $_lives",
              style: TextStyle(
                  fontSize: 20, color: _lives > 0 ? Colors.green : Colors.redAccent)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _onReplayPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(tr(context).playAgain,
                style: const TextStyle(fontSize: 22, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _optionButton(bool value, String label, Color themeColor) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    return ElevatedButton(
      onPressed: () {
        audioManager.playEventSound('clickButton');
        _checkAnswer(value);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: themeColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        elevation: 6,
        shadowColor: themeColor.withOpacity(0.5),
      ),
      child: Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
