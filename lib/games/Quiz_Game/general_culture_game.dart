import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mortaalim/games/Quiz_Game/Result_QuizPage.dart';
import 'package:mortaalim/tools/audio_tool/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';
import '../../tools/SettingPanelInGame.dart';
import 'Questions.dart';
import 'question_model.dart';
import 'ModeSelectorPage.dart';

enum GameMode { single, multiplayer }

class QuizGameApp extends StatelessWidget {
  const QuizGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModeSelectorPage();
  }
}

class QuizPage extends StatefulWidget {
  final GameMode mode;
  final String? player1Name;
  final String? player2Name;
  final String? player1Emoji;
  final String? player2Emoji;
  final QuizLanguage language;

  const QuizPage({
    super.key,
    required this.mode,
    this.player1Name,
    this.player2Name,
    this.player1Emoji,
    this.player2Emoji,
    required this.language,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  BannerAd? _bannerAd;
  final MusicPlayer _player = MusicPlayer();
  final MusicPlayer _backgroundMusic = MusicPlayer();
  final MusicPlayer _CountDown = MusicPlayer();
  final MusicPlayer _CountDownRobot = MusicPlayer();
  final MusicPlayer _fire = MusicPlayer();
  bool _isBannerAdLoaded = false;

  late List<Question> _questions;
  int _currentQuestion = 0;
  int _player1Score = 0;
  int _player2Score = 0;
  int _playerTurn = 1;
  int _player1Lives = 2;
  int _player2Lives = 2;
  int _timeLeft = 30;
  int? _selectedIndex;
  bool _answered = false;
  bool _showCorrectAnimation = false;
  bool _showWrongAnimation = false;
  bool _showIntro = true;
  late Timer _timer;

  late AnimationController _introController;
  late Animation<double> _scaleAnimation;

  @override
  initState()  {
    super.initState();
    _loadBannerAd();
    _PlaySounds();
    _questions = _loadQuestions(widget.language)..shuffle();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _scaleAnimation = CurvedAnimation(parent: _introController, curve: Curves.easeInOut);

    _introController.forward();

    Future.delayed(const Duration(seconds: 4), () {
      setState(() => _showIntro = false);
      _startTimer();
    });
  }

  Future<void> _PlaySounds() async {
    try {
      _CountDownRobot.play("assets/audios/QuizGame_Sounds/RoboticCountDown3sec.mp3");
      await _CountDown.play("assets/audios/QuizGame_Sounds/GameCountDown3Sec.mp3");
      if (Provider.of<ExperienceManager>(context, listen: false).musicEnabled) {
        _backgroundMusic.play("assets/audios/QuizGame_Sounds/heyWhistleUkulele30Sec.mp3", loop: true);
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
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

  List<Question> _loadQuestions(QuizLanguage lang) => questionsByLanguage[lang] ?? [];

  void _startTimer() {
    _timeLeft = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
        if (_timeLeft == 0) _handleTimeout();
      });
    });
  }

  void _handleTimeout() {
    _timer.cancel();
    _playSound('assets/audios/sound_effects/wrong_answer.mp3');
    _fire.play("assets/audios/sound_effects/angry.mp3");
    _showWrongFeedback();
    if (widget.mode == GameMode.single) {
      _player1Lives--;
    } else {
      (widget.mode == GameMode.multiplayer && _playerTurn == 1)
          ? _player1Lives--
          : _player2Lives--;
    }
    _nextTurn();
  }

  void _playSound(String asset) async {
    await _player.stop();
    await _player.play(asset);
  }

  void _answerQuestion(int selected) {
    if (_answered) return;
    _timer.cancel();
    setState(() {
      _selectedIndex = selected;
      _answered = true;
      final isCorrect = selected == _questions[_currentQuestion].correctIndex;
      if (isCorrect) {
        Provider.of<ExperienceManager>(context, listen: false).addXP(30, context: context);

        // Increment score on correct answer
        if (widget.mode == GameMode.single) {
          _player1Score++;
        } else {
          if (_playerTurn == 1) {
            _player1Score++;
          } else {
            _player2Score++;
          }
        }

        _playSound('assets/audios/QuizGame_Sounds/correct.mp3');
        _showCorrectAnimation = true;
        Future.delayed(const Duration(seconds: 2), () => setState(() => _showCorrectAnimation = false));
      } else {
        _fire.play("assets/audios/sound_effects/angry.mp3");
        _playSound('assets/audios/QuizGame_Sounds/incorrect.mp3');
        _showWrongFeedback();

        // Decrement lives on wrong answer
        if (widget.mode == GameMode.single) {
          _player1Lives--;
        } else {
          if (_playerTurn == 1) {
            _player1Lives--;
          } else {
            _player2Lives--;
          }
        }
      }
    });
    Future.delayed(const Duration(seconds: 2), _nextTurn);
  }


  void _showWrongFeedback() {
    setState(() => _showWrongAnimation = true);
    Future.delayed(const Duration(seconds: 2), () => setState(() => _showWrongAnimation = false));
  }

  void _nextTurn() {
    setState(() {
      _currentQuestion++;
      _selectedIndex = null;
      _answered = false;
      if (widget.mode == GameMode.multiplayer) {
        _playerTurn = _playerTurn == 1 ? 2 : 1;
      }
    });

    if (_currentQuestion >= _questions.length ||
        (widget.mode == GameMode.single && _player1Lives == 0) ||
        (widget.mode == GameMode.multiplayer && (_player1Lives == 0 || _player2Lives == 0))) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            player1Score: _player1Score,
            player2Score: _player2Score,
            mode: widget.mode,
            language: widget.language,
          ),
        ),
      );
    } else {
      _startTimer();
    }
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadBannerAd();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _backgroundMusic.dispose();
    _CountDown.dispose();
    _introController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  Widget _buildPlayerInfo({
    required String name,
    required String avatar,
    required int score,
    required int lives,
    required bool isActive,
  }) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: isActive ? Colors.deepOrange : Colors.grey.shade300,
          child: Text(avatar, style: const TextStyle(fontSize: 28)),
        ),
        const SizedBox(height: 4),
        Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.deepOrange : Colors.grey[700])),
        const SizedBox(height: 4),
        Text("❤️ $lives", style: const TextStyle(fontSize: 16)),
        Text("🧰 $score", style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestion];
    final player1Name = widget.player1Name ?? "Player 1";
    final player2Name = widget.player2Name ?? "Player 2";
    final player1Avatar = widget.player1Emoji ?? "😀";
    final player2Avatar = widget.player2Emoji ?? "😎";

    return Stack(
      children: [
        if (_showIntro)
          FadeTransition(
            opacity: _scaleAnimation,
            child: Scaffold(
              backgroundColor: Colors.orange.shade100,
              body: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  color: Colors.orange.shade100,
                  child: Center(
                    child: Lottie.asset(
                        "assets/animations/QuizzGame_Animation/CountdownGo.json",
                    width: 450, height: 450),
                  ),
                ),
              ),
            ),
          )
        else
          Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.withValues(alpha: 0.1), Colors.orange.shade200],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Userstatutbar(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_circle_left,
                              size: 50,
                              color: Colors.deepOrangeAccent,),
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Back',
                          ),

                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const SettingsDialog(),
                              );
                            },
                          ),


                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          Text(
                            "Question ${_currentQuestion + 1}/",
                            style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange),
                          ),
                          Text(
                            "${_questions.length}",
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.orangeAccent),
                          ),

                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: _timeLeft / 30,
                            backgroundColor: Colors.orange.shade100,
                            color: Colors.deepOrange,
                          ),
                          const SizedBox(height: 6),
                          Text(
                              "⏳ $_timeLeft seconds left",
                              style: const TextStyle(
                                  fontSize: 28,
                                  color: Colors.deepOrange)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Show scoreboard
                    if (widget.mode == GameMode.multiplayer)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildPlayerInfo(
                            name: player1Name,
                            avatar: player1Avatar,
                            score: _player1Score,
                            lives: _player1Lives,
                            isActive: _playerTurn == 1,
                          ),
                          _buildPlayerInfo(
                            name: player2Name,
                            avatar: player2Avatar,
                            score: _player2Score,
                            lives: _player2Lives,
                            isActive: _playerTurn == 2,
                          ),
                        ],
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '🧰 $_player1Score | ❤️ $_player1Lives',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                        ),
                      ),


                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        shadowColor: Colors.deepOrange.withValues(alpha: 0.4),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            question.questionText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        childAspectRatio: 3,
                        children: List.generate(question.options.length, (index) {
                          final isCorrect = index == question.correctIndex;
                          final isSelected = index == _selectedIndex;
                          final showResult = _answered;

                          Color bgColor = Colors.white;
                          Icon? icon;

                          if (showResult) {
                            if (isCorrect) {
                              bgColor = Colors.green.shade400;
                              icon = const Icon(Icons.check, color: Colors.white);
                            } else if (isSelected) {
                              bgColor = Colors.red.shade300;
                              icon = const Icon(Icons.clear_outlined, color: Colors.white);
                            }
                          }

                          return ElevatedButton.icon(
                            onPressed: () => _answerQuestion(index),
                            icon: icon ?? const SizedBox.shrink(),
                            label: Text(question.options[index], style: const TextStyle(fontSize: 18)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: bgColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 5,
                              shadowColor: Colors.deepOrange.withValues(alpha: 0.5),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            /// ADS BANNER
            ///
            bottomNavigationBar: context.watch<ExperienceManager>().adsEnabled && _bannerAd != null && _isBannerAdLoaded
                ? SafeArea(
              child: Container(
                color: Colors.orange.shade200,
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            )
                : null,
          ),
        if (_showCorrectAnimation)
          Center(
            child: Lottie.asset('assets/animations/QuizzGame_Animation/DoneAnimation.json', width: 500, repeat: false),
          ),
        if (_showWrongAnimation)
          Center(
            child: Lottie.asset('assets/animations/QuizzGame_Animation/Fiery Lolo.json', width: 200, repeat: false),
          ),
      ],
    );
  }
}
