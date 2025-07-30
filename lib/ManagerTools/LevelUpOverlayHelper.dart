import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool.dart';

class LevelUpOverlayHelper {
  static final MusicPlayer _lvlUp = MusicPlayer();
  static final MusicPlayer _lvlUp2 = MusicPlayer();

  static void showOverlayLevelUpBanner(BuildContext context, int newLevel, {GlobalKey? avatarKey}) {
    final overlay = Overlay.of(context);
    if (overlay == null || !context.mounted) return;

    _lvlUp.play("assets/audios/sound_effects/victory2_SFX.mp3");
    _lvlUp2.play("assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3");

    final AnimationController controller = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 500),
    );

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Builder(
        builder: (ctx) {
          final topPadding = MediaQuery.of(ctx).padding.top + 20;

          return Positioned(
            top: topPadding,
            left: 20,
            right: 20,
            child: SafeArea(
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.2, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack)),
                child: Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepOrange.shade400.withOpacity(0.6),
                              Colors.deepOrange.shade700.withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Lottie.asset(
                              'assets/animations/LvlUnlocked/StarPlus1.json',
                              width: 60,
                              height: 60,
                              repeat: false,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🎉 Level $newLevel Reached!',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 2,
                                        offset: Offset(1, 1),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '+1 ⭐ Star Earned',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Lottie.asset(
                              'assets/animations/LvlUnlocked/StarPlus1.json',
                              width: 40,
                              height: 40,
                              repeat: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    overlay.insert(entry);
    controller.forward();

    if (avatarKey != null) {
      _showAvatarSparkle(context, avatarKey);
    }

    Future.delayed(const Duration(seconds: 4), () {
      entry.remove();
      controller.dispose();
    });
  }

  static void _showAvatarSparkle(BuildContext context, GlobalKey avatarKey) {
    final renderBox = avatarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final sparkleEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: offset.dx + size.width / 2 - 30,
        top: offset.dy - 10,
        child: SizedBox(
          width: 60,
          height: 60,
          child: Lottie.asset(
            'assets/animations/MouthDrop.json',
            repeat: false,
          ),
        ),
      ),
    );

    overlay.insert(sparkleEntry);
    Future.delayed(const Duration(seconds: 2), () => sparkleEntry.remove());
  }
}
