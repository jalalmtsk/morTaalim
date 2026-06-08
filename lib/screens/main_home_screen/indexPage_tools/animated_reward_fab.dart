// animated_reward_fab.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:mortaalim/tools/Ads_Manager.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/XpSystem.dart';

class AnimatedRewardFAB extends StatefulWidget {
  const AnimatedRewardFAB({super.key});

  @override
  State<AnimatedRewardFAB> createState() => _AnimatedRewardFABState();
}

class _AnimatedRewardFABState extends State<AnimatedRewardFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    return ScaleTransition(
      scale: _pulseAnimation,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main FAB Button
          GestureDetector(
            onTap: () {
              audioManager.playEventSound('clickButton');
              AdHelper.showRewardedAdWithLoading(context, () {
                Provider.of<ExperienceManager>(context, listen: false)
                    .addTokenBanner(context, 2);
              });
            },
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.55),
                    blurRadius: 14,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Lottie.asset(
                  'assets/animations/UI_Animations/Ads2Gift.json', // 🔁 replace with your Lottie file
                  fit: BoxFit.cover,
                  repeat: true,
                ),
              ),
            ),
          ),

          // "+2 Tolims" badge — top-left
          Positioned(
            top: -10,
            left: -14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853), // vivid green
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.45),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.generating_tokens_rounded,
                      color: Colors.white, size: 12),
                  SizedBox(width: 3),
                  Text(
                    '+2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}