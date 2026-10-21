import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';

import 'mk_data.dart';
import 'mk_play.dart';

/// Le petit marché — home screen.
class MarketMenu extends StatefulWidget {
  const MarketMenu({super.key});
  @override
  State<MarketMenu> createState() => _MarketMenuState();
}

class _MarketMenuState extends State<MarketMenu> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..forward();
  List<int> _stars = List.filled(mkLevels.length, 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final st = await MkStore.stars();
    if (mounted) setState(() => _stars = st);
  }

  @override
  void dispose() {
    _idle.dispose();
    _intro.dispose();
    super.dispose();
  }

  Future<void> _playNext() async {
    mkSound(context, 'PopButton');
    if (!await MkStore.seenHelp()) {
      if (!mounted) return;
      await showMkHelp(context);
      await MkStore.setSeenHelp();
    }
    if (!mounted) return;
    await mkOpenLevel(context, MkStore.next(_stars));
    _load();
  }

  Future<void> _openMap([int? world]) async {
    mkSound(context, 'clickButton');
    await Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => MarketMap(focusWorld: world),
      transitionsBuilder: (_, a, __, c) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: 1.06, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: c),
      ),
    ));
    _load();
  }

  Widget _step(int i, Widget c) {
    final a = CurvedAnimation(parent: _intro, curve: Interval(min(0.08 * i, 0.6), min(0.45 + 0.08 * i, 1.0), curve: Curves.easeOutBack));
    return AnimatedBuilder(
      animation: a,
      builder: (_, child) => Opacity(
        opacity: a.value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - a.value) * 30), child: child),
      ),
      child: c,
    );
  }

  @override
  Widget build(BuildContext context) => MkFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = mkScale(context);
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 520.0);
    final done = _stars.where((v) => v > 0).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5D9A8),
      body: Stack(children: [
        const Positioned.fill(child: MkBg()),
        SafeArea(
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
                  child: Row(children: [
                    mkRound(context, 'mk_back', 48 * s, () {
                      mkSound(context, 'cancelButton');
                      Navigator.of(context).maybePop();
                    }, flipRtl: true),
                    const Spacer(),
                    Consumer<AudioManager>(
                      builder: (_, a, __) => Opacity(
                        opacity: a.isBgMuted ? 0.5 : 1,
                        child: mkRound(context, 'mk_sound', 48 * s, () {
                          a.playEventSound('toggleButton');
                          a.toggleBgMute();
                        }),
                      ),
                    ),
                  ]),
                ),
                _step(
                  0,
                  AnimatedBuilder(
                    animation: _idle,
                    builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi) * 3 * s), child: c),
                    child: MkTitle(top: mkT(context, 'title1'), bottom: mkT(context, 'title2'), pill: mkT(context, 'tag'), width: min(w * 0.82, 340 * s)),
                  ),
                ),
                // characters
                Expanded(
                  child: _step(
                    1,
                    LayoutBuilder(builder: (_, c) {
                      final h = c.maxHeight;
                      return Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: -6 * s,
                          child: AnimatedBuilder(
                            animation: _idle,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(0, -sin(_idle.value * 2 * pi * 2).abs() * 4 * s),
                              child: child,
                            ),
                            child: Center(child: Image.asset(mk('mk_party'), height: min(h * 0.98, w * 0.62))),
                          ),
                        ),
                        PositionedDirectional(
                          start: 4 * s,
                          top: 0,
                          child: _sway(Image.asset(mk('mk_lantern'), height: min(h * 0.45, 110 * s)), 0),
                        ),
                        PositionedDirectional(
                          end: 4 * s,
                          top: h * 0.05,
                          child: _sway(Image.asset(mk('mk_lantern'), height: min(h * 0.35, 90 * s)), 0.4),
                        ),
                      ]);
                    }),
                  ),
                ),
                // panel
                _step(
                  2,
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 14 * s),
                    padding: EdgeInsets.fromLTRB(12 * s, 14 * s, 12 * s, 12 * s),
                    decoration: BoxDecoration(
                      color: mkCream.withOpacity(0.97),
                      borderRadius: BorderRadius.circular(30 * s),
                      border: Border.all(color: Colors.white, width: 3 * s),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 18 * s, offset: Offset(0, 6 * s))],
                    ),
                    child: Column(children: [
                      Row(children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i > 0) SizedBox(width: 8 * s),
                          Expanded(child: _worldCard(s, i)),
                        ],
                      ]),
                      SizedBox(height: 12 * s),
                      MkPlayButton(label: mkT(context, 'play'), onTap: _playNext, width: min(w * 0.72, 300 * s), s: s, pulse: _idle),
                      SizedBox(height: 8 * s),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Flexible(child: MkPillButton(label: mkT(context, 'choose'), icon: Icons.bar_chart_rounded, iconColor: mkInk, onTap: _openMap, s: s)),
                        SizedBox(width: 8 * s),
                        Flexible(
                          child: MkPillButton(
                            label: mkT(context, 'how'),
                            icon: Icons.help_rounded,
                            iconColor: mkInk,
                            onTap: () {
                              mkSound(context, 'clickButton');
                              showMkHelp(context);
                            },
                            s: s,
                          ),
                        ),
                      ]),
                      SizedBox(height: 10 * s),
                      _progress(s, done),
                    ]),
                  ),
                ),
                SizedBox(height: 10 * s),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sway(Widget c, double phase) => AnimatedBuilder(
        animation: _idle,
        builder: (_, child) => Transform.rotate(alignment: Alignment.topCenter, angle: sin((_idle.value + phase) * 2 * pi) * 0.06, child: child),
        child: c,
      );

  Widget _worldCard(double s, int i) {
    const tints = [Color(0xFFDDF5EF), Color(0xFFFFEBD3), Color(0xFFE6E4FF)];
    final from = i * 4;
    final got = _stars.skip(from).take(4).where((v) => v > 0).length;
    final art = switch (i) {
      0 => Image.asset(mk('mk_basket_fruits'), height: 62 * s),
      1 => Image.asset(mk('mk_scale'), height: 50 * s),
      _ => SizedBox(
          height: 62 * s,
          width: 80 * s,
          child: Stack(alignment: Alignment.center, children: [
            Positioned(left: 4 * s, top: 14 * s, child: MkCoin(value: 5, size: 38 * s)),
            Positioned(right: 2 * s, top: 4 * s, child: MkCoin(value: 10, size: 42 * s)),
            Positioned(left: 24 * s, bottom: 0, child: MkCoin(value: 2, size: 32 * s)),
          ]),
        ),
    };
    return MkPress(
      onTap: () => _openMap(i),
      label: mkT(context, 'w$i'),
      child: Container(
        height: 112 * s,
        padding: EdgeInsets.all(6 * s),
        decoration: BoxDecoration(color: tints[i], borderRadius: BorderRadius.circular(20 * s)),
        child: Column(children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _idle,
              builder: (_, c) => Transform.translate(offset: Offset(0, sin((_idle.value * 2 + i * 0.3) * 2 * pi) * 2.5 * s), child: c),
              child: Center(child: art),
            ),
          ),
          FittedBox(fit: BoxFit.scaleDown, child: Text(mkT(context, 'w$i'), style: mkText(15 * s))),
          Text('$got / 4', style: mkText(11.5 * s, color: mkInkSoft, weight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _progress(double s, int done) => Container(
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30 * s),
          border: Border.all(color: const Color(0xFFF1DDB8), width: 2 * s),
        ),
        child: Row(children: [
          Icon(Icons.star_rounded, color: const Color(0xFFFFB800), size: 22 * s),
          SizedBox(width: 6 * s),
          Expanded(
            child: Row(children: [
              for (var i = 0; i < mkLevels.length; i++) ...[
                if (i > 0) Expanded(child: Container(height: 3 * s, color: i < done ? const Color(0xFFFFB800) : const Color(0xFFE4DCCB))),
                Container(
                  width: 11 * s,
                  height: 11 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < done ? const Color(0xFFFFB800) : const Color(0xFFE4DCCB),
                    border: Border.all(color: Colors.white, width: 1.5 * s),
                  ),
                ),
              ],
            ]),
          ),
          SizedBox(width: 8 * s),
          Text(mkT(context, 'done', {'n': done}), style: mkText(12 * s, color: mkInk, weight: FontWeight.w600)),
        ]),
      );
}

