import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

import 'bb_common.dart';
import 'bb_engine.dart';
import 'brain_builder_game.dart';

/// Brain Builder home: a floating-island map, 12 level stops per world.
class BrainBuilderMenu extends StatefulWidget {
  const BrainBuilderMenu({super.key});

  @override
  State<BrainBuilderMenu> createState() => _BrainBuilderMenuState();
}

class _BrainBuilderMenuState extends State<BrainBuilderMenu> with TickerProviderStateMixin {
  List<int> _stars = List.filled(bbLevelCount, 0);
  int _world = 0;
  bool _loaded = false;
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  /// Level stops along the path, in the 941 × 1672 map artwork.
  static const List<Offset> _nodes = [
    Offset(215, 1318), Offset(410, 1290), Offset(640, 1205), Offset(480, 1082),
    Offset(600, 992), Offset(738, 912), Offset(620, 790), Offset(598, 625),
    Offset(690, 518), Offset(500, 410), Offset(620, 342), Offset(828, 292),
  ];
  // Art-space band that must stay visible (all stops + their size).
  static const double _bandTop = 215, _bandBottom = 1380, _bandCx = 522;
  static const double _mapW = 941, _mapH = 1672;

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _load(jump: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final a in [BBAssets.mapBg, BBAssets.a('node_green'), BBAssets.a('node_purple'), BBAssets.a('node_grey'), BBAssets.a('robot_wave')]) {
      precacheImage(AssetImage(a), context);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  Future<void> _load({bool jump = false}) async {
    final s = await BBProgress.allStars();
    if (!mounted) return;
    setState(() {
      _stars = s;
      _loaded = true;
      if (jump) _world = bbWorldOf(_nextLevel);
    });
  }

  bool _unlocked(int n) => n == 1 || _stars[n - 2] > 0;
  bool _worldOpen(int w) => _unlocked(w * bbLevelsPerWorld + 1);

  int get _nextLevel {
    for (var n = 1; n <= bbLevelCount; n++) {
      if (_stars[n - 1] == 0) return n;
    }
    return bbLevelCount;
  }

  /// The level the "Play" card offers in the shown world.
  int get _focusLevel {
    final first = _world * bbLevelsPerWorld + 1;
    for (var n = first; n < first + bbLevelsPerWorld; n++) {
      if (_stars[n - 1] == 0) return _unlocked(n) ? n : first;
    }
    return first + bbLevelsPerWorld - 1;
  }

  Future<void> _open(int n) async {
    if (!_unlocked(n)) {
      _lockedTap('lockedMsg');
      return;
    }
    _audio.playEventSound('PopButton');
    int? next = n;
    while (next != null && mounted) {
      final level = next;
      final r = await Navigator.push<int>(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, __, ___) => BrainBuilderGame(level: level),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        ),
      );
      await _load();
      next = (r != null && r <= bbLevelCount) ? r : null;
      if (next != null && mounted) setState(() => _world = bbWorldOf(next!));
    }
  }

  void _lockedTap(String key) {
    _audio.playEventSound('invalid');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: KidColors.purpleDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(bbT(context, key), style: kidBodyStyle(15, color: Colors.white, weight: FontWeight.w600)),
      ));
  }

  void _switchWorld(int dir) {
    final w = _world + dir;
    if (w < 0 || w >= bbWorldCount) return;
    if (!_worldOpen(w)) {
      _lockedTap('worldLocked');
      return;
    }
    _audio.playEventSound('toggleButton');
    setState(() => _world = w);
  }

  Future<void> _toggleSound() async {
    final a = _audio;
    final mute = !(a.isBgMuted && a.isSfxMuted);
    if (a.isBgMuted != mute) await a.toggleBgMute();
    if (a.isSfxMuted != mute) await a.toggleSfxMute();
    if (mounted) setState(() {});
  }

  // ─── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8FD3FF),
      body: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final pad = MediaQuery.paddingOf(context);
        final s0 = (w / 400).clamp(0.8, 1.3).toDouble();
        final headerH = pad.top + 168 * s0, footerH = pad.bottom + 120 * s0;
        // Zoom so every stop fits between the header and the play card, but never
        // smaller than the screen width (no side gaps).
        final cover = max(w / _mapW, h / _mapH);
        final fit = (h - headerH - footerH) / (_bandBottom - _bandTop);
        final scale = max(min(cover, fit), w / _mapW);
        final ox = (w / 2 - _bandCx * scale).clamp(w - _mapW * scale, 0.0);
        // stops start right under the header; the map always reaches the bottom edge
        final oy = max(headerH - _bandTop * scale, h - _mapH * scale);
        Offset at(Offset p) => Offset(ox + p.dx * scale, oy + p.dy * scale);
        final s = s0;
        return Stack(children: [
          // sky behind the map in case it is shorter than the screen
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF5CC3FF), Color(0xFFBFE9FF)],
                ),
              ),
            ),
          ),
          Positioned(left: ox, top: oy, width: _mapW * scale, height: _mapH * scale, child: _mapImage()),
          if (_loaded) ..._mapLayer(at, scale, s),
          Positioned(left: 0, right: 0, top: pad.top + 4, child: _header(s)),
          Positioned(left: 12, right: 12, bottom: pad.bottom + 10, child: _playCard(s)),
        ]);
      }),
    );
  }

  Widget _mapImage() {
    final img = Image.asset(BBAssets.mapBg, fit: BoxFit.fill);
    // Each world tints the islands a little.
    final tint = const [null, Color(0x22FF8AD8), Color(0x3384D8FF), Color(0x26FFC23A), Color(0x8A1B1450), Color(0x1A7EE08A)][_world];
    if (tint == null) return img;
    return Stack(fit: StackFit.expand, children: [img, ColoredBox(color: tint)]);
  }

  List<Widget> _mapLayer(Offset Function(Offset) at, double scale, double s) {
    final first = _world * bbLevelsPerWorld + 1;
    final focus = _focusLevel;
    final ns = 132 * scale; // node width on screen
    final out = <Widget>[];
    // treasure chest beside stop 6
    final chest = at(const Offset(300, 1005));
    out.add(Positioned(
      left: chest.dx - 55 * scale,
      top: chest.dy - 50 * scale,
      child: AnimatedBuilder(
        animation: _idle,
        builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi) * 4 * scale), child: c),
        child: Image.asset(BBAssets.a('chest'), width: 110 * scale),
      ),
    ));
    for (var i = bbLevelsPerWorld - 1; i >= 0; i--) {
      final n = first + i;
      final p = at(_nodes[i]);
      out.add(Positioned(
        left: p.dx - ns / 2,
        top: p.dy - ns * 0.42,
        width: ns,
        height: ns * 1.05,
        child: _node(n, ns, n == focus),
      ));
    }
    // robot + "play next" bubble next to the focused stop
    final fi = focus - first;
    final fp = at(_nodes[fi]);
    final left = fp.dx < 470 * scale + (at(Offset.zero).dx);
    out.add(Positioned(
      left: left ? fp.dx + ns * 0.45 : fp.dx - ns * 0.45 - 105 * scale,
      top: fp.dy - 190 * scale,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _idle,
          builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi) * 5 * scale), child: c),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 5 * s),
              decoration: BoxDecoration(
                color: bbCream,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE9DFC9), width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3))],
              ),
              child: Text(bbT(context, 'playNext'), style: kidBodyStyle(14 * s, color: bbInk, weight: FontWeight.w700)),
            ),
            Transform.flip(
              flipX: !left,
              child: Image.asset(BBAssets.a('robot_wave'), height: 128 * scale),
            ),
          ]),
        ),
      ),
    ));
    return out;
  }

  Widget _node(int n, double size, bool focus) {
    final open = _unlocked(n);
    final st = _stars[n - 1];
    final done = st > 0;
    final sprite = done ? 'node_green' : (focus && open ? 'node_purple' : 'node_grey');
    Widget body = Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
      Image.asset(BBAssets.a(sprite), width: size, fit: BoxFit.contain),
      Positioned(
        top: size * (done ? 0.05 : 0.1),
        child: Text('$n'.padLeft(1),
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w700,
              fontSize: size * 0.3,
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.35), blurRadius: 3, offset: const Offset(0, 2)),
              ],
            )),
      ),
      if (done)
        Positioned(
          top: size * 0.42,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < 3; i++)
              Image.asset(BBAssets.a(i < st ? 'star_on' : 'star_off'), width: size * (i == 1 ? 0.27 : 0.24)),
          ]),
        )
      else if (!open)
        Positioned(
          top: size * 0.45,
          child: Container(
            padding: EdgeInsets.all(size * 0.03),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(size * 0.08)),
            child: Icon(Icons.lock_rounded, color: const Color(0xFF6A5ACD), size: size * 0.16),
          ),
        ),
    ]);
    if (focus && open) {
      body = AnimatedBuilder(
        animation: _idle,
        builder: (_, c) {
          final t = (sin(_idle.value * 2 * pi * 2) + 1) / 2;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFFFFE066).withOpacity(0.35 + 0.35 * t), blurRadius: 18 + 14 * t, spreadRadius: 2)],
            ),
            child: Transform.scale(scale: 1 + 0.05 * t, child: c),
          );
        },
        child: body,
      );
    }
    return KidPressable(onTap: () => _open(n), semanticLabel: bbT(context, 'levelN', {'n': n}), child: body);
  }

  Widget _header(double s) {
    final a = _audio;
    final muted = a.isBgMuted && a.isSfxMuted;
    final first = _world * bbLevelsPerWorld + 1;
    final done = [for (var n = first; n < first + bbLevelsPerWorld; n++) if (_stars[n - 1] > 0) n].length;
    Widget arrow(int dir) {
      final ok = _world + dir >= 0 && _world + dir < bbWorldCount;
      return Opacity(
        opacity: ok ? 1 : 0.3,
        child: KidPressable(
          onTap: ok ? () => _switchWorld(dir) : null,
          child: Container(
            width: 30 * s,
            height: 30 * s,
            decoration: BoxDecoration(color: KidColors.purple, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
            child: Icon(dir < 0 ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: Colors.white, size: 22 * s),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12 * s),
          child: Row(children: [
            BBSpriteButton(
              asset: BBAssets.a('m_back'),
              size: 52 * s,
              label: MaterialLocalizations.of(context).backButtonTooltip,
              onTap: () {
                _audio.playEventSound('cancelButton');
                Navigator.maybePop(context);
              },
            ),
            Expanded(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: BBTitle(bbT(context, 'title'), size: 36 * s)))),
            BBSpriteButton(
              asset: BBAssets.a('m_sound'),
              size: 52 * s,
              onTap: _toggleSound,
              overlay: muted ? Icon(Icons.close_rounded, color: const Color(0xFFFF4D6D), size: 40 * s) : null,
            ),
          ]),
        ),
        SizedBox(height: 4 * s),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          arrow(-1),
          SizedBox(width: 8 * s),
          BBPill(
            height: 40 * s,
            padding: EdgeInsets.symmetric(horizontal: 16 * s),
            child: Directionality(
              textDirection: Directionality.of(context),
              child: Text('${bbT(context, 'worldN', {'n': _world + 1})}  •  ${bbT(context, 'w$_world')}',
                  style: kidBodyStyle(16 * s, color: bbInk, weight: FontWeight.w700)),
            ),
          ),
          SizedBox(width: 8 * s),
          arrow(1),
        ]),
        SizedBox(height: 4 * s),
        BBPill(
          height: 28 * s,
          padding: EdgeInsets.symmetric(horizontal: 14 * s),
          child: Text(bbT(context, 'completedN', {'n': done, 't': bbLevelsPerWorld}),
              style: kidBodyStyle(13 * s, color: bbInk, weight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _playCard(double s) {
    final n = _focusLevel;
    return Container(
      padding: EdgeInsets.all(8 * s),
      decoration: BoxDecoration(
        color: bbCream,
        borderRadius: BorderRadius.circular(24 * s),
        border: Border.all(color: const Color(0xFFCDB8FF), width: 3),
        boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14 * s),
          child: Image.asset(BBAssets.worldThumb(_world), width: 96 * s, height: 72 * s, fit: BoxFit.cover),
        ),
        SizedBox(width: 10 * s),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(bbT(context, 'levelN', {'n': bbIndexInWorld(n) + 1}), style: kidBodyStyle(24 * s, color: bbInk, weight: FontWeight.w700)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(bbT(context, 'w$_world'), style: kidBodyStyle(15 * s, color: KidColors.inkSoft, weight: FontWeight.w600)),
            ),
          ]),
        ),
        KidPressable(
          onTap: () => _open(n),
          child: AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.scale(scale: 1 + 0.03 * sin(_idle.value * 2 * pi), child: c),
            child: SizedBox(
              width: 140 * s,
              height: 58 * s,
              child: Stack(alignment: Alignment.center, children: [
                Positioned.fill(child: Image.asset(BBAssets.a('play_btn'), fit: BoxFit.fill)),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30 * s,
                      shadows: const [Shadow(color: Color(0xFFB86A00), blurRadius: 4)]),
                  SizedBox(width: 2 * s),
                  Text(bbT(context, 'play'), style: kidBodyStyle(24 * s, color: bbInk, weight: FontWeight.w700)),
                ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
