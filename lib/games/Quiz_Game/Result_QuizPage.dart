// result_page.dart (Enhanced Result UI with Effects)

import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool/audio_tool.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import 'ModeSelectorPage.dart';
import 'general_culture_game.dart';

class ResultPage extends StatefulWidget {
  final int player1Score;
  final int player2Score;
  final GameMode mode;
  final QuizLanguage language;

  const ResultPage({
    super.key,
    required this.player1Score,
    required this.player2Score,
    required this.mode,
    required this.language,
  });

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeInAnimation;
  final MusicPlayer _musicPlayer = MusicPlayer();
  final MusicPlayer _PeopleCheering = MusicPlayer();
  final MusicPlayer _Ukulele4sec = MusicPlayer();

  String get winner {
    if (widget.mode == GameMode.single) {
      return "🎉 ${tr(context).greatJob}";
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
       _PeopleCheering.play("assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3",loop: true);
       _Ukulele4sec.play("assets/audios/QuizGame_Sounds/skaWhistleukulele30Sec.mp3", loop: true);
       _musicPlayer.play('assets/audios/sound_effects/victory1.mp3');
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _musicPlayer.dispose();
    _Ukulele4sec.dispose();
    _PeopleCheering.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: Text('🎮 ${tr(context).gameOver}'),
        backgroundColor: Colors.deepOrange,
      ),
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    child: AnimatedTextKit(
                      animatedTexts: [
                        ColorizeAnimatedText(
                          winner,
                          textStyle: const TextStyle(
                            fontSize: 34,
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

                  const SizedBox(height: 20),

                  Lottie.asset(
                    'assets/animations/QuizzGame_Animation/Champion.json',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 10),

                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 6,
                    shadowColor: Colors.deepOrange.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        children: [
                          Text(
                            '${tr(context).player1}: ${widget.player1Score} ${tr(context).points}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                          ),
                          if (widget.mode == GameMode.multiplayer)
                            Text(
                              '${tr(context).player2}: ${widget.player2Score} ${tr(context).points}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizPage(
                          mode: widget.mode,
                          language: widget.language,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: Text('🔁 ${tr(context).playAgain}', style: const TextStyle(fontSize: 20)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
