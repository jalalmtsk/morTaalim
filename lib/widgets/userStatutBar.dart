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

  bool showAvatarXp = true; // controls which UI to show

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

    _tokenScaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400), lowerBound: 1.0, upperBound: 1.3);

    _starFlashController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _starColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.yellowAccent.withOpacity(0.5),
    ).animate(CurvedAnimation(parent: _starFlashController, curve: Curves.easeInOut));

    _starScaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400), lowerBound: 1.0, upperBound: 1.3);
  }

  Future<void> _loadLastRewardTime() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt('lastRewardTime');
    if (millis != null) {
      _lastRewardTime = DateTime.fromMillisecondsSinceEpoch(millis);

      // If last reward time was too long ago (e.g., more than rewardCooldown + some buffer),
      // reset it to now - rewardCooldown so user can get reward immediately.
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
    print('[Timer] Starting reward timer...');
    _cancelTimer();

    _rewardTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeLeft();
    });
  }

  void _cancelTimer() {
    if (_rewardTimer != null) {
      _rewardTimer!.cancel();
      _rewardTimer = null;
      print('[Timer] Reward timer canceled.');
    }
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('[Lifecycle] State changed to: $state');

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      print('[Lifecycle] App paused/inactive, resetting reward timer.');
      _cancelTimer();

      // Reset last reward time to now, so timer restarts fresh on resume
      _lastRewardTime = DateTime.now();
      _saveRewardTime(); // Save reset time to persistent storage

      setState(() {
        _timeLeft = rewardCooldown;
      });

    } else if (state == AppLifecycleState.resumed) {
      print('[Lifecycle] App resumed, starting timer fresh.');
      _startTimer();
    }
  }

  Widget _buildAvatar(String avatarPath) {
    if (avatarPath.endsWith('.json')) {
      // It's a Lottie animation
      return SizedBox(
        width: 40,
        height: 40,
        child: Lottie.asset(
          avatarPath,
          fit: BoxFit.cover,
          repeat: true,
        ),
      );
    } else if (avatarPath.contains('assets/')) {
      // It's an image asset
      return Image.asset(
        avatarPath,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      );
    } else {
      // It's a text-based emoji avatar
      return Center(
        child: Text(
          avatarPath,
          style: const TextStyle(fontSize: 22),
        ),
      );
    }
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

    return GestureDetector(
      onLongPress: () => Navigator.of(context).pushNamed("Shop"),
      onTap: () => setState(() => showAvatarXp = !showAvatarXp),
      child: Container(
        margin: const EdgeInsets.all(10),
        height: 60,
        child: Stack(
          children: [
            // 🖼️ Background image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                xpManager.selectedBannerImage, // ✅ Change to any user-selected image
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // 🎨 Semi-transparent overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withOpacity(0.2),
              ),
            ),


            // 🔤 Content (XP or Timer)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
              child: showAvatarXp
                  ? Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    radius: 20,
                    child: ClipOval(
                      child: _buildAvatar(xpManager.selectedAvatar),
                    ),
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
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        LinearProgressIndicator(
                          value: xpManager.levelProgress,
                          backgroundColor: Colors.white24,
                          color: Colors.deepOrange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ⭐ Stars
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    decoration: BoxDecoration(
                      color: _starColorAnimation.value,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          Row(children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 1),
                            Text("${xpManager.stars}",
                              style: const TextStyle(
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      offset: Offset(1, 1),
                                      blurRadius: 3,
                                    )
                                  ],
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],),

                          Row(children: [
                             Row(
                                children: [
                                  const Icon(Icons.generating_tokens_rounded,
                                      color: Colors.green, size: 20),
                                  const SizedBox(width: 2),
                                  Text("${xpManager.saveTokenCount}",
                                      style: const TextStyle(
                                          shadows: [
                                            Shadow(
                                              color: Colors.black87,
                                              offset: Offset(1, 1),
                                              blurRadius: 3,
                                            )
                                          ],
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                ],
                              ),

                          ],)

                        ],),
                        SizedBox(width: 10),
                      ],

                    ),

                  ),
                  const SizedBox(width: 8),
                  // 🟢 Tokens
                ],
              )
                  : Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    const Icon(Icons.timer_outlined, color: Colors.white),
                    const SizedBox(width: 8),
                    Text("Next Reward: ${_formatDuration(_timeLeft)}",
                        style: const TextStyle(
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              )
                            ],
                            fontWeight: FontWeight.w600, color: Colors.white)),
                    const Spacer(),
                    // Same stars & tokens UI
                    // ...
                                    ],
                                  ),
                  ),
            ),
          ],
        ),
      ),
    );

  }
}
