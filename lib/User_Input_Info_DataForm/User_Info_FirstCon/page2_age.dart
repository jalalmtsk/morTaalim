import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../tools/audio_tool/Audio_Manager.dart';

// ─── NOTE : AdHelper.setChildMode() supprimé ─────────────────────────────────
// La config COPPA est fixée une fois pour toutes dans AdHelper.initializeAds().
// La sélection d'âge ici sert uniquement à personnaliser l'expérience (niveau,
// difficulté, langue) — elle n'affecte plus jamais les annonces.
// ─────────────────────────────────────────────────────────────────────────────

class AgeRange {
  final String label;
  final int minAge;
  final int maxAge;
  final String image;
  final double imageAspect; // height / width

  const AgeRange({
    required this.label,
    required this.minAge,
    required this.maxAge,
    required this.image,
    required this.imageAspect,
  });
}

const List<AgeRange> ageRanges = [
  AgeRange(label: '3–6', minAge: 3, maxAge: 6, image: KidAssets.ageAbc, imageAspect: 0.7478),
  AgeRange(label: '7–9', minAge: 7, maxAge: 9, image: KidAssets.ageBook, imageAspect: 0.7188),
  AgeRange(label: '10–12', minAge: 10, maxAge: 12, image: KidAssets.agePlanet, imageAspect: 0.752),
  AgeRange(label: '13+', minAge: 13, maxAge: 99, image: KidAssets.ageRocket, imageAspect: 0.8635),
];

/// Onboarding — "How old are you?".
class AgeCheckPage extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const AgeCheckPage({Key? key, this.onNext, this.onBack}) : super(key: key);

  @override
  State<AgeCheckPage> createState() => _AgeCheckPageState();
}

