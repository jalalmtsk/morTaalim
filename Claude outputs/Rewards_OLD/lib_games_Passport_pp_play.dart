import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:provider/provider.dart';

import 'pp_data.dart';
import 'pp_menu.dart';
import 'pp_strings.dart';

enum _Phase { observe, find, puzzle, stamp }

/// One stage ("escale"): observe → find the details → rebuild the postcard → stamp.
class StagePlay extends StatefulWidget {
  final PpStage stage;
  const StagePlay({super.key, required this.stage});
  @override
  State<StagePlay> createState() => _StagePlayState();
}

class _StagePlayState extends State<StagePlay> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final AnimationController _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _stampAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  final Random _rng = Random();

  PpStage get _st => widget.stage;
  _Phase _phase = _Phase.observe;
  int _mistakes = 0, _hints = 0;
  bool _leaving = false, _over = false;
  String _say = '';
  String _shakeId = '';

  // observe
  final Set<String> _seen = {};
  bool _glowHint = false;
  // find
  final Set<String> _found = {};
  String? _hintId;
  Offset? _missAt;
  // puzzle
  late final (int, int) _grid = _st.grid;
  late final List<int> _pieces = List.generate(_grid.$1 * _grid.$2, (i) => i)..shuffle(_rng);
  final Set<int> _placed = {};
  int? _picked;
  bool _model = true;
  int? _flashCell;
  // stamp
  bool _stamped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _speak(ppT(context, 'observeTouch'));
    });
  }

  @override
  void dispose() {
    PpVoice.stop();
    _idle.dispose();
    _shake.dispose();
    _burst.dispose();
    _stampAnim.dispose();
    super.dispose();
  }

  void _speak(String t, {bool voice = true}) {
    setState(() => _say = t);
    if (voice) PpVoice.say(context, t);
  }

  void _shakeIt(String id) {
    setState(() => _shakeId = id);
    _shake.forward(from: 0);
  }

  // ── navigation ────────────────────────────────────────────────────────────

  void _leave([String? result]) {
    if (_leaving) return;
    PpVoice.stop();
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  void _restart() {
    PpVoice.stop();
    Navigator.of(context).pushReplacement(PageRouteBuilder<String>(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => StagePlay(stage: _st),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
  }

  Future<void> _askQuit() async {
    ppSound(context, 'clickButton');
    final q = await ppDialog<bool>(context, const _QuitDialog());
    if (q == true && mounted) _leave();
  }

  Future<void> _pause() async {
    ppSound(context, 'clickButton');
    final r = await ppDialog<String>(context, const _PauseDialog());
    if (!mounted) return;
    if (r == 'restart') _restart();
    if (r == 'home') _leave();
  }

  void _goto(_Phase p) {
    ppSfx(context, 'CorrectAnwser_SFX.mp3');
    setState(() {
      _phase = p;
      _glowHint = false;
      _hintId = null;
    });
    _speak(switch (p) {
      _Phase.observe => ppT(context, 'observeTouch'),
      _Phase.find => ppT(context, 'findThree'),
      _Phase.puzzle => ppT(context, 'slide'),
      _Phase.stamp => ppT(context, 'pressStamp'),
    });
  }

  Future<void> _hint() async {
    ppSound(context, 'clickButton');
    _hints++;
    switch (_phase) {
      case _Phase.observe:
        setState(() => _glowHint = true);
        await ppDialog(context, _HintDialog(message: ppT(context, 'hintObserve')));
      case _Phase.find:
        final next = _st.details.firstWhere((d) => !_found.contains(d.id));
        final msg = ppT(context, 'hintFind', {'d': next.name(context).toLowerCase()});
        PpVoice.say(context, msg);
        await ppDialog(context, _HintDialog(message: msg, extra: _cropOf(next, 80)));
        if (!mounted) return;
        setState(() => _hintId = next.id);
      case _Phase.puzzle:
        PpVoice.say(context, ppT(context, 'hintPuzzle'));
        await ppDialog(context, _HintDialog(message: ppT(context, 'hintPuzzle')));
        if (!mounted) return;
        final left = [for (final p in _pieces) if (!_placed.contains(p)) p];
        if (left.isNotEmpty) {
          left.sort();
          _place(left.first, left.first, byHint: true);
        }
      case _Phase.stamp:
        break;
    }
  }

  // ── observe ───────────────────────────────────────────────────────────────

  void _see(PpDetail d) {
    if (_seen.contains(d.id)) {
      PpVoice.say(context, d.name(context));
      return;
    }
    ppSound(context, 'PopButton');
    _burst.forward(from: 0);
    setState(() => _seen.add(d.id));
    _speak(d.name(context));
  }

  Future<void> _zoom() async {
    ppSound(context, 'clickButton');
    await ppDialog(context, _ZoomDialog(stage: _st), dismissible: true);
  }

  // ── find ──────────────────────────────────────────────────────────────────

  Future<void> _tapPicture(Offset local, Size size) async {
    if (_phase != _Phase.find) return;
    final fx = local.dx / size.width, fy = local.dy / size.height;
    PpDetail? hit;
    for (final d in _st.details) {
      if (_found.contains(d.id)) continue;
      final dx = (fx - d.x) * size.width, dy = (fy - d.y) * size.height;
      final r = d.r * size.width * 1.45 + 10;
      if (dx * dx + dy * dy <= r * r) hit = d;
    }
    if (hit == null) {
      _mistakes++;
      ppSound(context, 'clickButton2');
      setState(() => _missAt = local);
      _shakeIt('pic');
      _speak(ppT(context, 'againSub'));
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _missAt = null);
      });
      return;
    }
    final got = hit;
    ppSfx(context, 'CorrectAnwser_SFX.mp3');
    _burst.forward(from: 0);
    setState(() {
      _found.add(got.id);
      if (_hintId == got.id) _hintId = null;
    });
    _speak('${ppT(context, 'goodT')} ${got.name(context)} !');
    if (_found.length == _st.details.length) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      await ppDialog(context, const _GoodDialog());
    }
  }

  // ── puzzle ────────────────────────────────────────────────────────────────

  void _place(int piece, int cell, {bool byHint = false}) {
    if (_placed.contains(piece)) return;
    if (piece != cell) {
      _mistakes++;
      ppSound(context, 'clickButton2');
      _shakeIt('cell$cell');
      _speak(ppT(context, 'wrongPiece'));
      setState(() => _picked = null);
      return;
    }
    ppSound(context, 'PopButton');
    setState(() {
      _placed.add(piece);
      _picked = null;
      _flashCell = cell;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _flashCell == cell) setState(() => _flashCell = null);
    });
    if (_placed.length == _pieces.length) {
      ppSfx(context, 'CorrectAnwser_SFX.mp3');
      _burst.forward(from: 0);
      setState(() => _model = false);
      _speak(ppT(context, 'allPlaced'));
    } else if (!byHint) {
      _speak(ppT(context, 'placed', {'n': _placed.length, 'm': _pieces.length}), voice: false);
    }
  }

  // ── stamp ─────────────────────────────────────────────────────────────────

  Future<void> _doStamp() async {
    if (_stamped || _stampAnim.isAnimating) return;
    ppSound(context, 'PopButton');
    await _stampAnim.forward(from: 0);
    if (!mounted) return;
    ppSfx(context, 'MarimbaWin_SFX.mp3');
    _burst.forward(from: 0);
    setState(() => _stamped = true);
    _speak('${_st.title(context)} ! ${ppT(context, 'souvenir')}');
  }

  // ── win ───────────────────────────────────────────────────────────────────

  Future<void> _win() async {
    if (_over) return;
    _over = true;
    final before = await PpStore.load();
    final stars = (_mistakes + _hints == 0) ? 3 : (_mistakes + _hints <= 3 ? 2 : 1);
    final (fresh, first) = await PpStore.record(_st.id, stars);
    final after = await PpStore.load();
    if (!mounted) return;
    final badge = first && !before.countryDone(_st.land) && after.countryDone(_st.land);
    final gold = first ? 12 + _st.index * 2 : 3 + fresh * 2;
    var gems = (stars == 3 && fresh > 0) ? 1 : 0;
    if (badge) gems += 3;
    try {
      final xp = Provider.of<ExperienceManager>(context, listen: false);
      xp.addGold(context, gold);
      if (gems > 0) xp.addGems(context, gems);
      xp.addXP(5 + stars * 3, context: context);
    } catch (_) {}
    PpVoice.say(context, '${ppT(context, 'bravo1')} ${ppT(context, 'bravo2')}');
    final r = await Navigator.of(context).push<String>(PageRouteBuilder<String>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => _EndPage(stage: _st, stars: stars, gold: gold, gems: gems, badge: badge, last: after.stamps == ppStages.length),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
    if (!mounted) return;
    if (r == 'again') {
      _restart();
    } else {
      _leave(r);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) => PpFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = ppScale(context);
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 520.0);
    final land = _st.land.name(context);
    final (String? cap, String a, String b) = switch (_phase) {
      _Phase.observe => (ppT(context, 'stepOf', {'c': land, 'n': _st.index + 1}), ppT(context, 'escaleA'), _st.city(context)),
      _Phase.find => (ppT(context, 'defiN', {'c': _st.city(context), 'n': 1}), ppT(context, 'defiA'), ppT(context, 'defiB')),
      _Phase.puzzle => (ppT(context, 'defiN', {'c': _st.city(context), 'n': 2}), ppT(context, 'pcA'), ppT(context, 'pcB')),
      _Phase.stamp => (null, ppT(context, 'newA'), ppT(context, 'newB')),
    };
    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askQuit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF8FD3F5),
        body: Stack(children: [
          Positioned.fill(child: PpBg(asset: _phase == _Phase.stamp ? 'pp_bg_win' : 'pp_bg')),
          SafeArea(
            child: Center(
              child: SizedBox(
                width: w,
                child: Column(children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8 * s),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ppRound(context, 'pp_back', 44 * s, _askQuit, flipRtl: true),
                      Expanded(
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: PpHeader(key: ValueKey(_phase), caption: cap, a: a, b: b, width: min(w * 0.7, 280 * s)),
                          ),
                        ),
                      ),
                      Column(children: [
                        ppRound(context, 'pp_pause', 44 * s, _pause),
                        if (_phase != _Phase.stamp) ...[
                          SizedBox(height: 4 * s),
                          PpPress(
                            onTap: _hint,
                            label: ppT(context, 'hint'),
                            child: AnimatedBuilder(
                              animation: _idle,
                              builder: (_, c) => Transform.rotate(angle: sin(_idle.value * 2 * pi * 2) * 0.08, child: c),
                              child: Image.asset(pp('pp_hint_btn'), width: 44 * s),
                            ),
                          ),
                        ],
                      ]),
                    ]),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      transitionBuilder: (c, an) => FadeTransition(
                        opacity: an,
                        child: SlideTransition(position: Tween(begin: const Offset(0.12, 0), end: Offset.zero).animate(an), child: c),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_phase),
                        child: switch (_phase) {
                          _Phase.observe => _observeView(s, w),
                          _Phase.find => _findView(s, w),
                          _Phase.puzzle => _puzzleView(s, w),
                          _Phase.stamp => _stampView(s, w),
                        },
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── shared pieces ─────────────────────────────────────────────────────────

  Widget _bob(Widget c, {double amp = 3, double speed = 2, double phase = 0}) => AnimatedBuilder(
        animation: _idle,
        builder: (_, child) => Transform.translate(offset: Offset(0, sin((_idle.value * speed + phase) * 2 * pi) * amp), child: child),
        child: c,
      );

  Widget _shaking(String id, Widget child) => AnimatedBuilder(
        animation: _shake,
        builder: (_, c) => Transform.translate(
          offset: Offset(_shakeId == id ? sin(_shake.value * pi * 6) * 8 * (1 - _shake.value) : 0, 0),
          child: c,
        ),
        child: child,
      );

  Widget _cropOf(PpDetail d, double size, {bool done = false, bool active = false}) => Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.05),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: done ? ppGreen : (active ? const Color(0xFF39D2FF) : const Color(0xFFF0C77A)), width: size * 0.05),
          boxShadow: [
            if (done || active) BoxShadow(color: (done ? ppGreen : const Color(0xFF39D2FF)).withOpacity(0.6), blurRadius: size * 0.15),
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: PpDetailCrop(stage: _st, detail: d, size: size * 0.9 - size * 0.1),
      );

  /// Size of the picture fitted in a box.
  Size _fit(double bw, double bh) {
    var w = bw, h = bw / _st.aspect;
    if (h > bh) {
      h = bh;
      w = bh * _st.aspect;
    }
    return Size(w, h);
  }

  Widget _framed(Size sz, Widget child, double s) => Container(
        width: sz.width + 10 * s,
        height: sz.height + 10 * s,
        padding: EdgeInsets.all(5 * s),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22 * s),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12 * s, offset: Offset(0, 5 * s))],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(17 * s), child: child),
      );

  Widget _robotBubble(double s, String art, double h, double bw) => IgnorePointer(
        child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
          _bob(Transform.flip(flipX: ppRtl(context), child: Image.asset(pp(art), height: h))),
          if (_say.isNotEmpty) Padding(padding: EdgeInsets.only(bottom: h * 0.45), child: PpBubble(text: _say, width: bw)),
        ]),
      );

  // ═════════════════════════════════════════════════════════════════════════
  // 1. Observe — "Escale à Rabat"
  // ═════════════════════════════════════════════════════════════════════════

  Widget _observeView(double s, double w) => Column(children: [
        Expanded(
          child: LayoutBuilder(builder: (_, c) {
            final sz = _fit(c.maxWidth - 30 * s, c.maxHeight - 14 * s);
            return Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
              _framed(
                sz,
                SizedBox(
                  width: sz.width,
                  height: sz.height,
                  child: Stack(clipBehavior: Clip.none, children: [
                    Positioned.fill(child: Image.asset(_st.scene, fit: BoxFit.fill)),
                    for (final d in _st.details) _lens(d, sz, s),
                    Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(animation: _burst, builder: (_, __) => CustomPaint(painter: PpBurst(_burst.value))))),
                  ]),
                ),
                s,
              ),
              PositionedDirectional(
                end: 4 * s,
                top: 0,
                child: _bob(
                  ppOnSprite('pp_eye_pill', 150 * s, 0.4234, Text(ppT(context, 'observeTouch'), textAlign: TextAlign.center, maxLines: 2, style: ppText(12 * s, height: 1.1)),
                      area: const EdgeInsets.fromLTRB(0.34, 0.2, 0.06, 0.2)),
                  phase: 0.4,
                ),
              ),
            ]);
          }),
        ),
        _observeCard(s, w),
        SizedBox(height: 6 * s),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          PpPill(label: ppT(context, 'closer'), icon: Image.asset(pp('pp_magnifier'), height: 22 * s), onTap: _zoom, s: s, border: const Color(0xFF2B3FA8), font: 13),
          SizedBox(width: 8 * s),
          Flexible(
            child: PpButton.main(
              ppT(context, 'challenge'),
              _seen.length == _st.details.length ? () => _goto(_Phase.find) : null,
              min(w * 0.52, 210 * s),
              pulse: _idle,
            ),
          ),
        ]),
        SizedBox(height: 8 * s),
      ]);

  Widget _lens(PpDetail d, Size sz, double s) {
    final seen = _seen.contains(d.id);
    final r = max(d.r * sz.width, 20 * s);
    final c = Offset(d.x * sz.width, d.y * sz.height);
    if (seen) {
      return Positioned(
        left: c.dx - r * 1.25,
        top: c.dy - r * 1.25,
        width: r * 2.5,
        height: r * 2.5,
        child: GestureDetector(
          onTap: () => _see(d),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.elasticOut,
            builder: (_, v, ch) => Transform.scale(scale: v, child: ch),
            child: Image.asset(pp('pp_ring'), fit: BoxFit.contain),
          ),
        ),
      );
    }
    final m = 34 * s;
    return Positioned(
      left: c.dx - m / 2,
      top: c.dy - m / 2,
      width: m,
      height: m,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _see(d),
        child: AnimatedBuilder(
          animation: _idle,
          builder: (_, ch) {
            final p = sin((_idle.value * 4 + d.x) * 2 * pi);
            return Transform.scale(
              scale: (_glowHint ? 1.2 : 1.0) + 0.1 * p,
              child: DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                  BoxShadow(color: const Color(0xFFFFF27A).withOpacity(_glowHint ? 0.95 : 0.55 + 0.25 * p), blurRadius: 14 * s, spreadRadius: 3 * s),
                ]),
                child: ch,
              ),
            );
          },
          child: Image.asset(pp('pp_magnifier'), fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _observeCard(double s, double w) => Stack(clipBehavior: Clip.none, children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 10 * s),
          padding: EdgeInsets.fromLTRB(12 * s, 8 * s, 12 * s, 10 * s),
          decoration: BoxDecoration(
            color: ppCream,
            borderRadius: BorderRadius.circular(24 * s),
            border: Border.all(color: const Color(0xFFF1D7A6), width: 3 * s),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 10 * s, offset: Offset(0, 4 * s))],
          ),
          child: Column(children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(_st.title(context), style: ppText(23 * s, weight: FontWeight.w800))),
            Text(_st.fact(context), textAlign: TextAlign.center, maxLines: 2, style: ppText(12.5 * s, color: ppInkSoft, weight: FontWeight.w600, height: 1.15)),
            SizedBox(height: 4 * s),
            PpPress(
              onTap: () => PpVoice.say(context, '${_st.title(context)}. ${_st.fact(context)}'),
              label: ppT(context, 'listen'),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 3 * s),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16 * s), border: Border.all(color: const Color(0xFF2B3FA8), width: 1.8 * s)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Image.asset(pp('pp_sound'), height: 20 * s),
                  SizedBox(width: 4 * s),
                  Text(ppT(context, 'listen'), style: ppText(13 * s)),
                ]),
              ),
            ),
            SizedBox(height: 6 * s),
            Row(children: [
              SizedBox(width: w * 0.2),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14 * s)),
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text(ppT(context, 'whatDetails'), style: ppText(12.5 * s))),
                ),
              ),
              SizedBox(width: 6 * s),
              for (final d in _st.details)
                Padding(
                  padding: EdgeInsets.only(left: 4 * s),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                    child: _seen.contains(d.id)
                        ? KeyedSubtree(key: ValueKey('c${d.id}'), child: _cropOf(d, 46 * s, done: true))
                        : Image.asset(pp('pp_dash'), key: ValueKey('e${d.id}'), width: 46 * s),
                  ),
                ),
            ]),
          ]),
        ),
        Positioned(left: 0, bottom: -6 * s, child: IgnorePointer(child: _bob(Image.asset(pp('pp_robot_point'), height: 74 * s)))),
      ]);

  // ═════════════════════════════════════════════════════════════════════════
  // 2. Find the details — "Le défi des explorateurs"
  // ═════════════════════════════════════════════════════════════════════════

  Widget _findView(double s, double w) {
    final n = _found.length;
    return Column(children: [
      PpSay(text: ppT(context, 'findThree'), width: min(w - 30 * s, 360 * s)),
      SizedBox(height: 4 * s),
      Expanded(
        child: LayoutBuilder(builder: (_, c) {
          final sz = _fit(c.maxWidth - 24 * s, c.maxHeight - 8 * s);
          return Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
            _shaking(
              'pic',
              _framed(
                sz,
                InteractiveViewer(
                  minScale: 1,
                  maxScale: 3.5,
                  clipBehavior: Clip.hardEdge,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (e) => _tapPicture(e.localPosition, sz),
                    child: SizedBox(
                      width: sz.width,
                      height: sz.height,
                      child: Stack(clipBehavior: Clip.none, children: [
                        Positioned.fill(child: Image.asset(_st.scene, fit: BoxFit.fill)),
                        for (final d in _st.details)
                          if (_found.contains(d.id) || _hintId == d.id) _foundMark(d, sz, s, hint: !_found.contains(d.id)),
                        if (_missAt != null)
                          Positioned(
                            left: _missAt!.dx - 18 * s,
                            top: _missAt!.dy - 18 * s,
                            child: IgnorePointer(child: Icon(Icons.close_rounded, color: ppRed, size: 36 * s)),
                          ),
                        Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(animation: _burst, builder: (_, __) => CustomPaint(painter: PpBurst(_burst.value))))),
                      ]),
                    ),
                  ),
                ),
                s,
              ),
            ),
            PositionedDirectional(
              start: 0,
              bottom: -8 * s,
              child: _robotBubble(s, 'pp_robot', 92 * s, min(w * 0.38, 140 * s)),
            ),
          ]);
        }),
      ),
      SizedBox(height: 6 * s),
      // the three details to find
      Container(
        margin: EdgeInsets.symmetric(horizontal: 12 * s),
        padding: EdgeInsets.fromLTRB(10 * s, 8 * s, 10 * s, 8 * s),
        decoration: BoxDecoration(
          color: ppCream,
          borderRadius: BorderRadius.circular(22 * s),
          border: Border.all(color: const Color(0xFFF1D7A6), width: 3 * s),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            for (final d in _st.details)
              Column(children: [
                Stack(clipBehavior: Clip.none, children: [
                  _cropOf(d, 70 * s, done: _found.contains(d.id), active: _hintId == d.id),
                  if (_found.contains(d.id)) Positioned(right: -4 * s, bottom: -2 * s, child: Image.asset(pp('pp_check_big'), width: 26 * s)),
                ]),
                SizedBox(height: 2 * s),
                SizedBox(
                  width: 92 * s,
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text(d.name(context), style: ppText(12.5 * s))),
                ),
              ]),
          ]),
          SizedBox(height: 6 * s),
          Row(children: [
            Expanded(child: ppProgress(n, 3, double.infinity, s)),
            SizedBox(width: 8 * s),
            Text(ppT(context, 'found', {'n': n}), style: ppText(12.5 * s)),
          ]),
        ]),
      ),
      SizedBox(height: 6 * s),
      PpButton.main(ppT(context, 'cont'), n == 3 ? () => _goto(_Phase.puzzle) : null, min(w * 0.7, 270 * s), pulse: _idle),
      Padding(
        padding: EdgeInsets.only(top: 2 * s, bottom: 6 * s),
        child: Text('🔍 ${ppT(context, 'zoomTip')}', style: ppText(11 * s, color: ppInkSoft, weight: FontWeight.w600)),
      ),
    ]);
  }

  Widget _foundMark(PpDetail d, Size sz, double s, {bool hint = false}) {
    final r = max(d.r * sz.width * 1.35, 22 * s);
    final c = Offset(d.x * sz.width, d.y * sz.height);
    return Positioned(
      left: c.dx - r,
      top: c.dy - r,
      width: r * 2,
      height: r * 2,
      child: IgnorePointer(
        child: hint
            ? AnimatedBuilder(
                animation: _idle,
                builder: (_, __) => Opacity(
                  opacity: 0.4 + 0.6 * sin(_idle.value * 2 * pi * 4).abs(),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFE04A), width: 4 * s),
                      boxShadow: [BoxShadow(color: const Color(0xFFFFE04A).withOpacity(0.8), blurRadius: 12 * s)],
                    ),
                  ),
                ),
              )
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (_, v, ch) => Transform.scale(scale: v, child: ch),
                child: Image.asset(pp('pp_ring'), fit: BoxFit.contain),
              ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 3. Puzzle — "La carte postale à reconstituer"
  // ═════════════════════════════════════════════════════════════════════════

  Widget _puzzleView(double s, double w) {
    final (cols, rows) = _grid;
    final total = cols * rows;
    final done = _placed.length == total;
    return Column(children: [
      PpSay(text: ppT(context, 'slide'), width: min(w - 30 * s, 360 * s)),
      SizedBox(height: 6 * s),
      Expanded(
        flex: 5,
        child: LayoutBuilder(builder: (_, c) {
          final sz = _fit(c.maxWidth - 40 * s, c.maxHeight - 10 * s);
          final cw = sz.width / cols, ch = sz.height / rows;
          return Center(
            child: Container(
              padding: EdgeInsets.all(10 * s),
              decoration: BoxDecoration(
                color: const Color(0xFFE9B56B),
                borderRadius: BorderRadius.circular(22 * s),
                border: Border.all(color: const Color(0xFFC98A3C), width: 3 * s),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12 * s, offset: Offset(0, 5 * s))],
              ),
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFF7E7C8), borderRadius: BorderRadius.circular(10 * s)),
                child: SizedBox(
                  width: sz.width,
                  height: sz.height,
                  child: Stack(children: [
                    // faint model
                    Positioned.fill(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _model ? 0.22 : 0,
                        child: ClipRRect(borderRadius: BorderRadius.circular(10 * s), child: Image.asset(_st.scene, fit: BoxFit.fill)),
                      ),
                    ),
                    for (var cell = 0; cell < total; cell++)
                      Positioned(
                        left: (cell % cols) * cw,
                        top: (cell ~/ cols) * ch,
                        width: cw,
                        height: ch,
                        child: _cell(cell, cols, rows, cw, ch, s),
                      ),
                    Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(animation: _burst, builder: (_, __) => CustomPaint(painter: PpBurst(_burst.value))))),
                  ]),
                ),
              ),
            ),
          );
        }),
      ),
      SizedBox(height: 6 * s),
      // tray of pieces
      Expanded(
        flex: 3,
        child: LayoutBuilder(builder: (_, c) {
          final left = [for (final p in _pieces) if (!_placed.contains(p)) p];
          final aspectPiece = _st.aspect * rows / cols;
          final perRow = min(left.length, total <= 4 ? 4 : (total <= 6 ? 3 : 5)).clamp(1, 9);
          final lines = (left.length / perRow).ceil().clamp(1, 9);
          var pw = (c.maxWidth - 60 * s) / perRow - 8 * s;
          var ph = pw / aspectPiece;
          final maxH = (c.maxHeight - 24 * s) / lines - 8 * s;
          if (ph > maxH) {
            ph = maxH;
            pw = ph * aspectPiece;
          }
          return Row(children: [
            SizedBox(width: 6 * s),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(8 * s),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2D19A),
                  borderRadius: BorderRadius.circular(18 * s),
                  border: Border.all(color: const Color(0xFFC98A3C), width: 3 * s),
                ),
                child: Center(
                  child: done
                      ? Column(mainAxisSize: MainAxisSize.min, children: [
                          Image.asset(pp('pp_check_big'), height: min(70 * s, c.maxHeight * 0.5)),
                          Text(ppT(context, 'allPlaced'), textAlign: TextAlign.center, style: ppText(14 * s, color: ppGreen)),
                        ])
                      : Wrap(alignment: WrapAlignment.center, spacing: 8 * s, runSpacing: 8 * s, children: [
                          for (final p in left) _trayPiece(p, cols, rows, pw, ph, s),
                        ]),
                ),
              ),
            ),
            SizedBox(width: 6 * s),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              PpPress(
                onTap: () {
                  ppSound(context, 'toggleButton');
                  setState(() => _model = !_model);
                },
                label: ppT(context, 'model'),
                child: Opacity(opacity: _model ? 1 : 0.6, child: Image.asset(pp('pp_eye_btn'), width: 50 * s)),
              ),
              Text(ppT(context, 'model'), style: ppText(10.5 * s)),
              SizedBox(height: 6 * s),
              PpPress(
                onTap: () {
                  ppSound(context, 'cancelButton');
                  setState(() {
                    _placed.clear();
                    _pieces.shuffle(_rng);
                    _picked = null;
                    _model = true;
                  });
                },
                label: ppT(context, 'restart'),
                child: Image.asset(pp('pp_replay_btn'), width: 50 * s),
              ),
              Text(ppT(context, 'restart'), style: ppText(10.5 * s)),
            ]),
            SizedBox(width: 6 * s),
          ]);
        }),
      ),
      SizedBox(height: 4 * s),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 30 * s),
        child: Row(children: [
          Expanded(child: ppProgress(_placed.length, total, double.infinity, s)),
          SizedBox(width: 8 * s),
          Text(ppT(context, 'placed', {'n': _placed.length, 'm': total}), style: ppText(12 * s)),
        ]),
      ),
      SizedBox(height: 6 * s),
      PpButton.main(ppT(context, 'validate'), done ? () => _goto(_Phase.stamp) : null, min(w * 0.7, 270 * s), pulse: _idle),
      SizedBox(height: 8 * s),
    ]);
  }

  Widget _cell(int cell, int cols, int rows, double cw, double ch, double s) {
    final filled = _placed.contains(cell);
    return _shaking(
      'cell$cell',
      DragTarget<int>(
        onWillAcceptWithDetails: (_) => !filled,
        onAcceptWithDetails: (d) => _place(d.data, cell),
        builder: (_, cand, __) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_picked != null && !filled) _place(_picked!, cell);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.all(filled ? 0.5 : 2 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8 * s),
              border: filled
                  ? null
                  : Border.all(
                      color: cand.isNotEmpty || (_picked != null) ? const Color(0xFF39D2FF) : const Color(0xFFC9A46A),
                      width: (cand.isNotEmpty ? 3 : 1.6) * s,
                    ),
              color: cand.isNotEmpty ? const Color(0x5539D2FF) : null,
              boxShadow: _flashCell == cell ? [BoxShadow(color: const Color(0xFFFFE04A).withOpacity(0.9), blurRadius: 14 * s, spreadRadius: 2 * s)] : null,
            ),
            child: filled
                ? TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.6, end: 1),
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutBack,
                    builder: (_, v, c) => Transform.scale(scale: v, child: c),
                    child: PpPiece(stage: _st, col: cell % cols, row: cell ~/ cols, cols: cols, rows: rows, w: cw - 1, h: ch - 1),
                  )
                : Center(child: Icon(Icons.explore_outlined, color: const Color(0xFFD7B47A), size: min(cw, ch) * 0.3)),
          ),
        ),
      ),
    );
  }

  Widget _trayPiece(int p, int cols, int rows, double pw, double ph, double s) {
    final sel = _picked == p;
    Widget art(double k) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8 * s),
            border: Border.all(color: sel ? const Color(0xFF39D2FF) : Colors.white, width: 3 * s),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 5 * s, offset: Offset(0, 2 * s))],
          ),
          child: PpPiece(stage: _st, col: p % cols, row: p ~/ cols, cols: cols, rows: rows, w: pw * k, h: ph * k),
        );
    return Draggable<int>(
      data: p,
      feedback: Material(type: MaterialType.transparency, child: Transform.rotate(angle: 0.05, child: art(1.15))),
      childWhenDragging: Opacity(opacity: 0.25, child: art(1)),
      onDragStarted: () => ppSound(context, 'clickButton'),
      child: GestureDetector(
        onTap: () {
          ppSound(context, 'clickButton');
          setState(() => _picked = sel ? null : p);
        },
        child: AnimatedScale(scale: sel ? 1.08 : 1, duration: const Duration(milliseconds: 180), child: art(1)),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 4. Stamp — "Un nouveau tampon !"
  // ═════════════════════════════════════════════════════════════════════════

  Widget _stampView(double s, double w) => Column(children: [
        Expanded(
          child: LayoutBuilder(builder: (_, c) {
            final bw = min(c.maxWidth - 16 * s, (c.maxHeight - 20 * s) / 0.6867);
            final bh = bw * 0.6867;
            final circle = Offset(bw * 0.696, bh * 0.53);
            final cr = bw * 0.135;
            final stamperH = bw * 0.36;
            return Center(
              child: SizedBox(
                width: bw,
                height: bh,
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned.fill(child: Image.asset(pp('pp_book_stamp'), fit: BoxFit.fill)),
                  // left page: the postcard + "my discovery"
                  Positioned(
                    left: bw * 0.18,
                    top: bh * 0.22,
                    width: bw * 0.275,
                    height: bh * 0.4,
                    child: Transform.rotate(
                      angle: -0.04,
                      child: Container(
                        padding: EdgeInsets.all(4 * s),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6 * s), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                        child: ClipRRect(borderRadius: BorderRadius.circular(4 * s), child: Image.asset(_st.scene, fit: BoxFit.cover)),
                      ),
                    ),
                  ),
                  Positioned(
                    left: bw * 0.15,
                    width: bw * 0.33,
                    top: bh * 0.64,
                    height: bh * 0.16,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(ppT(context, 'myDiscovery'), style: ppText(13 * s, color: ppInkSoft)),
                        Text(_st.city(context), style: ppText(20 * s, weight: FontWeight.w800)),
                      ]),
                    ),
                  ),
                  // right page: the stamp
                  if (!_stamped)
                    Positioned(
                      left: circle.dx - cr,
                      top: circle.dy + cr * 1.05,
                      width: cr * 2,
                      child: FittedBox(fit: BoxFit.scaleDown, child: Text(ppT(context, 'souvenirSlot'), style: ppText(12 * s, color: const Color(0xFFB08A50)))),
                    ),
                  if (_stamped)
                    Positioned(
                      left: circle.dx - cr * 1.1,
                      top: circle.dy - cr * 1.1,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.6, end: 1),
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutBack,
                        builder: (_, v, ch) => Transform.scale(scale: v, child: ch),
                        child: PpStamp(stage: _st, size: cr * 2.2),
                      ),
                    ),
                  Positioned(
                    left: circle.dx - cr * 2,
                    top: circle.dy - cr * 2,
                    width: cr * 4,
                    height: cr * 4,
                    child: IgnorePointer(child: AnimatedBuilder(animation: _burst, builder: (_, __) => CustomPaint(painter: PpBurst(_burst.value, seed: 9)))),
                  ),
                  // the stamper
                  AnimatedBuilder(
                    animation: Listenable.merge([_idle, _stampAnim]),
                    builder: (_, ch) {
                      final t = _stampAnim.value;
                      // down fast, squash, back up
                      final down = t < 0.45 ? Curves.easeIn.transform(t / 0.45) : (t < 0.6 ? 1.0 : 1 - Curves.easeOut.transform((t - 0.6) / 0.4));
                      final rest = _stamped ? -bh * 0.05 : -stamperH * 0.55;
                      final y = rest + (circle.dy - stamperH * 0.78 - rest) * down + (t == 0 && !_stamped ? sin(_idle.value * 2 * pi * 3) * 5 * s : 0);
                      final squash = (t > 0.42 && t < 0.62) ? 0.92 : 1.0;
                      return Positioned(
                        left: circle.dx - stamperH * 0.38 + (_stamped ? bw * 0.18 : 0),
                        top: y,
                        child: Transform.scale(scaleY: squash, alignment: Alignment.bottomCenter, child: ch),
                      );
                    },
                    child: GestureDetector(onTap: _doStamp, child: Image.asset(pp('pp_stamper'), height: stamperH)),
                  ),
                  // hand pointing at the stamper
                  if (!_stamped && !_stampAnim.isAnimating)
                    Positioned(
                      left: circle.dx + cr * 0.2,
                      top: circle.dy - cr * 0.1,
                      child: IgnorePointer(child: _bob(Image.asset(pp('pp_hand_curve'), width: cr * 1.3), amp: 6, speed: 3)),
                    ),
                ]),
              ),
            );
          }),
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          SizedBox(width: 6 * s),
          _robotBubble(s, 'pp_robot_point', 96 * s, min(w * 0.46, 170 * s)),
          const Spacer(),
          Image.asset(pp('pp_compass2'), height: 60 * s),
          SizedBox(width: 10 * s),
        ]),
        SizedBox(height: 6 * s),
        PpButton.main(
          ppT(context, _stamped ? 'cont' : 'stampBtn'),
          _stamped ? _win : _doStamp,
          min(w * 0.72, 280 * s),
          pulse: _idle,
        ),
        Padding(
          padding: EdgeInsets.only(top: 2 * s, bottom: 8 * s),
          child: Text('✦ ${ppT(context, 'souvenir')} ✦', style: ppText(12 * s, color: ppInkSoft, weight: FontWeight.w600)),
        ),
      ]);
}

