import 'dart:math';

import 'package:flutter/material.dart';

import 'm1_kit.dart';
import 'm1_shell.dart';
import 'm1_text.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Le train des nombres — reconnaître · compter · mettre en ordre
// ═══════════════════════════════════════════════════════════════════════════

const _wagons = ['wagon_r', 'wagon_y', 'wagon_g', 'wagon_p'];

class M1TrainPlay extends M1Play {
  const M1TrainPlay({super.key, required super.lv});
  @override
  State<M1TrainPlay> createState() => _TrainState();
}

class _TrainState extends M1PlayState<M1TrainPlay> {
  late final AnimationController _drive = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  late final AnimationController _puff = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  bool _leaving = false;

  // challenge
  List<int?> _cars = []; // numbers on the wagons (null = missing wagon)
  int _answer = 0;
  List<int> _options = [];
  int _apples = 0; // count mode
  final Set<int> _tapped = {}; // apples already counted
  int _wrongCar = -1, _shakeCar = 0;
  int? _hintValue;
  bool _filled = false; // order: missing wagon got its number
  int _step = 1;

  String get _mode => lv.modeId;

  @override
  void dispose() {
    _drive.dispose();
    _puff.dispose();
    super.dispose();
  }

  @override
  String get instruction => switch (_mode) {
        'recognize' => m1T(context, 'tr_find', {'n': _answer}),
        'count' => m1T(context, 'tr_count'),
        _ => m1T(context, 'tr_missing'),
      };

