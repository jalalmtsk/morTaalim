import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'art_kit.dart';
import 'm1_kit.dart';
import 'm1_shell.dart';
import 'm1_text.dart';
import 'sc_play.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Éducation artistique — 1re année primaire. Five games on the shared engine.
// ═══════════════════════════════════════════════════════════════════════════

/// Faces of answer cards: J:<colour> pot · B:<colour> blob · S:<stamp> · R:<beats>.
Widget artFace(ScOpt o, double th) {
  final s = o.sprite;
  if (s.startsWith('J:')) return Center(child: ArtJar(c: s.substring(2), size: th * 0.62));
  if (s.startsWith('B:')) return Center(child: ArtBlob(color: artColor(s.substring(2)), size: th * 0.9, seed: s.hashCode));
  if (s.startsWith('S:')) return Center(child: ArtStamp(id: s.substring(2), size: th * 0.7));
  if (s.startsWith('R:')) {
    final beats = s.substring(2).split(',');
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final b in beats) Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: ArtBeatCard(beat: b, size: th * 0.62, label: false)),
        ]),
      ),
    );
  }
  return const SizedBox();
}

/// Orange action button under the board ("Mélanger", "Terminer", "Garder ma création" …).
Widget artAction(BuildContext c, String label, IconData icon, VoidCallback? onTap, double w, {Animation<double>? pulse}) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: M1OrangeButton(label: label, icon: icon, onTap: onTap, width: min(w - 60, 300.0), height: 52, pulse: pulse),
    );

// ═══════════════════════════════════════════════════════════════════════════
// 1 · LE JARDIN DES COULEURS — je reconnais · je mélange · je colorie
// ═══════════════════════════════════════════════════════════════════════════

const List<(String, String, String)> _mixes0 = [('blue', 'yellow', 'green'), ('red', 'yellow', 'orange'), ('red', 'blue', 'purple')];
const List<(String, String, String)> _mixes1 = [('red', 'white', 'pink'), ('blue', 'white', 'lightblue'), ('black', 'white', 'grey')];

const Map<String, Map<String, List<String>>> _natural = {
  'flower': {'petals': ['red', 'pink', 'purple'], 'center': ['yellow'], 'stem': ['green'], 'leaf': ['green'], 'pot': ['orange', 'brown']},
  'house': {'roof': ['red'], 'wall': ['yellow', 'orange'], 'door': ['purple', 'brown'], 'window': ['blue'], 'grass': ['green'], 'sky_sun': ['yellow']},
  'butterfly': {'wings_top': ['orange', 'purple', 'blue'], 'wings_bottom': ['pink', 'yellow'], 'body': ['brown'], 'dots': ['yellow', 'red']},
};

class ArtColorsPlay extends M1Play {
  const ArtColorsPlay({super.key, required super.lv});
  @override
  State<ArtColorsPlay> createState() => _ColorsState();
}

class _ColorsState extends ScQuizState<ArtColorsPlay> {
  String _c = 'red';
  // mix
  late final AnimationController _mix = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  (String, String, String) _m = _mixes0.first;
  final List<String> _plate = [];
  List<String> _jars = [];
  final Map<String, GlobalKey> _jarKeys = {};
  final GlobalKey _plateKey = GlobalKey();
  bool _mixed = false;
  // coloring
  String _pic = 'flower';
  final Map<String, String> _fills = {};
  List<(String, String)> _steps = [];
  int _step = 0;
  String? _brush;
  final GlobalKey _picKey = GlobalKey();

  bool get _free => mode == 'color' && tier == 2;

  @override
  int get rounds => mode == 'color' ? (tier == 2 ? 1 : 2) : 5;

  @override
  void dispose() {
    _mix.dispose();
    super.dispose();
  }

  GlobalKey _jk(String c) => _jarKeys.putIfAbsent(c, () => GlobalKey());

  @override
  Widget optFace(ScOpt o, double th) => artFace(o, th);

  @override
  bool get optionsReady => mode != 'mix' || tier == 2 || _mixed;
  @override
  String get waitText => m1T(context, 'co_wait_mix');

  @override
  String get instruction => switch (mode) {
        'recognize' => m1T(context, 'co_q_find', {'c': m1T(context, 'co_n_$_c')}),
        'mix' => tier == 2
            ? m1T(context, 'co_q_make', {'c': m1T(context, 'co_n_${_m.$3}')})
            : (_mixed ? m1T(context, 'co_q_result') : m1T(context, 'co_q_mix', {'a': m1T(context, 'co_n_${_m.$1}'), 'b': m1T(context, 'co_n_${_m.$2}')})),
        _ => _free
            ? m1T(context, 'co_free')
            : (_step < _steps.length
                ? m1T(context, 'co_paint', {'r': m1T(context, 'co_r_${_steps[_step].$1}'), 'c': m1T(context, 'co_n_${_steps[_step].$2}')})
                : m1T(context, 'praise2')),
      };

  @override
  void newRound() {
    clearQuiz();
    _plate.clear();
    _mixed = false;
    _mix.value = 0;
    switch (mode) {
      case 'recognize':
        final pool = [
          ['red', 'yellow', 'blue'],
          ['red', 'yellow', 'blue', 'green', 'orange', 'purple'],
          ['red', 'yellow', 'blue', 'green', 'orange', 'purple', 'pink', 'brown'],
        ][tier];
        final pick = (List.of(pool)..shuffle(rng)).take([3, 4, 5][tier]).toList();
        _c = pick[rng.nextInt(pick.length)];
        opts = [for (final c in pick) ScOpt(c, tier < 2 && !['pink', 'brown'].contains(c) ? 'J:$c' : 'B:$c', 'co_n_$c')];
        answers = {_c};
        labels = tier == 0;
        missTopic = 'co_rev_$_c';
        missHelp = 'co_help_find';
      case 'mix':
        final pool = tier == 1 ? [..._mixes0, ..._mixes1] : _mixes0;
        _m = pool[rng.nextInt(pool.length)];
        if (tier == 2) {
          _jars = (['red', 'yellow', 'blue', 'white']..shuffle(rng));
        } else {
          _jars = [_m.$1, _m.$2];
        }
        final others = (['green', 'orange', 'purple', 'pink', 'lightblue', 'grey'].where((c) => c != _m.$3).toList()..shuffle(rng)).take(2);
        opts = [for (final c in [_m.$3, ...others]) ScOpt(c, 'B:$c', 'co_n_$c')]..shuffle(rng);
        answers = {_m.$3};
        labels = tier == 0;
        missTopic = 'co_rev_mix_${_m.$3}';
        missHelp = 'co_help_mix';
      default:
        _pic = artPictureIds[(round + lv.range) % artPictureIds.length];
        _fills.clear();
        _brush = null;
        _step = 0;
        final nat = _natural[_pic]!;
        final regions = artPicture(_pic).map((r) => r.$1).toList()..shuffle(rng);
        final take = tier == 0 ? 3 : regions.length;
        _steps = [for (final r in regions.take(take)) (r, nat[r]![rng.nextInt(nat[r]!.length)])];
        // the regions not asked are already painted
        for (final r in regions.skip(take)) {
          _fills[r] = nat[r]!.first;
        }
        missTopic = 'co_rev_paint';
    }
  }

  // ── mix ──
  void _pour(String c) {
    if (busy || _plate.contains(c) || _plate.length >= 2) return;
    setState(() => _plate.add(c));
    m1Sfx(context, 'art_splash.wav');
    M1Voice.say(context, m1T(context, 'co_n_$c'));
    if (_plate.length == 2) _doMix();
  }

  Future<void> _doMix() async {
    await _mix.forward(from: 0);
    if (!mounted) return;
    final res = _resultOf(_plate[0], _plate[1]);
    if (tier == 2) {
      if (res == _m.$3) {
        good(text: m1T(context, 'co_yes_mix', {'a': m1T(context, 'co_n_${_plate[0]}'), 'b': m1T(context, 'co_n_${_plate[1]}'), 'c': m1T(context, 'co_n_$res')}));
      } else {
        bad(m1T(context, 'co_rev_mix_${_m.$3}'), help: res == null ? m1T(context, 'co_help_make') : m1T(context, 'co_got', {'c': m1T(context, 'co_n_$res')}));
        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        setState(() {
          _plate.clear();
          _mix.value = 0;
        });
      }
    } else {
      setState(() => _mixed = true);
      say(m1T(context, 'co_q_result'));
    }
  }

