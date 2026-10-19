import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/Manager/models/banner_catalog.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/widgets/KidScene/kid_form.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';
import '../../tools/audio_tool/Audio_Manager.dart';

/// Onboarding — "Choose your banner".
class UserInfoBannerPage extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const UserInfoBannerPage({Key? key, this.onNext, this.onBack}) : super(key: key);

  @override
  State<UserInfoBannerPage> createState() => _UserInfoBannerPageState();
}

class _UserInfoBannerPageState extends State<UserInfoBannerPage> with TickerProviderStateMixin {
  late String _selected;
  bool _precached = false;

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  @override
  void initState() {
    super.initState();
    final em = Provider.of<ExperienceManager>(context, listen: false);
    _selected = BannerCatalog.resolve(em.selectedBannerImage);
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
        KidAssets.avatarMascot,
        ...BannerCatalog.starter,
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

  void _pick(String path) {
    if (path == _selected) return;
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton2');
    setState(() => _selected = path);
  }

  void _apply() {
    final em = Provider.of<ExperienceManager>(context, listen: false);
    em.unlockBanner(_selected);
    em.selectBannerImage(_selected);
  }

  void _continue() {
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton');
    _apply();
    widget.onNext?.call();
  }

  void _skip() {
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton');
    // Keep (or set) a valid default so the profile never shows a broken banner.
    final em = Provider.of<ExperienceManager>(context, listen: false);
    if (!BannerCatalog.isValid(em.selectedBannerImage)) {
      em.unlockBanner(BannerCatalog.defaultBanner);
      em.selectBannerImage(BannerCatalog.defaultBanner);
    }
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

    final buttonH = g.lc(130, 50, 70);
    final linkH = g.lc(46, 28, 36);
    final buttonTop = min(g.y(1418), size.height - pad.bottom - buttonH - linkH - 26);
    final panelTop = g.y(362) + headerShift * 0.5;
    final panelBottom = buttonTop - g.l(22);
    final panelW = g.contentWidth(828, pad: 12);

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
            top: g.y(168) + headerShift * 0.5,
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
                    child: Text(tr(context).chooseYourBanner,
                        maxLines: 1, style: kidTitleStyle(g.lc(80, 24, 44))),
                  ),
                  SizedBox(height: g.l(6)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(tr(context).bannerSubtitle,
                        style: kidBodyStyle(g.lc(32, 13, 18), color: KidColors.ink, weight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),

          // Panel
          Positioned(
            left: (size.width - panelW) / 2,
            width: panelW,
            top: panelTop,
            height: max(220.0, panelBottom - panelTop),
            child: KidIntro(
              intro: _intro,
              from: 0.3,
              to: 0.8,
              rise: 40,
              child: _BannerPanel(
                g: g,
                selected: _selected,
                idle: _idle,
                onPick: _pick,
              ),
            ),
          ),

          // Button + skip
          Positioned(
            left: 0,
            right: 0,
            top: buttonTop,
            child: KidIntro(
              intro: _intro,
              from: 0.6,
              to: 1.0,
              child: Column(
                children: [
                  KidButton(
                    label: tr(context).useThisBanner,
                    width: g.contentWidth(722, pad: 24),
                    height: buttonH,
                    onPressed: _continue,
                  ),
                  SizedBox(
                    height: linkH,
                    child: Center(
                      child: KidLink(text: tr(context).skipForNow, onTap: _skip, size: g.lc(28, 12, 15)),
                    ),
                  ),
                ],
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

class _BannerPanel extends StatelessWidget {
  final KidSceneGeometry g;
  final String selected;
  final Animation<double> idle;
  final ValueChanged<String> onPick;

  const _BannerPanel({required this.g, required this.selected, required this.idle, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final radius = g.lc(44, 22, 30);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF6),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFD9CCF7), width: 3),
        boxShadow: [
          BoxShadow(color: KidColors.purpleDeep.withOpacity(0.16), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(g.l(16), g.l(16), g.l(16), g.l(18)),
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final gap = g.l(BannerCatalog.starter.length > 6 ? 14 : 20);
        final tileW = (w - gap) / 2;
        // Height budget: hero + pill + heading + 3 rows of tiles.
        final headingH = g.lc(64, 26, 40);
        final pillH = g.lc(44, 24, 30);
        final rows = (BannerCatalog.starter.length / 2).ceil();
        double heroH = min(g.l(285), w / 2.75);
        double tileH = min(tileW / 2.25, g.l(170));
        final need = heroH + pillH * 0.5 + headingH + rows * tileH + (rows - 1) * gap + g.l(24);
        if (need > c.maxHeight) {
          final k = (c.maxHeight - pillH * 0.5 - headingH - (rows - 1) * gap - g.l(24)) /
              (heroH + rows * tileH);
          heroH *= k.clamp(0.4, 1.0);
          tileH *= k.clamp(0.4, 1.0);
        }
        final avatar = heroH * 0.8;

        return Column(
          children: [
            // ── Hero preview ───────────────────────────────────────────
            SizedBox(
              height: heroH + pillH * 0.5,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    height: heroH,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius * 0.8),
                      border: Border.all(color: const Color(0xFFDCCFF8), width: 4),
                      boxShadow: [
                        BoxShadow(color: KidColors.purple.withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius * 0.8 - 3),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 420),
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: ScaleTransition(scale: Tween(begin: 1.06, end: 1.0).animate(a), child: child),
                        ),
                        child: Image.asset(
                          selected,
                          key: ValueKey(selected),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ),
                  // Avatar bubble
                  Positioned(
                    top: (heroH - avatar) / 2 - heroH * 0.04,
                    child: AnimatedBuilder(
                      animation: idle,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, sin(idle.value * 2 * pi * 2) * avatar * 0.025),
                        child: child,
                      ),
                      child: Image.asset(KidAssets.avatarMascot,
                          width: avatar, height: avatar * 196 / 186, filterQuality: FilterQuality.medium),
                    ),
                  ),
                  // "Your profile" pill
                  Positioned(
                    top: heroH - pillH * 0.5,
                    child: Container(
                      height: pillH,
                      padding: EdgeInsets.symmetric(horizontal: pillH * 0.8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: KidColors.cream,
                        borderRadius: BorderRadius.circular(pillH),
                        boxShadow: [
                          BoxShadow(color: KidColors.purple.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Text(tr(context).yourProfile,
                          style: kidBodyStyle(pillH * 0.46, color: KidColors.ink, weight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: headingH,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(tr(context).pickYourFavorite,
                      style: kidTitleStyle(headingH * 0.52).copyWith(shadows: const [])),
                ),
              ),
            ),

            // ── Grid ───────────────────────────────────────────────────
            for (int row = 0; row < (BannerCatalog.starter.length / 2).ceil(); row++) ...[
              if (row > 0) SizedBox(height: gap),
              Row(
                children: [
                  for (int col = 0; col < 2; col++) ...[
                    if (col > 0) SizedBox(width: gap),
                    Expanded(
                      child: row * 2 + col < BannerCatalog.starter.length
                          ? _BannerTile(
                              path: BannerCatalog.starter[row * 2 + col],
                              selected: BannerCatalog.starter[row * 2 + col] == selected,
                              height: tileH,
                              onTap: () => onPick(BannerCatalog.starter[row * 2 + col]),
                            )
                          : SizedBox(height: tileH),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _BannerTile extends StatelessWidget {
  final String path;
  final bool selected;
  final double height;
  final VoidCallback onTap;

  const _BannerTile({required this.path, required this.selected, required this.height, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final h = height;
    final r = h * 0.16;
    final badge = h * 0.26;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.95,
      child: AnimatedScale(
        scale: selected ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        child: SizedBox(
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(r),
                    border: Border.all(
                      color: selected ? KidColors.purple : const Color(0xFFE3D9F8),
                      width: selected ? 4 : 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: KidColors.purple.withOpacity(selected ? 0.35 : 0.12),
                        blurRadius: selected ? 14 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(r - 3),
                    child: Image.asset(path, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
                  ),
                ),
              ),
              PositionedDirectional(
                top: -badge * 0.3,
                end: -badge * 0.25,
                child: AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: badge,
                    height: badge,
                    decoration: BoxDecoration(
                      color: KidColors.purple,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: badge * 0.09),
                      boxShadow: [BoxShadow(color: KidColors.purple.withOpacity(0.4), blurRadius: 8)],
                    ),
                    child: Icon(Icons.check_rounded, color: Colors.white, size: badge * 0.62),
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
