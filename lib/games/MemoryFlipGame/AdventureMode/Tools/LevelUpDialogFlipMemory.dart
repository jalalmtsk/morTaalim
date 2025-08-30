import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'dart:math';

import 'package:provider/provider.dart';

class LevelUpDialogFlipMemory extends StatefulWidget {
  final int nextLevel;
  final VoidCallback onContinue;

  const LevelUpDialogFlipMemory({
    super.key,
    required this.nextLevel,
    required this.onContinue,
  });

  @override
  State<LevelUpDialogFlipMemory> createState() =>
      _LevelUpDialogFlipMemoryState();
}

class _LevelUpDialogFlipMemoryState extends State<LevelUpDialogFlipMemory> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();
    playSound();
  }
  void playSound(){
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playSfx("assets/audios/UI_Audio/SFX_Audio/PowerUp_SFX.mp3");
    audioManager.playSfx("assets/audios/UI_Audio/SFX_Audio/VictoryOrchestral_SFX.mp3");
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Flying star/confetti behind (your existing ConfettiWidget)
          Positioned.fill(
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.purple,
                Colors.blue,
                Colors.pink,
                Colors.yellow,
                Colors.orange
              ],
              createParticlePath: drawStar, // Custom star shape
              gravity: 0.3,
            ),
          ),

          // Main dialog card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Level Up!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You reached level ${widget.nextLevel}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.deepPurple.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                Lottie.asset(
                  'assets/animations/UI_Animations/Gong.json',
                  width: 300,
                  height: 150,
                  repeat: false,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: widget.onContinue,
                  child: Text(
                    tr(context).awesome,
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Confetti Lottie in front of the dialog
          Positioned(
            child: Lottie.asset(
              'assets/animations/UI_Animations/Confetti1.json',
              width: 350,
              height: 200,
              repeat: true,
            ),
          ),
        ],
      ),
    );
  }

  /// Draws a custom star shape for confetti
  Path drawStar(Size size) {
    final Path path = Path();
    const int points = 5;
    final double outerRadius = size.width / 2;
    final double innerRadius = outerRadius / 2.5;
    final double angle = (2 * pi) / points;

    for (int i = 0; i <= points; i++) {
      final double xOuter =
          outerRadius + outerRadius * cos(i * angle - pi / 2);
      final double yOuter =
          outerRadius + outerRadius * sin(i * angle - pi / 2);
      if (i == 0) {
        path.moveTo(xOuter, yOuter);
      } else {
        path.lineTo(xOuter, yOuter);
      }

      final double xInner = outerRadius +
          innerRadius * cos(i * angle + angle / 2 - pi / 2);
      final double yInner = outerRadius +
          innerRadius * sin(i * angle + angle / 2 - pi / 2);
      path.lineTo(xInner, yInner);
    }
    path.close();
    return path;
  }
}
