import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

/// Onboarding page 1 — "Welcome to your new Adventure".
///
/// The language hasn't been chosen yet, so the title and button cycle
/// through every supported language.
class WelcomePage extends StatefulWidget {
  final VoidCallback onGetStarted;

  const WelcomePage({Key? key, required this.onGetStarted}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  static const _titles = <(String, String, TextDirection)>[
    ('Welcome to your\nnew Adventure', "Let's go", TextDirection.ltr),
    ('Bienvenue dans ta\nnouvelle aventure', "C'est parti", TextDirection.ltr),
    ('مرحبًا بك في\nمغامرتك الجديدة', 'هيا بنا', TextDirection.rtl),
    ('ⴰⵏⵙⵓⴼ ⵙ ⵓⵎⵓⵔⴰⵔ\nⵏⵏⴽ ⴰⵎⴰⵢⵏⵓ', 'ⴱⴷⵓ', TextDirection.ltr),
    ('Willkommen zu deinem\nneuen Abenteuer', "Los geht's", TextDirection.ltr),
  ];

  static const List<String> _assets = [
    KidAssets.welcomeBg,
    KidAssets.wordmark,
    KidAssets.mascotWalk,
    KidAssets.blocksAbc,
    KidAssets.blocks123,
    KidAssets.globe2,
    KidAssets.star2,
  ];

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final AnimationController _jump =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 650));

  Timer? _cycle;
  int _index = 0;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playAlert("assets/audios/sound_effects/WelcomeSoundPage.mp3");
    audioManager.playBackgroundMusic("assets/audios/BackGround_Audio/FunnyDogUserInfo_bg.mp3");
    _cycle = Timer.periodic(const Duration(milliseconds: 3600), (_) {
      if (mounted) setState(() => _index = (_index + 1) % _titles.length);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      KidAssets.precache(context, _assets);
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) _intro.forward();
      });
    }
  }

  @override
  void dispose() {
    _cycle?.cancel();
    _intro.dispose();
    _idle.dispose();
    _jump.dispose();
    super.dispose();
  }

  void _onMascotTap() {
    if (_jump.isAnimating) return;
    Provider.of<AudioManager>(context, listen: false).playEventSound('PopButton');
    _jump.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final g = KidSceneGeometry(size);
    final headerShift = max(0.0, pad.top + 6 - g.y(62));
    final t = _titles[_index];

    SceneSprite sprite(String asset, double l, double top, double w, double aspect,
            {double from = 0.2,
            double to = 0.7,
            double bob = 0,
            double sway = 0,
            double rot = 0,
            double phase = 0,
            int speed = 1,
            bool twinkle = false,
            Animation<double>? jump,
            VoidCallback? onTap}) =>
        SceneSprite(
          g: g,
          asset: asset,
          left: l,
          top: top,
          width: w,
          aspect: aspect,
          idle: _idle,
          intro: _intro,
          introFrom: from,
          introTo: to,
          bob: bob,
          sway: sway,
          rot: rot,
          phase: phase,
          speed: speed,
          twinkle: twinkle,
          jump: jump,
          onTap: onTap,
        );

    return Scaffold(
      backgroundColor: KidColors.sky,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          KidSceneBackground(asset: KidAssets.welcomeBg, g: g),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: [
                sprite(KidAssets.globe2, 586, 416, 154, 1.2218,
                    from: 0.3, to: 0.75, bob: 10, rot: 0.04, phase: 0.6),
                sprite(KidAssets.blocksAbc, 6, 543, 243, 0.9712,
                    from: 0.35, to: 0.8, bob: 8, rot: 0.03, phase: 0.2),
                sprite(KidAssets.blocks123, 672, 858, 232, 0.9621,
                    from: 0.4, to: 0.85, bob: 7, rot: 0.03, phase: 0.75),
                sprite(KidAssets.mascotWalk, 180, 438, 425, 1.6736,
                    from: 0.1, to: 0.6, bob: 10, rot: 0.025, phase: 0.4,
                    jump: _jump, onTap: _onMascotTap),
                Positioned(
                  left: 0,
                  right: 0,
                  top: headerShift,
                  height: g.y(200),
                  child: Stack(children: [
                    sprite(KidAssets.wordmark, 272, 62, 398, 0.2289,
                        from: 0.0, to: 0.45, bob: 4, phase: 0.1),
                  ]),
                ),
                sprite(KidAssets.star2, 726, 130, 50, 1.08,
                    from: 0.5, to: 0.9, twinkle: true, phase: 0.1, speed: 2),
                sprite(KidAssets.star2, 36, 212, 38, 1.08,
                    from: 0.55, to: 0.95, twinkle: true, phase: 0.5, speed: 2),
                sprite(KidAssets.star2, 494, 428, 44, 1.08,
                    from: 0.6, to: 1.0, twinkle: true, phase: 0.8, speed: 3),
              ],
            ),
          ),

          // ── Title (cycles through languages) ───────────────────────────
          Positioned(
            left: g.visibleLeft + 16,
            width: g.visibleWidth - 32,
            top: g.y(190) + headerShift * 0.5,
            height: g.l(215),
            child: KidIntro(
              intro: _intro,
              from: 0.25,
              to: 0.75,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 550),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(a), child: child),
                ),
                child: Center(
                  key: ValueKey(_index),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      t.$1,
                      textAlign: TextAlign.center,
                      textDirection: t.$3,
                      style: kidTitleStyle(g.lc(92, 28, 48)),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Button ─────────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            top: min(g.y(1352), size.height - pad.bottom - g.lc(150, 52, 76) - 56),
            child: KidIntro(
              intro: _intro,
              from: 0.5,
              to: 1.0,
              child: Center(
                child: KidButton(
                  label: t.$2,
                  width: g.contentWidth(750, pad: 24),
                  height: g.lc(150, 52, 76),
                  onPressed: () {
                    audioManager.playEventSound("clickButton");
                    widget.onGetStarted();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
