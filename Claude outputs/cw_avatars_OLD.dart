import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/Manager/models/avatar_catalog.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:provider/provider.dart';

import 'cw_common.dart';

/// "Avatar island": try on avatars, see them full-body in a magic portal.
class CwAvatarsPage extends StatefulWidget {
  const CwAvatarsPage({super.key});
  @override
  State<CwAvatarsPage> createState() => _CwAvatarsPageState();
}

class _CwAvatarsPageState extends State<CwAvatarsPage> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final AnimationController _swap = AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..forward();
  late final AnimationController _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  String? _preview;
  int _tab = 0;

  @override
  void dispose() {
    _idle.dispose();
    _swap.dispose();
    _burst.dispose();
    super.dispose();
  }

  void _pick(String a) {
    if (a == _preview) return;
    cwSound(context, 'PopButton');
    setState(() => _preview = a);
    _swap.forward(from: 0);
  }

  void _equip(ExperienceManager xp, String a) {
    if (AvatarCatalog.starter.contains(a)) xp.unlockAvatar(a);
    xp.selectAvatar(a);
    cwCelebrate(context);
    _burst.forward(from: 0);
    _swap.forward(from: 0.3);
  }

  @override
  Widget build(BuildContext context) {
    final xp = context.watch<ExperienceManager>();
    final s = cwScale(context);
    final h = MediaQuery.sizeOf(context).height;
    final owned = AvatarCatalog.sanitizeUnlocked(xp.unlockedAvatars);
    final equipped = AvatarCatalog.resolve(xp.selectedAvatar);
    final shown = _preview ?? equipped;
    final list = switch (_tab) {
      1 => owned.where((a) => !AvatarCatalog.isCompanion(a)).toList(),
      2 => owned.where(AvatarCatalog.isCompanion).toList(),
      _ => owned,
    };
    final isEquipped = shown == equipped;
    final heroH = (h * 0.4).clamp(280.0, 400.0);

    return CwIslandLayout(
      s: s,
      header: Column(children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10 * s),
          child: Row(children: [
            CwBack(size: 48 * s),
            SizedBox(width: 6 * s),
            Expanded(child: CwTitlePill(title: cwT(context, 'avTitle'), s: s)),
            SizedBox(width: 30 * s),
          ]),
        ),
        SizedBox(height: 4 * s),
        CwChip(s: s, icon: Icons.people_alt_rounded, text: cwT(context, 'avCount', {'n': owned.length})),
      ]),
      heroHeight: heroH,
      hero: _hero(s, heroH, shown, isEquipped),
      panel: Column(children: [
        CwTabs(
          s: s,
          labels: [cwT(context, 'all'), cwT(context, 'kids'), cwT(context, 'friends')],
          icons: const [Icons.people_alt_rounded, Icons.person_rounded, Icons.pets_rounded],
          index: _tab,
          onTap: (i) => setState(() => _tab = i),
        ),
        SizedBox(height: 10 * s),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(top: 6 * s, bottom: 8 * s),
            itemCount: list.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8 * s,
              crossAxisSpacing: 6 * s,
              childAspectRatio: 270 / 266,
            ),
            itemBuilder: (_, i) => _card(s, list[i], list[i] == shown, list[i] == equipped),
          ),
        ),
        SizedBox(height: 6 * s),
        CwButton(
          asset: cw('av_btn_orange'),
          label: cwT(context, 'avChoose'),
          onTap: isEquipped ? null : () => _equip(xp, shown),
          width: min(MediaQuery.sizeOf(context).width * 0.78, 340 * s),
          aspect: 0.2687,
          s: s,
          pulse: _idle,
          leading: Icon(Icons.check_circle_rounded, color: Colors.white, size: 22 * s),
        ),
        SizedBox(height: 4 * s),
        Text(isEquipped ? cwT(context, 'avAlready') : cwT(context, 'avHint'),
            style: cwText(13.5 * s, color: cwInkSoft, weight: FontWeight.w500)),
        CwBackLink(s: s),
      ]),
    );
  }

  Widget _hero(double s, double heroH, String shown, bool isEquipped) => LayoutBuilder(builder: (_, c) {
        final w = c.maxWidth;
        final portalH = heroH * 0.74;
        final aspect = AvatarCatalog.fullAspect(shown);
        final portalW = min(portalH * max(aspect, 0.42), w * 0.5);
        final name = AvatarCatalog.nameOf(shown, cwLang(context));
        return Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(child: CwSparkles(idle: _idle, count: 16, seed: 21)),
          // pedestal
          Positioned(
            left: w / 2 - w * 0.3,
            width: w * 0.6,
            bottom: heroH * 0.04,
            child: Image.asset(cw('av_pedestal'), fit: BoxFit.contain),
          ),
          // magic portal with the full-body character
          Positioned(
            left: w / 2 - portalW / 2,
            width: portalW,
            top: heroH * 0.02,
            height: portalH,
            child: CwFloat(
              idle: _idle,
              amp: 4 * s,
              speed: 1.5,
              child: AnimatedBuilder(
                animation: _swap,
                builder: (_, child) {
                  final t = Curves.elasticOut.transform(_swap.value.clamp(0.0, 1.0));
                  return Transform.scale(scale: 0.7 + 0.3 * t, alignment: Alignment.bottomCenter, child: child);
                },
                child: _Portal(s: s, image: AvatarCatalog.fullBody(shown), aspect: aspect, idle: _idle, glow: isEquipped),
              ),
            ),
          ),
          Positioned.fill(child: CwBurst(anim: _burst)),
          // guide robot + bubble
          PositionedDirectional(
            start: 0,
            top: heroH * 0.06,
            child: CwFloat(
              idle: _idle,
              amp: 3,
              speed: 2,
              phase: 0.4,
              child: CwBubble(text: cwT(context, 'avAsk'), width: w * 0.3, flip: cwRtl(context)),
            ),
          ),
          PositionedDirectional(
            start: 2 * s,
            bottom: heroH * 0.1,
            child: CwFloat(
              idle: _idle,
              amp: 5,
              speed: 1.5,
              tilt: 0.05,
              child: Transform.flip(flipX: cwRtl(context), child: Image.asset(cw('av_robot'), width: w * 0.24)),
            ),
          ),
          // name + equipped
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (name.isNotEmpty) CwPlaque(s: s, text: name, width: 150 * s, fontSize: 19),
              SizedBox(height: 3 * s),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: isEquipped
                    ? CwEquipped(key: const ValueKey('eq'), s: s, text: cwT(context, 'equipped'))
                    : SizedBox(key: const ValueKey('no'), height: 28 * s),
              ),
            ]),
          ),
        ]);
      });

  Widget _card(double s, String a, bool sel, bool eq) {
    final name = AvatarCatalog.nameOf(a, cwLang(context));
    return CwPress(
      onTap: () => _pick(a),
      label: name,
      child: LayoutBuilder(builder: (_, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final kx = w / 270, ky = h / 266;
        const cx = 137.5, cy = 109.0, r = 97.0;
        return Stack(clipBehavior: Clip.none, children: [
          // avatar inside the gold ring
          Positioned(
            left: (cx - r - 2) * kx,
            top: (cy - r - 2) * ky,
            width: (2 * r + 4) * kx,
            height: (2 * r + 4) * ky,
            child: ClipOval(
              child: sel
                  ? CwFloat(idle: _idle, amp: 1.5 * s, speed: 3, child: Image.asset(a, fit: BoxFit.cover))
                  : Image.asset(a, fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(child: Image.asset(cw('av_card'), fit: BoxFit.fill)),
          // selection glow
          if (sel)
            Positioned(
              left: (cx - r - 4) * kx,
              top: (cy - r - 4) * ky,
              width: (2 * r + 8) * kx,
              height: (2 * r + 8) * ky,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF34E0D6), width: 3 * s),
                    boxShadow: [BoxShadow(color: const Color(0xFF34E0D6).withOpacity(0.7), blurRadius: 10 * s)],
                  ),
                ),
              ),
            ),
          // name on the stone
          Positioned(
            left: 62 * kx,
            right: 62 * kx,
            top: 213 * ky,
            height: 40 * ky,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(name, maxLines: 1, style: cwText(13 * s, weight: FontWeight.w600)),
              ),
            ),
          ),
          if (eq)
            PositionedDirectional(
              top: -2 * s,
              end: 2 * s,
              child: Image.asset(cw('av_check'), width: 24 * s),
            ),
        ]);
      }),
    );
  }
}

