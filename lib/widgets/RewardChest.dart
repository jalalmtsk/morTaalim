import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';

typedef RewardCallback = void Function({required bool isRare});

class RewardChest extends StatefulWidget {
  final Duration cooldown;
  final RewardCallback onRewardCollected; // now gets isRare flag
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
    this.size = 60,
  });

  @override
  State<RewardChest> createState() => _RewardChestState();
}

class _RewardChestState extends State<RewardChest> {
  Timer? _timer;
  DateTime? _lastRewardTime;
  Duration _timeLeft = Duration.zero;
  bool get isReady => _timeLeft <= Duration.zero;

  final _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  final MusicPlayer _audioPlayer = MusicPlayer();
  final MusicPlayer _player = MusicPlayer();
  final MusicPlayer _player1 = MusicPlayer();
  bool _isRare = false;

  int _streak = 0; // daily streak count

  @override
  void initState() {
    super.initState();
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

      // Check streak continuity: if last collected day was yesterday, keep streak, else reset
      if (lastCollectedDay == todayDayOfYear - 1) {
        _streak = streak;
      } else if (lastCollectedDay == todayDayOfYear) {
        _streak = streak; // collected today, keep streak
      } else {
        _streak = 0; // missed day(s), reset streak
      }
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
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final nextReward = _lastRewardTime!.add(widget.cooldown);
    final diff = nextReward.difference(now);

    _timeLeft = diff <= Duration.zero ? Duration.zero : diff;
    setState(() {});
  }

  Future<void> _playSound(String asset) async {
    await _audioPlayer.play(asset);
  }

  Future<void> _collectReward() async {
    if (!isReady) {
      await _playSound('assets/audios/sound_effects/buttonPressed.mp3');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayDayOfYear = _dayOfYear(now);
    final lastCollectedDay = prefs.getInt('lastCollectedDay') ?? 0;

    if (lastCollectedDay == todayDayOfYear - 1) {
      _streak++;
    } else if (lastCollectedDay != todayDayOfYear) {
      _streak = 1;
    }

    await prefs.setInt('rewardStreak', _streak);
    await prefs.setInt('lastCollectedDay', todayDayOfYear);

    double baseChance = 0.2;
    double increment = 0.05;
    double maxChance = 0.3;
    double chance = (baseChance + _streak * increment).clamp(baseChance, maxChance);

    _isRare = Random().nextDouble() < chance;

    _lastRewardTime = now;
    await prefs.setInt('lastRewardTime', _lastRewardTime!.millisecondsSinceEpoch);

    // Show reward popup FIRST
    _showRewardPopup();

    // Then play sound and confetti
    _confettiController.play();
    _audioPlayer.play('assets/audios/sound_effects/victory2_SFX.mp3');
    _player.play("assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3");
    _player1.play("assets/audios/QuizGame_Sounds/whistleUkulele4Sec.mp3");

    widget.onRewardCollected(isRare: _isRare);

    _timeLeft = widget.cooldown;
    _startTimer();
    setState(() {});
  }


  void _showRewardPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.grey.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.7),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isRare ? "🌟 Rare Star Collected!" : "🎁 XP Collected!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _isRare ? Colors.cyanAccent : Colors.amber,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Lottie.asset(
                    _isRare ? 'assets/animations/GiftStar.json' : 'assets/animations/girl_jumping.json',
                    repeat: false,
                    height: 150,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRare ? Colors.cyanAccent : Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Text("Awesome!", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _dayOfYear(DateTime date) {
    final beginningOfYear = DateTime(date.year, 1, 1);
    return date.difference(beginningOfYear).inDays + 1;
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
    _audioPlayer.dispose();
    _player.dispose();
    _player1.dispose();
    super.dispose();
  }

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
          colors: const [Colors.amber, Colors.green, Colors.purple],
        ),
        GestureDetector(
          onTap: _collectReward,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isReady)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    _formatDuration(_timeLeft),
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: CircularProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      color: isReady ? Colors.amber : Colors.green,
                      strokeWidth: 5,
                    ),
                  ),
                  if (isReady)
                    Positioned.fill(
                      child: AnimatedRotation(
                        duration: const Duration(seconds: 5),
                        turns: 1,
                      ),
                    ),
                  SizedBox(
                    width: widget.size - 35,
                    height: widget.size - 35,
                    child: isReady
                        ? Lottie.asset(
                      _isRare ? widget.rareChestOpenAnimationAsset : widget.chestOpenAnimationAsset,
                      width: 70,
                      height: 70,
                      repeat: true,
                    )
                        : Image.asset(
                      _isRare ? widget.rareChestClosedAsset : widget.chestClosedAsset,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "🔥 Streak: $_streak",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
