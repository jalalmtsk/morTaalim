import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../main.dart';
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
      return "🎉 ${tr(context).greatJob} ";
    } else {
      if (widget.player1Score > widget.player2Score) {
        return "🏆 ${tr(context).player1Wins}";
      } else if (widget.player2Score > widget.player1Score) {
        return "🏆 ${tr(context).player2Wins}";
      } else {
        return "🤝 ${tr(context).itsATie}";
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
      await _musicPlayer.play('assets/audios/sound_effects/victory1.mp3');
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:  Text('🎮 ${tr(context).gameOver}'),
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

              Lottie.asset(
                'assets/animations/menWining.json',
                width: 350,
                height: 350,
                fit: BoxFit.contain,
              ),

              Text('${tr(context).player1}: ${widget.player1Score} ${tr(context).points}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
              if (widget.mode == GameMode.multiplayer)
                Text('${tr(context).player2}: ${widget.player2Score} ${tr(context).points}',
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
                child: Text('🔁 ${tr(context).playAgain}', style: TextStyle(color: Colors.white, fontSize: 20)),

              ),
            ],
          ),
        ),
      ),
    );
  }
}
