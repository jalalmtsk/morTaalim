import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../tools/audio_tool/Audio_Manager.dart';

typedef RewardCallback = void Function({required bool isRare});

class RewardChest extends StatefulWidget {
  final Duration cooldown;
  final RewardCallback onRewardCollected;
  final String chestClosedAsset;
  final String chestOpenAnimationAsset;
  final String rareChestClosedAsset;
  final String rareChestOpenAnimationAsset;
  final double size;

  const RewardChest({
    super.key,
    required this.cooldown,
    required this.onRewardCollected,
    required this.chestClosedAsset,
    required this.chestOpenAnimationAsset,
    required this.rareChestClosedAsset,
    required this.rareChestOpenAnimationAsset,
    this.size = 80,
  });

  @override
  State<RewardChest> createState() => _RewardChestState();
}

class _RewardChestState extends State<RewardChest> with SingleTickerProviderStateMixin {
  Timer? _timer;
  DateTime? _lastRewardTime;
  Duration _timeLeft = Duration.zero;
  bool _isRare = false;
  int _streak = 0;

  final _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  late AnimationController _bounceController;

  bool get isReady => _timeLeft <= Duration.zero;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _loadRewardTimeAndStreak();
  }

  Future<void> _loadRewardTimeAndStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt('lastRewardTime');
    final streak = prefs.getInt('rewardStreak') ?? 0;
    final lastCollectedDay = prefs.getInt('lastCollectedDay') ?? 0;
    final now = DateTime.now();
    final todayDayOfYear = _dayOfYear(now);

    if (millis != null) {
      _lastRewardTime = DateTime.fromMillisecondsSinceEpoch(millis);
      final nextRewardTime = _lastRewardTime!.add(widget.cooldown);
      _timeLeft = nextRewardTime.difference(now);

      _streak = (lastCollectedDay == todayDayOfYear || lastCollectedDay == todayDayOfYear - 1) ? streak : 0;
    } else {
      _lastRewardTime = now.subtract(widget.cooldown);
      _timeLeft = Duration.zero;
      _streak = 0;
    }

    _startTimer();
    setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 300), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final nextReward = _lastRewardTime!.add(widget.cooldown);
    _timeLeft = nextReward.isBefore(now) ? Duration.zero : nextReward.difference(now);
    setState(() {});
  }

  Future<void> _collectReward() async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    if (!isReady) {
      audioManager.playEventSound('clickButton2');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayDayOfYear = _dayOfYear(now);
    final lastCollectedDay = prefs.getInt('lastCollectedDay') ?? 0;

    _streak = (lastCollectedDay == todayDayOfYear - 1) ? _streak + 1 : 1;

    await prefs.setInt('rewardStreak', _streak);
    await prefs.setInt('lastCollectedDay', todayDayOfYear);

    double chance = (0.2 + _streak * 0.05).clamp(0.2, 0.3);
    _isRare = Random().nextDouble() < chance;

    _lastRewardTime = now;
    await prefs.setInt('lastRewardTime', _lastRewardTime!.millisecondsSinceEpoch);

    _showRewardPopup();
    _confettiController.play();
    audioManager.playSfx('assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3');

    widget.onRewardCollected(isRare: _isRare);

    _timeLeft = widget.cooldown;
    _startTimer();
    setState(() {});
  }

  void _showRewardPopup() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Reward Screen",
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque, // tap anywhere to dismiss
          onTap: () => Navigator.pop(context),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // Confetti Background
                Positioned.fill(
                  child: IgnorePointer(
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      colors: const [Colors.amber, Colors.orange, Colors.purple],
                    ),
                  ),
                ),

                // Reward Content Centered
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isRare ? "🌟 RARE STAR COLLECTED!" : "🔥 XP COLLECTED!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: _isRare ? Colors.amber : Colors.orangeAccent,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.8),
                              blurRadius: 10,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Centered Lottie animation for both rewards
                      Center(
                        child: Lottie.asset(
                          _isRare
                              ? 'assets/animations/GiftStar.json'
                              : 'assets/animations/girl_jumping.json',
                          height: 250,
                          repeat: true,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        "Tap anywhere to continue",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
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
    );
  }


  int _dayOfYear(DateTime date) {
    final start = DateTime(date.year, 1, 1);
    return date.difference(start).inDays + 1;
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final progress = 1.0 - (_timeLeft.inSeconds / widget.cooldown.inSeconds).clamp(0.0, 1.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [Colors.amber, Colors.orange, Colors.purple],
        ),
        GestureDetector(
          onTap: _collectReward,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.05).animate(
              CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isReady)
                  Lottie.asset(
                    'assets/animations/LvlUnlocked/StarSpark.json',
                    width: widget.size,
                    repeat: true,
                  ),
                SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Lottie animation if ready
                      if (isReady)
                        Transform(
                          transform: Matrix4.identity()
                            ..translate(0.0, -5.0)
                            ..scale(2.7),
                          alignment: Alignment.center,
                          child: Lottie.asset(
                            _isRare
                                ? widget.rareChestOpenAnimationAsset
                                : widget.chestOpenAnimationAsset,
                            repeat: true,
                          ),
                        )
                      else
                      // Image if NOT ready
                        Transform(
                          transform: Matrix4.identity()
                            ..translate(0.0, 3.0)
                            ..scale(0.95),
                          alignment: Alignment.center,
                          child: Image.asset(
                            _isRare ? widget.rareChestClosedAsset : widget.chestClosedAsset,
                          ),
                        ),

                      // Timer text overlay
                      if (!isReady)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatDuration(_timeLeft),
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                )

              ],
            ),
          ),
        ),
      ],
    );
  }
}
