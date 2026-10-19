import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

import 'bb_common.dart';
import 'bb_engine.dart';

/// One Brain Builder level: guide Robo through the maze to the big star.
class BrainBuilderGame extends StatefulWidget {
  final int level;
  const BrainBuilderGame({super.key, required this.level});

  @override
  State<BrainBuilderGame> createState() => _BrainBuilderGameState();
}

class _HintMark {
  final int cell;
  final BBDir dir;
  const _HintMark(this.cell, this.dir);
}

class _BrainBuilderGameState extends State<BrainBuilderGame> with TickerProviderStateMixin {
  // Inner play area of the board sprite, as fractions of its size.
  static const double _inL = 0.1067, _inT = 0.1161, _inR = 0.8787, _inB = 0.8887;
  static const double _wallF = 0.2; // wall thickness relative to a cell
  static const int _hintCost = 10;

  late final BBLevel _lvl = bbLevel(widget.level);
  late int _pos = _lvl.start;
  int _mask = 0;
  int _moves = 0;
  final Set<int> _trail = {};
  List<_HintMark> _hint = const [];
  int _hintsLeft = 3;
  int _prevStars = 0;
  int _potential = 3;
  bool _busy = false;
  bool _won = false;
  bool _stuck = false;
  bool _faceLeft = false;
  BBDir? _queued;
  BBDir _bumpDir = BBDir.up;
  int _gen = 0; // bumps on reset so stale move callbacks are ignored
  Duration _moveDur = const Duration(milliseconds: 160);
  Curve _moveCurve = Curves.easeOutCubic;
  String? _tipKey;
  Timer? _tipTimer;
  Offset _drag = Offset.zero;
  bool _dragFired = false;

  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  late final AnimationController _bump = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  late final AnimationController _cheer = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final ConfettiController _confetti = ConfettiController(duration: const Duration(seconds: 2));
  final FocusNode _focus = FocusNode();

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);
  bool get _gotAll => _mask == _lvl.fullMask;

  @override
  void initState() {
    super.initState();
    _trail.add(_pos);
    BBProgress.starsOf(widget.level).then((v) {
      if (mounted) setState(() => _prevStars = v);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final a in BBAssets.all) {
      precacheImage(AssetImage(a), context);
    }
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _idle.dispose();
    _bump.dispose();
    _cheer.dispose();
    _confetti.dispose();
    _focus.dispose();
    super.dispose();
  }

  // ─── Game logic ──────────────────────────────────────────────────────────

  void _say(String key, {bool sticky = false}) {
    _tipTimer?.cancel();
    setState(() => _tipKey = key);
    if (!sticky) {
      _tipTimer = Timer(const Duration(milliseconds: 2400), () {
        if (mounted && !_stuck) setState(() => _tipKey = null);
      });
    }
  }

  int _starsFor(int total) {
    final o = _lvl.optimal;
    if (total <= o) return 3;
    if (total <= o + max(2, (o * 0.5).ceil())) return 2;
    return 1;
  }

  void _move(BBDir d) {
    if (_won) return;
    if (_busy) {
      _queued = d;
      return;
    }
    if (d == BBDir.left) _faceLeft = true;
    if (d == BBDir.right) _faceLeft = false;
    final st = _lvl.step(_pos, _mask, d);
    if (st == null) {
      _bumpDir = d;
      _bump.forward(from: 0);
      HapticFeedback.lightImpact();
      _audio.playEventSound('invalid');
      _say('bump');
      return;
    }
    _audio.playEventSound('clickButton');
    if (_hint.isNotEmpty) {
      _hint = (_hint.first.cell == _pos && _hint.first.dir == d) ? _hint.sublist(1) : const [];
    }
    final per = _lvl.slides ? 90 : 170;
    final gen = _gen;
    setState(() {
      _busy = true;
      _moveDur = Duration(milliseconds: per * st.path.length + (_lvl.slides ? 80 : 0));
      _moveCurve = _lvl.slides ? Curves.easeOutBack : Curves.easeOutCubic;
      _pos = st.to;
      _moves++;
    });
    for (var k = 0; k < st.path.length; k++) {
      final cell = st.path[k];
      Future.delayed(Duration(milliseconds: per * (k + 1) - per ~/ 3), () {
        if (!mounted || gen != _gen) return;
        setState(() => _trail.add(cell));
        final gi = _lvl.gems.indexOf(cell);
        if (gi >= 0 && _mask & (1 << gi) == 0) {
          setState(() => _mask |= 1 << gi);
          _audio.playEventSound('starSound');
          _say(_gotAll ? 'allStars' : 'gotStar');
        }
      });
    }
    Future.delayed(_moveDur, () {
      if (!mounted || gen != _gen) return;
      _afterMove(st);
    });
  }

  void _afterMove(BBStep st) {
    setState(() {
      _busy = false;
      _mask = st.mask;
    });
    if (_lvl.isWin(_pos, _mask)) {
      _win();
      return;
    }
    if (_pos == _lvl.goal && !_gotAll) _say('needStars');
    final rem = _lvl.solve(_pos, _mask);
    setState(() {
      _stuck = rem == null;
      _potential = _starsFor(_moves + (rem?.length ?? 999));
    });
    if (_stuck) {
      _queued = null;
      _say('stuck', sticky: true);
      return;
    }
    final q = _queued;
    _queued = null;
    if (q != null) _move(q);
  }

  void _restart() {
    _tipTimer?.cancel();
    setState(() {
      _gen++;
      _pos = _lvl.start;
      _mask = 0;
      _moves = 0;
      _trail
        ..clear()
        ..add(_lvl.start);
      _hint = const [];
      _busy = false;
      _won = false;
      _stuck = false;
      _queued = null;
      _potential = 3;
      _faceLeft = false;
      _tipKey = null;
      _moveDur = const Duration(milliseconds: 280);
      _moveCurve = Curves.easeInOut;
    });
  }

  void _useHint() {
    if (_won || _busy) return;
    if (_hintsLeft <= 0) {
      _buyHints();
      return;
    }
    final path = _lvl.solve(_pos, _mask);
    if (path == null) {
      _say('stuck', sticky: true);
      return;
    }
    final marks = <_HintMark>[];
    var p = _pos, m = _mask;
    for (final d in path.take(3)) {
      marks.add(_HintMark(p, d));
      final st = _lvl.step(p, m, d)!;
      p = st.to;
      m = st.mask;
    }
    _audio.playEventSound('PopButton');
    setState(() {
      _hint = marks;
      _hintsLeft--;
    });
    _say('hintTip');
  }

  Future<void> _buyHints() async {
    _audio.playEventSound('clickButton2');
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: KidColors.purpleDeep.withOpacity(0.35),
      builder: (ctx) => KidDialog(
        headerAsset: BBAssets.bulb,
        headerAspect: 93 / 115,
        title: bbT(ctx, 'moreHints'),
        message: bbT(ctx, 'moreHintsMsg', {'n': _hintCost}),
        actions: [
          KidOutlineButton(label: bbT(ctx, 'cancel'), onTap: () => Navigator.pop(ctx, false)),
          const SizedBox(height: 10),
          KidButton(
            label: bbT(ctx, 'buy'),
            width: double.infinity,
            height: 54,
            showArrow: false,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    if (xp.gold < _hintCost) {
      _audio.playEventSound('invalid');
      _say('notEnough');
      return;
    }
    xp.spendGold(context, _hintCost);
    setState(() => _hintsLeft += 3);
    _useHint();
  }

  Future<void> _win() async {
    setState(() {
      _won = true;
      _hint = const [];
    });
    final stars = _starsFor(_moves);
    final gold = bbReward(widget.level, stars, _prevStars);
    final newStars = max(0, stars - _prevStars);
    await BBProgress.record(widget.level, stars, _moves);
    _cheer.forward(from: 0);
    _confetti.play();
    _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/${stars == 3 ? 'VictoryOrchestral_SFX' : 'victory2_SFX'}.mp3');
    await Future.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    if (gold > 0) xp.addGold(context, gold);
    if (newStars > 0) xp.addXP(4 + newStars * 3, context: context);
    final last = widget.level >= bbLevelCount;
    final result = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => _WinCard(
        stars: stars,
        moves: _moves,
        best: _lvl.optimal,
        gold: gold,
        last: last,
      ),
      transitionBuilder: (_, a, __, child) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: child),
      ),
    );
    if (!mounted) return;
    _prevStars = max(_prevStars, stars);
    switch (result) {
      case 'next':
        // Hand the next level back to the menu so it can save/refresh first.
        Navigator.pop(context, widget.level + 1);
      case 'replay':
        _restart();
      default:
        Navigator.pop(context);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final d = k == LogicalKeyboardKey.arrowUp
        ? BBDir.up
        : k == LogicalKeyboardKey.arrowDown
            ? BBDir.down
            : k == LogicalKeyboardKey.arrowLeft
                ? BBDir.left
                : k == LogicalKeyboardKey.arrowRight
                    ? BBDir.right
                    : null;
    if (d == null) return KeyEventResult.ignored;
    _move(d);
    return KeyEventResult.handled;
  }

  Future<void> _toggleSound() async {
    final a = _audio;
    final mute = !(a.isBgMuted && a.isSfxMuted);
    if (a.isBgMuted != mute) await a.toggleBgMute();
    if (a.isSfxMuted != mute) await a.toggleSfxMute();
    if (!mute) a.playEventSound('toggleButton');
    if (mounted) setState(() {});
  }

  // ─── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8FD3FF),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(BBAssets.bg, fit: BoxFit.cover)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withOpacity(0.18), Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.22)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Focus(
              focusNode: _focus,
              autofocus: true,
              onKeyEvent: _onKey,
              child: LayoutBuilder(builder: _layout),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 28,
              emissionFrequency: 0.06,
              gravity: 0.25,
              colors: const [Color(0xFFFFC93C), Color(0xFF7B3FE4), Color(0xFF34D2F5), Color(0xFFFF6FB5), Color(0xFF4ADE80)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _layout(BuildContext context, BoxConstraints c) {
    final width = min(c.maxWidth, 560.0);
    final s = min(width / 400, c.maxHeight / 840).clamp(0.62, 1.4).toDouble();
    return Center(
      child: SizedBox(
        width: width,
        child: Column(
          children: [
            SizedBox(height: 4 * s),
            _header(s),
            SizedBox(height: 4 * s),
            Padding(padding: EdgeInsets.symmetric(horizontal: 16 * s), child: _statsPill(s)),
            SizedBox(height: 8 * s),
            Padding(padding: EdgeInsets.symmetric(horizontal: 26 * s), child: _instruction(s)),
            SizedBox(height: 4 * s),
            Expanded(
              child: LayoutBuilder(
                builder: (_, bc) => Center(child: _board(bc.maxWidth - 12 * s, bc.maxHeight)),
              ),
            ),
            SizedBox(height: 2 * s),
            _movesRow(s),
            SizedBox(height: 194 * s, child: _controls(s)),
            SizedBox(height: 4 * s),
          ],
        ),
      ),
    );
  }

  Widget _header(double s) {
    final a = _audio;
    final muted = a.isBgMuted && a.isSfxMuted;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12 * s),
      child: Row(
        children: [
          BBSpriteButton(
            asset: BBAssets.back,
            size: 52 * s,
            flipRtl: true,
            label: MaterialLocalizations.of(context).backButtonTooltip,
            onTap: () {
              _audio.playEventSound('cancelButton');
              Navigator.maybePop(context);
            },
          ),
          Expanded(
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: BBTitle(bbT(context, 'title'), size: 36 * s)),
            ),
          ),
          BBSpriteButton(
            asset: BBAssets.sound,
            size: 52 * s,
            onTap: _toggleSound,
            overlay: muted ? CustomPaint(painter: _MutePainter()) : null,
          ),
        ],
      ),
    );
  }

  Widget _statsPill(double s) {
    final reward = bbReward(widget.level, _potential, _prevStars);
    return BBPill(
      height: 54 * s,
      padding: EdgeInsets.symmetric(horizontal: 8 * s),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 6 * s),
            decoration: BoxDecoration(color: const Color(0xFFE6E0FA), borderRadius: BorderRadius.circular(30)),
            child: Text(bbT(context, 'levelN', {'n': widget.level}),
                style: kidBodyStyle(17 * s, color: bbInk, weight: FontWeight.w700)),
          ),
          Expanded(child: Center(child: BBStars(count: _potential, size: 30 * s))),
          Container(width: 2, height: 28 * s, color: const Color(0xFFEDE3CF)),
          SizedBox(width: 10 * s),
          Image.asset(BBAssets.coin, width: 30 * s, height: 30 * s),
          SizedBox(width: 6 * s),
          Text(reward > 0 ? '+$reward' : '✓', style: kidBodyStyle(19 * s, color: bbInk, weight: FontWeight.w700)),
          SizedBox(width: 8 * s),
        ],
      ),
    );
  }

  Widget _instruction(double s) {
    final mode = _lvl.mode.name;
    final total = _lvl.gems.length;
    final got = [for (var g = 0; g < total; g++) if (_mask & (1 << g) != 0) g].length;
    return BBPill(
      radius: 26 * s,
      padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 7 * s),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(bbT(context, 'goal_$mode'),
                      maxLines: 1, style: kidBodyStyle(19 * s, color: bbInk, weight: FontWeight.w700)),
                ),
                Text(bbT(context, 'sub_$mode'),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: kidBodyStyle(13.5 * s, color: KidColors.inkSoft, weight: FontWeight.w600)),
              ],
            ),
          ),
          if (total > 0) ...[
            SizedBox(width: 8 * s),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
              decoration: BoxDecoration(
                color: got == total ? const Color(0xFFFFE9A6) : const Color(0xFFF1ECFF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Image.asset(BBAssets.star, width: 22 * s, height: 22 * s),
                SizedBox(width: 3 * s),
                Text('$got/$total', style: kidBodyStyle(15 * s, color: bbInk, weight: FontWeight.w700)),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _board(double aw, double ah) {
    final cols = _lvl.cols, rows = _lvl.rows;
    const fw = _inR - _inL, fh = _inB - _inT;
    final cell = min(aw * fw / (cols + _wallF), ah * fh / (rows + _wallF));
    final t = cell * _wallF;
    final bw = cell * (cols + _wallF) / fw, bh = cell * (rows + _wallF) / fh;
    return GestureDetector(
      onPanStart: (_) {
        _drag = Offset.zero;
        _dragFired = false;
      },
      onPanUpdate: (d) {
        if (_dragFired) return;
        _drag += d.delta;
        if (_drag.distance < max(22.0, cell * 0.35)) return;
        _dragFired = true;
        final dx = _drag.dx, dy = _drag.dy;
        _move(dx.abs() > dy.abs() ? (dx > 0 ? BBDir.right : BBDir.left) : (dy > 0 ? BBDir.down : BBDir.up));
      },
      child: SizedBox(
        width: bw,
        height: bh,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: Image.asset(BBAssets.board, fit: BoxFit.fill)),
            Positioned(
              left: bw * _inL,
              top: bh * _inT,
              width: cell * (cols + _wallF),
              height: cell * (rows + _wallF),
              child: Directionality(textDirection: TextDirection.ltr, child: _field(cell, t)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(double cell, double t) {
    Offset at(int i) => Offset(t / 2 + _lvl.col(i) * cell, t / 2 + _lvl.row(i) * cell);
    Widget inCell(int i, double f, Widget child) {
      final o = at(i);
      return Positioned(
        left: o.dx + cell * (1 - f) / 2,
        top: o.dy + cell * (1 - f) / 2,
        width: cell * f,
        height: cell * f,
        child: child,
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_idle, _bump, _cheer]),
      builder: (_, __) {
        final ph = _idle.value * 2 * pi;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _TilesPainter(_lvl.cols, _lvl.rows, cell, t)),
            ),
            for (final i in _trail)
              if (i != _lvl.goal)
                inCell(i, 0.9, Opacity(opacity: 0.5, child: Image.asset(BBAssets.glow, fit: BoxFit.fill))),
            for (var k = 0; k < _hint.length; k++)
              inCell(
                _hint[k].cell,
                0.9,
                Opacity(
                  opacity: (0.78 + 0.22 * sin(ph * 3 - k)).clamp(0.0, 1.0).toDouble(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(child: Image.asset(BBAssets.glow, fit: BoxFit.fill)),
                      Transform.rotate(
                        angle: _hint[k].dir.index * pi / 2,
                        child: Icon(Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: cell * 0.56,
                            shadows: const [Shadow(color: Color(0xFF0A7FA6), blurRadius: 5)]),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned.fill(child: CustomPaint(painter: _WallsPainter(_lvl, cell, t))),
            inCell(
              _lvl.goal,
              0.96,
              Transform.scale(
                scale: _gotAll ? 1 + 0.05 * sin(ph * 2) : 0.92,
                child: _gotAll
                    ? Image.asset(BBAssets.goal, fit: BoxFit.contain)
                    : Stack(
                        children: [
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.8,
                              child: ColorFiltered(colorFilter: _greyFilter, child: Image.asset(BBAssets.goal, fit: BoxFit.contain)),
                            ),
                          ),
                          Align(
                            alignment: const Alignment(0.8, 0.8),
                            child: Container(
                              padding: EdgeInsets.all(cell * 0.04),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Icon(Icons.lock_rounded, size: cell * 0.24, color: KidColors.purpleDeep),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            for (var g = 0; g < _lvl.gems.length; g++)
              inCell(
                _lvl.gems[g],
                0.66,
                AnimatedScale(
                  scale: _mask & (1 << g) != 0 ? 0 : 1,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInBack,
                  child: Transform.translate(
                    offset: Offset(0, sin(ph * 2 + g * 1.7) * cell * 0.05),
                    child: Image.asset(BBAssets.star, fit: BoxFit.contain),
                  ),
                ),
              ),
            _robot(cell, at),
          ],
        );
      },
    );
  }

  static const ColorFilter _greyFilter = ColorFilter.matrix([
    0.45, 0.45, 0.10, 0, 30, //
    0.40, 0.45, 0.15, 0, 30,
    0.40, 0.40, 0.30, 0, 60,
    0, 0, 0, 1, 0,
  ]);

  Widget _robot(double cell, Offset Function(int) at) {
    final rh = cell * 1.12, rw = rh * 157 / 237;
    final p = at(_pos);
    final b = _bump.value;
    final shake = _bump.isAnimating ? sin(b * pi * 4) * (1 - b) * cell * 0.12 : 0.0;
    final hop = _cheer.isAnimating ? -sin(_cheer.value * pi * 2).abs() * cell * 0.35 : 0.0;
    final bob = _busy ? 0.0 : sin(_idle.value * 2 * pi * 2) * cell * 0.025;
    return AnimatedPositioned(
      duration: _moveDur,
      curve: _moveCurve,
      left: p.dx + (cell - rw) / 2,
      top: p.dy + cell - rh - cell * 0.02,
      width: rw,
      height: rh,
      child: Transform.translate(
        offset: Offset(_bumpDir.dx * shake, _bumpDir.dy * shake + bob + hop),
        child: Transform.flip(flipX: _faceLeft, child: Image.asset(BBAssets.robot, fit: BoxFit.contain)),
      ),
    );
  }

  Widget _movesRow(double s) {
    final tip = _tipKey ?? 'tip';
    return Column(
      children: [
        BBPill(
          padding: EdgeInsets.symmetric(horizontal: 24 * s, vertical: 4 * s),
          child: Text(bbT(context, 'movesN', {'n': _moves}),
              style: kidBodyStyle(19 * s, color: bbInk, weight: FontWeight.w700)),
        ),
        SizedBox(height: 4 * s),
        SizedBox(
          height: 22 * s,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: a, child: c)),
            child: FittedBox(
              key: ValueKey(tip),
              fit: BoxFit.scaleDown,
              child: Text(
                bbT(context, tip),
                textAlign: TextAlign.center,
                style: kidBodyStyle(16 * s, color: _tipKey == 'stuck' ? const Color(0xFFD9214E) : bbInk, weight: FontWeight.w700)
                    .copyWith(shadows: const [Shadow(color: Colors.white, blurRadius: 6), Shadow(color: Colors.white, blurRadius: 14)]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _controls(double s) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 6 * s,
          top: 0,
          height: 118 * s,
          child: AnimatedBuilder(
            animation: Listenable.merge([_idle, _cheer]),
            builder: (_, c) => Transform.translate(
              offset: Offset(0, sin(_idle.value * 2 * pi) * 3 * s - (_cheer.isAnimating ? sin(_cheer.value * pi).abs() * 14 * s : 0)),
              child: c,
            ),
            child: Image.asset(BBAssets.robotPoint, fit: BoxFit.contain),
          ),
        ),
        Align(alignment: const Alignment(0, -0.35), child: _dpad(172 * s)),
        Positioned(left: 8 * s, bottom: 6 * s, child: _resetButton(s)),
        Positioned(right: 8 * s, bottom: 6 * s, child: _hintButton(s)),
      ],
    );
  }

  Widget _dpad(double w) {
    final h = w * 336 / 352;
    const pos = {
      BBDir.up: [0.4984, 0.2371],
      BBDir.right: [0.7653, 0.4875],
      BBDir.left: [0.2346, 0.4875],
      BBDir.down: [0.4985, 0.7385],
    };
    final d = w * 0.3394;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(BBAssets.plate, fit: BoxFit.fill)),
            for (final e in pos.entries)
              Positioned(
                left: e.value[0] * w - d / 2,
                top: e.value[1] * h - d / 2,
                width: d,
                height: d,
                child: _PadButton(asset: BBAssets.btn(e.key), onPress: () => _move(e.key)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _resetButton(double s) {
    return KidPressable(
      semanticLabel: bbT(context, 'reset'),
      onTap: () {
        _audio.playEventSound('clickButton2');
        _restart();
      },
      child: BBPill(
        height: 54 * s,
        padding: EdgeInsetsDirectional.only(start: 6 * s, end: 16 * s),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 118 * s),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(BBAssets.reset, width: 40 * s, height: 40 * s),
              SizedBox(width: 6 * s),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(bbT(context, 'reset'), style: kidBodyStyle(19 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hintButton(double s) {
    final empty = _hintsLeft <= 0;
    return KidPressable(
      semanticLabel: bbT(context, 'hint'),
      onTap: _useHint,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 56 * s,
            padding: EdgeInsetsDirectional.only(start: 8 * s, end: 18 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFE66B), Color(0xFFFFBE1A)],
              ),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: const Color(0xFFE08A00).withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 118 * s),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _idle,
                    builder: (_, c) => Transform.rotate(angle: sin(_idle.value * 2 * pi * 2) * 0.08, child: c),
                    child: Image.asset(BBAssets.bulb, height: 40 * s),
                  ),
                  SizedBox(width: 6 * s),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(bbT(context, 'hint'), style: kidBodyStyle(20 * s, color: bbInk, weight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            top: -10 * s,
            end: -6 * s,
            child: Container(
              width: 30 * s,
              height: 30 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: empty ? const Color(0xFF22B573) : KidColors.purple,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: empty
                  ? Icon(Icons.add_rounded, color: Colors.white, size: 18 * s)
                  : Text('$_hintsLeft', style: kidBodyStyle(15 * s, color: Colors.white, weight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

/// D-pad button: fires on press, repeats while held.
class _PadButton extends StatefulWidget {
  final String asset;
  final VoidCallback onPress;
  const _PadButton({required this.asset, required this.onPress});

  @override
  State<_PadButton> createState() => _PadButtonState();
}

class _PadButtonState extends State<_PadButton> {
  bool _down = false;
  Timer? _repeat;

  void _start() {
    setState(() => _down = true);
    widget.onPress();
    _repeat?.cancel();
    _repeat = Timer(const Duration(milliseconds: 380), () {
      _repeat = Timer.periodic(const Duration(milliseconds: 200), (_) => widget.onPress());
    });
  }

  void _stop() {
    _repeat?.cancel();
    _repeat = null;
    if (mounted) setState(() => _down = false);
  }

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _start(),
      onTapUp: (_) => _stop(),
      onTapCancel: _stop,
      child: AnimatedScale(
        scale: _down ? 0.88 : 1,
        duration: const Duration(milliseconds: 90),
        child: Image.asset(widget.asset, fit: BoxFit.contain),
      ),
    );
  }
}

/// Light cyan floor tiles with a soft grid.
class _TilesPainter extends CustomPainter {
  final int cols, rows;
  final double cell, t;
  _TilesPainter(this.cols, this.rows, this.cell, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final area = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(cell * 0.18));
    canvas.drawRRect(area, Paint()..color = const Color(0xFFC6F1F8));
    final alt = Paint()..color = const Color(0xFFB6EAF5);
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if ((r + c).isOdd) canvas.drawRect(Rect.fromLTWH(t / 2 + c * cell, t / 2 + r * cell, cell, cell), alt);
      }
    }
    final line = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = max(1.0, cell * 0.02);
    for (var c = 1; c < cols; c++) {
      final x = t / 2 + c * cell;
      canvas.drawLine(Offset(x, t / 2), Offset(x, size.height - t / 2), line);
    }
    for (var r = 1; r < rows; r++) {
      final y = t / 2 + r * cell;
      canvas.drawLine(Offset(t / 2, y), Offset(size.width - t / 2, y), line);
    }
  }

  @override
  bool shouldRepaint(_TilesPainter o) => o.cols != cols || o.rows != rows || o.cell != cell;
}

/// Glossy blue maze walls, matching the design sheet's wall pieces.
class _WallsPainter extends CustomPainter {
  final BBLevel lvl;
  final double cell, t;
  _WallsPainter(this.lvl, this.cell, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final segs = <Rect>[];
    for (var i = 0; i < lvl.cols * lvl.rows; i++) {
      final x = t / 2 + lvl.col(i) * cell, y = t / 2 + lvl.row(i) * cell;
      if (lvl.blocked(i, BBDir.up)) segs.add(Rect.fromLTRB(x, y, x + cell, y));
      if (lvl.blocked(i, BBDir.left)) segs.add(Rect.fromLTRB(x, y, x, y + cell));
      if (lvl.row(i) == lvl.rows - 1 && lvl.blocked(i, BBDir.down)) {
        segs.add(Rect.fromLTRB(x, y + cell, x + cell, y + cell));
      }
      if (lvl.col(i) == lvl.cols - 1 && lvl.blocked(i, BBDir.right)) {
        segs.add(Rect.fromLTRB(x + cell, y, x + cell, y + cell));
      }
    }
    final r = Radius.circular(t * 0.5);
    RRect rr(Rect s, double grow, Offset shift) => RRect.fromRectAndRadius(s.inflate(grow).shift(shift), r);

    final shadow = Paint()..color = const Color(0xFF1630A0).withOpacity(0.55);
    final body = Paint()..color = const Color(0xFF2A55E4);
    final face = Paint()..color = const Color(0xFF4877FF);
    final gloss = Paint()..color = Colors.white.withOpacity(0.32);

    for (final s in segs) {
      canvas.drawRRect(rr(s, t / 2, Offset(0, t * 0.3)), shadow);
    }
    for (final s in segs) {
      canvas.drawRRect(rr(s, t / 2, Offset.zero), body);
    }
    for (final s in segs) {
      canvas.drawRRect(rr(s, t * 0.3, Offset(0, -t * 0.1)), face);
    }
    for (final s in segs) {
      final g = s.isEmpty && s.width == 0
          ? Rect.fromLTRB(s.left - t * 0.12, s.top - t * 0.05, s.left - t * 0.02, s.bottom + t * 0.05)
          : Rect.fromLTRB(s.left - t * 0.05, s.top - t * 0.24, s.right + t * 0.05, s.top - t * 0.12);
      canvas.drawRRect(RRect.fromRectAndRadius(g, Radius.circular(t * 0.1)), gloss);
    }
  }

  @override
  bool shouldRepaint(_WallsPainter o) => o.lvl != lvl || o.cell != cell;
}

class _MutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFFF4D6D)
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * 0.26, size.height * 0.26), Offset(size.width * 0.74, size.height * 0.74), p);
  }

  @override
  bool shouldRepaint(_MutePainter o) => false;
}

/// End-of-level card: stars pop in, reward, replay / next.
class _WinCard extends StatefulWidget {
  final int stars, moves, best, gold;
  final bool last;
  const _WinCard({required this.stars, required this.moves, required this.best, required this.gold, required this.last});

  @override
  State<_WinCard> createState() => _WinCardState();
}

class _WinCardState extends State<_WinCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.stars; i++) {
      Future.delayed(Duration(milliseconds: 380 + i * 300), () {
        if (mounted) Provider.of<AudioManager>(context, listen: false).playEventSound('starSound');
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = min(MediaQuery.sizeOf(context).width - 48, 360.0);
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: w,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 78),
                padding: const EdgeInsets.fromLTRB(20, 84, 20, 20),
                decoration: BoxDecoration(
                  color: bbCream,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFB79CFF), width: 4),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: BBTitle(bbT(context, widget.stars == 3 ? 'perfect' : 'greatJob'), size: 34),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Padding(
                            padding: EdgeInsets.only(left: 4, right: 4, bottom: i == 1 ? 10 : 0),
                            child: ScaleTransition(
                              scale: CurvedAnimation(
                                parent: _c,
                                curve: Interval(0.2 + i * 0.2, min(1.0, 0.55 + i * 0.2), curve: Curves.elasticOut),
                              ),
                              child: BBStar(on: i < widget.stars, size: i == 1 ? 66 : 54),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(bbT(context, 'yourMoves', {'n': widget.moves}),
                        style: kidBodyStyle(18, color: bbInk, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(bbT(context, 'bestMoves', {'n': widget.best}),
                        style: kidBodyStyle(14, color: KidColors.muted, weight: FontWeight.w600)),
                    if (widget.gold > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFFFF1C2), borderRadius: BorderRadius.circular(30)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Image.asset(BBAssets.coin, width: 30, height: 30),
                          const SizedBox(width: 8),
                          Text('+${widget.gold}', style: kidBodyStyle(22, color: bbInk, weight: FontWeight.w700)),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        KidPressable(
                          onTap: () => Navigator.pop(context, 'replay'),
                          semanticLabel: bbT(context, 'reset'),
                          child: Image.asset(BBAssets.reset, width: 58, height: 58),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KidButton(
                            label: bbT(context, widget.last ? 'done' : 'next'),
                            width: double.infinity,
                            height: 58,
                            onPressed: () => Navigator.pop(context, widget.last ? 'menu' : 'next'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Image.asset(BBAssets.robotPoint, height: 158),
            ],
          ),
        ),
      ),
    );
  }
}
