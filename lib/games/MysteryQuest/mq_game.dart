import 'dart:async';
import 'package:mortaalim/Manager/rewards.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:provider/provider.dart';

import 'mq_data.dart';
import 'package:mortaalim/tools/Ads_Manager.dart';

/// One round of Mystery Quest in a room: find every hidden thing on the list.
class MqGamePage extends StatefulWidget {
  final MqPlace place;
  final MqRoom room;
  final int level;
  final bool timer;
  const MqGamePage({super.key, required this.place, required this.room, required this.level, required this.timer});
  @override
  State<MqGamePage> createState() => _MqGamePageState();
}

class _Spot {
  final Offset bottom; // bottom-centre on screen (scene pixels)
  final double w, rot;
  final bool flip;
  const _Spot(this.bottom, this.w, this.rot, this.flip);
}

class _MqGamePageState extends State<MqGamePage> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  final TransformationController _view = TransformationController();
  final Random _rng = Random();

  MqLevel get _lvl => mqLevels[widget.level];
  late List<String> _targets;
  late List<String> _decoys;
  final Map<String, _Spot> _spots = {};
  Size? _sceneSize;
  final Set<String> _found = {};
  final Map<String, int> _foundAt = {}; // id → tick counter when found (for animation keys)
  int _misses = 0, _hintsUsed = 0;
  String? _hint; // id being highlighted
  int _missKey = 0;
  Offset? _missAt;
  String? _wiggle;
  int _wiggleKey = 0;
  String _say = '';
  int _left = 0;
  Timer? _clock, _hintTimer, _idleTimer;
  bool _paused = false, _over = false, _zoomed = false, _leaving = false;

  /// Leaves the game screen (PopScope would otherwise block it).
  void _leave([Object? result]) {
    if (_leaving) return;
    _clock?.cancel();
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  static const int _maxHints = 3;

  @override
  void initState() {
    super.initState();
    final pool = [...widget.room.items]..shuffle(_rng);
    _targets = pool.take(_lvl.find).toList();
    _decoys = pool.skip(_lvl.find).take(_lvl.decoys).toList();
    _left = _lvl.seconds;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _say = mqT(context, 'start'));
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted && !_over) _askNext();
      });
    });
    if (widget.timer) {
      _clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_paused || _over || !mounted) return;
        setState(() => _left--);
        if (_left <= 10 && _left > 0) mqSound(context, 'clickButton2');
        if (_left <= 0) _finish(won: false);
      });
    }
    _armIdle();
  }

  @override
  void dispose() {
    _clock?.cancel();
    _hintTimer?.cancel();
    _idleTimer?.cancel();
    _idle.dispose();
    _enter.dispose();
    _view.dispose();
    super.dispose();
  }

  // ── layout of the hidden things ───────────────────────────────────────────

  /// Puts every item on a real surface of the room (shelves, tables, floor).
  void _place(Size size, double topFree, double s) {
    if (_sceneSize == size && _spots.isNotEmpty) return;
    _sceneSize = size;
    _spots.clear();
    // the room picture is drawn with BoxFit.cover
    final k = max(size.width / 720, size.height / 1280);
    final dx = (size.width - 720 * k) / 2, dy = (size.height - 1280 * k) / 2;
    final all = [..._targets, ..._decoys];
    final base = _lvl.size * size.width;
    final spots = [...widget.room.spots]..shuffle(_rng);
    final used = <Rect>[];
    for (final id in all) {
      _Spot? got;
      for (final sp in spots) {
        final w = base * sp.scale * (0.92 + _rng.nextDouble() * 0.16);
        final h = w * mqItemAspect(id);
        final x = dx + (sp.x + (_rng.nextDouble() - 0.5) * 0.03) * 720 * k;
        final y = dy + sp.y * 1280 * k;
        final r = Rect.fromLTWH(x - w / 2, y - h, w, h);
        final ok = r.top >= topFree &&
            r.left >= 4 &&
            r.right <= size.width - 4 &&
            r.bottom <= size.height - 6 &&
            !(r.center.dx < size.width * 0.55 && r.bottom > size.height - 150 * s) &&
            used.every((u) => !u.inflate(4).overlaps(r));
        if (!ok) continue;
        got = _Spot(Offset(x, y), w, (_rng.nextDouble() - 0.5) * 0.16, _rng.nextBool());
        used.add(r);
        spots.remove(sp);
        break;
      }
      if (got == null) {
        // not enough free surfaces: put it on the floor somewhere free
        for (var t = 0; t < 300 && got == null; t++) {
          final w = base * 0.9, h = w * mqItemAspect(id);
          final x = w / 2 + 6 + _rng.nextDouble() * (size.width - w - 12);
          final y = size.height * (0.55 + _rng.nextDouble() * 0.4);
          final r = Rect.fromLTWH(x - w / 2, y - h, w, h);
          if (r.top < topFree || (r.center.dx < size.width * 0.55 && r.bottom > size.height - 150 * s)) continue;
          if (used.every((u) => !u.overlaps(r)) || t == 299) {
            got = _Spot(Offset(x, y), w, 0, _rng.nextBool());
            used.add(r);
          }
        }
      }
      _spots[id] = got!;
    }
  }

  // ── game flow ─────────────────────────────────────────────────────────────

  String? get _nextTarget {
    for (final t in _targets) {
      if (!_found.contains(t)) return t;
    }
    return null;
  }

  void _askNext() {
    final n = _nextTarget;
    if (n == null) return;
    setState(() => _say = mqT(context, 'find', {'name': mqItemName(context, n)}));
  }

  void _armIdle() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 18), () {
      // gentle free nudge when the child is stuck: the item twinkles a bit
      if (!mounted || _over || _paused) return;
      final n = _nextTarget;
      if (n != null) {
        setState(() {
          _wiggle = n;
          _wiggleKey++;
        });
      }
    });
  }

  void _tapItem(String id) {
    if (_over || _paused) return;
    _armIdle();
    if (_targets.contains(id) && !_found.contains(id)) {
      HapticFeedback.lightImpact();
      mqSfx(context, 'CorrectAnwser_SFX.mp3');
      setState(() {
        _found.add(id);
        _foundAt[id] = DateTime.now().millisecondsSinceEpoch;
        if (_hint == id) _hint = null;
        _say = mqT(context, 'yes');
      });
      if (_found.length == _targets.length) {
        Future.delayed(const Duration(milliseconds: 900), () => _finish(won: true));
      } else {
        Future.delayed(const Duration(milliseconds: 1100), () {
          if (mounted && !_over) _askNext();
        });
      }
    } else if (_decoys.contains(id)) {
      mqSound(context, 'clickButton2');
      setState(() {
        _wiggle = id;
        _wiggleKey++;
        _say = mqT(context, 'notThis');
      });
    }
  }

  void _tapMiss(Offset at) {
    if (_over || _paused) return;
    _armIdle();
    mqSound(context, 'clickButton2');
    setState(() {
      _misses++;
      _missAt = at;
      _missKey++;
      _say = mqT(context, 'oops');
    });
  }

  void _useHint() {
    if (_over || _paused) return;
    final n = _nextTarget;
    if (n == null) return;
    if (_hintsUsed >= _maxHints) {
      mqSound(context, 'clickButton2');
      setState(() => _say = mqT(context, 'noHint'));
      return;
    }
    mqSound(context, 'PopButton');
    _hintTimer?.cancel();
    setState(() {
      _hintsUsed++;
      _hint = n;
      _say = mqT(context, 'hint');
    });
    _hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _hint = null);
    });
  }

  void _toggleZoom() {
    mqSound(context, 'toggleButton');
    final size = _sceneSize;
    if (size == null) return;
    if (_zoomed) {
      _view.value = Matrix4.identity();
    } else {
      const k = 1.8;
      _view.value = Matrix4.identity()
        ..translate(-size.width * (k - 1) / 2, -size.height * (k - 1) / 2)
        ..scale(k);
    }
    setState(() => _zoomed = !_zoomed);
  }

  Future<void> _pause() async {
    mqSound(context, 'clickButton');
    setState(() => _paused = true);
    final quit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PauseDialog(onQuit: () => Navigator.pop(ctx, true), onResume: () => Navigator.pop(ctx, false)),
    );
    if (!mounted) return;
    if (quit == true) {
      _leave();
    } else {
      setState(() => _paused = false);
    }
  }

  Future<void> _finish({required bool won}) async {
    if (_over || !mounted) return;
    _over = true;
    _clock?.cancel();
    _idleTimer?.cancel();
    var stars = 0, gold = 0;
    if (won) {
      stars = (_misses <= 2 && _hintsUsed == 0)
          ? 3
          : (_misses <= 6 && _hintsUsed <= 1)
              ? 2
              : 1;
      final fresh = await MqStore.record(widget.place.id, widget.room.id, widget.level, stars);
      final rw = Rewards.levelFromGain(tier: widget.level + 1, stars: stars, gained: fresh);
      gold = rw.gold;
      mqSfx(context, 'MarimbaWin_SFX.mp3');
      if (!mounted) return;
      Provider.of<ExperienceManager>(context, listen: false).grant(context, rw);
    } else {
      mqSfx(context, 'FailMeme_SFX.mp3');
    }
    if (!mounted) return;
    // next open room of this place
    final rooms = widget.place.rooms;
    final me = rooms.indexOf(widget.room);
    int? next;
    for (var k = 1; k < rooms.length; k++) {
      final i = (me + k) % rooms.length;
      if (rooms[i].open) {
        next = i;
        break;
      }
    }
    final choice = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x99140A40),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (ctx, _, __) => _EndDialog(
        won: won,
        stars: stars,
        gold: gold,
        found: _found.length,
        total: _targets.length,
        hasNext: next != null,
      ),
      transitionBuilder: (_, a, __, c) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
    );
    if (!mounted) return;
    // Fin de niveau = pause naturelle (AdHelper applique fréquence + écran « Publicité »).
    await AdHelper.showInterstitialAd(context: context);
    if (!mounted) return;
    switch (choice) {
      case 'again':
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => MqGamePage(place: widget.place, room: widget.room, level: widget.level, timer: widget.timer),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        ));
      case 'next':
        _leave(next);
      default:
        _leave();
    }
  }

  // ═════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) => MqFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final s = (min(size.width, 520.0) / 390).clamp(0.78, 1.3).toDouble();

    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_over && !_paused) _pause();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(children: [
          // scene + HUD on top of it
          Expanded(
            child: Stack(children: [
              Positioned.fill(child: _scene(s)),
              Positioned(left: 0, right: 0, top: pad.top + 4 * s, child: _hud(s)),
              PositionedDirectional(start: 0, bottom: 0, child: IgnorePointer(child: _robot(s))),
            ]),
          ),
          _tray(s, pad.bottom),
        ]),
      ),
    );
  }

  Widget _scene(double s) => LayoutBuilder(builder: (ctx, c) {
        final size = c.biggest;
        // keep the HUD area free of hidden things
        final topFree = MediaQuery.paddingOf(ctx).top + 96 * s;
        _place(size, topFree, s);
        return InteractiveViewer(
          transformationController: _view,
          minScale: 1,
          maxScale: 3,
          onInteractionEnd: (_) => setState(() => _zoomed = _view.value.getMaxScaleOnAxis() > 1.05),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _tapMiss(d.localPosition),
              child: Stack(clipBehavior: Clip.hardEdge, children: [
                // room + items settle in together after the zoom from the house
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _enter,
                    builder: (_, child) {
                      final t = Curves.easeOutCubic.transform(_enter.value);
                      return Transform.scale(scale: 1.18 - 0.18 * t, child: child);
                    },
                    child: Stack(clipBehavior: Clip.none, children: [
                      Positioned.fill(child: Image.asset(widget.room.bg, fit: BoxFit.cover)),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(animation: _idle, builder: (_, __) => CustomPaint(painter: _DustPainter(_idle.value))),
                        ),
                      ),
                      for (final id in [..._decoys, ..._targets]) _item(s, id),
                    ]),
                  ),
                ),
                if (_missAt != null)
                  Positioned(
                    left: _missAt!.dx - 34 * s,
                    top: _missAt!.dy - 34 * s,
                    width: 68 * s,
                    height: 68 * s,
                    child: IgnorePointer(
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey('miss$_missKey'),
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 600),
                        builder: (_, v, __) => Opacity(
                          opacity: (1 - v).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.5 + v * 0.7,
                            child: Transform.rotate(angle: sin(v * pi * 6) * 0.25 * (1 - v), child: Image.asset(mq('mq_mag'))),
                          ),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        );
      });

  Widget _item(double s, String id) {
    final sp = _spots[id];
    if (sp == null) return const SizedBox.shrink();
    final w = sp.w;
    final h = w * mqItemAspect(id);
    final found = _found.contains(id);
    final hinted = _hint == id;
    final wiggle = _wiggle == id;
    // a bigger invisible touch area makes small items easy to tap
    final pad = max(10.0 * s, w * 0.18);

    Widget pic = Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
      // soft contact shadow on the surface
      Positioned(
        left: w * 0.12,
        right: w * 0.12,
        bottom: -h * 0.03,
        height: h * 0.1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            gradient: RadialGradient(colors: [Colors.black.withOpacity(0.38), Colors.black.withOpacity(0)]),
          ),
        ),
      ),
      Positioned.fill(child: Transform.flip(flipX: sp.flip, child: Image.asset(mqItemAsset(id), fit: BoxFit.contain))),
    ]);
    pic = Transform.rotate(angle: sp.rot, alignment: Alignment.bottomCenter, child: pic);

    if (wiggle) {
      pic = TweenAnimationBuilder<double>(
        key: ValueKey('wig$id$_wiggleKey'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        builder: (_, v, c) => Transform.rotate(alignment: Alignment.bottomCenter, angle: sin(v * pi * 5) * 0.16 * (1 - v), child: c),
        child: pic,
      );
    }

    return Positioned(
      left: sp.bottom.dx - w / 2 - pad,
      top: sp.bottom.dy - h - pad,
      width: w + pad * 2,
      height: h + pad * 2,
      child: found
          ? IgnorePointer(
              child: TweenAnimationBuilder<double>(
                key: ValueKey('found$id${_foundAt[id]}'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 950),
                builder: (_, v, c) => Stack(clipBehavior: Clip.none, children: [
                  // green ring at the item's feet
                  Positioned(
                    left: pad - w * 0.25,
                    width: w * 1.5,
                    top: pad + h * 0.7,
                    height: h * 0.5,
                    child: Opacity(
                      opacity: (v < 0.7 ? 1.0 : (1 - v) / 0.3).clamp(0.0, 1.0),
                      child: Transform.scale(scale: 0.6 + v * 0.5, child: Image.asset(mq('mq_ring'), fit: BoxFit.fill)),
                    ),
                  ),
                  Positioned(
                    left: -w * 0.4,
                    right: -w * 0.4,
                    top: -h * 0.4,
                    bottom: -h * 0.2,
                    child: CustomPaint(painter: MqBurstPainter(v, seed: id.hashCode)),
                  ),
                  Positioned(
                    left: pad,
                    top: pad,
                    width: w,
                    height: h,
                    child: Opacity(
                      opacity: 1 - Curves.easeIn.transform(((v - 0.45) / 0.55).clamp(0.0, 1.0)),
                      child: Transform.translate(
                        offset: Offset(0, -v * h * 0.8),
                        child: Transform.scale(scale: 1 + sin(v * pi) * 0.5, child: c),
                      ),
                    ),
                  ),
                ]),
                child: pic,
              ),
            )
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _tapItem(id),
              child: Stack(clipBehavior: Clip.none, children: [
                if (hinted)
                  Positioned(
                    left: pad - w * 0.35,
                    top: pad - h * 0.3,
                    width: w * 1.7,
                    height: h * 1.5,
                    child: AnimatedBuilder(
                      animation: _idle,
                      builder: (_, __) {
                        final p = 0.5 + 0.5 * sin(_idle.value * 2 * pi * 8);
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFFE066), width: 3 + 3 * p),
                            boxShadow: [BoxShadow(color: const Color(0xFFFFE066).withOpacity(0.5 + 0.4 * p), blurRadius: 24)],
                          ),
                        );
                      },
                    ),
                  ),
                Positioned(left: pad, top: pad, width: w, height: h, child: pic),
              ]),
            ),
    );
  }

  // ── HUD ───────────────────────────────────────────────────────────────────

  Widget _hud(double s) {
    final total = _targets.length;
    final done = _found.length;
    final ratio = widget.timer ? (_left / _lvl.seconds).clamp(0.0, 1.0) : done / total;
    final low = widget.timer && _left <= 15;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8 * s),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        mqRound(context, 'mq_back', 46 * s, _pause, flipRtl: true),
        SizedBox(width: 4 * s),
        Expanded(
          child: SizedBox(
            height: 76 * s,
            child: Stack(children: [
              Positioned.fill(child: Image.asset(mq('mq_hud'), fit: BoxFit.fill)),
              // room name (beside the little house)
              Positioned(
                top: 12 * s,
                left: 66 * s,
                right: 16 * s,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(mqPick(context, widget.room.name), style: mqText(19 * s)),
                ),
              ),
              // progress inside the small pill
              Positioned(
                left: 0,
                right: 0,
                bottom: 8 * s,
                child: Center(
                  child: SizedBox(
                    width: 150 * s,
                    height: 22 * s,
                    child: Row(children: [
                      Icon(widget.timer ? Icons.timer_rounded : Icons.search_rounded, size: 16 * s, color: low ? const Color(0xFFE5484D) : mqBlue),
                      SizedBox(width: 4 * s),
                      Expanded(
                        child: Container(
                          height: 10 * s,
                          decoration: BoxDecoration(color: const Color(0xFFD9DCE4), borderRadius: BorderRadius.circular(8 * s)),
                          alignment: AlignmentDirectional.centerStart,
                          child: AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 400),
                            widthFactor: max(0.03, ratio.toDouble()),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: low ? [const Color(0xFFFF8A8A), const Color(0xFFE5484D)] : [const Color(0xFF5BC8FF), mqBlue]),
                                borderRadius: BorderRadius.circular(8 * s),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 6 * s),
                      Text(widget.timer ? '${_left ~/ 60}:${(_left % 60).toString().padLeft(2, '0')}' : '$done/$total',
                          style: mqText(12.5 * s, color: low ? const Color(0xFFE5484D) : mqInk)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
        SizedBox(width: 4 * s),
        Column(mainAxisSize: MainAxisSize.min, children: [
          mqRound(context, 'mq_pause', 40 * s, _pause),
          SizedBox(height: 4 * s),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _zoomed ? 1 : 0.85,
            child: mqRound(context, 'mq_expand', 40 * s, _toggleZoom),
          ),
        ]),
      ]),
    );
  }

  Widget _robot(double s) => Padding(
        padding: EdgeInsets.only(bottom: 4 * s),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
          AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi * 2) * 3 * s), child: c),
            child: Transform.flip(flipX: mqRtl(context), child: Image.asset(mq('mq_robot_point'), height: 92 * s)),
          ),
          if (_say.isNotEmpty) Padding(padding: EdgeInsets.only(bottom: 44 * s), child: MqBubble(text: _say, width: 190 * s)),
        ]),
      );

  // ── list of things to find ────────────────────────────────────────────────

  Widget _tray(double s, double bottomPad) {
    final hintsLeft = _maxHints - _hintsUsed;
    return Container(
      padding: EdgeInsets.fromLTRB(6 * s, 6 * s, 6 * s, 6 * s + bottomPad),
      color: const Color(0xFFFFF3DD),
      child: SizedBox(
        height: 74 * s,
        child: Row(children: [
          Expanded(
            child: Stack(children: [
              Positioned.fill(child: Image.asset(mq('mq_tray'), fit: BoxFit.fill)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 6 * s),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _targets.length,
                  separatorBuilder: (_, __) => SizedBox(width: 4 * s),
                  itemBuilder: (_, i) => _slot(s, _targets[i]),
                ),
              ),
            ]),
          ),
          SizedBox(width: 6 * s),
          // hint bulb
          MqPress(
            onTap: _useHint,
            label: 'hint',
            child: SizedBox(
              width: 50 * s,
              child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                if (hintsLeft > 0)
                  AnimatedBuilder(
                    animation: _idle,
                    builder: (_, __) => Opacity(
                      opacity: 0.5 + 0.5 * sin(_idle.value * 2 * pi * 3).abs(),
                      child: Image.asset(mq('mq_burst'), width: 50 * s),
                    ),
                  ),
                Opacity(opacity: hintsLeft > 0 ? 1 : 0.4, child: Image.asset(mq('mq_bulb'), height: 54 * s)),
                PositionedDirectional(
                  end: -2 * s,
                  bottom: 2 * s,
                  child: Container(
                    width: 20 * s,
                    height: 20 * s,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: mqBlue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: Text('$hintsLeft', style: mqText(11 * s, color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _slot(double s, String id) {
    final got = _found.contains(id);
    final current = id == _nextTarget;
    Widget pic = Image.asset(mqItemAsset(id), fit: BoxFit.contain);
    if (_lvl.silhouettes && !got) {
      pic = ColorFiltered(
        colorFilter: const ColorFilter.matrix([0, 0, 0, 0, 70, 0, 0, 0, 0, 60, 0, 0, 0, 0, 120, 0, 0, 0, 1, 0]),
        child: pic,
      );
    }
    return GestureDetector(
      onTap: () {
        mqSound(context, 'clickButton');
        setState(() => _say = mqT(context, 'find', {'name': mqItemName(context, id)}));
      },
      child: AnimatedScale(
        scale: current ? 1.06 : 1,
        duration: const Duration(milliseconds: 250),
        child: SizedBox(
          width: 66 * s,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(child: Image.asset(mq(got ? 'mq_slot_ok' : 'mq_slot'), fit: BoxFit.fill)),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(8 * s),
                child: AnimatedOpacity(duration: const Duration(milliseconds: 300), opacity: got ? 0.55 : 1, child: pic),
              ),
            ),
            if (got)
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('ok$id'),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  builder: (_, v, c) => Transform.scale(scale: v, child: c),
                  child: Center(child: Image.asset(mq('mq_check'), width: 30 * s)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════

class _PauseDialog extends StatelessWidget {
  final VoidCallback onQuit, onResume;
  const _PauseDialog({required this.onQuit, required this.onResume});
  @override
  Widget build(BuildContext context) => MqFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = (min(MediaQuery.sizeOf(context).width, 520.0) / 390).clamp(0.78, 1.3).toDouble();
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 300 * s,
          padding: EdgeInsets.all(18 * s),
          decoration: BoxDecoration(
            color: mqCream,
            borderRadius: BorderRadius.circular(26 * s),
            border: Border.all(color: const Color(0xFFF2C46B), width: 3 * s),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset(mq('mq_robot_mag'), height: 90 * s),
            SizedBox(height: 6 * s),
            Text(mqT(context, 'paused'), style: mqText(24 * s)),
            SizedBox(height: 14 * s),
            MqBigButton(label: mqT(context, 'resume'), onTap: onResume, width: 240 * s, s: s),
            SizedBox(height: 6 * s),
            TextButton(onPressed: onQuit, child: Text(mqT(context, 'quit'), style: mqText(16 * s, color: mqInkSoft, weight: FontWeight.w600))),
          ]),
        ),
      ),
    );
  }
}

class _EndDialog extends StatefulWidget {
  final bool won, hasNext;
  final int stars, gold, found, total;
  const _EndDialog({required this.won, required this.stars, required this.gold, required this.found, required this.total, required this.hasNext});
  @override
  State<_EndDialog> createState() => _EndDialogState();
}

class _EndDialogState extends State<_EndDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MqFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = (min(MediaQuery.sizeOf(context).width, 520.0) / 390).clamp(0.78, 1.3).toDouble();
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: 330 * s,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
            Container(
              margin: EdgeInsets.only(top: 60 * s),
              padding: EdgeInsets.fromLTRB(18 * s, 70 * s, 18 * s, 16 * s),
              decoration: BoxDecoration(
                color: mqCream,
                borderRadius: BorderRadius.circular(28 * s),
                border: Border.all(color: const Color(0xFFF2C46B), width: 3 * s),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24 * s)],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(widget.won ? mqT(context, 'win') : mqT(context, 'timeUp'), textAlign: TextAlign.center, style: mqText(26 * s)),
                SizedBox(height: 8 * s),
                if (widget.won)
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var i = 0; i < 3; i++)
                      AnimatedBuilder(
                        animation: _a,
                        builder: (_, __) {
                          final t = Curves.elasticOut.transform(((_a.value - 0.15 - i * 0.18) / 0.45).clamp(0.0, 1.0));
                          final on = i < widget.stars;
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4 * s),
                            child: Transform.translate(
                              offset: Offset(0, i == 1 ? -10 * s : 0),
                              child: Transform.scale(
                                scale: on ? t : 1,
                                child: Image.asset(mq(on ? 'mq_star_w' : 'mq_star_g'),
                                    width: (i == 1 ? 62 : 52) * s,
                                    color: on ? const Color(0xFFFFC21A) : null,
                                    colorBlendMode: BlendMode.modulate),
                              ),
                            ),
                          );
                        },
                      ),
                  ])
                else
                  Text(mqT(context, 'timeUpSub', {'n': widget.found, 't': widget.total}),
                      textAlign: TextAlign.center, style: mqText(15 * s, color: mqInkSoft, weight: FontWeight.w500)),
                if (widget.gold > 0) ...[
                  SizedBox(height: 8 * s),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 5 * s),
                    decoration: BoxDecoration(color: const Color(0xFFFFF0C2), borderRadius: BorderRadius.circular(20 * s)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.monetization_on_rounded, color: const Color(0xFFF2A900), size: 20 * s),
                      SizedBox(width: 5 * s),
                      Text(mqT(context, 'gold', {'n': widget.gold}), style: mqText(16 * s, color: const Color(0xFFB45309))),
                    ]),
                  ),
                ],
                SizedBox(height: 16 * s),
                if (widget.won && widget.hasNext)
                  MqBigButton(label: mqT(context, 'next'), onTap: () => Navigator.pop(context, 'next'), width: 260 * s, s: s),
                SizedBox(height: 6 * s),
                Row(children: [
                  Expanded(child: _small(s, Icons.refresh_rounded, mqT(context, 'again'), () => Navigator.pop(context, 'again'))),
                  SizedBox(width: 8 * s),
                  Expanded(child: _small(s, Icons.home_rounded, mqT(context, 'backHouse'), () => Navigator.pop(context, 'back'))),
                ]),
              ]),
            ),
            // celebrating robot on top
            AnimatedBuilder(
              animation: _a,
              builder: (_, c) => Transform.scale(scale: Curves.elasticOut.transform(_a.value.clamp(0.0, 1.0)), child: c),
              child: Image.asset(mq(widget.won ? 'mq_robot_mag' : 'mq_robot_point'), height: 120 * s),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _small(double s, IconData icon, String text, VoidCallback onTap) => MqPress(
        onTap: onTap,
        child: Container(
          height: 46 * s,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24 * s),
            border: Border.all(color: const Color(0xFFE8DCC4), width: 2 * s),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: mqBlue, size: 20 * s),
            SizedBox(width: 5 * s),
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, style: mqText(15 * s)))),
          ]),
        ),
      );
}

/// Floating golden dust in the sunbeams.
class _DustPainter extends CustomPainter {
  final double t;
  _DustPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(17);
    for (var i = 0; i < 22; i++) {
      final x0 = r.nextDouble() * size.width;
      final y0 = r.nextDouble() * size.height;
      final sp = 0.4 + r.nextDouble();
      final ph = r.nextDouble();
      final tt = (t * sp + ph) % 1.0;
      final x = x0 + sin((tt + ph) * 2 * pi) * 14;
      final y = y0 - tt * 40;
      final o = sin(tt * pi) * 0.55;
      canvas.drawCircle(Offset(x, y), 1.5 + r.nextDouble() * 2, Paint()..color = const Color(0xFFFFF1B8).withOpacity(o));
    }
  }

  @override
  bool shouldRepaint(_DustPainter o) => o.t != t;
}
