import 'dart:math';

import 'package:flutter/material.dart';

import 'm1_kit.dart';
import 'm1_shell.dart';
import 'm1_text.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Les trésors à retirer — j'enlève · je compte le reste · petits problèmes
// ═══════════════════════════════════════════════════════════════════════════

const _gems = ['gem_p', 'gem_b', 'gem_g', 'gem_o'];

class M1TreasurePlay extends M1Play {
  const M1TreasurePlay({super.key, required super.lv});
  @override
  State<M1TreasurePlay> createState() => _TreasureState();
}

class _TreasureState extends M1PlayState<M1TreasurePlay> {
  String get _mode => lv.modeId;
  int _a = 0, _b = 0;
  String _gem = 'gem_p';
  List<int> _options = [];
  int? _hint;
  final List<int> _removed = []; // indexes taken out, in order
  int _story = 0;
  String _item = 'shell';

  int get _rest => _a - _b;
  bool get _ready => _removed.length >= _b; // all removals done → time to count

  @override
  String get instruction {
    switch (_mode) {
      case 'remove':
        return _ready ? m1T(context, 'tz_howmany') : m1T(context, 'tz_remove', {'a': _a, 'b': _b});
      case 'rest':
        return m1T(context, 'tz_rest', {'a': _a, 'b': _b});
      default:
        return m1T(context, 'tz_story$_story', {'a': _a, 'b': _b});
    }
  }

  @override
  void newRound() {
    _removed.clear();
    _hint = null;
    final top = lv.top;
    final lo = lv.range == 0 ? 2 : (lv.range == 1 ? 5 : 10);
    _a = lo + rng.nextInt(top - lo + 1);
    _b = 1 + rng.nextInt(_a - 1);
    _gem = _gems[rng.nextInt(_gems.length)];
    _options = m1Choices(_rest, rng, min0: 0, max0: top);
    if (_mode == 'rest') {
      // the robot takes the treasures out by itself, one by one
      final pick = List.generate(_a, (i) => i)..shuffle(rng);
      final take = pick.take(_b).toList()..sort();
      final r = round;
      for (var k = 0; k < take.length; k++) {
        Future.delayed(Duration(milliseconds: 900 + k * 450), () {
          if (!mounted || round != r || _removed.length >= _b) return;
          setState(() => _removed.add(take[k]));
          m1Sound(context, 'PopButton');
        });
      }
    }
    if (_mode == 'problems') {
      _story = rng.nextInt(4);
      _item = const ['shell', 'gem_b', 'apple2', 'gem_o'][_story];
      _removed.addAll(List.generate(_b, (i) => _a - 1 - i));
    }
  }

