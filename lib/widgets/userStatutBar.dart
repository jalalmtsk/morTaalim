import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/main.dart';
import 'package:provider/provider.dart';
import '../../XpSystem.dart';
import '../AppGlobal.dart';

class Userstatutbar extends StatefulWidget {
  const Userstatutbar({super.key});

  @override
  State<Userstatutbar> createState() => _UserStatutBar();
}

class _UserStatutBar extends State<Userstatutbar>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // STAR ANIMATION
  late AnimationController _starColorController;
  late Animation<Color?> _starColor;
  late AnimationController _starFloatController;
  int _starDelta = 0;
  bool _initialized = false;


  // STAR VALUE SLIDER
  late AnimationController _starValueController;
  late Animation<double> _starValueAnimation;
  double _displayedStars = 0;

  // TOKEN ANIMATION
  late AnimationController _tokenColorController;
  late Animation<Color?> _tokenColor;
  late AnimationController _tokenFloatController;
  int _tokenDelta = 0;

  // TOKEN VALUE SLIDER
  late AnimationController _tokenValueController;
  late Animation<double> _tokenValueAnimation;
  double _displayedTokens = 0;

  // XP ANIMATION
  late AnimationController _xpScaleController;
  late AnimationController _xpColorController;
  late Animation<double> _xpScale;
  late Animation<Color?> _xpColor;
  late AnimationController _xpFloatController;
  int _xpDelta = 0;

  // XP VALUE SLIDER
  late AnimationController _xpValueController;
  late Animation<double> _xpValueAnimation;
  double _displayedXP = 0;

  // BORDER FLASH
  Color _borderColor = Colors.transparent;

  final AudioPlayer _rewardSound = AudioPlayer();
  final AudioPlayer _coinSoundPlayer = AudioPlayer();

  bool showAvatarXp = true;

  int previousStars = 0;
  int previousTokens = 0;
  int previousXP = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _xpColor = AlwaysStoppedAnimation<Color?>(Colors.white);
    _starColor = AlwaysStoppedAnimation<Color?>(Colors.white);
    _tokenColor = AlwaysStoppedAnimation<Color?>(Colors.white);
    _initAnimations();

    // Prevent animations on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final xpManager = context.read<ExperienceManager>();
      previousStars = xpManager.stars;
      previousTokens = xpManager.saveTokenCount;
      previousXP = xpManager.xp;
      _displayedStars = previousStars.toDouble();
      _displayedTokens = previousTokens.toDouble();
      _displayedXP = previousXP.toDouble();
      setState(() => _initialized = true); // ✅ Mark initialized
    });
  }



  void _initAnimations() {
    // Stars
    _starColorController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _starFloatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _starValueController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _starValueAnimation = Tween<double>(begin: 0, end: 0).animate(_starValueController)
      ..addListener(() => setState(() => _displayedStars = _starValueAnimation.value));
    _starColor = AlwaysStoppedAnimation<Color?>(Colors.white);

    // Tokens
    _tokenColorController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _tokenFloatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _tokenValueController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _tokenValueAnimation = Tween<double>(begin: 0, end: 0).animate(_tokenValueController)
      ..addListener(() => setState(() => _displayedTokens = _tokenValueAnimation.value));
    _tokenColor = AlwaysStoppedAnimation<Color?>(Colors.white);

    // XP
    _xpScaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _xpScale = Tween<double>(begin: 1.0, end: 1.4).animate(CurvedAnimation(parent: _xpScaleController, curve: Curves.easeOut));
    _xpColorController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _xpFloatController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _xpColor = AlwaysStoppedAnimation<Color?>(Colors.white); // ✅ FIX

    // XP VALUE SLIDER
    _xpValueController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _xpValueAnimation = Tween<double>(begin: 0, end: 0).animate(_xpValueController)
      ..addListener(() => setState(() => _displayedXP = _xpValueAnimation.value));
  }


  void _flashBorder(Color color) {
    setState(() => _borderColor = color);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _borderColor = Colors.transparent);
    });
  }

  Future<void> _playIncrementSound(int delta) async {
    if (delta > 0) {
      for (int i = 0; i < delta; i++) {
        try {
          await _coinSoundPlayer.setAsset('assets/sounds/coin.mp3'); // Your coin sound file
          _coinSoundPlayer.play();
          await Future.delayed(const Duration(milliseconds: 80)); // Small delay between sounds
        } catch (_) {}
      }
    }
  }

  void _triggerStarAnimation(bool increased, int delta, int newStars) {
    _starDelta = delta;
    _starColor = ColorTween(begin: Colors.white, end: increased ? Colors.yellowAccent : Colors.redAccent)
        .animate(_starColorController);
    _starColorController.forward(from: 0).then((_) => _starColorController.reverse());
    _starFloatController.forward(from: 0);

    _starValueAnimation = Tween<double>(begin: _displayedStars, end: newStars.toDouble())
        .animate(CurvedAnimation(parent: _starValueController, curve: Curves.easeOut));
    _starValueController.forward(from: 0);

    _flashBorder(increased ? Colors.yellow : Colors.red);

    if (increased) _playIncrementSound(delta);
  }

  void _triggerTokenAnimation(bool increased, int delta, int newTokens) {
    _tokenDelta = delta;
    _tokenColor = ColorTween(begin: Colors.white, end: increased ? Colors.greenAccent : Colors.redAccent)
        .animate(_tokenColorController);
    _tokenColorController.forward(from: 0).then((_) => _tokenColorController.reverse());
    _tokenFloatController.forward(from: 0);

    _tokenValueAnimation = Tween<double>(begin: _displayedTokens, end: newTokens.toDouble())
        .animate(CurvedAnimation(parent: _tokenValueController, curve: Curves.easeOut));
    _tokenValueController.forward(from: 0);

    _flashBorder(increased ? Colors.green : Colors.red);

    if (increased) _playIncrementSound(delta);
  }

  void _triggerXPAnimation(bool increased, int delta, int newXP) {
    _xpDelta = delta;
    _xpScaleController.forward(from: 0).then((_) => _xpScaleController.reverse());
    _xpColor = ColorTween(begin: Colors.white, end: increased ? Colors.cyanAccent : Colors.redAccent)
        .animate(_xpColorController);
    _xpColorController.forward(from: 0).then((_) => _xpColorController.reverse());
    _xpFloatController.forward(from: 0);

    _xpValueAnimation = Tween<double>(begin: _displayedXP, end: newXP.toDouble()).animate(
      CurvedAnimation(parent: _xpValueController, curve: Curves.easeOut),
    );
    _xpValueController.forward(from: 0);

    _flashBorder(increased ? Colors.cyan : Colors.red);
  }

  Widget _buildFloatingLabel(AnimationController controller, int delta, Color color) {
    if (controller.isDismissed || delta == 0) return const SizedBox();

    final offsetAnimation = Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0, -1))
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    final opacityAnimation = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    return SlideTransition(
      position: offsetAnimation,
      child: FadeTransition(
        opacity: opacityAnimation,
        child: Text(
          "${delta > 0 ? "+" : ""}$delta",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: const [Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2)],
          ),
        ),
      ),
    );
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
            child: SizedBox(width: 30, height: 30, child: Lottie.asset('assets/animations/LvlUnlocked/LevelUp.json', repeat: false)),
          ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _starColorController.dispose();
    _starFloatController.dispose();
    _starValueController.dispose();
    _tokenColorController.dispose();
    _tokenFloatController.dispose();
    _tokenValueController.dispose();
    _xpScaleController.dispose();
    _xpColorController.dispose();
    _xpFloatController.dispose();
    _xpValueController.dispose();
    _rewardSound.dispose();
    _coinSoundPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);

    if (_initialized) {
      if (xpManager.stars != previousStars) {
        final delta = xpManager.stars - previousStars;
        previousStars = xpManager.stars;
        _triggerStarAnimation(delta > 0, delta, xpManager.stars);
      }

      if (xpManager.saveTokenCount != previousTokens) {
        final delta = xpManager.saveTokenCount - previousTokens;
        previousTokens = xpManager.saveTokenCount;
        _triggerTokenAnimation(delta > 0, delta, xpManager.saveTokenCount);
      }

      if (xpManager.xp != previousXP) {
        final delta = xpManager.xp - previousXP;
        previousXP = xpManager.xp;
        _triggerXPAnimation(delta > 0, delta, xpManager.xp);
      }
    }


    final showSparkle = xpManager.recentlyAddedStars > 0 || xpManager.recentlyAddedTokens > 0;
    int currentLevelXP = xpManager.currentLevelXP;
    int requiredXPForNextLevel = xpManager.requiredXPForNextLevel;

    return GestureDetector(
      onTap: () {
        audioManager.playEventSound("PopButton");
        setState(() => showAvatarXp = !showAvatarXp);
      },
      child: Container(
        margin: const EdgeInsets.all(10),
        height: 86,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor, width: 5),
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
                color: Colors.black.withOpacity(0.25),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: showAvatarXp
                  ? Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    radius: 22,
                    child: _buildAvatar(xpManager.selectedAvatar, showSparkle),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Level ${xpManager.level}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                        const SizedBox(height: 4),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            LinearProgressIndicator(
                              value: xpManager.levelProgress,
                              backgroundColor: Colors.white24,
                              color: Colors.deepOrange,
                              minHeight: 8,
                            ),
                            Positioned(
                              top: -12,
                              left: 0,
                              child: _buildFloatingLabel(_xpFloatController, _xpDelta, Colors.cyanAccent),
                            ),
                          ],
                        ),
                        AnimatedBuilder(
                          animation: Listenable.merge([_xpValueController, _xpColorController]),
                          builder: (_, __) {
                            final displayedXPInt = _displayedXP.toInt();
                            return Text(
                              "$displayedXPInt / $requiredXPForNextLevel XP",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: _xpColor.value ?? Colors.white,
                                shadows: const [
                                  Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 22),
                              const SizedBox(width: 6),
                              AnimatedBuilder(
                                animation: _starColorController,
                                builder: (_, __) => Text(
                                  "${_displayedStars.toInt()}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _starColor.value ?? Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            top: -18,
                            right: -24,
                            child: _buildFloatingLabel(_starFloatController, _starDelta, Colors.yellowAccent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.generating_tokens, color: Colors.green, size: 22),
                              const SizedBox(width: 2),
                              AnimatedBuilder(
                                animation: _tokenColorController,
                                builder: (_, __) => Text(
                                  "${_displayedTokens.toInt()}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _tokenColor.value ?? Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            top: -18,
                            right: -24,
                            child: _buildFloatingLabel(_tokenFloatController, _tokenDelta, Colors.greenAccent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              )
                  : Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white10,
                      child: _buildAvatar(xpManager.selectedAvatar, showSparkle),
                    ),
                    const SizedBox(width: 14),
                    AnimatedBuilder(
                      animation: Listenable.merge([_xpScaleController, _xpColorController]),
                      builder: (_, __) {
                        final scale = 1 + (_xpScaleController.value * 0.4);
                        return Transform.scale(
                          scale: scale,
                          child: Text(
                            "$currentLevelXP / $requiredXPForNextLevel XP",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: _xpColor.value ?? Colors.white,
                              shadows: const [
                                Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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
