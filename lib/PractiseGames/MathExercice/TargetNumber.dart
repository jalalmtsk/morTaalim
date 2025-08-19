import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';

class TargetNumberGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TargetNumberExercise();
  }
}

class TargetNumberExercise extends StatefulWidget {
  @override
  _TargetNumberExerciseState createState() => _TargetNumberExerciseState();
}

class _TargetNumberExerciseState extends State<TargetNumberExercise> {
  final MusicPlayer player = MusicPlayer();

  late int targetNumber;
  int currentSum = 0;
  List<int> chosenNumbers = [];

  int score = 0;
  int wrong = 0;
  bool showGameOver = false;

  bool? _isAnswerCorrect;
  bool _showFinalCelebration = false;
  bool _isProcessingAnswer = false;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  final int maxTarget = 20;
  final List<int> options = List.generate(20, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    generateNewTarget();
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

  void generateNewTarget() {
    final rand = Random();
    targetNumber = rand.nextInt(maxTarget - 5) + 6; // cible entre 6 et maxTarget
    currentSum = 0;
    chosenNumbers.clear();
    setState(() {
      _isAnswerCorrect = null;
    });
  }

  void checkAnswer(int selected) async {
    if (_isProcessingAnswer) return;
    _isProcessingAnswer = true;

    int newSum = currentSum + selected;

    if (newSum == targetNumber) {
      await player.play('assets/audios/QuizGame_Sounds/correct.mp3');
      setState(() {
        score++;
        currentSum = newSum;
        chosenNumbers.add(selected);
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
          generateNewTarget();
          setState(() {
            _isAnswerCorrect = null;
            _isProcessingAnswer = false;
          });
        }
      });
    } else if (newSum > targetNumber) {
      await player.play('assets/audios/QuizGame_Sounds/incorrect.mp3');
      setState(() {
        wrong++;
        _isAnswerCorrect = false;
        currentSum = 0;
        chosenNumbers.clear();
      });

      Future.delayed(Duration(milliseconds: 1500), () {
        setState(() {
          _isAnswerCorrect = null;
          _isProcessingAnswer = false;
        });
      });
    } else {
      setState(() {
        currentSum = newSum;
        chosenNumbers.add(selected);
        _isProcessingAnswer = false;
      });
    }
  }

  void resetGame() {
    setState(() {
      score = 0;
      wrong = 0;
      showGameOver = false;
      _showFinalCelebration = false;
      generateNewTarget();
      _isProcessingAnswer = false;
      currentSum = 0;
      chosenNumbers.clear();
      _isAnswerCorrect = null;
    });
  }

  void _onReplayPressed() {
    AdHelper.showInterstitialAd(
        context: context,
        onDismissed: () {
      resetGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.deepPurple.shade700;

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Center(child: Text('Nombre Cible', style: TextStyle(fontWeight: FontWeight.bold))),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: showGameOver
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("🎉 Bravo !", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: themeColor)),
                  SizedBox(height: 16),
                  Text("Tu dois marquer 10 points pour obtenir 1 Tolim.",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: themeColor),
                      textAlign: TextAlign.center),
                  SizedBox(height: 16),
                  Text("Score : $score / 10", style: TextStyle(fontSize: 24)),
                  Text("Fautes : $wrong", style: TextStyle(fontSize: 20, color: Colors.redAccent)),
                  SizedBox(height: 24),
                  if (_showFinalCelebration)
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Lottie.asset('assets/animations/QuizzGame_Animation/Champion.json', repeat: false),
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
                Text("Atteins le nombre :", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: themeColor)),
                SizedBox(height: 10),
                Text("$targetNumber", style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: themeColor)),
                SizedBox(height: 10),
                Text(
                  chosenNumbers.isEmpty
                      ? "Aucun nombre choisi"
                      : chosenNumbers.map((e) => e.toString()).join(" + "),
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: themeColor),
                ),
                SizedBox(height: 10),
                Text("Somme actuelle : $currentSum", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: themeColor)),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    alignment: WrapAlignment.center,
                    children: options.map((num) {
                      return ElevatedButton(
                        onPressed: () => checkAnswer(num),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(20),
                          elevation: 6,
                          shadowColor: themeColor.withOpacity(0.5),
                        ),
                        child: Text(
                          '$num',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      );
                    }).toList(),
                  ),
                ),
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
      bottomNavigationBar: Provider.of<ExperienceManager>(context).adsEnabled && _bannerAd != null && _isBannerAdLoaded
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
