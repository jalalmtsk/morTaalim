import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../XpSystem.dart';

class Userstatutbar extends StatefulWidget {
  const Userstatutbar({super.key});

  @override
  State<Userstatutbar> createState() => _UserStatutBar();
}

class _UserStatutBar extends State<Userstatutbar> with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _tokenFlashController;
  late Animation<Color?> _tokenColorAnimation;
  late AnimationController _tokenScaleController;

  late AnimationController _starFlashController;
  late Animation<Color?> _starColorAnimation;
  late AnimationController _starScaleController;

  final AudioPlayer _rewardSound = AudioPlayer();
  Timer? _rewardTimer;
  Duration _timeLeft = const Duration();
  DateTime? _lastRewardTime;

  static const rewardCooldown = Duration(minutes: 30);
  bool showAvatarXp = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAnimationControllers();
    _loadLastRewardTime();
    _startTimer();
  }

  void _initAnimationControllers() {
    _tokenFlashController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _tokenColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.greenAccent.withOpacity(0.5),
    ).animate(CurvedAnimation(parent: _tokenFlashController, curve: Curves.easeInOut));

    _tokenScaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400), lowerBound: 1.0, upperBound: 1.3);

    _starFlashController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _starColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.yellowAccent.withOpacity(0.5),
    ).animate(CurvedAnimation(parent: _starFlashController, curve: Curves.easeInOut));

    _starScaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400), lowerBound: 1.0, upperBound: 1.3);
  }

  Future<void> _loadLastRewardTime() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt('lastRewardTime');
    if (millis != null) {
      _lastRewardTime = DateTime.fromMillisecondsSinceEpoch(millis);
      final now = DateTime.now();
      if (now.difference(_lastRewardTime!) > rewardCooldown + Duration(minutes: 5)) {
        _lastRewardTime = now.subtract(rewardCooldown);
        await _saveRewardTime();
      }
      _updateTimeLeft();
    } else {
      _lastRewardTime = DateTime.now().subtract(rewardCooldown);
    }
  }

  Future<void> _saveRewardTime() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('lastRewardTime', DateTime.now().millisecondsSinceEpoch);
  }

  void _startTimer() {
    _cancelTimer();
    _rewardTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeLeft();
    });
  }

  void _cancelTimer() {
    _rewardTimer?.cancel();
    _rewardTimer = null;
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    final nextRewardTime = (_lastRewardTime ?? now).add(rewardCooldown);
    final remaining = nextRewardTime.difference(now);

    if (remaining <= Duration.zero) {
      _giveReward();
      _lastRewardTime = DateTime.now();
      _saveRewardTime();
      setState(() {
        _timeLeft = rewardCooldown;
      });
    } else {
      setState(() {
        _timeLeft = remaining;
      });
    }
  }

  void _giveReward() {
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    xpManager.addTokens(2);
    xpManager.addStars(1);
    _tokenFlashController.forward(from: 0.0);
    _starFlashController.forward(from: 0.0);
    _tokenScaleController.forward(from: 0.0);
    _starScaleController.forward(from: 0.0);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Widget _buildAvatar(String avatarPath, bool showSparkle) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipOval(
          child: avatarPath.endsWith('.json')
              ? Lottie.asset(avatarPath, fit: BoxFit.cover, repeat: true, width: 40, height: 40)
              : (avatarPath.contains('assets/')
              ? Image.asset(avatarPath, width: 40, height: 40, fit: BoxFit.cover)
              : Text(avatarPath, style: const TextStyle(fontSize: 22))),
        ),
        if (showSparkle)
          Positioned(
            top: -10,
            right: -3,
            child: SizedBox(
              width: 30,
              height: 30,
              child: Lottie.asset('assets/animations/AnimatedAvatars/Trophy.json', repeat: false),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimer();
    _tokenFlashController.dispose();
    _tokenScaleController.dispose();
    _starFlashController.dispose();
    _starScaleController.dispose();
    _rewardSound.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final showSparkle = xpManager.recentlyAddedStars > 0 || xpManager.recentlyAddedTokens > 0;

    return GestureDetector(
      onLongPress: () => Navigator.of(context).pushNamed("Shop"),
      onTap: () => setState(() => showAvatarXp = !showAvatarXp),
      child: Container(
        margin: const EdgeInsets.all(10),
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: showSparkle ? Colors.green : Colors.transparent,
            width: 5,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                xpManager.selectedBannerImage,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withOpacity(0.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
              child: showAvatarXp
                  ? Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    radius: 20,
                    child: _buildAvatar(xpManager.selectedAvatar, showSparkle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Level ${xpManager.level}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 3)],
                          ),
                        ),                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                blurRadius: 6,
                                spreadRadius: showSparkle ? 2 : 0,
                              )
                            ],
                          ),
                          child: LinearProgressIndicator(
                            value: xpManager.levelProgress,
                            backgroundColor: Colors.white24,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(" ${xpManager.stars}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(width: 8),
                      Icon(Icons.generating_tokens, color: Colors.green, size: 20),
                      Text(" ${xpManager.saveTokenCount}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  )
                ],
              )
                  : Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.white),
                    const SizedBox(width: 8),
                    Text("Next Reward: ${_formatDuration(_timeLeft)}", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    const Spacer(),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
