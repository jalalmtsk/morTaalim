import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mortaalim/games/Quiz_Game/Result_QuizPage.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/tools/audio_tool/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';
import '../../Settings/SettingPanelInGame.dart';
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

  bool _showIntro = true;
  bool _isPaused = false;
  bool _showCorrectAnimation = false;
  bool _showWrongAnimation = false;

  late Timer _timer;

  late AnimationController _introController;
  late Animation<double> _scaleAnimation;

  // Combo UI state
  String _comboText = "";
  Color _comboColor = Colors.white;
  double _comboScale = 1.0;
  late AnimationController _comboAnimationController;
  Timer? _comboFadeTimer;

  int _comboCount = 0;
  final int _comboThresholdStart = 2;
  final int _comboThresholdMax = 10;

  final List<String> _comboSoundsStage1 = [
    'assets/audios/UI_Audio/SFX_Audio/ManSaysStunning.mp3',
    'assets/audios/UI_Audio/SFX_Audio/ManSaysExhilarating.mp3',
    'assets/audios/UI_Audio/SFX_Audio/ManSaysThrilling.mp3',
    'assets/audios/UI_Audio/SFX_Audio/ManSaysLegendary_SFX.mp3',
  ];

  final List<String> _comboSoundsStage2 = [
    'assets/audios/UI_Audio/SFX_Audio/MarimbaWinA1_SFX.mp3',
    'assets/audios/UI_Audio/SFX_Audio/MarimbaWinA2_SFX.mp3',
    'assets/audios/UI_Audio/SFX_Audio/MarimbaWinA3_SFX.mp3',
  ];

  int _highPitchIndex = 0;

  @override
  void initState() {
    super.initState();
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playAlert('assets/audios/QuizGame_Sounds/GameCountDown3Sec.mp3');
    audioManager.playSfx('assets/audios/QuizGame_Sounds/RoboticCountDown3sec.mp3');
    _loadBannerAd();
    _questions = _loadQuestions(widget.language)..shuffle();

    // Limit questions to max 15
    if (_questions.length > 15) {
      _questions = _questions.sublist(0, 15);
    }

    _comboAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() => setState(() {}));

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _scaleAnimation = CurvedAnimation(parent: _introController, curve: Curves.easeInOut);

    _introController.forward();

    // After 4 seconds, hide intro, start timer and background music
    Future.delayed(const Duration(seconds: 4), () {
      audioManager.playSfx('assets/audios/UI_Audio/SFX_Audio/CinematicStart_SFX.mp3');
      setState(() => _showIntro = false);
      _startTimer();

      audioManager.playBackgroundMusic(
        "assets/audios/BackGround_Audio/FunnyHappyMusic.mp3",
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _introController.dispose();
    _comboAnimationController.dispose();
    _bannerAd?.dispose();
    super.dispose();
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
      if (!_isPaused) {
        setState(() {
          _timeLeft--;
          if (_timeLeft == 0) _handleTimeout();
        });
      }
    });
  }

  void _handleTimeout() {
    _timer.cancel();
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playSfx('assets/audios/sound_effects/wrong_answer.mp3');
    audioManager.playSfx("assets/audios/sound_effects/angry.mp3");
    _showWrongFeedback();

    if (widget.mode == GameMode.single) {
      _player1Lives--;
    } else {
      _playerTurn == 1 ? _player1Lives-- : _player2Lives--;
    }

    _checkLivesAndProceed();
  }

  void _answerQuestion(int selected) {
    if (_answered) return;
    _timer.cancel();

    final audioManager = Provider.of<AudioManager>(context, listen: false);

    setState(() {
      _selectedIndex = selected;
      _answered = true;
      final isCorrect = selected == _questions[_currentQuestion].correctIndex;

      if (isCorrect) {
        _comboCount++;
        int xpToAdd = 2 + (_comboCount - 1);
        if (xpToAdd > 5) xpToAdd = 5;
        Provider.of<ExperienceManager>(context, listen: false).addXP(xpToAdd, context: context);

        if (widget.mode == GameMode.single) {
          _player1Score++;
        } else {
          _playerTurn == 1 ? _player1Score++ : _player2Score++;
        }

        if (_comboCount < 2) {
          audioManager.playSfx('assets/audios/UI_Audio/SFX_Audio/CorrectAnwser_SFX.mp3');
          _comboText = "";
        } else {
          final normalComboSound = _comboSoundsStage1[Random().nextInt(_comboSoundsStage1.length)];
          audioManager.playSfx(normalComboSound);

          final highPitchSound = _comboSoundsStage2[_highPitchIndex];
          audioManager.playSfx(highPitchSound);

          if (_highPitchIndex < _comboSoundsStage2.length - 1) {
            _highPitchIndex++;
          }

          _comboText = "Combo X$_comboCount";
          _comboScale = 1.0 + (_comboCount * 0.1).clamp(0.0, 1.0);

          if (_comboCount < 4) {
            _comboColor = Colors.greenAccent;
          } else if (_comboCount < 7) {
            _comboColor = Colors.orangeAccent;
          } else {
            _comboColor = Colors.redAccent;
          }

          _comboAnimationController.forward(from: 0);
          _comboFadeTimer?.cancel();
          _comboFadeTimer = Timer(const Duration(seconds: 2), () {
            setState(() => _comboText = "");
          });
        }

        _showCorrectAnimation = true;
        Future.delayed(const Duration(seconds: 2),
                () => setState(() => _showCorrectAnimation = false));
      } else {
        _comboCount = 0;
        _highPitchIndex = 0;
        _comboText = "";
        audioManager.playSfx("assets/audios/sound_effects/angry.mp3");
        audioManager.playSfx('assets/audios/UI_Audio/SFX_Audio/WrongAnwser_SFX.mp3');
        _showWrongFeedback();

        if (widget.mode == GameMode.single) {
          _player1Lives--;
        } else {
          _playerTurn == 1 ? _player1Lives-- : _player2Lives--;
        }
      }
    });

    // ✅ FIXED: check lives before proceeding
    Future.delayed(const Duration(seconds: 2), _checkLivesAndProceed);
  }


  Future<void> _checkLivesAndProceed() async {
    bool outOfLives = false;

    if (widget.mode == GameMode.single) {
      if (_player1Lives <= 0) outOfLives = true;
    } else {
      // Multiplayer: if either player has 0 lives → game ends (no dialog)
      if ((_playerTurn == 1 && _player1Lives <= 0) ||
          (_playerTurn == 2 && _player2Lives <= 0)) {
        _endGame();
        return;
      }
    }

    if (outOfLives) {
      // Single player → Show pay/ad dialog
      bool continueGame = await _showPayOrAdDialog();
      if (!continueGame) {
        _endGame();
        return;
      }
    } else {
      _nextTurn();
    }
  }


  void _showWrongFeedback() {
    setState(() => _showWrongAnimation = true);
    Future.delayed(const Duration(seconds: 2), () => setState(() => _showWrongAnimation = false));
  }

  Future<bool> _showPayOrAdDialog() async {
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title:  Text(tr(context).outOfHearts),
          content:  Text(tr(context).youHaveNoHeartsLeftWhatWouldYouLikeToDo),
          actions: [
            if (xpManager.Tolims > 0)
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                  xpManager.SpendTokenBanner(context, 1);
                  setState(() {
                    _player1Lives = 1;
                  });
                  _nextTurn(); // ✅ FIX: Move to the next question
                },
                child:  Text("${tr(context).pay} 1 Tolim"),
              ),
            TextButton(
              onPressed: () async {
                bool success = await AdHelper.showRewardedAd(context);
                if (!mounted) return;
                if (success) {
                  setState(() {
                    _player1Lives = 1;
                  });
                  Navigator.pop(context, true); // pop only after success & UI update
                  _nextTurn();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(tr(context).adFailedToLoadOrWasNotCompletedPleaseTryAgainLater)),
                  );
                  // Keep dialog open or handle retry
                }
              },
              child:  Text(tr(context).watchAd),
            ),


            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Quit"),
            ),
          ],
        );
      },
    ) ?? false;
  }



  void _endGame() {
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
  }

  void _nextTurn() {
    if (_currentQuestion + 1 >= _questions.length) {
      _endGame();
      return;
    }
    setState(() {
      _currentQuestion++;
      _selectedIndex = null;
      _answered = false;
      if (widget.mode == GameMode.multiplayer) {
        _playerTurn = _playerTurn == 1 ? 2 : 1;
      }
    });

    _startTimer();
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
        Text(name,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.deepOrange : Colors.grey[700])),
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: isActive ? Colors.deepOrange : Colors.grey.shade300,
              child: Text(avatar, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 4),
            Text("❤️ $lives", style: const TextStyle(fontSize: 16)),
            Text("🏆 $score", style: const TextStyle(fontSize: 16)),
          ],
        ),


      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    final question = _questions[_currentQuestion];
    final player1Name = widget.player1Name ?? tr(context).player1;
    final player2Name = widget.player2Name ?? tr(context).player2;
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
                      width: 450,
                      height: 450,
                    ),
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
                  colors: [Colors.orange.withOpacity(0.1), Colors.orange.shade200],
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_circle_left,
                              size: 50,
                              color: Colors.deepOrangeAccent,
                            ),
                            onPressed: () {
                              audioManager.playEventSound('cancelButton');
                              Navigator.of(context).pop();
                            },
                            tooltip: tr(context).back,
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () async {
                              audioManager.playEventSound('clickButton');
                              setState(() => _isPaused = true);
                              await showDialog(
                                context: context,
                                builder: (_) => const SettingsDialog(),
                              );
                              setState(() => _isPaused = false);
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
                          Text("⏳ $_timeLeft ${tr(context).secondsLeft}",
                              style: const TextStyle(
                                  fontSize: 28, color: Colors.deepOrange)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Combo Text UI here:
                    if (_comboText.isNotEmpty)
                      Transform.scale(
                        scale: 1.0 + 0.3 * _comboAnimationController.value,
                        child: Text(
                          _comboText,
                          style: TextStyle(
                            fontSize: (40 + (_comboCount * 2).clamp(0, 20)).toDouble(),
                            fontWeight: FontWeight.bold,
                            color: _comboColor,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: _comboColor.withOpacity(0.8),
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),

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
                          '🏆 $_player1Score | ❤️ $_player1Lives',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        shadowColor: Colors.deepOrange.withOpacity(0.4),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            question.questionText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange),
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
                              icon = const Icon(Icons.clear_outlined,
                                  color: Colors.white);
                            }
                          }

                          return ElevatedButton.icon(
                            onPressed: () => _answerQuestion(index),
                            icon: icon ?? const SizedBox.shrink(),
                            label: Text(question.options[index],
                                style: const TextStyle(fontSize: 18)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: bgColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 5,
                              shadowColor: Colors.deepOrange.withOpacity(0.5),
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
            bottomNavigationBar: context.watch<ExperienceManager>().adsEnabled &&
                _bannerAd != null &&
                _isBannerAdLoaded
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
            child: Lottie.asset('assets/animations/QuizzGame_Animation/DoneAnimation.json',
                width: 500, repeat: false),
          ),
        if (_showWrongAnimation)
          Center(
            child: Lottie.asset('assets/animations/QuizzGame_Animation/Fiery Lolo.json',
                width: 200, repeat: false),
          ),
      ],
    );
  }
}
