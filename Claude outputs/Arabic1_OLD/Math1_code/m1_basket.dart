import 'dart:math';

import 'package:flutter/material.dart';

import 'm1_kit.dart';
import 'm1_shell.dart';
import 'm1_text.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Les paniers à compter — je compte · je remplis · je compare
// ═══════════════════════════════════════════════════════════════════════════

const _fruits = ['apple2', 'pear', 'orange'];

/// A wicker basket holding [count] fruits; the front weave is drawn again on
/// top so the fruits really sit inside it.
class M1Basket extends StatelessWidget {
  final int count;
  final String fruit;
  final double width;
  final Set<int> tapped; // counted fruits get a number badge
  final List<int>? order; // counting order of the tapped fruits
  final void Function(int i)? onTapFruit;
  final int dropFrom; // fruits from this index fall in with a bounce
  final int? spot; // fruit being counted right now (highlighted, with the finger)
  final int? nextIdx; // the fruit a demo hand will tap
  final GlobalKey? nextKey;
  const M1Basket({super.key, required this.count, required this.fruit, required this.width, this.tapped = const {}, this.order, this.onTapFruit, this.dropFrom = 1 << 30, this.spot, this.nextIdx, this.nextKey});

  @override
  Widget build(BuildContext context) {
    final h = width * m1Ratio('basket_empty');
    final cap = count <= 6 ? 3 : (count <= 12 ? 4 : 5); // fruits per row
    final rows = (count / cap).ceil();
    final f = width * 0.74 / cap * 1.12;
    final pos = <Offset>[];
    for (var i = 0; i < count; i++) {
      final r = i ~/ cap, c = i % cap;
      final inRow = min(cap, count - r * cap);
      final rowW = inRow * f * 0.9;
      final x = (width - rowW) / 2 + c * f * 0.9 + (r.isOdd ? f * 0.2 : 0);
      final y = h * 0.6 - f - r * f * (rows > 3 ? 0.42 : 0.55);
      pos.add(Offset(x, y));
    }
    return SizedBox(
      width: width,
      height: h,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(child: Image.asset(m1('basket_empty'), fit: BoxFit.fill)),
        // back rows first so the front ones overlap them
        for (var i = count - 1; i >= 0; i--)
          Positioned(
            left: pos[i].dx,
            top: pos[i].dy,
            width: f,
            height: f,
            child: M1Spot(
              key: i == nextIdx ? nextKey : null,
              on: spot == i,
              badge: '${i + 1}',
              size: f,
              child: _Fruit(
                key: ValueKey('f$i'),
                sprite: fruit,
                size: f,
                number: tapped.contains(i) ? ((order?.indexOf(i) ?? -1) + 1) : 0,
                drop: i >= dropFrom,
                onTap: onTapFruit == null ? null : () => onTapFruit!(i),
              ),
            ),
          ),
        Positioned.fill(child: IgnorePointer(child: ClipRect(clipper: const _Below(0.56), child: Image.asset(m1('basket_empty'), fit: BoxFit.fill)))),
        // the counting finger stays on top of the basket weave
        if (spot != null && spot! < count)
          Positioned(left: pos[spot!].dx + f * 0.55, top: pos[spot!].dy + f * 0.45, child: M1HintHand(size: max(30.0, f * 0.8))),
      ]),
    );
  }
}

class _Below extends CustomClipper<Rect> {
  final double f;
  const _Below(this.f);
  @override
  Rect getClip(Size size) => Rect.fromLTRB(-50, size.height * f, size.width + 50, size.height + 50);
  @override
  bool shouldReclip(_Below o) => o.f != f;
}

class _Fruit extends StatelessWidget {
  final String sprite;
  final double size;
  final int number;
  final bool drop;
  final VoidCallback? onTap;
  const _Fruit({super.key, required this.sprite, required this.size, this.number = 0, this.drop = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    Widget f = AnimatedScale(
      scale: number > 0 ? 1.1 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      child: Stack(alignment: Alignment.center, children: [
        Image.asset(m1(sprite), width: size, height: size, fit: BoxFit.contain),
        if (number > 0)
          M1PopIn(
            child: Container(
              width: size * 0.48,
              height: size * 0.48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: m1Green, width: 2.5)),
              child: FittedBox(child: Padding(padding: const EdgeInsets.all(2), child: Text('$number', style: m1Text(16, color: m1Green)))),
            ),
          ),
      ]),
    );
    if (drop) {
      f = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.bounceOut,
        builder: (_, v, c) => Transform.translate(offset: Offset(0, -size * 2.6 * (1 - v)), child: c),
        child: f,
      );
    }
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: f);
  }
}

