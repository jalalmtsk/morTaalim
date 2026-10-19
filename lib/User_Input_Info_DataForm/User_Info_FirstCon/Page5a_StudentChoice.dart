import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../XpSystem.dart';
import '../../tools/audio_tool/Audio_Manager.dart';

/// Onboarding — "Are you a student?".
/// Yes → school details page. No → skips it.
class StudentChoicePage extends StatefulWidget {
  final VoidCallback onYes;
  final VoidCallback onNo;
  final VoidCallback? onBack;

  const StudentChoicePage({Key? key, required this.onYes, required this.onNo, this.onBack})
      : super(key: key);

  @override
  State<StudentChoicePage> createState() => _StudentChoicePageState();
}

class _StudentChoicePageState extends State<StudentChoicePage> with TickerProviderStateMixin {
  bool? _isStudent;
  bool _precached = false;

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final AnimationController _jump =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  static const List<String> _assets = [
    KidAssets.valleyBg,
    KidAssets.wordmark,
    KidAssets.backBtn,
    KidAssets.mascotStudent,
    KidAssets.books,
    KidAssets.island,
    KidAssets.exclaim,
    KidAssets.school,
    KidAssets.bookStar,
  ];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted && p.containsKey('is_student')) {
        setState(() => _isStudent = p.getBool('is_student'));
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      KidAssets.precache(context, _assets);
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    _jump.dispose();
    super.dispose();
  }

  void _choose(bool v) {
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton2');
    setState(() => _isStudent = v);
    if (_jump.isAnimating == false) _jump.forward(from: 0);
  }

  Future<void> _continue() async {
    final v = _isStudent;
    if (v == null) return;
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_student', v);
    if (!mounted) return;
    if (v) {
      widget.onYes();
    } else {
      Provider.of<ExperienceManager>(context, listen: false).setSchoolName('Not a student');
      widget.onNo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final g = KidSceneGeometry(size);
    final headerShift = max(0.0, pad.top + 6 - g.y(48));
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final buttonH = g.lc(136, 52, 72);
    final buttonTop = min(g.y(1408), size.height - pad.bottom - buttonH - 52);
    final formW = g.contentWidth(784, pad: 16);
    final gap = g.l(22);
    final cardW = (formW - gap) / 2;
    final cardH = min(g.l(400), cardW * 1.08);
    final cardTop = min(g.y(962), buttonTop - cardH - g.l(30));

    SceneSprite sprite(String asset, double l, double t, double w, double aspect,
            {double from = 0.2,
            double to = 0.7,
            double bob = 0,
            double rot = 0,
            double phase = 0,
            int speed = 1,
            Animation<double>? jump,
            VoidCallback? onTap}) =>
        SceneSprite(
          g: g,
          asset: asset,
          left: l,
          top: t,
          width: w,
          aspect: aspect,
          idle: _idle,
          intro: _intro,
          introFrom: from,
          introTo: to,
          bob: bob,
          rot: rot,
          phase: phase,
          speed: speed,
          jump: jump,
          onTap: onTap,
        );

    return Scaffold(
      backgroundColor: KidColors.sky,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          KidSceneBackground(asset: KidAssets.valleyBg, g: g),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: [
                sprite(KidAssets.island, 180, 752, 620, 0.382, from: 0.1, to: 0.55, bob: 5, phase: 0.5),
                sprite(KidAssets.books, 548, 706, 196, 1.0711, from: 0.35, to: 0.8, bob: 5, phase: 0.5),
                sprite(KidAssets.mascotStudent, 296, 372, 392, 1.3203,
                    from: 0.2, to: 0.65, bob: 6, rot: 0.02, phase: 0.5, jump: _jump,
                    onTap: () {
                      if (_jump.isAnimating) return;
                      audioManager.playEventSound('PopButton');
                      _jump.forward(from: 0);
                    }),
                sprite(KidAssets.exclaim, 622, 470, 110, 1.0157,
                    from: 0.55, to: 0.95, bob: 5, rot: 0.1, phase: 0.2, speed: 2),
                Positioned(
                  left: 0,
                  right: 0,
                  top: headerShift,
                  height: g.y(200),
                  child: Stack(children: [
                    sprite(KidAssets.wordmark, 272, 62, 398, 0.2289, from: 0, to: 0.45, bob: 4),
                  ]),
                ),
              ],
            ),
          ),

          // Title
          Positioned(
            left: g.visibleLeft + 16,
            width: g.visibleWidth - 32,
            top: g.y(168) + headerShift * 0.5,
            height: g.l(220),
            child: KidIntro(
              intro: _intro,
              from: 0.15,
              to: 0.6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(tr(context).studentTitle.replaceFirst(' ', '\n', _mid(tr(context).studentTitle)),
                          textAlign: TextAlign.center, style: kidTitleStyle(g.lc(88, 26, 48))),
                    ),
                  ),
                  SizedBox(height: g.l(6)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(tr(context).studentSubtitle,
                        style: kidBodyStyle(g.lc(34, 14, 19), color: KidColors.ink, weight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),

          // Cards
          Positioned(
            left: (size.width - formW) / 2,
            width: formW,
            top: cardTop,
            height: cardH,
            child: Row(
              children: [
                Expanded(
                  child: KidIntro(
                    intro: _intro,
                    from: 0.4,
                    to: 0.85,
                    rise: 40,
                    child: _ChoiceCard(
                      image: KidAssets.school,
                      imageAspect: 0.7989,
                      title: tr(context).studentYes,
                      subtitle: tr(context).studentYesSub,
                      selected: _isStudent == true,
                      height: cardH,
                      onTap: () => _choose(true),
                    ),
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: KidIntro(
                    intro: _intro,
                    from: 0.48,
                    to: 0.92,
                    rise: 40,
                    child: _ChoiceCard(
                      image: KidAssets.bookStar,
                      imageAspect: 0.8542,
                      title: tr(context).studentNo,
                      subtitle: tr(context).studentNoSub,
                      selected: _isStudent == false,
                      height: cardH,
                      onTap: () => _choose(false),
                    ),
                  ),
                ),
              ],
            ),
          ),

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
                  onPressed: _isStudent == null ? null : _continue,
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

  static int _mid(String s) {
    final spaces = <int>[];
    for (int i = 0; i < s.length; i++) {
      if (s[i] == ' ') spaces.add(i);
    }
    if (spaces.isEmpty) return s.length;
    final mid = s.length / 2;
    spaces.sort((a, b) => (a - mid).abs().compareTo((b - mid).abs()));
    return spaces.first;
  }
}

class _ChoiceCard extends StatelessWidget {
  final String image;
  final double imageAspect;
  final String title, subtitle;
  final bool selected;
  final double height;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.image,
    required this.imageAspect,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final h = height;
    final badge = h * 0.1;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.96,
      semanticLabel: '$title, $subtitle',
      child: AnimatedScale(
        scale: selected ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          height: h,
          decoration: BoxDecoration(
            color: selected ? KidColors.purpleLight : Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(h * 0.1),
            border: Border.all(
              color: selected ? KidColors.purple : const Color(0xFFD9CCF7),
              width: selected ? 4 : 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: KidColors.purple.withOpacity(selected ? 0.32 : 0.14),
                blurRadius: selected ? 22 : 12,
                offset: Offset(0, selected ? 9 : 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(h * 0.05, h * 0.07, h * 0.05, h * 0.05),
                child: Column(
                  children: [
                    Expanded(
                      child: AnimatedScale(
                        scale: selected ? 1.06 : 0.96,
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutBack,
                        child: Image.asset(image, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
                      ),
                    ),
                    SizedBox(height: h * 0.02),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(title,
                          style: kidTitleStyle(h * 0.15, color: KidColors.purpleDeep)
                              .copyWith(shadows: const [])),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(subtitle,
                          style: kidBodyStyle(h * 0.068, color: KidColors.ink, weight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              PositionedDirectional(
                top: h * 0.045,
                end: h * 0.045,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: badge,
                  height: badge,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? KidColors.purple : Colors.white,
                    border: Border.all(
                        color: selected ? KidColors.purple : KidColors.lavender, width: badge * 0.1),
                  ),
                  child: AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutBack,
                    child: Icon(Icons.check_rounded, color: Colors.white, size: badge * 0.72),
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
