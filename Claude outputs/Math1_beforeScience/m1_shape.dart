import 'dart:math';

import 'package:flutter/material.dart';

import 'm1_kit.dart';
import 'm1_shell.dart';
import 'm1_text.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Le village des formes — je reconnais · je trie · je construis · les suites
// ═══════════════════════════════════════════════════════════════════════════

enum M1Kind { circle, square, triangle }

const Map<M1Kind, List<String>> _sprites = {
  M1Kind.circle: ['sh_circle_red', 'sh_circle_blue', 'sh_circle_red2'],
  M1Kind.square: ['sh_square_green', 'sh_square_yellow', 'sh_square_blue'],
  M1Kind.triangle: ['sh_triangle_orange', 'sh_triangle_purple', 'sh_triangle_yellow'],
};

class _Shape {
  final M1Kind kind;
  final String sprite;
  final double scale, turn;
  const _Shape(this.kind, this.sprite, {this.scale = 1, this.turn = 0});
  Widget view(double size) => Transform.rotate(
        angle: turn,
        child: Image.asset(m1(sprite), width: size * scale, height: size * scale, fit: BoxFit.contain),
      );
}

/// A dashed outline of a shape (where a piece must go).
class _Outline extends CustomPainter {
  final M1Kind kind;
  final bool lit;
  _Outline(this.kind, {this.lit = false});
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = lit ? const Color(0xFF39B8F2) : const Color(0xFF7B3FE4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = lit ? 3.5 : 2.5;
    final r = Rect.fromLTWH(4, 4, s.width - 8, s.height - 8);
    final path = switch (kind) {
      M1Kind.circle => Path()..addOval(r),
      M1Kind.square => Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.1))),
      M1Kind.triangle => Path()
        ..moveTo(r.center.dx, r.top)
        ..lineTo(r.right, r.bottom)
        ..lineTo(r.left, r.bottom)
        ..close(),
    };
    canvas.drawPath(path, Paint()..color = (lit ? const Color(0xFF39B8F2) : const Color(0xFF7B3FE4)).withOpacity(0.07));
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, d + 6), p);
      }
    }
  }

  @override
  bool shouldRepaint(_Outline o) => o.kind != kind || o.lit != lit;
}

/// A picture to build: slots (kind + rect as fractions of the board).
class _Model {
  final String id;
  final List<(M1Kind, Rect)> slots;
  const _Model(this.id, this.slots);
}

const _models = [
  _Model('house', [
    (M1Kind.triangle, Rect.fromLTWH(0.22, 0.02, 0.56, 0.38)),
    (M1Kind.square, Rect.fromLTWH(0.28, 0.42, 0.44, 0.5)),
    (M1Kind.circle, Rect.fromLTWH(0.8, 0.0, 0.18, 0.2)),
  ]),
  _Model('tree', [
    (M1Kind.triangle, Rect.fromLTWH(0.25, 0.0, 0.5, 0.42)),
    (M1Kind.triangle, Rect.fromLTWH(0.2, 0.28, 0.6, 0.42)),
    (M1Kind.square, Rect.fromLTWH(0.41, 0.72, 0.18, 0.24)),
  ]),
  _Model('robot', [
    (M1Kind.square, Rect.fromLTWH(0.33, 0.0, 0.34, 0.3)),
    (M1Kind.square, Rect.fromLTWH(0.27, 0.32, 0.46, 0.42)),
    (M1Kind.circle, Rect.fromLTWH(0.24, 0.76, 0.22, 0.24)),
    (M1Kind.circle, Rect.fromLTWH(0.54, 0.76, 0.22, 0.24)),
  ]),
  _Model('rocket', [
    (M1Kind.triangle, Rect.fromLTWH(0.33, 0.0, 0.34, 0.28)),
    (M1Kind.square, Rect.fromLTWH(0.33, 0.3, 0.34, 0.32)),
    (M1Kind.circle, Rect.fromLTWH(0.41, 0.36, 0.18, 0.2)),
    (M1Kind.triangle, Rect.fromLTWH(0.14, 0.6, 0.22, 0.3)),
    (M1Kind.triangle, Rect.fromLTWH(0.64, 0.6, 0.22, 0.3)),
  ]),
  _Model('snowman', [
    (M1Kind.triangle, Rect.fromLTWH(0.38, 0.0, 0.24, 0.2)),
    (M1Kind.circle, Rect.fromLTWH(0.34, 0.2, 0.32, 0.3)),
    (M1Kind.circle, Rect.fromLTWH(0.26, 0.5, 0.48, 0.48)),
    (M1Kind.square, Rect.fromLTWH(0.78, 0.6, 0.16, 0.16)),
  ]),
];