// ═════════════════════════════════════════════════════════════════════════════
// Dialogs
// ═════════════════════════════════════════════════════════════════════════════

class _GoodDialog extends StatelessWidget {
  const _GoodDialog();
  @override
  Widget build(BuildContext context) => PpFrame(child: Builder(builder: _page));
  Widget _page(BuildContext context) {
    final s = ppScale(context);
    PpVoice.say(context, '${ppT(context, 'goodT')} ${ppT(context, 'goodSub')}');
    return PpDialog(
      title: ppT(context, 'goodT'),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Image.asset(pp('pp_rb_thumb'), height: 120 * s),
          SizedBox(width: 10 * s),
          Image.asset(pp('pp_check_big'), height: 90 * s),
        ]),
        SizedBox(height: 8 * s),
        ppNote(ppT(context, 'goodSub'), s),
        SizedBox(height: 12 * s),
        ppFlat(ppT(context, 'cont'), () => Navigator.pop(context), 230 * s),
      ]),
    );
  }
}

class _HintDialog extends StatelessWidget {
  final String message;
  final Widget? extra;
  const _HintDialog({required this.message, this.extra});
  @override
  Widget build(BuildContext context) => PpFrame(child: Builder(builder: _page));
  Widget _page(BuildContext context) {
    final s = ppScale(context);
    return PpDialog(
      title: ppT(context, 'hintT'),
      blue: true,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Image.asset(pp('pp_rb_magnif'), height: 110 * s),
          SizedBox(width: 8 * s),
          extra ?? Image.asset(pp('pp_bulb'), height: 80 * s),
        ]),
        SizedBox(height: 8 * s),
        ppNote(message, s),
        SizedBox(height: 12 * s),
        ppFlat(ppT(context, 'understood'), () => Navigator.pop(context), 230 * s, teal: true),
      ]),
    );
  }
}