class M1BasketPlay extends M1Play {
  const M1BasketPlay({super.key, required super.lv});
  @override
  State<M1BasketPlay> createState() => _BasketState();
}

class _BasketState extends M1PlayState<M1BasketPlay> {
  String get _mode => lv.modeId;
  int _n = 0; // count / target
  String _fruit = 'apple2';
  List<int> _options = [];
  final List<int> _order = [];
  int? _hint;
  // fill
  int _inBasket = 0;
  int _dropFrom = 0;
  int _shakeCheck = 0;
  // compare
  int _a = 0, _b = 0;
  String _fruitB = 'pear';
  bool _askMore = true;
  int _shakeA = 0, _shakeB = 0;
  int _chosen = -1;

  @override
  String get bg => 'basket';

  @override
  String get instruction => switch (_mode) {
        'count' => m1T(context, 'bk_count', {'f': m1T(context, 'fruit_$_fruit')}),
        'fill' => m1T(context, 'bk_fill', {'n': _n, 'f': m1T(context, 'fruit_$_fruit')}),
        _ => m1T(context, _askMore ? 'bk_more' : 'bk_less'),
      };

  @override
  void newRound() {
    _order.clear();
    _hint = null;
    _chosen = -1;
    _cmpSide = -1;
    final top = lv.top;
    _fruit = _fruits[rng.nextInt(_fruits.length)];
    switch (_mode) {
      case 'count':
        final lo = lv.range == 0 ? 1 : (lv.range == 1 ? 4 : 9);
        _n = lo + rng.nextInt(top - lo + 1);
        _options = m1Choices(_n, rng, min0: 1, max0: top + 1);
      case 'fill':
        final lo = lv.range == 0 ? 2 : (lv.range == 1 ? 5 : 10);
        _n = lo + rng.nextInt(top - lo + 1);
        _inBasket = 0;
        _dropFrom = 0;
      default:
        final lo = lv.range == 0 ? 1 : 3;
        _a = lo + rng.nextInt(top - lo + 1);
        do {
          _b = lo + rng.nextInt(top - lo + 1);
        } while (_b == _a || (lv.range == 0 && (_a - _b).abs() < 1));
        _fruitB = _fruits[(_fruits.indexOf(_fruit) + 1 + rng.nextInt(2)) % 3];
        _askMore = rng.nextBool();
    }
  }