  String? _resultOf(String a, String b) {
    for (final m in [..._mixes0, ..._mixes1]) {
      if ((m.$1 == a && m.$2 == b) || (m.$1 == b && m.$2 == a)) return m.$3;
    }
    return null;
  }

  Color get _plateColor {
    if (_plate.isEmpty) return Colors.white;
    if (_plate.length == 1) return artColor(_plate[0]);
    final res = _resultOf(_plate[0], _plate[1]);
    return res == null ? Color.lerp(artColor(_plate[0]), artColor(_plate[1]), 0.5)! : artColor(res);
  }

  // ── coloring ──
  void _paintAt(Offset local, Size size, [String? color]) {
    final c = color ?? _brush;
    if (busy) return;
    if (c == null) {
      say(m1T(context, 'co_pick_first'));
      return;
    }
    final r = ArtColoringPainter.hit(_pic, size, local);
    if (r == null) return;
    if (_free) {
      setState(() => _fills[r] = c);
      m1Sfx(context, 'art_splash.wav');
      return;
    }
    if (_step >= _steps.length) return;
    final (want, wc) = _steps[_step];
    if (r != want) {
      say(m1T(context, 'co_this_first', {'r': m1T(context, 'co_r_$want')}));
      return;
    }
    if (c != wc) {
      bad(m1T(context, 'co_rev_paint'), help: m1T(context, 'co_wrong_color', {'c': m1T(context, 'co_n_$wc')}));
      return;
    }
    setState(() {
      _fills[r] = c;
      _step++;
    });
    m1Sfx(context, 'art_splash.wav');
    burst.forward(from: 0);
    if (_step >= _steps.length) {
      good(text: m1T(context, 'co_pic_done'));
    } else {
      say(instruction);
    }
  }

  Future<void> _finishFree() async {
    final saved = await artSaveDialog(context, 'coloring', {'pic': _pic, 'f': Map<String, String>.from(_fills)}, m1T(context, 'co_pic_$_pic'));
    if (!mounted) return;
    good(text: m1T(context, saved ? 'art_saved' : 'praise3'));
  }

  @override
  void idleHelp() {
    switch (mode) {
      case 'mix':
        if (tier == 2) {
          say(m1T(context, 'co_help_make'));
          final need = [_m.$1, _m.$2].where((c) => !_plate.contains(c)).toList();
          if (need.isNotEmpty) showDrag(_jk(need.first), _plateKey, '', ghost: ArtJar(c: need.first, size: 56));
        } else if (!_mixed) {
          say(m1T(context, 'co_help_drag'));
          final need = _jars.where((c) => !_plate.contains(c)).toList();
          if (need.isNotEmpty) showDrag(_jk(need.first), _plateKey, '', ghost: ArtJar(c: need.first, size: 56));
        } else {
          super.idleHelp();
        }
      case 'color':
        if (_free || _step >= _steps.length) return say(instruction);
        final wc = _steps[_step].$2;
        say(instruction);
        showDrag(_jk(wc), _picKey, '', ghost: ArtJar(c: wc, size: 56));
      default:
        super.idleHelp();
    }
  }

  @override
  Future<void> explain() async {
    if (mode == 'color') {
      await Future.delayed(const Duration(milliseconds: 1200));
      return;
    }
    if (mode == 'mix') {
      M1Voice.say(context, m1T(context, 'co_yes_mix', {'a': m1T(context, 'co_n_${_m.$1}'), 'b': m1T(context, 'co_n_${_m.$2}'), 'c': m1T(context, 'co_n_${_m.$3}')}));
      setState(() => showWhy = true);
      await Future.delayed(const Duration(milliseconds: 2200));
      if (mounted) setState(() => showWhy = false);
      return;
    }
    return super.explain();
  }

  @override
  Widget? actions(BuildContext context, double w) =>
      _free ? artAction(context, m1T(context, 'art_finish'), Icons.check_rounded, _fills.length >= 2 && !busy ? _finishFree : null, w, pulse: pulse) : null;

  @override
  Widget board(BuildContext context, double w, double h) => switch (mode) {
        'recognize' => quizBoard(w, h, scene: Image.asset(m1('art_palette'), fit: BoxFit.contain), sceneFlex: 26),
        'mix' => quizBoard(w, h, scene: _mixScene(), sceneFlex: 44),
        _ => _colorBoard(w, h),
      };

