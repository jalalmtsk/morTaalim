import 'dart:math';

import 'package:flutter/material.dart';

import 'm1_kit.dart';
import 'm1_shell.dart';
import 'm1_text.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Les additions magiques — avec des objets · sur une ligne · petits problèmes
// ═══════════════════════════════════════════════════════════════════════════

class M1AddPlay extends M1Play {
  const M1AddPlay({super.key, required super.lv});
  @override
  State<M1AddPlay> createState() => _AddState();
}

class _AddState extends M1PlayState<M1AddPlay> {
  String get _mode => lv.modeId;
  int _a = 0, _b = 0;
  List<int> _options = [];
  int? _hint;
  // objects: which cubes were moved to the tray (0..a-1 blue, a..a+b-1 orange), in order
  final List<int> _tray = [];
  // line: hops made from a
  int _hops = 0;
  int _shakeLine = 0;
  // problems
  int _story = 0;
  String _itemA = 'apple2', _itemB = 'apple2';

  int get _sum => _a + _b;

  @override
  String get instruction => switch (_mode) {
        'objects' => m1T(context, _tray.length < _sum ? 'ad_objects' : 'ad_howmany'),
        'line' => m1T(context, _hops < _b ? 'ad_line' : 'ad_howmany_line', {'a': _a, 'b': _b}),
        _ => m1T(context, 'ad_story$_story', {'a': _a, 'b': _b}),
      };

  @override
  void newRound() {
    _tray.clear();
    _piled.clear();
    _hops = 0;
    _hint = null;
    final top = lv.top;
    final minSum = lv.range == 0 ? 2 : (lv.range == 1 ? 5 : 10);
    final s = minSum + rng.nextInt(top - minSum + 1);
    _a = 1 + rng.nextInt(s - 1);
    _b = s - _a;
    if (_mode == 'objects' && lv.range == 2) {
      // keep the two groups at 10 cubes max each
      _a = min(_a, 10);
      _b = min(s - _a, 10);
    }
    _options = m1Choices(_sum, rng, min0: 1, max0: top + 2);
    if (_mode == 'problems') {
      _story = rng.nextInt(4);
      const pairs = [('apple2', 'pear'), ('cube_red', 'cube_blue2'), ('gem_p', 'gem_b'), ('pear', 'orange')];
      _itemA = pairs[_story].$1;
      _itemB = pairs[_story].$2;
    }
  }

  bool _pick(int v) {
    if (busy) return false;
    if (v == _sum) {
      good(text: '$_a + $_b = $_sum ! ${praise()}');
      return true;
    }
    bad('$_a + $_b = $_sum', help: m1T(context, _mode == 'line' ? 'ad_help_line' : 'ad_help', {'a': _a, 'b': _b}));
    return false;
  }