class _PauseDialog extends StatelessWidget {
  const _PauseDialog();
  @override
  Widget build(BuildContext context) => PpFrame(child: Builder(builder: _page));
  Widget _page(BuildContext context) {
    final s = ppScale(context);
    return PpDialog(
      title: ppT(context, 'pauseT'),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Image.asset(pp('pp_rb_sleep'), height: 120 * s),
        SizedBox(height: 6 * s),
        ppNote(ppT(context, 'pauseSub'), s),
        SizedBox(height: 12 * s),
        ppFlat(ppT(context, 'resume'), () => Navigator.pop(context, 'resume'), 240 * s),
        SizedBox(height: 6 * s),
        ppFlat(ppT(context, 'restart'), () => Navigator.pop(context, 'restart'), 240 * s, teal: true),
        TextButton.icon(
          onPressed: () => Navigator.pop(context, 'home'),
          icon: Image.asset(pp('pp_pin'), height: 22 * s),
          label: Text(ppT(context, 'myDest'), style: ppText(14 * s).copyWith(decoration: TextDecoration.underline)),
        ),
      ]),
    );
  }
}

class _QuitDialog extends StatelessWidget {
  const _QuitDialog();
  @override
  Widget build(BuildContext context) => PpFrame(child: Builder(builder: _page));
  Widget _page(BuildContext context) {
    final s = ppScale(context);
    return PpDialog(
      title: ppT(context, 'quitT'),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Image.asset(pp('pp_map_old'), height: 100 * s),
        SizedBox(height: 6 * s),
        ppNote(ppT(context, 'quitSub'), s),
        SizedBox(height: 12 * s),
        ppFlat(ppT(context, 'keep'), () => Navigator.pop(context, false), 250 * s),
        SizedBox(height: 6 * s),
        ppFlat(ppT(context, 'quit'), () => Navigator.pop(context, true), 250 * s, teal: true),
      ]),
    );
  }
}