  Widget _jar(String c, double size) {
    final used = _plate.contains(c);
    return Opacity(
      opacity: used ? 0.35 : 1,
      child: Draggable<String>(
        key: _jk(c),
        data: c,
        maxSimultaneousDrags: used || busy ? 0 : 1,
        feedback: Material(type: MaterialType.transparency, child: ArtJar(c: c, size: size * 1.1)),
        childWhenDragging: Opacity(opacity: 0.3, child: ArtJar(c: c, size: size)),
        child: M1Press(
          onTap: () => _pour(c),
          sound: '',
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            M1Float(amp: 2, phase: c.length * 0.1, child: ArtJar(c: c, size: size)),
            if (tier < 2) Text(m1T(context, 'co_n_$c'), style: m1Text(13)),
          ]),
        ),
      ),
    );
  }

  Widget _mixScene() => LayoutBuilder(builder: (_, c) {
        final js = min(c.maxHeight * 0.38, 66.0);
        final ps = min(c.maxWidth * 0.5, c.maxHeight * 0.75);
        final plate = DragTarget<String>(
          key: _plateKey,
          onWillAcceptWithDetails: (_) => !busy,
          onAcceptWithDetails: (d) => _pour(d.data),
          builder: (_, cand, __) => AnimatedScale(
            scale: cand.isNotEmpty ? 1.06 : 1,
            duration: const Duration(milliseconds: 160),
            child: Container(
              width: ps,
              height: ps * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.all(Radius.elliptical(ps, ps * 0.7)),
                color: Colors.white,
                border: Border.all(color: cand.isNotEmpty ? const Color(0xFF39B8F2) : const Color(0xFFE2DACB), width: 4),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), offset: const Offset(0, 5), blurRadius: 8)],
              ),
              child: AnimatedBuilder(
                animation: _mix,
                builder: (_, __) => CustomPaint(painter: _PlatePainter([for (final p in _plate) artColor(p)], _plateColor, _mix.value)),
              ),
            ),
          ),
        );
        return Column(children: [
          if (tier == 2)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(m1T(context, 'co_target'), style: m1Text(15)),
              const SizedBox(width: 8),
              ArtBlob(color: artColor(_m.$3), size: 54),
            ]),
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              if (tier < 2) _jar(_jars[0], js),
              plate,
              if (tier < 2) _jar(_jars[1], js),
            ]),
          ),
          if (tier == 2) Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (final j in _jars) _jar(j, js * 0.85)]),
        ]);
      });

  Widget _colorBoard(double w, double h) {
    final rh = min(h * 0.17, 92.0);
    final palette = _free
        ? ['red', 'yellow', 'blue', 'green', 'orange', 'purple', 'pink', 'brown']
        : {for (final s in _steps) s.$2, 'red', 'yellow', 'blue', 'green'}.toList();
    return Column(children: [
      SizedBox(height: rh, child: robotLine(w, rh, sprite: 'art_robot', robotH: rh)),
      M1SayPill(text: instruction, width: min(w - 24, 380.0), height: 46),
      const SizedBox(height: 6),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: M1Card(
            radius: 24,
            padding: const EdgeInsets.all(8),
            child: LayoutBuilder(builder: (_, c) {
              final size = Size(c.maxWidth, c.maxHeight);
              return DragTarget<String>(
                key: _picKey,
                onWillAcceptWithDetails: (_) => !busy,
                onAcceptWithDetails: (d) {
                  final box = _picKey.currentContext?.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  setState(() => _brush = d.data);
                  _paintAt(box.globalToLocal(d.offset) + const Offset(28, 32), size, d.data);
                },
                builder: (_, __, ___) => GestureDetector(
                  onTapUp: (d) => _paintAt(d.localPosition, size),
                  child: Stack(children: [
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: pulse,
                        builder: (_, __) => CustomPaint(
                          painter: ArtColoringPainter(_pic, _fills, !_free && _step < _steps.length ? _steps[_step].$1 : null, pulse.value),
                        ),
                      ),
                    ),
                    Positioned.fill(child: burstLayer()),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
      const SizedBox(height: 8),
      // the palette: pick a pot (or drag it onto the picture)
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          for (final p in palette)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Draggable<String>(
                key: _jk(p),
                data: p,
                feedback: Material(type: MaterialType.transparency, child: ArtJar(c: p, size: 56)),
                child: M1Press(
                  onTap: () {
                    setState(() => _brush = p);
                    M1Voice.say(context, m1T(context, 'co_n_$p'));
                  },
                  sound: 'toggleButton',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _brush == p ? const Color(0xFFDDF2FF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _brush == p ? const Color(0xFF39B8F2) : Colors.transparent, width: 3),
                    ),
                    child: ArtJar(c: p, size: 40),
                  ),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 4),
    ]);
  }
}

class _PlatePainter extends CustomPainter {
  final List<Color> colors;
  final Color result;
  final double t;
  _PlatePainter(this.colors, this.result, this.t);
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.shortestSide * 0.32;
    if (colors.isEmpty) return;
    if (colors.length == 1) {
      canvas.drawCircle(c, r, Paint()..color = colors[0]);
      return;
    }
    // two colours swirl around and melt into the result
    final a = t * 2 * pi * 2;
    final d = r * 0.6 * (1 - t);
    final ca = Color.lerp(colors[0], result, t)!, cb = Color.lerp(colors[1], result, t)!;
    canvas.drawCircle(c + Offset(cos(a), sin(a)) * d, r * (0.75 + 0.25 * t), Paint()..color = ca);
    canvas.drawCircle(c - Offset(cos(a), sin(a)) * d, r * (0.75 + 0.25 * t), Paint()..color = cb);
    if (t > 0.98) canvas.drawCircle(c, r, Paint()..color = result);
    final sw = Paint()
      ..color = Colors.white.withOpacity(0.5 * (1 - t))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.7), a, pi, false, sw);
  }

  @override
  bool shouldRepaint(_PlatePainter o) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// 2 · LES CHEMINS DU DESSIN — droites · courbes · spirales (tracer / créer)
// ═══════════════════════════════════════════════════════════════════════════

class ArtLinesPlay extends M1Play {
  const ArtLinesPlay({super.key, required super.lv});
  @override
  State<ArtLinesPlay> createState() => _LinesState();
}

class _LinesState extends M1PlayState<ArtLinesPlay> {
  List<Offset> _path = []; // fractions of the canvas
  int _done = 0;
  bool _stray = false, _strayCounted = false;
  late final AnimationController _demo = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  bool _demoOn = false;
  Size _size = Size.zero;
  // free drawing
  final List<ArtStroke> _strokes = [];
  String _col = 'blue';
  double _w = 0.025;
  bool _eraser = false;

  String get _mode => lv.modeId;
  bool get _free => lv.range == 2;

  @override
  int get rounds => _free ? 1 : 5;

  @override
  void dispose() {
    _demo.dispose();
    super.dispose();
  }

  @override
  String get instruction => _free ? m1T(context, 'ln_free_$_mode') : m1T(context, 'ln_trace');

  @override
  void newRound() {
    _done = 0;
    _stray = false;
    _demoOn = false;
    _path = _makePath(_mode, lv.range, round);
  }

  List<Offset> _sample(Offset Function(double t) f, [int n = 240]) => [for (var i = 0; i <= n; i++) f(i / n)];

  List<Offset> _poly(List<Offset> pts) {
    final out = <Offset>[];
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i], b = pts[i + 1];
      final n = max(8, ((b - a).distance * 120).round());
      for (var k = 0; k < n; k++) {
        out.add(Offset.lerp(a, b, k / n)!);
      }
    }
    return out..add(pts.last);
  }

  List<Offset> _makePath(String mode, int tier, int k) {
    final v = (k + rng.nextInt(3)) % 3;
    switch (mode) {
      case 'straight':
        if (tier == 0) {
          return _poly([
            [const Offset(0.12, 0.5), const Offset(0.88, 0.5)],
            [const Offset(0.5, 0.12), const Offset(0.5, 0.88)],
            [const Offset(0.14, 0.82), const Offset(0.86, 0.18)],
          ][v]);
        }
        return _poly([
          [const Offset(0.1, 0.7), const Offset(0.3, 0.3), const Offset(0.5, 0.7), const Offset(0.7, 0.3), const Offset(0.9, 0.7)],
          [const Offset(0.1, 0.85), const Offset(0.1, 0.62), const Offset(0.35, 0.62), const Offset(0.35, 0.4), const Offset(0.62, 0.4), const Offset(0.62, 0.18), const Offset(0.9, 0.18)],
          [const Offset(0.15, 0.2), const Offset(0.85, 0.2), const Offset(0.85, 0.8), const Offset(0.15, 0.8), const Offset(0.15, 0.4)],
        ][v]);
      case 'curves':
        if (tier == 0) {
          return [
            _sample((t) => Offset(0.12 + 0.76 * t, 0.7 - sin(t * pi) * 0.45)),
            _sample((t) => Offset(0.1 + 0.8 * t, 0.5 + sin(t * 2 * pi) * 0.22)),
            _sample((t) => Offset(0.12 + 0.76 * t, 0.3 + sin(t * pi) * 0.42)),
          ][v];
        }
        return [
          _sample((t) => Offset(0.08 + 0.84 * t, 0.5 + sin(t * 4 * pi) * 0.22)),
          _sample((t) => Offset(0.5 + sin(t * 2 * pi) * 0.3 * (t < 0.5 ? 1 : -1), 0.12 + 0.76 * t)),
          _sample((t) => Offset(0.08 + 0.84 * t, 0.62 - (sin(t * 3 * pi)).abs() * 0.4)),
        ][v];
      default: // spirals
        if (tier == 0) {
          return [
            _sample((t) => const Offset(0.5, 0.5) + Offset(cos(t * 3 * pi), sin(t * 3 * pi)) * (0.06 + 0.32 * t)),
            _sample((t) => const Offset(0.5, 0.5) + Offset(sin(t * 2 * pi * 0.97), -cos(t * 2 * pi * 0.97)) * 0.34),
            _sample((t) => const Offset(0.5, 0.5) + Offset(cos(-t * 3 * pi), sin(-t * 3 * pi)) * (0.38 - 0.3 * t)),
          ][v];
        }
        return [
          _sample((t) => const Offset(0.5, 0.5) + Offset(cos(t * 5 * pi), sin(t * 5 * pi)) * (0.04 + 0.34 * t), 400),
          _sample((t) => Offset(0.1 + 0.8 * t + sin(t * 6 * pi) * 0.07, 0.55 - (1 - cos(t * 6 * pi)) * 0.12), 400),
          _sample((t) => const Offset(0.5, 0.5) + Offset(cos(-t * 5 * pi), sin(-t * 5 * pi)) * (0.4 - 0.34 * t), 400),
        ][v];
    }
  }

  double get _tol => (_size.shortestSide == 0 ? 300 : _size.shortestSide) * (lv.range == 0 ? 0.085 : 0.06);
  Offset _px(Offset f) => Offset(f.dx * _size.width, f.dy * _size.height);

  void _touch(Offset p, {bool start = false}) {
    if (busy || _path.isEmpty) return;
    if (start) {
      _strayCounted = false;
      if (_demoOn) {
        _demo.stop();
        setState(() => _demoOn = false);
      }
    }
    var best = -1;
    var bd = double.infinity;
    final hi = min(_path.length - 1, _done + 30);
    for (var i = max(0, _done - 6); i <= hi; i++) {
      final d = (_px(_path[i]) - p).distance;
      if (d < bd) {
        bd = d;
        best = i;
      }
    }
    if (bd <= _tol) {
      if (best > _done || _stray) {
        setState(() {
          _done = max(_done, best);
          _stray = false;
        });
      }
      if (_done >= _path.length - 3) {
        good(text: m1T(context, 'ln_done'));
      }
    } else if (bd > _tol * 2.2 && !_stray) {
      setState(() => _stray = true);
      say(m1T(context, 'ln_stay'));
      if (lv.range == 1 && !_strayCounted) {
        _strayCounted = true;
        mistakes++;
      }
    }
  }

  @override
  void idleHelp() {
    if (_free) return say(instruction);
    say(m1T(context, 'ln_follow'));
    setState(() => _demoOn = true);
    _demo.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _demoOn = false);
    });
  }

  @override
  void hint() {
    mistakes++;
    idleHelp();
  }

  @override
  Future<void> explain() async {
    await Future.delayed(const Duration(milliseconds: 700));
  }

  Future<void> _finishFree() async {
    final saved = await artSaveDialog(context, 'drawing', {'s': [for (final s in _strokes) s.toJson()]}, m1T(context, 'ln_name_$_mode'));
    if (!mounted) return;
    good(text: m1T(context, saved ? 'art_saved' : 'praise3'));
  }

  @override
  Widget? actions(BuildContext context, double w) =>
      _free ? artAction(context, m1T(context, 'art_finish'), Icons.check_rounded, _strokes.length >= 3 && !busy ? _finishFree : null, w, pulse: pulse) : null;

  @override
  Widget board(BuildContext context, double w, double h) {
    final rh = min(h * 0.16, 88.0);
    return Column(children: [
      SizedBox(height: rh, child: robotLine(w, rh, sprite: 'art_robot', robotH: rh)),
      M1SayPill(text: instruction, width: min(w - 24, 380.0), height: 44),
      const SizedBox(height: 6),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF9A5B2E),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 5), blurRadius: 8)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                color: const Color(0xFFFFFAEE),
                child: LayoutBuilder(builder: (_, c) {
                  _size = Size(c.maxWidth, c.maxHeight);
                  return _free ? _drawCanvas() : _traceCanvas();
                }),
              ),
            ),
          ),
        ),
      ),
      if (_free) _toolbar(w),
      const SizedBox(height: 2),
    ]);
  }

  Widget _traceCanvas() {
    final s = _size;
    final bs = min(s.width, s.height) * 0.16;
    final cur = _px(_path[min(_done, _path.length - 1)]);
    final end = _px(_path.last);
    return GestureDetector(
      onPanStart: (d) => _touch(d.localPosition, start: true),
      onPanUpdate: (d) => _touch(d.localPosition),
      onTapDown: (d) => _touch(d.localPosition, start: true),
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(child: CustomPaint(painter: _TracePainter(_path, _done, _stray, const [m1Blue, m1Purple, m1Orange, m1Green, m1Red][round % 5]))),
        Positioned(left: end.dx - bs * 0.5, top: end.dy - bs * 0.8, child: M1Float(amp: 3, child: Image.asset(m1('ar_flowers'), width: bs))),
        Positioned(
          left: cur.dx - bs * 0.5,
          top: cur.dy - bs * 0.55,
          child: IgnorePointer(child: AnimatedBuilder(animation: idle, builder: (_, ch) => Transform.rotate(angle: sin(idle.value * 2 * pi * 6) * 0.12, child: ch), child: Image.asset(m1('ar_w_butterfly'), width: bs))),
        ),
        if (_demoOn)
          AnimatedBuilder(
            animation: _demo,
            builder: (_, __) {
              final i = (_done + (_path.length - 1 - _done) * Curves.easeInOut.transform(_demo.value)).round().clamp(0, _path.length - 1);
              final p = _px(_path[i]);
              return Positioned(left: p.dx - 8, top: p.dy - 4, child: IgnorePointer(child: Image.asset(m1('hand_tap'), width: 52)));
            },
          ),
        Positioned.fill(child: burstLayer()),
      ]),
    );
  }

  Widget _drawCanvas() {
    Offset f(Offset p) => Offset((p.dx / _size.width).clamp(0.0, 1.0), (p.dy / _size.height).clamp(0.0, 1.0));
    return GestureDetector(
      onPanStart: (d) => setState(() => _strokes.add(ArtStroke(_eraser ? 'white' : _col, _eraser ? 0.07 : _w, [f(d.localPosition)]))),
      onPanUpdate: (d) => setState(() => _strokes.last.pts.add(f(d.localPosition))),
      onTapUp: (d) => setState(() => _strokes.add(ArtStroke(_eraser ? 'white' : _col, _eraser ? 0.07 : _w, [f(d.localPosition)]))),
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _GuidePainter(_mode))),
        Positioned.fill(child: CustomPaint(painter: ArtStrokesPainter(_strokes))),
        Positioned.fill(child: burstLayer()),
      ]),
    );
  }

  Widget _toolbar(double w) {
    Widget tool(Widget child, bool on, VoidCallback tap) => M1Press(
          onTap: tap,
          sound: 'toggleButton',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? const Color(0xFFDDF2FF) : m1Cream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: on ? const Color(0xFF39B8F2) : m1Line, width: on ? 2.5 : 1.5),
            ),
            child: child,
          ),
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: const Color(0xFFFFF4DE), borderRadius: BorderRadius.circular(16), border: Border.all(color: m1Line, width: 2)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          tool(const Text('✏️', style: TextStyle(fontSize: 20)), !_eraser, () => setState(() => _eraser = false)),
          tool(const Text('🧽', style: TextStyle(fontSize: 20)), _eraser, () => setState(() => _eraser = true)),
          const SizedBox(width: 4),
          for (final c in ['blue', 'red', 'green', 'purple', 'orange', 'yellow'])
            tool(Container(width: 22, height: 22, decoration: BoxDecoration(color: artColor(c), shape: BoxShape.circle)), !_eraser && _col == c, () => setState(() {
                  _col = c;
                  _eraser = false;
                })),
          const SizedBox(width: 4),
          for (final s in [0.012, 0.025, 0.045])
            tool(Container(width: 6 + s * 300, height: 6 + s * 300, decoration: const BoxDecoration(color: m1Ink, shape: BoxShape.circle)), _w == s, () => setState(() => _w = s)),
          tool(const Icon(Icons.undo_rounded, color: m1Ink), false, () => setState(() {
                if (_strokes.isNotEmpty) _strokes.removeLast();
              })),
        ]),
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  final List<Offset> path;
  final int done;
  final bool stray;
  final Color color;
  _TracePainter(this.path, this.done, this.stray, this.color);
  @override
  void paint(Canvas canvas, Size s) {
    Offset p(Offset f) => Offset(f.dx * s.width, f.dy * s.height);
    final w = s.shortestSide;
    // wide soft road
    final road = Path()..moveTo(p(path.first).dx, p(path.first).dy);
    for (final q in path) {
      road.lineTo(p(q).dx, p(q).dy);
    }
    canvas.drawPath(road, Paint()
      ..color = (stray ? const Color(0xFFFFD6D6) : const Color(0xFFEDE4FF)).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
    // dotted guide
    final dot = Paint()..color = const Color(0xFFA8A0B5);
    for (var i = done; i < path.length; i += 6) {
      canvas.drawCircle(p(path[i]), w * 0.009, dot);
    }
    // traced part
    if (done > 0) {
      final tr = Path()..moveTo(p(path.first).dx, p(path.first).dy);
      for (var i = 1; i <= done; i++) {
        tr.lineTo(p(path[i]).dx, p(path[i]).dy);
      }
      canvas.drawPath(tr, Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
    }
    canvas.drawCircle(p(path.first), w * 0.025, Paint()..color = m1Green);
  }

  @override
  bool shouldRepaint(_TracePainter o) => true;
}

class _GuidePainter extends CustomPainter {
  final String mode;
  _GuidePainter(this.mode);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = const Color(0xFFE6DCF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var k = 0; k < 4; k++) {
      final y = s.height * (0.15 + k * 0.23);
      final path = Path()..moveTo(s.width * 0.05, y);
      for (var x = 0.05; x <= 0.95; x += 0.01) {
        final dy = switch (mode) { 'curves' => sin(x * 4 * pi) * s.height * 0.04, 'spirals' => 0.0, _ => 0.0 };
        path.lineTo(s.width * x, y + dy);
      }
      if (mode == 'spirals') {
        for (var i = 0; i < 3; i++) {
          final c = Offset(s.width * (0.2 + i * 0.3), y);
          final sp = Path();
          for (var t = 0.0; t <= 1; t += 0.02) {
            final q = c + Offset(cos(t * 4 * pi), sin(t * 4 * pi)) * (s.height * 0.07 * t);
            if (t == 0) {
              sp.moveTo(q.dx, q.dy);
            } else {
              sp.lineTo(q.dx, q.dy);
            }
          }
          canvas.drawPath(sp, p);
        }
      } else {
        canvas.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(_GuidePainter o) => o.mode != mode;
}

// ═══════════════════════════════════════════════════════════════════════════
// 3 · MA MAISON DE PAPIER — je reproduis · je complète · je crée
// ═══════════════════════════════════════════════════════════════════════════

const Map<String, List<(String, double, double)>> _models = {
  'house': [('grass', 0.5, 0.88), ('sun', 0.85, 0.15), ('wall', 0.5, 0.62), ('roof', 0.5, 0.32), ('door', 0.5, 0.72), ('window', 0.36, 0.58), ('window', 0.64, 0.58)],
  'garden': [('grass', 0.5, 0.9), ('sun', 0.84, 0.16), ('cloud', 0.48, 0.17), ('trunk', 0.28, 0.67), ('crown', 0.28, 0.42), ('flower', 0.6, 0.76), ('flower2', 0.8, 0.77)],
  'boat': [('sea', 0.5, 0.86), ('sun', 0.15, 0.15), ('cloud', 0.72, 0.15), ('hull', 0.5, 0.68), ('sail', 0.55, 0.44), ('sail2', 0.38, 0.5), ('fish', 0.2, 0.9)],
};
const List<String> _modelIds = ['house', 'garden', 'boat'];

class ArtCollagePlay extends M1Play {
  const ArtCollagePlay({super.key, required super.lv});
  @override
  State<ArtCollagePlay> createState() => _CollageState();
}

class _CollageState extends M1PlayState<ArtCollagePlay> {
  String get _mode => lv.modeId;
  String get _model => _modelIds[lv.range];
  List<(String, double, double)> get _slots => _models[_model]!;

  final Set<int> _filled = {};
  List<String> _tray = [];
  final Set<int> _used = {};
  int? _sel;
  final Map<int, int> _slotShake = {};
  final GlobalKey _boardKey = GlobalKey(), _trayKey = GlobalKey();
  final Map<int, GlobalKey> _slotKeys = {};
  // create
  final List<ArtPlaced> _placed = [];
  int? _pick;
  double _bw = 300;

  @override
  int get rounds => _mode == 'complete' ? 3 : 1;

  @override
  String get instruction => switch (_mode) {
        'copy' => m1T(context, 'cl_copy'),
        'complete' => m1T(context, 'cl_complete'),
        _ => m1T(context, 'cl_create'),
      };

  @override
  void newRound() {
    _filled.clear();
    _used.clear();
    _sel = null;
    _slotShake.clear();
    switch (_mode) {
      case 'copy':
        _tray = [for (final s in _slots) s.$1]..shuffle(rng);
      case 'complete':
        final idx = List.generate(_slots.length, (i) => i)..shuffle(rng);
        final missing = idx.take(2 + (round > 0 ? 1 : 0)).toSet();
        for (var i = 0; i < _slots.length; i++) {
          if (!missing.contains(i)) _filled.add(i);
        }
        final types = _slots.map((s) => s.$1).toSet();
        final others = (artPieces.keys.where((t) => !types.contains(t)).toList()..shuffle(rng)).take(2);
        _tray = [for (final i in missing) _slots[i].$1, ...others]..shuffle(rng);
      default:
        _tray = artPieces.keys.toList();
    }
  }

  int? get _nextSlot {
    for (var i = 0; i < _slots.length; i++) {
      if (!_filled.contains(i)) return i;
    }
    return null;
  }

  int? get _trayFor {
    final s = _nextSlot;
    if (s == null) return null;
    for (var i = 0; i < _tray.length; i++) {
      if (!_used.contains(i) && _tray[i] == _slots[s].$1) return i;
    }
    return null;
  }

  void _drop(int trayIdx, int slot) {
    if (busy || _filled.contains(slot) || _used.contains(trayIdx)) return;
    if (_tray[trayIdx] == _slots[slot].$1) {
      setState(() {
        _filled.add(slot);
        _used.add(trayIdx);
        _sel = null;
      });
      m1Sound(context, 'PopButton');
      M1Voice.say(context, m1T(context, 'cl_n_${_tray[trayIdx]}'));
      if (_filled.length == _slots.length) good(text: m1T(context, 'cl_done_$_model'));
    } else {
      setState(() {
        _sel = null;
        _slotShake[slot] = (_slotShake[slot] ?? 0) + 1;
      });
      bad(m1T(context, 'cl_rev'), help: m1T(context, 'cl_wrong', {'p': m1T(context, 'cl_n_${_slots[slot].$1}')}));
    }
  }

  void _addFree(String type, Offset local) {
    final h = _bw * 0.9;
    setState(() {
      _placed.add(ArtPlaced(type, (local.dx / _bw).clamp(0.05, 0.95), (local.dy / h).clamp(0.05, 0.95)));
      _pick = _placed.length - 1;
    });
    m1Sound(context, 'PopButton');
  }

  Future<void> _finishFree() async {
    final saved = await artSaveDialog(context, 'collage', {'p': [for (final p in _placed) p.toJson()]}, m1T(context, 'cl_name'));
    if (!mounted) return;
    good(text: m1T(context, saved ? 'art_saved' : 'praise3'));
  }

  @override
  void idleHelp() {
    if (_mode == 'create') return say(instruction);
    final t = _trayFor, s = _nextSlot;
    say(instruction);
    if (t != null && s != null) {
      final pt = artPieces[_tray[t]]!;
      showDrag(_trayKey, _slotKeys.putIfAbsent(s, () => GlobalKey()), '', ghost: ArtPiece(type: _tray[t], w: max(30.0, pt.w * 160), h: max(24.0, pt.h * 160)));
    }
  }

  @override
  void hint() {
    mistakes++;
    idleHelp();
  }

  @override
  Future<void> explain() async {
    await Future.delayed(const Duration(milliseconds: 900));
  }

  @override
  Widget? actions(BuildContext context, double w) => _mode == 'create'
      ? artAction(context, m1T(context, 'art_keep'), Icons.check_rounded, _placed.length >= 3 && !busy ? _finishFree : null, w, pulse: pulse)
      : null;

  @override
  Widget board(BuildContext context, double w, double h) {
    final rh = min(h * 0.15, 84.0);
    final trayH = min(h * 0.17, 92.0);
    final avail = h - rh - trayH - 70 - (_mode == 'create' ? 48 : 0);
    final copy = _mode != 'create';
    final bw0 = min(w - 30, avail / 0.9);
    final mw = min(bw0 * 0.3, 104.0); // model card width
    final mh = mw * 0.9 + 26;
    _bw = min(w - 30, (avail - (copy ? max(0.0, mh - 44) : 0)) / 0.9);
    final model = [for (final s in _slots) ArtPlaced(s.$1, s.$2, s.$3)];
    return Column(children: [
      SizedBox(height: rh, child: robotLine(w, rh, sprite: 'art_robot', robotH: rh)),
      // instruction + the model, side by side so the model never hides the board
      if (copy)
        SizedBox(
          height: mh,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            M1SayPill(text: instruction, width: min(w - mw - 40, 300.0), height: 44),
            const SizedBox(width: 8),
            M1Press(
              onTap: () => _zoomModel(model),
              child: Transform.rotate(
                angle: 0.04,
                child: Container(
                  width: mw + 8,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF9B62F2), width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.zoom_in_rounded, size: 13, color: m1Purple),
                      Text(m1T(context, 'cl_model'), style: m1Text(11, color: m1Purple)),
                    ]),
                    artCollage(model, mw),
                  ]),
                ),
              ),
            ),
          ]),
        )
      else
        M1SayPill(text: instruction, width: min(w - 24, 380.0), height: 44),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFC98B4E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(0, 4), blurRadius: 6)],
        ),
        child: _mode == 'create' ? _freeBoard() : _slotBoard(),
      ),
      if (_mode == 'create') _freeTools(),
      const Spacer(),
      _trayRow(w, trayH),
      const SizedBox(height: 4),
    ]);
  }

  /// Shows the model big, on demand.
  void _zoomModel(List<ArtPlaced> model) {
    final w = MediaQuery.sizeOf(context).width;
    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (c) => GestureDetector(
        onTap: () => Navigator.of(c).pop(),
        child: Center(
          child: M1PopIn(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF9B62F2), width: 3)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(m1T(context, 'cl_model'), style: m1Text(18, color: m1Purple)),
                const SizedBox(height: 6),
                artCollage(model, min(w * 0.8, 340.0)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _slotBoard() {
    final bw = _bw, bh = bw * 0.9;
    return Container(
      key: _boardKey,
      width: bw,
      height: bh,
      decoration: BoxDecoration(color: const Color(0xFFFFF8EA), borderRadius: BorderRadius.circular(10)),
      child: Stack(clipBehavior: Clip.none, children: [
        for (var i = 0; i < _slots.length; i++)
          () {
            final (type, x, y) = _slots[i];
            final t = artPieces[type]!;
            final pw = t.w * bw, ph = t.h * bw;
            final done = _filled.contains(i);
            return Positioned(
              left: x * bw - pw / 2,
              top: y * bh - ph / 2,
              child: DragTarget<int>(
                key: _slotKeys.putIfAbsent(i, () => GlobalKey()),
                onWillAcceptWithDetails: (_) => !done,
                onAcceptWithDetails: (d) => _drop(d.data, i),
                builder: (_, cand, __) => GestureDetector(
                  onTap: _sel == null || done ? null : () => _drop(_sel!, i),
                  child: M1Shake(
                    trigger: _slotShake[i] ?? 0,
                    child: done
                        ? M1PopIn(from: 0.6, child: ArtPiece(type: type, w: pw, h: ph))
                        : ArtPiece(type: type, w: pw, h: ph, ghost: true, lit: cand.isNotEmpty || (showHand && i == _nextSlot)),
                  ),
                ),
              ),
            );
          }(),
        Positioned.fill(child: burstLayer()),
      ]),
    );
  }

  Widget _freeBoard() {
    final bw = _bw, bh = bw * 0.9;
    return DragTarget<String>(
      key: _boardKey,
      onWillAcceptWithDetails: (_) => !busy,
      onAcceptWithDetails: (d) {
        final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
        if (box == null) return;
        final t = artPieces[d.data]!;
        _addFree(d.data, box.globalToLocal(d.offset) + Offset(t.w * 120 / 2, t.h * 120 / 2));
      },
      builder: (_, cand, __) => Container(
        width: bw,
        height: bh,
        decoration: BoxDecoration(
          color: cand.isNotEmpty ? const Color(0xFFF0F8FF) : const Color(0xFFFFF8EA),
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          for (var i = 0; i < _placed.length; i++)
            () {
              final p = _placed[i];
              final t = artPieces[p.type]!;
              final pw = t.w * bw * p.scale, ph = t.h * bw * p.scale;
              return Positioned(
                left: p.x * bw - pw / 2,
                top: p.y * bh - ph / 2,
                child: GestureDetector(
                  onTap: () => setState(() => _pick = i),
                  onPanStart: (_) => setState(() => _pick = i),
                  onPanUpdate: (d) => setState(() {
                    p.x = (p.x + d.delta.dx / bw).clamp(0.0, 1.0);
                    p.y = (p.y + d.delta.dy / bh).clamp(0.0, 1.0);
                  }),
                  child: Transform.rotate(
                    angle: p.turn,
                    child: DecoratedBox(
                      decoration: BoxDecoration(border: _pick == i ? Border.all(color: const Color(0xFF39B8F2), width: 2) : null),
                      child: ArtPiece(type: p.type, w: pw, h: ph),
                    ),
                  ),
                ),
              );
            }(),
          if (_placed.isEmpty) Center(child: Text(m1T(context, 'cl_drop_here'), style: m1Text(16, color: const Color(0xFFB5A88E)))),
        ]),
      ),
    );
  }

  Widget _freeTools() {
    final p = _pick != null && _pick! < _placed.length ? _placed[_pick!] : null;
    Widget b(IconData i, VoidCallback? tap) => M1Press(
          onTap: tap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: m1Cream, borderRadius: BorderRadius.circular(10), border: Border.all(color: m1Line, width: 1.5)),
            child: Icon(i, color: tap == null ? const Color(0xFFC9C0B0) : m1Ink, size: 22),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        b(Icons.rotate_right_rounded, p == null ? null : () => setState(() => p.turn += pi / 12)),
        b(Icons.zoom_in_rounded, p == null ? null : () => setState(() => p.scale = min(2.2, p.scale * 1.15))),
        b(Icons.zoom_out_rounded, p == null ? null : () => setState(() => p.scale = max(0.4, p.scale / 1.15))),
        b(Icons.copy_rounded, p == null ? null : () => setState(() => _placed.add(ArtPlaced(p.type, min(0.95, p.x + 0.06), min(0.95, p.y + 0.06), scale: p.scale, turn: p.turn)))),
        b(Icons.delete_rounded, p == null ? null : () => setState(() {
              _placed.removeAt(_pick!);
              _pick = null;
            })),
        b(Icons.undo_rounded, _placed.isEmpty ? null : () => setState(() {
              _placed.removeLast();
              _pick = null;
            })),
      ]),
    );
  }

  Widget _trayRow(double w, double trayH) {
    final cell = trayH - 16;
    return Container(
      key: _trayKey,
      height: trayH,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFD9A066),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB07A42), width: 3),
      ),
      child: ListView(scrollDirection: Axis.horizontal, children: [
        for (var i = 0; i < _tray.length; i++)
          if (!_used.contains(i))
            () {
              final type = _tray[i];
              final t = artPieces[type]!;
              final k = min(cell / t.w, cell / t.h) * 0.85;
              final piece = ArtPiece(type: type, w: t.w * k * 0.9, h: t.h * k * 0.9);
              final tile = Container(
                width: cell,
                height: cell,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _sel == i ? const Color(0xFFDDF2FF) : const Color(0xFFF6E3C6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _sel == i ? const Color(0xFF39B8F2) : Colors.transparent, width: 2.5),
                ),
                child: piece,
              );
              final fb = Material(type: MaterialType.transparency, child: ArtPiece(type: type, w: t.w * (_mode == 'create' ? 120 : _bw), h: t.h * (_mode == 'create' ? 120 : _bw)));
              if (_mode == 'create') {
                return Draggable<String>(data: type, feedback: fb, childWhenDragging: Opacity(opacity: 0.4, child: tile), child: tile);
              }
              return Draggable<int>(
                data: i,
                maxSimultaneousDrags: busy ? 0 : 1,
                feedback: fb,
                childWhenDragging: Opacity(opacity: 0.3, child: tile),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _sel = _sel == i ? null : i);
                    M1Voice.say(context, m1T(context, 'cl_n_$type'));
                  },
                  child: M1Spot(size: cell, hand: showHand && helpLevel >= 2 && i == _trayFor, child: tile),
                ),
              );
            }(),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4 · LES MOTIFS ENCHANTÉS — je complète · je reproduis · j'invente
