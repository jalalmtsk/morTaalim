import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';

import 'jd_data.dart';
import 'jd_garden.dart';
import 'jd_play.dart';

/// Mon jardin vivant — home screen.
class GardenMenu extends StatefulWidget {
  const GardenMenu({super.key});
  @override
  State<GardenMenu> createState() => _GardenMenuState();
}

class _GardenMenuState extends State<GardenMenu> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..forward();
  List<int> _stars = List.filled(jdLevels.length, 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final st = await JdStore.stars();
    if (mounted) setState(() => _stars = st);
  }

  @override
  void dispose() {
    _idle.dispose();
    _intro.dispose();
    super.dispose();
  }

  Future<void> _playNext() async {
    jdSound(context, 'PopButton');
    if (!await JdStore.seenHelp()) {
      if (!mounted) return;
      await showJdHelp(context);
      await JdStore.setSeenHelp();
    }
    if (!mounted) return;
    await jdOpenLevel(context, JdStore.next(_stars));
    _load();
  }

  Future<void> _openMap([int? world]) async {
    jdSound(context, 'clickButton');
    await Navigator.of(context).push(jdRoute(GardenMap(focusWorld: world)));
    _load();
  }

  Future<void> _openGarden() async {
    jdSound(context, 'clickButton');
    await Navigator.of(context).push(jdRoute(const MyGardenPage()));
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
  Widget build(BuildContext context) => JdFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = jdScale(context);
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 520.0);
    final found = JdStore.discoveredFrom(_stars).length;

    return Scaffold(
      backgroundColor: const Color(0xFFBFE3A0),
      body: Stack(children: [
        const Positioned.fill(child: JdBg(asset: 'jd_bg_home')),
        SafeArea(
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
                  child: Row(children: [
                    jdRound(context, 'jd_back', 48 * s, () {
                      jdSound(context, 'cancelButton');
                      Navigator.of(context).maybePop();
                    }, flipRtl: true),
                    const Spacer(),
                    jdMuteButton(context, 48 * s),
                  ]),
                ),
                // title
                _step(
                  0,
                  AnimatedBuilder(
                    animation: _idle,
                    builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi * 2) * 3 * s), child: c),
                    child: _title(s, w),
                  ),
                ),
                // scene
                Expanded(child: _step(1, _scene(s, w))),
                _step(2, _panel(s, w, found)),
                SizedBox(height: 8 * s),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _title(double s, double w) {
    final tw = min(w * 0.78, 300 * s);
    final th = tw * 0.4804;
    final words = [jdT(context, 't1'), jdT(context, 't2'), jdT(context, 't3')].where((e) => e.isNotEmpty).toList();
    const colors = [Color(0xFF7A2BE0), Color(0xFF13A6A0), Color(0xFFFF8A1F)];
    final line1 = words.length > 2 ? '${words[0]} ${words[1]}' : words.first;
    final line2 = words.length > 2 ? words[2] : (words.length > 1 ? words[1] : '');
    // each letter hops in turn
    Widget wave(String text, Color c, double size, int offset) => Row(mainAxisSize: MainAxisSize.min, children: [
          for (var k = 0; k < text.length; k++)
            AnimatedBuilder(
              animation: _idle,
              builder: (_, ch) {
                final ph = (_idle.value * 3 - (k + offset) * 0.06) % 1.0;
                final hop = ph < 0.18 ? sin(ph / 0.18 * pi) : 0.0;
                return Transform.translate(offset: Offset(0, -hop * size * 0.18), child: ch);
              },
              child: jdOutlined(text[k], k.isEven ? c : Color.lerp(c, Colors.white, 0.18)!, size, stroke: 0.2),
            ),
        ]);
    return JdPopIn(
      child: SizedBox(
        width: tw,
        height: th,
        child: Stack(children: [
          Positioned.fill(child: Image.asset(jd('jd_title_home'), fit: BoxFit.fill)),
          Positioned(
            left: tw * 0.12,
            right: tw * 0.12,
            top: th * 0.12,
            bottom: th * 0.36,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                wave(line1, colors[0], tw * 0.11, 0),
                if (line2.isNotEmpty) Transform.translate(offset: Offset(0, -tw * 0.02), child: wave(line2, colors[1], tw * 0.12, line1.length)),
              ]),
            ),
          ),
          Positioned(
            left: tw * 0.22,
            right: tw * 0.22,
            bottom: th * 0.08,
            height: th * 0.2,
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(jdT(context, 'tag').replaceAll('\n', ' '), style: jdText(14 * s, color: jdBrown))),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _scene(double s, double w) => LayoutBuilder(builder: (_, c) {
        final h = c.maxHeight;
        final t = _idle;
        final heroH = min(h * 0.8, w * 0.5);
        return Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
          // ground glow
          Positioned(
            left: w * 0.08,
            right: w * 0.08,
            bottom: -heroH * 0.05,
            height: heroH * 0.3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [const Color(0xFFFFF6C8).withOpacity(0.75), const Color(0x00FFF6C8)]),
              ),
            ),
          ),
          // kid planting (bobbing as he digs)
          Positioned(
            left: w * 0.06,
            bottom: 0,
            child: AnimatedBuilder(
              animation: t,
              builder: (_, ch) => Transform.translate(
                offset: Offset(0, sin(t.value * 2 * pi * 6).abs() * -4 * s),
                child: Transform.rotate(alignment: Alignment.bottomCenter, angle: sin(t.value * 2 * pi * 3) * 0.02, child: ch),
              ),
              child: Image.asset(jd('jd_kid_plant'), height: heroH * 0.95),
            ),
          ),
          // the little bean sprout growing & wiggling between them
          Positioned(
            left: w * 0.38,
            bottom: 0,
            child: AnimatedBuilder(
              animation: t,
              builder: (_, ch) => Transform.scale(
                alignment: Alignment.bottomCenter,
                scale: 0.92 + 0.08 * sin(t.value * 2 * pi * 2),
                child: Transform.rotate(alignment: Alignment.bottomCenter, angle: sin(t.value * 2 * pi * 4) * 0.05, child: ch),
              ),
              child: Image.asset(jd('jd_sprout_bean'), height: heroH * 0.45),
            ),
          ),
          // robot watering
          Positioned(
            right: w * 0.02,
            bottom: 0,
            child: AnimatedBuilder(
              animation: t,
              builder: (_, ch) => Transform.rotate(alignment: Alignment.bottomCenter, angle: -0.03 + sin(t.value * 2 * pi * 3) * 0.04, child: ch),
              child: Transform.flip(flipX: true, child: Image.asset(jd('jd_robot_water'), height: heroH)),
            ),
          ),
          // falling water drops from the can
          Positioned(
            right: w * 0.02 + heroH * 0.62,
            bottom: heroH * 0.12,
            width: heroH * 0.3,
            height: heroH * 0.45,
            child: IgnorePointer(child: AnimatedBuilder(animation: t, builder: (_, __) => CustomPaint(painter: _DropsPainter(t.value)))),
          ),
          // signpost with the garden words
          PositionedDirectional(
            start: 2 * s,
            top: 0,
            child: JdFloat(
              amp: 0,
              tilt: 0.03,
              period: const Duration(seconds: 4),
              child: SizedBox(
                width: min(w * 0.24, 92 * s),
                child: AspectRatio(
                  aspectRatio: 1 / 1.5444,
                  child: LayoutBuilder(builder: (_, b) {
                    final bw = b.maxWidth, bh = b.maxHeight;
                    return Stack(children: [
                      Positioned.fill(child: Image.asset(jd('jd_signpost'), fit: BoxFit.fill)),
                      for (var i = 0; i < 3; i++)
                        Positioned(
                          left: bw * 0.12,
                          right: bw * 0.1,
                          top: bh * (0.06 + i * 0.165),
                          height: bh * 0.13,
                          child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(jdT(context, 'sign$i'), style: jdText(13 * s, color: const Color(0xFF4A2408))))),
                        ),
                    ]);
                  }),
                ),
              ),
            ),
          ),
          // sunflower swaying
          PositionedDirectional(
            end: 4 * s,
            top: 0,
            child: AnimatedBuilder(
              animation: t,
              builder: (_, c) => Transform.rotate(alignment: Alignment.bottomCenter, angle: sin(t.value * 2 * pi * 2) * 0.06, child: c),
              child: Image.asset(jd('jd_sunflower'), width: min(w * 0.22, 86 * s)),
            ),
          ),
          // bird flying across, landing on the sign
          AnimatedBuilder(
            animation: t,
            builder: (_, c) {
              final p = (t.value * 2) % 1.0;
              final x = w * (1.1 - p * 1.3);
              final y = h * 0.08 + sin(p * pi * 4) * h * 0.06;
              return Positioned(left: x, top: y, child: Transform.rotate(angle: sin(p * pi * 8) * 0.12, child: c));
            },
            child: Image.asset(jd('jd_bird'), width: min(w * 0.13, 50 * s)),
          ),
          // two butterflies
          for (var b = 0; b < 2; b++)
            AnimatedBuilder(
              animation: t,
              builder: (_, c) {
                final a = t.value * 2 * pi + b * pi;
                return Positioned(
                  left: w * 0.45 + cos(a) * w * (0.28 - b * 0.08) - 20 * s,
                  top: h * (0.22 + b * 0.18) + sin(a * 2) * h * 0.12,
                  child: Transform.scale(scaleX: 0.6 + 0.4 * sin(a * 20).abs(), child: c),
                );
              },
              child: Image.asset(jd('jd_butterfly'), width: (34 - b * 8) * s),
            ),
        ]);
      });

  Widget _panel(double s, double w, int found) {
    final pw = w - 24 * s;
    final cw = (pw - 24 * s) / 3;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12 * s),
      padding: EdgeInsets.fromLTRB(6 * s, 8 * s, 6 * s, 10 * s),
      decoration: BoxDecoration(
        color: jdCream.withOpacity(0.96),
        borderRadius: BorderRadius.circular(30 * s),
        border: Border.all(color: Colors.white, width: 3 * s),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 18 * s, offset: Offset(0, 6 * s))],
      ),
      child: Column(children: [
        // three world cards
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          for (var i = 0; i < 3; i++)
            JdPopIn(
              delayMs: 150 + i * 120,
              child: JdPress(
                onTap: () => _openMap(i),
                label: jdT(context, 'w$i'),
                child: SizedBox(
                  width: cw,
                  height: cw * 0.86,
                  child: Stack(children: [
                    Positioned.fill(child: Image.asset(jd('jd_panel_sq'), fit: BoxFit.fill)),
                    Positioned(
                      left: cw * 0.12,
                      right: cw * 0.12,
                      top: cw * 0.08,
                      bottom: cw * 0.28,
                      child: AnimatedBuilder(
                        animation: _idle,
                        builder: (_, c) => Transform.translate(
                          offset: Offset(0, sin((_idle.value * 3 + i * 0.3) * 2 * pi) * 3 * s),
                          child: Transform.rotate(angle: sin((_idle.value * 3 + i * 0.3) * 2 * pi) * 0.05, child: c),
                        ),
                        child: Image.asset(jd(['jd_seed_sprout', 'jd_can_blue', 'jd_greenhouse'][i]), fit: BoxFit.contain),
                      ),
                    ),
                    Positioned(
                      left: cw * 0.1,
                      right: cw * 0.1,
                      bottom: cw * 0.1,
                      height: cw * 0.17,
                      child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(jdT(context, 'w$i'), style: jdText(15 * s, color: jdInk)))),
                    ),
                  ]),
                ),
              ),
            ),
        ]),
        SizedBox(height: 6 * s),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(children: [
              jdPlay(jdT(context, 'play'), _playNext, min(pw * 0.68, 260 * s), pulse: _idle),
              SizedBox(height: 6 * s),
              JdSpriteButton(
                sprite: 'jd_pill_level',
                ratio: 0.2444,
                start: 0.08,
                end: 0.08,
                label: jdT(context, 'choose'),
                onTap: _openMap,
                width: min(pw * 0.56, 215 * s),
                shadow: Colors.transparent,
              ).withInk(),
              SizedBox(height: 2 * s),
              JdPress(
                onTap: () {
                  jdSound(context, 'clickButton');
                  showJdHelp(context);
                },
                label: jdT(context, 'how'),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4 * s),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    JdFloat(amp: 0, tilt: 0.12, period: const Duration(milliseconds: 1600), child: Image.asset(jd('jd_help'), width: 28 * s)),
                    SizedBox(width: 6 * s),
                    Text(jdT(context, 'how'), style: jdText(14 * s, color: jdInk)),
                  ]),
                ),
              ),
            ]),
          ),
          // my garden card
          JdPress(
            onTap: _openGarden,
            label: jdT(context, 'myGarden'),
            child: JdFloat(
              amp: 2.5 * s,
              period: const Duration(milliseconds: 2800),
              child: SizedBox(
                width: min(pw * 0.32, 124 * s),
                child: AspectRatio(
                  aspectRatio: 1 / 0.7227,
                  child: LayoutBuilder(builder: (_, b) {
                    final bw = b.maxWidth, bh = b.maxHeight;
                    return Stack(children: [
                      Positioned.fill(child: Image.asset(jd('jd_garden_card'), fit: BoxFit.fill)),
                      Positioned(
                        left: bw * 0.44,
                        right: bw * 0.07,
                        top: bh * 0.28,
                        bottom: bh * 0.14,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            Text(jdT(context, 'myGarden'), style: jdText(11 * s, color: jdBrown)),
                            Text(jdT(context, 'found', {'n': found}), style: jdText(12 * s, color: jdInk, height: 1.1)),
                          ]),
                        ),
                      ),
                    ]);
                  }),
                ),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

