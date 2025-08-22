import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../XpSystem.dart';
import '../../main.dart';
import '../../tools/audio_tool/Audio_Manager.dart';
import 'TracingAlphabetPage.dart';

class LanguageOption {
  final String name;
  final String languageCode;
  final String icon;
  final String imagePath;
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
  final ConfettiController _confettiController =
  ConfettiController(duration: const Duration(seconds: 2));

  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioManager = Provider.of<AudioManager>(context, listen: false);
      audioManager.playBackgroundMusic(
        'assets/audios/BackGround_Audio/RetroGame_BCG.mp3',
      );
    });
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnim = Tween<double>(begin: 0.9, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _playUnlockSound() async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    try {
      await audioManager.playSfx('assets/audios/sound_effects/unlock_sound.mp3');
      audioManager.playSfx('assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3');
      audioManager.playSfx('assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3');
    } catch (e) {
      debugPrint('Error playing unlock sound: $e');
    }
  }

  Future<void> _unlockLanguage(LanguageOption lang, ExperienceManager xpManager) async {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // ✅ Create full-screen overlay with Lottie and Confetti
    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Lottie.asset(
                  "assets/animations/unlock_key.json",
                  repeat: false,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.2,
              numberOfParticles: 25,
              gravity: 0.1,
              colors: const [Colors.green, Colors.blue, Colors.orange, Colors.pink],
            ),
          ),
        ],
      ),
    );

    overlay.insert(overlayEntry);

    xpManager.unlockLanguage(lang.languageCode, lang.cost);
    xpManager.addXP(20, context: context);

    _confettiController.play();
    await _playUnlockSound();

    setState(() => _unlocked = true);

    // Wait for unlock animation
    await Future.delayed(const Duration(seconds: 2));

    overlayEntry.remove();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AlphabetTracingPage(language: lang.languageCode)),
      );
    }
  }

  void _onTap() async {
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final lang = widget.language;
    final isUnlocked = !lang.locked || xpManager.isLanguageUnlocked(lang.languageCode);

    if (isUnlocked) {
      audioManager.playEventSound('PopButton');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AlphabetTracingPage(language: lang.languageCode)),
      );
    } else {
      audioManager.playEventSound('clickButton');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title:  Text("🔒 ${tr(context).languageLocked}"),
          content: Text("${tr(context).unlock} ${lang.name} ${tr(context).forb} ${lang.cost} ⭐?"),
          actions: [
            TextButton(
              onPressed: () {
                audioManager.playEventSound('cancelButton');
                Navigator.pop(context);
              },
              child:  Text(tr(context).cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (xpManager.stars >= lang.cost) {
                  Navigator.pop(context);
                  await _unlockLanguage(lang, xpManager);
                } else {
                  Navigator.pop(context);
                  audioManager.playEventSound('invalid');
                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(tr(context).notEnoughStars)),
                  );
                }
              },
              child:  Text(tr(context).unlock),
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

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTap: _onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // BACKGROUND IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  lang.locked && !isUnlocked
                      ? Colors.black.withOpacity(0.5)
                      : Colors.transparent,
                  BlendMode.darken,
                ),
                child: Image.asset(
                  lang.imagePath,
                  width: 190,
                  height: 190,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // CARD CONTENT
            Container(
              width: 190,
              height: 190,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 4),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(lang.icon, style: const TextStyle(fontSize: 40)),
                        if (!isUnlocked)
                          const Positioned(
                            bottom: 5,
                            left: 5,
                            child: Icon(Icons.lock, color: Colors.orange, size: 35),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lang.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
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
          ],
        ),
      ),
    );
  }
}
