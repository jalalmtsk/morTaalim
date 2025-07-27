import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';

class CountObject extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CountExercise();
  }
}

class CountExercise extends StatefulWidget {
  @override
  _CountExerciseState createState() => _CountExerciseState();
}

class _CountExerciseState extends State<CountExercise> {
  final MusicPlayer player = MusicPlayer();
  final List<String> objectEmojis = ["🍎", "🏀", "✏️", "🧸", "🐠"];
  late int correctCount;
  late String currentObject;
  int score = 0;
  int wrong = 0;
  bool showGameOver = false;

  bool? _isAnswerCorrect; // for correct/wrong animations
  bool _showFinalCelebration = false;

  bool _isProcessingAnswer = false; // <-- Added to block rapid taps

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

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
    setState(() {
      currentObject = objectEmojis[Random().nextInt(objectEmojis.length)];
      correctCount = Random().nextInt(10) + 1;
      _isAnswerCorrect = null;
    });
  }

  void checkAnswer(int selected) async {
    if (_isProcessingAnswer) return;  // Ignore taps while processing

    _isProcessingAnswer = true;       // Block input immediately

    if (selected == correctCount) {
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
            _isProcessingAnswer = false; // Unlock input after game ends
          });
        } else {
          setState(() {
            _isProcessingAnswer = false; // Unlock input before next question
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
          _isProcessingAnswer = false;  // Unlock input after wrong animation
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
      _isProcessingAnswer = false;  // Reset input flag on game reset
    });
  }

  // New function to show interstitial ad on replay
  void _onReplayPressed() {
    AdHelper.showInterstitialAd(onDismissed: () {
      resetGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.orange.shade700;

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Compte les objets', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
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
                  Text("Score : $score / 10",
                      style: TextStyle(fontSize: 24)),
                  Text("Fautes : $wrong",
                      style:
                      TextStyle(fontSize: 20, color: Colors.redAccent)),
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
                      padding: EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25)),
                    ),
                    child: Text("Rejouer",
                        style:
                        TextStyle(fontSize: 22, color: Colors.white)),
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
                SizedBox(height: 30),
                Text(
                  "Combien de $currentObject vois-tu ?",
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: themeColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Center(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: List.generate(
                      correctCount,
                          (index) => Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          currentObject,
                          style: TextStyle(fontSize: 40),
                        ),
                      ),
                    ),
                  ),
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    alignment: WrapAlignment.center,
                    children: List.generate(10, (index) {
                      int number = index + 1;
                      return ElevatedButton(
                        onPressed: () => checkAnswer(number),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(20),
                          elevation: 6,
                          shadowColor: Colors.orange.shade300,
                        ),
                        child: Text(
                          '$number',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      );
                    }),
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
          Text(label,
              style: TextStyle(
                  fontSize: 16, color: color, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
