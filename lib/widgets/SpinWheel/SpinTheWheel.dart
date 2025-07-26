import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';
import 'WheelUI.dart';

class SpinWheelPopup extends StatefulWidget {
  const SpinWheelPopup({Key? key}) : super(key: key);

  @override
  State<SpinWheelPopup> createState() => _SpinWheelPopupState();
}

class _SpinWheelPopupState extends State<SpinWheelPopup> with TickerProviderStateMixin {
  bool _canSpin = false;
  Duration _timeLeft = Duration.zero;
  Timer? _countdownTimer;
  late AnimationController _controller;
  late Animation<double> _animation;
  int _selectedIndex = 0;

  final List<String> _rewards = [
    'XP +10',
    'XP +20',
    'Tolim +2',
    'XP +5',
    'Try Again',
    'Star +1',
    'Nothing',
    'Star +2',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 4), vsync: this);

    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
    _checkSpinAvailability();
  }

  Future<void> _checkSpinAvailability() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSpinTimeMillis = prefs.getInt('lastSpinTime');
    final currentTime = DateTime.now();

    if (lastSpinTimeMillis != null) {
      final lastSpinTime = DateTime.fromMillisecondsSinceEpoch(lastSpinTimeMillis);
      final nextAvailableSpinTime = lastSpinTime.add(const Duration(hours: 24));
      final difference = nextAvailableSpinTime.difference(currentTime);

      if (difference.isNegative) {
        setState(() {
          _canSpin = true;
          _timeLeft = Duration.zero;
        });
      } else {
        setState(() {
          _canSpin = false;
          _timeLeft = difference;
        });
        _startCountdown();
      }
    } else {
      setState(() {
        _canSpin = true;
        _timeLeft = Duration.zero;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft.inSeconds <= 1) {
        timer.cancel();
        setState(() {
          _canSpin = true;
          _timeLeft = Duration.zero;
        });
      } else {
        setState(() {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        });
      }
    });
  }

  void _spinWheel() {
    if (!_canSpin || _controller.isAnimating) return;

    final random = Random();
    _selectedIndex = random.nextInt(_rewards.length);
    final double spinDegrees = 5 * 360 + (_selectedIndex * (360 / _rewards.length));

    _animation = Tween<double>(begin: 0, end: spinDegrees).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    )
      ..addStatusListener((status) async {
        if (status == AnimationStatus.completed) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('lastSpinTime', DateTime.now().millisecondsSinceEpoch);

          setState(() {
            _canSpin = false;
            _timeLeft = const Duration(hours: 24);
          });
          _startCountdown();

          _applyReward(_rewards[_selectedIndex]);
          _showResultDialog(_rewards[_selectedIndex]);
        }
      });

    _controller.reset();
    _controller.forward();
  }

  void _showResultDialog(String reward) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🎉 You Won!'),
        content: Text('Reward: $reward'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  Future<void> _rerollWithAd() async {
    await AdHelper.showRewardedAdWithLoading(context, () {
      setState(() {
        _canSpin = true;
        _timeLeft = Duration.zero;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎁 Free spin unlocked!')),
      );
    });
  }

  void _applyReward(String reward) {
    if (reward.startsWith('XP +')) {
      final xpAmount = int.tryParse(reward.substring(4)) ?? 0;
      if (xpAmount > 0) {
        Provider.of<ExperienceManager>(context, listen: false).addXP(xpAmount, context: context);
        _showSnackBar('You earned $xpAmount XP!');
      }
    } else if (reward.startsWith('Tolim +')) {
      final tolimAmount = int.tryParse(reward.substring(7)) ?? 0;
      if (tolimAmount > 0) {
        Provider.of<ExperienceManager>(context, listen: false).addTokens(tolimAmount);
        _showSnackBar('You earned $tolimAmount Tolims!');
      }
    } else if (reward.startsWith('Star +')) {
      final starAmount = int.tryParse(reward.substring(6)) ?? 0;
      if (starAmount > 0) {
        Provider.of<ExperienceManager>(context, listen: false).addStars(starAmount);
        _showSnackBar('You earned $starAmount Star${starAmount > 1 ? 's' : ''}!');
      }
    } else if (reward == 'Try Again') {
      _showSnackBar('Try again!');
    } else if (reward == 'Nothing') {
      _showSnackBar('No reward this time.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wheelRadius = 120.0;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 350,
        constraints: BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "🎁 Daily Reward",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              if (!_canSpin)
                Text(
                  "Come back in: ${_formatDuration(_timeLeft)}",
                  style: const TextStyle(fontSize: 18, color: Colors.red),
                )
              else
                const Text(
                  "You're ready to spin!",
                  style: TextStyle(fontSize: 18, color: Colors.green),
                ),

              const SizedBox(height: 20),

              Stack(
                alignment: Alignment.center,
                children: [
                  // Spinning Wheel
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, child) {
                      return Transform.rotate(
                        angle: _animation.value * pi / 180,
                        child: child,
                      );
                    },
                    child: CustomPaint(
                      painter: WheelPainter(_rewards),
                      size: Size(wheelRadius * 2, wheelRadius * 2),
                    ),
                  ),

                  // Pointer
                  Positioned(
                    top: wheelRadius * 0.05,
                    child: CustomPaint(
                      size: const Size(30, 30),
                      painter: TrianglePointerPainter(),
                    ),
                  ),
                ],
              ),


              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _canSpin && !_controller.isAnimating ? _spinWheel : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSpin ? Colors.green : Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  "SPIN",
                  style: TextStyle(fontSize: 20),
                ),
              ),

              const SizedBox(height: 16),

              if (!_canSpin)
                ElevatedButton.icon(
                  onPressed: _rerollWithAd,
                  icon: const Icon(Icons.refresh),
                  label: const Text("REROLL (Watch Ad)"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}