// ═══════════════════════════════════════════════════════════════════════════

class ArtMotifsPlay extends M1Play {
  const ArtMotifsPlay({super.key, required super.lv});
  @override
  State<ArtMotifsPlay> createState() => _MotifsState();
}

class _MotifsState extends ScQuizState<ArtMotifsPlay> {
  List<String> _unit = [], _frise = [];
  String _next = '';
  // copy
  final List<String> _copy = [];
  List<String> _stamps = [];
  final Map<String, int> _stampShake = {};
  final Map<String, GlobalKey> _stampKeys = {};
  final GlobalKey _rowKey = GlobalKey();
  // invent
  final List<String> _mine = [];
  bool _repeated = false;

  @override
  int get rounds => mode == 'invent' ? 1 : 5;

  @override
  Widget optFace(ScOpt o, double th) => artFace(o, th);

  @override
  String get instruction => switch (mode) {
        'complete' => m1T(context, 'mo_next'),
        'copy' => m1T(context, 'mo_copy'),
        _ => _repeated ? m1T(context, 'mo_keep') : m1T(context, 'mo_invent', {'n': _unitLen}),
      };

  int get _unitLen => tier == 0 ? 2 : 3;

  String _rand(Set<String> not) {
    while (true) {
      final s = '${artStampShapes[rng.nextInt(artStampShapes.length)]}:${artStampColors[rng.nextInt(3)]}';
      if (!not.contains(s)) return s;
    }
  }