  void _tapGem(int i) {
    if (busy || _mode != 'remove' || _removed.contains(i)) return;
    if (_ready) {
      say(m1T(context, 'tz_enough', {'b': _b}));
      return;
    }
    setState(() => _removed.add(i));
    m1Sound(context, 'PopButton');
    M1Voice.say(context, '${_removed.length}');
    if (_ready) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) say(m1T(context, 'tz_howmany'));
      });
    }
  }

  void _undo() {
    if (busy || _mode != 'remove' || _removed.isEmpty) return;
    setState(() => _removed.removeLast());
    m1Sound(context, 'cancelButton');
  }

  bool _pick(int v) {
    if (busy) return false;
    if (_mode == 'remove' && !_ready) {
      say(m1T(context, 'tz_remove_first', {'b': _b}));
      return false;
    }
    if (v == _rest) {
      good(text: '$_a − $_b = $_rest ! ${praise()}');
      return true;
    }
    bad('$_a − $_b = $_rest', help: m1T(context, 'tz_help'));
    return false;
  }

  // ── guided help ──
  List<int> get _left => [for (var i = 0; i < _a; i++) if (!_removed.contains(i)) i];

  /// The treasure being counted right now (counting goes over the ones left).
  int? get _spotGem {
    final k = countIdx;
    final l = _left;
    return (k != null && k < l.length) ? l[k] : null;
  }

  @override
  void idleHelp() {
    if (_mode == 'remove' && !_ready) {
      say(m1T(context, 'tz_remove', {'a': _a, 'b': _b}));
      return;
    }
    if (helpLevel == 1) {
      say(m1T(context, 'tz_count_left'));
      countAlong(_left.length, demo: true);
    } else {
      setState(() => _hint = _rest);
      say(m1T(context, 'tz_help'));
    }
  }

  @override
  Future<void> explain() async {
    if (_removed.length < _b) {
      // problems / rest: make sure the taken treasures are really gone
      final pick = _left.reversed.take(_b - _removed.length).toList();
      setState(() => _removed.addAll(pick));
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
    }
    M1Voice.say(context, m1T(context, 'tz_left_are'));
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await countAlong(_left.length);
    if (!mounted) return;
    M1Voice.say(context, '$_a − $_b = $_rest');
    await Future.delayed(const Duration(milliseconds: 1400));
  }

  @override
  void hint() {
    mistakes++;
    if (_mode == 'remove' && !_ready) {
      say(m1T(context, 'tz_remove', {'a': _a, 'b': _b}));
      return;
    }
    setState(() => _hint = _rest);
    say(m1T(context, 'tz_help'));
  }

  @override
  Widget board(BuildContext context, double w, double h) {
    final topH = min(h * 0.24, 116.0);
    return Column(children: [
      SizedBox(
        height: topH,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const SizedBox(width: 4),
          M1Float(amp: 3, child: Image.asset(m1('explorer_point'), height: topH)),
          Expanded(child: Padding(padding: EdgeInsets.only(bottom: topH * 0.3), child: M1Bubble(text: robotSay, width: min(w * 0.62, 250.0)))),
          const SizedBox(width: 6),
        ]),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: LayoutBuilder(builder: (_, c) {
            final H = c.maxHeight, W = c.maxWidth;
            final choiceH = min(H * 0.2, 84.0);
            return Stack(children: [
              Column(children: [
                Expanded(child: _treasures(W)),
                SizedBox(height: H * 0.025),
                _equation(W, min(H * 0.16, 76.0)),
                SizedBox(height: H * 0.02),
                M1SayPill(text: instruction, width: W, height: 46),
                SizedBox(height: H * 0.02),
                M1ChoiceRow(key: ValueKey('c$round'), options: _options, onPick: _pick, width: W, height: choiceH, enabled: !busy, hintValue: _hint, hintHand: showHand),
              ]),
              Positioned.fill(child: burstLayer()),
            ]);
          }),
        ),
      ),
    ]);
  }

  Widget _goldFrame({required Widget child, EdgeInsets padding = const EdgeInsets.all(8)}) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFDD6E), Color(0xFFF0A30F)]),
          boxShadow: [BoxShadow(color: const Color(0xFFB66A00).withOpacity(0.35), offset: const Offset(0, 5), blurRadius: 8)],
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(color: const Color(0xFFFFF6E2), borderRadius: BorderRadius.circular(16)),
          child: child,
        ),
      );

  Widget _treasures(double W) => LayoutBuilder(builder: (_, c) {
        final H = c.maxHeight;
        final item = _mode == 'problems' ? _item : _gem;
        final mainW = W * 0.68, sideW = W - mainW - 8;
        final perRow = _a <= 5 ? _a : (_a <= 10 ? 5 : 7);
        final rows = (_a / perRow).ceil();
        final s = min((mainW - 24) / perRow, (H - 30) / rows) * 0.94;
        final takenS = min((sideW - 20) / min(3, max(1, _b)), (H - 40) / ((_b / 3).ceil())) * 0.9;
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              width: mainW,
              child: _goldFrame(
                child: Center(
                  child: Wrap(alignment: WrapAlignment.center, runAlignment: WrapAlignment.center, children: [
                    for (var i = 0; i < _a; i++)
                      GestureDetector(
                        onTap: () => _tapGem(i),
                        child: M1Spot(
                          on: _spotGem == i,
                          badge: _spotGem == i ? '${countIdx! + 1}' : null,
                          hand: _spotGem == i || (showHand && _mode == 'remove' && !_ready && _left.isNotEmpty && i == _left.first),
                          size: s,
                          child: SizedBox(
                          width: s,
                          height: s,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 380),
                            transitionBuilder: (ch, a) => ScaleTransition(scale: a, child: ch),
                            child: _removed.contains(i)
                                ? Padding(key: ValueKey('e$i'), padding: EdgeInsets.all(s * 0.08), child: Image.asset(m1('gem_slot'), fit: BoxFit.contain, opacity: const AlwaysStoppedAnimation(0.8)))
                                : M1Float(
                                    key: ValueKey('g$i'),
                                    amp: 1.5,
                                    phase: i * 0.13,
                                    child: Padding(padding: EdgeInsets.all(s * 0.05), child: Image.asset(m1(item), fit: BoxFit.contain)),
                                  ),
                          ),
                        ),
                        ),
                      ),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: sideW,
              child: _goldFrame(
                padding: const EdgeInsets.all(4),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: FittedBox(child: Text(m1T(context, 'tz_taken', {'n': _removed.length}), style: m1Text(14))),
                  ),
                  Expanded(
                    child: Center(
                      child: Wrap(alignment: WrapAlignment.center, children: [
                        for (var k = 0; k < _removed.length; k++)
                          TweenAnimationBuilder<double>(
                            key: ValueKey('t${_removed[k]}'),
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutBack,
                            builder: (_, v, ch) => Transform.translate(offset: Offset(-60 * (1 - v), -30 * sin(v * pi)), child: Transform.scale(scale: 0.4 + 0.6 * v, child: ch)),
                            child: Image.asset(m1(item), width: takenS, height: takenS),
                          ),
                      ]),
                    ),
                  ),
                  if (_mode == 'remove' && _removed.isNotEmpty && !busy)
                    M1Press(onTap: _undo, child: Image.asset(m1('btn_restart_sq'), width: 34)),
                ]),
              ),
            ),
          ]),
        );
      });

  Widget _equation(double W, double h) {
    final showB = _mode != 'remove' || _ready;
    return Container(
      width: W,
      height: h,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: m1Cream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: m1Line, width: 2.5),
        boxShadow: [BoxShadow(color: const Color(0xFFB98B3E).withOpacity(0.3), offset: const Offset(0, 4), blurRadius: 6)],
      ),
      child: FittedBox(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            m1Number(_a, 54, color: m1Ink),
            const SizedBox(width: 10),
            m1Outlined('−', 54, color: m1Ink),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: showB ? m1Number(_b, 54, key: const ValueKey('b'), color: m1Ink) : m1Outlined('?', 54, key: const ValueKey('qb'), color: const Color(0xFFBCAF98)),
            ),
            const SizedBox(width: 10),
            Image.asset(m1('equals'), width: 40),
            const SizedBox(width: 10),
            Container(
              width: 66,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: busy ? const Color(0xFFE9FBE2) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: busy ? m1Green : const Color(0xFFD9B97A), width: 3),
              ),
              child: busy ? m1Number(_rest, 44) : m1Outlined('?', 44, color: m1Purple),
            ),
          ]),
        ),
      ),
    );
  }
}
