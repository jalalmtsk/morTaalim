import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mortaalim/games/Quiz_Game/Result_QuizPage.dart' hide QuizLanguage;
import 'package:mortaalim/tools/audio_tool/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

import '../../XpSystem.dart';
import 'Questions.dart';
import 'question_model.dart';
import 'avatar_widget.dart';
import 'ModeSelectorPage.dart';

enum GameMode { single, multiplayer }

class QuizGameApp extends StatelessWidget {
  const QuizGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModeSelectorPage();
  }
}

// quiz_page.dart (Enhanced UI Version with Return, Progress, Score, Lives)


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

  late List<Question> _questions;
  int _currentQuestion = 0;
  int _player1Score = 0;
  int _player2Score = 0;
  int _playerTurn = 1;
  int _player1Lives = 2;
  int _player2Lives = 2;
  int _timeLeft = 10;
  int? _selectedIndex;
  bool _answered = false;
  bool _showCorrectAnimation = false;
  bool _showWrongAnimation = false;
  bool _showIntro = true;
  late Timer _timer;

  late AnimationController _introController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _backgroundMusic.play("assets/audios/sound_track/piano.mp3");
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

  List<Question> _loadQuestions(QuizLanguage lang) => questionsByLanguage[lang] ?? [];

  void _startTimer() {
    _timeLeft = 10;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
        if (_timeLeft == 0) _handleTimeout();
      });
    });
  }

  void _handleTimeout() {
    _timer.cancel();
    _playSound('assets/audios/wrong_answer.mp3');
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
        Provider.of<ExperienceManager>(context, listen: false).addXP(2);
        _playSound('assets/audios/sound_effects/correct_anwser.mp3');
        _showCorrectAnimation = true;
        Future.delayed(const Duration(seconds: 1), () => setState(() => _showCorrectAnimation = false));
      } else {
        _playSound('assets/audios/sound_effects/wrong_answer.mp3');
        _showWrongFeedback();
        if (widget.mode == GameMode.single) {
          _player1Lives--;
        } else {
          (widget.mode == GameMode.multiplayer && _playerTurn == 1)
              ? _player1Lives--
              : _player2Lives--;
        }
      }
    });
    Future.delayed(const Duration(seconds: 2), _nextTurn);
  }

  void _showWrongFeedback() {
    setState(() => _showWrongAnimation = true);
    Future.delayed(const Duration(seconds: 1), () => setState(() => _showWrongAnimation = false));
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

  @override
  void dispose() {
    _timer.cancel();
    _backgroundMusic.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final question = _questions[_currentQuestion];

    return Stack(
      children: [
        if (_showIntro)
          FadeTransition(
            opacity: _scaleAnimation,
            child: Scaffold(
              backgroundColor: Colors.deepOrange,
              body: Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.player1Name ?? "Player", style: const TextStyle(fontSize: 32, color: Colors.white)),
                      const SizedBox(height: 16),
                      Text(widget.player1Emoji ?? "😀", style: const TextStyle(fontSize: 50)),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                        child: const Text("Steady... Ready... GO!",
                            style: TextStyle(fontSize: 24, color: Colors.deepOrange)),
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                "Question ${_currentQuestion + 1} of ${_questions.length}",
                style: const TextStyle(color: Colors.deepOrange),
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Userstatutbar(),
                  LinearProgressIndicator(
                    value: _timeLeft / 10,
                    color: Colors.deepOrange,
                    backgroundColor: Colors.orange.shade100,
                  ),
                  const SizedBox(height: 8),
                  Text("⏳ $_timeLeft seconds", style: const TextStyle(fontSize: 18)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text("❤️ Lives: $_player1Lives", style: const TextStyle(fontSize: 18)),
                        Text("⭐ Score: $_player1Score", style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      question.questionText,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(12),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 3,
                      children: List.generate(question.options.length, (index) {
                        Color color = Colors.white;
                        if (_answered) {
                          if (index == question.correctIndex) {
                            color = Colors.green.shade300;
                          } else if (index == _selectedIndex) {
                            color = Colors.red.shade300;
                          }
                        }
                        return ElevatedButton(
                          onPressed: () => _answerQuestion(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          child: Text(question.options[index], style: const TextStyle(fontSize: 18)),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_showCorrectAnimation)
          Center(
            child: Lottie.asset('assets/animations/confetti_success.json', width: 200, repeat: false),
          ),
        if (_showWrongAnimation)
          Center(
            child: Lottie.asset('assets/animations/wrong_cross.json', width: 150, repeat: false),
          ),
      ],
    );
  }
}
