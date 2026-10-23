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
                    child: Transform.translate(offset: Offset(0, -18 * s), child: _title(s, w)),
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
    final big = min(w * 0.15, 58 * s);
    final words = [jdT(context, 't1'), jdT(context, 't2'), jdT(context, 't3')].where((e) => e.isNotEmpty).toList();
    const colors = [Color(0xFF7A2BE0), Color(0xFF13A6A0), Color(0xFFFF8A1F)];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < words.length; i++)
        Transform.translate(
          offset: Offset(0, -i * big * 0.18),
          child: FittedBox(fit: BoxFit.scaleDown, child: jdOutlined(words[i], colors[i % 3], big * (i == 0 ? 0.85 : 1), stroke: 0.2)),
        ),
      Transform.translate(
        offset: Offset(0, -big * 0.3),
        child: jdOnSprite(
          'jd_plank_curve',
          min(w * 0.66, 260 * s),
          0.32,
          Text(jdT(context, 'tag'), textAlign: TextAlign.center, style: jdText(15 * s, color: jdInk, height: 1.1)),
          area: const EdgeInsets.fromLTRB(0.14, 0.14, 0.14, 0.14),
        ),
      ),
    ]);
  }

  Widget _scene(double s, double w) => LayoutBuilder(builder: (_, c) {
        final h = c.maxHeight;
        final t = _idle;
        return Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
          // hero: robot watering + kid planting
          Positioned(
            left: 0,
            right: 0,
            bottom: -4 * s,
            child: Center(child: Image.asset(jd('jd_hero'), height: min(h * 0.92, w * 0.6))),
          ),
          // signpost with the garden words
          PositionedDirectional(
            start: 2 * s,
            top: h * 0.02,
            child: SizedBox(
              width: min(w * 0.27, 105 * s),
              child: AspectRatio(
                aspectRatio: 1 / 0.8591,
                child: LayoutBuilder(builder: (_, b) {
                  final bw = b.maxWidth, bh = b.maxHeight;
                  return Stack(children: [
                    Positioned.fill(child: Image.asset(jd('jd_signpost'), fit: BoxFit.fill)),
                    for (var i = 0; i < 3; i++)
                      Positioned(
                        left: bw * 0.18,
                        right: bw * 0.14,
                        top: bh * (0.08 + i * 0.205),
                        height: bh * 0.18,
                        child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(jdT(context, 'sign$i'), style: jdText(13 * s)))),
                      ),
                  ]);
                }),
              ),
            ),
          ),
          // sunflower with the bird
          PositionedDirectional(
            end: 0,
            top: h * 0.0,
            child: AnimatedBuilder(
              animation: t,
              builder: (_, c) => Transform.rotate(alignment: Alignment.bottomCenter, angle: sin(t.value * 2 * pi * 2) * 0.04, child: c),
              child: Image.asset(jd('jd_sunflower'), width: min(w * 0.2, 80 * s)),
            ),
          ),
          PositionedDirectional(
            end: w * 0.13,
            top: h * 0.02,
            child: AnimatedBuilder(
              animation: t,
              builder: (_, c) => Transform.translate(offset: Offset(0, -sin(t.value * 2 * pi * 6).abs() * 3 * s), child: c),
              child: Transform.flip(flipX: !jdRtl(context), child: Image.asset(jd('jd_bird'), width: min(w * 0.15, 58 * s))),
            ),
          ),
          // butterfly
          AnimatedBuilder(
            animation: t,
            builder: (_, c) {
              final a = t.value * 2 * pi;
              return Positioned(
                left: w * 0.5 + cos(a) * w * 0.3 - 20 * s,
                top: h * 0.25 + sin(a * 2) * h * 0.14,
                child: Transform.scale(scaleX: 0.75 + 0.25 * sin(a * 18).abs(), child: c),
              );
            },
            child: Image.asset(jd('jd_butterfly'), width: 38 * s),
          ),
        ]);
      });

  Widget _panel(double s, double w, int found) {
    final pw = w - 24 * s;
    final ph = pw * 0.3359;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12 * s),
      padding: EdgeInsets.fromLTRB(6 * s, 6 * s, 6 * s, 10 * s),
      decoration: BoxDecoration(
        color: jdCream.withOpacity(0.96),
        borderRadius: BorderRadius.circular(30 * s),
        border: Border.all(color: Colors.white, width: 3 * s),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 18 * s, offset: Offset(0, 6 * s))],
      ),
      child: Column(children: [
        // three world cards
        SizedBox(
          width: pw,
          height: ph,
          child: Stack(children: [
            Positioned.fill(child: Image.asset(jd('jd_panel3'), fit: BoxFit.fill)),
            for (var i = 0; i < 3; i++)
              Positioned(
                left: pw * [0.09, 0.37, 0.65][i],
                width: pw * 0.26,
                top: ph * 0.1,
                bottom: ph * 0.12,
                child: JdPress(
                  onTap: () => _openMap(i),
                  label: jdT(context, 'w$i'),
                  child: Column(children: [
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _idle,
                        builder: (_, c) => Transform.translate(offset: Offset(0, sin((_idle.value * 3 + i * 0.3) * 2 * pi) * 2.5 * s), child: c),
                        child: Image.asset(jd(['jd_seed_sprout', 'jd_can_teal', 'jd_sunflower'][i]), fit: BoxFit.contain),
                      ),
                    ),
                    FittedBox(fit: BoxFit.scaleDown, child: Text(jdT(context, 'w$i'), style: jdText(15 * s, color: jdInk))),
                  ]),
                ),
              ),
          ]),
        ),
        SizedBox(height: 4 * s),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(children: [
              jdPlay(jdT(context, 'play'), _playNext, min(pw * 0.7, 270 * s), pulse: _idle),
              SizedBox(height: 6 * s),
              JdSpriteButton(
                sprite: 'jd_pill_level',
                ratio: 0.3077,
                start: 0.26,
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
                    Image.asset(jd('jd_help'), width: 26 * s),
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
            child: SizedBox(
              width: min(pw * 0.3, 118 * s),
              child: AspectRatio(
                aspectRatio: 1 / 0.6988,
                child: LayoutBuilder(builder: (_, b) {
                  final bw = b.maxWidth, bh = b.maxHeight;
                  return Stack(children: [
                    Positioned.fill(child: Image.asset(jd('jd_garden_card'), fit: BoxFit.fill)),
                    Positioned(
                      left: bw * 0.42,
                      right: bw * 0.06,
                      top: bh * 0.2,
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
        ]),
      ]),
    );
  }
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
    final cardH = cardW * 0.4446;

    return Scaffold(
      backgroundColor: const Color(0xFF9CCB6A),
      body: Stack(children: [
        const Positioned.fill(child: JdBg(asset: 'jd_bg_map')),
        // the painted garden
        Positioned(
          left: 0,
          right: 0,
          top: pad.top + headerH * 0.75,
          bottom: pad.bottom + cardH * 0.82,
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
            aspectRatio: 1 / 0.53,
            child: Stack(children: [
              Positioned.fill(child: Image.asset(jd(a), fit: BoxFit.fill)),
              Positioned(
                left: width * 0.14,
                right: width * 0.14,
                top: width * 0.08,
                height: width * 0.25,
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
    final sprite = !open ? 'jd_node_lock' : (sel ? 'jd_node_now' : (st == 3 ? 'jd_node_stars' : 'jd_node'));
    final shake = n == _shakeN ? sin(_shake.value * pi * 6) * 6 * (1 - _shake.value) : 0.0;
    final pulse = sel ? 1.06 + 0.05 * sin(_idle.value * 2 * pi * 3) : 1.0;
    final ratio = switch (sprite) { 'jd_node_now' => 0.6864, 'jd_node_lock' => 0.745, 'jd_node_stars' => 0.695, _ => 0.715 };
    final h = size * ratio;
    return Positioned(
      left: c.dx - size / 2 + shake,
      top: c.dy - h * 0.55,
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
              top: h * (sprite == 'jd_node_lock' ? 0.04 : (sprite == 'jd_node_stars' ? 0.06 : 0.16)),
              child: Text('$n',
                  style: jdText(h * (sprite == 'jd_node_lock' ? 0.3 : 0.42),
                          color: sprite == 'jd_node_now' ? Colors.white : (open ? const Color(0xFF4A1D9E) : const Color(0xFF55555F)),
                          weight: FontWeight.w800)
                      .copyWith(shadows: sprite == 'jd_node_now' ? [Shadow(color: Colors.brown.withOpacity(0.5), offset: const Offset(0, 1.5))] : null)),
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
    final h = width * 0.4446;
    final known = JdStore.discoveredFrom(_stars).contains(lvl.plantId);
    return SizedBox(
      width: width,
      height: h,
      child: Stack(children: [
        Positioned.fill(child: Image.asset(jd('jd_level_card'), fit: BoxFit.fill)),
        // picture in the light circle
        Positioned(
          left: width * 0.09,
          width: width * 0.28,
          top: h * 0.16,
          height: h * 0.66,
          child: AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi * 2) * 2.5 * s), child: c),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: known
                  ? JdPot(key: ValueKey(lvl.plantId), plant: lvl.plant, height: h * 0.66)
                  : Image.asset(jd('jd_sprout_bean'), key: const ValueKey('sprout'), fit: BoxFit.contain),
            ),
          ),
        ),
        Positioned(
          left: width * 0.38,
          right: width * 0.28,
          top: h * 0.12,
          height: h * 0.21,
          child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(jdT(context, 'level', {'n': lvl.n}), style: jdText(17 * s, color: Colors.white)))),
        ),
        Positioned(
          left: width * 0.38,
          right: width * 0.08,
          top: h * 0.33,
          height: h * 0.17,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(lvl.title(context), style: jdText(17 * s, color: jdInk, height: 1.0)),
              Text(lvl.sub(context), style: jdText(10.5 * s, color: jdInkSoft, weight: FontWeight.w600, height: 1.1)),
            ]),
          ),
        ),
        // the orange pill of the sprite is the play button
        Positioned(
          left: width * 0.36,
          right: width * 0.1,
          top: h * 0.5,
          bottom: h * 0.12,
          child: JdPress(
            onTap: _play,
            label: jdT(context, 'play'),
            child: Row(children: [
              SizedBox(width: width * 0.25),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(jdT(context, 'play'),
                      style: jdText(24 * s, color: Colors.white, weight: FontWeight.w800)
                          .copyWith(shadows: const [Shadow(color: Color(0xFFB4410A), offset: Offset(0, 2))])),
                ),
              ),
            ]),
          ),
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
    final w = min(MediaQuery.sizeOf(context).width - 28, 400.0);
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: w,
          child: Stack(children: [
            Positioned.fill(child: Image.asset(jd('jd_dialog'), fit: BoxFit.fill, centerSlice: null)),
            Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                height: w * 0.17,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(w * 0.22, w * 0.035, w * 0.22, w * 0.025),
                  child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(title, style: jdText(26 * s, color: jdInk, weight: FontWeight.w800)))),
                ),
              ),
              Padding(padding: EdgeInsets.fromLTRB(w * 0.07, 4 * s, w * 0.07, w * 0.07), child: child),
            ]),
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
            Stack(alignment: Alignment.topLeft, children: [
              Image.asset(jd('jd_step$n')),
              Positioned(
                left: 0,
                top: 0,
                width: 30 * s,
                height: 30 * s,
                child: Center(child: Text('$n', style: jdText(17 * s, color: Colors.white, weight: FontWeight.w800))),
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
