import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../XpSystem.dart';

class Userstatutbar extends StatefulWidget {
  const Userstatutbar({super.key});

  @override
  State<Userstatutbar> createState() => _UserStatutBar();
}

class _UserStatutBar extends State<Userstatutbar>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _tokenFlashController;
  late Animation<Color?> _tokenColorAnimation;
  late AnimationController _tokenScaleController;

  late AnimationController _starFlashController;
  late Animation<Color?> _starColorAnimation;
  late AnimationController _starScaleController;

  final AudioPlayer _rewardSound = AudioPlayer();

  bool showAvatarXp = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAnimationControllers();
  }

  void _initAnimationControllers() {
    _tokenFlashController =
        AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _tokenColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.greenAccent.withValues(alpha: 0.5),
    ).animate(CurvedAnimation(parent: _tokenFlashController, curve: Curves.easeInOut));

    _tokenScaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400), lowerBound: 1.0, upperBound: 1.3);

    _starFlashController =
        AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _starColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.yellowAccent.withValues(alpha: 0.5),
    ).animate(CurvedAnimation(parent: _starFlashController, curve: Curves.easeInOut));

    _starScaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400), lowerBound: 1.0, upperBound: 1.3);
  }


  Widget _buildAvatar(String avatarPath, bool showSparkle) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipOval(
          child: avatarPath.endsWith('.json')
              ? Lottie.asset(avatarPath, fit: BoxFit.cover, repeat: true, width: 40, height: 40)
              : (avatarPath.contains('assets/')
              ? Image.asset(avatarPath, width: 40, height: 40, fit: BoxFit.cover)
              : Text(avatarPath, style: const TextStyle(fontSize: 22))),
        ),
        if (showSparkle)
          Positioned(
            top: -10,
            right: -3,
            child: SizedBox(
              width: 30,
              height: 30,
              child: Lottie.asset('assets/animations/AnimatedAvatars/Trophy.json', repeat: false),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tokenFlashController.dispose();
    _tokenScaleController.dispose();
    _starFlashController.dispose();
    _starScaleController.dispose();
    _rewardSound.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final showSparkle = xpManager.recentlyAddedStars > 0 || xpManager.recentlyAddedTokens > 0;

    Color borderColor;
    if (xpManager.recentlyAddedStars > 0 && xpManager.recentlyAddedTokens > 0) {
      borderColor = Colors.deepOrange;
    } else if (xpManager.recentlyAddedStars > 0) {
      borderColor = Colors.yellow;
    } else if (xpManager.recentlyAddedTokens > 0) {
      borderColor = Colors.green;
    } else {
      borderColor = Colors.transparent;
    }

    return GestureDetector(
      onLongPress: () {
        final xpManager = Provider.of<ExperienceManager>(context, listen: false);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Your Progress"),
            content: Text(
              "🎯 Level: ${xpManager.level}\n"
                  "⚡ XP: ${xpManager.xp}\n"
                  "📈 Progress: ${((xpManager.levelProgress) * 100).toStringAsFixed(1)}%",
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
            ],
          ),
        );
      },
      onTap: () => setState(() => showAvatarXp = !showAvatarXp),
      child: Container(
        margin: const EdgeInsets.all(10),
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: 5,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                xpManager.selectedBannerImage,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withValues(alpha: 0.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
              child: showAvatarXp
                  ? Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    radius: 20,
                    child: _buildAvatar(xpManager.selectedAvatar, showSparkle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Level ${xpManager.level}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                      color: Colors.black87,
                                      offset: Offset(1, 1),
                                      blurRadius: 3)
                                ],
                              ),
                            ),
                            Text(
                              "${xpManager.currentLevelXP} / ${xpManager.requiredXPForNextLevel} XP",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                      color: Colors.black,
                                      offset: Offset(1, 1),
                                      blurRadius: 5)
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.3),
                                blurRadius: 6,
                                spreadRadius: showSparkle ? 2 : 0,
                              )
                            ],
                          ),
                          child: LinearProgressIndicator(
                            value: xpManager.levelProgress,
                            backgroundColor: Colors.white24,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          Text(" ${xpManager.stars}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.white)),

                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.generating_tokens,
                              color: Colors.green, size: 20),
                          Text(" ${xpManager.saveTokenCount}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),

                    ],
                  )
                ],
              )
                  : Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white10,
                      child: _buildAvatar(xpManager.selectedAvatar, showSparkle),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "${xpManager.xp} XP",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 3)],
                      ),
                    ),
                  ],
                ),
              )


            )
          ],
        ),
      ),
    );
  }
}
