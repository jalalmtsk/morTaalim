import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';
import 'Tools/AnimatedHeart.dart';

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

class _CountExerciseState extends State<CountExercise>
    with SingleTickerProviderStateMixin {
  final MusicPlayer player = MusicPlayer();
  final List<String> objectEmojis = ["🍎", "🏀", "✏️", "🧸", "🐠"];
  late int correctCount;
  late String currentObject;
  int score = 0;
  int wrong = 0;
  int lives = 3;

  bool showGameOver = false;
  bool? _isAnswerCorrect;
  bool _showFinalCelebration = false;
  bool _isProcessingAnswer = false;

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
    if (_isProcessingAnswer) return;
    _isProcessingAnswer = true;

    if (selected == correctCount) {
      await player.play('assets/audios/QuizGame_Sounds/correct.mp3');
      setState(() {
        score++;
        _isAnswerCorrect = true;
      });

      Future.delayed(Duration(milliseconds: 1500), () {
        if (score >= 10) {
          final manager =
          Provider.of<ExperienceManager>(context, listen: false);
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
        lives = (lives > 0) ? lives - 1 : 0;
        _isAnswerCorrect = false;
      });

      Future.delayed(Duration(milliseconds: 1500), () {
        if (lives == 0) {
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

  void resetGame() {
    setState(() {
      score = 0;
      wrong = 0;
      lives = 3;
      showGameOver = false;
      _showFinalCelebration = false;
      generateNewQuestion();
      _isProcessingAnswer = false;
    });
  }

  void _onReplayPressed() {
    AdHelper.showInterstitialAd(onDismissed: () {
      resetGame();
    }, context: context);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.deepPurple.shade400;

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      body: Stack(
        children: [
          // 🌈 Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade200, Colors.orange.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: showGameOver
                ? _buildGameOver(themeColor)
                : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Userstatutbar(),

                // 🏆 Score + Lives Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard('Score', '$score / 10', themeColor),
                    Row(
                      children: List.generate(3, (index) {
                        bool lost = index >= lives;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AnimatedHeart(lost: lost),
                        );
                      }),
                    ),

                  ],
                ),
                SizedBox(height: 20),

                // 🏆 Progress bar
                LinearProgressIndicator(
                  value: score / 10,
                  backgroundColor: Colors.white,
                  color: themeColor,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(12),
                ),
                SizedBox(height: 20),

                Text(
                  "Combien de $currentObject vois-tu ?",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),

                // 🎨 Animated objects
                Center(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: List.generate(
                      correctCount,
                          (index) => AnimatedScale(
                        scale: 1,
                        duration: Duration(milliseconds: 400),
                        child: Container(
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(2, 2),
                              )
                            ],
                          ),
                          child: Text(
                            currentObject,
                            style: TextStyle(fontSize: 36),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Spacer(),

                // 🔢 Answer buttons
                Wrap(
                  spacing: 6,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: List.generate(10, (index) {
                    int number = index + 1;
                    return ElevatedButton(
                      onPressed: () => checkAnswer(number),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(24),
                        elevation: 8,
                        shadowColor: Colors.deepPurpleAccent,
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
                SizedBox(height: 20),
              ],
            ),
          ),

          // ✅ Correct/Wrong animation overlay
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

  Widget _buildGameOver(Color themeColor) {
    bool win = score >= 10 && lives > 0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
              win
                  ? 'assets/animations/QuizzGame_Animation/Champion.json'
                  : 'assets/animations/QuizzGame_Animation/wrong.json',
              width: 200,
              repeat: false),
          SizedBox(height: 16),
          Text(
            win ? "🎉 Bravo !" : "💔 Game Over",
            style: TextStyle(
                fontSize: 40, fontWeight: FontWeight.bold, color: themeColor),
          ),
          SizedBox(height: 10),
          Text("Score : $score / 10",
              style: TextStyle(fontSize: 24, color: Colors.black87)),
          Text("Vies restantes : $lives",
              style: TextStyle(
                  fontSize: 20,
                  color: lives > 0 ? Colors.green : Colors.redAccent)),

          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _onReplayPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: Text("Rejouer",
                style: TextStyle(fontSize: 22, color: Colors.white)),
          ),
        ],
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
