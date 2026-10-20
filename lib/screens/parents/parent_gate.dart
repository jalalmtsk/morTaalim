import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';

import 'parent_strings.dart';
import 'parent_ui.dart';

/// Adult check: hold 3 s, then solve a multiplication.
/// After a success, the gate stays open for a few minutes.
class ParentGate {
  ParentGate._();
  static DateTime? _passedAt;
  static const _grace = Duration(minutes: 5);

  /// Closes the grace period (next access asks again).
  static void lock() => _passedAt = null;

  static bool get recentlyPassed => _passedAt != null && DateTime.now().difference(_passedAt!) < _grace;

  /// True when an adult passed the check.
  static Future<bool> check(BuildContext context, {bool force = false}) async {
    if (!force && recentlyPassed) return true;
    final ok = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) => const ParentGatePage(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    );
    if (ok == true) _passedAt = DateTime.now();
    return ok == true;
  }
}

class ParentGatePage extends StatefulWidget {
  const ParentGatePage({super.key});

  @override
  State<ParentGatePage> createState() => _ParentGatePageState();
}

class _ParentGatePageState extends State<ParentGatePage> with TickerProviderStateMixin {
  final _r = Random();
  late int _a, _b;
  String _typed = '';
  bool _step1 = false;
  bool _wrong = false;
  int _fails = 0;
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(seconds: 3))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        HapticFeedback.mediumImpact();
        setState(() => _step1 = true);
      }
    });
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  void _newQuestion() {
    _a = 6 + _r.nextInt(4); // 6–9
    _b = 6 + _r.nextInt(4);
    _typed = '';
  }

  @override
  void dispose() {
    _hold.dispose();
    _idle.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _key(String k) {
    HapticFeedback.selectionClick();
    setState(() {
      _wrong = false;
      if (k == '<') {
        if (_typed.isNotEmpty) _typed = _typed.substring(0, _typed.length - 1);
      } else if (_typed.length < 3) {
        _typed += k;
      }
    });
  }

  void _submit() {
    if (!_step1 || _typed.isEmpty) return;
    if (int.tryParse(_typed) == _a * _b) {
      HapticFeedback.lightImpact();
      Navigator.pop(context, true);
      return;
    }
    _fails++;
    HapticFeedback.heavyImpact();
    _shake.forward(from: 0);
    setState(() {
      _wrong = true;
      _newQuestion();
      if (_fails >= 3) {
        // three wrong answers: start again from the hold step
        _fails = 0;
        _step1 = false;
        _hold.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final w = min(MediaQuery.sizeOf(context).width - 32, 460.0);
    return Scaffold(
      backgroundColor: PC.cream,
      body: ParentBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(children: [
                _round(Icons.arrow_back_rounded, () => Navigator.pop(context, false)),
                const SizedBox(width: 14),
                Text(pT(context, 'parentsSpace'), style: ps(28, w: FontWeight.w700)),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 4, 16, pad.bottom + 16),
                child: Center(child: SizedBox(width: w, child: _card(w))),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _round(IconData i, VoidCallback onTap) => KidPressable(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: PC.cream,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Icon(i, color: PC.teal, size: 28),
        ),
      );

  Widget _card(double w) {
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        margin: const EdgeInsets.only(top: 74),
        padding: const EdgeInsets.fromLTRB(16, 70, 16, 16),
        decoration: BoxDecoration(
          color: PC.cream,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: const Color(0xFF3B2A7A).withOpacity(0.14), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Column(children: [
          Text(pT(context, 'adultsOnly'), textAlign: TextAlign.center, style: ps(28, w: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(pT(context, 'adultsOnlySub'), textAlign: TextAlign.center, style: ps(15, color: PC.sub, w: FontWeight.w500)),
          const SizedBox(height: 16),
          _stepHold(),
          const SizedBox(height: 14),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _step1 ? 1 : 0.45,
            child: IgnorePointer(ignoring: !_step1, child: _stepMath()),
          ),
          const SizedBox(height: 16),
          PButton(pT(context, 'enter'), onTap: _step1 && _typed.isNotEmpty ? _submit : null),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.pop(context, false),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.undo_rounded, color: PC.teal, size: 24),
              const SizedBox(width: 8),
              Text(pT(context, 'backToKid'), style: ps(16, color: PC.tealDeep, w: FontWeight.w700)),
            ]),
          ),
        ]),
      ),
      // arch top with shield
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        child: Center(
          child: AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi) * 3), child: c),
            child: Image.asset(pa('gate_shield'), height: 140),
          ),
        ),
      ),
      Positioned(
        right: -10,
        top: 6,
        child: AnimatedBuilder(
          animation: _idle,
          builder: (_, c) => Transform.rotate(angle: sin(_idle.value * 2 * pi) * 0.05, child: c),
          child: Image.asset(pa('gate_robot'), width: min(130.0, w * 0.3)),
        ),
      ),
    ]);
  }

  Widget _num(int n, bool done) => Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: done ? PC.teal : const Color(0xFFA79CC2)),
        child: done ? const Icon(Icons.check_rounded, color: Colors.white) : Text('$n', style: ps(20, color: Colors.white, w: FontWeight.w700)),
      );

  Widget _stepHold() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: PC.tealSoft.withOpacity(0.7),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(children: [
        Row(children: [
          _num(1, _step1),
          const SizedBox(width: 12),
          Expanded(child: Text(pT(context, 'hold3'), style: ps(19, w: FontWeight.w700))),
        ]),
        const SizedBox(height: 10),
        GestureDetector(
          onTapDown: (_) {
            if (!_step1) _hold.forward();
          },
          onTapUp: (_) {
            if (!_step1) _hold.reverse();
          },
          onTapCancel: () {
            if (!_step1) _hold.reverse();
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([_hold, _idle]),
            builder: (_, __) {
              final pulse = (sin(_idle.value * 2 * pi * 2) + 1) / 2;
              return SizedBox(
                width: 150,
                height: 150,
                child: Stack(alignment: Alignment.center, children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                      BoxShadow(color: const Color(0xFF3EE6E0).withOpacity(0.25 + 0.25 * pulse + 0.3 * _hold.value), blurRadius: 30, spreadRadius: 4),
                    ]),
                  ),
                  SizedBox(
                    width: 146,
                    height: 146,
                    child: CircularProgressIndicator(
                      value: _step1 ? 1 : _hold.value,
                      strokeWidth: 7,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.white.withOpacity(0.6),
                      valueColor: const AlwaysStoppedAnimation(PC.teal),
                    ),
                  ),
                  Transform.scale(scale: 1 - 0.06 * _hold.value, child: Image.asset(pa('fingerprint'), width: 128)),
                ]),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Container(
            key: ValueKey(_step1),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.55), borderRadius: BorderRadius.circular(30)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (_step1) ...[
                const Icon(Icons.check_circle_rounded, color: PC.tealDeep, size: 26),
                const SizedBox(width: 8),
              ],
              Text(pT(context, _step1 ? 'step1Done' : 'holdHint'), style: ps(16, color: PC.tealDeep, w: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _stepMath() {
    return AnimatedBuilder(
      animation: _shake,
      builder: (_, c) => Transform.translate(offset: Offset(sin(_shake.value * pi * 6) * 10 * (1 - _shake.value), 0), child: c),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: PC.line, width: 1.5),
        ),
        child: Column(children: [
          Row(children: [
            _num(2, false),
            const SizedBox(width: 12),
            Expanded(child: Text(pT(context, 'solve'), style: ps(18, w: FontWeight.w700))),
          ]),
          const SizedBox(height: 4),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text('$_a × $_b = ?', style: ps(44, w: FontWeight.w700, h: 1.1)),
          ),
          const SizedBox(height: 8),
          Container(
            height: 56,
            width: 220,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _wrong ? const Color(0xFFE5486A) : PC.line, width: 2),
            ),
            child: Text(_wrong ? pT(context, 'tryAgain') : _typed,
                style: ps(_wrong ? 16 : 30, color: _wrong ? const Color(0xFFE5486A) : PC.ink, w: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(children: [
              for (final row in const [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    for (final k in row) ...[
                      Expanded(child: _keyBtn(k)),
                      if (k != row.last) const SizedBox(width: 8),
                    ],
                  ]),
                ),
              Row(children: [
                Expanded(flex: 2, child: _keyBtn('0')),
                const SizedBox(width: 8),
                Expanded(child: _keyBtn('<')),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _keyBtn(String k) => KidPressable(
        onTap: () => _key(k),
        pressedScale: 0.93,
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: PC.cream,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: const Color(0xFFDCD3C0).withOpacity(0.9), offset: const Offset(0, 3)),
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
            ],
          ),
          child: k == '<'
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: PC.ink, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                )
              : Text(k, style: ps(24, w: FontWeight.w700)),
        ),
      );
}
