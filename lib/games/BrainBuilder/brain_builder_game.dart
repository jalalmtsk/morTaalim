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

/// Look of each world: tiles, controls, wall colours and decorations.
class _Theme {
  final String floor, start, goal, gem, robot, up, down, left, right, reset, hint;
  final Color wallBody, wallFace, wallShadow, frame, frameDeep;
  final bool snow;
  final List<String> decor; // top-left, top-right, bottom-left, bottom-right
  const _Theme({
    required this.floor,
    required this.start,
    required this.goal,
    required this.gem,
    this.robot = 'r_robot',
    required this.up,
    required this.down,
    required this.left,
    required this.right,
    required this.reset,
    required this.hint,
    this.wallBody = const Color(0xFF2A55E4),
    this.wallFace = const Color(0xFF4877FF),
    this.wallShadow = const Color(0xFF1630A0),
    this.frame = const Color(0xFF8BD66A),
    this.frameDeep = const Color(0xFF4E9E3A),
    this.snow = false,
    required this.decor,
  });
}

const Map<BBMode, _Theme> _themes = {
  BBMode.bridge: _Theme(
    floor: 'r_floor', start: 'r_start', goal: 'r_goal', gem: 'r_star',
    up: 'r_up', down: 'r_down', left: 'r_left', right: 'r_right', reset: 'r_reset', hint: 'r_hint',
    decor: ['flowers', 'r_grass', 'flowers', 'crystals'],
  ),
  BBMode.portal: _Theme(
    floor: 'p_floor', start: 'p_start', goal: 'p_goal', gem: 'r_star',
    up: 'r_up', down: 'r_down', left: 'r_left', right: 'r_right', reset: 'p_reset', hint: 'p_hint',
    frame: Color(0xFFF7A8D8), frameDeep: Color(0xFFD45CA8),
    decor: ['p_tree', 'p_arch', 'p_bush1', 'p_bush3'],
  ),
  BBMode.ice: _Theme(
    floor: 'i_floor', start: 'i_start', goal: 'i_goal', gem: 'i_star',
    up: 'i_up', down: 'i_down', left: 'i_left', right: 'i_right', reset: 'i_reset', hint: 'i_hint',
    wallBody: Color(0xFF2F6FE0), wallFace: Color(0xFF5B9BFF), wallShadow: Color(0xFF1C4AA8),
    frame: Color(0xFFBFEFFF), frameDeep: Color(0xFF5BB8F5), snow: true,
    decor: ['i_tree', 'i_wind', 'i_snowman', 'i_tree'],
  ),
  BBMode.gear: _Theme(
    floor: 'g_floor', start: 'g_start', goal: 'g_goal', gem: 'g_star',
    up: 'g_up', down: 'g_down', left: 'g_left', right: 'g_right', reset: 'g_reset', hint: 'g_hint',
    frame: Color(0xFFFFD66B), frameDeep: Color(0xFFC88A12),
    decor: ['g_gear', 'g_box', 'g_pipe', 'g_gear2'],
  ),
  BBMode.moon: _Theme(
    floor: 'o_floor', start: 'o_start', goal: 'o_floor', gem: 'o_star', robot: 'o_robot',
    up: 'o_up', down: 'o_down', left: 'o_left', right: 'o_right', reset: 'o_reset', hint: 'o_hint',
    wallBody: Color(0xFF243A9E), wallFace: Color(0xFF3550C8), wallShadow: Color(0xFF0F1A55),
    frame: Color(0xFF5B4BB8), frameDeep: Color(0xFF2B1F75),
    decor: ['o_mushroom', 'o_moon', 'o_crystal', 'o_lantern'],
  ),
  BBMode.buddy: _Theme(
    floor: 'b_floor', start: 'b_start1', goal: 'b_face1', gem: 'r_star',
    up: 'b_up', down: 'b_down', left: 'b_left', right: 'b_right', reset: 'b_reset', hint: 'b_hint',
    decor: ['flowers', 'p_bush2', 'p_bush1', 'flowers'],
  ),
};

