import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/Manager/lesson_progress.dart';

import 'm1_kit.dart';
import 'm1_shell.dart';
import 'm1_text.dart';

/// "Mathématiques — 1re année primaire": the five games.
class M1Home extends StatefulWidget {
  final M1World world;
  const M1Home({super.key, this.world = m1MathWorld});
  @override
  State<M1Home> createState() => _M1HomeState();
}

class _M1HomeState extends State<M1Home> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  final Map<String, List<int>> _stars = {};

  @override
  void initState() {
    super.initState();
    m1LangOverride = widget.world.lang;
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _hello();
    });
  }

  M1World get _w => widget.world;
  List<M1Game> get _games => _w.games();
  void _hello() => M1Voice.say(context, '${m1T(context, _w.k('mathTitle'))}. ${m1T(context, _w.k('homeSay'))}');

  Future<void> _load() async {
    for (final g in _games) {
      final s = await M1Store.stars(g.id, g.levels);
      if (!mounted) return;
      setState(() => _stars[g.id] = s);
    }
  }

  @override
  void dispose() {
    if (m1LangOverride == widget.world.lang) m1LangOverride = null;
    _idle.dispose();
    M1Voice.stop();
    super.dispose();
  }

  Future<void> _open(M1Game g) async {
    M1Voice.stop();
    LessonProgress.record(_w.subject, _games.indexOf(g));
    await Navigator.of(context).push(m1Route(M1GameMenu(game: g)));
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFF6E9C8), body: M1Frame(child: Builder(builder: _page)));

  Widget _page(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = size.width, h = size.height - pad.vertical;
    final head = min(h * 0.27, 210.0);
    final foot = 52.0;
    final cardH = ((h - head - foot - 6 * 8) / 5).clamp(78.0, 118.0);
    return Stack(children: [
      M1Bg(asset: _w.homeBg),
      SafeArea(
        child: Column(children: [
          SizedBox(
            height: head,
            child: Stack(children: [
              PositionedDirectional(start: 10, top: 6, child: m1Round(context, _w.homeBack, 52, () => Navigator.of(context).maybePop(), flipRtl: true)),
              PositionedDirectional(end: 10, top: 6, child: m1Round(context, _w.homeSound, 52, _hello)),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: M1Swing(
                    child: M1Sign(
                      sprite: _w.homeSign,
                      title: m1T(context, _w.k('mathTitle')),
                      sub: m1T(context, _w.k('grade')),
                      width: min(w * 0.66, head * 0.74 / m1Ratio(_w.homeSign)),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              physics: const BouncingScrollPhysics(),
              children: [
                for (var i = 0; i < _games.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: M1SlideIn(delay: 90 * i, dy: 40, child: _card(_games[i], cardH, i)),
                  ),
              ],
            ),
          ),
          if (_w.homeExtra != null) Padding(padding: const EdgeInsets.only(bottom: 4), child: _w.homeExtra!(context)),
          SizedBox(
            height: foot,
            child: Center(
              child: m1OnSprite(_w.footerSprite, min(w * 0.72, 300.0), Text(m1T(context, _w.k('learnPlaying')), style: m1Text(18, color: const Color(0xFF5A2A0E))),
                  area: const EdgeInsets.fromLTRB(0.18, 0.18, 0.18, 0.22)),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _card(M1Game g, double hgt, int i) {
    final st = _stars[g.id];
    final done = st?.where((e) => e > 0).length ?? 0;
    final total = st?.fold<int>(0, (a, b) => a + b) ?? 0;
    return M1Press(
      onTap: () => _open(g),
      scale: 0.96,
      sound: 'PopButton',
      label: g.title(context),
      child: M1Card(
        height: hgt,
        radius: 22,
        padding: const EdgeInsets.all(6),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: SizedBox(
              width: min((hgt - 12) * 1.75, MediaQuery.sizeOf(context).width * 0.36),
              height: hgt - 12,
              child: Image.asset(m1(g.thumb), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text('${m1T(context, '${g.id}_t1')}\n${m1T(context, '${g.id}_t2')}', maxLines: 2, style: m1Text(hgt * 0.2, height: 1.05, weight: FontWeight.w800)),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(m1T(context, '${g.id}_home'), maxLines: 1, style: m1Text(hgt * 0.14, color: m1Blue, weight: FontWeight.w600)),
              ),
              const SizedBox(height: 3),
              Row(children: [
                Icon(Icons.star_rounded, color: m1Yellow, size: hgt * 0.16),
                Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(' $total/${g.levels * 3}', maxLines: 1, style: m1Text(hgt * 0.12, color: m1InkSoft)))),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: g.levels == 0 ? 0 : done / g.levels,
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE6DED0),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF22B8F0)),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.scale(scale: 1 + 0.05 * sin((_idle.value + i * 0.2) * 2 * pi), child: c),
            child: Container(
              width: hgt * 0.52,
              height: hgt * 0.52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFA23A), Color(0xFFF2620C)]),
                border: Border.all(color: const Color(0xFFFFD35A), width: 2.5),
                boxShadow: [BoxShadow(color: const Color(0xFFC9480A), offset: const Offset(0, 3)), BoxShadow(color: m1Orange.withOpacity(0.4), blurRadius: 10)],
              ),
              child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: hgt * 0.36),
            ),
          ),
          const SizedBox(width: 4),
        ]),
      ),
    );
  }
}
