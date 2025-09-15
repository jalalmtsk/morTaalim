import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mortaalim/games/Quiz_Game/Result_QuizPage.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
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

  // TTS----------------------------------
  final FlutterTts flutterTts = FlutterTts();
  bool _isTtsMuted = false; // Track if TTS is muted

  // ADS
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

  late String player1Name;
  late String player2Name;
  late String player1Emoji;
  late String player2Emoji;

  @override
  void initState() {
    super.initState();

    // Save passed values or fallback to defaults
    player1Name = widget.player1Name ?? 'Player1';
    player2Name = widget.player2Name ?? 'Player2';
    player1Emoji = widget.player1Emoji ?? '😀';
    player2Emoji = widget.player2Emoji ?? '😎';

    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playAlert('assets/audios/QuizGame_Sounds/GameCountDown3Sec.mp3');
    audioManager.playSfx('assets/audios/QuizGame_Sounds/RoboticCountDown3sec.mp3');
    _configureTts();
    _loadBannerAd();
    _questions = _loadQuestions(widget.language)..shuffle();

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

    Future.delayed(const Duration(seconds: 4), () {
      audioManager.playSfx('assets/audios/UI_Audio/SFX_Audio/CinematicStart_SFX.mp3');
      setState(() => _showIntro = false);
      _startTimer();
      _readQuestion(_questions[_currentQuestion]);
      audioManager.playBackgroundMusic("assets/audios/BackGround_Audio/FunnyHappyMusic.mp3");
    });
  }



  Future<void> _configureTts() async {
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    _setTtsLanguage(widget.language);
  }

  void _setTtsLanguage(QuizLanguage lang) async {
    switch (lang) {
      case QuizLanguage.english:
        await flutterTts.setLanguage("en-US");
        break;
      case QuizLanguage.french:
        await flutterTts.setLanguage("fr-FR");
        break;
      case QuizLanguage.arabic:
        await flutterTts.setLanguage("ar-SA");
        var voices = await flutterTts.getVoices;
        var arabicVoice = voices.firstWhere(
                (v) => v['locale'] == 'ar-SA',
            orElse: () => voices.first);
        await flutterTts.setVoice(arabicVoice);
        break;

      case QuizLanguage.deutch:
        await flutterTts.setLanguage("de-DE");
        break;
      case QuizLanguage.spanish:
        await flutterTts.setLanguage("es-ES");
        break;
      case QuizLanguage.amazigh:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  Future<void> _readQuestion(Question question) async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    if (_isTtsMuted) return;

    if (widget.language == QuizLanguage.arabic) {
      await flutterTts.stop();

      // Use question.id instead of _currentQuestion
      String audioPath = 'assets/audios/tts_female/arabic_Questions_QuizzGame/qst${question.id}.mp3';

      audioManager.playAlert(audioPath);

    } else {
      String text = question.questionText;
      text += ". Options: ";
      for (int i = 0; i < question.options.length; i++) {
        text += "${i + 1}. ${question.options[i]}. ";
      }

      await flutterTts.stop();
      await flutterTts.speak(text);
    }
  }





  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    _introController.dispose();
    _comboAnimationController.dispose();
    _bannerAd?.dispose();
    flutterTts.stop(); // ✅ Stop TTS when leaving the page
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
    _timeLeft = 40;
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

  void _answerQuestion(int selected) async {
    if (_answered) return;

    // Stop reading immediately
    await flutterTts.stop();
    _timer.cancel();

    final audioManager = Provider.of<AudioManager>(context, listen: false);

    setState(() {
      _selectedIndex = selected;
      _answered = true;
      final isCorrect = selected == _questions[_currentQuestion].correctIndex;

      if (isCorrect) {
        if (widget.mode == GameMode.single) {
          // Combo logic only for single player
          _comboCount++;
          int xpToAdd = 2 + (_comboCount - 1);
          if (xpToAdd > 5) xpToAdd = 5;
          Provider.of<ExperienceManager>(context, listen: false).addXP(xpToAdd, context: context);

          _player1Score++;

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
        } else {
          // Multiplayer: No combo logic, just add score to current player
          _playerTurn == 1 ? _player1Score++ : _player2Score++;
        }

        _showCorrectAnimation = true;
        Future.delayed(const Duration(seconds: 2),
                () => setState(() => _showCorrectAnimation = false));
      } else {
        // Wrong answer resets combo for single player; no combo for multiplayer anyway
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

    // Check lives after 2 seconds
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
    await flutterTts.stop();

    int countdown = 15; // ⏱ 15 seconds
    late StateSetter dialogSetState;
    Timer? timer;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            dialogSetState = setState;

            // Start timer only once
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (countdown > 0) {
                dialogSetState(() => countdown--);
              } else {
                t.cancel();
                Navigator.pop(context, false); // Auto-quit
              }
            });

            return AlertDialog(
              title: Text(tr(context).outOfHearts),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr(context).youHaveNoHeartsLeftWhatWouldYouLikeToDo),
                  const SizedBox(height: 10),
                  Text(
                    "⏳ $countdown seconds remaining",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  ),
                ],
              ),
              actions: [
                if (xpManager.Tolims > 0)
                  TextButton(
                    onPressed: () {
                      timer?.cancel();
                      Navigator.pop(context, true);
                      xpManager.SpendTokenBanner(context, 1);
                      setState(() {
                        _player1Lives = 1;
                      });
                      _nextTurn();
                    },
                    child: Text("${tr(context).pay} 1 Tolim"),
                  ),
                TextButton(
                  onPressed: () async {
                    timer?.cancel();
                    bool success = await AdHelper.showRewardedAd(context);
                    if (!mounted) return;
                    if (success) {
                      setState(() {
                        _player1Lives = 1;
                      });
                      Navigator.pop(context, true);
                      _nextTurn();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              tr(context).adFailedToLoadOrWasNotCompletedPleaseTryAgainLater),
                        ),
                      );
                    }
                  },
                  child: Text(tr(context).watchAd),
                ),
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.pop(context, false);
                  },
                  child: const Text("Quit"),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      timer?.cancel();
    }) ?? false;
  }




  void _endGame() async{
    await flutterTts.stop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          player1Score: _player1Score,
          player2Score: _player2Score,
          mode: widget.mode,
          language: widget.language,
          player1Name: widget.player1Name,
          player2Name: widget.player2Name,
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

    _readQuestion(_questions[_currentQuestion]);
  }


  Widget _buildPlayerInfo({
    required String name,
    required String avatar,
    required int score,
    required int lives,
    required bool isActive,
  }) {
    return Container(
      width: 120,
      height: 120,
      padding: const EdgeInsets.symmetric( horizontal: 4),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
          colors: [
            Colors.deepOrange.shade400.withOpacity(0.6),
            Colors.orange.shade200.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: isActive ? null : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive
            ? [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ]
            : [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        border: isActive
            ? Border.all(color: Colors.deepOrange, width: 2)
            : Border.all(color: Colors.transparent),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isActive ? Colors.deepOrange.shade900 : Colors.grey.shade700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          CircleAvatar(
            radius: 26,
            backgroundColor: isActive ? Colors.deepOrange : Colors.orange.shade100,
            child: Text(
              avatar,
              style: TextStyle(
                fontSize: 32,
                color: isActive ? Colors.white : Colors.deepOrange.shade300,
                shadows: isActive
                    ? [
                  Shadow(
                    color: Colors.deepOrange.shade700,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite, color: Colors.red.shade400, size: 20),
              const SizedBox(width: 2),
              Text(
                '$lives',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Icon(Icons.emoji_events, color: Colors.amber.shade600, size: 20),
              const SizedBox(width: 3),
              Text(
                '$score',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
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
                  colors: [
                    Colors.orange.withOpacity(0.1),
                    Colors.orange.shade200,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Userstatutbar(),

                    // Top navigation row with back and settings buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back button styled as a circular elevated button
                          Material(
                            color: Colors.deepOrangeAccent,
                            shape: const CircleBorder(),
                            elevation: 6,
                            child: IconButton(
                              iconSize: 30,
                              icon: const Icon(Icons.arrow_circle_left, color: Colors.white),
                              onPressed: () {
                                audioManager.playEventSound('cancelButton');
                                Navigator.of(context).pop();
                              },
                              tooltip: tr(context).back,
                            ),
                          ),

                          // Settings button with subtle elevation and rounded rectangle
                          Material(
                            color: Colors.orange.shade300,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 4,
                            child: IconButton(
                              iconSize: 30,
                              icon: const Icon(Icons.settings, color: Colors.deepOrange),
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
                          ),
                        ],
                      ),
                    ),

                    // Question number indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              text: 'Question ',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                              children: [
                                TextSpan(
                                  text: '${_currentQuestion + 1}/',
                                  style: const TextStyle(color: Colors.orangeAccent),
                                ),
                                TextSpan(text: '${_questions.length}'),
                              ],
                            ),
                          ),

                          // TTS and Replay controls with consistent style
                          Row(
                            children: [
                              _buildCircleIconButton(
                                icon: Icons.replay_circle_filled,
                                tooltip: "Replay Question",
                                onPressed: () async {
                                  await flutterTts.stop();
                                  await _readQuestion(question);
                                },
                                color: Colors.deepOrange,
                              ),
                              _buildCircleIconButton(
                                icon: _isTtsMuted ? Icons.volume_mute_outlined : Icons.volume_down_outlined,
                                tooltip: _isTtsMuted ?  "Unmute" :  "Mute",
                                onPressed: () async {
                                  setState(() => _isTtsMuted = !_isTtsMuted);
                                  if (_isTtsMuted) {
                                    await flutterTts.stop();
                                  } else {
                                    await _readQuestion(question);
                                  }
                                },
                                color: Colors.deepOrange,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Show scoreboard or linear progress for single player
                    if (widget.mode == GameMode.multiplayer)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildPlayerInfo(
                              name: player1Name,
                              avatar: player1Avatar,
                              score: _player1Score,
                              lives: _player1Lives,
                              isActive: _playerTurn == 1,
                            ),

                            Row(
                              children: [
                                const Icon(Icons.hourglass_bottom, color: Colors.deepOrange),
                                const SizedBox(width: 2),
                                Text(
                                  "$_timeLeft ${tr(context).secondsLeft}",
                                  style: const TextStyle(
                                    fontSize: 28,
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            _buildPlayerInfo(
                              name: player2Name,
                              avatar: player2Avatar,
                              score: _player2Score,
                              lives: _player2Lives,
                              isActive: _playerTurn == 2,
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: LinearProgressIndicator(
                          value: _timeLeft / 40,
                          backgroundColor: Colors.orange.shade100,
                          color: Colors.deepOrange,
                          minHeight: 10,
                        ),
                      ),

                    // Timer and score row for single player mode
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 10),
                          if (widget.mode == GameMode.single)
                            Row(
                              children: [
                                Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(Icons.hourglass_bottom, color: Colors.deepOrange),
                                    const SizedBox(width: 2),
                                    Text(
                                      "$_timeLeft ${tr(context).secondsLeft}",
                                      style: const TextStyle(
                                        fontSize: 28,
                                        color: Colors.deepOrange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(width: 40),

                                const Icon(Icons.emoji_events, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '$_player1Score',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.favorite, color: Colors.redAccent),
                                const SizedBox(width: 8),
                                Text(
                                  '$_player1Lives',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Question card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        shadowColor: Colors.deepOrange.withOpacity(0.4),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            question.questionText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Answer options grid
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                            label: Text(
                              question.options[index],
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: bgColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              elevation: 8,
                              shadowColor: Colors.deepOrange.withOpacity(0.5),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          );
                        }),
                      ),
                    ),

                    // Combo text effect
                    if (_comboText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Transform.scale(
                          scale: 1.0 + 0.2 * _comboAnimationController.value,
                          child: Text(
                            _comboText,
                            style: TextStyle(
                              fontSize: (28 + (_comboCount * 2).clamp(0, 20)).toDouble(),
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

        // Correct and wrong answer animations overlay
        if (_showCorrectAnimation)
          Center(
            child: Lottie.asset(
              'assets/animations/QuizzGame_Animation/DoneAnimation.json',
              width: 500,
              repeat: false,
            ),
          ),
        if (_showWrongAnimation)
          Center(
            child: Lottie.asset(
              'assets/animations/QuizzGame_Animation/Fiery Lolo.json',
              width: 200,
              repeat: false,
            ),
          ),
      ],
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color color = Colors.deepOrange,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: color),
        iconSize: 30,
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}