/// Water drops falling from the watering can.
class _DropsPainter extends CustomPainter {
  final double t;
  _DropsPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(3);
    final p = Paint()..color = const Color(0xFF6CC8FF).withOpacity(0.85);
    for (var i = 0; i < 9; i++) {
      final x = r.nextDouble() * size.width;
      final y = ((t * 10 + r.nextDouble()) % 1.0) * size.height;
      canvas.drawOval(Rect.fromCenter(center: Offset(x - y * 0.15, y), width: 4, height: 8), p);
    }
  }

  @override
  bool shouldRepaint(_DropsPainter o) => o.t != t;
}

extension on JdSpriteButton {
  /// Same button but with purple text (used on the cream "Choose a level" pill).
  Widget withInk() => _InkSpriteButton(this);
}

class _InkSpriteButton extends StatelessWidget {
  final JdSpriteButton b;
  const _InkSpriteButton(this.b);
  @override
  Widget build(BuildContext context) {
    final h = b.width * b.ratio;
    return JdPress(
      onTap: b.onTap,
      label: b.label,
      child: SizedBox(
        width: b.width,
        height: h,
        child: Stack(children: [
          Positioned.fill(child: Image.asset(jd(b.sprite), fit: BoxFit.fill)),
          PositionedDirectional(
            start: b.width * b.start,
            end: b.width * b.end,
            top: 0,
            bottom: 0,
            child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(b.label, style: jdText(h * 0.36, color: jdInk)))),
          ),
        ]),
      ),
    );
  }
}

