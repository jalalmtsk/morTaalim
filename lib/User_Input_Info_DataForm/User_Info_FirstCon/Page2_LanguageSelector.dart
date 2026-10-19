import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

/// Onboarding page 2 — "Choose your language".
class LanguageTouch extends StatefulWidget {
  final VoidCallback? onLanguageSelected;
  final VoidCallback? onBack;

  const LanguageTouch({Key? key, this.onLanguageSelected, this.onBack}) : super(key: key);

  @override
  State<LanguageTouch> createState() => _LanguageTouchState();
}

class _LangOption {
  final String code, label, flag;
  final String? subLabel;
  final TextDirection dir;
  const _LangOption(this.code, this.label, this.flag, {this.subLabel, this.dir = TextDirection.ltr});
}

class _LanguageTouchState extends State<LanguageTouch> with TickerProviderStateMixin {
  String? _selectedLanguage;
  bool _precached = false;

  static const _all = <_LangOption>[
    _LangOption('ar', 'العربية', KidAssets.flagMa, dir: TextDirection.rtl),
    _LangOption('fr', 'Français', KidAssets.flagFr),
    _LangOption('en', 'English', KidAssets.flagUk),
    _LangOption('de', 'Deutsch', KidAssets.flagDe),
    _LangOption('zgh', 'ⵜⴰⵎⴰⵣⵉⵖⵜ', KidAssets.flagZgh, subLabel: 'Amazigh'),
  ];

  static const List<String> _assets = [
    KidAssets.valleyBg,
    KidAssets.wordmark,
    KidAssets.backBtn,
    KidAssets.mascotWave,
    KidAssets.flagMa,
    KidAssets.flagFr,
    KidAssets.flagUk,
    KidAssets.flagDe,
    KidAssets.flagZgh,
  ];

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

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
    super.dispose();
  }

  void _select(_LangOption o) {
    final expManager = Provider.of<ExperienceManager>(context, listen: false);
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton2');
    setState(() => _selectedLanguage = o.code);
    expManager.changeLanguage(Locale(o.code));
  }

  @override
  Widget build(BuildContext context) {
    final expManager = Provider.of<ExperienceManager>(context);
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final g = KidSceneGeometry(size);
    final headerShift = max(0.0, pad.top + 6 - g.y(52));

    var options = _all.where((o) => expManager.unlockedLanguages.contains(o.code)).toList();
    if (options.isEmpty) options = _all;

    // Cards: design y 455 → 1325, 177 px pitch, 160 px tall.
    final cardTop = g.y(455);
    final buttonTop = min(g.y(1372), size.height - pad.bottom - g.lc(140, 52, 74) - 56);
    final avail = buttonTop - cardTop - g.l(30);
    final pitch = min(g.l(177), avail / options.length);
    final cardH = min(g.lc(160, 52, 88), pitch * 0.9);
    final cardW = g.contentWidth(658, pad: 18);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

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
                SceneSprite(
                  g: g,
                  asset: KidAssets.mascotWave,
                  left: 590,
                  top: 130,
                  width: 320,
                  aspect: 1.4372,
                  idle: _idle,
                  intro: _intro,
                  introFrom: 0.15,
                  introTo: 0.6,
                  bob: 8,
                  rot: 0.05,
                  phase: 0.3,
                  speed: 2,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: headerShift,
                  height: g.y(200),
                  child: Stack(children: [
                    SceneSprite(
                      g: g,
                      asset: KidAssets.wordmark,
                      left: 272,
                      top: 62,
                      width: 398,
                      aspect: 0.2289,
                      idle: _idle,
                      intro: _intro,
                      introFrom: 0,
                      introTo: 0.45,
                      bob: 4,
                    ),
                  ]),
                ),
              ],
            ),
          ),

          // Back
          if (widget.onBack != null)
            Positioned(
              top: g.y(46) + headerShift,
              left: isRtl ? null : g.fitLeft(42, 88, bleed: 0) ,
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

          // Title + subtitle, left of the mascot
          Positioned(
            left: g.fitLeft(110, 520, bleed: 0, margin: 12),
            width: min(g.l(520), size.width * 0.66),
            top: g.y(178) + headerShift * 0.5,
            height: g.l(240),
            child: KidIntro(
              intro: _intro,
              from: 0.2,
              to: 0.7,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        tr(context).langChooseTitle.replaceFirst(' ', '\n', _splitAt(tr(context).langChooseTitle)),
                        textAlign: TextAlign.center,
                        style: kidTitleStyle(g.lc(86, 26, 46)),
                      ),
                    ),
                  ),
                  SizedBox(height: g.l(10)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      tr(context).langLearnTogether,
                      style: kidBodyStyle(g.lc(32, 13, 18),
                          color: KidColors.ink, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Language cards
          for (int i = 0; i < options.length; i++)
            Positioned(
              top: cardTop + i * pitch,
              left: (size.width - cardW) / 2,
              width: cardW,
              height: cardH,
              child: KidIntro(
                intro: _intro,
                from: 0.3 + i * 0.08,
                to: 0.75 + i * 0.05,
                rise: 40,
                child: _LanguageCard(
                  option: options[i],
                  selected: _selectedLanguage == options[i].code,
                  height: cardH,
                  onTap: () => _select(options[i]),
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
                  height: g.lc(140, 52, 74),
                  onPressed: _selectedLanguage == null
                      ? null
                      : () {
                          audioManager.playEventSound('clickButton');
                          widget.onLanguageSelected?.call();
                        },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Index of the space to break the title on, so "Choose your language"
  /// becomes "Choose your\nlanguage" (break at the space nearest the middle).
  static int _splitAt(String s) {
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

class _LanguageCard extends StatelessWidget {
  final _LangOption option;
  final bool selected;
  final double height;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.option,
    required this.selected,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final h = height;
    final flag = h * 0.76;
    final radio = h * 0.38;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.97,
      semanticLabel: option.label,
      child: AnimatedScale(
        scale: selected ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: h * 0.28),
          decoration: BoxDecoration(
            color: selected ? KidColors.purpleLight : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(h),
            border: Border.all(
              color: selected ? KidColors.purple : const Color(0xFFE6DDF7),
              width: selected ? 3.5 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (selected ? KidColors.purple : const Color(0xFF6B4FA8))
                    .withOpacity(selected ? 0.32 : 0.14),
                blurRadius: selected ? 20 : 12,
                offset: Offset(0, selected ? 8 : 5),
              ),
            ],
          ),
          child: Row(
            textDirection: Directionality.of(context),
            children: [
              Container(
                width: flag,
                height: flag,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 6, offset: const Offset(0, 3)),
                  ],
                ),
                child: Image.asset(option.flag, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
              ),
              SizedBox(width: h * 0.24),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        option.label,
                        textDirection: option.dir,
                        style: kidBodyStyle(h * 0.3, color: KidColors.ink, weight: FontWeight.w700),
                      ),
                    ),
                    if (option.subLabel != null)
                      Text(option.subLabel!,
                          style: kidBodyStyle(h * 0.15, color: KidColors.purple.withOpacity(0.7))),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: radio,
                height: radio,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: selected ? KidColors.purple : KidColors.lavender,
                    width: selected ? radio * 0.12 : radio * 0.08,
                  ),
                ),
                child: Center(
                  child: AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: radio * 0.56,
                      height: radio * 0.56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: KidColors.purple,
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
