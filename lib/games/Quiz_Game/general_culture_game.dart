import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mortaalim/games/Quiz_Game/Result_QuizPage.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:provider/provider.dart';
import '../../XpSystem.dart';
import 'question_model.dart';
import 'avatar_widget.dart';
import 'ModeSelectorPage.dart';

enum GameMode { single, multiplayer }

class QuizGameApp extends StatelessWidget {
  const QuizGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModeSelectorPage();  // no MaterialApp here
  }
}

class QuizPage extends StatefulWidget {
  final GameMode mode;
  final String? player1Name;
  final String? player2Name;
  final String? player1Emoji;
  final String? player2Emoji;

  const QuizPage({
    super.key,
    required this.mode,
    this.player1Name,
    this.player2Name,
    this.player1Emoji,
    this.player2Emoji,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final MusicPlayer _player = MusicPlayer();
  final MusicPlayer _backgroundMusic = MusicPlayer();

  final List<Question> _originalQuestions = [

    Question('🌤️ What color is the sky?', ['Blue', 'Green', 'Red', 'Yellow'], 0),
    Question('🕷️ How many legs does a spider have?', ['6', '8', '10', '4'], 1),
    Question('🐶 Which animal barks?', ['Cat', 'Cow', 'Dog', 'Bird'], 2),
    Question('🧮 What is 2 + 2?', ['3', '4', '5'], 1),
    Question('🍌 Which one is a fruit?', ['Carrot', 'Banana', 'Potato', 'Onion'], 1),
    Question('🐶 Which one is an animal?', ['Car', 'Dog', 'Table', 'Chair'], 1),
    Question('🌈 What color is the sky?', ['Green', 'Blue', 'Red', 'Yellow'], 1),
    Question('🚗 Which one can fly?', ['Car', 'Boat', 'Airplane', 'Bike'], 2),
    Question('🍎 Which one is red?', ['Banana', 'Apple', 'Grape', 'Orange'], 1),
    Question('🌻 Which one is a flower?', ['Rose', 'Tree', 'Grass', 'Rock'], 0),
    Question('🐸 Which one lives in water?', ['Dog', 'Frog', 'Cat', 'Horse'], 1),
    Question('🍪 Which one is a sweet treat?', ['Bread', 'Cookie', 'Rice', 'Potato'], 1),
    Question('🎵 Which one is a musical instrument?', ['Piano', 'Book', 'Chair', 'Pen'], 0),
    Question('⚽ What do you use to play soccer?', ['Ball', 'Bat', 'Glove', 'Racket'], 0),
    Question('🌟 Which one shines in the night sky?', ['Moon', 'Sun', 'Cloud', 'Tree'], 0),

  ];

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
  late Timer _timer;

  String get player1Avatar => widget.player1Emoji ?? '😀';
  String get player2Avatar => widget.player2Emoji ?? '😎';
  String get player1Name => widget.player1Name ?? 'Player 1';
  String get player2Name => widget.player2Name ?? 'Player 2';

  @override
  void initState() {
    super.initState();
    _backgroundMusic.play("assets/audios/sound_track/piano.mp3");
    _questions = [..._originalQuestions]..shuffle();
    _startTimer();
  }

  void _startTimer() {
    _timeLeft = 10;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
        if (_timeLeft == 0) {
          _handleTimeout();
        }
      });
    });
  }

  void _handleTimeout() {
    _timer.cancel();
    _playSound('assets/audios/wrong_answer.mp3');

    if (widget.mode == GameMode.single) {
      _player1Lives--;
    } else {
      if (_playerTurn == 1) {
        _player1Lives--;
      } else {
        _player2Lives--;
      }
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
        final xpManager = Provider.of<ExperienceManager>(context, listen: false);
        xpManager.addXP(3);   // 🎮 Give 3 XP
        xpManager.addStars(1); // ⭐ Give 1 Star

        if (widget.mode == GameMode.single) {
          _player1Score++;
        } else {
          if (_playerTurn == 1) {
            _player1Score++;
          } else {
            _player2Score++;
          }
        }

        _playSound('assets/audios/sound_effects/correct_anwser.mp3');
      } else {
        if (widget.mode == GameMode.single) {
          _player1Lives--;
        } else {
          if (_playerTurn == 1) {
            _player1Lives--;
          } else {
            _player2Lives--;
          }
        }
        _playSound('assets/audios/sound_effects/wrong_answer.mp3');
      }
    });

    Future.delayed(const Duration(seconds: 2), _nextTurn);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final xp = xpManager.xp;
    final level = xpManager.level;
    final stars = xpManager.stars;

    if (_currentQuestion >= _questions.length) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = _questions[_currentQuestion];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.orange.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [

                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '⏳ $_timeLeft s | XP: $xp',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 30),

                if (widget.mode == GameMode.multiplayer)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          avatarWithHighlight(player1Avatar, _playerTurn == 1),
                          const SizedBox(height: 6),
                          Text(player1Name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _playerTurn == 1 ? Colors.deepOrange : Colors.grey[700],
                              )),
                          Text('🧰: $_player1Score',style: TextStyle(fontSize: 20)),
                          Text('❤️: $_player1Lives',style: TextStyle(fontSize: 20)),
                        ],
                      ),
                      Column(
                        children: [
                          avatarWithHighlight(player2Avatar, _playerTurn == 2),
                          const SizedBox(height: 6),
                          Text(player2Name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _playerTurn == 2 ? Colors.deepOrange : Colors.grey[700],
                              )),
                          Text('🧰: $_player2Score', style: TextStyle(fontSize: 20),),
                          Text('❤️: $_player2Lives',style: TextStyle(fontSize: 20)),
                        ],
                      ),

                    ],
                  )
                else
                  Text(
                    '🧰: $_player1Score | ⭐ $stars | ❤️: $_player1Lives | XP: $xp',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                const SizedBox(height: 30),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  shadowColor: Colors.deepOrange.withOpacity(0.5),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      question.questionText,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3,
                    physics: const NeverScrollableScrollPhysics(),
                    children: List.generate(question.options.length, (index) {
                      final option = question.options[index];
                      Color buttonColor = Colors.white;
                      Icon? icon;

                      if (_answered) {
                        if (index == question.correctIndex) {
                          buttonColor = Colors.green.shade300;
                          icon = const Icon(Icons.check, color: Colors.white);
                        } else if (index == _selectedIndex) {
                          buttonColor = Colors.red.shade300;
                          icon = const Icon(Icons.close, color: Colors.white);
                        }
                      }

                      return ElevatedButton.icon(
                        onPressed: () => _answerQuestion(index),
                        icon: icon ?? const SizedBox.shrink(),
                        label: Text(option, style: const TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 6,
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
      ),
    );
  }
}
