import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';
import '../../main.dart';
import 'TracingAlphabetPage.dart';

class LanguageOption {
  final String name;
  final String languageCode;
  final String icon;
  final Color color;
  final bool locked;
  final int cost;

  LanguageOption({
    required this.name,
    required this.languageCode,
    required this.icon,
    required this.color,
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

    final bgColor = isUnlocked ? lang.color : Colors.grey.shade400;
    final iconColor = isUnlocked ? Colors.white : Colors.grey.shade200;
    final textColor = isUnlocked ? Colors.white : Colors.grey.shade100;

    return Stack(
      alignment: Alignment.center,
      children: [
        ScaleTransition(
          scale: _scaleAnim,
          child: GestureDetector(
            onTap: _onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 160,
              height: 180,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUnlocked
                    ? LinearGradient(
                  colors: [lang.color.withOpacity(0.9), lang.color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : LinearGradient(
                  colors: [Colors.orange.shade700.withValues(alpha: 0.4), Colors.grey.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: isUnlocked ? Border.all(color: Colors.white.withOpacity(0.3), width: 2) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(lang.icon, style: TextStyle(fontSize: 40),),
                      if (!isUnlocked)
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          child: Icon(Icons.lock, color: Colors.orange, size: 35),
                        ),
                    ],
                  ),
                  Text(
                    lang.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      shadows: isUnlocked
                          ? [const Shadow(blurRadius: 4, color: Colors.black26, offset: Offset(1, 1))]
                          : [],
                    ),
                  ),
                  if (!isUnlocked)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, size: 18, color: Colors.amber.shade200),
                          const SizedBox(width: 4),
                          Text(
                            "${lang.cost}",
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor,
                              fontWeight: FontWeight.bold,
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

        // 🎉 Confetti stays the same
        Positioned(
          top: 0,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.2,
            colors: const [Colors.green, Colors.blue, Colors.orange, Colors.pink],
          ),
        ),
      ],
    );
  }


}
