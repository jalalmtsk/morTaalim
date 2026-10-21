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

  void _buy(ExperienceManager xp, String a) {
    final cost = AvatarCatalog.costOf(a);
    if (xp.gems < cost) {
      cwSound(context, 'clickButton2');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(cwT(context, 'avNoGems'))));
      return;
    }
    xp.spendGems(context, cost);
    xp.unlockAvatar(a);
    _equip(xp, a);
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
    // owned avatars first, then the locked ones
    final everyone = [...owned, ...AvatarCatalog.all.where((a) => !owned.contains(a))];
    final list = switch (_tab) {
      1 => everyone.where((a) => !AvatarCatalog.isCompanion(a)).toList(),
      2 => everyone.where(AvatarCatalog.isCompanion).toList(),
      _ => everyone,
    };
    final isEquipped = shown == equipped;
    final isLocked = !owned.contains(shown);
    final cost = AvatarCatalog.costOf(shown);
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
        CwChip(s: s, icon: Icons.people_alt_rounded, text: '${cwT(context, 'avCount', {'n': owned.length})} / ${AvatarCatalog.all.length}'),
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
            itemBuilder: (_, i) => _card(s, list[i], list[i] == shown, list[i] == equipped, !owned.contains(list[i])),
          ),
        ),
        SizedBox(height: 6 * s),
        CwButton(
          asset: cw('av_btn_orange'),
          label: isLocked ? '${cwT(context, 'avUnlock')}  💎 $cost' : cwT(context, 'avChoose'),
          onTap: isEquipped ? null : (isLocked ? () => _buy(xp, shown) : () => _equip(xp, shown)),
          width: min(MediaQuery.sizeOf(context).width * 0.78, 340 * s),
          aspect: 0.2687,
          s: s,
          pulse: _idle,
          leading: Icon(isLocked ? Icons.lock_open_rounded : Icons.check_circle_rounded, color: Colors.white, size: 22 * s),
        ),
        SizedBox(height: 4 * s),
        Text(isEquipped ? cwT(context, 'avAlready') : (isLocked ? cwT(context, 'avLocked') : cwT(context, 'avHint')),
            style: cwText(13.5 * s, color: cwInkSoft, weight: FontWeight.w500)),
        CwBackLink(s: s),
      ]),
    );
  }

  Widget _hero(double s, double heroH, String shown, bool isEquipped) => LayoutBuilder(builder: (_, c) {
        final w = c.maxWidth;
        final aspect = AvatarCatalog.fullAspect(shown);
        final name = AvatarCatalog.nameOf(shown, cwLang(context));
        // pedestal (420 × 174 sprite, top of the stone ≈ 35 % from its top)
        final pedW = w * 0.62;
        final pedH = pedW * 174 / 420;
        final pedBottom = heroH * 0.03;
        final feet = pedBottom + pedH * 0.58;
        // character standing on it, full body, no background
        var charH = heroH - feet - heroH * 0.03;
        var charW = charH * aspect;
        if (charW > w * 0.56) {
          charW = w * 0.56;
          charH = charW / aspect;
        }
        return Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(child: CwSparkles(idle: _idle, count: 16, seed: 21)),
          // magic aura behind the character
          Positioned(
            left: w / 2 - charH * 0.55,
            width: charH * 1.1,
            bottom: feet - charH * 0.05,
            height: charH * 1.05,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _idle,
                builder: (_, __) {
                  final g = 0.55 + 0.2 * sin(_idle.value * 2 * pi * 3);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        (isEquipped ? const Color(0xFF8DF5EE) : const Color(0xFFFFF0B0)).withOpacity(g),
                        (isEquipped ? const Color(0xFF34E0D6) : const Color(0xFFFFD86B)).withOpacity(0),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),
          // pedestal
          Positioned(
            left: w / 2 - pedW / 2,
            width: pedW,
            bottom: pedBottom,
            child: Image.asset(cw('av_pedestal'), fit: BoxFit.contain),
          ),
          // soft shadow under the feet
          Positioned(
            left: w / 2 - charW * 0.45,
            width: charW * 0.9,
            bottom: feet - charH * 0.035,
            height: charH * 0.07,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.elliptical(charW, charH * 0.07)),
                  gradient: RadialGradient(colors: [Colors.black.withOpacity(0.32), Colors.black.withOpacity(0)]),
                ),
              ),
            ),
          ),
          // the character
          Positioned(
            left: w / 2 - charW / 2,
            width: charW,
            bottom: feet,
            height: charH,
            child: AnimatedBuilder(
              animation: Listenable.merge([_swap, _idle]),
              builder: (_, child) {
                final t = Curves.elasticOut.transform(_swap.value.clamp(0.0, 1.0));
                final breathe = 1 + 0.012 * sin(_idle.value * 2 * pi * 4);
                return Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.diagonal3Values(0.7 + 0.3 * t, (0.7 + 0.3 * t) * breathe, 1),
                  child: child,
                );
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Image.asset(
                  AvatarCatalog.fullBody(shown),
                  key: ValueKey(shown),
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (_, __, ___) => Image.asset(shown, fit: BoxFit.contain),
                ),
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
          // name + equipped (top corner, so the feet stay visible)
          PositionedDirectional(
            end: 4 * s,
            top: heroH * 0.06,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (name.isNotEmpty) CwPlaque(s: s, text: name, width: 130 * s, fontSize: 18),
              SizedBox(height: 3 * s),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: isEquipped
                    ? CwEquipped(key: const ValueKey('eq'), s: s, text: cwT(context, 'equipped'))
                    : const SizedBox(key: ValueKey('no')),
              ),
            ]),
          ),
        ]);
      });

  Widget _card(double s, String a, bool sel, bool eq, bool locked) {
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
              child: locked
                  ? ColorFiltered(colorFilter: _grey, child: Image.asset(a, fit: BoxFit.cover))
                  : (sel
                      ? CwFloat(idle: _idle, amp: 1.5 * s, speed: 3, child: Image.asset(a, fit: BoxFit.cover))
                      : Image.asset(a, fit: BoxFit.cover)),
            ),
          ),
          if (locked)
            Positioned(
              left: 0,
              right: 0,
              top: (cy + r * 0.35) * ky,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 1.5 * s),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12 * s)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.lock_rounded, size: 12 * s, color: const Color(0xFF6A3FC4)),
                    Text(' 💎${AvatarCatalog.costOf(a)}', style: cwText(10.5 * s, weight: FontWeight.w700)),
                  ]),
                ),
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

const ColorFilter _grey = ColorFilter.matrix(<double>[
  0.3, 0.5, 0.1, 0, 25, //
  0.3, 0.5, 0.1, 0, 25,
  0.3, 0.5, 0.1, 0, 25,
  0, 0, 0, 1, 0,
]);
