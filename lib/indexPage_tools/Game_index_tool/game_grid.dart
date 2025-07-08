import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mortaalim/Ads_Manager.dart';
import '../../l10n/app_localizations.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';

import '../../XpSystem.dart';
import '../../tools/audio_tool/audio_tool.dart';
import '../../loading_page.dart';


final MusicPlayer _victorySound = MusicPlayer();
class GameGrid extends StatefulWidget {
  final List<Map<String, dynamic>> games;
  final MusicPlayer musicPlayer;

  const GameGrid({super.key, required this.games, required this.musicPlayer});

  @override
  State<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid> with TickerProviderStateMixin {

  BannerAd? _bannerAd;

  late MusicPlayer _clickButton;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _clickButton = MusicPlayer();
    _clickButton.preload("assets/audios/pop.mp3");
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));

    _bannerAd = AdHelper.getBannerAd((){
      setState(() {

      });
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _victorySound.dispose();
    _clickButton.dispose();

    super.dispose();

  }


  Future<void> simulateLoading() async {
    final random = Random();
    final seconds = 1 + random.nextInt(2); // 1, 2 seconds
    print('Simulating loading for $seconds second(s)...'); // optional debug
    await Future.delayed(Duration(seconds: seconds));
  }

  void showUnlockAnimation(BuildContext context) {
    _clickButton.play("assets/audios/sound_effects/unlock_sound.mp3");

    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Center(
        child: Lottie.asset(
          'assets/animations/unlock_key.json',
          width: 100,
          height: 100,
          repeat: false,
          onLoaded: (composition) {
            _clickButton.play("assets/audios/sound_effects/validationAfterUnlock.mp3");
            Future.delayed(composition.duration, () {
              entry.remove();
            });
          },
        ),
      ),
    );

    overlay.insert(entry);
  }

  void triggerConfetti() {
    print("Confetti triggered!"); // Debug
    _clickButton.play("assets/audios/sound_effects/victory1.mp3");
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final tr = AppLocalizations.of(context)!;

    return Stack(
      children: [
        /// Main content (behind confetti)
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                tr.chooseGame,
                style: TextStyle(fontSize: 20, color: Colors.grey[700]),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: widget.games.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: 4 / 3,
                ),
                itemBuilder: (context, index) {
                  final game = widget.games[index];
                  final isUnlocked = !game['locked'] || xpManager.isCourseUnlocked(game['title']);
                  final cost = game['cost'] ?? 10;
                  final isLocked = game['locked'] && !isUnlocked;

                  return GestureDetector(
                    onTap: () {
                      if (isUnlocked) {
                        _clickButton.play("assets/audios/pop.mp3");
                        widget.musicPlayer.stop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LoadingPage(
                              loadingFuture: simulateLoading(),
                              nextRouteName: game['routeName'],
                            ),
                          ),
                        );
                      } else {
                        _clickButton.play("assets/audios/pop.mp3");
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Course Locked"),
                            content: Text("Unlock this course for $cost ⭐?"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  _clickButton.play("assets/audios/sound_effects/uiButton.mp3");
                                  Navigator.pop(context);
                                },
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (xpManager.stars >= cost) {
                                    _victorySound.play("assets/audios/sound_effects/victory2.mp3");
                                    triggerConfetti();
                                    _clickButton.play("assets/audios/sound_effects/uiButton.mp3");
                                    xpManager.unlockCourse(game['title'], cost);
                                    Navigator.pop(context);
                                    if (mounted) {
                                      triggerConfetti();
                                      showUnlockAnimation(context);
                                    }
                                  } else {
                                    _clickButton.play("assets/audios/sound_effects/wrong_answer.mp3");
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          duration: Duration(milliseconds: 1500),
                                          content: Text("Not enough stars!")),
                                    );
                                  }
                                },
                                child: const Text("Unlock"),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isLocked
                            ? Colors.grey.shade700
                            : game['color'].withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: game['color'].withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(2, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(game['icon'], size: 48, color: Colors.white),
                              if (isLocked)
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Icon(Icons.lock, size: 30, color: Colors.orange),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _getCourseTitle(tr, game['title']),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isLocked)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.star, size: 18, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    "$cost",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (!isLocked && cost == 0)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade600,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "FREE!",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            /// Dev Reset Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Reset Purchases (Dev Only)'),
                    content: const Text('Are you sure you want to reset all unlocked courses, stars, and progress?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () {
                          xpManager.resetData();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All progress has been reset!')),
                          );
                          setState(() {});
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Reset Purchases (Dev Only)'),
            ),

            /// TEMP: Debug button to manually trigger confetti
            ElevatedButton(
              onPressed: () {
                triggerConfetti();
              },
              child: const Text("🎉 Trigger Confetti (Debug)"),
            ),
            ElevatedButton(
              onPressed: () {
               xpManager.addStars(40);
               xpManager.addTokens(3);
xpManager.addXP(30, context: context);
              },
              child: const Text("Add Stars and Tolims"),
            ),

            if (_bannerAd != null)
              Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),

        /// Confetti Widget — always on top
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 300,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                  maxBlastForce: 20,
                  minBlastForce: 10,
                  gravity: 0.3,
                  shouldLoop: false,
                  colors: const [Colors.red, Colors.yellow, Colors.green, Colors.blue],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getCourseTitle(AppLocalizations tr, String key) {
    switch (key) {
      case 'drawingAlphabet':
        return tr.drawingAlphabet;
      case 'quizGame':
        return tr.quizGame;
      case 'appStories':
        return tr.appStories;
      case 'shapeSorter':
        return tr.shapeSorter;
      case 'PlaneDestroyer':
        return tr.boardGame;
      case 'piano':
        return tr.piano;
      case 'WordLink':
        return tr.linkWordgame;
      case 'IQGame':
        return tr.iQTest;
      case 'MagicPainting':
        return tr.iQTest;
      case 'JumpingBoard':
        return tr.iQTest;
      default:
        return key;
    }
  }
}