  List<String> _makeUnit() {
    final a = _rand({}), b = _rand({a}), c = _rand({a, b});
    return switch (tier) {
      0 => [a, b],
      1 => rng.nextBool() ? [a, a, b] : [a, b, c],
      _ => [
          [a, b, b],
          [a, b, a, c],
          [a, a, b, c],
        ][rng.nextInt(3)],
    };
  }

  @override
  void newRound() {
    clearQuiz();
    _copy.clear();
    _stampShake.clear();
    _mine.clear();
    _repeated = false;
    _unit = _makeUnit();
    final len = tier == 0 ? 5 : 6;
    _frise = [for (var i = 0; i < len; i++) _unit[i % _unit.length]];
    _next = _unit[len % _unit.length];
    switch (mode) {
      case 'complete':
        final others = {..._unit}..remove(_next);
        final opt = {_next, ...others};
        while (opt.length < 3) {
          opt.add(_rand(opt));
        }
        opts = [for (final s in opt.take(3)) ScOpt(s, 'S:$s', '')]..shuffle(rng);
        answers = {_next};
        labels = false;
        missTopic = 'mo_rev';
        missHelp = 'mo_help';
      case 'copy':
        final st = {..._unit};
        while (st.length < _unit.toSet().length + 2) {
          st.add(_rand(st));
        }
        _stamps = st.toList()..shuffle(rng);
      default:
        final st = <String>{};
        while (st.length < 8) {
          st.add(_rand(st));
        }
        _stamps = st.toList();
    }
  }

