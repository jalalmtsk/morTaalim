import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/screens/main_home_screen/Profile/Customize/profile_look.dart';
import 'package:mortaalim/screens/main_shop_screen/MainShopPageIndex.dart';
import 'package:provider/provider.dart';

import 'cw_common.dart';

/// "Frame workshop": try every frame on your own avatar.
class CwFramesPage extends StatefulWidget {
  const CwFramesPage({super.key});
  @override
  State<CwFramesPage> createState() => _CwFramesPageState();
}

class _CwFramesPageState extends State<CwFramesPage> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  late final AnimationController _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  String? _preview;

  @override
  void dispose() {
    _idle.dispose();
    _spin.dispose();
    _burst.dispose();
    super.dispose();
  }

  void _pick(String id) {
    if (id == _preview) return;
    cwSound(context, 'PopButton');
    setState(() => _preview = id);
    _spin.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final xp = context.watch<ExperienceManager>();
    final s = cwScale(context);
    final h = MediaQuery.sizeOf(context).height;
    bool owns(AvatarFrame f) => AvatarFrames.owned(f, xp.level, xp.unlockedAvatarFrames);
    final equipped = AvatarFrames.resolve(xp.selectedAvatarFrame);
    final shown = _preview ?? equipped;
    final shownFrame = AvatarFrames.of(shown);
    final ownedShown = shownFrame == null || owns(shownFrame);
    final isEquipped = shown == equipped;
    final ownedCount = AvatarFrames.all.where(owns).length;
    // "no frame" first, owned frames, then locked ones (closest first)
    final ids = <String>[
      AvatarFrames.none,
      ...AvatarFrames.all.where(owns).map((f) => f.id),
      ...AvatarFrames.all.where((f) => !owns(f)).map((f) => f.id),
    ];
    final heroH = (h * 0.32).clamp(230.0, 320.0);
    final btnW = min(MediaQuery.sizeOf(context).width * 0.78, 340 * s);

    return CwIslandLayout(
      s: s,
      header: Column(children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10 * s),
          child: Row(children: [
            CwBack(size: 48 * s),
            SizedBox(width: 6 * s),
            Expanded(child: CwTitlePill(title: cwT(context, 'frTitle'), s: s)),
            SizedBox(width: 30 * s),
          ]),
        ),
        SizedBox(height: 4 * s),
        CwChip(s: s, icon: Icons.filter_frames_rounded, text: cwT(context, 'frCount', {'n': ownedCount})),
      ]),
      heroHeight: heroH,
      hero: _hero(s, heroH, xp.selectedAvatar, shown, shownFrame, ownedShown, isEquipped),
      panel: Column(children: [
        CwPanelTitle(s: s, text: cwT(context, 'frPick')),
        SizedBox(height: 10 * s),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(bottom: 8 * s, top: 4 * s),
            itemCount: ids.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10 * s,
              crossAxisSpacing: 10 * s,
              childAspectRatio: 0.84,
            ),
            itemBuilder: (_, i) {
              final id = ids[i];
              final f = AvatarFrames.of(id);
              return _tile(s, xp.selectedAvatar, id, f, f == null || owns(f), id == shown, id == equipped);
            },
          ),
        ),
        SizedBox(height: 6 * s),
        if (ownedShown)
          CwButton(
            asset: cw('fr_btn_orange'),
            label: cwT(context, 'frChoose'),
            onTap: isEquipped
                ? null
                : () {
                    xp.unlockAvatarFrame(shown);
                    xp.selectAvatarFrame(shown);
                    cwCelebrate(context);
                    _burst.forward(from: 0);
                  },
            width: btnW,
            aspect: 0.2348,
            s: s,
            pulse: _idle,
          )
        else if ((shownFrame?.gems ?? 0) > 0)
          CwButton(
            asset: cw('av_btn_orange'),
            label: cwT(context, 'goShop'),
            onTap: () => cwOpen(context, const MainShopPageIndex()),
            width: btnW,
            aspect: 0.2687,
            s: s,
            leading: Icon(Icons.storefront_rounded, color: Colors.white, size: 22 * s),
          )
        else
          SizedBox(height: 50 * s),
        SizedBox(height: 4 * s),
        Text(
          _hint(shownFrame, ownedShown, isEquipped),
          textAlign: TextAlign.center,
          style: cwText(13.5 * s, color: cwInkSoft, weight: FontWeight.w500),
        ),
        CwBackLink(s: s),
      ]),
    );
  }

  String _hint(AvatarFrame? f, bool owned, bool eq) {
    if (owned) return eq ? cwT(context, 'frAlready') : cwT(context, 'avHint');
    if (f!.level > 0) return cwT(context, 'frLevel', {'n': f.level});
    return cwT(context, 'frGems', {'n': f.gems});
  }

  Widget _hero(double s, double heroH, String avatar, String id, AvatarFrame? f, bool owned, bool eq) =>
      LayoutBuilder(builder: (_, c) {
        final w = c.maxWidth;
        final av = min(heroH * 0.56, w * 0.42);
        final pedW = min(w * 0.62, 300 * s);
        return Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(child: CwSparkles(idle: _idle, count: 14, seed: 31)),
          Positioned(
            left: w * 0.55 - pedW / 2,
            width: pedW,
            bottom: heroH * 0.02,
            child: Image.asset(cw('fr_pedestal'), fit: BoxFit.contain),
          ),
          Positioned(
            left: w * 0.55 - av / 2,
            top: heroH * 0.06,
            width: av,
            height: av,
            child: CwFloat(
              idle: _idle,
              amp: 5 * s,
              speed: 1.5,
              child: AnimatedBuilder(
                animation: _spin,
                builder: (_, child) {
                  final t = _spin.value;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateY((1 - Curves.easeOutBack.transform(t)) * pi * 0.5)
                      ..scale(0.8 + 0.2 * Curves.elasticOut.transform(t)),
                    child: child,
                  );
                },
                child: owned
                    ? FramedAvatar(avatar: avatar, frame: id, size: av, fill: const Color(0xFFDDEBFF))
                    : ColorFiltered(colorFilter: cwGrey, child: FramedAvatar(avatar: avatar, frame: id, size: av)),
              ),
            ),
          ),
          if (!owned)
            Positioned(
              left: w * 0.55 - 22 * s,
              top: heroH * 0.06 + av / 2 - 22 * s,
              child: Image.asset(cw('fr_lock'), width: 44 * s),
            ),
          Positioned.fill(child: CwBurst(anim: _burst)),
          PositionedDirectional(
            start: 0,
            bottom: heroH * 0.02,
            child: CwFloat(
              idle: _idle,
              amp: 4,
              speed: 1.5,
              tilt: 0.04,
              child: Transform.flip(flipX: cwRtl(context), child: Image.asset(cw('fr_robot'), height: heroH * 0.8)),
            ),
          ),
          if (eq)
            Positioned(
              left: w * 0.55 - 70 * s,
              width: 140 * s,
              bottom: 2 * s,
              child: Center(child: CwEquipped(s: s, text: cwT(context, 'equipped'))),
            ),
        ]);
      });

  Widget _tile(double s, String avatar, String id, AvatarFrame? f, bool owned, bool sel, bool eq) {
    return CwPress(
      onTap: () => _pick(id),
      label: f == null ? cwT(context, 'noFrame') : id,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.all(6 * s),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFE7FBFA) : const Color(0xFFF7EFE0),
          borderRadius: BorderRadius.circular(20 * s),
          border: Border.all(color: sel ? const Color(0xFF34E0D6) : Colors.transparent, width: 3 * s),
          boxShadow: sel ? [BoxShadow(color: const Color(0xFF34E0D6).withOpacity(0.5), blurRadius: 12 * s)] : const [],
        ),
        child: Column(children: [
          Expanded(
            child: LayoutBuilder(builder: (_, c) {
              final sz = min(c.maxWidth, c.maxHeight);
              final pic = FramedAvatar(avatar: avatar, frame: id, size: sz * 0.92);
              return Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                owned ? pic : ColorFiltered(colorFilter: cwGrey, child: Opacity(opacity: 0.8, child: pic)),
                if (!owned) Image.asset(cw('fr_lock'), width: sz * 0.32),
                if (eq) PositionedDirectional(top: -4 * s, end: -4 * s, child: Image.asset(cw('av_check'), width: 22 * s)),
              ]);
            }),
          ),
          SizedBox(height: 3 * s),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              f == null
                  ? cwT(context, 'noFrame')
                  : owned
                      ? _pretty(id)
                      : (f.level > 0 ? '⭐ Lv ${f.level}' : '💎 ${f.gems}'),
              maxLines: 1,
              style: cwText(12.5 * s, color: owned ? cwInk : cwInkSoft, weight: FontWeight.w600),
            ),
          ),
        ]),
      ),
    );
  }

  String _pretty(String id) => id.isEmpty ? '' : id[0].toUpperCase() + id.substring(1);
}