  // ── count ──
  void _tapFruit(int i) {
    if (_order.contains(i)) return;
    setState(() => _order.add(i));
    m1Sound(context, 'PopButton');
    M1Voice.say(context, '${_order.length}');
    if (_order.length == _n) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) say(m1T(context, 'tr_now_choose', {'n': _n}));
      });
    }
  }

  bool _pick(int v) {
    if (busy) return false;
    if (v == _n) {
      good();
      return true;
    }
    bad(m1T(context, 'bk_rev_count'), help: m1T(context, 'bk_count_help'));
    return false;
  }

  // ── fill ──
  void _add() {
    if (busy) return;
    if (_inBasket >= lv.top + 3) return;
    setState(() {
      _dropFrom = _inBasket;
      _inBasket++;
    });
    m1Sound(context, 'PopButton');
    M1Voice.say(context, '$_inBasket');
  }

  void _remove() {
    if (busy || _inBasket == 0) return;
    setState(() {
      _inBasket--;
      _dropFrom = 1 << 30;
    });
    m1Sound(context, 'cancelButton');
  }

  void _check() {
    if (busy) return;
    if (_inBasket == _n) {
      good();
    } else {
      setState(() => _shakeCheck++);
      bad(m1T(context, 'bk_rev_fill', {'n': _n}),
          help: m1T(context, _inBasket < _n ? 'bk_need_more' : 'bk_need_less', {'n': _inBasket, 't': _n}));
    }
  }

  // ── compare ──
  void _choose(int side) {
    if (busy) return;
    final right = _askMore ? (_a > _b ? 0 : 1) : (_a < _b ? 0 : 1);
    setState(() => _chosen = side);
    if (side == right) {
      good(text: m1T(context, _askMore ? 'bk_yes_more' : 'bk_yes_less', {'a': max(_a, _b), 'b': min(_a, _b)}));
    } else {
      setState(() => side == 0 ? _shakeA++ : _shakeB++);
      bad(m1T(context, 'bk_rev_compare'), help: m1T(context, 'bk_compare_help'));
    }
  }

  int _cmpSide = -1; // compare: which basket is being counted
  final GlobalKey _srcKey = GlobalKey(), _basketKey = GlobalKey();

  int get _nextFruit {
    for (var i = 0; i < _n; i++) {
      if (!_order.contains(i)) return i;
    }
    return -1;
  }

  // ── guided help ──
  @override
  void idleHelp() {
    switch (_mode) {
      case 'count':
        if (_order.length < _n) {
          say(m1T(context, 'bk_tap_to_count'));
          showTap(_srcKey);
        } else if (helpLevel == 1) {
          say(m1T(context, 'bk_count_with_me'));
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted && showHand) countAlong(_n, demo: true);
          });
        } else {
          setState(() => _hint = _n);
          say(m1T(context, 'bk_count_help'));
        }
      case 'fill':
        say(_inBasket == 0
            ? m1T(context, 'bk_tap_fruit', {'n': _n})
            : m1T(context, _inBasket < _n ? 'bk_need_more' : (_inBasket > _n ? 'bk_need_less' : 'bk_ok'), {'n': _inBasket, 't': _n}));
        if (_inBasket < _n) {
          showDrag(_srcKey, _basketKey, _fruit, size: 56);
        } else if (_inBasket > 0) {
          countAlong(_inBasket, demo: true);
        }
      default:
        say(m1T(context, 'bk_compare_help'));
        if (helpLevel == 1) _countBoth(demo: true);
    }
  }

  Future<void> _countBoth({bool demo = false}) async {
    setState(() => _cmpSide = 0);
    await countAlong(_a, demo: demo, ms: 550);
    if (!mounted || (demo && !showHand)) return;
    setState(() => _cmpSide = 1);
    await countAlong(_b, demo: demo, ms: 550);
    if (mounted) setState(() => _cmpSide = -1);
  }

  @override
  Future<void> explain() async {
    switch (_mode) {
      case 'count':
        await countAlong(_n);
        M1Voice.say(context, m1T(context, 'tr_there_are', {'n': _n}));
        await Future.delayed(const Duration(milliseconds: 900));
      case 'fill':
        await countAlong(_inBasket);
      default:
        await _countBoth();
        if (!mounted) return;
        M1Voice.say(context, m1T(context, 'bk_more_than', {'a': max(_a, _b), 'b': min(_a, _b)}));
        await Future.delayed(const Duration(milliseconds: 1400));
    }
  }

  @override
  void hint() {
    mistakes++;
    switch (_mode) {
      case 'count':
        setState(() => _hint = _order.length == _n ? _n : null);
        say(m1T(context, 'bk_count_help'));
      case 'fill':
        say(m1T(context, _inBasket < _n ? 'bk_need_more' : (_inBasket > _n ? 'bk_need_less' : 'bk_ok'), {'n': _inBasket, 't': _n}));
      default:
        say(m1T(context, 'bk_compare_help'));
    }
  }

  @override
  Widget? actions(BuildContext context, double w) => _mode == 'fill'
      ? Padding(
          padding: const EdgeInsets.only(top: 2),
          child: M1Shake(
            trigger: _shakeCheck,
            child: M1OrangeButton(label: m1T(context, 'check'), icon: Icons.check_rounded, onTap: busy ? null : _check, width: min(w - 80, 290.0), height: 54, pulse: _inBasket == _n ? pulse : null),
          ),
        )
      : null;

  @override
  Widget board(BuildContext context, double w, double h) {
    final robotH = min(h * 0.24, 112.0);
    return Column(children: [
      SizedBox(
        height: robotH,
        child: Row(children: [
          const SizedBox(width: 8),
          Expanded(child: M1SayPill(text: instruction, width: w * 0.6, height: 54, blue: true)),
          SizedBox(width: robotH * 0.9, child: M1Float(child: Image.asset(m1('robot_small'), height: robotH))),
          const SizedBox(width: 4),
        ]),
      ),
      Expanded(
        child: switch (_mode) {
          'count' => _countBoard(w),
          'fill' => _fillBoard(w),
          _ => _compareBoard(w),
        },
      ),
    ]);
  }

  Widget _countBoard(double w) => LayoutBuilder(builder: (_, c) {
        final choiceH = min(c.maxHeight * 0.24, 92.0);
        final bw = min(w * 0.8, (c.maxHeight - choiceH - 70) / m1Ratio('basket_empty'));
        return Column(children: [
          const Spacer(),
          Stack(alignment: Alignment.center, children: [
            M1PopIn(
              key: ValueKey('b$round'),
              child: M1Basket(count: _n, fruit: _fruit, width: bw, tapped: _order.toSet(), order: _order, onTapFruit: busy ? null : _tapFruit, spot: countIdx, nextIdx: _nextFruit, nextKey: _srcKey),
            ),
            Positioned.fill(child: burstLayer()),
          ]),
          const SizedBox(height: 6),
          _counter(_order.length, null),
          const Spacer(),
          _order.length < _n
              ? M1WaitPill(text: m1T(context, 'bk_wait_count'), width: min(w - 40, 330.0), height: choiceH)
              : M1PopIn(
                  key: ValueKey('ready$round'),
                  child: M1ChoiceRow(key: ValueKey('c$round'), options: _options, onPick: _pick, width: min(w - 40, 330.0), height: choiceH, enabled: !busy, hintValue: _hint, hintHand: showHand),
                ),
          const SizedBox(height: 6),
        ]);
      });

  Widget _fillBoard(double w) => LayoutBuilder(builder: (_, c) {
        final H = c.maxHeight;
        final cardW = min(w * 0.27, 110.0);
        final bw = min(w * 0.6, (H * 0.48) / m1Ratio('basket_empty'));
        return Column(children: [
          SizedBox(height: H * 0.02),
          Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
            // target number card
            M1PopIn(
              key: ValueKey('card$round'),
              child: M1Float(
                amp: 3,
                child: m1OnSprite('frame_leaf', cardW, m1Number(_n, 80, color: m1Ink), area: const EdgeInsets.fromLTRB(0.2, 0.2, 0.2, 0.18)),
              ),
            ),
            const SizedBox(width: 8),
            Stack(alignment: Alignment.center, children: [
              DragTarget<int>(
                key: _basketKey,
                onWillAcceptWithDetails: (_) => true,
                onAcceptWithDetails: (_) => _add(),
                builder: (_, cand, __) => AnimatedScale(
                  scale: cand.isNotEmpty ? 1.06 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: M1Basket(count: _inBasket, fruit: _fruit, width: bw, dropFrom: _dropFrom, spot: countIdx),
                ),
              ),
              Positioned.fill(child: burstLayer()),
            ]),
          ]),
          SizedBox(height: H * 0.02),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _counter(_inBasket, _n),
            const SizedBox(width: 8),
            M1Press(
              onTap: _inBasket == 0 ? null : _remove,
              sound: '',
              child: Opacity(
                opacity: _inBasket == 0 ? 0.5 : 1,
                child: m1OnSprite('pill_minus', 128, Text(m1T(context, 'bk_remove'), textAlign: TextAlign.center, maxLines: 2, style: m1Text(14, height: 1.05)),
                    area: const EdgeInsets.fromLTRB(0.38, 0.18, 0.06, 0.18)),
              ),
            ),
          ]),
          const Spacer(),
          // the tray of fruits to pick from
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E2),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: m1Line, width: 3),
              boxShadow: [BoxShadow(color: const Color(0xFF8A5A1A).withOpacity(0.25), offset: const Offset(0, 5), blurRadius: 8)],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              for (var i = 0; i < 4; i++)
                Draggable<int>(
                  key: i == 0 ? _srcKey : null,
                  data: i,
                  maxSimultaneousDrags: busy ? 0 : 1,
                  feedback: Material(type: MaterialType.transparency, child: Image.asset(m1(_fruit), width: min(w * 0.18, 72.0), height: min(w * 0.18, 72.0))),
                  childWhenDragging: Opacity(opacity: 0.3, child: Image.asset(m1(_fruit), width: min(w * 0.15, 60.0), height: min(w * 0.15, 60.0))),
                  child: M1Press(
                  onTap: _add,
                  sound: '',
                  scale: 0.8,
                  child: M1Float(
                    amp: 3,
                    phase: i * 0.25,
                    child: Stack(clipBehavior: Clip.none, children: [
                      Image.asset(m1(_fruit), width: min(w * 0.15, 60.0), height: min(w * 0.15, 60.0)),
                      if (i == 0 && _inBasket == 0 && round == 0) Positioned(right: -14, bottom: -16, child: M1HintHand(size: 44, sprite: 'hand_tap')),
                    ]),
                  ),
                ),
                ),
            ]),
          ),
          SizedBox(height: H * 0.02),
        ]);
      });

  Widget _counter(int n, int? target) {
    final total = target ?? n;
    final dots = min(max(total, n), 20);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: m1Cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: m1Line, width: 2),
        boxShadow: [BoxShadow(color: const Color(0xFFB98B3E).withOpacity(0.25), offset: const Offset(0, 3), blurRadius: 5)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(m1T(context, 'bk_inbasket'), style: m1Text(14)),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Text('$n', key: ValueKey(n), style: m1Text(20, color: m1Purple)),
          ),
        ]),
        if (dots > 0)
          SizedBox(
            width: min(dots, 10) * 15.0,
            child: Wrap(alignment: WrapAlignment.center, spacing: 3, runSpacing: 3, children: [
              for (var i = 0; i < dots; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < n ? m1Red : const Color(0xFFE2DACB),
                    border: Border.all(color: i < n ? const Color(0xFFB0222C) : const Color(0xFFC9BFAE), width: 1),
                  ),
                ),
            ]),
          ),
      ]),
    );
  }

  Widget _compareBoard(double w) => LayoutBuilder(builder: (_, c) {
        final bw = min((w - 50) / 2, (c.maxHeight * 0.62) / m1Ratio('basket_empty'));
        Widget side(int i) {
          final n = i == 0 ? _a : _b;
          final f = i == 0 ? _fruit : _fruitB;
          final right = _askMore ? (n == max(_a, _b)) : (n == min(_a, _b));
          final picked = _chosen == i && busy && right;
          return M1Press(
            onTap: busy ? null : () => _choose(i),
            sound: '',
            child: M1Shake(
              trigger: i == 0 ? _shakeA : _shakeB,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: picked ? const Color(0xFFE6FBDD).withOpacity(0.9) : Colors.white.withOpacity(0.35),
                  border: Border.all(color: picked ? m1Green : Colors.white.withOpacity(0.7), width: picked ? 4 : 2),
                  boxShadow: [if (picked) BoxShadow(color: m1Green.withOpacity(0.5), blurRadius: 16)],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  M1PopIn(delay: 150 * i, key: ValueKey('cmp$round$i'), child: M1Basket(count: n, fruit: f, width: bw, spot: _cmpSide == i ? countIdx : null)),
                  AnimatedOpacity(
                    opacity: busy ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 54,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: m1Cream, borderRadius: BorderRadius.circular(10), border: Border.all(color: m1Line, width: 2)),
                      child: FittedBox(child: m1Number(n, 30, color: m1Ink)),
                    ),
                  ),
                ]),
              ),
            ),
          );
        }

        return Stack(children: [
          Column(children: [
            const Spacer(),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end, children: [
                side(0),
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: busy
                        ? m1Outlined(_a > _b ? '>' : '<', 46, key: const ValueKey('sign'), color: m1Purple)
                        : m1Outlined('?', 40, key: const ValueKey('q'), color: m1Purple),
                  ),
                ),
                side(1),
              ]),
            ),
            const Spacer(),
            Image.asset(m1(_askMore ? 'fox_happy' : 'bunny'), height: min(c.maxHeight * 0.22, 110.0)),
          ]),
          Positioned.fill(child: burstLayer()),
        ]);
      });
}