  String _name(String s) => m1T(context, 'mo_s_${s.split(':')[0]}');

  void _stamp(String s) {
    if (busy) return;
    if (mode == 'invent') {
      if (_repeated || _mine.length >= _unitLen) return;
      setState(() => _mine.add(s));
      m1Sound(context, 'PopButton');
      M1Voice.say(context, _name(s));
      return;
    }
    if (_copy.length >= _frise.length) return;
    if (s == _frise[_copy.length]) {
      setState(() => _copy.add(s));
      m1Sound(context, 'PopButton');
      M1Voice.say(context, _name(s));
      if (_copy.length == _frise.length) good(text: m1T(context, 'mo_copied'));
    } else {
      setState(() => _stampShake[s] = (_stampShake[s] ?? 0) + 1);
      bad(m1T(context, 'mo_rev'), help: m1T(context, 'mo_look', {'s': _name(_frise[_copy.length])}));
    }
  }

  Future<void> _repeat() async {
    setState(() => _repeated = true);
    for (var i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      setState(() => _frise = [for (var k = 0; k <= i; k++) _mine[k % _mine.length]]);
      m1Sound(context, 'PopButton');
    }
    say(instruction);
  }

  Future<void> _save() async {
    final saved = await artSaveDialog(context, 'motif', {'m': _frise}, m1T(context, 'mo_name'));
    if (!mounted) return;
    good(text: m1T(context, saved ? 'art_saved' : 'praise3'));
  }