class M1ShapePlay extends M1Play {
  const M1ShapePlay({super.key, required super.lv});
  @override
  State<M1ShapePlay> createState() => _ShapeState();
}

class _ShapeState extends M1PlayState<M1ShapePlay> {
  String get _mode => lv.modeId;
  int get _diff => lv.range;

  // recognize
  M1Kind _target = M1Kind.circle;
  List<_Shape> _field = [];
  final Set<int> _found = {};
  final Map<int, int> _shake = {};
  // sort
  List<_Shape> _tray = [];
  final Map<int, M1Kind> _placed = {}; // tray index → house
  int? _selected;
  // build
  _Model _model = _models[0];
  final Map<int, int> _filled = {}; // slot → tray index
  // sequence
  List<_Shape> _seq = [];
  _Shape? _missing;
  List<_Shape> _seqOptions = [];
  int _seqShake = -1, _seqShakeN = 0;
  bool _seqDone = false;

  String _kindName(M1Kind k, {bool plural = false}) => m1T(context, 'sh_${k.name}${plural ? 's' : ''}');

  _Shape _rand(M1Kind k, {bool vary = true}) {
    final list = _sprites[k]!;
    final sp = list[rng.nextInt(list.length)];
    final sc = vary && _diff > 0 ? 0.7 + rng.nextDouble() * 0.3 : 1.0;
    final turn = vary && _diff == 2 && k != M1Kind.circle ? (rng.nextDouble() - 0.5) * 0.9 : 0.0;
    return _Shape(k, sp, scale: sc, turn: turn);
  }

  @override
  String get instruction => switch (_mode) {
        'recognize' => m1T(context, 'sh_find', {'s': _kindName(_target, plural: true)}),
        'sort' => m1T(context, 'sh_sort'),
        'build' => m1T(context, 'sh_build', {'m': m1T(context, 'sh_m_${_model.id}')}),
        _ => m1T(context, 'sh_next'),
      };

  @override
  void newRound() {
    _found.clear();
    _placed.clear();
    _filled.clear();
    _selected = null;
    _seqDone = false;
    switch (_mode) {
      case 'recognize':
        _target = M1Kind.values[rng.nextInt(3)];
        final n = [6, 8, 10][_diff];
        final targets = 2 + rng.nextInt(2) + _diff;
        _field = [
          for (var i = 0; i < targets; i++) _rand(_target),
          for (var i = targets; i < n; i++) _rand(M1Kind.values.where((k) => k != _target).toList()[rng.nextInt(2)]),
        ]..shuffle(rng);
      case 'sort':
        final n = [6, 6, 9][_diff];
        _tray = [for (var i = 0; i < n; i++) _rand(M1Kind.values[i % 3])]..shuffle(rng);
      case 'build':
        final pool = _diff == 0 ? _models.sublist(0, 2) : (_diff == 1 ? _models.sublist(1, 4) : _models.sublist(2));
        _model = pool[rng.nextInt(pool.length)];
        final need = [for (final s in _model.slots) _rand(s.$1, vary: false)];
        final extra = _diff == 0 ? 0 : _diff;
        _tray = [...need, for (var i = 0; i < extra; i++) _rand(M1Kind.values[rng.nextInt(3)], vary: false)]..shuffle(rng);
      default:
        _makeSequence();
    }
  }

  void _makeSequence() {
    final kinds = [...M1Kind.values]..shuffle(rng);
    List<int> unit;
    if (_diff == 0) {
      unit = [0, 1];
    } else if (_diff == 1) {
      unit = rng.nextBool() ? [0, 0, 1] : [0, 1, 1];
    } else {
      unit = rng.nextBool() ? [0, 1, 2] : [0, 0, 1, 2];
    }
    final shapes = [for (final k in kinds) _Shape(k, _sprites[k]![rng.nextInt(2)])];
    final len = unit.length * 2 + (unit.length == 2 ? 1 : 0);
    final full = [for (var i = 0; i <= len; i++) shapes[unit[i % unit.length]]];
    _seq = full.sublist(0, len);
    _missing = full[len];
    final others = shapes.where((s) => s.kind != _missing!.kind).toList();
    _seqOptions = [_missing!, ...others.take(2)]..shuffle(rng);
  }

