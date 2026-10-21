import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/screens/main_home_screen/Profile/Badges/badge_catalog.dart';

import 'cw_common.dart';
import 'cw_treasures.dart' show CwProgress;

/// "Badge garden": every badge hangs on the magic tree.
class CwBadgesPage extends StatefulWidget {
  const CwBadgesPage({super.key});
  @override
  State<CwBadgesPage> createState() => _CwBadgesPageState();
}

class _CwBadgesPageState extends State<CwBadgesPage> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
  BadgeStats _s = BadgeStats.empty;
  int _tab = 0;
  AppBadge? _sel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = await CwProgress.load(context);
      if (!mounted) return;
      setState(() {
        _s = p.stats;
        final earned = appBadges.where((b) => b.earned(_s)).toList();
        _sel = earned.isNotEmpty ? earned.last : nextBadge(_s) ?? appBadges.first;
      });
    });
  }

  @override
  void dispose() {
    _idle.dispose();
    _pop.dispose();
    super.dispose();
  }

  void _pick(AppBadge b) {
    if (b == _sel) return;
    cwSound(context, b.earned(_s) ? 'PopButton' : 'clickButton2');
    setState(() => _sel = b);
    _pop.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final s = cwScale(context);
    final h = MediaQuery.sizeOf(context).height;
    final earned = appBadges.where((b) => b.earned(_s)).length;
    final list = switch (_tab) {
      1 => appBadges.where((b) => b.earned(_s)).toList(),
      2 => appBadges.where((b) => !b.earned(_s)).toList(),
      _ => appBadges,
    };
    final next = nextBadge(_s);
    final heroH = (h * 0.34).clamp(240.0, 340.0);

    return CwIslandLayout(
      s: s,
      header: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10 * s),
        child: Row(children: [
          CwBack(size: 48 * s),
          SizedBox(width: 6 * s),
          Expanded(child: CwTitlePill(title: cwT(context, 'bdTitle'), s: s)),
          SizedBox(width: 6 * s),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
            decoration: BoxDecoration(
              color: cwCream,
              borderRadius: BorderRadius.circular(18 * s),
              border: Border.all(color: Colors.white, width: 2 * s),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(cwT(context, 'bdCount', {'n': earned, 't': appBadges.length}), style: cwText(16 * s, color: cwPurpleDeep)),
              Text(cwT(context, 'bdUnlocked'), style: cwText(10.5 * s, color: cwInkSoft, weight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
      heroHeight: heroH,
      hero: _hero(s, heroH),
      panel: Column(children: [
        CwTabs(
          s: s,
          labels: [cwT(context, 'tabAll'), cwT(context, 'tabEarned'), cwT(context, 'tabLocked')],
          index: _tab,
          color: cwTeal,
          onTap: (i) => setState(() => _tab = i),
        ),
        SizedBox(height: 10 * s),
        Expanded(
          child: list.isEmpty
              ? Center(child: Text(cwT(context, 'nothing'), style: cwText(15 * s, color: cwInkSoft, weight: FontWeight.w500)))
              : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: 8 * s),
                  itemCount: list.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8 * s,
                    crossAxisSpacing: 6 * s,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (_, i) => _cell(s, list[i]),
                ),
        ),
        SizedBox(height: 6 * s),
        _nextCard(s, next),
        CwBackLink(s: s),
      ]),
    );
  }

  Widget _hero(double s, double heroH) => LayoutBuilder(builder: (_, c) {
        final w = c.maxWidth;
        final b = _sel;
        final got = b != null && b.earned(_s);
        final badgeW = min(w * 0.36, heroH * 0.5);
        return Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(child: CwSparkles(idle: _idle, count: 16, seed: 51)),
          // magic tree + gardener robot
          PositionedDirectional(
            start: -w * 0.04,
            top: 0,
            child: CwFloat(idle: _idle, amp: 2, speed: 0.8, child: Image.asset(cw('bd_tree'), width: w * 0.56)),
          ),
          PositionedDirectional(
            start: w * 0.02,
            bottom: 0,
            child: CwFloat(
              idle: _idle,
              amp: 3,
              speed: 1.5,
              tilt: 0.04,
              child: Transform.flip(flipX: cwRtl(context), child: Image.asset(cw('bd_robot'), height: heroH * 0.48)),
            ),
          ),
          if (b != null) ...[
            // featured badge
            PositionedDirectional(
              end: w * 0.06,
              top: 0,
              width: badgeW,
              height: badgeW,
              child: ScaleTransition(
                scale: CurvedAnimation(parent: _pop, curve: Curves.elasticOut),
                child: CwFloat(
                  idle: _idle,
                  amp: 4 * s,
                  speed: 2,
                  child: got
                      ? Image.asset(b.asset, fit: BoxFit.contain)
                      : Stack(alignment: Alignment.center, children: [
                          ColorFiltered(colorFilter: cwGrey, child: Image.asset(b.asset, fit: BoxFit.contain)),
                          Image.asset(cw('bd_lock'), width: badgeW * 0.3),
                        ]),
                ),
              ),
            ),
            // plaque
            PositionedDirectional(
              end: 4 * s,
              bottom: 6 * s,
              width: w * 0.5,
              child: Container(
                padding: EdgeInsets.fromLTRB(10 * s, 8 * s, 10 * s, 8 * s),
                decoration: BoxDecoration(
                  color: cwCream,
                  borderRadius: BorderRadius.circular(18 * s),
                  border: Border.all(color: const Color(0xFFE8C77A), width: 2 * s),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8 * s, offset: Offset(0, 3 * s))],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  FittedBox(fit: BoxFit.scaleDown, child: Text(b.name(context), maxLines: 1, style: cwText(17 * s, color: cwPurpleDeep))),
                  SizedBox(height: 2 * s),
                  Text(b.how(context),
                      maxLines: 2, textAlign: TextAlign.center, style: cwText(12 * s, color: cwInkSoft, weight: FontWeight.w500)),
                  SizedBox(height: 6 * s),
                  if (got)
                    SizedBox(
                      height: 30 * s,
                      child: Stack(alignment: Alignment.center, children: [
                        Image.asset(cw('bd_btn_green'), height: 30 * s, fit: BoxFit.contain),
                        Padding(
                          padding: EdgeInsetsDirectional.only(start: 22 * s),
                          child: Text(cwT(context, 'got'), style: cwText(13 * s, color: Colors.white)),
                        ),
                      ]),
                    )
                  else
                    _bar(s, b.ratio(_s), '${b.progress(_s)} / ${b.target}'),
                ]),
              ),
            ),
          ],
        ]);
      });

  Widget _bar(double s, double r, String label) => Row(children: [
        Expanded(
          child: Container(
            height: 11 * s,
            decoration: BoxDecoration(color: const Color(0xFFDDE3E8), borderRadius: BorderRadius.circular(10 * s)),
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: r.clamp(0.04, 1.0).toDouble(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF5BE3DA), cwTeal]),
                  borderRadius: BorderRadius.circular(10 * s),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 6 * s),
        Text(label, style: cwText(12 * s, color: cwInk)),
      ]);

  Widget _cell(double s, AppBadge b) {
    final got = b.earned(_s);
    final sel = b == _sel;
    return CwPress(
      onTap: () => _pick(b),
      label: b.name(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.all(3 * s),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFE7FBFA) : Colors.transparent,
          borderRadius: BorderRadius.circular(16 * s),
          border: Border.all(color: sel ? const Color(0xFF34E0D6) : Colors.transparent, width: 2.5 * s),
        ),
        child: Column(children: [
          Expanded(
            child: got
                ? (sel ? CwFloat(idle: _idle, amp: 2 * s, speed: 3, child: Image.asset(b.asset)) : Image.asset(b.asset))
                : Stack(alignment: Alignment.center, children: [
                    ColorFiltered(colorFilter: cwGrey, child: Opacity(opacity: 0.85, child: Image.asset(b.asset))),
                    Align(alignment: const Alignment(0, 0.6), child: Image.asset(cw('bd_lock'), width: 22 * s)),
                  ]),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(b.name(context), maxLines: 1, style: cwText(11.5 * s, color: got ? cwInk : cwInkSoft, weight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  Widget _nextCard(double s, AppBadge? next) {
    if (next == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8 * s),
        child: Text(cwT(context, 'allBadges'), style: cwText(16 * s, color: cwPurpleDeep)),
      );
    }
    final left = next.target - next.progress(_s);
    return CwPress(
      onTap: () => _pick(next),
      child: Container(
        padding: EdgeInsets.all(8 * s),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20 * s),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8 * s, offset: Offset(0, 3 * s))],
        ),
        child: Row(children: [
          SizedBox(
            width: 52 * s,
            height: 52 * s,
            child: Stack(alignment: Alignment.center, children: [
              ColorFiltered(colorFilter: cwGrey, child: Image.asset(next.asset)),
              Align(alignment: const Alignment(0, 0.7), child: Image.asset(cw('bd_lock'), width: 18 * s)),
            ]),
          ),
          SizedBox(width: 10 * s),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(cwT(context, 'nextBadge', {'name': next.name(context)}),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: cwText(15 * s, color: cwPurpleDeep)),
              Text(next.how(context), maxLines: 1, overflow: TextOverflow.ellipsis, style: cwText(12 * s, color: cwInkSoft, weight: FontWeight.w500)),
              SizedBox(height: 4 * s),
              _bar(s, next.ratio(_s), '${next.progress(_s)} / ${next.target}'),
              Text(cwT(context, 'left', {'n': left}), style: cwText(11 * s, color: cwInkSoft, weight: FontWeight.w500)),
            ]),
          ),
        ]),
      ),
    );
  }
}