  @override
  void idleHelp() {
    if (mode == 'copy' && _copy.length < _frise.length) {
      say(m1T(context, 'mo_look', {'s': _name(_frise[_copy.length])}));
      final k = _stampKeys[_frise[_copy.length]];
      if (k != null) showDrag(k, _rowKey, '', ghost: ArtStamp(id: _frise[_copy.length], size: 50));
      return;
    }
    if (mode == 'complete' && helpLevel == 1) {
      say(m1T(context, 'mo_help'));
      countAlong(_frise.length, word: (k) => _name(_frise[k]), ms: 750, demo: true);
      return;
    }
    super.idleHelp();
  }

  @override
  Future<void> explain() async {
    if (mode == 'invent') return;
    final all = mode == 'complete' ? [..._frise, _next] : _frise;
    await countAlong(all.length, word: (k) => _name(all[k]), ms: 600);
  }

  @override
  Widget? actions(BuildContext context, double w) {
    if (mode != 'invent') return null;
    if (!_repeated) return artAction(context, m1T(context, 'mo_repeat'), Icons.repeat_rounded, _mine.length == _unitLen ? _repeat : null, w, pulse: pulse);
    return artAction(context, m1T(context, 'mo_keep_btn'), Icons.check_rounded, busy ? null : _save, w, pulse: pulse);
  }

  Widget _friseRow(List<String?> items, double w, {bool slot = false, int? glow, Key? key}) {
    final n = items.length + (slot ? 1 : 0);
    final cell = min((w - 40) / max(n, 5), 58.0);
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF2A65A), width: 3),
        boxShadow: [BoxShadow(color: const Color(0xFF8A5A1A).withOpacity(0.2), offset: const Offset(0, 4), blurRadius: 6)],
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < items.length; i++)
            SizedBox(
              width: cell,
              height: cell,
              child: items[i] == null
                  ? CustomPaint(painter: _DashCircle(i == glow))
                  : M1PopIn(
                      key: ValueKey('f$i${items[i]}'),
                      from: 0.4,
                      child: M1Spot(on: countIdx == i, hand: countIdx == i, size: cell, child: ArtStamp(id: items[i]!, size: cell * 0.86)),
                    ),
            ),
          if (slot)
            SizedBox(
              width: cell,
              height: cell,
              child: busy
                  ? M1PopIn(child: M1Spot(on: countIdx == items.length, size: cell, child: ArtStamp(id: _next, size: cell * 0.86)))
                  : AnimatedBuilder(animation: pulse, builder: (_, __) => CustomPaint(painter: _DashCircle(sin(pulse.value * 2 * pi * 3) > 0))),
            ),
        ]),
      ),
    );
  }

  @override
  Widget board(BuildContext context, double w, double h) {
    if (mode == 'complete') return quizBoard(w, h, scene: FittedBox(child: _friseRow(_frise, w, slot: true)), sceneFlex: 30);
    final rh = min(h * 0.17, 92.0);
    final cell = min((w - 60) / 4.5, 64.0);
    return Column(children: [
      SizedBox(height: rh, child: robotLine(w, rh, sprite: 'art_robot', robotH: rh)),
      M1SayPill(text: instruction, width: min(w - 24, 380.0), height: 46),
      const SizedBox(height: 10),
      if (mode == 'copy') ...[
        Text(m1T(context, 'cl_model'), style: m1Text(14, color: m1Purple)),
        FittedBox(child: _friseRow(_frise, w)),
        const SizedBox(height: 10),
        Stack(children: [
          FittedBox(child: _friseRow([for (var i = 0; i < _frise.length; i++) i < _copy.length ? _copy[i] : null], w, glow: _copy.length, key: _rowKey)),
          Positioned.fill(child: burstLayer()),
        ]),
      ] else ...[
        Text(m1T(context, 'mo_my_unit'), style: m1Text(14, color: m1Purple)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < _unitLen; i++)
            GestureDetector(
              onTap: _repeated || i >= _mine.length ? null : () => setState(() => _mine.removeAt(i)),
              child: Container(
                margin: const EdgeInsets.all(4),
                width: cell,
                height: cell,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: i == _mine.length ? m1Orange : m1Line, width: 2.5)),
                child: i < _mine.length ? M1PopIn(child: ArtStamp(id: _mine[i], size: cell * 0.8)) : null,
              ),
            ),
        ]),
        const SizedBox(height: 10),
        if (_repeated) Stack(children: [FittedBox(child: _friseRow(_frise, w)), Positioned.fill(child: burstLayer())]),
      ],
      const Spacer(),
      if (!(mode == 'invent' && _repeated))
        Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
          for (final s in _stamps)
            M1Shake(
              key: _stampKeys.putIfAbsent(s, () => GlobalKey()),
              trigger: _stampShake[s] ?? 0,
              child: M1Press(
                onTap: () => _stamp(s),
                sound: '',
                child: Container(
                  width: cell,
                  height: cell,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFBF0), Color(0xFFF2DFC0)]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD9B57A), width: 2),
                    boxShadow: [BoxShadow(color: const Color(0xFF8A5A1A).withOpacity(0.35), offset: const Offset(0, 4))],
                  ),
                  child: Center(child: ArtStamp(id: s, size: cell * 0.72)),
                ),
              ),
            ),
        ]),
      const Spacer(),
    ]);
  }
}

class _DashCircle extends CustomPainter {
  final bool lit;
  _DashCircle(this.lit);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = lit ? const Color(0xFF39B8F2) : const Color(0xFF9C86C9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final path = Path()..addOval(Rect.fromCircle(center: s.center(Offset.zero), radius: s.shortestSide * 0.4));
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 8) {
        canvas.drawPath(m.extractPath(d, d + 4), p);
      }
    }
  }

  @override
  bool shouldRepaint(_DashCircle o) => o.lit != lit;
}

// ═══════════════════════════════════════════════════════════════════════════
// 5 · LA RONDE DES RYTHMES — j'écoute · je reproduis · je compose
// ═══════════════════════════════════════════════════════════════════════════

class ArtRhythmsPlay extends M1Play {
  const ArtRhythmsPlay({super.key, required super.lv});
  @override
  State<ArtRhythmsPlay> createState() => _RhythmsState();
}

class _RhythmsState extends ScQuizState<ArtRhythmsPlay> {
  List<String> _model = [];
  final List<String> _mine = [];
  bool _heard = false, _slow = false, _playing = false;
  int? _lit;
  String _litWhere = '';
  int _tok = 0;
  final Map<String, int> _btnShake = {};
  final Map<String, GlobalKey> _btnKeys = {};
  final GlobalKey _listenKey = GlobalKey();

  @override
  int get rounds => mode == 'compose' ? 1 : 5;

  int get _len => [3, 4, 5][tier];
  List<String> get _beats => tier == 0 ? ['clap', 'boum'] : ['clap', 'boum', 'rest'];

  @override
  Widget optFace(ScOpt o, double th) => artFace(o, th);