/// One Brain Builder level.
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
  static const int _hintCost = 10;

  late final BBLevel _lvl = bbLevel(widget.level);
  late final _Theme _th = _themes[_lvl.mode]!;
  late BBState _s = _lvl.initial;
  late int _pos1 = _lvl.start, _pos2 = _lvl.start2; // shown cells (animated)
  int _shownMask = 0;
  int _moves = 0;
  final Set<int> _trail = {};
  List<_HintMark> _hint = const [];
  int _hintsLeft = 3, _prevStars = 0, _potential = 3, _pop1 = 0, _pop2 = 0;
  bool _busy = false, _won = false, _stuck = false, _face1Left = false, _face2Left = false;
  BBDir? _queued;
  BBDir _bumpDir = BBDir.up;
  int _gen = 0;
  Duration _moveDur = const Duration(milliseconds: 170);
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
  bool get _gotAll => _shownMask == _lvl.fullMask;
  String _a(String name) => BBAssets.a(name);

  @override
  void initState() {
    super.initState();
    _trail.add(_pos1);
    BBProgress.starsOf(widget.level).then((v) {
      if (mounted) setState(() => _prevStars = v);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final n in [_th.floor, _th.start, _th.goal, _th.gem, _th.robot, 'o_paw', 'b_robot2', 'b_start2', 'b_face2']) {
      precacheImage(AssetImage(_a(n)), context);
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
    if (d == BBDir.left) {
      _face1Left = true;
      _face2Left = true;
    }
    if (d == BBDir.right) {
      _face1Left = false;
      _face2Left = false;
    }
    final mv = _lvl.move(_s, d);
    if (mv == null) {
      _bumpDir = d;
      _bump.forward(from: 0);
      HapticFeedback.lightImpact();
      _audio.playEventSound('invalid');
      _say('bump');
      return;
    }
    _audio.playEventSound('clickButton');
    if (_hint.isNotEmpty) {
      _hint = (_hint.first.cell == _s.p1 && _hint.first.dir == d) ? _hint.sublist(1) : const [];
    }
    final r1 = mv.r1, r2 = mv.r2;
    int walkLen(BBStep1? r) => r == null ? 0 : (r.teleported ? r.path.length - 1 : r.path.length);
    final steps = max(walkLen(r1), walkLen(r2));
    final per = _lvl.slides ? 90 : 170;
    final gen = _gen;
    final before = _s.flags;
    final tele = (r1?.teleported ?? false) || (r2?.teleported ?? false);
    setState(() {
      _busy = true;
      _moveDur = Duration(milliseconds: per * steps + (_lvl.slides ? 80 : 0));
      _moveCurve = _lvl.slides ? Curves.easeOutBack : Curves.easeOutCubic;
      if (r1 != null) _pos1 = r1.teleported ? r1.path[r1.path.length - 2] : r1.to;
      if (r2 != null) _pos2 = r2.teleported ? r2.path[r2.path.length - 2] : r2.to;
      _moves++;
    });
    // trail + stars picked up along the way
    for (final r in [r1, r2]) {
      if (r == null) continue;
      final walk = r.teleported ? r.path.sublist(0, r.path.length - 1) : r.path;
      for (var k = 0; k < walk.length; k++) {
        final cell = walk[k];
        Future.delayed(Duration(milliseconds: per * (k + 1) - per ~/ 3), () {
          if (!mounted || gen != _gen) return;
          setState(() => _trail.add(cell));
          final gi = _lvl.gems.indexOf(cell);
          if (gi >= 0 && _shownMask & (1 << gi) == 0) {
            setState(() => _shownMask |= 1 << gi);
            _audio.playEventSound('starSound');
            _say(_gotAll ? 'allStars' : 'gotStar');
          }
        });
      }
    }
    Future.delayed(_moveDur, () async {
      if (!mounted || gen != _gen) return;
      if (tele) {
        _audio.playEventSound('PopButton');
        setState(() {
          _moveDur = Duration.zero;
          if (r1?.teleported ?? false) {
            _pos1 = r1!.to;
            _pop1++;
            _trail.add(r1.to);
          }
          if (r2?.teleported ?? false) {
            _pos2 = r2!.to;
            _pop2++;
          }
        });
        _say('whoosh');
        await Future.delayed(const Duration(milliseconds: 260));
        if (!mounted || gen != _gen) return;
      }
      _afterMove(mv.to, before);
    });
  }

  void _afterMove(BBState to, int before) {
    setState(() {
      _busy = false;
      _s = to;
      _shownMask = to.mask;
    });
    if ((to.flags & 3) != (before & 3)) {
      _audio.playEventSound('PopButton');
      _say('gateOpen');
    } else if ((to.flags & bbGearBit) != (before & bbGearBit)) {
      _audio.playEventSound('toggleButton');
      _say('gearTurn');
    }
    if (_lvl.isWin(_s)) {
      _win();
      return;
    }
    if (to.p1 == _lvl.goal && !_gotAll) _say('needStars');
    final rem = _lvl.solve(_s);
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
      _s = _lvl.initial;
      _pos1 = _lvl.start;
      _pos2 = _lvl.start2;
      _shownMask = 0;
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
      _face1Left = false;
      _face2Left = false;
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
    final path = _lvl.solve(_s);
    if (path == null) {
      _say('stuck', sticky: true);
      return;
    }
    final marks = <_HintMark>[];
    var st = _s;
    for (final d in path.take(3)) {
      marks.add(_HintMark(st.p1, d));
      st = _lvl.move(st, d)!.to;
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
        headerAsset: _a(_th.hint),
        headerAspect: 1,
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
      pageBuilder: (_, __, ___) => _WinCard(stars: stars, moves: _moves, best: _lvl.optimal, gold: gold, last: last),
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
    final dark = _lvl.dark;
    return Scaffold(
      backgroundColor: const Color(0xFF8FD3FF),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(BBAssets.mapBg, fit: BoxFit.cover)),
          Positioned.fill(
            child: ColoredBox(color: dark ? const Color(0xC8120C3A) : Colors.white.withOpacity(0.28)),
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
            SizedBox(height: 6 * s),
            Padding(padding: EdgeInsets.symmetric(horizontal: 22 * s), child: _instruction(s)),
            SizedBox(height: 6 * s),
            Expanded(
              child: LayoutBuilder(
                builder: (_, bc) => Center(child: _board(bc.maxWidth - 40 * s, bc.maxHeight - 16 * s, s)),
              ),
            ),
            _movesRow(s),
            SizedBox(height: 4 * s),
            _controls(s),
            SizedBox(height: 8 * s),
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
            asset: _a('m_back'),
            size: 50 * s,
            flipRtl: true,
            label: MaterialLocalizations.of(context).backButtonTooltip,
            onTap: () {
              _audio.playEventSound('cancelButton');
              Navigator.maybePop(context);
            },
          ),
          Expanded(
            child: Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: BBTitle(bbT(context, 'w${bbWorldOf(widget.level)}'), size: 30 * s)),
            ),
          ),
          BBSpriteButton(
            asset: _a('m_sound'),
            size: 50 * s,
            onTap: _toggleSound,
            overlay: muted ? Icon(Icons.close_rounded, color: const Color(0xFFFF4D6D), size: 38 * s) : null,
          ),
        ],
      ),
    );
  }

  Widget _statsPill(double s) {
    final reward = bbReward(widget.level, _potential, _prevStars);
    return BBPill(
      height: 50 * s,
      padding: EdgeInsets.symmetric(horizontal: 8 * s),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 6 * s),
            decoration: BoxDecoration(color: const Color(0xFFE6E0FA), borderRadius: BorderRadius.circular(30)),
            child: Text(bbT(context, 'levelN', {'n': bbIndexInWorld(widget.level) + 1}),
                style: kidBodyStyle(17 * s, color: bbInk, weight: FontWeight.w700)),
          ),
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 3; i++)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: Image.asset(_a(i < _potential ? 'star_on' : 'star_off'),
                      key: ValueKey(i < _potential), width: (i == 1 ? 32 : 28) * s),
                ),
            ]),
          ),
          Container(width: 2, height: 28 * s, color: const Color(0xFFEDE3CF)),
          SizedBox(width: 10 * s),
          Image.asset(BBAssets.coin, width: 28 * s, height: 28 * s),
          SizedBox(width: 6 * s),
          Text(reward > 0 ? '+$reward' : '✓', style: kidBodyStyle(18 * s, color: bbInk, weight: FontWeight.w700)),
          SizedBox(width: 8 * s),
        ],
      ),
    );
  }

  Widget _instruction(double s) {
    final mode = _lvl.mode == BBMode.ice ? 'slide' : _lvl.mode.name;
    final total = _lvl.gems.length;
    final got = [for (var g = 0; g < total; g++) if (_shownMask & (1 << g) != 0) g].length;
    return BBPill(
      radius: 24 * s,
      padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 6 * s),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(bbT(context, 'goal_$mode'), maxLines: 1, style: kidBodyStyle(18 * s, color: bbInk, weight: FontWeight.w700)),
                ),
                Text(bbT(context, 'sub_$mode'),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: kidBodyStyle(13 * s, color: KidColors.inkSoft, weight: FontWeight.w600)),
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
                Image.asset(_a(_th.gem), width: 22 * s, height: 22 * s),
                SizedBox(width: 3 * s),
                Text('$got/$total', style: kidBodyStyle(15 * s, color: bbInk, weight: FontWeight.w700)),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Board ───────────────────────────────────────────────────────────────

  Widget _board(double aw, double ah, double s) {
    final cols = _lvl.cols, rows = _lvl.rows;
    final pad = 14.0 * s; // frame thickness
    final t0 = 0.22; // wall thickness relative to a cell
    final cell = min((aw - 2 * pad) / (cols + t0), (ah - 2 * pad) / (rows + t0));
    final t = cell * t0;
    final fw = cell * (cols + t0), fh = cell * (rows + t0);
    final bw = fw + 2 * pad, bh = fh + 2 * pad;
    final decoSize = min(bw, bh) * 0.24;
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
            // decorations peeking out behind the corners
            for (var i = 0; i < 4; i++) _decor(i, bw, bh, decoSize),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(pad * 1.6),
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_th.frame, _th.frameDeep]),
                  border: Border.all(color: Colors.white.withOpacity(0.9), width: 3),
                  boxShadow: [
                    BoxShadow(color: _th.frameDeep.withOpacity(0.55), blurRadius: 18, offset: const Offset(0, 8)),
                  ],
                ),
              ),
            ),
            Positioned(
              left: pad,
              top: pad,
              width: fw,
              height: fh,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cell * 0.18),
                clipBehavior: Clip.none,
                child: Directionality(textDirection: TextDirection.ltr, child: _field(cell, t)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decor(int i, double bw, double bh, double size) {
    final name = _th.decor[i];
    final left = i.isEven, top = i < 2;
    return Positioned(
      left: left ? -size * 0.45 : null,
      right: left ? null : -size * 0.45,
      top: top ? -size * 0.5 : null,
      bottom: top ? null : -size * 0.35,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _idle,
          builder: (_, c) => Transform.translate(
            offset: Offset(0, sin(_idle.value * 2 * pi + i * 1.3) * 3),
            child: Transform.rotate(angle: name.contains('gear') ? _idle.value * 2 * pi * (i.isEven ? 1 : -1) : 0, child: c),
          ),
          child: Image.asset(_a(name), width: size, height: size, fit: BoxFit.contain),
        ),
      ),
    );
  }

  static const ColorFilter _greyFilter = ColorFilter.matrix([
    0.45, 0.45, 0.10, 0, 30, //
    0.40, 0.45, 0.15, 0, 30,
    0.40, 0.40, 0.30, 0, 60,
    0, 0, 0, 1, 0,
  ]);

  /// True when the corridor through [cell] runs up–down (so a barrier lies across it horizontally).
  bool _vertical(int cell) {
    final ud = (!_lvl.blocked(cell, BBDir.up) ? 1 : 0) + (!_lvl.blocked(cell, BBDir.down) ? 1 : 0);
    final lr = (!_lvl.blocked(cell, BBDir.left) ? 1 : 0) + (!_lvl.blocked(cell, BBDir.right) ? 1 : 0);
    return ud >= lr;
  }

  Widget _field(double cell, double t) {
    Offset at(int i) => Offset(t / 2 + _lvl.col(i) * cell, t / 2 + _lvl.row(i) * cell);
    Widget inCell(int i, double f, Widget child, {double dy = 0}) {
      final o = at(i);
      return Positioned(
        left: o.dx + cell * (1 - f) / 2,
        top: o.dy + cell * (1 - f) / 2 + dy * cell,
        width: cell * f,
        height: cell * f,
        child: child,
      );
    }

    final flags = _s.flags;
    final dark = _lvl.dark;
    return AnimatedBuilder(
      animation: Listenable.merge([_idle, _bump, _cheer]),
      builder: (_, __) {
        final ph = _idle.value * 2 * pi;
        final children = <Widget>[
          // floor
          Positioned.fill(child: ColoredBox(color: _th.frameDeep.withOpacity(0.6))),
          for (var i = 0; i < _lvl.cells; i++)
            inCell(i, 1.03, Image.asset(_a(dark && _trail.contains(i) ? 'o_paw' : _th.floor), fit: BoxFit.fill)),
          if (!dark)
            for (final i in _trail)
              if (i != _lvl.goal && i != _lvl.goal2)
                inCell(i, 0.5, DecoratedBox(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.35)),
                )),
          // start pads
          inCell(_lvl.start, 0.94, Image.asset(_a(_th.start), fit: BoxFit.contain)),
          if (_lvl.buddy) inCell(_lvl.start2, 0.94, Image.asset(_a('b_start2'), fit: BoxFit.contain)),
          // buttons
          for (final e in _lvl.buttons.entries) inCell(e.key, 0.92, Image.asset(_a(_buttonSprite(e.value, flags)), fit: BoxFit.contain)),
          // portals
          for (final e in _lvl.portals.entries) inCell(e.key, 1.0, _portal(e.key, ph)),
          // gear switches
          for (final sw in _lvl.switches) inCell(sw, 0.98, _gear(flags)),
          // walls
          Positioned.fill(child: CustomPaint(painter: _WallsPainter(_lvl, cell, t, _th))),
          // gates and doors (drawn over walls so they read as barriers)
          for (final e in _lvl.gates.entries)
            inCell(e.key, 1.0, _barrier(_gateSprite(e.value), e.key, !_lvl.closed(e.key, flags))),
          for (final dcell in {..._lvl.doorsA, ..._lvl.doorsB}) inCell(dcell, 1.0, _barrier('g_bar', dcell, !_lvl.closed(dcell, flags))),
          // goal(s)
          inCell(_lvl.goal, 1.0, _goal(ph, _th.goal, first: true)),
          if (_lvl.buddy) inCell(_lvl.goal2, 1.0, _goal(ph, 'b_face2', first: false)),
          // little stars
          for (var g = 0; g < _lvl.gems.length; g++)
            inCell(
              _lvl.gems[g],
              0.62,
              AnimatedScale(
                scale: _shownMask & (1 << g) != 0 ? 0 : 1,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInBack,
                child: Transform.translate(
                  offset: Offset(0, sin(ph * 2 + g * 1.7) * cell * 0.05),
                  child: Image.asset(_a(_th.gem), fit: BoxFit.contain),
                ),
              ),
            ),
          // hints
          for (var k = 0; k < _hint.length; k++)
            inCell(
              _hint[k].cell,
              0.86,
              Opacity(
                opacity: (0.78 + 0.22 * sin(ph * 3 - k)).clamp(0.0, 1.0).toDouble(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(cell * 0.2),
                    color: const Color(0xFF22C7DE).withOpacity(0.55),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Transform.rotate(
                    angle: _hint[k].dir.index * pi / 2,
                    child: Icon(Icons.arrow_upward_rounded, color: Colors.white, size: cell * 0.56),
                  ),
                ),
              ),
            ),
        ];
        // darkness: only the lantern light around the robot shows the maze
        if (dark) {
          children.add(Positioned.fill(
            child: IgnorePointer(
              child: TweenAnimationBuilder<Offset>(
                tween: Tween(end: at(_pos1) + Offset(cell / 2, cell / 2)),
                duration: _moveDur,
                curve: _moveCurve,
                builder: (_, c, __) => CustomPaint(
                  painter: _FogPainter(c, cell * (1.75 + 0.06 * sin(ph * 2)), _won),
                ),
              ),
            ),
          ));
          // paw prints (memory) and the star stay visible
          for (final i in _trail) {
            children.add(inCell(i, 0.5, IgnorePointer(child: Opacity(opacity: 0.55, child: Image.asset(_a('o_paw'), fit: BoxFit.contain)))));
          }
          children.add(inCell(_lvl.goal, 0.8, Opacity(opacity: 0.9, child: Image.asset(_a('o_star'), fit: BoxFit.contain))));
        }
        // robots on top
        children.add(_robot(cell, at, _pos1, _th.robot, _face1Left, _pop1, 0));
        if (_lvl.buddy) children.add(_robot(cell, at, _pos2, 'b_robot2', _face2Left, _pop2, 1));
        return Stack(clipBehavior: Clip.none, children: children);
      },
    );
  }

  String _buttonSprite(int colour, int flags) {
    final on = flags & (1 << colour) != 0;
    if (_lvl.buddy) return '${colour == 0 ? 'b_btn1' : 'b_btn0'}${on ? '_on' : ''}';
    return 'r_btn$colour${on ? '_on' : ''}';
  }

  String _gateSprite(int colour) => _lvl.buddy ? (colour == 0 ? 'b_gate1' : 'b_gate0') : 'r_gate$colour';

  Widget _barrier(String sprite, int cell, bool open) {
    final img = Image.asset(_a(sprite), fit: BoxFit.contain);
    final rotated = _vertical(cell) ? img : RotatedBox(quarterTurns: 1, child: img);
    return AnimatedOpacity(
      opacity: open ? 0.22 : 1,
      duration: const Duration(milliseconds: 350),
      child: AnimatedScale(
        scale: open ? 0.7 : 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        child: rotated,
      ),
    );
  }

  Widget _portal(int cell, double ph) {
    final keys = _lvl.portals.keys.toList()..sort();
    final pair = (keys.indexOf(cell) ~/ 2) % 2; // first pair purple, second pair cyan
    Widget img = Image.asset(_a('p_portal'), fit: BoxFit.contain);
    if (pair == 1) {
      img = ColorFiltered(colorFilter: const ColorFilter.mode(Color(0xFF8FEAFF), BlendMode.modulate), child: img);
    }
    return Transform.scale(scale: 1 + 0.05 * sin(ph * 3 + cell), child: img);
  }

  Widget _gear(int flags) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: flags & bbGearBit != 0 ? pi / 2 : 0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (_, a, c) => Transform.rotate(angle: a, child: c),
      child: Image.asset(_a('g_gear'), fit: BoxFit.contain),
    );
  }

  Widget _goal(double ph, String sprite, {required bool first}) {
    final open = !first || _gotAll;
    final img = Image.asset(_a(sprite), fit: BoxFit.contain);
    return Transform.scale(
      scale: open ? 1 + 0.04 * sin(ph * 2) : 0.94,
      child: open
          ? img
          : Stack(children: [
              Positioned.fill(child: Opacity(opacity: 0.85, child: ColorFiltered(colorFilter: _greyFilter, child: img))),
              Align(
                alignment: const Alignment(0.8, 0.8),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.lock_rounded, size: 14, color: KidColors.purpleDeep),
                ),
              ),
            ]),
    );
  }

  Widget _robot(double cell, Offset Function(int) at, int pos, String sprite, bool faceLeft, int pop, int which) {
    final rh = cell * 1.15, rw = rh * 0.62;
    final p = at(pos);
    final b = _bump.value;
    final shake = _bump.isAnimating ? sin(b * pi * 4) * (1 - b) * cell * 0.12 : 0.0;
    final hop = _cheer.isAnimating ? -sin(_cheer.value * pi * 2 + which).abs() * cell * 0.35 : 0.0;
    final bob = _busy ? 0.0 : sin(_idle.value * 2 * pi * 2 + which * 1.5) * cell * 0.025;
    return AnimatedPositioned(
      duration: _moveDur,
      curve: _moveCurve,
      left: p.dx + (cell - rw) / 2,
      top: p.dy + cell - rh - cell * 0.06,
      width: rw,
      height: rh,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('pop$which$pop'),
        tween: Tween(begin: pop == 0 ? 1.0 : 0.2, end: 1.0),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutBack,
        builder: (_, sc, c) => Transform.scale(scale: sc, alignment: Alignment.bottomCenter, child: c),
        child: Transform.translate(
          offset: Offset(_bumpDir.dx * shake, _bumpDir.dy * shake + bob + hop),
          child: Transform.flip(flipX: faceLeft, child: Image.asset(_a(sprite), fit: BoxFit.contain)),
        ),
      ),
    );
  }

  Widget _movesRow(double s) {
    final tip = _tipKey ?? 'tip';
    final dark = _lvl.dark;
    return Column(
      children: [
        BBPill(
          padding: EdgeInsets.symmetric(horizontal: 22 * s, vertical: 3 * s),
          child: Text(bbT(context, 'movesN', {'n': _moves}), style: kidBodyStyle(18 * s, color: bbInk, weight: FontWeight.w700)),
        ),
        SizedBox(height: 3 * s),
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
                style: kidBodyStyle(15 * s,
                        color: _tipKey == 'stuck' ? const Color(0xFFD9214E) : (dark ? Colors.white : bbInk), weight: FontWeight.w700)
                    .copyWith(shadows: [
                  Shadow(color: dark ? Colors.black : Colors.white, blurRadius: 6),
                  Shadow(color: dark ? Colors.black : Colors.white, blurRadius: 14),
                ]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _controls(double s) {
    final b = 60 * s;
    Widget arrow(BBDir d, String sprite) =>
        SizedBox(width: b, height: b, child: _PadButton(asset: _a(sprite), onPress: () => _move(d)));
    final empty = _hintsLeft <= 0;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          KidPressable(
            semanticLabel: bbT(context, 'reset'),
            onTap: () {
              _audio.playEventSound('clickButton2');
              _restart();
            },
            child: Image.asset(_a(_th.reset), width: 56 * s, height: 56 * s),
          ),
          SizedBox(width: 16 * s),
          SizedBox(
            width: b * 3,
            height: b * 2.05,
            child: Stack(children: [
              Positioned(left: b, top: 0, child: arrow(BBDir.up, _th.up)),
              Positioned(left: 0, bottom: 0, child: arrow(BBDir.left, _th.left)),
              Positioned(left: b, bottom: 0, child: arrow(BBDir.down, _th.down)),
              Positioned(right: 0, bottom: 0, child: arrow(BBDir.right, _th.right)),
            ]),
          ),
          SizedBox(width: 16 * s),
          KidPressable(
            semanticLabel: bbT(context, 'hint'),
            onTap: _useHint,
            child: Stack(clipBehavior: Clip.none, children: [
              AnimatedBuilder(
                animation: _idle,
                builder: (_, c) => Transform.rotate(angle: sin(_idle.value * 2 * pi * 2) * 0.06, child: c),
                child: Image.asset(_a(_th.hint), width: 56 * s, height: 56 * s),
              ),
              Positioned(
                top: -8 * s,
                right: -8 * s,
                child: Container(
                  width: 26 * s,
                  height: 26 * s,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: empty ? const Color(0xFF22B573) : KidColors.purple,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: empty
                      ? Icon(Icons.add_rounded, color: Colors.white, size: 16 * s)
                      : Text('$_hintsLeft', style: kidBodyStyle(13 * s, color: Colors.white, weight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Arrow button: fires on press, repeats while held.
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

/// Glossy maze walls in the world's colours (with snow caps on ice).
class _WallsPainter extends CustomPainter {
  final BBLevel lvl;
  final double cell, t;
  final _Theme th;
  _WallsPainter(this.lvl, this.cell, this.t, this.th);

  @override
  void paint(Canvas canvas, Size size) {
    final segs = <Rect>[];
    for (var i = 0; i < lvl.cells; i++) {
      final x = t / 2 + lvl.col(i) * cell, y = t / 2 + lvl.row(i) * cell;
      if (lvl.blocked(i, BBDir.up)) segs.add(Rect.fromLTRB(x, y, x + cell, y));
      if (lvl.blocked(i, BBDir.left)) segs.add(Rect.fromLTRB(x, y, x, y + cell));
      if (lvl.row(i) == lvl.rows - 1 && lvl.blocked(i, BBDir.down)) segs.add(Rect.fromLTRB(x, y + cell, x + cell, y + cell));
      if (lvl.col(i) == lvl.cols - 1 && lvl.blocked(i, BBDir.right)) segs.add(Rect.fromLTRB(x + cell, y, x + cell, y + cell));
    }
    final r = Radius.circular(t * 0.5);
    RRect rr(Rect s, double grow, Offset shift) => RRect.fromRectAndRadius(s.inflate(grow).shift(shift), r);
    final shadow = Paint()..color = th.wallShadow.withOpacity(0.6);
    final base = Paint()..color = const Color(0xFFC9B79A);
    final body = Paint()..color = th.wallBody;
    final face = Paint()..color = th.wallFace;
    final gloss = Paint()..color = Colors.white.withOpacity(0.3);
    final snow = Paint()..color = Colors.white.withOpacity(0.95);
    for (final s in segs) {
      canvas.drawRRect(rr(s, t / 2 + t * 0.12, Offset(0, t * 0.38)), shadow);
    }
    for (final s in segs) {
      canvas.drawRRect(rr(s, t / 2 + t * 0.06, Offset(0, t * 0.2)), base);
    }
    for (final s in segs) {
      canvas.drawRRect(rr(s, t / 2, Offset.zero), body);
    }
    for (final s in segs) {
      canvas.drawRRect(rr(s, t * 0.3, Offset(0, -t * 0.1)), face);
    }
    for (final s in segs) {
      if (th.snow) {
        canvas.drawRRect(rr(s, t * 0.32, Offset(0, -t * 0.28)), snow);
      } else {
        final g = s.width == 0
            ? Rect.fromLTRB(s.left - t * 0.12, s.top - t * 0.05, s.left - t * 0.02, s.bottom + t * 0.05)
            : Rect.fromLTRB(s.left - t * 0.05, s.top - t * 0.24, s.right + t * 0.05, s.top - t * 0.12);
        canvas.drawRRect(RRect.fromRectAndRadius(g, Radius.circular(t * 0.1)), gloss);
      }
    }
  }

  @override
  bool shouldRepaint(_WallsPainter o) => o.lvl != lvl || o.cell != cell;
}

/// Darkness with a soft lantern circle around the robot.
class _FogPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final bool lifted; // fades away when the level is won
  _FogPainter(this.center, this.radius, this.lifted);

  @override
  void paint(Canvas canvas, Size size) {
    if (lifted) return;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment((center.dx / size.width) * 2 - 1, (center.dy / size.height) * 2 - 1),
        radius: radius / min(size.width, size.height),
        colors: const [Color(0x00000000), Color(0x22070A30), Color(0xEE070A30)],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect.inflate(4), paint);
  }

  @override
  bool shouldRepaint(_FogPainter o) => o.center != center || o.radius != radius || o.lifted != lifted;
}

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