  // ── recognize ──
  void _tapField(int i) {
    if (busy || _found.contains(i)) return;
    if (_field[i].kind == _target) {
      setState(() => _found.add(i));
      m1Sound(context, 'PopButton');
      final total = _field.where((s) => s.kind == _target).length;
      if (_found.length == total) {
        good(text: m1T(context, 'sh_all_found', {'n': total, 's': _kindName(_target, plural: total > 1)}));
      } else {
        M1Voice.say(context, '${_found.length}');
      }
    } else {
      setState(() => _shake[i] = (_shake[i] ?? 0) + 1);
      bad(m1T(context, 'sh_rev_${_target.name}'), help: m1T(context, 'sh_not', {'a': _kindName(_field[i].kind), 'b': _kindName(_target)}));
    }
  }

  // ── sort ──
  void _drop(int i, M1Kind house) {
    if (busy || _placed.containsKey(i)) return;
    if (_tray[i].kind == house) {
      setState(() {
        _placed[i] = house;
        _selected = null;
      });
      m1Sound(context, 'PopButton');
      if (_placed.length == _tray.length) {
        good(text: m1T(context, 'sh_sorted'));
      } else {
        say(m1T(context, 'sh_good_house', {'s': _kindName(house)}), speak: true);
      }
    } else {
      setState(() => _selected = null);
      bad(m1T(context, 'sh_rev_sort'), help: m1T(context, 'sh_wrong_house', {'s': _kindName(_tray[i].kind)}));
    }
  }

  // ── build ──
  void _fill(int slot, int i) {
    if (busy || _filled.containsKey(slot) || _filled.containsValue(i)) return;
    if (_model.slots[slot].$1 == _tray[i].kind) {
      setState(() {
        _filled[slot] = i;
        _selected = null;
      });
      m1Sound(context, 'PopButton');
      if (_filled.length == _model.slots.length) {
        good(text: m1T(context, 'sh_built', {'m': m1T(context, 'sh_m_${_model.id}')}), wait: 1600);
      }
    } else {
      setState(() => _selected = null);
      bad(m1T(context, 'sh_rev_build'), help: m1T(context, 'sh_wrong_slot', {'s': _kindName(_model.slots[slot].$1)}));
    }
  }

  // ── sequence ──
  void _pickSeq(int k) {
    if (busy) return;
    if (_seqOptions[k].kind == _missing!.kind && _seqOptions[k].sprite == _missing!.sprite) {
      setState(() => _seqDone = true);
      good();
    } else {
      setState(() {
        _seqShake = k;
        _seqShakeN++;
      });
      bad(m1T(context, 'sh_rev_seq'), help: m1T(context, 'sh_seq_help'));
    }
  }

  @override
  void hint() {
    mistakes++;
    switch (_mode) {
      case 'recognize':
        say(m1T(context, 'sh_hint_${_target.name}'));
      case 'sort':
        say(m1T(context, 'sh_sort_help'));
      case 'build':
        final free = [for (var s = 0; s < _model.slots.length; s++) if (!_filled.containsKey(s)) s];
        if (free.isNotEmpty) say(m1T(context, 'sh_hint_${_model.slots[free.first].$1.name}'));
      default:
        say(m1T(context, 'sh_seq_help'));
    }
  }