/// Full-screen picture with pinch-zoom ("Voir de plus près").
class _ZoomDialog extends StatelessWidget {
  final PpStage stage;
  const _ZoomDialog({required this.stage});
  @override
  Widget build(BuildContext context) => PpFrame(child: Builder(builder: _page));
  Widget _page(BuildContext context) {
    final s = ppScale(context);
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width - 24, 480.0);
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: w,
            constraints: BoxConstraints(maxHeight: size.height * 0.72),
            padding: EdgeInsets.all(6 * s),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24 * s)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18 * s),
              child: AspectRatio(
                aspectRatio: stage.aspect,
                child: InteractiveViewer(maxScale: 4, child: Image.asset(stage.scene, fit: BoxFit.cover)),
              ),
            ),
          ),
          SizedBox(height: 8 * s),
          Text('🔍 ${ppT(context, 'zoomTip')}', style: ppText(14 * s, color: Colors.white)),
          SizedBox(height: 8 * s),
          ppRound(context, 'pp_ic_close', 56 * s, () => Navigator.pop(context)),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// End screen — "Bravo, petit explorateur !"
// ═════════════════════════════════════════════════════════════════════════════

class _EndPage extends StatefulWidget {
  final PpStage stage;
  final int stars, gold, gems;
  final bool badge, last;
  const _EndPage({required this.stage, required this.stars, required this.gold, required this.gems, required this.badge, required this.last});
  @override
  State<_EndPage> createState() => _EndPageState();
}

