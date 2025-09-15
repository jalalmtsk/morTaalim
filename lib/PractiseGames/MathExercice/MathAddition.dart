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

class MathAdditionGame extends StatelessWidget {
  const MathAdditionGame({super.key});

  @override
  Widget build(BuildContext context) => const MathAdditionExercise();
}

class MathAdditionExercise extends StatefulWidget {
  const MathAdditionExercise({super.key});
  @override
  State<MathAdditionExercise> createState() => _MathAdditionExerciseState();
}

class _MathAdditionExerciseState extends State<MathAdditionExercise>
    with SingleTickerProviderStateMixin {
  // ---- Tunables ----
  static const int _targetScore = 10;
  static const int _maxLives = 3;

  final Random _rng = Random();
  int _firstNumber = 0;
  int _secondNumber = 0;
  int _correctAnswer = 0;

  int _score = 0;
  int _wrong = 0;
  int _lives = _maxLives;
  int _streak = 0;

  bool _showGameOver = false;
  bool? _isAnswerCorrect;
  bool _showFinalCelebration = false;
  bool _isProcessingAnswer = false;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

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
      if (mounted) {
        setState(() => _isBannerAdLoaded = true);
      }
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _generateNewQuestion() {
    final maxNumber = 10 + (_score ~/ 3); // difficulty scaling
    _firstNumber = _rng.nextInt(maxNumber) + 1;
    _secondNumber = _rng.nextInt(maxNumber) + 1;
    _correctAnswer = _firstNumber + _secondNumber;
    _isAnswerCorrect = null;
    setState(() {});
  }

  Future<void> _checkAnswer(int selected) async {
    if (_isProcessingAnswer || _showGameOver) return;
    _isProcessingAnswer = true;

    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    HapticFeedback.selectionClick();

    if (selected == _correctAnswer) {
      _streak++;
      int xpGain = 1;
      if (_streak >= 3) xpGain += 1;
      if (_streak >= 5) xpGain += 2;
      xpManager.addXP(xpGain, context: context);

      audioManager.playSfx('assets/audios/QuizGame_Sounds/correct.mp3');
      setState(() {
        _score++;
        _isAnswerCorrect = true;
      });

      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        if (_score >= _targetScore) {
          if (_lives >= 1) {
            xpManager.addTokenBanner(context, 1);
            audioManager.playSfx('assets/audios/UI_Audio/SFX_Audio/VictoryOrchestral_SFX.mp3');
            audioManager.playSfx('assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3');
          }
          setState(() {
            _showGameOver = true;
            _isAnswerCorrect = null;
            _showFinalCelebration = true;
            _isProcessingAnswer = false;
          });
        } else {
          setState(() => _isProcessingAnswer = false);
          _generateNewQuestion();
        }
      });
    } else {
      _streak = 0;
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
            _showGameOver = true;
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
      _streak = 0;
      _showGameOver = false;
      _showFinalCelebration = false;
      _isProcessingAnswer = false;
    });
    _generateNewQuestion();
  }

  void _onReplayPressed() {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playEventSound('cancelButton');
    AdHelper.showInterstitialAd(
      onDismissed: _resetGame,
      context: context,
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
        onDismissed: () => Navigator.pop(context, true),
        context: context,
      );
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.blue.shade700;
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    return WillPopScope(
      onWillPop: () async {
        final quit = await _confirmQuit();
        if (quit && mounted) {
          audioManager.playEventSound("cancelButton");
        }
        return quit;
      },
      child: Scaffold(
        backgroundColor: Colors.blue.shade50,
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade200, Colors.cyan.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _showGameOver
                      ? _buildGameOver(themeColor)
                      : _buildGameScreen(themeColor),
                ),
              ),
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

  Widget _buildGameScreen(Color themeColor) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () async {
                if (await _confirmQuit()) {
                  if (mounted) Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.arrow_back),
            ),
            const Expanded(child: Userstatutbar()),
          ],
        ),
        const SizedBox(height: 12),

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

        const SizedBox(height: 16),

        LinearProgressIndicator(
          value: _score / _targetScore,
          backgroundColor: Colors.white,
          color: themeColor,
          minHeight: 12,
        ),

        const SizedBox(height: 30),
        Text(
          "$_firstNumber + $_secondNumber = ?",
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: themeColor),
        ),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: List.generate(20, (index) {
            final n = index + 1;
            return ElevatedButton(
              onPressed: () => _checkAnswer(n),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(20),
              ),
              child: Text('$n', style: const TextStyle(fontSize: 22, color: Colors.white)),
            );
          }),
        ),
        const SizedBox(height: 24),
        if (_streak >= 2)
          Text("🔥 ${tr(context).streak} $_streak!", style: TextStyle(fontSize: 20, color: Colors.orange.shade800)),
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
            win ? "🎉 ${tr(context).awesome}!" : "💔 ${tr(context).gameOver}",
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: themeColor),
          ),
          const SizedBox(height: 10),
          Text("${tr(context).score} : $_score / $_targetScore", style: const TextStyle(fontSize: 24)),
          Text(" ${tr(context).remainingLives}: $_lives",
              style: TextStyle(fontSize: 20, color: _lives > 0 ? Colors.green : Colors.redAccent)),
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
