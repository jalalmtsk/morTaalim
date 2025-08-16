import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mortaalim/tools/Ads_Manager.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';

import '../../XpSystem.dart';
import '../../main.dart';
import '../../tools/audio_tool/audio_tool.dart';
import '../../tools/loading_page.dart';
import '../../widgets/RewardChest.dart';
import '../../widgets/SpinWheel/SpinTheWheel.dart';


class ITGrid extends StatefulWidget {
  final List<Map<String, dynamic>> ITCourses;

  const ITGrid({super.key, required this.ITCourses});

  @override
  State<ITGrid> createState() => _GameGridState();
}

class _GameGridState extends State<ITGrid>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  BannerAd? _bannerAd;

  late ConfettiController _confettiController;
  bool _isBannerAdLoaded = false;
  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _isBannerAdLoaded = false;

    _bannerAd = AdHelper.getBannerAd(() {
      setState(() {
        _isBannerAdLoaded = true;
      });
    });
  }

  Future<void> resetCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastSpinTime'); // Remove the cooldown
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadBannerAd();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> simulateLoading() async {
    final random = Random();
    final seconds = 1 + random.nextInt(2);
    await Future.delayed(Duration(seconds: seconds));
  }



  void triggerConfetti() {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playSfx("assets/audios/sound_effects/victory1_SFX.mp3");
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    return Stack(
      children: [
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    tr(context).chooseGame,
                    style: TextStyle(fontSize: 20, color: Colors.grey[700]),
                  ),
                ),
                IconButton(
                  onPressed: () { triggerConfetti();},
                  icon: const Icon(Icons.card_giftcard),
                )
              ],
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: widget.ITCourses.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: 4 / 3,
                ),
                itemBuilder: (context, index) {
                  final game = widget.ITCourses[index];
                  final isUnlocked = !game['locked'] || xpManager.isCourseUnlocked(game['title']);
                  final cost = game['cost'] ?? 10;
                  final isLocked = game['locked'] && !isUnlocked;

                  return GestureDetector(
                    onTap: () {
                      if (isUnlocked) {
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
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Course Locked"),
                            content: Text("Unlock this course for $cost ⭐?"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () {},

                                child: const Text("Unlock"),
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
                              game['image'] ?? 'assets/images/AvatarImage/Avatar2.png',
                              fit: BoxFit.cover,
                              color: isLocked ? Colors.black.withValues(alpha: 0.5) : null,
                              colorBlendMode: isLocked ? BlendMode.darken : null,
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.3),
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
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
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
                                      color: Colors.green.shade700.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "FREE!",
                                      style: TextStyle(
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


            ///:::::::: BANNER ADS
            (context.watch<ExperienceManager>().adsEnabled && _bannerAd != null && _isBannerAdLoaded)
                ? SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
            )
                : const SizedBox.shrink(),
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
