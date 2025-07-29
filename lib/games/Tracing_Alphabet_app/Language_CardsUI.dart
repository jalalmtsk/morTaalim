import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';
import '../../main.dart';
import '../../tools/audio_tool/Audio_Manager.dart';
import 'TracingAlphabetPage.dart';

class LanguageOption {
  final String name;
  final String languageCode;
  final String icon;
  final String imagePath; // ✅ NEW
  final bool locked;
  final int cost;

  LanguageOption({
    required this.name,
    required this.languageCode,
    required this.icon,
    required this.imagePath,
    this.locked = false,
    this.cost = 10,
  });
}


class LanguageCard extends StatefulWidget {
  final LanguageOption language;

  const LanguageCard({super.key, required this.language});

  @override
  State<LanguageCard> createState() => _LanguageCardState();
}


class _LanguageCardState extends State<LanguageCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  final player = AudioPlayer();

  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    final audio = Provider.of<AudioManager>(context, listen: false);
    audio.playBackgroundMusic("assets/audios/sound_track/backGroundMusic8bit.mp3");
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnim = Tween<double>(begin: 0.9, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    player.dispose();
    super.dispose();
  }

  Future<void> _playUnlockSound() async {
    try {
      await player.setAsset('assets/audios/unlock_success.mp3'); // Add a fun sound
      await player.play();
    } catch (e) {
      print('Error playing unlock sound: $e');
    }
  }

  void _onTap() async {
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    final lang = widget.language;

    final isUnlocked = !lang.locked || xpManager.isLanguageUnlocked(lang.languageCode);

    if (isUnlocked) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AlphabetTracingPage(language: lang.languageCode)));
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("🔒 ${tr(context).languageLocked}"),
          content: Text("${tr(context).unlock} ${lang.name} ${tr(context).forb} ${lang.cost} ⭐?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(tr(context).cancel)),
            ElevatedButton(
              onPressed: () async {
                if (xpManager.stars >= lang.cost) {
                  Navigator.pop(context);
                  xpManager.unlockLanguage(lang.languageCode, lang.cost);

                  // Trigger animation
                  _confettiController.play();
                  await _playUnlockSound();

                  setState(() {
                    _unlocked = true;
                  });

                  await Future.delayed(const Duration(milliseconds: 1200));

                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr(context).notEnoughStars)),
                  );
                }
              },
              child: Text(tr(context).unlock),
            )
          ],
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    final xpManager = Provider.of<ExperienceManager>(context);
    final isUnlocked = !lang.locked || xpManager.isLanguageUnlocked(lang.languageCode);

    final bgColor = isUnlocked ? Colors.grey : Colors.grey.shade400;
    final iconColor = isUnlocked ? Colors.white : Colors.grey.shade200;
    final textColor = isUnlocked ? Colors.white : Colors.grey.shade100;

    return Stack(
      alignment: Alignment.center,
      children: [
        ScaleTransition(
          scale: _scaleAnim,
          child: GestureDetector(
            onTap: _onTap,
            child: Stack(
            alignment: Alignment.center,
            children: [
              // 🖼️ Background image with dark overlay if locked
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    lang.locked && !isUnlocked ? Colors.black.withOpacity(0.4) : Colors.transparent,
                    BlendMode.darken,
                  ),
                  child: Image.asset(
                    lang.imagePath,
                    width: 160,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // 🎯 Card content on top
              ScaleTransition(
                scale: _scaleAnim,
                child: GestureDetector(
                  onTap: _onTap,
                  child: Container(
                    width: 160,
                    height: 180,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.7), width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(lang.icon, style: const TextStyle(fontSize: 40)),
                            if (!isUnlocked)
                              const Positioned(
                                bottom: 0,
                                right: 0,
                                child: Icon(Icons.lock, color: Colors.orange, size: 35),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          lang.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                          ),
                        ),
                        if (!isUnlocked)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star, size: 18, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  "${lang.cost}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // 🎉 Confetti remains
              Positioned(
                top: 0,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  emissionFrequency: 0.2,
                  numberOfParticles: 20,
                  gravity: 0.1,
                  colors: const [Colors.green, Colors.blue, Colors.orange, Colors.pink],
                ),
              ),
            ],
          ),
          ),
        ),

        // 🎉 Confetti stays the same
        Positioned(
          top: 0,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            emissionFrequency: 0.2,
            numberOfParticles: 20,
            gravity: 0.1,
            colors: const [Colors.green, Colors.blue, Colors.orange, Colors.pink],
          ),
        ),
      ],
    );
  }


}
