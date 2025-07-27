import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';

class NumberComparisonGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NumberComparisonExercise();
  }
}

class NumberComparisonExercise extends StatefulWidget {
  @override
  _NumberComparisonExerciseState createState() => _NumberComparisonExerciseState();
}

class _NumberComparisonExerciseState extends State<NumberComparisonExercise> {
  final MusicPlayer player = MusicPlayer();

  late int numberA;
  late int numberB;

  int score = 0;
  int wrong = 0;
  bool showGameOver = false;

  bool? _isAnswerCorrect;
  bool _showFinalCelebration = false;

  bool _isProcessingAnswer = false;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  final int maxNumber = 20;

  @override
  void initState() {
    super.initState();
    generateNewQuestion();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _isBannerAdLoaded = false;
    _bannerAd = AdHelper.getBannerAd(() {
      setState(() {
        _isBannerAdLoaded = true;
      });
    });
  }

  @override
  void dispose() {
    player.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void generateNewQuestion() {
    final rand = Random();
    setState(() {
      numberA = rand.nextInt(maxNumber) + 1;
      do {
        numberB = rand.nextInt(maxNumber) + 1;
      } while (numberB == numberA);
      _isAnswerCorrect = null;
    });
  }

  void checkAnswer(int selectedNumber) async {
    if (_isProcessingAnswer) return;
    _isProcessingAnswer = true;

    final correctNumber = numberA > numberB ? numberA : numberB;

    if (selectedNumber == correctNumber) {
      await player.play('assets/audios/QuizGame_Sounds/correct.mp3');
      setState(() {
        score++;
        _isAnswerCorrect = true;
      });

      Future.delayed(Duration(milliseconds: 1500), () {
        if (score >= 10) {
          final manager = Provider.of<ExperienceManager>(context, listen: false);
          if (wrong == 0) {
            manager.addTokenBanner(context, 1);
          }
          setState(() {
            showGameOver = true;
            _isAnswerCorrect = null;
            _showFinalCelebration = true;
            _isProcessingAnswer = false;
          });
        } else {
          setState(() {
            _isProcessingAnswer = false;
          });
          generateNewQuestion();
        }
      });
    } else {
      await player.play('assets/audios/QuizGame_Sounds/incorrect.mp3');
      setState(() {
        wrong++;
        _isAnswerCorrect = false;
      });

      Future.delayed(Duration(milliseconds: 1500), () {
        setState(() {
          _isAnswerCorrect = null;
          _isProcessingAnswer = false;
        });
      });
    }
  }

  void resetGame() {
    setState(() {
      score = 0;
      wrong = 0;
      showGameOver = false;
      _showFinalCelebration = false;
      generateNewQuestion();
      _isProcessingAnswer = false;
    });
  }

  void _onReplayPressed() {
    AdHelper.showInterstitialAd(onDismissed: () {
      resetGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.blue.shade700;

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Center(
          child: Text('Jeu de Comparaison', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: showGameOver
                ? SingleChildScrollView(
              child: Column(
                children: [
                  Userstatutbar(),
                  const SizedBox(height: 100,),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "🎉 Bravo !",
                          style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: themeColor),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Tu dois marquer 10 points pour obtenir 1 Tolim.",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: themeColor),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text("Score : $score / 10", style: TextStyle(fontSize: 24)),
                        Text("Fautes : $wrong", style: TextStyle(fontSize: 20, color: Colors.redAccent)),
                        SizedBox(height: 24),

                        if (_showFinalCelebration)
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: Lottie.asset(
                              'assets/animations/QuizzGame_Animation/Champion.json',
                              repeat: false,
                            ),
                          ),

                        ElevatedButton(
                          onPressed: _onReplayPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          child: Text("Rejouer", style: TextStyle(fontSize: 22, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Userstatutbar(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard('Score', '$score / 10', themeColor),
                    _buildStatCard('Fautes', '$wrong', Colors.redAccent),
                  ],
                ),
                SizedBox(height: 40),
                Text(
                  "Quel est le plus grand nombre ?",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: themeColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _numberButton(numberA, themeColor),
                    Text("ou", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: themeColor)),
                    _numberButton(numberB, themeColor),
                  ],
                ),
                Spacer(),
              ],
            ),
          ),

          if (_isAnswerCorrect != null)
            Container(
              color: Colors.black.withOpacity(0.4),
              alignment: Alignment.center,
              child: SizedBox(
                width: 200,
                height: 200,
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
        child: Container(
          height: _bannerAd!.size.height.toDouble(),
          width: _bannerAd!.size.width.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      )
          : null,
    );
  }

  Widget _numberButton(int number, Color themeColor) {
    return ElevatedButton(
      onPressed: () => checkAnswer(number),
      style: ElevatedButton.styleFrom(
        backgroundColor: themeColor,
        shape: CircleBorder(),
        padding: EdgeInsets.all(30),
        elevation: 6,
        shadowColor: themeColor.withOpacity(0.5),
      ),
      child: Text(
        '$number',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}