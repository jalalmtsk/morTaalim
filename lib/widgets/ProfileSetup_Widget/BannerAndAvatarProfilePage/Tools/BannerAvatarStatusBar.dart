import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import '../../../../XpSystem.dart';
import 'package:provider/provider.dart';

class BannerAvatarStatusBar extends StatelessWidget {
  const BannerAvatarStatusBar({Key? key}) : super(key: key);

  /// Fallback avatar (initials if no image/Lottie is chosen)
  Widget _buildSimpleAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : "?";
    return CircleAvatar(
      radius: 35,
      backgroundColor: Colors.deepOrange.shade300,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 36,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Build the actual avatar (supports image, Lottie, or fallback initials)
  Widget _buildAvatar(String avatarPath, String fallbackName) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white12,
          child:   ClipOval(
            child: avatarPath.endsWith('.json')
                ? Lottie.asset(avatarPath, fit: BoxFit.cover, repeat: true, width: 75, height: 75)
                : (avatarPath.contains('assets/')
                ? Image.asset(avatarPath, width: 75, height: 75, fit: BoxFit.cover)
                : Text(avatarPath, style: const TextStyle(fontSize: 55))),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final user = xpManager.userProfile;
    final playerName = user.fullName;
    final banner = xpManager.selectedBannerImage;
    final stars = xpManager.stars;
    final tokens = xpManager.saveTokenCount;

    // Sparkle when new stars or tokens are gained
    final showSparkle =
        xpManager.recentlyAddedStars > 0 || xpManager.recentlyAddedTokens > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        children: [
          // Banner background
          Image.asset(
            banner,
            width: double.infinity,
            height: 100,
            fit: BoxFit.cover,
          ),
          // Dark overlay
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 👉 Place of selected avatar
                  _buildAvatar(xpManager.selectedAvatar, playerName),
                  const SizedBox(width: 8),
                  // Name + stats
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          playerName.isEmpty ? "Enter your name ✏️" : playerName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(blurRadius: 3, color: Colors.black)
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Column( mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            Row(
                              children: [
                                const SizedBox(width: 20),
                                const Icon(Icons.star, color: Colors.amber, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  "$stars",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const SizedBox(width: 20),
                                const Icon(Icons.generating_tokens_rounded,
                                    color: Colors.greenAccent, size: 20),
                                const SizedBox(width: 6),

                                Text(
                                  "$tokens",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ],
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