class _AgeCheckPageState extends State<AgeCheckPage> with TickerProviderStateMixin {
  AgeRange? selectedRange;
  bool _precached = false;

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final age = p.getInt('age');
      if (!mounted || age == null || age <= 0) return;
      for (final r in ageRanges) {
        if (age >= r.minAge && age <= r.maxAge) {
          setState(() => selectedRange = r);
          break;
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      KidAssets.precache(context, [
        KidAssets.valleyBg,
        KidAssets.wordmark,
        KidAssets.backBtn,
        KidAssets.ageMascot,
        for (final r in ageRanges) r.image,
      ]);
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  Future<void> _saveAge(AgeRange range) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('age', range.minAge);
    await prefs.setBool('age_check_completed', true);
  }

  Future<void> _onConfirm() async {
    final r = selectedRange;
    if (r == null) return;
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton');
    await _saveAge(r);
    widget.onNext?.call();
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final g = KidSceneGeometry(size);
    final headerShift = max(0.0, pad.top + 6 - g.y(48));
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final buttonH = g.lc(132, 50, 70);
    final buttonTop = min(g.y(1392), size.height - pad.bottom - buttonH - 50);
    final formW = g.contentWidth(745, pad: 14);
    final gap = g.l(18);
    final cardW = (formW - gap) / 2;
    final gridTop = g.y(600) + headerShift * 0.5;
    final cardH = min(min(g.l(382), cardW * 1.05), (buttonTop - g.l(24) - gridTop - gap) / 2);

    return Scaffold(
      backgroundColor: KidColors.sky,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          KidSceneBackground(asset: KidAssets.valleyBg, g: g),

          Positioned(
            left: 0,
            right: 0,
            top: headerShift,
            height: g.y(200),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Stack(children: [
                SceneSprite(
                  g: g, asset: KidAssets.wordmark, left: 272, top: 62, width: 398, aspect: 0.2289,
                  idle: _idle, intro: _intro, introFrom: 0, introTo: 0.45, bob: 4,
                ),
              ]),
            ),
          ),

          // Title
          Positioned(
            left: g.visibleLeft + 16,
            width: g.visibleWidth - 32,
            top: g.y(172) + headerShift * 0.5,
            height: g.l(150),
            child: KidIntro(
              intro: _intro,
              from: 0.15,
              to: 0.6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(tr(context).ageTitle, maxLines: 1, style: kidTitleStyle(g.lc(84, 26, 46))),
                  ),
                  SizedBox(height: g.l(6)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(tr(context).ageSubtitle,
                        style: kidBodyStyle(g.lc(34, 14, 19), color: KidColors.ink, weight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),

          // Cards
          for (int i = 0; i < ageRanges.length; i++)
            Positioned(
              left: (size.width - formW) / 2 + (i % 2) * (cardW + gap),
              top: gridTop + (i ~/ 2) * (cardH + gap),
              width: cardW,
              height: cardH,
              child: KidIntro(
                intro: _intro,
                from: 0.3 + i * 0.07,
                to: 0.75 + i * 0.05,
                rise: 40,
                child: _AgeCard(
                  range: ageRanges[i],
                  selected: selectedRange == ageRanges[i],
                  height: cardH,
                  idle: _idle,
                  phase: i * 0.25,
                  onTap: () {
                    audioManager.playEventSound('clickButton2');
                    setState(() => selectedRange = ageRanges[i]);
                  },
                ),
              ),
            ),

          // Mascot peeking over the cards (paws on the top edge)
          Positioned.fill(
            child: IgnorePointer(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Stack(children: [
                  SceneSprite(
                    g: g, asset: KidAssets.ageMascot,
                    left: 290, top: gridTop / g.s - 275 * 0.9319 + 14, width: 275, aspect: 0.9319,
                    idle: _idle, intro: _intro, introFrom: 0.45, introTo: 0.9,
                    pop: false, bob: 3, rot: 0.02, phase: 0.3, speed: 2,
                  ),
                ]),
              ),
            ),
          ),

          // Continue
          Positioned(
            left: 0,
            right: 0,
            top: buttonTop,
            child: KidIntro(
              intro: _intro,
              from: 0.6,
              to: 1.0,
              child: Center(
                child: KidButton(
                  label: tr(context).continueLabel,
                  width: g.contentWidth(722, pad: 24),
                  height: buttonH,
                  onPressed: selectedRange == null ? null : _onConfirm,
                ),
              ),
            ),
          ),

          if (widget.onBack != null)
            Positioned(
              top: g.y(46) + headerShift,
              left: isRtl ? null : g.fitLeft(42, 88, bleed: 0),
              right: isRtl ? g.fitLeft(42, 88, bleed: 0) : null,
              child: KidIntro(
                intro: _intro,
                from: 0.1,
                to: 0.5,
                rise: -10,
                child: KidBackButton(
                  size: g.lc(88, 40, 52),
                  onTap: () {
                    audioManager.playEventSound('cancelButton');
                    widget.onBack!.call();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AgeCard extends StatelessWidget {
  final AgeRange range;
  final bool selected;
  final double height;
  final Animation<double> idle;
  final double phase;
  final VoidCallback onTap;

  const _AgeCard({
    required this.range,
    required this.selected,
    required this.height,
    required this.idle,
    required this.phase,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final h = height;
    final radio = h * 0.1;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.96,
      semanticLabel: '${range.label} ${tr(context).yearsOld}',
      child: AnimatedScale(
        scale: selected ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          decoration: BoxDecoration(
            color: selected ? KidColors.purpleLight : Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(h * 0.11),
            border: Border.all(
              color: selected ? KidColors.purple : const Color(0xFFDDD0F8),
              width: selected ? 4 : 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: KidColors.purple.withOpacity(selected ? 0.3 : 0.12),
                blurRadius: selected ? 20 : 10,
                offset: Offset(0, selected ? 8 : 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(h * 0.06, h * 0.1, h * 0.06, h * 0.05),
                child: Column(
                  children: [
                    Expanded(
                      child: AnimatedBuilder(
                        animation: idle,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, sin(2 * pi * (idle.value * 2 + phase)) * h * (selected ? 0.025 : 0.012)),
                          child: child,
                        ),
                        child: Image.asset(range.image, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
                      ),
                    ),
                    SizedBox(height: h * 0.02),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        range.label,
                        textDirection: TextDirection.ltr,
                        style: kidTitleStyle(h * 0.17, color: KidColors.ink).copyWith(shadows: const []),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(tr(context).yearsOld,
                          style: kidBodyStyle(h * 0.075, color: KidColors.purpleDeep, weight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              PositionedDirectional(
                top: h * 0.05,
                end: h * 0.05,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: radio,
                  height: radio,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: selected ? KidColors.purple : KidColors.lavender,
                      width: radio * (selected ? 0.13 : 0.09),
                    ),
                  ),
                  child: Center(
                    child: AnimatedScale(
                      scale: selected ? 1 : 0,
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: radio * 0.55,
                        height: radio * 0.55,
                        decoration: const BoxDecoration(color: KidColors.purple, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
