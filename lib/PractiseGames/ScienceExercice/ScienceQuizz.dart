import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';

class ScienceQuizGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScienceQuizExercise();
  }
}

class ScienceQuizExercise extends StatefulWidget {
  @override
  _ScienceQuizExerciseState createState() => _ScienceQuizExerciseState();
}

class _ScienceQuizExerciseState extends State<ScienceQuizExercise> {
  final MusicPlayer player = MusicPlayer();

  final List<Map<String, Object>> questions = [
    {
      'question': 'Quelle est l\'état de l\'eau à température ambiante ?',
      'options': ['Solide', 'Liquide', 'Gaz'],
      'answer': 'Liquide',
      'image': 'assets/images/water_state.png',
    },
    {
      'question': 'Quel gaz respirons-nous ?',
      'options': ['Oxygène', 'Hydrogène', 'Azote'],
      'answer': 'Oxygène',
      'image': 'assets/images/oxygen.png',
    },
    {
      'question': 'Le Soleil est composé principalement de quel élément ?',
      'options': ['Fer', 'Hydrogène', 'Carbone'],
      'answer': 'Hydrogène',
      'image': 'assets/images/sun.png',
    },
    {
      'question': 'Comment s\'appelle le gaz qui remplit les ballons légers ?',
      'options': ['Hélium', 'Oxygène', 'Azote'],
      'answer': 'Hélium',
      'image': 'assets/images/helium_balloon.png',
    },
    {
      'question': 'De quoi est faite la glace ?',
      'options': ['Eau', 'Feu', 'Air'],
      'answer': 'Eau',
      'image': 'assets/images/ice.png',
    },
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

    final correctAnswer = questions[currentQuestionIndex]['answer'] as String;

    if (selected == correctAnswer) {
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
            _isAnswerCorrect = null;
            _isProcessingAnswer = false;
            currentQuestionIndex = (currentQuestionIndex + 1) % questions.length;
          });
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
          currentQuestionIndex = (currentQuestionIndex + 1) % questions.length;
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
      currentQuestionIndex = 0;
      _isProcessingAnswer = false;
    });
  }

  void _onReplayPressed() {
    AdHelper.showInterstitialAd(onDismissed: () {
      resetGame();

    },     context: context,);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.green.shade700;
    final currentQuestion = questions[currentQuestionIndex];
    final imagePath = currentQuestion['image'] as String?;

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Center(
            child: Text('Quiz Sciences - Chimie', style: TextStyle(fontWeight: FontWeight.bold))),
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
                  Text("🎉 Bravo !",
                      style: TextStyle(
                          fontSize: 40, fontWeight: FontWeight.bold, color: themeColor)),
                  SizedBox(height: 16),
                  Text("Tu dois marquer 10 points pour obtenir 1 Tolim.",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600, color: themeColor),
                      textAlign: TextAlign.center),
                  SizedBox(height: 16),
                  Text("Score : $score / 10", style: TextStyle(fontSize: 24)),
                  Text("Fautes : $wrong",
                      style: TextStyle(fontSize: 20, color: Colors.redAccent)),
                  SizedBox(height: 24),
                  if (_showFinalCelebration)
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Lottie.asset('assets/animations/QuizzGame_Animation/Champion.json',
                          repeat: false),
                    ),
                  ElevatedButton(
                    onPressed: _onReplayPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child:
                    Text("Rejouer", style: TextStyle(fontSize: 22, color: Colors.white)),
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

                if (imagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Image.asset(
                      imagePath,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),

                Text(currentQuestion['question'] as String,
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold, color: themeColor),
                    textAlign: TextAlign.center),
                Spacer(),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children:
                  (currentQuestion['options'] as List<String>).map((option) {
                    return ElevatedButton(
                      onPressed: () => checkAnswer(option),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                        elevation: 6,
                        shadowColor: themeColor.withOpacity(0.5),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
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
              style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
