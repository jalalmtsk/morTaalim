import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';

class LevelUpOverlayHelper {
  static Future<void> showOverlayLevelUpBanner(BuildContext context, int newLevel) async {
    final overlay = Overlay.of(context);
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    if (overlay == null || !context.mounted) return;

    audioManager.playSfx("assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3");
    audioManager.playSfx("assets/audios/UI_Audio/SFX_Audio/VictoryOrchestral_SFX.mp3");

    final completer = Completer<void>();
    late OverlayEntry entry;

    bool showText = false; // controls text visibility

    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        ignoring: true,
        child: StatefulBuilder(
          builder: (context, setState) {
            // Trigger text appearance after 800ms
            Future.delayed(const Duration(milliseconds: 800), () {
              if (context.mounted && !showText) {
                setState(() => showText = true);
              }
            });

            return Stack(
              children: [
                // Centered confetti animation
                Center(
                  child: Lottie.asset(
                    'assets/animations/UI_Animations/Confetti1.json',
                    repeat: false,
                  ),
                ),

                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: SizedBox(
                      width: 250,
                      height: 250,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Original level-up banner animation
                          Lottie.asset(
                            'assets/animations/LvlUnlocked/LvlUpBanner.json',
                            repeat: false,
                          ),

                          // Additional confetti on top of the level-up banner
                          Lottie.asset(
                            'assets/animations/UI_Animations/Confetti2.json',
                            repeat: false,
                          ),

                          // Text fades in after 800ms
                          Positioned(
                            bottom: 85,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 400),
                              opacity: showText ? 1 : 0,
                              child: Text(
                                "${tr(context).level} $newLevel",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                  decoration: TextDecoration.none,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 8,
                                      offset: Offset(2, 2),
                                    ),
                                    Shadow(
                                      color: Colors.orangeAccent,
                                      blurRadius: 20,
                                      offset: Offset(1, 1),
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
                ),
              ],
            );
          },
        ),
      ),
    );

    overlay.insert(entry);

    // Remove after 3.5 seconds and complete the Future
    Future.delayed(const Duration(milliseconds: 4800), () {
      entry.remove();
      completer.complete();
    });

    return completer.future;
  }
}
