import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/Manager/models/avatar_catalog.dart';
import 'package:mortaalim/Manager/models/banner_catalog.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_form.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../XpSystem.dart';
import '../../main.dart';
import 'LoadingFromUserToIndex.dart';

/// Onboarding (last step) — "Make it yours!": gender (optional) + avatar.
class UserInfoAvatarAndGender extends StatefulWidget {
  final VoidCallback? onBack;

  const UserInfoAvatarAndGender({Key? key, this.onBack}) : super(key: key);

  @override
  State<UserInfoAvatarAndGender> createState() => _UserInfoAvatarAndGenderState();
}

class _UserInfoAvatarAndGenderState extends State<UserInfoAvatarAndGender>
    with TickerProviderStateMixin {
  late String _avatar;
  String _gender = ''; // 'male' | 'female' | '' (prefer not to say)
  bool _saving = false;
  bool _precached = false;

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  @override
  void initState() {
    super.initState();
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    _avatar = AvatarCatalog.resolve(xp.selectedAvatar);
    _gender = xp.userProfile.gender == 'male' || xp.userProfile.gender == 'female'
        ? xp.userProfile.gender
        : '';
    SharedPreferences.getInstance().then((p) {
      final g = p.getString('gender');
      if (mounted && (g == 'male' || g == 'female')) setState(() => _gender = g!);
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
        ...AvatarCatalog.starter,
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

  void _pickAvatar(String a) {
    if (a == _avatar) return;
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton2');
    setState(() => _avatar = a);
  }

  void _pickGender(String g) {
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton2');
    setState(() => _gender = g);
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    Provider.of<AudioManager>(context, listen: false).playEventSound('clickButton');
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    xp.unlockAvatar(_avatar);
    xp.selectAvatar(_avatar);
    xp.setGender(_gender);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setString('gender', _gender);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const LoadingFromUserToIndex(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final xp = Provider.of<ExperienceManager>(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final g = KidSceneGeometry(size);
    final headerShift = max(0.0, pad.top + 6 - g.y(48));
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final buttonH = g.lc(124, 48, 68);
    final linkH = g.lc(44, 26, 34);
    final buttonTop = min(g.y(1472), size.height - pad.bottom - buttonH - linkH - 20);
    final panelTop = g.y(332) + headerShift * 0.5;
    final panelBottom = buttonTop - g.l(16);
    final panelW = g.contentWidth(820, pad: 12);

    return PopScope(
      canPop: false,
      child: Scaffold(
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
                    g: g, asset: KidAssets.wordmark, left: 300, top: 52, width: 340, aspect: 0.2289,
                    idle: _idle, intro: _intro, introFrom: 0, introTo: 0.45, bob: 4,
                  ),
                ]),
              ),
            ),

            // Title
            Positioned(
              left: g.visibleLeft + 16,
              width: g.visibleWidth - 32,
              top: g.y(136) + headerShift * 0.5,
              height: g.l(160),
              child: KidIntro(
                intro: _intro,
                from: 0.15,
                to: 0.6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(tr(context).avatarTitle, maxLines: 1, style: kidTitleStyle(g.lc(86, 26, 46))),
                    ),
                    SizedBox(height: g.l(4)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(tr(context).avatarSubtitle,
                          style: kidBodyStyle(g.lc(36, 14, 20), color: KidColors.ink, weight: FontWeight.w700)),
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
              height: max(260.0, panelBottom - panelTop),
              child: KidIntro(
                intro: _intro,
                from: 0.3,
                to: 0.8,
                rise: 40,
                child: _Panel(
                  g: g,
                  banner: BannerCatalog.resolve(xp.selectedBannerImage),
                  avatar: _avatar,
                  gender: _gender,
                  idle: _idle,
                  onAvatar: _pickAvatar,
                  onGender: _pickGender,
                ),
              ),
            ),

            // Continue + skip
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
                      label: tr(context).continueLabel,
                      width: g.contentWidth(712, pad: 24),
                      height: buttonH,
                      loading: _saving,
                      onPressed: _finish,
                    ),
                    SizedBox(
                      height: linkH,
                      child: Center(
                        child: KidLink(
                          text: tr(context).skipForNow,
                          size: g.lc(28, 12, 15),
                          onTap: () {
                            // Keep the defaults (mascot avatar, no gender).
                            setState(() {
                              _avatar = AvatarCatalog.resolve(_avatar);
                            });
                            _finish();
                          },
                        ),
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
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final KidSceneGeometry g;
  final String banner, avatar, gender;
  final Animation<double> idle;
  final ValueChanged<String> onAvatar, onGender;

  const _Panel({
    required this.g,
    required this.banner,
    required this.avatar,
    required this.gender,
    required this.idle,
    required this.onAvatar,
    required this.onGender,
  });

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
      padding: EdgeInsets.fromLTRB(g.l(14), g.l(12), g.l(14), g.l(14)),
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final labelSize = g.lc(32, 14, 18);
        final pillH = g.lc(78, 38, 50);
        final headingH = g.lc(56, 26, 36);
        final gap = g.l(10);
        double heroH = min(g.l(240), w / 3.2);
        double cell = min((w - 2 * gap) / 3, g.l(212));
        // Fit everything into the panel height.
        double need() => heroH * 1.12 + labelSize * 1.6 + pillH + headingH + 3 * cell + 2 * gap + g.l(28);
        if (need() > c.maxHeight) {
          final fixed = labelSize * 1.6 + pillH + headingH + 2 * gap + g.l(28);
          final k = ((c.maxHeight - fixed) / (heroH * 1.12 + 3 * cell)).clamp(0.45, 1.0);
          heroH *= k;
          cell *= k;
        }
        final bubble = heroH * 0.92;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Banner + avatar preview ───────────────────────────────
            SizedBox(
              height: heroH * 1.12,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    height: heroH,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius * 0.75),
                      border: Border.all(color: const Color(0xFFDCCFF8), width: 4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius * 0.75 - 3),
                      child: Image.asset(banner,
                          width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: heroH * 1.12 - bubble,
                    child: AnimatedBuilder(
                      animation: idle,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, sin(idle.value * 4 * pi) * bubble * 0.02),
                        child: child,
                      ),
                      child: Container(
                        width: bubble,
                        height: bubble,
                        padding: EdgeInsets.all(bubble * 0.045),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: KidColors.purple.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          transitionBuilder: (child, a) => ScaleTransition(
                              scale: Tween(begin: 0.6, end: 1.0)
                                  .animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
                              child: FadeTransition(opacity: a, child: child)),
                          child: ClipOval(
                            key: ValueKey(avatar),
                            child: Image.asset(avatar, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Gender ─────────────────────────────────────────────────
            KidFieldLabel(tr(context).genderLabel, tag: tr(context).optionalTag, size: labelSize),
            SizedBox(
              height: pillH,
              child: Row(
                children: [
                  Expanded(
                      flex: 5,
                      child: _GenderPill(
                          label: tr(context).genderBoy, selected: gender == 'male', height: pillH,
                          onTap: () => onGender('male'))),
                  SizedBox(width: g.l(10)),
                  Expanded(
                      flex: 5,
                      child: _GenderPill(
                          label: tr(context).genderGirl, selected: gender == 'female', height: pillH,
                          onTap: () => onGender('female'))),
                  SizedBox(width: g.l(10)),
                  Expanded(
                      flex: 9,
                      child: _GenderPill(
                          label: tr(context).preferNotToSay, selected: gender.isEmpty, height: pillH,
                          onTap: () => onGender(''))),
                ],
              ),
            ),

            SizedBox(
              height: headingH,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(tr(context).chooseAvatar,
                      style: kidTitleStyle(headingH * 0.56).copyWith(shadows: const [])),
                ),
              ),
            ),

            // ── Avatars 3×3 ────────────────────────────────────────────
            for (int row = 0; row < 3; row++) ...[
              if (row > 0) SizedBox(height: gap),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int col = 0; col < 3; col++)
                    if (row * 3 + col < AvatarCatalog.starter.length)
                      _AvatarCell(
                        path: AvatarCatalog.starter[row * 3 + col],
                        selected: AvatarCatalog.starter[row * 3 + col] == avatar,
                        size: cell,
                        onTap: () => onAvatar(AvatarCatalog.starter[row * 3 + col]),
                      ),
                ],
              ),
            ],
          ],
        );
      }),
    );
  }
}

