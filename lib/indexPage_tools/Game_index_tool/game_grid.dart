import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mortaalim/Themes/ThemeManager.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/AboutMoorTaalim/AboutMoorTaalim.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';

import '../../XpSystem.dart';
import '../../main.dart';
import '../../tools/AnimatedGridItem.dart';
import '../../tools/loading_page.dart';

class GameGrid extends StatefulWidget {
  final List<Map<String, dynamic>> games;

  const GameGrid({super.key, required this.games});

  @override
  State<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late ConfettiController _confettiController;

  bool _isUnlocking = false; // 🔥 Blocks screen when true

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  Future<void> resetCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastSpinTime');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> simulateLoading() async {
    final random = Random();
    final seconds = 1 + random.nextInt(2);
    await Future.delayed(Duration(seconds: seconds));
  }

  void showUnlockAnimation() {
    setState(() => _isUnlocking = true);

    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playSfx("assets/audios/sound_effects/unlock_sound.mp3");
    audioManager.playSfx("assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3");
  }

  void triggerConfetti() {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playSfx("assets/audios/UI_Audio/SFX_Audio/victory1_SFX.mp3");
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final themeManager = Provider.of<ThemeManager>(context);

    return Stack(
      children: [
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    tr(context).chooseGame,
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(1.0, 2.0), // horizontal & vertical shadow
                          blurRadius: 3.0,          // how blurry the shadow is
                          color: themeManager.currentTheme.primaryColor.withOpacity(0.4), // shadow color
                        ),
                        Shadow(
                          offset: Offset(-1.0, -1.0),
                          blurRadius: 2.0,
                          color: themeManager.currentTheme.primaryColor.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        audioManager.playEventSound('PopButton');

                        // Example: text to share
                        String shareText = "Check out my magical profile on MoorTaalim! ✨\n"
                            "Name: ${xpManager.userProfile.fullName} ${xpManager.userProfile.lastName}\n"
                            "Age: ${xpManager.userProfile.age}\n"
                            "Gender: ${xpManager.userProfile.gender}\n"
                            "Tolim: ${xpManager.Tolims}\n"
                            "Stars: ${xpManager.stars}\n"

                            "xp: ${xpManager.xp}";
 
                        Share.share(shareText); // triggers system share dialog
                      },
                      icon: Icon(
                        Icons.share,
                        color: themeManager.currentTheme.accentColor,
                      ),
                    ),


                    IconButton(
                      onPressed: () {
                        audioManager.playEventSound('PopButton');
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AboutMoorTaalimPage()));
                      },
                      icon:  Icon(Icons.info_outlined, color:themeManager.currentTheme.primaryColor ),
                    ),
                  ],
                ),

              ],
            ),
            Expanded(
              child: GridView.builder(
                itemCount: widget.games.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 14,
                  childAspectRatio: 4 / 3,
                ),
                itemBuilder: (context, index) {
                  final game = widget.games[index];
                  final isUnlocked = !game['locked'] || xpManager.isCourseUnlocked(game['title']);
                  final cost = game['cost'] ?? 10;
                  final isLocked = game['locked'] && !isUnlocked;

                  return AnimatedGridItem(
                    index: index,
                    columnCount: 1,
                    onTap: () {
                      if (isUnlocked) {
                        audioManager.playEventSound('PopButton');
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
                        audioManager.playEventSound('clickButton2');
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(tr(context).unlock),
                            content: Text("${tr(context).unlockThisCourseFor} $cost ⭐?"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  audioManager.playEventSound('cancelButton');
                                  Navigator.pop(context);
                                },
                                child: Text(tr(context).cancel),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (xpManager.stars >= cost) {
                                    audioManager.playSfx("assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3");
                                    triggerConfetti();
                                    xpManager.unlockCourse(game['title'], cost);
                                    xpManager.addXP(10, context: context);
                                    Navigator.pop(context);

                                    if (mounted) {
                                      showUnlockAnimation();
                                    }
                                  } else {
                                    audioManager.playEventSound('invalid');
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        duration: const Duration(milliseconds: 1200),
                                        content: Text(tr(context).notEnoughStars),
                                      ),
                                    );
                                  }
                                },
                                child: Text(tr(context).unlock),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              game['image'] ?? '',
                              fit: BoxFit.cover,
                              color: isLocked ? Colors.black.withValues(alpha: 0.45) : null,
                              colorBlendMode: isLocked ? BlendMode.darken : null,
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.2),
                                    Colors.black.withValues(alpha: 0),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(game['icon'], size: 35, color: Colors.white),
                                    if (isLocked)
                                      const Positioned(
                                        bottom: 0,
                                        right: 3,
                                        child: Icon(Icons.lock, size: 30, color: Colors.orange),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _getCourseTitle(tr(context), game['title']),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 4,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isLocked)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.star, size: 28, color: Colors.amber),
                                        const SizedBox(width: 2),
                                        Text(
                                          "$cost",
                                          style: const TextStyle(
                                            fontSize: 20,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black,
                                                blurRadius: 4,
                                                offset: Offset(1, 1),
                                              ),
                                            ],
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
                                      color: Colors.green.shade700.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "${tr(context).free}!",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            blurRadius: 4,
                                            offset: Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            //TODO: DEV ONLY
            /*
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
                        child: Text(tr(context).cancel),
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
             */
          ],
        ),
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

        // 🔥 FULL-SCREEN BLOCKER
        if (_isUnlocking)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: Center(
                child: Lottie.asset(
                  'assets/animations/unlock_key.json',
                  width: 200,
                  height: 200,
                  repeat: false,
                  onLoaded: (composition) {
                    Future.delayed(composition.duration, () {
                      if (mounted) setState(() => _isUnlocking = false);
                    });
                  },
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
      case 'MagicPainting':
        return tr.magicPainting;
      case 'AnimalSounds':
        return tr.animalSound;
      case 'MemoryFlip':
        return tr.memoryFlip;
      case 'SugarSmash':
        return tr.sugarSmash;
      case 'shapeSorter':
        return tr.shapeSorter;
      case 'PlaneDestroyer':
        return tr.planeDestroyer;
      case 'WordLink':
        return tr.wordLink;
      case 'IQGame':
        return tr.iqTest;
      case 'JumpingBoard':
        return tr.jumpingBoard;
      case 'boardGame':
        return tr.boardGame;
      default:
        return key;
    }
  }
}
