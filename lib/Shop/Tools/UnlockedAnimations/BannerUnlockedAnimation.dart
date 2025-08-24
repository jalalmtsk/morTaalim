import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:mortaalim/main.dart';
import 'package:provider/provider.dart';

import '../../../XpSystem.dart';
import '../../../tools/audio_tool/Audio_Manager.dart';

class BannerUnlockedDialog extends StatefulWidget {
  final String bannerImage;
  final int xpReward;

  const BannerUnlockedDialog({required this.bannerImage, this.xpReward = 25, super.key});

  @override
  State<BannerUnlockedDialog> createState() => _BannerUnlockedDialogState();
}

class _BannerUnlockedDialogState extends State<BannerUnlockedDialog>
    with TickerProviderStateMixin {
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
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
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
                  BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10))
                ],
              ),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "🎉 Banner Unlocked!",
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                    const SizedBox(height: 16),
                    // Banner + Lottie stack
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Lottie behind
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: Lottie.asset(
                            "assets/animations/UI_Animations/BackgroundEffectStarAnimation.json",
                            repeat: true,
                          ),
                        ),
                        // Banner image
                        Container(
                          width: 260,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.amber, width: 4),
                            image: DecorationImage(
                              image: AssetImage(widget.bannerImage),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final xpManager =
                        Provider.of<ExperienceManager>(context, listen: false);
                        xpManager.addXP(widget.xpReward, context: context);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrangeAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child:  Text(
                        "${tr(context).awesome}!",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
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
