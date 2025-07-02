import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:mortaalim/tools/audio_tool.dart';

import 'general_culture_game.dart';

class ResultPage extends StatefulWidget {
  final int player1Score;
  final int player2Score;
  final GameMode mode;

  const ResultPage({
    super.key,
    required this.player1Score,
    required this.player2Score,
    required this.mode,
  });

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeInAnimation;
  final MusicPlayer _musicPlayer = MusicPlayer();

  String get winner {
    if (widget.mode == GameMode.single) {
      return "🎉 Great Job!";
    } else {
      if (widget.player1Score > widget.player2Score) {
        return "🏆 Player 1 Wins!";
      } else if (widget.player2Score > widget.player1Score) {
        return "🏆 Player 2 Wins!";
      } else {
        return "🤝 It's a Tie!";
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    _playVictorySound();
  }

  Future<void> _playVictorySound() async {
    try {
      // You can use your own local asset or URL here
      // For example, add a 'victory.mp3' file in assets/sounds and declare in pubspec.yaml
      await _musicPlayer.play('assets/audios/victory1.mp3');
    } catch (e) {
      // Handle error or fallback
      debugPrint('Error playing sound: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _musicPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text('🎮 Game Over!'),
        backgroundColor: Colors.deepOrange,
      ),
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated celebration text
              SizedBox(
                width: 250,
                child: AnimatedTextKit(
                  animatedTexts: [
                    ColorizeAnimatedText(
                      winner,
                      textStyle: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      colors: [
                        Colors.deepOrange,
                        Colors.orange,
                        Colors.redAccent,
                        Colors.deepOrangeAccent,
                      ],
                    ),
                  ],
                  isRepeatingAnimation: false,
                ),
              ),
              const SizedBox(height: 30),

              Text('Player 1: ${widget.player1Score}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
              if (widget.mode == GameMode.multiplayer)
                Text('Player 2: ${widget.player2Score}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),

              const SizedBox(height: 40),

              // Button with scale animation on press
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => QuizPage(mode: widget.mode)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('🔁 Play Again', style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
