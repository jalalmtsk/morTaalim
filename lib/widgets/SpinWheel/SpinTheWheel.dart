import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';

import '../../XpSystem.dart';
import '../../main.dart';
import '../../tools/Ads_Manager.dart';
import '../../tools/audio_tool.dart';
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
  late ConfettiController _confettiController;
  final MusicPlayer audioTool = MusicPlayer();
  final MusicPlayer audioTool1 = MusicPlayer();
  final MusicPlayer audioTool2 = MusicPlayer();
  int _selectedIndex = 0;

  final List<String> _rewards = [
    'Star +1',
    'Nothing',
    'Star +2',
    'XP +10',
    'XP +20',
    'Tolim +2',
    'XP +5',
    'Try Again',
  ];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(seconds: 4), vsync: this);
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _checkSpinAvailability();
  }

  Future<void> _checkSpinAvailability() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSpinTimeMillis = prefs.getInt('lastSpinTime');
    final currentTime = DateTime.now();

    if (lastSpinTimeMillis != null) {
      final lastSpinTime = DateTime.fromMillisecondsSinceEpoch(
          lastSpinTimeMillis);
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

  bool _dialogShown = false;

  void _spinWheel() {
    if (!_canSpin || _controller.isAnimating) return;

    _dialogShown = false;

    final random = Random();
    _selectedIndex = random.nextInt(_rewards.length);
    final anglePerReward = 360 / _rewards.length;

    // ✅ Align selected reward to pointer at bottom (180°)
    final double spinDegrees = 5 * 360 + 180 -
        (_selectedIndex * anglePerReward + anglePerReward / 2);

    audioTool.play("assets/audios/sound_effects/spin.mp3");

    _animation = Tween<double>(begin: 0, end: spinDegrees).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    )
      ..addStatusListener((status) async {
        if (status == AnimationStatus.completed && !_dialogShown) {
          _dialogShown = true;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('lastSpinTime', DateTime
              .now()
              .millisecondsSinceEpoch);

          setState(() {
            _canSpin = false;
            _timeLeft = const Duration(hours: 24);
          });

          _startCountdown();
          _applyReward(_rewards[_selectedIndex]);

          // 🎉 Show reward
          audioTool.play("assets/audios/sound_effects/victory2.mp3");
          audioTool1.play("assets/audios/sound_effects/unlock_sound.mp3");
          audioTool2.play(
              "assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3");
          _confettiController.play();
          _showResultDialog(_rewards[_selectedIndex]);
        }
      });

    _controller.reset();
    _controller.forward();
  }


  void _showResultDialog(String reward) {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title:  Text('🎉 ${tr(context).congratulations}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    Icons.emoji_events, color: Colors.amber.shade700, size: 40),
                const SizedBox(height: 10),
                Text('${tr(context).youWon} : $reward', style: const TextStyle(fontSize: 18)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child:  Text('${tr(context).awesome} !'),
              ),
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
         SnackBar(content: Text('🎁 ${tr(context).freeSpinUnlocked}!')),
      );
    });
  }

  void _applyReward(String reward) {
    if (reward.startsWith('XP +')) {
      final xpAmount = int.tryParse(reward.substring(4)) ?? 0;
      Provider.of<ExperienceManager>(context, listen: false).addXP(
          xpAmount, context: context);
      _showSnackBar('${tr(context).youEarned} $xpAmount XP!');
    } else if (reward.startsWith('Tolim +')) {
      final tolimAmount = int.tryParse(reward.substring(7)) ?? 0;
      Provider.of<ExperienceManager>(context, listen: false).addTokenBanner(
          context, tolimAmount);
      _showSnackBar('${tr(context).youEarned} $tolimAmount Tolims!');
    } else if (reward.startsWith('Star +')) {
      final starAmount = int.tryParse(reward.substring(6)) ?? 0;
      Provider.of<ExperienceManager>(context, listen: false).addStarBanner(
          context, starAmount);
      _showSnackBar('${tr(context).youEarned}  $starAmount Star${starAmount > 1 ? 's' : ''}!');
    } else if (reward == 'Try Again') {
      _showSnackBar('${tr(context).tryAgain} ');
    } else if (reward == 'Nothing') {
      _showSnackBar('${tr(context).noRewardThisTime}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wheelRadius = 120.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // 🎉 Background Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF141E30), Color(0xFF243B55)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // 🎉 Confetti
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          emissionFrequency: 0.05,
          numberOfParticles: 30,
          gravity: 0.3,
        ),

        // 🎡 Wheel popup UI
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 360,
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white.withOpacity(0.15),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
              // Glass effect
              backgroundBlendMode: BlendMode.overlay,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       Text(
                        "🎁 ${tr(context).dailySpin}",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (!_canSpin)
                        Text(
                          "${tr(context).comeBackIn}: ${_formatDuration(_timeLeft)}",
                          style: const TextStyle(fontSize: 16, color: Colors
                              .redAccent),
                        )
                      else
                         Text(
                          "${tr(context).youreReadyToSpin}!",
                          style: TextStyle(fontSize: 16, color: Colors
                              .greenAccent),
                        ),

                      const SizedBox(height: 20),

                      Stack(
                        alignment: Alignment.center,
                        children: [
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
                          Positioned(
                            left: 0,
                            child: Transform.rotate(
                              angle: pi / 2,
                              child: CustomPaint(
                                size: const Size(25, 25),
                                painter: TrianglePointerPainter(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Glowing Spin Button
                      GestureDetector(
                        onTap: _canSpin && !_controller.isAnimating
                            ? _spinWheel
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          padding: const EdgeInsets.symmetric(horizontal: 40,
                              vertical: 16),
                          decoration: BoxDecoration(
                            gradient: _canSpin
                                ? const LinearGradient(
                              colors: [Color(0xFF56ab2f), Color(0xFFa8e063)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                                : const LinearGradient(
                              colors: [Colors.grey, Colors.grey],
                            ),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: _canSpin
                                ? [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.6),
                                blurRadius: 20,
                                spreadRadius: 1,
                              ),
                            ]
                                : [],
                          ),
                          child:  Text(
                            tr(context).spin,
                            style: TextStyle(fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (!_canSpin)
                        ElevatedButton.icon(
                          onPressed: _rerollWithAd,
                          icon: const Icon(Icons.refresh),
                          label:  Text("${tr(context).reroll} (${tr(context).watchAd})"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  String _formatDuration(Duration duration) {
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
