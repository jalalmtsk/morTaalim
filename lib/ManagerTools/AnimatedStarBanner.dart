import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:provider/provider.dart';

import '../tools/audio_tool/Audio_Manager.dart';

class AnimatedStarBanner extends StatefulWidget {
  final int starAmount;
  final VoidCallback onDismiss;

  const AnimatedStarBanner({
    required this.starAmount,
    required this.onDismiss,
  });

  @override
  State<AnimatedStarBanner> createState() => _AnimatedStarBannerState();
}

class _AnimatedStarBannerState extends State<AnimatedStarBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override

  @override
  void initState() {
    super.initState();

    // 🎵 Play sound
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playAlert('assets/audios/UI_Audio/SFX_Audio/StarSound.mp3');

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
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
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Lottie.asset(
                          'assets/animations/UIBannerAnimations/AddStar.json',
                          repeat: false,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '+${widget.starAmount} Star${widget.starAmount > 1 ? 's' : ''} earned!',
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
                            const Text(
                              'Keep Shining!',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Lottie.asset(
                          'assets/animations/UIBannerAnimations/AddStar.json',
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
