import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';

import 'mq_data.dart';
import 'mq_game.dart';

/// Mystery Quest home: pick a place, pick a room, then fly into it.
class MysteryQuestMenu extends StatefulWidget {
  const MysteryQuestMenu({super.key});
  @override
  State<MysteryQuestMenu> createState() => _MysteryQuestMenuState();
}

class _MysteryQuestMenuState extends State<MysteryQuestMenu> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  late final AnimationController _zoom = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final AnimationController _peek = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  int _place = 0;
  int _room = 0;
  int _level = 0;
  bool _timer = false;
  bool _busy = false;
  String _say = '';
  Map<String, List<int>> _stars = {};

  MqPlace get _p => mqPlaces[_place];
  MqRoom get _r => _p.rooms[_room];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lvl = await MqStore.level();
    final t = await MqStore.timer();
    final st = <String, List<int>>{};
    for (final r in _p.rooms) {
      st[r.id] = await MqStore.roomStars(_p.id, r.id);
    }
    if (!mounted) return;
    setState(() {
      _level = lvl.clamp(0, mqLevels.length - 1);
      _timer = t;
      _stars = st;
    });
  }

  @override
  void dispose() {
    _idle.dispose();
    _intro.dispose();
    _zoom.dispose();
    _peek.dispose();
    super.dispose();
  }

  void _pickRoom(int i) {
    final r = _p.rooms[i];
    if (!r.open) {
      mqSound(context, 'clickButton2');
      setState(() => _say = mqT(context, 'locked'));
      return;
    }
    mqSound(context, 'PopButton');
    setState(() {
      _room = i;
      _say = mqPick(context, r.name);
    });
    _peek.forward(from: 0);
  }

  Future<void> _enter() async {
    if (_busy || !_r.open) return;
    setState(() => _busy = true);
    int? next;
    try {
      mqSfx(context, 'CinematicStart_SFX.mp3');
      await _zoom.forward(from: 0);
      if (!mounted) return;
      next = await Navigator.of(context).push<int>(PageRouteBuilder<int>(
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => MqGamePage(place: _p, room: _r, level: _level, timer: _timer),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ));
      if (!mounted) return;
      _zoom.reverse(); // zoom back out of the room
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    // "Next room" asked from the end screen
    if (next != null && mounted) {
      _pickRoom(next);
      await Future.delayed(const Duration(milliseconds: 450));
      if (mounted) _enter();
    }
  }

  @override
  Widget build(BuildContext context) => MqFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 520.0);
    final s = (w / 390).clamp(0.78, 1.3).toDouble();

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF8FD3FF),
        body: Stack(children: [
          const Positioned.fill(child: _Sky()),
          Positioned.fill(child: AnimatedBuilder(animation: _idle, builder: (_, __) => CustomPaint(painter: _CloudPainter(_idle.value)))),
          SafeArea(
            child: Center(
              child: SizedBox(
                width: w,
                child: Column(children: [
                  _fade(0, _header(s)),
                  SizedBox(height: 6 * s),
                  _fade(1, _places(s)),
                  Expanded(child: _house(s)),
                  _fade(3, _rooms(s)),
                  SizedBox(height: 8 * s),
                  _fade(4, _options(s)),
                  SizedBox(height: 8 * s),
                  _fade(
                    5,
                    MqBigButton(
                      label: mqT(context, 'play'),
                      onTap: _r.open ? _enter : null,
                      width: min(w * 0.8, 320 * s),
                      s: s,
                      pulse: _idle,
                      leading: Transform.flip(flipX: mqRtl(context), child: Image.asset(mq('mq_play'), height: 30 * s)),
                    ),
                  ),
                  SizedBox(height: 8 * s + (pad.bottom > 0 ? 0 : 4)),
                ]),
              ),
            ),
          ),
          // the room picture fades in at the end of the zoom
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _zoom,
              builder: (_, __) {
                final z = _zoom.value;
                final o = Curves.easeInOut.transform(((z - 0.55) / 0.4).clamp(0.0, 1.0));
                final flash = z < 0.5 ? 0.0 : sin(((z - 0.5) / 0.5).clamp(0.0, 1.0) * pi) * 0.55;
                if (z <= 0.3) return const SizedBox.shrink();
                return Stack(fit: StackFit.expand, children: [
                  // darken the edges while we fly in
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 1.1,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.45 * ((z - 0.3) / 0.7).clamp(0.0, 1.0))],
                      ),
                    ),
                  ),
                  // the real room appears (same zoom the game starts with)
                  Opacity(
                    opacity: o,
                    child: Transform.scale(scale: 1.32 - 0.14 * o, child: Image.asset(_r.bg, fit: BoxFit.cover)),
                  ),
                  // soft magic flash
                  if (flash > 0)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(colors: [Colors.white.withOpacity(flash), Colors.white.withOpacity(0)]),
                      ),
                    ),
                ]);
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _fade(int i, Widget c) {
    final a = CurvedAnimation(parent: _intro, curve: Interval(min(0.08 * i, 0.6), min(0.45 + 0.08 * i, 1.0), curve: Curves.easeOutBack));
    return AnimatedBuilder(
      animation: Listenable.merge([a, _zoom]),
      builder: (_, child) {
        final out = 1 - Curves.easeIn.transform((_zoom.value / 0.5).clamp(0.0, 1.0));
        return Opacity(
          opacity: (a.value.clamp(0.0, 1.0) * out).toDouble(),
          child: Transform.translate(offset: Offset(0, (1 - a.value) * 24), child: child),
        );
      },
      child: c,
    );
  }

  // ── header ─────────────────────────────────────────────────────────────────

  Widget _header(double s) => Padding(
        padding: EdgeInsets.fromLTRB(10 * s, 4 * s, 10 * s, 0),
        child: Row(children: [
          mqRound(context, 'mq_back2', 48 * s, () {
            mqSound(context, 'cancelButton');
            Navigator.of(context).pop();
          }, flipRtl: true),
          Expanded(
            child: SizedBox(
              height: 78 * s,
              child: Stack(alignment: Alignment.center, children: [
                Positioned.fill(child: Image.asset(mq('mq_cloud'), fit: BoxFit.fill)),
                Positioned(
                  top: 18 * s,
                  left: 30 * s,
                  right: 30 * s,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(mqT(context, 'title'), style: mqText(24 * s)),
                      SizedBox(width: 6 * s),
                      Image.asset(mq('mq_mag'), height: 26 * s),
                    ]),
                  ),
                ),
                Positioned(
                  bottom: 10 * s,
                  left: 50 * s,
                  right: 50 * s,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(mqT(context, 'sub'), style: mqText(13 * s, color: mqInkSoft, weight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
          ),
          Consumer<AudioManager>(
            builder: (_, a, __) => Opacity(
              opacity: a.isBgMuted ? 0.5 : 1,
              child: mqRound(context, 'mq_sound', 48 * s, () {
                a.playEventSound('toggleButton');
                a.toggleBgMute();
              }),
            ),
          ),
        ]),
      );

  // ── places (house now, more later) ──────────────────────────────────────

  Widget _places(double s) => SizedBox(
        height: 40 * s,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 12 * s),
          itemCount: mqPlaces.length,
          separatorBuilder: (_, __) => SizedBox(width: 8 * s),
          itemBuilder: (_, i) {
            final p = mqPlaces[i];
            final sel = i == _place;
            return MqPress(
              onTap: () {
                if (!p.open) {
                  mqSound(context, 'clickButton2');
                  setState(() => _say = '${mqPick(context, p.name)} · ${mqT(context, 'soon')} ✨');
                  return;
                }
                setState(() => _place = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: EdgeInsets.symmetric(horizontal: 14 * s),
                decoration: BoxDecoration(
                  color: sel ? mqBlue : mqCream.withOpacity(p.open ? 1 : 0.75),
                  borderRadius: BorderRadius.circular(30 * s),
                  border: Border.all(color: Colors.white, width: 2 * s),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6 * s, offset: Offset(0, 2 * s))],
                ),
                child: Row(children: [
                  Icon(p.open ? p.icon : Icons.lock_rounded, size: 18 * s, color: sel ? Colors.white : mqInkSoft),
                  SizedBox(width: 6 * s),
                  Text(mqPick(context, p.name), style: mqText(14.5 * s, color: sel ? Colors.white : mqInk, weight: FontWeight.w600)),
                  if (!p.open) ...[
                    SizedBox(width: 6 * s),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 1 * s),
                      decoration: BoxDecoration(color: const Color(0xFFFFC21A), borderRadius: BorderRadius.circular(10 * s)),
                      child: Text(mqT(context, 'soon'), style: mqText(10.5 * s, color: mqInk)),
                    ),
                  ],
                ]),
              ),
            );
          },
        ),
      );

  // ── the house with its rooms (zooms into the chosen room) ────────────────

  Widget _house(double s) => LayoutBuilder(builder: (_, c) {
        final areaW = c.maxWidth, areaH = c.maxHeight;
        // fit the place picture in the area
        var hw = areaW * 0.86;
        var hh = hw * _p.aspect;
        if (hh > areaH * 0.98) {
          hh = areaH * 0.98;
          hw = hh / _p.aspect;
        }
        final house = Rect.fromLTWH((areaW - hw) / 2, (areaH - hh) / 2, hw, hh);
        Rect roomRect(MqRoom r) =>
            Rect.fromLTRB(house.left + r.rect.left * hw, house.top + r.rect.top * hh, house.left + r.rect.right * hw, house.top + r.rect.bottom * hh);

        return AnimatedBuilder(
          animation: Listenable.merge([_zoom, _idle, _peek]),
          builder: (_, __) {
            // zoom: scale so the chosen room fills the screen, centred
            final z = Curves.easeInOutCubic.transform(_zoom.value);
            final target = roomRect(_r);
            final scaleTo = max(areaW / target.width, areaH / target.height) * 1.05;
            final scale = 1 + (scaleTo - 1) * z;
            final focus = target.center;
            final centre = Offset(areaW / 2, areaH / 2);
            final dx = (centre.dx - focus.dx) * z;
            final dy = (centre.dy - focus.dy) * z;
            final bob = sin(_idle.value * 2 * pi) * 5 * s * (1 - z);

            return ClipRect(
              clipBehavior: _zoom.value > 0 ? Clip.none : Clip.hardEdge,
              child: Stack(clipBehavior: Clip.none, children: [
                Transform(
                  transform: Matrix4.identity()
                    ..translate(focus.dx + dx, focus.dy + dy + bob)
                    ..scale(scale)
                    ..translate(-focus.dx, -focus.dy),
                  child: SizedBox(
                    width: areaW,
                    height: areaH,
                    child: Stack(clipBehavior: Clip.none, children: [
                      Positioned.fromRect(rect: house, child: Image.asset(_p.picture, fit: BoxFit.fill)),
                      for (var i = 0; i < _p.rooms.length; i++) _hotspot(s, i, roomRect(_p.rooms[i])),
                    ]),
                  ),
                ),
                // detective robot + kid
                if (z < 0.4) ...[
                  PositionedDirectional(
                    start: -6 * s,
                    bottom: 0,
                    child: Opacity(
                      opacity: 1 - z * 2.5,
                      child: Transform.translate(
                        offset: Offset(0, sin(_idle.value * 2 * pi * 2) * 4 * s),
                        child: Transform.flip(flipX: mqRtl(context), child: Image.asset(mq('mq_robot_mag'), height: min(areaH * 0.32, 130 * s))),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    end: -4 * s,
                    bottom: 0,
                    child: Opacity(
                      opacity: 1 - z * 2.5,
                      child: Transform.translate(
                        offset: Offset(0, -sin(_idle.value * 2 * pi * 2).abs() * 5 * s),
                        child: Transform.flip(flipX: mqRtl(context), child: Image.asset(mq('mq_kid'), height: min(areaH * 0.42, 170 * s))),
                      ),
                    ),
                  ),
                  if (_say.isNotEmpty)
                    PositionedDirectional(
                      start: 4 * s,
                      top: 0,
                      child: Opacity(opacity: 1 - z * 2.5, child: MqBubble(text: _say, width: min(areaW * 0.5, 200 * s))),
                    ),
                ],
              ]),
            );
          },
        );
      });

  Widget _hotspot(double s, int i, Rect r) {
    final room = _p.rooms[i];
    final sel = i == _room && room.open;
    final glow = 0.5 + 0.5 * sin(_idle.value * 2 * pi * 3);
    final pop = sel ? sin(_peek.value * pi) : 0.0;
    final fade = 1 - _zoom.value.clamp(0.0, 1.0); // hide the frame while flying in
    return Positioned.fromRect(
      rect: r,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _pickRoom(i),
        onDoubleTap: () {
          _pickRoom(i);
          _enter();
        },
        child: Stack(clipBehavior: Clip.none, children: [
          if (sel)
            Positioned.fill(
              child: Opacity(
                opacity: fade,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF7FE3FF).withOpacity(0.10 + 0.10 * glow + 0.15 * pop),
                    borderRadius: BorderRadius.circular(5 * s),
                    border: Border.all(color: Colors.white.withOpacity(0.85 + 0.15 * glow), width: 2.2 * s),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF39C6FF).withOpacity(0.55 + 0.35 * glow), blurRadius: 10 * s + 8 * s * pop, spreadRadius: 1.5 * s),
                    ],
                  ),
                ),
              ),
            ),
          if (sel)
            Positioned(
              left: 0,
              right: 0,
              top: -26 * s - 4 * s * glow,
              child: Opacity(
                opacity: fade,
                child: Center(
                  child: Transform.rotate(
                    angle: pi,
                    child: Icon(Icons.navigation_rounded, color: const Color(0xFFFFC21A), size: 24 * s,
                        shadows: const [Shadow(color: Colors.black38, blurRadius: 4)]),
                  ),
                ),
              ),
            ),
          if (!room.open) Center(child: Image.asset(mq('mq_lock'), height: r.height * 0.4)),
        ]),
      ),
    );
  }

  // ── room cards ────────────────────────────────────────────────────────────

  Widget _rooms(double s) => SizedBox(
        height: 104 * s,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 4 * s),
          itemCount: _p.rooms.length,
          separatorBuilder: (_, __) => SizedBox(width: 8 * s),
          itemBuilder: (_, i) {
            final r = _p.rooms[i];
            final sel = i == _room;
            final best = (_stars[r.id] ?? const [0, 0, 0]);
            final st = best.isEmpty ? 0 : best[_level.clamp(0, best.length - 1)];
            return MqPress(
              onTap: () => _pickRoom(i),
              label: mqPick(context, r.name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 124 * s,
                padding: EdgeInsets.all(4 * s),
                decoration: BoxDecoration(
                  color: mqCream,
                  borderRadius: BorderRadius.circular(16 * s),
                  border: Border.all(color: sel ? const Color(0xFF3FB6FF) : Colors.white, width: sel ? 3 * s : 2 * s),
                  boxShadow: [
                    if (sel) BoxShadow(color: const Color(0xFF3FB6FF).withOpacity(0.55), blurRadius: 12 * s),
                    BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6 * s, offset: Offset(0, 3 * s)),
                  ],
                ),
                child: Column(children: [
                  Expanded(
                    child: Stack(fit: StackFit.expand, children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12 * s),
                        child: r.open
                            ? Image.asset(r.card, fit: BoxFit.cover)
                            : ColorFiltered(
                                colorFilter: const ColorFilter.matrix([
                                  0.4, 0.4, 0.2, 0, 0, 0.4, 0.4, 0.2, 0, 0, 0.4, 0.4, 0.2, 0, 0, 0, 0, 0, 1, 0, //
                                ]),
                                child: Image.asset(r.card, fit: BoxFit.cover)),
                      ),
                      if (!r.open) Center(child: Image.asset(mq('mq_lock'), height: 34 * s)),
                      if (sel && r.open) PositionedDirectional(top: 2 * s, end: 2 * s, child: Image.asset(mq('mq_check_blue'), width: 22 * s)),
                    ]),
                  ),
                  SizedBox(height: 3 * s),
                  Row(children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(mqPick(context, r.name), style: mqText(12.5 * s)),
                      ),
                    ),
                    for (var k = 0; k < 3; k++) Image.asset(mq(k < st ? 'mq_star_w' : 'mq_star_g'), width: 13 * s, color: k < st ? const Color(0xFFFFC21A) : null, colorBlendMode: BlendMode.modulate),
                  ]),
                ]),
              ),
            );
          },
        ),
      );

  // ── difficulty + timer ────────────────────────────────────────────────────

  Widget _options(double s) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 14 * s),
        child: Column(children: [
          // difficulty
          Container(
            height: 42 * s,
            padding: EdgeInsets.all(3 * s),
            decoration: BoxDecoration(
              color: mqCream,
              borderRadius: BorderRadius.circular(30 * s),
              border: Border.all(color: Colors.white, width: 2 * s),
            ),
            child: Row(children: [
              for (var i = 0; i < mqLevels.length; i++)
                Expanded(
                  child: MqPress(
                    onTap: () {
                      mqSound(context, 'toggleButton');
                      setState(() => _level = i);
                      MqStore.setLevel(i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: BoxDecoration(
                        color: i == _level ? mqBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(26 * s),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        for (var k = 0; k <= i; k++)
                          Icon(Icons.star_rounded, size: 15 * s, color: i == _level ? Colors.white : const Color(0xFF8D88A6)),
                        SizedBox(width: 4 * s),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(mqT(context, ['easy', 'medium', 'hard'][i]),
                                style: mqText(13.5 * s, color: i == _level ? Colors.white : mqInk, weight: FontWeight.w600)),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
            ]),
          ),
          SizedBox(height: 6 * s),
          // timer toggle
          MqPress(
            scale: 0.97,
            onTap: () {
              mqSound(context, 'toggleButton');
              setState(() => _timer = !_timer);
              MqStore.setTimer(_timer);
            },
            child: Container(
              height: 40 * s,
              padding: EdgeInsets.symmetric(horizontal: 10 * s),
              decoration: BoxDecoration(
                color: mqCream,
                borderRadius: BorderRadius.circular(30 * s),
                border: Border.all(color: Colors.white, width: 2 * s),
              ),
              child: Row(children: [
                Icon(_timer ? Icons.timer_rounded : Icons.timer_off_rounded, color: mqBlue, size: 22 * s),
                SizedBox(width: 8 * s),
                Expanded(child: Text(mqT(context, 'timer'), style: mqText(14 * s, weight: FontWeight.w600))),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48 * s,
                  height: 26 * s,
                  padding: EdgeInsets.all(3 * s),
                  alignment: _timer ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                  decoration: BoxDecoration(
                    color: _timer ? mqBlue : const Color(0xFFC9C6D6),
                    borderRadius: BorderRadius.circular(20 * s),
                  ),
                  child: Container(
                    width: 20 * s,
                    height: 20 * s,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      );
}

class _Sky extends StatelessWidget {
  const _Sky();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6EC3FF), Color(0xFFB9E4FF), Color(0xFFFFF1D6)],
          ),
        ),
      );
}

class _CloudPainter extends CustomPainter {
  final double t;
  _CloudPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.8);
    const clouds = [
      [0.05, 0.12, 1.0, 1.0],
      [0.6, 0.06, 0.8, 1.5],
      [0.3, 0.3, 0.6, 0.7],
      [0.85, 0.42, 0.9, 1.1],
    ];
    for (final c in clouds) {
      final k = size.width / 400 * c[2];
      final x = ((c[0] + t * 0.1 * c[3]) % 1.3 - 0.15) * size.width;
      final y = c[1] * size.height;
      for (final b in const [
        [0.0, 0.0, 20.0],
        [22.0, -9.0, 26.0],
        [48.0, 0.0, 20.0],
        [24.0, 7.0, 22.0],
      ]) {
        canvas.drawCircle(Offset(x + b[0] * k, y + b[1] * k), b[2] * k, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CloudPainter o) => o.t != t;
}