Widget jdMuteButton(BuildContext context, double size) => Consumer<AudioManager>(
      builder: (_, a, __) => Opacity(
        opacity: a.isBgMuted ? 0.5 : 1,
        child: jdRound(context, 'jd_sound', size, () {
          a.playEventSound('toggleButton');
          a.toggleBgMute();
        }),
      ),
    );

PageRoute<T> jdRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, c) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: 1.05, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: c),
      ),
    );

/// Opens a level and keeps playing the next one when asked.
Future<void> jdOpenLevel(BuildContext context, int n) async {
  var level = n;
  while (context.mounted) {
    final next = await Navigator.of(context).push<int>(PageRouteBuilder<int>(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => GardenPlay(level: jdLevels[level - 1]),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
    if (next == null) return;
    if (next == -1) {
      // "see my garden" from the end screen
      if (context.mounted) await Navigator.of(context).push(jdRoute(const MyGardenPage()));
      return;
    }
    if (next < 1 || next > jdLevels.length) return;
    level = next;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Level map — "Les sentiers du jardin"
// ═══════════════════════════════════════════════════════════════════════════

class GardenMap extends StatefulWidget {
  final int? focusWorld;
  const GardenMap({super.key, this.focusWorld});
  @override
  State<GardenMap> createState() => _GardenMapState();
}

class _GardenMapState extends State<GardenMap> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  late final AnimationController _walk = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..value = 1;
  List<int> _stars = List.filled(jdLevels.length, 0);
  int _sel = 1, _robotFrom = 1, _shakeN = 0;

  // node centres on the painted map (941 × 1000 image)
  static const List<Offset> _nodes = [
    Offset(272, 180), Offset(212, 290), Offset(133, 400), Offset(212, 495),
    Offset(300, 640), Offset(415, 788), Offset(607, 855), Offset(776, 813),
    Offset(820, 690), Offset(861, 545), Offset(868, 407), Offset(817, 297),
  ];
  static const Rect _focus = Rect.fromLTRB(40, 70, 941, 930); // part of the image that must stay visible
  static const double _imgW = 941, _imgH = 1000, _node = 128;

  @override
  void initState() {
    super.initState();
    _load(first: true);
  }

  Future<void> _load({bool first = false}) async {
    final st = await JdStore.stars();
    if (!mounted) return;
    setState(() {
      _stars = st;
      if (first) {
        _sel = widget.focusWorld != null ? widget.focusWorld! * 4 + 1 : JdStore.next(st);
        if (!JdStore.unlocked(st, _sel)) _sel = JdStore.next(st);
        _robotFrom = _sel;
      }
    });
  }

  @override
  void dispose() {
    _idle.dispose();
    _shake.dispose();
    _walk.dispose();
    super.dispose();
  }

  void _tapNode(int n) {
    if (!JdStore.unlocked(_stars, n)) {
      jdSound(context, 'clickButton2');
      setState(() => _shakeN = n);
      _shake.forward(from: 0);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: jdInk,
          duration: const Duration(milliseconds: 1400),
          content: Text(jdT(context, 'locked'), style: jdText(15, color: Colors.white, weight: FontWeight.w600)),
        ));
      return;
    }
    jdSound(context, 'PopButton');
    setState(() {
      _robotFrom = _sel;
      _sel = n;
    });
    _walk.forward(from: 0);
  }

  Future<void> _play() async {
    jdSound(context, 'PopButton');
    await jdOpenLevel(context, _sel);
    await _load();
    if (!mounted) return;
    setState(() {
      _robotFrom = _sel;
      if (!JdStore.unlocked(_stars, _sel)) _sel = JdStore.next(_stars);
    });
  }

  @override
  Widget build(BuildContext context) => JdFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = jdScale(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 520.0);
    final lvl = jdLevels[_sel - 1];
    final cardW = min(w - 20 * s, 400 * s);
    final headerH = 98 * s;
    final cardH = cardW * 0.5607;

    return Scaffold(
      backgroundColor: const Color(0xFF9CCB6A),
      body: Stack(children: [
        const Positioned.fill(child: JdBg(asset: 'jd_bg_map')),
        // the painted garden
        Positioned(
          left: 0,
          right: 0,
          top: pad.top + headerH * 0.75,
          bottom: pad.bottom + cardH * 0.92,
          child: LayoutBuilder(builder: (_, c) => _map(c.maxWidth, c.maxHeight, s)),
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
                jdRound(context, 'jd_back', 46 * s, () {
                  jdSound(context, 'cancelButton');
                  Navigator.of(context).maybePop();
                }, flipRtl: true),
                Expanded(
                  child: Center(
                    child: JdTitle(top: jdT(context, 'mapTitle1'), bottom: jdT(context, 'mapTitle2'), width: min(w * 0.6, 240 * s)),
                  ),
                ),
                jdMuteButton(context, 46 * s),
                SizedBox(width: 10 * s),
              ]),
            ),
          ),
        ),
        // level card
        Positioned(left: 0, right: 0, bottom: pad.bottom + 8 * s, child: Center(child: _card(s, cardW, lvl))),
      ]),
    );
  }

  Widget _map(double aw, double ah, double s) {
    // fit the focus area inside the available box
    final k = min(aw / _focus.width, ah / _focus.height);
    final ox = (aw - _focus.width * k) / 2 - _focus.left * k;
    final oy = (ah - _focus.height * k) / 2 - _focus.top * k;
    Offset pt(int n) => Offset(ox + _nodes[n - 1].dx * k, oy + _nodes[n - 1].dy * k);
    final nodeW = _node * k;
    return ClipRect(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
          stops: [0, 0.06, 0.94, 1],
        ).createShader(r),
        child: AnimatedBuilder(
          animation: Listenable.merge([_idle, _walk, _shake]),
          builder: (_, __) {
            final a = pt(_robotFrom), b = pt(_sel);
            final t = Curves.easeInOut.transform(_walk.value);
            final hop = _walk.isAnimating ? sin(t * pi * 5).abs() * 10 * s : 0.0;
            final rp = Offset.lerp(a, b, t)! + Offset(0, -hop);
            final robotH = 150 * k;
            return Stack(clipBehavior: Clip.none, children: [
              Positioned(left: ox, top: oy, width: _imgW * k, height: _imgH * k, child: Image.asset(jd('jd_map'), fit: BoxFit.fill)),
              // localised area signs over the painted ones
              _sign('jd_sign1', jdT(context, 'a0'), Offset(ox + 140 * k, oy + 82 * k), 255 * k, s),
              _sign('jd_sign2', jdT(context, 'a1'), Offset(ox + 440 * k, oy + 492 * k), 235 * k, s),
              _sign('jd_sign3', jdT(context, 'a2'), Offset(ox + 722 * k, oy + 112 * k), 230 * k, s),
              // decorations on the patched area
              Positioned(
                left: ox + 330 * k,
                top: oy + 680 * k,
                child: IgnorePointer(
                  child: Transform.rotate(
                    alignment: Alignment.topCenter,
                    angle: sin(_idle.value * 2 * pi) * 0.05,
                    child: Image.asset(jd('jd_lantern'), width: 70 * k),
                  ),
                ),
              ),
              for (var n = 1; n <= jdLevels.length; n++) _nodeW(n, pt(n), nodeW, s),
              // robot guide
              Positioned(
                left: rp.dx - nodeW * 0.95,
                top: rp.dy - robotH * 0.92,
                child: IgnorePointer(
                  child: Transform.translate(
                    offset: Offset(0, sin(_idle.value * 2 * pi * 2) * 2 * s),
                    child: Transform.flip(flipX: b.dx < a.dx, child: Image.asset(jd('jd_robot_wave'), height: robotH)),
                  ),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _sign(String a, String text, Offset c, double width, double s) => Positioned(
        left: c.dx - width / 2,
        top: c.dy - width * 0.27,
        width: width,
        child: IgnorePointer(
          child: AspectRatio(
            aspectRatio: 1 / 0.58,
            child: Stack(children: [
              Positioned.fill(child: Image.asset(jd(a), fit: BoxFit.fill)),
              Positioned(
                left: width * 0.16,
                right: width * 0.16,
                top: width * 0.1,
                height: width * 0.2,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(text, textAlign: TextAlign.center, maxLines: 2, style: jdText(22 * s, height: 1.05)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );

  Widget _nodeW(int n, Offset c, double size, double s) {
    final st = _stars[n - 1];
    final open = JdStore.unlocked(_stars, n);
    final sel = n == _sel;
    final sprite = !open ? 'jd_node_lock' : (sel ? 'jd_node_now' : (st == 3 ? 'jd_node_stars' : 'jd_node_open'));
    final shake = n == _shakeN ? sin(_shake.value * pi * 6) * 6 * (1 - _shake.value) : 0.0;
    final pulse = sel ? 1.06 + 0.05 * sin(_idle.value * 2 * pi * 3) : 1.0;
    final ratio = switch (sprite) { 'jd_node_now' => 0.645, 'jd_node_lock' => 0.6105, 'jd_node_stars' => 0.605, _ => 0.645 };
    // done levels do a little happy hop now and then
    final hop = (open && st > 0 && !sel) ? max(0.0, sin((_idle.value * 3 + n * 0.13) * 2 * pi)) * 3 * s : 0.0;
    final h = size * ratio;
    return Positioned(
      left: c.dx - size / 2 + shake,
      top: c.dy - h * 0.55 - hop,
      width: size,
      height: h,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _tapNode(n),
        child: Transform.scale(
          scale: pulse,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
            Positioned.fill(child: Image.asset(jd(sprite), fit: BoxFit.fill)),
            Positioned(
              top: h * (sprite == 'jd_node_lock' ? 0.0 : (sprite == 'jd_node_stars' ? 0.1 : 0.14)),
              child: Text('$n',
                  style: jdText(h * (sprite == 'jd_node_lock' ? 0.28 : 0.42),
                          color: sprite == 'jd_node_now' || sprite == 'jd_node_open' ? Colors.white : (open ? const Color(0xFF4A1D9E) : const Color(0xFF55555F)),
                          weight: FontWeight.w800)
                      .copyWith(shadows: sprite == 'jd_node_now' || sprite == 'jd_node_open' ? [Shadow(color: Colors.brown.withOpacity(0.5), offset: const Offset(0, 1.5))] : null)),
            ),
            if (!sel && st > 0 && st < 3)
              Positioned(
                bottom: -h * 0.12,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (var i = 0; i < 3; i++)
                    Icon(Icons.star_rounded, size: h * 0.3, color: i < st ? const Color(0xFFFFC21A) : Colors.white.withOpacity(0.8)),
                ]),
              ),
            if (sel && st > 0)
              Positioned(
                bottom: -h * 0.18,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (var i = 0; i < 3; i++)
                    Icon(Icons.star_rounded, size: h * 0.3, color: i < st ? const Color(0xFFFFC21A) : Colors.white.withOpacity(0.7)),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _card(double s, double width, JdLevel lvl) {
    final h = width * 0.5192;
    final known = JdStore.discoveredFrom(_stars).contains(lvl.plantId);
    return SizedBox(
      width: width,
      height: h + h * 0.08,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(left: 0, right: 0, top: 0, height: h, child: Image.asset(jd('jd_level_card'), fit: BoxFit.fill)),
        // picture in the light circle (covers the painted sprout)
        Positioned(
          left: width * 0.075,
          width: width * 0.3,
          top: h * 0.17,
          height: width * 0.3,
          child: ClipOval(
            child: DecoratedBox(
              decoration: const BoxDecoration(gradient: RadialGradient(colors: [Color(0xFFF4FFE6), Color(0xFFBDE89A)])),
              child: Padding(
                padding: EdgeInsets.all(width * 0.02),
                child: AnimatedBuilder(
                  animation: _idle,
                  builder: (_, c) => Transform.rotate(angle: sin(_idle.value * 2 * pi * 2) * 0.05, child: c),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: c),
                    child: known
                        ? JdPot(key: ValueKey(lvl.plantId), plant: lvl.plant, height: width * 0.26)
                        : Image.asset(jd('jd_seed_sprout'), key: ValueKey('s${lvl.n}'), fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: width * 0.44,
          right: width * 0.06,
          top: h * 0.13,
          height: h * 0.46,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: FittedBox(
              key: ValueKey(lvl.n),
              fit: BoxFit.scaleDown,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 2 * s),
                  decoration: BoxDecoration(color: jdOrange, borderRadius: BorderRadius.circular(12 * s)),
                  child: Text(jdT(context, 'level', {'n': lvl.n}), style: jdText(13 * s, color: Colors.white)),
                ),
                SizedBox(height: 3 * s),
                Text(lvl.title(context), style: jdText(19 * s, color: jdInk, height: 1.0)),
                Text(lvl.sub(context), style: jdText(10.5 * s, color: jdInkSoft, weight: FontWeight.w600, height: 1.2)),
              ]),
            ),
          ),
        ),
        // play button sitting on the cream pill of the card
        Positioned(
          left: width * 0.46,
          right: width * 0.04,
          top: h * 0.6,
          child: Center(child: jdPlay(jdT(context, 'play'), _play, width * 0.5, pulse: _idle)),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Dialog frame + "How to play"
// ═══════════════════════════════════════════════════════════════════════════

/// Cream panel with the wooden title plank.
class JdDialogFrame extends StatelessWidget {
  final String title;
  final Widget child;
  const JdDialogFrame({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => JdFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = jdScale(context);
    final w = min(MediaQuery.sizeOf(context).width - 28, 390.0);
    final pw = w * 0.84;
    final ph = pw * 0.366;
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: w,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
            Container(
              margin: EdgeInsets.only(top: ph * 0.55),
              padding: EdgeInsets.fromLTRB(w * 0.07, ph * 0.55, w * 0.07, w * 0.07),
              decoration: BoxDecoration(
                color: jdCream,
                borderRadius: BorderRadius.circular(28 * s),
                border: Border.all(color: const Color(0xFFB9783F), width: 5 * s),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFB8F27A).withOpacity(0.55), blurRadius: 24 * s, spreadRadius: 2 * s),
                  BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 14 * s, offset: Offset(0, 6 * s)),
                ],
              ),
              child: child,
            ),
            // leafy corners
            Positioned(left: -10 * s, bottom: -10 * s, child: JdFloat(amp: 0, tilt: 0.08, child: Image.asset(jd('jd_leaves'), width: 56 * s))),
            Positioned(
              right: -10 * s,
              bottom: -10 * s,
              child: Transform.flip(flipX: true, child: JdFloat(amp: 0, tilt: 0.08, phase: 0.5, child: Image.asset(jd('jd_leaves'), width: 56 * s))),
            ),
            // title plank
            SizedBox(
              width: pw,
              height: ph,
              child: Stack(children: [
                Positioned.fill(child: Image.asset(jd('jd_plank_title'), fit: BoxFit.fill)),
                Positioned(
                  left: pw * 0.14,
                  right: pw * 0.14,
                  top: ph * 0.18,
                  bottom: ph * 0.22,
                  child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(title, style: jdText(26 * s, color: jdInk, weight: FontWeight.w800)))),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

Widget jdNote(String text, double s) => Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 7 * s),
      decoration: BoxDecoration(color: const Color(0xFFE6DDFB), borderRadius: BorderRadius.circular(14 * s)),
      child: Text(text, textAlign: TextAlign.center, style: jdText(14.5 * s, color: jdInk, weight: FontWeight.w600)),
    );

Future<T?> jdDialog<T>(BuildContext context, Widget child, {bool dismissible = false}) => showGeneralDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: 'jd',
      barrierColor: const Color(0x8C1F4A1A),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => child,
      transitionBuilder: (_, a, __, c) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
    );

Future<void> showJdHelp(BuildContext context) => jdDialog(context, const _HelpDialog(), dismissible: true);

class _HelpDialog extends StatelessWidget {
  const _HelpDialog();
  @override
  Widget build(BuildContext context) => JdFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = jdScale(context);
    Widget step(int n) => Expanded(
          child: Column(children: [
            Stack(clipBehavior: Clip.none, alignment: Alignment.topLeft, children: [
              JdPopIn(
                delayMs: 120 * n,
                child: JdFloat(amp: 3 * s, phase: n * 0.3, child: SizedBox(height: 84 * s, child: Center(child: Image.asset(jd('jd_step$n'))))),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: CircleAvatar(radius: 13 * s, backgroundColor: jdOrange, child: Text('$n', style: jdText(15 * s, color: Colors.white, weight: FontWeight.w800))),
              ),
            ]),
            SizedBox(height: 4 * s),
            FittedBox(fit: BoxFit.scaleDown, child: Text(jdT(context, 'h$n'), style: jdText(14 * s))),
          ]),
        );
    return JdDialogFrame(
      title: jdT(context, 'how'),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [step(1), SizedBox(width: 6 * s), step(2), SizedBox(width: 6 * s), step(3)]),
        SizedBox(height: 10 * s),
        jdNote(jdT(context, 'helpNote'), s),
        SizedBox(height: 12 * s),
        JdFlatButton(label: jdT(context, 'go'), onTap: () => Navigator.pop(context), width: 220 * s),
      ]),
    );
  }
}
