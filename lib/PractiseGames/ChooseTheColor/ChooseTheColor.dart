import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import 'package:mortaalim/tools/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';

class ColorMatchingGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ColorMatchingGameExercise();
  }
}

class ColorMatchingGameExercise extends StatefulWidget {
  @override
  _ColorMatchingGameExerciseState createState() => _ColorMatchingGameExerciseState();
}

class _ColorMatchingGameExerciseState extends State<ColorMatchingGameExercise> {
  final MusicPlayer player = MusicPlayer();

  final List<Map<String, String>> questions = [
    {'emoji': '🍓', 'color': 'Rouge'},
    {'emoji': '🍌', 'color': 'Jaune'},
    {'emoji': '🟢', 'color': 'Vert'},
    {'emoji': '⚫', 'color': 'Noir'},
    {'emoji': '🔵', 'color': 'Bleu'},
    {'emoji': '🍊', 'color': 'Orange'},
    {'emoji': '🤍', 'color': 'Blanc'},
  ];

  int currentQuestionIndex = 0;
  int score = 0;
  int wrong = 0;
  bool showGameOver = false;
  bool? _isAnswerCorrect;
  bool _showFinalCelebration = false;
  bool _isProcessingAnswer = false;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    questions.shuffle();
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

  void checkAnswer(String selected) async {
    if (_isProcessingAnswer) return;
    _isProcessingAnswer = true;

    final correct = questions[currentQuestionIndex]['color'];

    if (selected == correct) {
      await player.play('assets/audios/QuizGame_Sounds/correct.mp3');
      setState(() {
        score++;
        _isAnswerCorrect = true;
      });

      Future.delayed(Duration(milliseconds: 1200), () {
        if (score >= 10) {
          final manager = Provider.of<ExperienceManager>(context, listen: false);
          if (wrong == 0) manager.addTokenBanner(context, 1);
          setState(() {
            showGameOver = true;
            _isAnswerCorrect = null;
            _showFinalCelebration = true;
            _isProcessingAnswer = false;
          });
        } else {
          setState(() {
            currentQuestionIndex = (currentQuestionIndex + 1) % questions.length;
            _isAnswerCorrect = null;
            _isProcessingAnswer = false;
          });
        }
      });
    } else {
      await player.play('assets/audios/QuizGame_Sounds/incorrect.mp3');
      setState(() {
        wrong++;
        _isAnswerCorrect = false;
      });

      Future.delayed(Duration(milliseconds: 1200), () {
        setState(() {
          currentQuestionIndex = (currentQuestionIndex + 1) % questions.length;
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
      currentQuestionIndex = 0;
      showGameOver = false;
      _isAnswerCorrect = null;
      _showFinalCelebration = false;
      _isProcessingAnswer = false;
      questions.shuffle();
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
    final themeColor = Colors.deepPurple;
    final current = questions[currentQuestionIndex];

    final options = ['Rouge', 'Jaune', 'Bleu', 'Vert', 'Orange', 'Noir', 'Blanc'];
    options.shuffle();

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Center(child: Text('Jeu des Couleurs', style: TextStyle(fontWeight: FontWeight.bold))),
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
                  Text("🎉 Bien joué !",
                      style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: themeColor)),
                  SizedBox(height: 16),
                  Text("Tu as terminé la partie !", style: TextStyle(fontSize: 18)),
                  Text("Score : $score / 10", style: TextStyle(fontSize: 24)),
                  Text("Fautes : $wrong", style: TextStyle(fontSize: 20, color: Colors.red)),
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
              children: [
                Userstatutbar(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard('Score', '$score / 10', themeColor),
                    _buildStatCard('Fautes', '$wrong', Colors.redAccent),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Quelle est la couleur de ce symbole ?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: themeColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(current['emoji'] ?? '❓', style: TextStyle(fontSize: 80)),
                Spacer(),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: options.map((option) {
                    return ElevatedButton(
                      onPressed: () => checkAnswer(option),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                      ),
                      child: Text(option,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    );
                  }).toList(),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
          if (_isAnswerCorrect != null)
            Container(
              color: Colors.black.withOpacity(0.4),
              alignment: Alignment.center,
              child: SizedBox(
                width: 220,
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
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w700)),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
