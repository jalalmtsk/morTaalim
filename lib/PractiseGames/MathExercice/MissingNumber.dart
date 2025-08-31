import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import 'package:mortaalim/tools/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import '../../XpSystem.dart';
import '../../main.dart';
import '../../tools/Ads_Manager.dart';
import '../../tools/audio_tool/Audio_Manager.dart';
import 'Tools/AnimatedHeart.dart';

/// MissingNumberExercise - Rewritten with hearts, ads on quit/replay, banner + adaptive UI
class MissingNumberGame extends StatelessWidget {
  const MissingNumberGame({super.key});
  @override
  Widget build(BuildContext context) => const MissingNumberExercise();
}

class MissingNumberExercise extends StatefulWidget {
  const MissingNumberExercise({super.key});
  @override
  State<MissingNumberExercise> createState() => _MissingNumberExerciseState();
}

class _MissingNumberExerciseState extends State<MissingNumberExercise>
    with SingleTickerProviderStateMixin {
  // ----------------- Tunables -----------------
  static const int _targetScore = 10;
  static const int _maxAnswers = 20;
  static const int _sequenceLength = 4;
  static const int _maxStart = 15;
  static const int _maxLives = 3;
  static const double _bannerHeightFallback = 50.0;

  // --------------- State & Helpers -------------
  final Random _rng = Random();
  final MusicPlayer _sfxPlayer = MusicPlayer();
  final MusicPlayer _victorySfx = MusicPlayer();
  final MusicPlayer _bgmPlayer = MusicPlayer();
  final MusicPlayer _bgmVictory = MusicPlayer();

  late List<int> _sequence;
  late int _correctAnswer;
  int _missingIndex = 1; // can randomize if desired

  int _score = 0;
  int _wrong = 0;
  int _lives = _maxLives;

  bool _showGameOver = false;
  bool? _isAnswerCorrect;
  bool _isProcessingAnswer = false;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  bool _isAdLoading = false;
  bool _isBgmPlaying = true;

  // ----------------- Lifecycle -----------------
  @override
  void initState() {
    super.initState();
    _generateNewQuestion();
    _loadBannerAd();
    _startBackgroundMusic();
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _isBannerAdLoaded = false;
    _bannerAd = AdHelper.getBannerAd(() {
      if (!mounted) return;
      setState(() => _isBannerAdLoaded = true);
    });
  }

  Future<void> _startBackgroundMusic() async {
    try {
      _bgmPlayer.setVolume(0.28);
      await _bgmPlayer.play('assets/audios/sound_track/FoamRubber_BcG.mp3', loop: true);
      if (mounted) setState(() => _isBgmPlaying = true);
    } catch (_) {
      // ignore bgm failures silently
    }
  }

  Future<void> _stopBackgroundMusic() async {
    try {
      await _bgmPlayer.stop();
    } catch (_) {}
  }

  Future<void> _playVictoryMusicSequence() async {
    try {
      _victorySfx.play("assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3");
      _bgmVictory.setVolume(0.4);
      _bgmVictory.play("assets/audios/sound_track/SakuraGirlYay_BcG.mp3", loop: true);
      await _sfxPlayer.play('assets/audios/sound_effects/victory1_SFX.mp3');
    } catch (_) {}
  }

  @override
  void dispose() {
    _sfxPlayer.dispose();
    _victorySfx.dispose();
    _bgmPlayer.dispose();
    _bgmVictory.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  // --------------- Game Logic -----------------
  void _generateNewQuestion() {
    final rand = _rng;
    final start = rand.nextInt(_maxStart) + 1;
    final step = rand.nextBool() ? 1 : 2;
    _sequence = List.generate(_sequenceLength, (i) => start + i * step);
    _correctAnswer = _sequence[_missingIndex];
    _sequence[_missingIndex] = -1;
    _isAnswerCorrect = null;
    if (mounted) setState(() {});
  }

  Future<void> _handleGameOver({required bool byLives}) async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    // stop bgm and play fail victor or crowd depending
    await _stopBackgroundMusic();
    if (byLives) {
      audioManager.playSfx("assets/audios/UI_Audio/SFX_Audio/FailMeme_SFX.mp3");
    }
    setState(() {
      _showGameOver = true;
      _isProcessingAnswer = false;
      _isAnswerCorrect = null;
    });
  }

  Future<void> _checkAnswer(int selected) async {
    if (_isProcessingAnswer || _showGameOver) return;
    _isProcessingAnswer = true;
    HapticFeedback.selectionClick();

    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);

    // ensure quick UI feedback
    if (selected == _correctAnswer) {
      // Correct
      xpManager.addXP(1, context: context);
      await _sfxPlayer.play('assets/audios/QuizGame_Sounds/correct.mp3');
      if (!mounted) return;
      setState(() {
        _score++;
        _isAnswerCorrect = true;
      });

      Future.delayed(const Duration(milliseconds: 900), () async {
        if (!mounted) return;
        if (_score >= _targetScore) {
          // reward if flawless or with lives remaining
          if (_wrong == 0) xpManager.addTokenBanner(context, 1);

          // play victory sequence
          audioManager.playSfx('assets/audios/UI_Audio/SFX_Audio/VictoryOrchestral_SFX.mp3');
          audioManager.playSfx('assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3');
          await _playVictoryMusicSequence();

          if (!mounted) return;
          setState(() {
            _showGameOver = true;
            _isAnswerCorrect = null;
            _isProcessingAnswer = false;
          });
        } else {
          // continue
          setState(() {
            _isProcessingAnswer = false;
            _isAnswerCorrect = null;
          });
          _generateNewQuestion();
        }
      });
    } else {
      // Incorrect
      await _sfxPlayer.play('assets/audios/QuizGame_Sounds/incorrect.mp3');
      if (!mounted) {
        _isProcessingAnswer = false;
        return;
      }

      _wrong++;
      _lives = (_lives > 0) ? _lives - 1 : 0;

      setState(() {
        _isAnswerCorrect = false;
      });

      // if lives exhausted -> game over
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        if (_lives == 0) {
          _handleGameOver(byLives: true);
        } else {
          setState(() {
            _isAnswerCorrect = null;
            _isProcessingAnswer = false;
          });
        }
      });
    }
  }

  void _resetGame() {
    setState(() {
      _score = 0;
      _wrong = 0;
      _lives = _maxLives;
      _showGameOver = false;
      _isProcessingAnswer = false;
      _isAnswerCorrect = null;
    });
    // stop any victory bgm and restart regular bgm
    _bgmVictory.stop();
    _startBackgroundMusic();
    _generateNewQuestion();
  }

  void _onReplayPressed() {
    setState(() => _isAdLoading = true);
    AdHelper.showInterstitialAd(
      context: context,
      onDismissed: () {
        if (!mounted) return;
        setState(() => _isAdLoading = false);
        _resetGame();
      },
    );
  }

  Future<bool> _confirmQuit() async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final shouldQuit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text('tr(context).areYouSureQuitGame'),
        content: Text('tr(context).youWillLoseYourProgress'),
        actions: [
          TextButton(
            onPressed: () {
              audioManager.playEventSound('cancelButton');
              Navigator.pop(ctx, false);
            },
            child: Text(tr(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              audioManager.playEventSound('confirmButton');
              Navigator.pop(ctx, true);
            },
            child: Text(tr(context).ok),
          ),
        ],
      ),
    );

    final res = shouldQuit ?? false;
    if (res) {
      setState(() => _isAdLoading = true);
      await AdHelper.showInterstitialAd(
        context: context,
        onDismissed: () {
          if (mounted) {
            setState(() => _isAdLoading = false);
            Navigator.pop(context); // Quit after ad is dismissed
          }
        },
      );
    }

    return false; // prevent default pop, handled manually
  }

  void _toggleBackgroundMusic() {
    if (_isBgmPlaying) {
      _stopBackgroundMusic();
    } else {
      _startBackgroundMusic();
    }
    if (mounted) setState(() => _isBgmPlaying = !_isBgmPlaying);
  }

  // ----------------- UI -----------------------
  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.teal.shade700;
    final media = MediaQuery.of(context);
    final maxWidth = media.size.width.clamp(0, 720);
    final isWide = maxWidth >= 520;
    final numberGridCross = isWide ? 5 : 4;

    return WillPopScope(
      onWillPop: () async {
        if (_showGameOver) {
          // allow back if on game over
          return true;
        }
        final shouldQuit = await _confirmQuit();
        if (shouldQuit) {
          Provider.of<AudioManager>(context, listen: false).playEventSound("cancelButton");
        }
        return shouldQuit;
      },
      child: Scaffold(
        backgroundColor: Colors.teal.shade50,
        appBar: AppBar(
          backgroundColor: themeColor,
          automaticallyImplyLeading: !_showGameOver,
          title: Center(child: Text('Nombre Manquant', style: const TextStyle(fontWeight: FontWeight.bold))),
          actions: [
            IconButton(
              onPressed: _toggleBackgroundMusic,
              icon: Icon(_isBgmPlaying ? Icons.volume_up : Icons.volume_off, color: Colors.white),
              tooltip: _isBgmPlaying ? 'Mute Background Music' : 'Play Background Music',
            ),
          ],
        ),
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.teal.shade100, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
            ),

            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth.toDouble()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: _showGameOver ? _buildGameOver(themeColor) : _buildPlayArea(themeColor, numberGridCross),
                  ),
                ),
              ),
            ),

            // correct/wrong overlay
            if (_isAnswerCorrect != null)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Lottie.asset(
                      _isAnswerCorrect! ? 'assets/animations/QuizzGame_Animation/DoneAnimation.json' : 'assets/animations/QuizzGame_Animation/wrong.json',
                      repeat: false,
                    ),
                  ),
                ),
              ),

            // ad-loading overlay
            if (_isAdLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.45),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Provider.of<ExperienceManager>(context).adsEnabled && _bannerAd != null && _isBannerAdLoaded
            ? SafeArea(
          child: SizedBox(
            height: _bannerAd!.size.height.toDouble() > 0 ? _bannerAd!.size.height.toDouble() : _bannerHeightFallback,
            width: _bannerAd!.size.width.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        )
            : null,
      ),
    );
  }

  Widget _buildPlayArea(Color themeColor, int gridCross) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 6),
          const Userstatutbar(),
          const SizedBox(height: 8),

          // Stats row: score, wrongs, hearts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatCard(label: 'Score', value: '$_score / $_targetScore', color: themeColor),
              _StatCard(label: 'Fautes', value: '$_wrong', color: Colors.redAccent),
              Row(
                children: List.generate(_maxLives, (index) {
                  final lost = index >= _lives;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedHeart(lost: lost),
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Question
          Text(
            "Quel est le nombre manquant ?",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: themeColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Sequence display with animated switcher
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Text(
              _sequence.map((e) => e == -1 ? '?' : e.toString()).join('  '),
              key: ValueKey<String>(_sequence.join(',')),
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: themeColor),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // Number buttons grid
          LayoutBuilder(builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final buttonSize = (maxWidth / (gridCross + 0.5)).clamp(56.0, 90.0);
            return GridView.count(
              crossAxisCount: gridCross,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
              children: List.generate(_maxAnswers, (index) {
                final n = index + 1;
                return Semantics(
                  button: true,
                  label: 'answer $n',
                  child: ElevatedButton(
                    onPressed: () => _checkAnswer(n),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      shape: const CircleBorder(),
                      padding: EdgeInsets.all(buttonSize * 0.17),
                      elevation: 6,
                      shadowColor: Colors.teal.shade300,
                    ),
                    child: Text('$n', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                );
              }),
            );
          }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGameOver(Color themeColor) {
    final win = _score >= _targetScore && _lives > 0;
    return Center(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(win ? 'assets/animations/QuizzGame_Animation/Champion.json' : 'assets/animations/QuizzGame_Animation/CuteTigerCrying.json', width: 220, repeat: true),
            const SizedBox(height: 12),
            Text(win ? "🎉 ${tr(context).awesome} !" : "💔 ${tr(context).gameOver}", style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: themeColor)),
            const SizedBox(height: 10),
            Text("Score : $_score / $_targetScore", style: const TextStyle(fontSize: 20, color: Colors.black87)),
            Text("Fautes : $_wrong", style: TextStyle(fontSize: 18, color: _wrong > 0 ? Colors.redAccent : Colors.green)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isAdLoading ? null : _onReplayPressed,
              icon: _isAdLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Icon(Icons.replay),
              label: Text(tr(context).playAgain),
              style: ElevatedButton.styleFrom(backgroundColor: themeColor, padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // go back to previous screen
                if (mounted) Navigator.pop(context);
              },
              child: Text("tr(context).backToMenu"),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small reusable stat card
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
