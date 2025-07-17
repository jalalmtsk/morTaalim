import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RewardChest extends StatefulWidget {
  final Duration cooldown;
  final VoidCallback onRewardCollected;
  final String chestClosedAsset;
  final String chestOpenAnimationAsset;
  final double size;

  const RewardChest({
    super.key,
    required this.cooldown,
    required this.onRewardCollected,
    required this.chestClosedAsset,
    required this.chestOpenAnimationAsset,
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

  @override
  void initState() {
    super.initState();
    _loadRewardTime();
  }

  Future<void> _loadRewardTime() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt('lastRewardTime');
    final now = DateTime.now();

    if (millis != null) {
      _lastRewardTime = DateTime.fromMillisecondsSinceEpoch(millis);
      final nextRewardTime = _lastRewardTime!.add(widget.cooldown);
      _timeLeft = nextRewardTime.difference(now);
    } else {
      _lastRewardTime = now.subtract(widget.cooldown);
      _timeLeft = Duration.zero;
    }

    _startTimer();
    setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final nextReward = _lastRewardTime!.add(widget.cooldown);
    final diff = nextReward.difference(now);

    if (diff <= Duration.zero) {
      _timeLeft = Duration.zero;
    } else {
      _timeLeft = diff;
    }

    setState(() {});
  }

  Future<void> _collectReward() async {
    if (!isReady) return;
    final prefs = await SharedPreferences.getInstance();
    _lastRewardTime = DateTime.now();
    await prefs.setInt('lastRewardTime', _lastRewardTime!.millisecondsSinceEpoch);
    widget.onRewardCollected();
    _timeLeft = widget.cooldown;
    _startTimer();
    setState(() {});
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1.0 - (_timeLeft.inSeconds / widget.cooldown.inSeconds).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: isReady ? _collectReward : null,
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


              SizedBox(
                width: widget.size - 35,
                height: widget.size - 35,
                child: isReady
                    ? Lottie.asset(widget.chestOpenAnimationAsset,
                    width: 70, height: 70,
                    repeat: true)
                    : Image.asset(widget.chestClosedAsset),
              ),
            ],
          ),

        ],
      ),
    );
  }
}
