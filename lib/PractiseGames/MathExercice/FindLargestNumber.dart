import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';

class FindLargestNumberGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FindLargestNumberExercise();
  }
}

class FindLargestNumberExercise extends StatefulWidget {
  @override
  _FindLargestNumberExerciseState createState() => _FindLargestNumberExerciseState();
}

class _FindLargestNumberExerciseState extends State<FindLargestNumberExercise> {
  final MusicPlayer player = MusicPlayer();
  final MusicPlayer player2 = MusicPlayer();      // for layered sounds
  final MusicPlayer bgmPlayer = MusicPlayer();    // background music player
  final MusicPlayer bgmVictory = MusicPlayer();   // victory background music player

  late List<int> numbers;
  late int correctAnswer;

  int score = 0;
  int wrong = 0;
  bool showGameOver = false;

  bool? _isAnswerCorrect;
  bool _showFinalCelebration = false;
  bool _isProcessingAnswer = false;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  bool _isAdLoading = false;       // track ad loading state
  bool _isBgmPlaying = true;       // track background music playing state

  @override
  void initState() {
    super.initState();
    generateNewQuestion();
    _loadBannerAd();
    _startBackgroundMusic();
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

  Future<void> _startBackgroundMusic() async {
    bgmPlayer.setVolume(0.3);
    await bgmPlayer.play('assets/audios/sound_track/SakuraGirl_bkG.mp3', loop: true);
  }

  Future<void> _stopBackgroundMusic() async {
    await bgmPlayer.stop();
  }

  Future<void> _playVictoryMusic() async {
    player2.play("assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3");
    bgmVictory.setVolume(0.4);
    bgmVictory.play("assets/audios/sound_track/SakuraGirlYay_BcG.mp3", loop: true);
    await player.play('assets/audios/sound_effects/victory1_SFX.mp3');
  }

  void _toggleBackgroundMusic() {
    if (_isBgmPlaying) {
      _stopBackgroundMusic();
    } else {
      _startBackgroundMusic();
    }
    setState(() {
      _isBgmPlaying = !_isBgmPlaying;
    });
  }

  @override
  void dispose() {
    player.dispose();
    player2.dispose();
    bgmPlayer.dispose();
    bgmVictory.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void generateNewQuestion() {
    final rand = Random();
    numbers = List.generate(4, (_) => rand.nextInt(99) + 1);
    correctAnswer = numbers.reduce(max);
    _isAnswerCorrect = null;
  }

  void checkAnswer(int selected) async {
    if (_isProcessingAnswer) return;
    _isProcessingAnswer = true;

    if (selected == correctAnswer) {
      await player.play('assets/audios/QuizGame_Sounds/correct.mp3');
      setState(() {
        score++;
        _isAnswerCorrect = true;
      });

      Future.delayed(Duration(milliseconds: 1500), () async {
        if (score >= 10) {
          final manager = Provider.of<ExperienceManager>(context, listen: false);
          if (wrong == 0) {
            manager.addTokenBanner(context, 1);
          }
          await _playVictoryMusic();  // play victory music here
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
    setState(() => _isAdLoading = true);
    AdHelper.showInterstitialAd(onDismissed: () {
      setState(() => _isAdLoading = false);
      bgmVictory.dispose();
      resetGame();
    }, context: context);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.deepPurple.shade700;

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        backgroundColor: themeColor,
        // No back button as per your request
        title: Center(child: Text('Le Plus Grand Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
        actions: [
          IconButton(
            onPressed: _toggleBackgroundMusic,
            icon: Icon(
              _isBgmPlaying ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
            ),
            tooltip: _isBgmPlaying ? 'Mute Background Music' : 'Play Background Music',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: showGameOver
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("🎉 Bravo !", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: themeColor)),
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
                    onPressed: _isAdLoading ? null : _onReplayPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: _isAdLoading
                        ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                        : Text("Rejouer", style: TextStyle(fontSize: 22, color: Colors.white)),
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
                SizedBox(height: 16),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: numbers
                      .map(
                        (num) => ElevatedButton(
                      onPressed: () => checkAnswer(num),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(20),
                        elevation: 6,
                        shadowColor: Colors.deepPurple.shade300,
                      ),
                      child: Text('$num', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                      .toList(),
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
          if (_isAdLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 4,
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
