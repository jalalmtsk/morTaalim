import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:mortaalim/main.dart';
import 'package:provider/provider.dart';
import '../../../XpSystem.dart';
import '../../../tools/audio_tool/Audio_Manager.dart';

class AvatarUnlockedDialog extends StatefulWidget {
  final String avatarImage;
  final int xpReward;

  const AvatarUnlockedDialog({required this.avatarImage, this.xpReward = 20, super.key});

  @override
  State<AvatarUnlockedDialog> createState() => _AvatarUnlockedDialogState();
}

class _AvatarUnlockedDialogState extends State<AvatarUnlockedDialog> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Confetti
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();

    // Scale animation
    _scaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnimation = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
    _scaleController.forward();

    // Play sounds
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
          // Blurred background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "🎉 Avatar Unlocked!",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                    const SizedBox(height: 16),
                    // Avatar image with Lottie behind
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Lottie animation behind
                        SizedBox(
                          width: 300,
                          height: 300,
                          child: Lottie.asset(
                            "assets/animations/UI_Animations/BackgroundEffectStarAnimation.json",
                            repeat: true,
                          ),
                        ),
                        // Avatar image in front
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.amber, width: 4),
                            image: DecorationImage(
                              image: AssetImage(widget.avatarImage),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Reward XP
                        final xpManager = Provider.of<ExperienceManager>(context, listen: false);
                        xpManager.addXP(widget.xpReward, context: context);
                        audioManager.playEventSound("cancelButton");
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
          // Confetti
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