/// Opens a level and plays the next one when asked.
Future<void> mkOpenLevel(BuildContext context, int n) async {
  var level = n;
  while (context.mounted) {
    final next = await Navigator.of(context).push<int>(PageRouteBuilder<int>(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => MarketPlay(level: mkLevels[level - 1]),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
    if (next == null || next < 1 || next > mkLevels.length) return;
    level = next;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Level map — "Les chemins du souk"
// ═══════════════════════════════════════════════════════════════════════════

class MarketMap extends StatefulWidget {
  final int? focusWorld;
  const MarketMap({super.key, this.focusWorld});
  @override
  State<MarketMap> createState() => _MarketMapState();
}

class _MarketMapState extends State<MarketMap> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  late final AnimationController _walk = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..value = 1;
  final ScrollController _scroll = ScrollController();
  List<int> _stars = List.filled(mkLevels.length, 0);
  int _sel = 1;
  int _robotFrom = 1;
  int _shakeN = 0;

  // node positions on the map (x: fraction of width, y: map units)
  static const List<Offset> _nodes = [
    Offset(0.16, 150), Offset(0.40, 175), Offset(0.64, 165), Offset(0.84, 205),
    Offset(0.70, 330), Offset(0.45, 355), Offset(0.20, 390), Offset(0.36, 500),
    Offset(0.62, 520), Offset(0.84, 600), Offset(0.56, 690), Offset(0.26, 720),
  ];
  static const double _mapH = 860;

  @override
  void initState() {
    super.initState();
    _load(first: true);
  }

  Future<void> _load({bool first = false}) async {
    final st = await MkStore.stars();
    if (!mounted) return;
    setState(() {
      _stars = st;
      if (first) {
        _sel = widget.focusWorld != null ? widget.focusWorld! * 4 + 1 : MkStore.next(st);
        if (!MkStore.unlocked(st, _sel)) _sel = MkStore.next(st);
        _robotFrom = _sel;
      }
    });
    if (first) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(_sel, jump: true));
    }
  }

  void _scrollTo(int n, {bool jump = false}) {
    if (!_scroll.hasClients) return;
    final k = _k;
    final y = _nodes[n - 1].dy * k - _scroll.position.viewportDimension * 0.4;
    final target = y.clamp(0.0, _scroll.position.maxScrollExtent);
    if (jump) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(target, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    }
  }

  double _k = 1;

  @override
  void dispose() {
    _idle.dispose();
    _shake.dispose();
    _walk.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _tapNode(int n) {
    if (!MkStore.unlocked(_stars, n)) {
      mkSound(context, 'clickButton2');
      setState(() => _shakeN = n);
      _shake.forward(from: 0);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: mkInk,
          duration: const Duration(milliseconds: 1400),
          content: Text(mkT(context, 'locked'), style: mkText(15, color: Colors.white, weight: FontWeight.w600)),
        ));
      return;
    }
    mkSound(context, 'PopButton');
    setState(() {
      _robotFrom = _sel;
      _sel = n;
    });
    _walk.forward(from: 0);
  }

  Future<void> _play() async {
    mkSound(context, 'PopButton');
    await mkOpenLevel(context, _sel);
    await _load();
    if (!mounted) return;
    setState(() {
      _robotFrom = _sel;
      if (!MkStore.unlocked(_stars, _sel)) _sel = MkStore.next(_stars);
    });
  }

  @override
  Widget build(BuildContext context) => MkFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = mkScale(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 520.0);
    _k = w / 390;
    final lvl = mkLevels[_sel - 1];

    return Scaffold(
      backgroundColor: const Color(0xFFF2D19A),
      body: Stack(children: [
        const Positioned.fill(child: MkBg()),
        Center(
          child: SizedBox(
            width: w,
            child: SingleChildScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(top: pad.top + 110 * s, bottom: 260 * s + pad.bottom),
              child: SizedBox(width: w, height: _mapH * _k, child: _map(w, s)),
            ),
          ),
        ),
        // header
        Positioned(
          left: 0,
          right: 0,
          top: pad.top + 4 * s,
          child: Center(
            child: SizedBox(
              width: w,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 10 * s),
                mkRound(context, 'mk_back', 46 * s, () {
                  mkSound(context, 'cancelButton');
                  Navigator.of(context).maybePop();
                }, flipRtl: true),
                Expanded(child: Center(child: MkTitle(top: mkT(context, 'mapTitle1'), bottom: mkT(context, 'mapTitle2'), width: min(w * 0.6, 250 * s)))),
                Consumer<AudioManager>(
                  builder: (_, a, __) => Opacity(
                    opacity: a.isBgMuted ? 0.5 : 1,
                    child: mkRound(context, 'mk_sound', 46 * s, () {
                      a.playEventSound('toggleButton');
                      a.toggleBgMute();
                    }),
                  ),
                ),
                SizedBox(width: 10 * s),
              ]),
            ),
          ),
        ),
        // level card
        Positioned(
          left: 0,
          right: 0,
          bottom: pad.bottom + 8 * s,
          child: Center(child: _card(s, min(w - 20 * s, 420 * s), lvl)),
        ),
      ]),
    );
  }

  Offset _pt(int n, double w) => Offset(_nodes[n - 1].dx * w, _nodes[n - 1].dy * _k);

  Widget _map(double w, double s) {
    final k = _k;
    final nodeW = 70 * s;
    return AnimatedBuilder(
      animation: Listenable.merge([_idle, _walk, _shake]),
      builder: (_, __) {
        // robot walks from the old node to the selected one
        final a = _pt(_robotFrom, w), b = _pt(_sel, w);
        final t = Curves.easeInOut.transform(_walk.value);
        final hop = sin(t * pi * 4).abs() * 8 * s * (1 - _walk.value.clamp(0.0, 1.0) + (_walk.isAnimating ? 0.3 : 0));
        final rp = Offset.lerp(a, b, t)! + Offset(0, -hop);
        return Stack(clipBehavior: Clip.none, children: [
          // stone path
          Positioned.fill(child: CustomPaint(painter: _PathPainter([for (var i = 1; i <= mkLevels.length; i++) _pt(i, w)], s))),
          // decorations
          _deco('mk_fountain', Offset(w * 0.78, 760 * k), 110 * s),
          _deco('mk_basket_fruits', Offset(w * 0.12, 270 * k), 64 * s),
          _deco('mk_crate', Offset(w * 0.86, 440 * k), 92 * s),
          _deco('mk_plant1', Offset(w * 0.08, 600 * k), 64 * s),
          _deco('mk_plant3', Offset(w * 0.93, 300 * k), 52 * s),
          _deco('mk_plant2', Offset(w * 0.06, 470 * k), 46 * s),
          _deco('mk_scale', Offset(w * 0.86, 360 * k), 84 * s),
          _deco('mk_lantern', Offset(w * 0.53, 260 * k), 30 * s, sway: true),
          _deco('mk_lantern', Offset(w * 0.10, 760 * k), 36 * s, sway: true),
          // world signs
          _sign('mk_sign1', mkT(context, 's0'), Offset(w * 0.32, 70 * k), w * 0.5, s),
          _sign('mk_sign2', mkT(context, 's1'), Offset(w * 0.62, 268 * k), w * 0.46, s),
          _sign('mk_sign3', mkT(context, 's2'), Offset(w * 0.40, 600 * k), w * 0.46, s),
          // nodes
          for (var n = 1; n <= mkLevels.length; n++) _node(n, _pt(n, w), nodeW, s),
          // robot guide
          Positioned(
            left: rp.dx + nodeW * 0.25,
            top: rp.dy - 112 * s,
            child: IgnorePointer(
              child: Transform.translate(
                offset: Offset(0, sin(_idle.value * 2 * pi * 2) * 3 * s),
                child: Transform.flip(flipX: b.dx < a.dx, child: Image.asset(mk('mk_robot_point'), height: 92 * s)),
              ),
            ),
          ),
        ]);
      },
    );
  }

  Widget _deco(String a, Offset c, double width, {bool sway = false}) {
    Widget img = Image.asset(mk(a), width: width);
    if (sway) {
      img = Transform.rotate(alignment: Alignment.topCenter, angle: sin(_idle.value * 2 * pi) * 0.06, child: img);
    }
    return Positioned(left: c.dx - width / 2, top: c.dy - width / 2, child: IgnorePointer(child: img));
  }

  Widget _sign(String a, String text, Offset c, double width, double s) => Positioned(
        left: c.dx - width / 2,
        top: c.dy - width * 0.22,
        width: width,
        child: IgnorePointer(
          child: AspectRatio(
            aspectRatio: 1 / 0.46,
            child: Stack(children: [
              Positioned.fill(child: Image.asset(mk(a), fit: BoxFit.fill)),
              Positioned(
                left: width * 0.14,
                right: width * 0.14,
                top: width * 0.17,
                bottom: width * 0.08,
                child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, style: mkText(22 * s)))),
              ),
            ]),
          ),
        ),
      );

  Widget _node(int n, Offset c, double size, double s) {
    final st = _stars[n - 1];
    final open = MkStore.unlocked(_stars, n);
    final sel = n == _sel;
    final sprite = !open ? 'mk_node_lock' : (st > 0 && !sel ? 'mk_node_done' : 'mk_node_now');
    final shake = n == _shakeN ? sin(_shake.value * pi * 6) * 6 * (1 - _shake.value) : 0.0;
    final pulse = sel ? 1 + 0.06 * sin(_idle.value * 2 * pi * 3) : 1.0;
    return Positioned(
      left: c.dx - size / 2 + shake,
      top: c.dy - size * 0.55,
      width: size,
      height: size * 1.05,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _tapNode(n),
        child: Transform.scale(
          scale: pulse,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
            Image.asset(mk(sprite), width: size, fit: BoxFit.contain),
            // number on the dome (the "done" sprite already has stars at the bottom)
            Positioned(
              top: size * (sprite == 'mk_node_lock' ? 0.06 : 0.12),
              child: Text('$n',
                  style: mkText(size * 0.36, color: Colors.white, weight: FontWeight.w800)
                      .copyWith(shadows: [Shadow(color: Colors.black.withOpacity(0.35), offset: const Offset(0, 2), blurRadius: 2)])),
            ),
            if (open && st > 0 && sel)
              Positioned(bottom: -size * 0.06, child: Image.asset(mk('mk_stars$st'), height: size * 0.28)),
            if (open && st > 0 && st < 3 && !sel)
              Positioned(
                bottom: 0,
                child: Container(
                  width: size * 0.82,
                  height: size * 0.3,
                  decoration: BoxDecoration(color: const Color(0xFF14A3A8), borderRadius: BorderRadius.circular(size * 0.15)),
                  child: Center(child: Image.asset(mk('mk_stars$st'), height: size * 0.26)),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _card(double s, double width, MkLevel lvl) {
    final h = width * 0.4613;
    final art = switch (lvl.kind) {
      MkKind.basket => Image.asset(mk('mk_basket_fruits')),
      MkKind.scale => Image.asset(mk('mk_scale')),
      _ => Stack(alignment: Alignment.center, children: [MkCoin(value: 10, size: 56 * s), Positioned(left: 0, bottom: 0, child: MkCoin(value: 5, size: 40 * s))]),
    };
    return SizedBox(
      width: width,
      height: h,
      child: Stack(children: [
        Positioned.fill(child: Image.asset(mk('mk_level_card'), fit: BoxFit.fill)),
        // level pill text (on the top orange pill of the sprite)
        Positioned(
          left: width * 0.34,
          right: width * 0.34,
          top: h * 0.12,
          height: h * 0.17,
          child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(mkT(context, 'level', {'n': lvl.n}), style: mkText(18 * s, color: Colors.white)))),
        ),
        PositionedDirectional(
          start: width * 0.06,
          top: h * 0.28,
          width: width * 0.25,
          height: h * 0.55,
          child: AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi * 2) * 3 * s), child: c),
            child: art,
          ),
        ),
        Positioned(
          left: width * 0.3,
          right: width * 0.08,
          top: h * 0.32,
          height: h * 0.25,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(lvl.title(context), style: mkText(19 * s))),
            FittedBox(fit: BoxFit.scaleDown, child: Text(lvl.sub(context), style: mkText(13 * s, color: mkInkSoft, weight: FontWeight.w600))),
          ]),
        ),
        // play (the bottom pill of the sprite is the button)
        Positioned(
          left: width * 0.3,
          right: width * 0.08,
          bottom: h * 0.06,
          height: h * 0.3,
          child: MkPress(
            onTap: _play,
            label: mkT(context, 'play'),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: width * 0.1),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(mkT(context, 'play'),
                      style: mkText(24 * s, color: Colors.white).copyWith(shadows: const [Shadow(color: Color(0xFFB4410A), offset: Offset(0, 2))])),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _PathPainter extends CustomPainter {
  final List<Offset> pts;
  final double s;
  _PathPainter(this.pts, this.s);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      final m = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 + 18 * s);
      path.quadraticBezierTo(m.dx, m.dy, b.dx, b.dy);
    }
    // sandy road
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 46 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFF6E3BF).withOpacity(0.92),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 50 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFFD9B27A).withOpacity(0.35),
    );
    // stepping stones
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 22 * s) {
        final t = m.getTangentForOffset(d);
        if (t == null) continue;
        canvas.save();
        canvas.translate(t.position.dx, t.position.dy);
        canvas.rotate(t.angle);
        final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 14 * s, height: 8 * s), Radius.circular(3 * s));
        canvas.drawRRect(r, Paint()..color = const Color(0xFFD08A4E));
        canvas.drawRRect(r.shift(Offset(0, -1.2 * s)), Paint()..color = const Color(0xFFE9A866));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter o) => o.pts != pts;
}

