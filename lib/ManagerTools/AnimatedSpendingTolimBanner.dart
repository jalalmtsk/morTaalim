import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:provider/provider.dart';

import '../tools/audio_tool/Audio_Manager.dart';

class AnimatedTokenSpentBanner extends StatefulWidget {
  final int tokenAmount;
  final VoidCallback onDismiss;

  const AnimatedTokenSpentBanner({
    required this.tokenAmount,
    required this.onDismiss,
  });

  @override
  State<AnimatedTokenSpentBanner> createState() => _AnimatedTokenSpentBannerState();
}

class _AnimatedTokenSpentBannerState extends State<AnimatedTokenSpentBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playAlert("assets/audios/UI_Audio/SFX_Audio/PurchaseSound.mp3"); // 🔁 Replace if you have a better sound

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
      top: MediaQuery.of(context).padding.top + 100,
      left: 30,
      right: 30,
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
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
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
                        'assets/animations/Spend/medal_spent.json', // 🎯 Customize with a new asset if needed
                        repeat: false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '-${widget.tokenAmount} Tolim${widget.tokenAmount > 1 ? 's' : ''} spent',
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
                            'Transaction complete!',
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
                        'assets/animations/Spend/medal_spent.json',
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
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
