import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'XpSystem.dart';

class TokenGainOverlay extends StatelessWidget {
  const TokenGainOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: Consumer<ExperienceManager>(
        builder: (context, xp, child) {
          if (xp.recentlyAddedTokens == 0) return const SizedBox.shrink();
          return Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 1.2),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${xp.recentlyAddedTokens} 🪙',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
