import 'package:flutter/material.dart';
import 'package:mortaalim/games/MemoryFlipGame/SurvivalMode/MainSurvivalModePage.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';

import 'AdventureMode/MFCategorySelector.dart';
// Your Survival mode page

class MFIndexPage extends StatelessWidget {
  const MFIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: ()
        {
          audioManager.playEventSound("cancelButton");
          Navigator.pop(context);
        }, icon: Icon(Icons.arrow_circle_left_sharp,
          size: 50,
          color: Colors.orangeAccent,)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        excludeHeaderSemantics: true,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: true,
        shadowColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF80DEEA), Color(0xFFE1BEE7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Floating shapes for style
          Positioned(
            top: -50,
            left: -50,
            child: _CircleDecoration(100, Colors.white.withOpacity(0.1)),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: _CircleDecoration(150, Colors.white.withOpacity(0.1)),
          ),
          // Main content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tr(context).memoryFlip,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _ModeCard(
                        title: tr(context).adventureMode,
                        description:
                        '${tr(context).playThroughLevelsAndEarn} Tolim & XP!',
                        icon: Icons.explore,
                        colors: [Colors.orange.shade400, Colors.deepOrange.shade300],
                        onTap: () {
                          audioManager.playEventSound("clickButton");
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CategorySelection(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _ModeCard(
                        title: tr(context).survivalMode,
                        description:
                        tr(context).seeHowLongYouCanSurviveWithLimitedMoves,
                        icon: Icons.timer,
                        colors: [Colors.purple.shade400, Colors.deepPurple.shade300],
                        onTap: () {
                          audioManager.playEventSound("clickButton");
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SurvivalMemoryGame(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------- Mode Card -----------------
class _ModeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ----------------- Decorative Circle -----------------
class _CircleDecoration extends StatelessWidget {
  final double size;
  final Color color;

  const _CircleDecoration(this.size, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