  @override
  int? get optCols => 1;

  @override
  bool get optionsReady => _heard;
  @override
  String get waitText => m1T(context, 'rt_wait');

  @override
  String get instruction => switch (mode) {
        'listen' => m1T(context, 'rt_q_listen'),
        'copy' => _heard ? m1T(context, 'rt_q_copy') : m1T(context, 'rt_listen_first'),
        _ => m1T(context, 'rt_q_compose'),
      };

  List<String> _randRhythm() {
    while (true) {
      final r = [for (var i = 0; i < _len; i++) _beats[rng.nextInt(_beats.length)]];
      if (r.where((b) => b != 'rest').length >= 2 && r.toSet().length > 1) return r;
    }
  }

  @override
  void newRound() {
    clearQuiz();
    _mine.clear();
    _heard = mode == 'compose';
    _lit = null;
    _model = _randRhythm();
    if (mode == 'listen') {
      final set = {_model.join(',')};
      while (set.length < 3) {
        final v = List.of(_model);
        final i = rng.nextInt(v.length);
        v[i] = _beats.where((b) => b != v[i]).toList()[rng.nextInt(_beats.length - 1)];
        set.add(v.join(','));
      }
      opts = [for (final s in set) ScOpt(s, 'R:$s', '')]..shuffle(rng);
      answers = {_model.join(',')};
      labels = false;
      missTopic = 'rt_rev';
      missHelp = 'rt_help';
    }
  }

  Future<void> _play(List<String> beats, String where) async {
    final tok = ++_tok;
    setState(() {
      _playing = true;
      _litWhere = where;
    });
    for (var i = 0; i < beats.length; i++) {
      if (!mounted || tok != _tok) return;
      setState(() => _lit = i);
      artBeat(context, beats[i]);
      await Future.delayed(Duration(milliseconds: _slow ? 900 : 620));
    }
    if (!mounted || tok != _tok) return;
    setState(() {
      _lit = null;
      _playing = false;
    });
  }

  Future<void> _listen() async {
    await _play(_model, 'model');
    if (!mounted) return;
    if (!_heard) {
      setState(() => _heard = true);
      say(instruction);
    }
  }

  void _press(String b) {
    if (busy) return;
    if (mode == 'compose') {
      if (_mine.length >= 6) return;
      setState(() => _mine.add(b));
      artBeat(context, b);
      return;
    }
    if (!_heard) {
      say(m1T(context, 'rt_listen_first'));
      return;
    }
    if (_mine.length >= _model.length) return;
    if (b == _model[_mine.length]) {
      setState(() => _mine.add(b));
      artBeat(context, b);
      if (_mine.length == _model.length) good(text: m1T(context, 'rt_copied'));
    } else {
      setState(() => _btnShake[b] = (_btnShake[b] ?? 0) + 1);
      bad(m1T(context, 'rt_rev'), help: m1T(context, 'rt_next_${_model[_mine.length]}'));
    }
  }

  Future<void> _save() async {
    final saved = await artSaveDialog(context, 'rhythm', {'b': _mine}, m1T(context, 'rt_name'));
    if (!mounted) return;
    good(text: m1T(context, saved ? 'art_saved' : 'praise3'));
  }

  @override
  void idleHelp() {
    if (!_heard) {
      say(m1T(context, 'rt_listen_first'));
      showTap(_listenKey);
      return;
    }
    if (mode == 'copy' && _mine.length < _model.length) {
      say(m1T(context, 'rt_next_${_model[_mine.length]}'));
      final k = _btnKeys[_model[_mine.length]];
      if (k != null) showTap(k);
      return;
    }
    super.idleHelp();
  }

  @override
  Future<void> explain() async {
    if (mode == 'compose') return;
    await _play(_model, 'model');
  }

  @override
  Widget? actions(BuildContext context, double w) {
    if (mode != 'compose') return null;
    return artAction(context, m1T(context, 'rt_keep'), Icons.check_rounded, _mine.length >= 4 && !busy ? _save : null, w, pulse: pulse);
  }

  Widget _row(List<String?> beats, String where, double w, {bool labels = true}) {
    final n = beats.length;
    final cell = min((w - 40) / max(n, 4) - 6, 74.0);
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (var i = 0; i < n; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: beats[i] == null
              ? Container(
                  width: cell,
                  height: cell * 1.15,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(cell * 0.22),
                    border: Border.all(color: i == _mine.length ? const Color(0xFF39B8F2) : const Color(0xFFD9C9A6), width: 2),
                  ),
                )
              : GestureDetector(
                  onTap: mode == 'compose' && where == 'mine' && !busy ? () => setState(() => _mine.removeAt(i)) : null,
                  child: M1PopIn(key: ValueKey('$where$i${beats[i]}'), from: 0.5, child: ArtBeatCard(beat: beats[i]!, size: cell, lit: _litWhere == where && _lit == i, label: labels)),
                ),
        ),
    ]);
  }

  Widget _listenBtn(String label, VoidCallback? onTap) => M1Press(
        key: _listenKey,
        onTap: onTap,
        sound: '',
        child: AnimatedBuilder(
          animation: pulse,
          builder: (_, ch) => Transform.scale(scale: _heard ? 1 : 1 + 0.04 * sin(pulse.value * 2 * pi * 3), child: ch),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF9B62F2), Color(0xFF6A2BD9)]),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [BoxShadow(color: m1Purple.withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_playing ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 8),
              Text(label, style: m1Text(18, color: Colors.white)),
            ]),
          ),
        ),
      );

  Widget _speed() => M1Press(
        onTap: () => setState(() => _slow = !_slow),
        sound: 'toggleButton',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: m1Cream, borderRadius: BorderRadius.circular(18), border: Border.all(color: m1Line, width: 2)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('🐌', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(m1T(context, 'rt_slow'), style: m1Text(13)),
            const SizedBox(width: 6),
            Icon(_slow ? Icons.toggle_on_rounded : Icons.toggle_off_rounded, color: _slow ? m1Green : const Color(0xFFB5ADA0), size: 28),
          ]),
        ),
      );

  Widget _bigButtons(double w) {
    final bs = min((w - 60) / _beats.length, 120.0);
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (final b in _beats)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: M1Shake(
            key: _btnKeys.putIfAbsent(b, () => GlobalKey()),
            trigger: _btnShake[b] ?? 0,
            child: M1Press(
              onTap: () => _press(b),
              sound: '',
              scale: 0.85,
              child: ArtBeatCard(beat: b, size: bs),
            ),
          ),
        ),
    ]);
  }

  @override
  Widget board(BuildContext context, double w, double h) {
    if (mode == 'listen') {
      return quizBoard(
        w,
        h,
        scene: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Expanded(child: M1Float(child: Image.asset(m1('art_drum'), fit: BoxFit.contain))),
          const SizedBox(height: 6),
          _listenBtn(m1T(context, _heard ? 'rt_again' : 'rt_listen'), _playing ? null : _listen),
          const SizedBox(height: 4),
          _speed(),
        ]),
        sceneFlex: 40,
      );
    }
    final rh = min(h * 0.16, 88.0);
    return Column(children: [
      SizedBox(height: rh, child: robotLine(w, rh, sprite: 'art_robot', robotH: rh)),
      M1SayPill(text: instruction, width: min(w - 24, 380.0), height: 44),
      const SizedBox(height: 8),
      if (mode == 'copy') ...[
        M1Card(padding: const EdgeInsets.all(8), radius: 20, child: _row(_model, 'model', w)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _listenBtn(m1T(context, _heard ? 'rt_again' : 'rt_listen'), _playing ? null : _listen),
          const SizedBox(width: 8),
          _speed(),
        ]),
        const SizedBox(height: 8),
        Stack(children: [
          _row([for (var i = 0; i < _model.length; i++) i < _mine.length ? _mine[i] : null], 'mine', w),
          Positioned.fill(child: burstLayer()),
        ]),
      ] else ...[
        Text(m1T(context, 'rt_my_rhythm'), style: m1Text(15, color: m1Purple)),
        const SizedBox(height: 4),
        _row([for (var i = 0; i < 6; i++) i < _mine.length ? _mine[i] : null], 'mine', w),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _listenBtn(m1T(context, 'rt_play_mine'), _mine.isEmpty || _playing ? null : () => _play(_mine, 'mine')),
          const SizedBox(width: 8),
          _speed(),
        ]),
      ],
      const Spacer(),
      _bigButtons(w),
      const Spacer(),
    ]);
  }
}
