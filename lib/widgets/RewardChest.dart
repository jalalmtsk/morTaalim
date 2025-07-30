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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: _isRare
                              ? [Colors.amber.withOpacity(0.4), Colors.transparent]
                              : [Colors.orangeAccent.withOpacity(0.4), Colors.transparent],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isRare ? Colors.amber : Colors.orangeAccent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isRare ? "🌟 Rare Star Collected!" : "🔥 XP Collected!",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _isRare ? Colors.amber : Colors.orangeAccent,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Lottie.asset(
                            _isRare
                                ? 'assets/animations/GiftStar.json'
                                : 'assets/animations/girl_jumping.json',
                            height: 150,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRare ? Colors.amber : Colors.orangeAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Text("Awesome!", style: TextStyle(fontSize: 18, color: Colors.black)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Lottie.asset(
                          'assets/animations/LvlUnlocked/StarSpark.json',
                          repeat: false,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
                              color: Colors.black.withOpacity(0.6),
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
