import 'package:mortaalim/widgets/KidScene/kid_toast.dart';
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

    // Confetti burst behind the new LEVEL UP banner.
    final confetti = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: Center(child: Lottie.asset('assets/animations/UI_Animations/Confetti1.json', repeat: false)),
      ),
    );
    overlay.insert(confetti);
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (confetti.mounted) confetti.remove();
    });
    await KidToast.show(KidToastKind.levelUp, level: newLevel);

  }
}