class _EndPageState extends State<_EndPage> with TickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _a.dispose();
    _idle.dispose();
    super.dispose();
  }

  Widget _pop(double a, double b, Widget child) {
    final an = CurvedAnimation(parent: _a, curve: Interval(a, b, curve: Curves.easeOutBack));
    return AnimatedBuilder(
      animation: an,
      builder: (_, c) => Opacity(opacity: an.value.clamp(0.0, 1.0), child: Transform.scale(scale: 0.4 + 0.6 * an.value, child: c)),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) => PpFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = ppScale(context);
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 520.0);
    final st = widget.stage;
    final checkW = min(w * 0.7, 270 * s);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF8FD3F5),
        body: Stack(children: [
          const Positioned.fill(child: PpBg(asset: 'pp_bg_win')),
          Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(animation: _idle, builder: (_, __) => CustomPaint(painter: PpConfetti(_idle.value))))),
          SafeArea(
            child: Center(
              child: SizedBox(
                width: w,
                child: Column(children: [
                  _pop(0, 0.3, PpCloudTitle(a: ppT(context, 'bravo1'), b: ppT(context, 'bravo2'), width: min(w * 0.82, 330 * s), confetti: true)),
                  Transform.translate(
                    offset: Offset(0, -12 * s),
                    child: _pop(
                      0.1,
                      0.35,
                      ppOnSprite('pp_ribbon_purple', min(w * 0.76, 290 * s), 0.3389,
                          Text(ppT(context, 'escaleDone', {'c': st.city(context)}), style: ppText(16 * s, color: Colors.white, weight: FontWeight.w800)),
                          area: const EdgeInsets.fromLTRB(0.16, 0.08, 0.16, 0.38)),
                    ),
                  ),
                  _pop(0.25, 0.55, _stars(s, min(w * 0.6, 220 * s))),
                  Expanded(
                    child: LayoutBuilder(builder: (_, c) {
                      final h = c.maxHeight;
                      return Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
                        Positioned(bottom: h * 0.05, child: _pop(0.35, 0.65, PpStamp(stage: st, size: min(h * 0.75, 130 * s)))),
                        PositionedDirectional(
                          start: 0,
                          bottom: 0,
                          child: AnimatedBuilder(
                            animation: _idle,
                            builder: (_, ch) => Transform.translate(offset: Offset(0, -sin(_idle.value * 2 * pi * 3).abs() * 10 * s), child: ch),
                            child: Image.asset(pp('pp_rb_jump'), height: min(h * 0.95, 150 * s)),
                          ),
                        ),
                        PositionedDirectional(
                          end: 0,
                          bottom: 0,
                          child: AnimatedBuilder(
                            animation: _idle,
                            builder: (_, ch) => Transform.translate(offset: Offset(0, -sin(_idle.value * 2 * pi * 3 + 1).abs() * 10 * s), child: ch),
                            child: Image.asset(pp('pp_kid_jump'), height: min(h * 0.85, 135 * s)),
                          ),
                        ),
                      ]);
                    }),
                  ),
                  _pop(
                    0.45,
                    0.75,
                    SizedBox(
                      width: checkW,
                      height: checkW * 0.7283,
                      child: Stack(children: [
                        Positioned.fill(child: Image.asset(pp('pp_checklist'), fit: BoxFit.fill)),
                        for (var i = 0; i < 3; i++)
                          Positioned(
                            left: checkW * 0.33,
                            right: checkW * 0.25,
                            top: checkW * 0.7283 * ([0.316, 0.537, 0.758][i] - 0.08),
                            height: checkW * 0.7283 * 0.16,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: FittedBox(fit: BoxFit.scaleDown, child: Text(ppT(context, 'c$i'), style: ppText(15 * s))),
                            ),
                          ),
                      ]),
                    ),
                  ),
                  SizedBox(height: 6 * s),
                  _pop(0.55, 0.85, _rewards(s, w)),
                  SizedBox(height: 8 * s),
                  _pop(
                    0.7,
                    1.0,
                    Column(children: [
                      widget.last
                          ? PpButton.main(ppT(context, 'allDone'), () => Navigator.pop(context, 'passport'), min(w * 0.84, 330 * s), pulse: _idle)
                          : PpButton.main(ppT(context, 'nextStop'), () => Navigator.pop(context, 'next'), min(w * 0.76, 300 * s), pulse: _idle),
                      SizedBox(height: 6 * s),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        PpPill(
                          label: ppT(context, 'myPassport'),
                          icon: Image.asset(pp('pp_passport_book'), height: 24 * s),
                          onTap: () => Navigator.pop(context, 'passport'),
                          s: s,
                          border: const Color(0xFF2B3FA8),
                          font: 14,
                        ),
                        SizedBox(width: 8 * s),
                        PpPill(
                          label: ppT(context, 'replay'),
                          icon: Icon(Icons.replay_rounded, color: ppInk, size: 22 * s),
                          onTap: () => Navigator.pop(context, 'again'),
                          s: s,
                          border: const Color(0xFF2B3FA8),
                          font: 14,
                        ),
                      ]),
                    ]),
                  ),
                  SizedBox(height: 8 * s),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _stars(double s, double width) {
    final h = width * 0.4139;
    final img = Image.asset(pp('pp_stars3'), width: width, height: h, fit: BoxFit.fill);
    return AnimatedBuilder(
      animation: _idle,
      builder: (_, c) => Transform.scale(scale: 1 + 0.03 * sin(_idle.value * 2 * pi * 2), child: c),
      child: SizedBox(
        width: width,
        height: h,
        child: Stack(children: [
          ColorFiltered(colorFilter: const ColorFilter.mode(Color(0xFFCFC6B3), BlendMode.srcIn), child: Opacity(opacity: 0.6, child: img)),
          ClipRect(child: Align(alignment: Alignment.centerLeft, widthFactor: widget.stars / 3, child: img)),
        ]),
      ),
    );
  }

  Widget _rewards(double s, double w) {
    Widget chip(String art, String text, Color c) => Container(
          padding: EdgeInsets.fromLTRB(6 * s, 4 * s, 14 * s, 4 * s),
          decoration: BoxDecoration(
            color: ppCream,
            borderRadius: BorderRadius.circular(20 * s),
            border: Border.all(color: const Color(0xFFF0C77A), width: 2 * s),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Image.asset(pp(art), height: 40 * s),
            SizedBox(width: 4 * s),
            Text(text, style: ppText(20 * s, color: c, weight: FontWeight.w800)),
          ]),
        );
    return Column(children: [
      Text(ppT(context, 'rewards'), style: ppText(15 * s, color: Colors.white).copyWith(shadows: const [Shadow(color: Color(0xAA3B1A9A), blurRadius: 4)])),
      SizedBox(height: 4 * s),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        chip('pp_coin', '+${widget.gold}', const Color(0xFFB66A00)),
        SizedBox(width: 8 * s),
        chip('pp_gem', '+${widget.gems}', ppBlue),
        if (widget.badge) ...[
          SizedBox(width: 8 * s),
          AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.rotate(angle: sin(_idle.value * 2 * pi * 2) * 0.05, child: c),
            child: SizedBox(
              width: 96 * s,
              height: 96 * s * 0.77,
              child: Stack(children: [
                Positioned.fill(child: Image.asset(pp('pp_badge'), fit: BoxFit.fill)),
                Positioned(
                  left: 96 * s * 0.12,
                  right: 96 * s * 0.12,
                  bottom: 96 * s * 0.77 * 0.06,
                  height: 96 * s * 0.77 * 0.2,
                  child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(ppT(context, 'badgeName'), style: ppText(11 * s, color: const Color(0xFF6B3A00))))),
                ),
              ]),
            ),
          ),
        ],
      ]),
    ]);
  }
}
