import 'package:flutter/material.dart';
import 'package:mortaalim/profileSetupPage.dart';
import 'package:provider/provider.dart';
import '../XpSystem.dart'; // adjust this import path

class Userstatutbar extends StatefulWidget {
  const Userstatutbar({super.key});

  @override
  State<Userstatutbar> createState() => _UserStatutBar();
}

class _UserStatutBar extends State<Userstatutbar> with TickerProviderStateMixin {
  late AnimationController _starController;
  late AnimationController _xpController;
  late AnimationController _avatarController;

  late AnimationController _tokenFlashController;
  late AnimationController _starFlashController;
  late Animation<Color?> _tokenColorAnimation;
  late Animation<Color?> _starColorAnimation;

  late AnimationController _tokenScaleController;
  late AnimationController _starScaleController;

  @override
  void initState() {
    super.initState();

    _starController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _xpController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _avatarController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
      lowerBound: 0.8,
      upperBound: 1.1,
    )..repeat(reverse: true);

    _tokenFlashController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _starFlashController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    _tokenColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.greenAccent.withOpacity(0.5),
    ).animate(CurvedAnimation(parent: _tokenFlashController, curve: Curves.easeInOut));

    _starColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.yellowAccent.withOpacity(0.5),
    ).animate(CurvedAnimation(parent: _starFlashController, curve: Curves.easeInOut));

    _tokenScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 1.0,
      upperBound: 1.3,
    );

    _starScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 1.0,
      upperBound: 1.3,
    );
  }

  @override
  void dispose() {
    _starController.dispose();
    _xpController.dispose();
    _avatarController.dispose();
    _tokenFlashController.dispose();
    _starFlashController.dispose();
    _tokenScaleController.dispose();
    _starScaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);

    // XP Animation trigger
    _xpController.forward(from: 0.0);

    // Animate on token gain
    if (xpManager.recentlyAddedTokens > 0 && !_tokenFlashController.isAnimating) {
      _tokenFlashController.forward(from: 0.0);
      _tokenScaleController.forward(from: 0.0);
    }

    // Animate on star gain
    if (xpManager.recentlyAddedStars > 0 && !_starFlashController.isAnimating) {
      _starFlashController.forward(from: 0.0);
      _starScaleController.forward(from: 0.0);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(1, 2)),
        ],
        border: Border.all(color: Colors.indigo.shade200.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          // Avatar
          ScaleTransition(
            scale: _avatarController,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.blue.shade100.withOpacity(0.6),
              child: Text(xpManager.selectedAvatar, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 10),

          // XP
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Level ${xpManager.level}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 3),
                AnimatedBuilder(
                  animation: _xpController,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: xpManager.levelProgress,
                      backgroundColor: Colors.grey.shade300.withOpacity(0.4),
                      color: Colors.blueAccent.withOpacity(0.8),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Stars + Tokens
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Star block
              AnimatedBuilder(
                animation: _starColorAnimation,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: _starColorAnimation.value,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ScaleTransition(
                      scale: _starScaleController,
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber.withOpacity(0.8), size: 24),
                          const SizedBox(width: 2),
                          Text("${xpManager.stars}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ProfileSetupPage()));
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber.shade600,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.shade300.withOpacity(0.7),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, size: 14, color: Colors.black),
                ),
              ),

              const SizedBox(width: 12),

              // Tokens block
              AnimatedBuilder(
                animation: _tokenColorAnimation,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: _tokenColorAnimation.value,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ScaleTransition(
                      scale: _tokenScaleController,
                      child: Row(
                        children: [
                          Icon(Icons.generating_tokens_rounded,
                              color: Colors.green.withOpacity(0.85), size: 24),
                          const SizedBox(width: 4),
                          Text(
                            "${xpManager.saveTokens}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
