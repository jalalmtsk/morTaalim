import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';

import '../Animal_Data.dart';
import 'MatchTheSound_ResultPage.dart';
import 'Tools/AnimalTiles.dart';
import 'Tools/DropTarget.dart';
import 'Widgets/HubBar.dart';
import 'Widgets/PromptCard.dart';

class AS_MatchDrop extends StatefulWidget {
  const AS_MatchDrop({super.key});

  @override
  State<AS_MatchDrop> createState() => _AS_MatchDropState();
}

class _AS_MatchDropState extends State<AS_MatchDrop>
    with TickerProviderStateMixin {
  static const int maxScore = 10;
  static const int initialLives = 3;

  final Random _rand = Random();
  late List<Map<String, dynamic>> _pool;
  late List<Map<String, dynamic>> _choices;
  late Map<String, dynamic> _target;

  int _score = 0;
  int _lives = initialLives;

  // UI
  late AnimationController _pulseController;
  bool _showOverlay = false;
  bool _lastCorrect = false;

  // Lottie preload
  late final Future<LottieComposition> _doneComp;
  late final Future<LottieComposition> _wrongComp;

  // ✅ Banner Ad
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);

    // preload animations
    _doneComp = AssetLottie(
        'assets/animations/QuizzGame_Animation/DoneAnimation.json')
        .load();
    _wrongComp =
        AssetLottie('assets/animations/QuizzGame_Animation/wrong.json').load();

    _startGame();

    // ✅ Initialize Banner Ad
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-9936922975297046/2736323402', // ✅ real ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() {}),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint("❌ Failed to load banner ad: $error");
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bannerAd?.dispose(); // ✅ Dispose Ad
    super.dispose();
  }

  void _startGame() {
    _score = 0;
    _lives = initialLives;
    _pool = List<Map<String, dynamic>>.from(animals)..shuffle();
    _loadRound();
  }

  void _loadRound() {
    _pool.shuffle();
    _choices = _pool.take(3).toList();
    _target = _choices[_rand.nextInt(_choices.length)];
    setState(() {});
  }

  Future<void> _onDrop(Map<String, dynamic> dropped) async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    _lastCorrect = dropped['name'] == _target['name'];

    if (_lastCorrect) {
      _score++;
      xpManager.addXP(1, context: context);
      audioManager.playSfx(
          'assets/audios/UI_Audio/SFX_Audio/CorrectAnwser_SFX.mp3');
      await audioManager.playAlert(dropped['sound']);
    } else {
      _lives--;
      audioManager.playSfx(
          'assets/audios/UI_Audio/SFX_Audio/WrongAnwser_SFX.mp3');
    }

    _showResultOverlay();
  }

  void _showResultOverlay() {
    setState(() => _showOverlay = true);
  }

  void _hideOverlayAndAdvance({bool sameRound = false}) {
    setState(() => _showOverlay = false);
    if (!sameRound) {
      _loadRound();
    } else {
      final otherPool = List<Map<String, dynamic>>.from(animals)
        ..removeWhere((a) => a['name'] == _target['name'])
        ..shuffle();
      final distractors = otherPool.take(2).toList();
      _choices = [...distractors, _target]..shuffle();
      setState(() {});
    }
  }

  void _endGame({required bool failed}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MatchResultPage(
          score: _score,
          maxScore: maxScore,
          failed: failed,
          onPlayAgain: () {
            Navigator.pop(context);
            _startGame();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _score / maxScore;
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50,
      appBar: AppBar(
        title:  Text('🐾 ${tr(context).matchTheSound}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Userstatutbar(),
                      const SizedBox(height: 8),
                      HudBar(
                        score: _score,
                        lives: _lives,
                        maxScore: maxScore,
                        progress: progress,
                      ),
                      const SizedBox(height: 8),
                      PromptCard(
                        pulseController: _pulseController,
                        onPlay: () => audioManager.playAlert(_target['sound']),
                        text:
                        '🎧 ${tr(context).listenThenDragTheCorrectAnimalIntoTheGlowingRing}!',
                      ),
                      const SizedBox(height: 10),
                      DropTarget(
                        highlight: false,
                        onWillAccept: (data) => !_showOverlay,
                        onAccept: (data) async {
                          if (_showOverlay) return;
                          await _onDrop(data);

                          // wait for Lottie
                          final composition =
                          _lastCorrect ? await _doneComp : await _wrongComp;
                          final controller = AnimationController(
                            vsync: this,
                            duration: composition.duration,
                          );

                          controller.addStatusListener((status) {
                            if (status == AnimationStatus.completed) {
                              controller.dispose();
                              setState(() => _showOverlay = false);
                              if (_lastCorrect) {
                                if (_score >= maxScore) {
                                  _endGame(failed: false);
                                } else {
                                  _hideOverlayAndAdvance();
                                }
                              } else {
                                if (_lives <= 0) {
                                  _endGame(failed: true);
                                } else {
                                  _hideOverlayAndAdvance(sameRound: true);
                                }
                              }
                            }
                          });

                          setState(() => _showOverlay = true);
                          controller.forward();
                        },
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _choices
                              .map(
                                (a) => Draggable<Map<String, dynamic>>(
                              data: a,
                              feedback: AnimalTile(
                                  image: a['image'], dragging: true),
                              childWhenDragging:
                              AnimalTile(image: a['image'], faded: true),
                              child: AnimalTile(image: a['image']),
                            ),
                          )
                              .toList(),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18.0),
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              audioManager.playAlert(_target['sound']),
                          icon: const Icon(Icons.volume_up),
                          label:  Text(tr(context).playAgain),
                          style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_showOverlay)
                    Positioned.fill(
                      child: AbsorbPointer(
                        absorbing: true,
                        child: Center(
                          child: Lottie.asset(
                            _lastCorrect
                                ? 'assets/animations/QuizzGame_Animation/DoneAnimation.json'
                                : 'assets/animations/QuizzGame_Animation/wrong.json',
                            repeat: false,
                            width: 280,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ✅ Banner Ad at bottom
            if (_bannerAd != null)
              Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }
}
