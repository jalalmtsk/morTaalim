import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/main.dart';
import 'package:provider/provider.dart';

import '../tools/audio_tool/Audio_Manager.dart';

class AnimatedXPBanner extends StatefulWidget {
  final int xpAmount;
  final VoidCallback onDismiss;

  const AnimatedXPBanner({
    required this.xpAmount,
    required this.onDismiss,
    Key? key,
  }) : super(key: key);

  @override
  State<AnimatedXPBanner> createState() => _AnimatedXPBannerState();

  /// ==============================
  /// Static helper method to show XP banner as a Future
  /// ==============================
  static Future<void> show(BuildContext context, int xpAmount) async {
    final overlay = Overlay.of(context);
    if (overlay == null || !context.mounted) return;

    final completer = Completer<void>();
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => AnimatedXPBanner(
        xpAmount: xpAmount,
        onDismiss: () {
          entry.remove();
          completer.complete();
        },
      ),
    );

    overlay.insert(entry);
    return completer.future; // completes when banner disappears
  }
}

class _AnimatedXPBannerState extends State<AnimatedXPBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playAlert("assets/audios/sound_effects/correct_anwser.mp3");
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _controller.forward();

    // Auto-dismiss after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _controller.reverse().then((_) => widget.onDismiss());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 30,
      right: 30,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _controller.value,
              child: Transform.scale(
                scale: 0.75 + (_controller.value * 0.05),
                child: child,
              ),
            );
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.white30),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Lottie.asset(
                          'assets/animations/UIBannerAnimations/XP.json',
                          repeat: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '+${widget.xpAmount} XP ${tr(context).gained}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 2,
                                    color: Colors.black45,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                             Text(tr(context).wellDone,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Lottie.asset(
                          'assets/animations/UIBannerAnimations/XP.json',
                          repeat: false,
                        ),
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