class _GenderPill extends StatelessWidget {
  final String label;
  final bool selected;
  final double height;
  final VoidCallback onTap;

  const _GenderPill({required this.label, required this.selected, required this.height, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final h = height;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.95,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: h,
        padding: EdgeInsets.symmetric(horizontal: h * 0.22),
        decoration: BoxDecoration(
          color: selected ? KidColors.purpleLight : Colors.white,
          borderRadius: BorderRadius.circular(h),
          border: Border.all(
            color: selected ? KidColors.purple : const Color(0xFFC7B2F6),
            width: selected ? 3.5 : 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: KidColors.purple.withOpacity(selected ? 0.28 : 0.0),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    maxLines: 1,
                    style: kidBodyStyle(h * 0.34, color: KidColors.purpleDeep, weight: FontWeight.w700)),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              child: selected
                  ? Padding(
                      padding: EdgeInsetsDirectional.only(start: h * 0.12),
                      child: Container(
                        width: h * 0.42,
                        height: h * 0.42,
                        decoration: const BoxDecoration(color: KidColors.purple, shape: BoxShape.circle),
                        child: Icon(Icons.check_rounded, color: Colors.white, size: h * 0.3),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarCell extends StatelessWidget {
  final String path;
  final bool selected;
  final double size;
  final VoidCallback onTap;

  const _AvatarCell({required this.path, required this.selected, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = size;
    final badge = s * 0.24;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.92,
      child: AnimatedScale(
        scale: selected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: s,
          height: s,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: EdgeInsets.all(selected ? s * 0.05 : s * 0.035),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: selected ? KidColors.purple : const Color(0xFFE6DDF7),
                      width: selected ? s * 0.035 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: KidColors.purple.withOpacity(selected ? 0.35 : 0.12),
                        blurRadius: selected ? 14 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(child: Image.asset(path, fit: BoxFit.cover, filterQuality: FilterQuality.medium)),
                ),
              ),
              PositionedDirectional(
                top: 0,
                end: 0,
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
                      border: Border.all(color: Colors.white, width: badge * 0.1),
                    ),
                    child: Icon(Icons.check_rounded, color: Colors.white, size: badge * 0.6),
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
