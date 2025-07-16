import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool.dart';

class LevelUpOverlayHelper {
  static final MusicPlayer _lvlUp = MusicPlayer();
  static final MusicPlayer _lvlUp2 = MusicPlayer();

  static void showOverlayLevelUpBanner(BuildContext context, int newLevel, {GlobalKey? avatarKey}) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _lvlUp.play("assets/audios/sound_effects/victory2.mp3");
    _lvlUp2.play("assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3");

    final AnimationController controller = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 400),
    );

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.5, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack)),
            child: Container(
              width: 280,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade600,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 🌟 Lottie Animation
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Lottie.asset(
                      'assets/animations/LvlUnlocked/StarPlus1.json',
                      repeat: false,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level $newLevel!',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '+1 ⭐ Star',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    controller.forward();

    // Optional avatar sparkle
    if (avatarKey != null) {
      _showAvatarSparkle(context, avatarKey);
    }

    // Auto-remove
    Future.delayed(const Duration(seconds: 4), () {
      entry.remove();
      controller.dispose();
    });
  }

  static void _showAvatarSparkle(BuildContext context, GlobalKey avatarKey) {
    final RenderBox? renderBox = avatarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset avatarOffset = renderBox.localToGlobal(Offset.zero);
    final Size avatarSize = renderBox.size;

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final OverlayEntry sparkleEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: avatarOffset.dx + avatarSize.width / 2 - 30,
        top: avatarOffset.dy - 10,
        child: SizedBox(
          width: 60,
          height: 60,
          child: Lottie.asset(
            'assets/animations/sparkle.json', // You can use any sparkle animation
            repeat: false,
          ),
        ),
      ),
    );

    overlay.insert(sparkleEntry);
    Future.delayed(const Duration(seconds: 2), () => sparkleEntry.remove());
  }
}
