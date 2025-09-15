import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import '../../XpSystem.dart';
import '../../main.dart';
import '../../tools/Ads_Manager.dart';
import 'Tools/AnimatedHeart.dart';

class TargetNumberGame extends StatelessWidget {
  const TargetNumberGame({super.key});
  @override
  Widget build(BuildContext context) => const TargetNumberExercise();
}

class TargetNumberExercise extends StatefulWidget {
  const TargetNumberExercise({super.key});
  @override
  State<TargetNumberExercise> createState() => _TargetNumberExerciseState();
}

class _TargetNumberExerciseState extends State<TargetNumberExercise>
    with SingleTickerProviderStateMixin {
  static const int _targetScore = 10;
  static const int _maxLives = 3;
  static const int _maxOptions = 6; // how many options per round

  final Random _rng = Random();

  late int targetNumber;
  int currentSum = 0;
  List<int> chosenNumbers = [];
  List<int> options = [];

  int score = 0;
  int wrong = 0;
  int lives = _maxLives;

  bool showGameOver = false;
  bool? _isAnswerCorrect;
  bool _showFinalCelebration = false;
  bool _isProcessingAnswer = false;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _generateNewTarget();
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

  List<int> _generateOptions() {
    final List<int> opts = [];
    while (opts.length < _maxOptions) {
      int num = _rng.nextInt(15) + 1; // random numbers 1..15
      if (!opts.contains(num)) opts.add(num);
    }
    return opts;
  }

  void _generateNewTarget() {
    options = _generateOptions();

    // choose 2-3 random numbers from options to make target
    final subset = (options..shuffle()).take(2 + _rng.nextInt(2)).toList();
    targetNumber = subset.reduce((a, b) => a + b);

    currentSum = 0;
    chosenNumbers.clear();
    _isAnswerCorrect = null;
    setState(() {});
  }

  Future<void> _checkAnswer(int selected) async {
    if (_isProcessingAnswer || showGameOver) return;
    _isProcessingAnswer = true;

    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    HapticFeedback.selectionClick();

    final newSum = currentSum + selected;

    if (newSum == targetNumber) {
      await audioManager.playSfx('assets/audios/QuizGame_Sounds/correct.mp3');
      setState(() {
        score++;
        currentSum = newSum;
        chosenNumbers.add(selected);
        _isAnswerCorrect = true;
      });

      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        if (score >= _targetScore) {
          if (lives > 0) xpManager.addTokenBanner(context, 1);
          audioManager.playSfx(
              'assets/audios/UI_Audio/SFX_Audio/VictoryOrchestral_SFX.mp3');
          audioManager
              .playSfx('assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3');
          setState(() {
            showGameOver = true;
            _isAnswerCorrect = null;
            _showFinalCelebration = true;
            _isProcessingAnswer = false;
          });
        } else {
          _generateNewTarget();
          _isProcessingAnswer = false;
        }
      });
    } else if (newSum > targetNumber) {
      await audioManager.playSfx('assets/audios/QuizGame_Sounds/incorrect.mp3');
      setState(() {
        wrong++;
        lives = (lives > 0) ? lives - 1 : 0;
        _isAnswerCorrect = false;
        currentSum = 0;
        chosenNumbers.clear();
      });

      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        if (lives == 0) {
          audioManager
              .playSfx("assets/audios/UI_Audio/SFX_Audio/FailMeme_SFX.mp3");
          audioManager
              .playSfx("assets/audios/UI_Audio/SFX_Audio/victory1_SFX.mp3");
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
    } else {
      setState(() {
        currentSum = newSum;
        chosenNumbers.add(selected);
        _isProcessingAnswer = false;
      });
    }
  }

  void _resetGame() {
    setState(() {
      score = 0;
      wrong = 0;
      lives = _maxLives;
      showGameOver = false;
      _showFinalCelebration = false;
      currentSum = 0;
      chosenNumbers.clear();
      _isProcessingAnswer = false;
      _isAnswerCorrect = null;
    });
    _generateNewTarget();
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
    final themeColor = Colors.deepPurple.shade400;

    return WillPopScope(
      onWillPop: _confirmQuit,
      child: Scaffold(
        backgroundColor: Colors.deepPurple.shade50,
        body: Stack(
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth;
                  final horizontalPadding = 16.0;
                  final contentWidth = maxW.clamp(0, 720);

                  return Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentWidth.toDouble()),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding, vertical: 12),
                        child: showGameOver
                            ? _buildGameOver(themeColor)
                            : _buildGameUI(themeColor),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Correct / Wrong overlay
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

  Widget _buildGameUI(Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                if (await _confirmQuit()) return;
              },
            ),
            const Expanded(child: Userstatutbar()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StatCard(
                label: 'Score', value: '$score / $_targetScore', color: themeColor),
            Row(
              children: List.generate(_maxLives, (index) {
                final lost = index >= lives;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedHeart(lost: lost),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: score / _targetScore,
            backgroundColor: Colors.white,
            color: themeColor,
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          tr(context).reachTheNumber,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: themeColor,
          ),
        ),
        const SizedBox(height: 10),
        Text("$targetNumber",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 60, fontWeight: FontWeight.bold, color: themeColor)),
        const SizedBox(height: 10),
        Text(
            chosenNumbers.isEmpty
                ? tr(context).noNumberChosen
                : chosenNumbers.join(" + "),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w600, color: themeColor)),
        const SizedBox(height: 10),
        Text("${tr(context).currentSum} : $currentSum",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w600, color: themeColor)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: options.map((num) {
            return ElevatedButton(
              onPressed: () => _checkAnswer(num),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(18),
                elevation: 8,
              ),
              child: Text('$num',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildGameOver(Color themeColor) {
    final win = score >= _targetScore && lives > 0;
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
          Text(win ? "🎉 ${tr(context).awesome} !" : "💔 ${tr(context).gameOver}",
              style: TextStyle(
                  fontSize: 40, fontWeight: FontWeight.bold, color: themeColor)),
          const SizedBox(height: 10),
          Text("${tr(context).score} : $score / $_targetScore", style: const TextStyle(fontSize: 24)),
          Text("${tr(context).remainingLives} : $lives",
              style: TextStyle(
                  fontSize: 20, color: lives > 0 ? Colors.green : Colors.redAccent)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _onReplayPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child:  Text("${tr(context).playAgain}",
                style: TextStyle(fontSize: 22, color: Colors.white)),
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
          Text(label,
              style: TextStyle(
                  fontSize: 16, color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
