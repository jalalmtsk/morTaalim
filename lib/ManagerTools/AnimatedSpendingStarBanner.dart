import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool.dart';

class AnimatedStarSpentBanner extends StatefulWidget {
  final int starAmount;
  final VoidCallback onDismiss;

  const AnimatedStarSpentBanner({
    required this.starAmount,
    required this.onDismiss,
  });

  @override
  State<AnimatedStarSpentBanner> createState() => _AnimatedStarSpentBannerState();
}

class _AnimatedStarSpentBannerState extends State<AnimatedStarSpentBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final MusicPlayer _audioPlayer = MusicPlayer();

  @override
  void initState() {
    super.initState();

    // 💸 Optional: play a "spending" sound
    _audioPlayer.play('assets/audios/sound_effects/cash-register.mp3'); // Replace with your asset

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
                color: Colors.redAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
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
                          'assets/animations/unlock_key.json', // Replace with your animation
                          repeat: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '-${widget.starAmount} Star${widget.starAmount > 1 ? 's' : ''} spent',
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
                              'Thanks for your purchase!',
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
                          'assets/animations/unlock_key.json',
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
