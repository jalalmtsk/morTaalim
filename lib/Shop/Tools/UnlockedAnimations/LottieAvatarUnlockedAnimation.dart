import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:mortaalim/main.dart';
import 'package:provider/provider.dart';
import '../../../XpSystem.dart';
import '../../../tools/audio_tool/Audio_Manager.dart';

class LottieAvatarUnlockedDialog extends StatefulWidget {
  final String lottiePath;
  final int xpReward;

  const LottieAvatarUnlockedDialog({required this.lottiePath, this.xpReward = 500, super.key});

  @override
  State<LottieAvatarUnlockedDialog> createState() => _LottieAvatarUnlockedDialogState();
}

class _LottieAvatarUnlockedDialogState extends State<LottieAvatarUnlockedDialog> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();

    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnimation = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
    _scaleController.forward();

    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playSfx("assets/audios/UI_Audio/SFX_Audio/victory1_SFX.mp3");
    audioManager.playSfx("assets/audios/UI_Audio/SFX_Audio/MarimbaWin_SFX.mp3");
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "🎉 Lottie Avatar Unlocked!",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                    const SizedBox(height: 16),
                    // Lottie avatar
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background Lottie effect
                          Lottie.asset(
                            "assets/animations/UI_Animations/BackgroundEffectStarAnimation.json",
                            repeat: true,
                          ),
                          // Avatar Lottie itself
                          Lottie.asset(widget.lottiePath, repeat: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final xpManager = Provider.of<ExperienceManager>(context, listen: false);
                        xpManager.addXP(widget.xpReward, context: context);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrangeAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text("${tr(context).awesome}!", style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.3,
          ),
        ],
      ),
    );
  }
}