  @override
  Widget board(BuildContext context, double w, double h) {
    final topH = min(h * 0.22, 106.0);
    return Column(children: [
      SizedBox(height: topH, child: robotLine(w, topH, sprite: 'robot_point_r', robotH: topH)),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Stack(children: [
            switch (_mode) {
              'recognize' => _recognize(),
              'sort' => _sort(),
              'build' => _build(),
              _ => _sequence(),
            },
            Positioned.fill(child: burstLayer()),
          ]),
        ),
      ),
    ]);
  }

  Widget _recognize() => LayoutBuilder(builder: (_, c) {
        final n = _field.length;
        final cols = n <= 6 ? 3 : (n <= 8 ? 4 : 5);
        final rows = (n / cols).ceil();
        final cell = min((c.maxWidth - 20) / cols, (c.maxHeight - 80) / rows);
        return Column(children: [
          M1SayPill(text: instruction, width: c.maxWidth, height: 48),
          const SizedBox(height: 8),
          Expanded(
            child: M1Card(
              radius: 26,
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Wrap(alignment: WrapAlignment.center, runAlignment: WrapAlignment.center, children: [
                  for (var i = 0; i < n; i++)
                    SizedBox(
                      width: cell,
                      height: cell,
                      child: M1PopIn(
                        delay: 50 * i,
                        key: ValueKey('r$round-$i'),
                        child: M1Shake(
                          trigger: _shake[i] ?? 0,
                          child: GestureDetector(
                            onTap: () => _tapField(i),
                            child: Stack(alignment: Alignment.center, children: [
                              AnimatedScale(
                                scale: _found.contains(i) ? 1.12 : 1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.elasticOut,
                                child: Container(
                                  margin: EdgeInsets.all(cell * 0.06),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _found.contains(i) ? const Color(0xFFDFF8D6) : Colors.transparent,
                                    boxShadow: [if (_found.contains(i)) BoxShadow(color: m1Green.withOpacity(0.45), blurRadius: 12)],
                                  ),
                                  alignment: Alignment.center,
                                  child: _field[i].view(cell * 0.72),
                                ),
                              ),
                              if (_found.contains(i)) Positioned(right: cell * 0.06, top: cell * 0.06, child: M1PopIn(child: Image.asset(m1('check'), width: cell * 0.3))),
                            ]),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ]);
      });

  Widget _sort() => LayoutBuilder(builder: (_, c) {
        final W = c.maxWidth, H = c.maxHeight;
        final houseW = min((W - 16) / 3, (H * 0.5) / m1Ratio('hut_circle'));
        final houseH = houseW * m1Ratio('hut_circle');
        final houses = [M1Kind.circle, M1Kind.square, M1Kind.triangle];
        final left = [for (var i = 0; i < _tray.length; i++) if (!_placed.containsKey(i)) i];
        final cell = min((W - 30) / 6, H * 0.14);
        return Column(children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              for (final k in houses)
                DragTarget<int>(
                  onWillAcceptWithDetails: (_) => true,
                  onAcceptWithDetails: (d) => _drop(d.data, k),
                  builder: (_, cand, __) => GestureDetector(
                    onTap: _selected == null ? null : () => _drop(_selected!, k),
                    child: AnimatedScale(
                      scale: cand.isNotEmpty || _selected != null ? 1.05 : 1,
                      duration: const Duration(milliseconds: 180),
                      child: SizedBox(
                        width: houseW,
                        height: houseH,
                        child: Stack(children: [
                          Positioned.fill(child: Image.asset(m1('hut_${k.name}'), fit: BoxFit.fill)),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: houseH * 0.06,
                            child: Center(child: FittedBox(child: Text(_kindName(k, plural: true), style: m1Text(14)))),
                          ),
                          Positioned(
                            left: houseW * 0.12,
                            right: houseW * 0.12,
                            top: houseH * 0.6,
                            bottom: houseH * 0.08,
                            child: Wrap(alignment: WrapAlignment.center, runAlignment: WrapAlignment.center, children: [
                              for (final e in _placed.entries)
                                if (e.value == k) M1PopIn(child: _tray[e.key].view(min(houseW * 0.25, 30.0))),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          const Spacer(),
          M1SayPill(text: instruction, width: W, height: 44),
          const SizedBox(height: 8),
          // the tray of shapes
          Container(
            width: W,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: m1Line, width: 3),
              boxShadow: [BoxShadow(color: const Color(0xFF8A5A1A).withOpacity(0.2), offset: const Offset(0, 4), blurRadius: 6)],
            ),
            child: Wrap(alignment: WrapAlignment.center, spacing: 4, runSpacing: 4, children: [
              for (final i in left)
                Draggable<int>(
                  data: i,
                  feedback: Material(type: MaterialType.transparency, child: _tray[i].view(cell * 1.15)),
                  childWhenDragging: Opacity(opacity: 0.25, child: SizedBox(width: cell, height: cell, child: Center(child: _tray[i].view(cell * 0.85)))),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selected = _selected == i ? null : i);
                      m1Sound(context, 'toggleButton');
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: cell,
                      height: cell,
                      decoration: BoxDecoration(
                        color: _selected == i ? const Color(0xFFDDF2FF) : Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _selected == i ? const Color(0xFF39B8F2) : const Color(0xFFEFE3CB), width: _selected == i ? 3 : 1.5),
                      ),
                      alignment: Alignment.center,
                      child: _tray[i].view(cell * 0.78),
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 8),
          _sortProgress(W),
          const SizedBox(height: 4),
        ]);
      });

  Widget _sortProgress(double W) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(color: const Color(0xFFF1E6FF), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFD5BFF5), width: 2)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(m1T(context, 'sh_progress', {'n': _placed.length, 't': _tray.length}), style: m1Text(14)),
          const SizedBox(width: 8),
          for (var i = 0; i < _tray.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 11,
              height: 11,
              decoration: BoxDecoration(shape: BoxShape.circle, color: i < _placed.length ? m1Purple : const Color(0xFFD8C8EE)),
            ),
        ]),
      );

  Widget _build() => LayoutBuilder(builder: (_, c) {
        final W = c.maxWidth, H = c.maxHeight;
        final cell = min((W - 30) / max(4, _tray.length), H * 0.15);
        final boardH = H - cell - 100;
        final bs = min(W * 0.78, boardH);
        return Column(children: [
          M1SayPill(text: instruction, width: W, height: 46),
          const SizedBox(height: 6),
          Expanded(
            child: Center(
              child: M1Card(
                radius: 26,
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                  width: bs,
                  height: bs * 0.9,
                  child: Stack(clipBehavior: Clip.none, children: [
                    for (var s = 0; s < _model.slots.length; s++) _slot(s, bs, bs * 0.9),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: W,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFFFF6E2), borderRadius: BorderRadius.circular(24), border: Border.all(color: m1Line, width: 3)),
            child: Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
              for (var i = 0; i < _tray.length; i++)
                if (!_filled.containsValue(i))
                  Draggable<int>(
                    data: i,
                    feedback: Material(type: MaterialType.transparency, child: _tray[i].view(cell * 1.2)),
                    childWhenDragging: SizedBox(width: cell, height: cell),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selected = _selected == i ? null : i);
                        m1Sound(context, 'toggleButton');
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: cell,
                        height: cell,
                        decoration: BoxDecoration(
                          color: _selected == i ? const Color(0xFFDDF2FF) : Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _selected == i ? const Color(0xFF39B8F2) : const Color(0xFFEFE3CB), width: _selected == i ? 3 : 1.5),
                        ),
                        alignment: Alignment.center,
                        child: _tray[i].view(cell * 0.8),
                      ),
                    ),
                  ),
            ]),
          ),
          const SizedBox(height: 4),
        ]);
      });

  Widget _slot(int s, double bw, double bh) {
    final (kind, r) = _model.slots[s];
    final rect = Rect.fromLTWH(r.left * bw, r.top * bh, r.width * bw, r.height * bh);
    final filled = _filled[s];
    return Positioned.fromRect(
      rect: rect,
      child: DragTarget<int>(
        onWillAcceptWithDetails: (_) => filled == null,
        onAcceptWithDetails: (d) => _fill(s, d.data),
        builder: (_, cand, __) => GestureDetector(
          onTap: _selected == null || filled != null ? null : () => _fill(s, _selected!),
          child: filled != null
              ? TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.elasticOut,
                  builder: (_, v, ch) => Transform.scale(scale: v, child: ch),
                  child: Image.asset(m1(_tray[filled].sprite), fit: BoxFit.fill),
                )
              : CustomPaint(painter: _Outline(kind, lit: cand.isNotEmpty || (_selected != null && _tray[_selected!].kind == kind))),
        ),
      ),
    );
  }

  Widget _sequence() => LayoutBuilder(builder: (_, c) {
        final W = c.maxWidth, H = c.maxHeight;
        final n = _seq.length + 1;
        final cell = min((W - 24) / n, H * 0.2);
        final opt = min((W - 40) / 3, H * 0.24);
        return Column(children: [
          M1SayPill(text: instruction, width: W, height: 48),
          const Spacer(),
          M1Card(
            radius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < _seq.length; i++)
                  M1PopIn(
                    key: ValueKey('s$round-$i'),
                    delay: 90 * i,
                    child: SizedBox(width: cell, height: cell, child: Center(child: _seq[i].view(cell * 0.82))),
                  ),
                SizedBox(
                  width: cell,
                  height: cell,
                  child: _seqDone
                      ? M1PopIn(child: Center(child: _missing!.view(cell * 0.82)))
                      : AnimatedBuilder(
                          animation: pulse,
                          builder: (_, ch) => Transform.scale(scale: 1 + 0.06 * sin(pulse.value * 2 * pi * 3), child: ch),
                          child: CustomPaint(painter: _Outline(_missing!.kind == M1Kind.circle ? M1Kind.circle : M1Kind.circle, lit: true)),
                        ),
                ),
              ]),
            ),
          ),
          const Spacer(),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var k = 0; k < _seqOptions.length; k++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: M1PopIn(
                  delay: 120 * k,
                  key: ValueKey('o$round-$k'),
                  child: M1Shake(
                    trigger: k == _seqShake ? _seqShakeN : 0,
                    child: M1Press(
                      onTap: busy ? null : () => _pickSeq(k),
                      sound: '',
                      child: M1Tile(width: opt, height: opt, child: _seqOptions[k].view(opt * 0.62)),
                    ),
                  ),
                ),
              ),
          ]),
          const Spacer(),
        ]);
      });
}