  void _tapCube(int i) {
    if (busy || _tray.contains(i)) return;
    setState(() => _tray.add(i));
    m1Sound(context, 'PopButton');
    M1Voice.say(context, '${_tray.length}');
    if (_tray.length == _sum) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) say(m1T(context, 'ad_howmany'));
      });
    }
  }

  void _gatherAll() {
    if (busy) return;
    setState(() {
      for (var i = 0; i < _sum; i++) {
        if (!_tray.contains(i)) _tray.add(i);
      }
    });
    m1Sound(context, 'PopButton');
    say(m1T(context, 'ad_howmany'));
  }

  void _tapChip(int v) {
    if (busy || _hops >= _b) return;
    if (v == _a + _hops + 1) {
      setState(() => _hops++);
      m1Sound(context, 'PopButton');
      M1Voice.say(context, '$v');
      if (_hops == _b) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) say(m1T(context, 'ad_howmany_line', {'a': _a, 'b': _b}));
        });
      }
    } else {
      setState(() => _shakeLine++);
      m1Sfx(context, 'Invalid_SFX.mp3');
      say(m1T(context, 'ad_hop_one'));
    }
  }

  // ── guided help ──
  String _cw = ''; // what is being counted: groups · tray · line · piles
  final GlobalKey _srcKey = GlobalKey(), _trayKey = GlobalKey();
  final List<int> _piled = []; // problems: objects the child counted

  /// The child has done the job: now the answers can appear.
  bool get _ready => switch (_mode) {
        'objects' => _tray.length >= _sum,
        'line' => _hops >= _b,
        _ => _piled.length >= _sum,
      };

  int get _nextPile {
    for (var i = 0; i < _sum; i++) {
      if (!_piled.contains(i)) return i;
    }
    return -1;
  }

  void _tapPile(int i) {
    if (busy || _piled.contains(i)) return;
    setState(() => _piled.add(i));
    m1Sound(context, 'PopButton');
    M1Voice.say(context, '${_piled.length}');
    if (_piled.length == _sum) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) say(m1T(context, 'ad_now_choose'));
      });
    }
  }

  int get _nextCube {
    for (var i = 0; i < _sum; i++) {
      if (!_tray.contains(i)) return i;
    }
    return -1;
  }

  Future<void> _count(String where, int n, {int from = 1, bool demo = false, String Function(int k)? word, int ms = 650}) async {
    setState(() => _cw = where);
    await countAlong(n, from: from, demo: demo, word: word, ms: ms);
    if (mounted && countIdx == null) setState(() => _cw = '');
  }

  @override
  void idleHelp() {
    switch (_mode) {
      case 'objects':
        if (_tray.length < _sum) {
          say(m1T(context, 'ad_tap_cubes'));
          final blue = _nextCube < _a;
          showDrag(_srcKey, _trayKey, blue ? 'cube_blue' : 'cube_orange', size: 48);
        } else if (helpLevel == 1) {
          say(m1T(context, 'ad_count_with_me'));
          _count('tray', _sum, demo: true);
        } else {
          setState(() => _hint = _sum);
          say(m1T(context, 'ad_help', {'a': _a, 'b': _b}));
        }
      case 'line':
        if (_hops < _b) {
          say(m1T(context, 'ad_hop_one'));
        } else {
          setState(() => _hint = _sum);
          say(m1T(context, 'ad_land', {'n': _a + _b}));
        }
      default:
        if (_piled.length < _sum) {
          say(m1T(context, 'ad_tap_to_count'));
          showTap(_srcKey);
        } else if (helpLevel == 1) {
          say(m1T(context, 'ad_count_with_me'));
          _count('piles', _sum, demo: true);
        } else {
          setState(() => _hint = _sum);
          say(m1T(context, 'ad_help', {'a': _a, 'b': _b}));
        }
    }
  }

  @override
  Future<void> explain() async {
    switch (_mode) {
      case 'objects':
        if (_tray.length < _sum) {
          setState(() {
            for (var i = 0; i < _sum; i++) {
              if (!_tray.contains(i)) _tray.add(i);
            }
          });
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;
        }
        await _count('tray', _sum, ms: 550);
      case 'line':
        setState(() => _hops = _b);
        M1Voice.say(context, '$_a');
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        await _count('line', _b, from: _a + 1);
      default:
        await _count('piles', _sum, ms: 550);
    }
    if (!mounted) return;
    setState(() => _cw = '');
    M1Voice.say(context, m1T(context, 'ad_says', {'a': _a, 'b': _b, 's': _sum}));
    await Future.delayed(const Duration(milliseconds: 1500));
  }

  @override
  void hint() {
    mistakes++;
    switch (_mode) {
      case 'objects':
        if (_tray.length < _sum) {
          _gatherAll();
        } else {
          setState(() => _hint = _sum);
          say(m1T(context, 'ad_help', {'a': _a, 'b': _b}));
        }
      case 'line':
        if (_hops < _b) {
          say(m1T(context, 'ad_hop_one'));
        } else {
          setState(() => _hint = _sum);
        }
      default:
        say(m1T(context, 'ad_help', {'a': _a, 'b': _b}));
        setState(() => _hint = _sum);
    }
  }

  @override
  Widget board(BuildContext context, double w, double h) {
    final topH = min(h * 0.26, 128.0);
    return Column(children: [
      SizedBox(
        height: topH,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(left: 0, bottom: -6, child: M1Float(amp: 3, child: Image.asset(m1('kid_fists'), height: topH * 0.98))),
          Positioned(right: 0, bottom: -6, child: M1Float(amp: 4, phase: 0.4, child: Image.asset(m1('robot_point_l'), height: topH * 0.98))),
          Positioned(left: w * 0.3, right: w * 0.26, top: 0, child: Center(child: M1Bubble(text: robotSay, width: min(w * 0.46, 190.0), tailRight: true))),
        ]),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: M1GoldBoard(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: LayoutBuilder(builder: (_, c) {
              final bw = c.maxWidth, bh = c.maxHeight;
              final choiceH = min(bh * 0.2, 84.0);
              return Stack(children: [
                Column(children: [
                  M1SayPill(text: instruction, width: bw, height: 46),
                  SizedBox(height: bh * 0.02),
                  Expanded(
                    child: switch (_mode) {
                      'objects' => _objects(bw),
                      'line' => _line(bw),
                      _ => _problem(bw),
                    },
                  ),
                  _equation(bh * 0.13),
                  SizedBox(height: bh * 0.02),
                  // the answers appear only once the child has done the job
                  _ready
                      ? M1PopIn(
                          key: ValueKey('ready$round'),
                          child: M1ChoiceRow(
                            key: ValueKey('c$round'),
                            options: _options,
                            onPick: _pick,
                            width: bw,
                            height: choiceH,
                            enabled: !busy,
                            hintValue: _hint,
                            hintHand: showHand,
                          ),
                        )
                      : M1WaitPill(text: m1T(context, 'ad_wait_$_mode'), width: bw, height: choiceH),
                ]),
                Positioned.fill(child: burstLayer()),
              ]);
            }),
          ),
        ),
      ),
    ]);
  }

  Widget _equation(double hgt) {
    final done = busy;
    return SizedBox(
      height: hgt.clamp(40.0, 66.0),
      child: FittedBox(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            m1Number(_a, 56, color: m1Blue),
            const SizedBox(width: 6),
            Image.asset(m1('plus'), width: 40),
            const SizedBox(width: 6),
            m1Number(_b, 56, color: m1Orange),
            const SizedBox(width: 6),
            Image.asset(m1('equals'), width: 40),
            const SizedBox(width: 8),
            Container(
              width: 70,
              height: 66,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done ? const Color(0xFFE9FBE2) : m1Cream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: done ? m1Green : m1Line, width: 3),
                boxShadow: [BoxShadow(color: const Color(0xFFC49A52).withOpacity(0.4), offset: const Offset(0, 4))],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: c),
                child: done ? m1Number(_sum, 46, key: const ValueKey('s')) : AnimatedBuilder(
                    key: const ValueKey('q'),
                    animation: pulse,
                    builder: (_, c) => Transform.scale(scale: 1 + 0.08 * sin(pulse.value * 2 * pi * 3), child: c),
                    child: m1Outlined('?', 46, color: m1Purple)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── with objects: two groups of cubes, tap them into the tray ──
  Widget _objects(double bw) => LayoutBuilder(builder: (_, c) {
        final H = c.maxHeight;
        final groupH = H * 0.5;
        final perRow = (int n) => n <= 5 ? n : 5;
        double cubeFor(int n, double gw) {
          final rows = (n / 5).ceil();
          return min((gw - 16) / perRow(n), (groupH - 16) / rows) * 0.95;
        }

        final gwA = (bw - 44) * (_a / (_a + _b)).clamp(0.35, 0.65);
        final gwB = bw - 44 - gwA;
        final cs = min(cubeFor(_a, gwA), cubeFor(_b, gwB)).clamp(14.0, 58.0);
        Widget group(int from, int n, bool blue, double gw) => Container(
              width: gw,
              height: groupH,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: blue ? const Color(0xFFDDF0FF) : const Color(0xFFFFEBD6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: blue ? const Color(0xFF59AEF5) : const Color(0xFFF7A24E), width: 3.5),
                boxShadow: [BoxShadow(color: (blue ? const Color(0xFF59AEF5) : const Color(0xFFF7A24E)).withOpacity(0.35), blurRadius: 10)],
              ),
              child: Center(
                child: Wrap(alignment: WrapAlignment.center, runAlignment: WrapAlignment.center, spacing: 1, runSpacing: 1, children: [
                  for (var i = from; i < from + n; i++)
                    Draggable<int>(
                      key: i == _nextCube ? _srcKey : null,
                      data: i,
                      maxSimultaneousDrags: _tray.contains(i) || busy ? 0 : 1,
                      feedback: Material(type: MaterialType.transparency, child: Image.asset(m1(blue ? 'cube_blue' : 'cube_orange'), width: cs * 1.25, height: cs * 1.25)),
                      childWhenDragging: SizedBox(width: cs, height: cs),
                      child: GestureDetector(
                      onTap: () => _tapCube(i),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: _tray.contains(i) ? 0.12 : 1,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 250),
                          scale: _tray.contains(i) ? 0.6 : 1,
                          child: M1Spot(
                            on: _cw == 'groups' && countIdx == i,
                            badge: '${i + 1}',
                            hand: (_cw == 'groups' && countIdx == i) || (showHand && helpLevel == 1 && i == _nextCube),
                            size: cs,
                            child: Image.asset(m1(blue ? 'cube_blue' : 'cube_orange'), width: cs, height: cs),
                          ),
                        ),
                      ),
                    ),
                    ),
                ]),
              ),
            );
        final slots = _sum;
        final slotS = min((bw - 30) / min(slots, 10), (H * 0.4 - 14) / ((slots / 10).ceil())) * 0.92;
        return Column(children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              group(0, _a, true, gwA),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: M1Float(amp: 2, child: Image.asset(m1('plus'), width: 32))),
              group(_a, _b, false, gwB),
            ]),
          ),
          const Spacer(),
          // the dashed tray where both groups come together
          DragTarget<int>(
            key: _trayKey,
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (d) => _tapCube(d.data),
            builder: (_, cand, __) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: bw,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cand.isNotEmpty ? const Color(0xFFE3F4FF) : const Color(0xFFFFF9EC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cand.isNotEmpty ? const Color(0xFF39B8F2) : m1Line, width: 3),
              ),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Wrap(alignment: WrapAlignment.center, spacing: 2, runSpacing: 2, children: [
                  for (var k = 0; k < slots; k++)
                    SizedBox(
                      width: slotS,
                      height: slotS,
                      child: k < _tray.length
                          ? TweenAnimationBuilder<double>(
                              key: ValueKey('t${_tray[k]}'),
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.elasticOut,
                              builder: (_, v, ch) => Transform.scale(scale: v, child: ch),
                              child: M1Spot(
                                on: _cw == 'tray' && countIdx == k,
                                badge: '${k + 1}',
                                hand: _cw == 'tray' && countIdx == k,
                                size: slotS,
                                child: Image.asset(m1(_tray[k] < _a ? 'cube_blue' : 'cube_orange')),
                              ),
                            )
                          : CustomPaint(painter: _DashedBox()),
                    ),
                ]),
              ),
            ),
          ),
        ]);
      });

  // ── on a number line: hop b times from a ──
  Widget _line(double bw) => LayoutBuilder(builder: (_, c) {
        final top = lv.top;
        final n = top + 1;
        final cw = min(40.0, (bw - 8) / n);
        final rows = cw < 22 ? 2 : 1; // long lines wrap on two rows
        final perRow = (n / rows).ceil();
        final cw2 = min(40.0, (bw - 8) / perRow);
        final now = _a + _hops;
        Widget chip(int v) {
          final passed = v > _a && v <= now;
          final isA = v == _a, isNow = v == now;
          final next = v == now + 1 && _hops < _b;
          final hopping = _cw == 'line' && countIdx != null && v == _a + 1 + countIdx!;
          return M1Spot(
            on: hopping,
            badge: hopping ? '+${countIdx! + 1}' : null,
            hand: hopping || (showHand && next),
            size: cw2,
            child: GestureDetector(
            onTap: () => _tapChip(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: cw2 - 3,
              height: cw2 - 3,
              margin: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isA ? const Color(0xFFBFE3FF) : (passed ? const Color(0xFFFFD9B0) : m1Cream),
                border: Border.all(
                  color: isNow ? m1Purple : (next ? const Color(0xFF39B8F2) : (isA ? m1Blue : const Color(0xFFD9C9A6))),
                  width: isNow || next ? 3 : 2,
                ),
                boxShadow: [if (next) BoxShadow(color: const Color(0xFF39B8F2).withOpacity(0.6), blurRadius: 8)],
              ),
              alignment: Alignment.center,
              child: FittedBox(child: Padding(padding: const EdgeInsets.all(3), child: Text('$v', style: m1Text(16, color: isA ? m1Blue : (passed ? m1Orange : m1Ink))))),
            ),
          ),
          );
        }

        final rowsW = <Widget>[];
        for (var r = 0; r < rows; r++) {
          final from = r * perRow, to = min(n - 1, from + perRow - 1);
          rowsW.add(Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (var v = from; v <= to; v++) chip(v)]));
        }
        return Column(children: [
          SizedBox(
            height: c.maxHeight * 0.32,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var k = 0; k < _b; k++)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: k < _hops ? 1 : 0.25,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.redo_rounded, color: m1Orange, size: min(30.0, (bw - 20) / max(1, _b) * 0.8)),
                        Text('+1', style: m1Text(12, color: m1Orange)),
                      ]),
                    ),
                  ),
              ]),
            ),
          ),
          const Spacer(),
          M1Shake(trigger: _shakeLine, child: Directionality(textDirection: TextDirection.ltr, child: Column(children: rowsW))),
          const Spacer(),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(m1('robot_plus'), height: min(c.maxHeight * 0.3, 70.0)),
            const SizedBox(width: 8),
            Text(m1T(context, 'ad_hops', {'n': _hops, 'b': _b}), style: m1Text(16, color: m1InkSoft)),
          ]),
        ]);
      });

  // ── small story problems ──
  Widget _problem(double bw) => LayoutBuilder(builder: (_, c) {
        final H = c.maxHeight;
        Widget pile(int n, String item, Color tint, int offset) {
          final per = n <= 5 ? n : 5;
          final rows = (n / 5).ceil();
          final s = min((bw * 0.4) / per, (H * 0.7) / rows) * 0.92;
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: tint.withOpacity(0.12), borderRadius: BorderRadius.circular(18), border: Border.all(color: tint.withOpacity(0.6), width: 2.5)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                width: s * per + 4,
                child: Wrap(alignment: WrapAlignment.center, children: [
                  for (var i = 0; i < n; i++)
                    M1PopIn(
                      delay: 60 * i,
                      child: GestureDetector(
                        key: offset + i == _nextPile ? _srcKey : null,
                        onTap: () => _tapPile(offset + i),
                        child: M1Spot(
                          on: (_cw == 'piles' && countIdx == offset + i),
                          badge: '${offset + i + 1}',
                          hand: _cw == 'piles' && countIdx == offset + i,
                          size: s,
                          child: Stack(alignment: Alignment.center, children: [
                            Image.asset(m1(item), width: s, height: s),
                            if (_piled.contains(offset + i))
                              M1PopIn(
                                from: 0.3,
                                child: Container(
                                  width: s * 0.5,
                                  height: s * 0.5,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: m1Green, width: 2)),
                                  child: FittedBox(child: Padding(padding: const EdgeInsets.all(2), child: Text('${_piled.indexOf(offset + i) + 1}', style: m1Text(14, color: m1Green)))),
                                ),
                              ),
                          ]),
                        ),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 2),
              m1Number(n, 26, color: tint),
            ]),
          );
        }

        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              pile(_a, _itemA, m1Red, 0),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Image.asset(m1('plus'), width: 34)),
              pile(_b, _itemB, m1Blue, _a),
            ]),
          ),
          ),
        );
      });
}

class _DashedBox extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFB6A88E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(3, 3, size.width - 6, size.height - 6), Radius.circular(size.width * 0.15));
    final path = Path()..addRRect(r);
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 7) {
        canvas.drawPath(m.extractPath(d, d + 4), p);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBox o) => false;
}
