import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import '../XpSystem.dart';
import 'package:provider/provider.dart';

class ProfileStatusBar extends StatelessWidget {


  const ProfileStatusBar({
    Key? key,
  }) : super(key: key);

  Widget _buildSimpleAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : "?";

    return CircleAvatar(
      radius: 35,
      backgroundColor: Colors.deepOrange.shade300,
      child: Text(
        initial,
        style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final user = xpManager.userProfile;
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final playerName = user.fullName;
    final banner = xpManager.selectedBannerImage;
    final stars = xpManager.stars;
    final tokens = xpManager.saveTokenCount;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Image.asset(
            banner,
            width: double.infinity,
            height: 110,
            fit: BoxFit.cover,
          ),
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 110,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      playerName.isEmpty ? "Enter your name ✏️" : playerName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            "$stars",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.generating_tokens_rounded, color: Colors.greenAccent),
                          const SizedBox(width: 4),
                          Text(
                            "$tokens",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),
                    ],
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