/// Arched golden portal showing a full-body picture.
class _Portal extends StatelessWidget {
  final double s, aspect;
  final String image;
  final Animation<double> idle;
  final bool glow;
  const _Portal({required this.s, required this.image, required this.aspect, required this.idle, required this.glow});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.vertical(top: Radius.circular(400), bottom: Radius.circular(22 * s));
    return AnimatedBuilder(
      animation: idle,
      builder: (_, child) {
        final g = 0.45 + 0.25 * sin(idle.value * 2 * pi * 3);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(color: (glow ? const Color(0xFF34E0D6) : const Color(0xFFFFE08A)).withOpacity(g), blurRadius: 26 * s, spreadRadius: 2 * s),
            ],
          ),
          child: child,
        );
      },
      child: Container(
        padding: EdgeInsets.all(5 * s),
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE9A0), Color(0xFFE2A93B), Color(0xFFFFD86B), Color(0xFFC98A1E)],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: const Radius.circular(400), bottom: Radius.circular(18 * s)),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Image.asset(
              image,
              key: ValueKey(image),
              fit: BoxFit.cover,
              alignment: aspect > 0.5 ? Alignment.center : const Alignment(0, 0.15),
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFDDEBFF)),
            ),
          ),
        ),
      ),
    );
  }
}