// ═══════════════════════════════════════════════════════════════════════════
// "How to play" dialog
// ═══════════════════════════════════════════════════════════════════════════

Future<void> showMkHelp(BuildContext context) => showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'help',
      barrierColor: const Color(0x99301A6B),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (ctx, _, __) => const _HelpDialog(),
      transitionBuilder: (_, a, __, c) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
    );

class _HelpDialog extends StatelessWidget {
  const _HelpDialog();
  @override
  Widget build(BuildContext context) => MkFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = mkScale(context);
    final w = min(MediaQuery.sizeOf(context).width - 24, 440.0);
    Widget step(int n, String text, Widget art) => Expanded(
          child: Column(children: [
            CircleAvatar(radius: 13 * s, backgroundColor: mkTeal, child: Text('$n', style: mkText(14 * s, color: Colors.white))),
            SizedBox(height: 4 * s),
            SizedBox(height: 36 * s, child: Center(child: Text(text, textAlign: TextAlign.center, maxLines: 2, style: mkText(13 * s, weight: FontWeight.w600)))),
            SizedBox(height: 70 * s, child: Center(child: art)),
          ]),
        );
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: w,
          child: Stack(children: [
            Positioned.fill(child: Image.asset(mk('mk_dialog'), fit: BoxFit.fill)),
            Padding(
              padding: EdgeInsets.fromLTRB(22 * s, 20 * s, 22 * s, 20 * s),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(mkT(context, 'how'), style: mkText(26 * s)),
                SizedBox(height: 10 * s),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  step(1, mkT(context, 'h1'), Image.asset(mk('mk_clipboard'))),
                  step(2, mkT(context, 'h2'), Image.asset(mk('mk_hand'))),
                  step(3, mkT(context, 'h3'), Image.asset(mk('mk_basket_full'))),
                ]),
                SizedBox(height: 8 * s),
                Row(children: [
                  Image.asset(mk('mk_robot_think'), height: 70 * s),
                  SizedBox(width: 8 * s),
                  Expanded(child: MkFlatButton(label: mkT(context, 'go'), onTap: () => Navigator.pop(context), width: 220 * s, s: s)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