  @override
  void newRound() {
    _hintValue = null;
    _tapped.clear();
    _filled = false;
    _leaving = false;
    final top = lv.top;
    switch (_mode) {
      case 'recognize':
        final pool = <int>{};
        final lo = lv.range == 0 ? 0 : (lv.range == 1 ? 5 : 10);
        while (pool.length < 4) {
          pool.add(lo + rng.nextInt(top - lo + 1));
        }
        _cars = pool.toList()..shuffle(rng);
        _answer = _cars[rng.nextInt(4)]!;
      case 'count':
        final lo = lv.range == 0 ? 2 : (lv.range == 1 ? 8 : 12);
        final hi = lv.range == 0 ? 10 : (lv.range == 1 ? 16 : 20);
        _apples = lo + rng.nextInt(hi - lo + 1);
        _answer = _apples;
        _cars = [null, null, null, null];
        _options = m1Choices(_answer, rng, max0: hi + 2, min0: 1);
      default:
        final step = (lv.range == 2 && rng.nextBool()) ? 10 : 1;
        _step = step;
        final len = 5;
        final maxStart = top - step * (len - 1);
        final start = step == 10 ? 10 * rng.nextInt(max(1, maxStart ~/ 10) + 1) : rng.nextInt(max(1, maxStart + 1));
        final seq = [for (var i = 0; i < len; i++) start + i * step];
        final miss = 1 + rng.nextInt(len - 1);
        _answer = seq[miss];
        _cars = [for (var i = 0; i < len; i++) i == miss ? null : seq[i]];
        final opts = <int>{_answer};
        for (final d in [step, -step, 2 * step, -2 * step, 1, -1]) {
          if (opts.length >= 3) break;
          final v = _answer + d;
          if (v >= 0 && v <= top && !seq.contains(v)) opts.add(v);
        }
        while (opts.length < 3) {
          opts.add(_answer + opts.length * 3);
        }
        _options = opts.toList()..shuffle(rng);
    }
    _drive.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) m1Sfx(context, 'PowerUp_SFX.mp3');
    });
  }

  Future<void> _leave() async {
    setState(() => _leaving = true);
    await _drive.reverse(from: 1);
  }

  Future<void> _win() async {
    m1Sfx(context, 'CorrectAnwser_SFX.mp3');
    burst.forward(from: 0);
    busy = true;
    say(praise());
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await _leave();
    if (!mounted) return;
    nextRound();
  }

  void _tapCar(int i) {
    if (busy || _mode != 'recognize') return;
    if (_cars[i] == _answer) {
      setState(() => _wrongCar = -1);
      _win();
    } else {
      setState(() {
        _wrongCar = i;
        _shakeCar++;
      });
      bad(m1T(context, 'tr_rev_find', {'n': _answer}), help: m1T(context, 'tr_not', {'n': _cars[i]!, 'm': _answer}));
    }
  }

  bool _pick(int v) {
    if (busy) return false;
    if (v == _answer) {
      setState(() => _filled = true);
      _win();
      return true;
    }
    if (_mode == 'count') {
      bad(m1T(context, 'tr_rev_count'), help: m1T(context, 'tr_count_help'));
    } else {
      final i = _cars.indexOf(null);
      final before = i > 0 ? _cars[i - 1] : null;
      bad(before == null ? m1T(context, 'tr_rev_order0') : m1T(context, 'tr_rev_order', {'n': before}), help: m1T(context, 'tr_order_help'));
    }
    return false;
  }

  void _tapApple(int i) {
    if (_tapped.contains(i) || busy) return;
    setState(() => _tapped.add(i));
    m1Sound(context, 'PopButton');
    M1Voice.say(context, '${_tapped.length}');
    if (_tapped.length == _apples) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) say(m1T(context, 'tr_now_choose', {'n': _apples}));
      });
    }
  }

  // ── guided help ──
  final GlobalKey _appleKey = GlobalKey();

  int get _nextApple {
    for (var k = 0; k < _apples; k++) {
      if (!_tapped.contains(k)) return k;
    }
    return -1;
  }

  @override
  void idleHelp() {
    switch (_mode) {
      case 'recognize':
        if (helpLevel == 1) {
          say(m1T(context, 'tr_find_hint', {'n': _answer}));
          // the finger reads the wagons one after the other
          countAlong(_cars.length, word: (k) => '${_cars[k]}', ms: 900, demo: true);
        } else {
          say(m1T(context, 'tr_look_here', {'n': _answer}));
        }
      case 'count':
        if (_tapped.length < _apples) {
          say(m1T(context, 'tr_tap_apples'));
          showTap(_appleKey);
        } else if (helpLevel == 1) {
          say(m1T(context, 'tr_count_with_me'));
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted && showHand) countAlong(_apples, demo: true);
          });
        } else {
          setState(() => _hintValue = _answer);
          say(m1T(context, 'tr_count_help'));
        }
      default:
        final miss = _cars.indexOf(null);
        if (helpLevel == 1) {
          say(m1T(context, 'tr_order_help'));
          countAlong(miss + 1, word: (k) => k == miss ? '…' : '${_cars[k]}', ms: 900, demo: true);
        } else {
          setState(() => _hintValue = _answer);
          say(m1T(context, 'tr_look_here', {'n': _answer}));
        }
    }
  }

  /// After a right answer: count / read it again, with the finger.
  @override
  Future<void> explain() async {
    switch (_mode) {
      case 'count':
        await countAlong(_apples);
        M1Voice.say(context, m1T(context, 'tr_there_are', {'n': _apples}));
        await Future.delayed(const Duration(milliseconds: 900));
      case 'order':
        await countAlong(_cars.length, word: (k) => '${_cars[k] ?? _answer}', ms: 700);
      default:
        setState(() => countIdx = _cars.indexOf(_answer));
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) setState(() => countIdx = null);
    }
  }

  @override
  void hint() {
    switch (_mode) {
      case 'recognize':
        say(m1T(context, 'tr_find_hint', {'n': _answer}));
      case 'count':
        say(m1T(context, 'tr_count_help'));
        setState(() => _hintValue = _tapped.length == _apples ? _answer : null);
      default:
        say(m1T(context, 'tr_order_help'));
        setState(() => _hintValue = _answer);
    }
    mistakes++; // a hint costs a little
  }

  @override
  Widget board(BuildContext context, double w, double h) {
    final robotH = min(h * 0.24, 118.0);
    final showLine = _mode != 'recognize';
    final choicesH = _mode == 'recognize' ? 0.0 : min(h * 0.17, 92.0);
    final lineH = showLine ? 52.0 : 0.0;
    final trainH = (h - robotH - choicesH - lineH - 70).clamp(110.0, 230.0);
    return Column(children: [
      SizedBox(height: robotH, child: robotLine(w, robotH, sprite: 'conductor_point', right: true, robotH: robotH)),
      SizedBox(height: trainH, child: _trainArea(w, trainH)),
      const SizedBox(height: 6),
      M1SayPill(text: instruction, width: min(w - 30, 360.0), height: 50),
      const Spacer(),
      if (_mode == 'count' && _tapped.length < _apples)
        M1WaitPill(text: m1T(context, 'tr_wait_count'), width: min(w - 40, 340.0), height: choicesH)
      else if (_mode != 'recognize')
        M1PopIn(
          key: ValueKey('ready$round'),
          child: M1ChoiceRow(key: ValueKey('c$round'), options: _options, onPick: _pick, width: min(w - 40, 340.0), height: choicesH, enabled: !busy, hintValue: _hintValue, hintHand: showHand),
        ),
      if (showLine) ...[const SizedBox(height: 8), _line(w)],
      const SizedBox(height: 4),
    ]);
  }

  Widget _line(double w) {
    if (_mode == 'count') {
      final top = _apples > 10 ? 20 : 10;
      return M1NumberLine(from: top == 20 ? 10 : 0, to: top, marked: {for (var i = 1; i <= _tapped.length; i++) i}, glow: _hintValue, width: min(w - 20, 370.0));
    }
    final known = _cars.whereType<int>().toList();
    if (_step == 10) {
      return M1NumberLine(from: 0, to: 100, step: 10, marked: {...known, if (_filled) _answer}, glow: _hintValue, width: min(w - 20, 370.0));
    }
    int lo = _answer - 5;
    if (lo > lv.top - 10) lo = lv.top - 10;
    if (lo < 0) lo = 0;
    return M1NumberLine(from: lo, to: lo + 10, marked: {...known, if (_filled) _answer}, glow: _hintValue, width: min(w - 20, 370.0));
  }

  Widget _trainArea(double w, double h) {
    final cars = _cars.length;
    final avail = w - 16;
    // wagon height = h*0.5, engine height = h*0.9; widths from the sprite ratios
    var wagonH = h * 0.5;
    var engineH = wagonH * 1.8;
    double width() => engineH / m1Ratio('engine') + cars * (wagonH / m1Ratio('wagon_r') - 2);
    if (width() > avail) {
      final k = avail / width();
      wagonH *= k;
      engineH *= k;
    }
    final wagonW = wagonH / m1Ratio('wagon_r');
    final engineW = engineH / m1Ratio('engine');
    final railY = h - 10;
    return AnimatedBuilder(
      animation: Listenable.merge([_drive, _puff]),
      builder: (_, __) {
        final t = Curves.easeOutCubic.transform(_drive.value);
        final dx = _leaving ? -(1 - _drive.value) * (w + 40) * 1.0 : (1 - t) * (w + 40);
        final bob = _drive.isAnimating ? sin(_puff.value * 2 * pi * 6) * 1.5 : sin(_puff.value * 2 * pi) * 0.8;
        return Stack(clipBehavior: Clip.none, children: [
          // rails
          Positioned(left: -10, right: -10, top: railY - 14, height: 22, child: const CustomPaint(painter: _RailsPainter())),
          Positioned(
            left: (w - (engineW + cars * (wagonW - 2))) / 2 + dx,
            top: 0,
            bottom: 10,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                // engine with smoke
                SizedBox(
                  width: engineW,
                  height: engineH,
                  child: Stack(clipBehavior: Clip.none, children: [
                    Positioned(
                      left: engineW * 0.25,
                      top: -engineH * 0.5,
                      width: engineW * 0.6,
                      height: engineH * 0.6,
                      child: IgnorePointer(child: CustomPaint(painter: _SmokePainter(_puff.value, _drive.isAnimating))),
                    ),
                    Positioned.fill(child: Transform.translate(offset: Offset(0, bob), child: Image.asset(m1('engine'), fit: BoxFit.contain))),
                  ]),
                ),
                for (var i = 0; i < cars; i++)
                  Transform.translate(
                    offset: Offset(-2.0 * (i + 1), sin(_puff.value * 2 * pi + i) * (_drive.isAnimating ? 1.5 : 0.6)),
                    child: _car(i, wagonW, wagonH),
                  ),
              ]),
            ),
          ),
          Positioned.fill(child: burstLayer()),
        ]);
      },
    );
  }

  Widget _car(int i, double ww, double wh) {
    final v = _cars[i];
    final missing = _mode == 'order' && v == null;
    if (_mode == 'count') return _appleCar(i, ww, wh);
    final sprite = missing && !_filled ? 'wagon_dash' : _wagons[i % _wagons.length];
    final face = missing && !_filled ? const EdgeInsets.fromLTRB(0.26, 0.2, 0.26, 0.42) : const EdgeInsets.fromLTRB(0.19, 0.2, 0.19, 0.36);
    final shown = missing ? (_filled ? _answer : null) : v;
    Widget car = SizedBox(
      width: ww,
      height: wh,
      child: Stack(children: [
        Positioned.fill(
          child: missing && !_filled
              ? Padding(padding: EdgeInsets.fromLTRB(0, wh * 0.06, 0, wh * 0.02), child: AnimatedBuilder(
                  animation: pulse,
                  builder: (_, c) => Opacity(opacity: 0.65 + 0.35 * sin(pulse.value * 2 * pi * 3).abs(), child: c),
                  child: Image.asset(m1(sprite), fit: BoxFit.fill),
                ))
              : Image.asset(m1(sprite), fit: BoxFit.fill),
        ),
        Positioned(
          left: ww * face.left,
          right: ww * face.right,
          top: wh * face.top,
          bottom: wh * face.bottom,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: c),
              child: FittedBox(
                key: ValueKey('$i-$shown'),
                child: shown == null
                    ? m1Outlined('?', 40, color: const Color(0xFF39B8F2))
                    : m1Number(shown, 40),
              ),
            ),
          ),
        ),
      ]),
    );
    final target = _mode == 'recognize' ? v == _answer : missing;
    car = M1Spot(
      on: countIdx == i,
      hand: countIdx == i || (showHand && helpLevel >= 2 && target),
      size: wh * 0.8,
      child: car,
    );
    if (_mode == 'recognize') {
      car = M1Press(
        onTap: busy ? null : () => _tapCar(i),
        sound: '',
        child: M1Shake(trigger: i == _wrongCar ? _shakeCar : 0, child: car),
      );
    }
    return car;
  }

  /// Count mode: apples riding in the wagons; tap them to count.
  Widget _appleCar(int i, double ww, double wh) {
    final per = (_apples / 4).ceil();
    final start = i * per;
    final mine = [for (var k = start; k < min(_apples, start + per); k++) k];
    final cols = mine.length <= 2 ? mine.length : (mine.length <= 4 ? 2 : 3);
    final rows = cols == 0 ? 0 : (mine.length / cols).ceil();
    final a = min(ww * 0.8 / max(1, cols), wh * 0.75 / max(1, rows));
    return SizedBox(
      width: ww,
      height: wh + a * rows * 0.55,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(left: 0, right: 0, bottom: 0, height: wh, child: Image.asset(m1(_wagons[i % 4]), fit: BoxFit.fill)),
        Positioned(
          left: ww * 0.1,
          right: ww * 0.1,
          top: 0,
          bottom: wh * 0.35,
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.end,
            verticalDirection: VerticalDirection.up,
            children: [
              for (final k in mine)
                GestureDetector(
                  key: k == _nextApple ? _appleKey : null,
                  onTap: () => _tapApple(k),
                  child: M1Spot(
                    on: countIdx == k,
                    badge: '${k + 1}',
                    hand: countIdx == k,
                    size: a,
                    child: AnimatedScale(
                    scale: _tapped.contains(k) ? 1.12 : 1,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.elasticOut,
                    child: SizedBox(
                      width: a,
                      height: a,
                      child: Stack(alignment: Alignment.center, children: [
                        Image.asset(m1('apple2'), width: a * 0.95),
                        if (_tapped.contains(k))
                          Container(
                            width: a * 0.5,
                            height: a * 0.5,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), shape: BoxShape.circle, border: Border.all(color: m1Green, width: 2)),
                            child: FittedBox(child: Padding(padding: const EdgeInsets.all(2), child: Text('${_tapped.toList().indexOf(k) + 1}', style: m1Text(14, color: m1Green)))),
                          ),
                      ]),
                    ),
                  ),
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _RailsPainter extends CustomPainter {
  const _RailsPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final wood = Paint()..color = const Color(0xFF8B5A2B);
    final woodTop = Paint()..color = const Color(0xFFA9713A);
    for (var x = 0.0; x < size.width; x += 20) {
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height * 0.25, 13, size.height * 0.75), const Radius.circular(3));
      canvas.drawRRect(r, wood);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height * 0.25, 13, size.height * 0.3), const Radius.circular(3)), woodTop);
    }
    final steel = Paint()
      ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE6EBF2), Color(0xFF8E98A8)])
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, size.height * 0.12, size.width, 5), const Radius.circular(2)), steel);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, size.height * 0.62, size.width, 5), const Radius.circular(2)), steel);
  }

  @override
  bool shouldRepaint(_RailsPainter o) => false;
}

class _SmokePainter extends CustomPainter {
  final double t;
  final bool moving;
  _SmokePainter(this.t, this.moving);
  @override
  void paint(Canvas canvas, Size size) {
    final n = moving ? 5 : 3;
    for (var i = 0; i < n; i++) {
      final v = (t + i / n) % 1.0;
      final p = Offset(size.width * (0.35 + v * 0.5) + sin(v * 6 + i) * 4, size.height * (1 - v));
      final r = size.width * (0.08 + v * 0.18);
      canvas.drawCircle(p, r, Paint()..color = Colors.white.withOpacity((1 - v) * (moving ? 0.85 : 0.55)));
    }
  }

  @override
  bool shouldRepaint(_SmokePainter o) => o.t != t || o.moving != moving;
}
