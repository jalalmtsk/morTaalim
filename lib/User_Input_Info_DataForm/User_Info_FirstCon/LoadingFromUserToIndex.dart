import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/IndexPage.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';

/// Shown once after onboarding: "Creating your adventure…", then Index.
class LoadingFromUserToIndex extends StatefulWidget {
  const LoadingFromUserToIndex({Key? key}) : super(key: key);

  @override
  State<LoadingFromUserToIndex> createState() => _LoadingFromUserToIndexState();
}

class _LoadingFromUserToIndexState extends State<LoadingFromUserToIndex> with TickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 7500);

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final AnimationController _progress = AnimationController(vsync: this, duration: _duration);
  late final Animation<double> _p = CurvedAnimation(parent: _progress, curve: Curves.easeInOutCubic);

  bool _precached = false;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _progress.addStatusListener((s) {
      if (s == AnimationStatus.completed) _goToIndex();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      KidAssets.precache(context, const [
        KidAssets.valleyBg, KidAssets.wordmark, KidAssets.ldBook, KidAssets.ldMascot,
        KidAssets.ldGlobe, KidAssets.ldPencil, KidAssets.ldAbc, KidAssets.ldSchool,
        KidAssets.ldSwirl, KidAssets.ldRays, KidAssets.ldSparkle, KidAssets.ldStar,
      ]);
      _intro.forward();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _progress.forward();
      });
    }
  }

  void _goToIndex() {
    if (_left || !mounted) return;
    _left = true;
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const Index(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    _progress.dispose();
    super.dispose();
  }

  String _phase(BuildContext context, double p) {
    final t = tr(context);
    if (p < 0.25) return t.loadPhase1;
    if (p < 0.5) return t.loadPhase2;
    if (p < 0.75) return t.loadPhase3;
    return t.loadPhase4;
  }

  @override
  Widget build(BuildContext context) {
    final xp = Provider.of<ExperienceManager>(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final g = KidSceneGeometry(size);
    final headerShift = max(0.0, pad.top + 6 - g.y(62));

    SceneSprite sprite(String asset, double l, double t, double w, double aspect,
            {double from = 0.1, double to = 0.6, double bob = 0, double rot = 0, double phase = 0,
             int speed = 1, bool twinkle = false, bool pop = true}) =>
        SceneSprite(
          g: g, asset: asset, left: l, top: t, width: w, aspect: aspect,
          idle: _idle, intro: _intro, introFrom: from, introTo: to,
          bob: bob, rot: rot, phase: phase, speed: speed, twinkle: twinkle, pop: pop,
        );

    final barW = g.contentWidth(670, pad: 28);
    final barH = g.lc(62, 26, 36);
    final contentTop = min(g.y(1030), size.height - pad.bottom - g.l(560));

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: KidColors.sky,
        body: Stack(
          children: [
            KidSceneBackground(asset: KidAssets.valleyBg, g: g),

            // Soft cream cloud bank behind the text (keeps it readable).
            Positioned(
              left: 0,
              right: 0,
              top: contentTop - g.l(120),
              bottom: 0,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00FFFBF3), Color(0xE6FFFBF3), Color(0xF2FFFBF3), Color(0xCCFFFBF3)],
                      stops: [0.0, 0.22, 0.75, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            Directionality(
              textDirection: TextDirection.ltr,
              child: Stack(
                children: [
                  sprite(KidAssets.ldSwirl, 120, 175, 700, 0.3471, from: 0.3, to: 0.8, bob: 6, phase: 0.2),
                  sprite(KidAssets.ldBook, 30, 330, 880, 0.811, from: 0.0, to: 0.5, bob: 4, phase: 0.5),
                  // Light burst pulsing from the book
                  AnimatedBuilder(
                    animation: _idle,
                    builder: (_, __) {
                      final k = 0.75 + 0.25 * sin(_idle.value * 6 * pi);
                      final w = 560 * k;
                      return Stack(children: [
                        sprite(KidAssets.ldRays, 470 - w / 2, 640 - 173 * k, w, 0.31, from: 0.4, to: 0.9),
                      ]);
                    },
                  ),
                  sprite(KidAssets.ldMascot, 335, 352, 275, 1.3467, from: 0.15, to: 0.6, bob: 10, rot: 0.02, phase: 0.3),
                  sprite(KidAssets.ldGlobe, 192, 236, 160, 1.1536, from: 0.3, to: 0.75, bob: 9, rot: 0.04, phase: 0.1),
                  sprite(KidAssets.ldPencil, 608, 262, 130, 1.3571, from: 0.35, to: 0.8, bob: 10, rot: 0.08, phase: 0.6),
                  sprite(KidAssets.ldAbc, 120, 430, 152, 0.9489, from: 0.4, to: 0.85, bob: 8, rot: 0.05, phase: 0.35),
                  sprite(KidAssets.ldSchool, 652, 380, 222, 1.1053, from: 0.45, to: 0.9, bob: 7, phase: 0.8),
                  // sparkles
                  sprite(KidAssets.ldSparkle, 330, 225, 34, 1.1045, from: 0.5, to: 0.9, twinkle: true, phase: 0.1, speed: 2),
                  sprite(KidAssets.ldSparkle, 592, 235, 30, 1.1045, from: 0.5, to: 0.9, twinkle: true, phase: 0.45, speed: 3),
                  sprite(KidAssets.ldSparkle, 572, 305, 24, 1.1045, from: 0.55, to: 0.95, twinkle: true, phase: 0.7, speed: 2),
                  sprite(KidAssets.ldSparkle, 160, 372, 32, 1.1045, from: 0.55, to: 0.95, twinkle: true, phase: 0.25, speed: 3),
                  sprite(KidAssets.ldSparkle, 700, 452, 36, 1.1045, from: 0.6, to: 1.0, twinkle: true, phase: 0.9, speed: 2),
                  sprite(KidAssets.ldSparkle, 245, 610, 30, 1.1045, from: 0.6, to: 1.0, twinkle: true, phase: 0.55, speed: 3),
                  sprite(KidAssets.ldSparkle, 712, 640, 28, 1.1045, from: 0.6, to: 1.0, twinkle: true, phase: 0.15, speed: 2),
                  // header
                  Positioned(
                    left: 0, right: 0, top: headerShift, height: g.y(200),
                    child: Stack(children: [
                      sprite(KidAssets.wordmark, 272, 62, 398, 0.2289, from: 0, to: 0.45, bob: 4),
                    ]),
                  ),
                ],
              ),
            ),

            // The child's own avatar in a golden bubble
            Positioned(
              left: g.x(383) + 0,
              top: g.y(165) + headerShift * 0.6,
              child: KidIntro(
                intro: _intro,
                from: 0.2,
                to: 0.7,
                rise: 20,
                child: AnimatedBuilder(
                  animation: _idle,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, sin(_idle.value * 4 * pi) * g.l(8)),
                    child: child,
                  ),
                  child: _AvatarBubble(avatar: xp.selectedAvatar, size: g.l(180)),
                ),
              ),
            ),

            // Text + progress
            Positioned(
              left: g.visibleLeft,
              width: g.visibleWidth,
              top: contentTop,
              child: KidIntro(
                intro: _intro,
                from: 0.35,
                to: 0.9,
                child: AnimatedBuilder(
                  animation: _p,
                  builder: (context, _) {
                    final p = _p.value;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Text(
                            tr(context).loadTitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: kidTitleStyle(g.lc(92, 26, 48)),
                          ),
                        ),
                        SizedBox(height: g.l(10)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(tr(context).loadSubtitle,
                              style: kidBodyStyle(g.lc(40, 15, 21), color: KidColors.ink, weight: FontWeight.w700)),
                        ),
                        SizedBox(height: g.l(34)),
                        _ProgressBar(value: p, width: barW, height: barH, idle: _idle),
                        SizedBox(height: g.l(16)),
                        Text('${(p * 100).round()}%',
                            style: kidBodyStyle(g.lc(38, 15, 21), color: KidColors.ink, weight: FontWeight.w700)),
                        SizedBox(height: g.l(18)),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, a) => FadeTransition(
                            opacity: a,
                            child: SlideTransition(
                              position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(a),
                              child: child,
                            ),
                          ),
                          child: _PhasePill(
                            key: ValueKey(_phase(context, p)),
                            text: _phase(context, p),
                            height: g.lc(66, 32, 42),
                            maxWidth: g.contentWidth(505, pad: 30),
                          ),
                        ),
                        SizedBox(height: g.l(24)),
                        Text(tr(context).loadAlmost,
                            style: kidBodyStyle(g.lc(26, 12, 15), color: KidColors.purple.withOpacity(0.75))),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  final String avatar;
  final double size;
  const _AvatarBubble({required this.avatar, required this.size});

  @override
  Widget build(BuildContext context) {
    Widget inner;
    if (avatar.endsWith('.json')) {
      inner = Lottie.asset(avatar, fit: BoxFit.cover);
    } else if (avatar.startsWith('assets/')) {
      inner = Image.asset(avatar, fit: BoxFit.cover, filterQuality: FilterQuality.medium);
    } else {
      inner = Center(child: Text(avatar.isEmpty ? '🙂' : avatar, style: TextStyle(fontSize: size * 0.5)));
    }
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.05),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE27A), Color(0xFFFFB627), Color(0xFFFFD45A)],
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFFC93C).withOpacity(0.7), blurRadius: size * 0.22),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(size * 0.025),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: ClipOval(child: ColoredBox(color: const Color(0xFFFFE9A8), child: inner)),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value, width, height;
  final Animation<double> idle;
  const _ProgressBar({required this.value, required this.width, required this.height, required this.idle});

  @override
  Widget build(BuildContext context) {
    final h = height;
    final inner = width - 8;
    final fillW = max(h, inner * value);
    final star = h * 1.25;
    return SizedBox(
      width: width,
      height: star,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          // Track
          Container(
            width: width,
            height: h,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE7DEFB),
              borderRadius: BorderRadius.circular(h),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: KidColors.purple.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            alignment: AlignmentDirectional.centerStart,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: fillW - 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(h),
                    gradient: const LinearGradient(colors: [Color(0xFF5B21C9), Color(0xFF8B3DF0), Color(0xFFE040C8)]),
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: h * 0.3, vertical: h * 0.1),
                      height: h * 0.22,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(h),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Star riding the end of the fill
          Positioned(
            left: (4 + fillW - star * 0.6).clamp(0.0, width - star),
            top: 0,
            child: AnimatedBuilder(
              animation: idle,
              builder: (_, child) => Transform.rotate(
                angle: sin(idle.value * 8 * pi) * 0.18,
                child: Transform.scale(scale: 0.92 + 0.12 * (0.5 + 0.5 * sin(idle.value * 12 * pi)), child: child),
              ),
              child: Image.asset(KidAssets.ldStar, width: star, height: star * 0.9591),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhasePill extends StatelessWidget {
  final String text;
  final double height, maxWidth;
  const _PhasePill({super.key, required this.text, required this.height, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    final h = height;
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth, minHeight: h),
      padding: EdgeInsets.symmetric(horizontal: h * 0.5, vertical: h * 0.18),
      decoration: BoxDecoration(
        color: KidColors.cream,
        borderRadius: BorderRadius.circular(h),
        boxShadow: [BoxShadow(color: KidColors.purple.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded, color: KidColors.purple, size: h * 0.48),
          SizedBox(width: h * 0.25),
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: kidBodyStyle(h * 0.3, color: KidColors.ink, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
