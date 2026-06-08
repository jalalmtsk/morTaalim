import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'shape_data.dart';
import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';

// ═══════════════════════════════════════════════════════════════
//  🌈 SHAPE PLANET ACADEMY — Game Page
//  BRIGHT candy-colour background (no dark space in game).
//  When shape is matched correctly → it STAYS rendered inside
//  the portal box (full-size, animated pop-in).
//  Ads: banner bottom + interstitial on replay.
// ═══════════════════════════════════════════════════════════════

class ShapeSorterPage extends StatefulWidget {
  final ShapeLevel level;
  const ShapeSorterPage({required this.level, super.key});
  @override State<ShapeSorterPage> createState() => _ShapeSorterPageState();
}

class _ShapeSorterPageState extends State<ShapeSorterPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  // ── Game state ───────────────────────────────────────────────
  late List<ShapeData> _shapes;       // portals order (fixed per round)
  late List<ShapeData> _planetOrder;  // draggables order (shuffled & different from portals)
  final Map<String, ShapeData> _matchedShapes = {}; // name → shape (keeps data for rendering)
  int    _score    = 0;
  int    _hearts   = 3;
  int    _loop     = 0;
  int    _timeLeft = 0;
  Timer? _timer;

  String? _hoveredPortal;
  String? _rejectedPortal;
  String? _lastFunFact;
  bool    _showFunFact = false;

  // ── Animations ───────────────────────────────────────────────
  late final ConfettiController _confetti;
  late final AnimationController _bgCtrl;      // BG gradient pulse
  late final AnimationController _portalCtrl;  // portal ring spin
  late final AnimationController _shakeCtrl;
  late final Animation<double>   _shakeAnim;
  late final AnimationController _funFactCtrl;
  late final Animation<double>   _funFactAnim;
  late final AnimationController _floatCtrl;   // planet idle float

  // Per-shape pop-in on match
  final Map<String, AnimationController> _popCtrl  = {};
  final Map<String, Animation<double>>   _popScale = {};

  // ── Random ───────────────────────────────────────────────────
  final Random _rng = Random();

  // ── Ads ──────────────────────────────────────────────────────
  BannerAd? _bannerAd;
  bool      _bannerLoaded = false;

  // ── Background confetti dots (decorative, static seed) ───────
  late final List<_BgDot> _bgDots;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final rng = Random(42);
    _bgDots = List.generate(22, (_) => _BgDot(
      x: rng.nextDouble(), y: rng.nextDouble(),
      size: 20 + rng.nextDouble() * 50,
      color: _kBrightPalette[rng.nextInt(_kBrightPalette.length)]
          .withOpacity(0.10 + rng.nextDouble() * 0.12),
    ));

    _confetti = ConfettiController(duration: const Duration(seconds: 3));

    _bgCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 5))..repeat(reverse: true);

    _portalCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 5))..repeat();

    _floatCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat(reverse: true);

    _shakeCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 380));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0,  end: 14.0),  weight: 20),
      TweenSequenceItem(tween: Tween(begin: 14.0, end: -14.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: -14.0, end: 0.0),  weight: 40),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _funFactCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 450));
    _funFactAnim = CurvedAnimation(parent: _funFactCtrl, curve: Curves.elasticOut);

    _loadBannerAd();
    _startRound();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _confetti.dispose();
    _bgCtrl.dispose(); _portalCtrl.dispose(); _floatCtrl.dispose();
    _shakeCtrl.dispose(); _funFactCtrl.dispose();
    for (final c in _popCtrl.values) c.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd?.dispose(); _bannerLoaded = false;
    if (!mounted) return;
    if (!Provider.of<ExperienceManager>(context, listen: false).adsEnabled) return;
    _bannerAd = AdHelper.getBannerAd(() {
      if (mounted) setState(() => _bannerLoaded = true);
    });
  }

  // ── Round management ─────────────────────────────────────────
  void _startRound() {
    _matchedShapes.clear();
    _hoveredPortal = _rejectedPortal = null;
    _showFunFact = false;

    for (final c in _popCtrl.values) c.dispose();
    _popCtrl.clear(); _popScale.clear();

    final offset = (_loop * 3) % kAllShapes.length;
    final pool   = [...kAllShapes.sublist(offset), ...kAllShapes.sublist(0, offset)];
    _shapes      = pool.take(widget.level.shapeCount).toList();

    // Shuffle planet order — keep re-shuffling until it differs from portal order
    // (so at least the first item is different, preventing an obvious 1-to-1 match)
    _planetOrder = List.of(_shapes)..shuffle(_rng);
    int attempts = 0;
    while (attempts < 10 && _shapes.length > 1 &&
        _planetOrder.first.name == _shapes.first.name) {
      _planetOrder.shuffle(_rng);
      attempts++;
    }

    for (final s in _shapes) {
      final c = AnimationController(vsync: this,
          duration: const Duration(milliseconds: 420));
      _popCtrl[s.name]  = c;
      _popScale[s.name] = TweenSequence([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.30), weight: 45),
        TweenSequenceItem(tween: Tween(begin: 1.30, end: 1.0),  weight: 55),
      ]).animate(CurvedAnimation(parent: c, curve: Curves.easeOut));
    }

    _timer?.cancel();
    if (widget.level.timeSeconds > 0) {
      _timeLeft = max(10, widget.level.timeSeconds - _loop * 3);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _timeLeft--);
        if (_timeLeft <= 0) { _timer?.cancel(); _onTimeUp(); }
      });
    }
    setState(() {});
  }

  // ── Drop logic ───────────────────────────────────────────────
  void _onDrop(ShapeData shape, String targetName) {
    if (_matchedShapes.containsKey(shape.name)) return;

    if (shape.name == targetName) {
      // ✅ CORRECT — store shape so portal renders it permanently
      HapticFeedback.lightImpact();
      _popCtrl[shape.name]?.forward();

      setState(() {
        _matchedShapes[shape.name] = shape;
        _score += 10 + (_loop * 2);
        _lastFunFact = shape.funFact;
        _showFunFact = true;
        _hoveredPortal = null;
        // Re-shuffle remaining unmatched planets so kids can't memorise positions
        final unmatched = _planetOrder
            .where((s) => !_matchedShapes.containsKey(s.name))
            .toList()..shuffle(_rng);
        final matched = _planetOrder
            .where((s) =>  _matchedShapes.containsKey(s.name))
            .toList();
        _planetOrder = [...unmatched, ...matched];
      });
      _funFactCtrl.reset(); _funFactCtrl.forward();
      Future.delayed(const Duration(milliseconds: 2400), () {
        if (mounted) setState(() => _showFunFact = false);
      });
      if (_matchedShapes.length == _shapes.length) {
        _timer?.cancel();
        Future.delayed(const Duration(milliseconds: 700), _onWin);
      }
    } else {
      // ❌ WRONG
      HapticFeedback.heavyImpact();
      setState(() {
        _hearts = max(0, _hearts - 1);
        _rejectedPortal = targetName;
        _hoveredPortal  = null;
      });
      _shakeCtrl.reset(); _shakeCtrl.forward();
      Future.delayed(const Duration(milliseconds: 420),
              () { if (mounted) setState(() => _rejectedPortal = null); });
      if (_hearts <= 0) { _timer?.cancel(); _onGameOver(); }
    }
  }

  void _onWin() {
    _confetti.play();
    Provider.of<ExperienceManager>(context, listen: false)
        .addXP(_loop + 1, context: context);
    _showEndDialog(isWin: true);
  }
  void _onTimeUp()   => _showEndDialog(isWin: false);
  void _onGameOver() => _showEndDialog(isWin: false);

  void _showEndDialog({required bool isWin}) {
    final stars = _hearts == 3 ? 3 : _hearts == 2 ? 2 : 1;
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFFF8F0), Color(0xFFFFEEFF)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
                color: isWin ? const Color(0xFFFFD700) : const Color(0xFFEF4444),
                width: 3),
            boxShadow: [BoxShadow(
                color: (isWin ? const Color(0xFFFFD700) : const Color(0xFFEF4444))
                    .withOpacity(0.40),
                blurRadius: 30)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(isWin ? '🎉' : '😢',
                style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 6),
            Text(isWin ? 'Amazing Job!' : 'Try Again!',
                style: TextStyle(fontFamily: 'Fredoka One', fontSize: 28,
                    color: isWin ? const Color(0xFFFF6B35)
                        : const Color(0xFFEF4444))),
            if (isWin) ...[
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(i < stars ? '⭐' : '☆',
                          style: TextStyle(fontSize: i < stars ? 36 : 28,
                              color: i < stars ? const Color(0xFFFFD700)
                                  : Colors.grey.shade300))))),
            ],
            const SizedBox(height: 8),
            Text('Score: $_score',
                style: const TextStyle(fontFamily: 'Fredoka One',
                    fontSize: 22, color: Color(0xFF6C63FF))),
            if (isWin)
              Text('Round ${_loop + 1} complete! 🚀',
                  style: const TextStyle(fontFamily: 'Fredoka One',
                      fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _BrightBtn(
                label: isWin ? '▶ Next Round' : '🔄 Retry',
                color: isWin ? const Color(0xFFFF6B35) : const Color(0xFF6C63FF),
                onTap: () {
                  Navigator.pop(context);
                  // Show interstitial before resetting
                  AdHelper.showInterstitialAd(
                    context: context,
                    onDismissed: () {
                      if (mounted) setState(() {
                        if (isWin) _loop++;
                        _hearts = 3;
                      });
                      _startRound();
                    },
                  );
                },
              )),
              const SizedBox(width: 10),
              Expanded(child: _BrightBtn(
                label: '🏠 Menu',
                color: Colors.grey.shade300,
                textColor: Colors.grey.shade700,
                onTap: () { Navigator.pop(context); Navigator.pop(context); },
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final adsOn = context.watch<ExperienceManager>().adsEnabled;
    return Scaffold(
      // Bright warm background colour
      backgroundColor: const Color(0xFFFFF3E0),
      bottomNavigationBar: adsOn
          ? _AdBannerBar(bannerAd: _bannerAd, isLoaded: _bannerLoaded)
          : null,
      body: Stack(children: [
        // ── ANIMATED GRADIENT BG ────────────────────────────
        AnimatedBuilder(animation: _bgCtrl, builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [
                  Color.lerp(const Color(0xFFFFF3E0), const Color(0xFFFFE8F5),
                      _bgCtrl.value)!,
                  Color.lerp(const Color(0xFFE8F4FF), const Color(0xFFF0EDFF),
                      _bgCtrl.value)!,
                  Color.lerp(const Color(0xFFFFFFE0), const Color(0xFFFFF0E8),
                      _bgCtrl.value)!,
                ],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        )),

        // ── DECORATIVE BG BLOBS ─────────────────────────────
        ..._bgDots.map((d) => Positioned(
            left: d.x * MediaQuery.of(context).size.width,
            top:  d.y * MediaQuery.of(context).size.height,
            child: Container(
                width: d.size, height: d.size,
                decoration: BoxDecoration(shape: BoxShape.circle, color: d.color)))),

        // ── CONTENT ─────────────────────────────────────────
        SafeArea(child: Column(children: [
          _buildHUD(),
          const SizedBox(height: 6),
          if (widget.level.timeSeconds > 0) ...[
            _buildTimerBar(),
            const SizedBox(height: 6),
          ],
          // Portals
          Expanded(flex: 5, child: _buildPortals()),
          // Fun fact
          AnimatedSize(
              duration: const Duration(milliseconds: 280),
              child: _showFunFact ? _buildFunFact() : const SizedBox.shrink()),
          // Planets
          Expanded(flex: 4, child: _buildPlanets()),
          const SizedBox(height: 4),
        ])),

        // ── CONFETTI ────────────────────────────────────────
        Align(alignment: Alignment.topCenter,
            child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                colors: const [Color(0xFFFF6B35), Color(0xFFFFD700),
                  Color(0xFF6C63FF), Color(0xFF00D4AA), Color(0xFFFF6B9D)],
                numberOfParticles: 50, maxBlastForce: 28,
                minBlastForce: 12, gravity: 0.22)),
      ]),
    );
  }

  // ── HUD ────────────────────────────────────────────────────
  Widget _buildHUD() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: widget.level.color.withOpacity(0.35), width: 1.8),
        boxShadow: [BoxShadow(
            color: widget.level.color.withOpacity(0.18),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); Navigator.pop(context); },
          child: Container(width: 38, height: 38,
              decoration: BoxDecoration(
                  color: widget.level.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: widget.level.color.withOpacity(0.40), width: 1.2)),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: widget.level.color)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
              color: widget.level.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.level.color.withOpacity(0.40), width: 1.2)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.level.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text('Round ${_loop + 1}',
                style: TextStyle(fontFamily: 'Fredoka One',
                    fontSize: 13, color: widget.level.color)),
          ]),
        ),
        const Spacer(),
        // Score
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFFF6B35).withOpacity(0.45), width: 1.2)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('⭐', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text('$_score',
                style: const TextStyle(fontFamily: 'Fredoka One',
                    fontSize: 14, color: Color(0xFFFF6B35))),
          ]),
        ),
        const SizedBox(width: 8),
        Row(children: List.generate(3, (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(i < _hearts ? '❤️' : '🤍',
                style: const TextStyle(fontSize: 18))))),
      ]),
    );
  }

  // ── TIMER BAR ──────────────────────────────────────────────
  Widget _buildTimerBar() {
    final maxTime = max(10, widget.level.timeSeconds - _loop * 3);
    final pct     = (_timeLeft / maxTime).clamp(0.0, 1.0);
    final barColor = pct > 0.5
        ? const Color(0xFF22C55E)
        : pct > 0.25 ? const Color(0xFFFFD700)
        : const Color(0xFFEF4444);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        const Text('⏱️', style: TextStyle(fontSize: 15)),
        const SizedBox(width: 6),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(children: [
            Container(height: 12, decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10))),
            AnimatedFractionallySizedBox(
              widthFactor: pct,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              child: Container(height: 12,
                  decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(
                          color: barColor.withOpacity(0.65), blurRadius: 8)])),
            ),
          ]),
        )),
        const SizedBox(width: 8),
        Text('${_timeLeft}s',
            style: TextStyle(fontFamily: 'Fredoka One',
                fontSize: 14, color: barColor)),
      ]),
    );
  }

  // ── PORTALS ────────────────────────────────────────────────
  Widget _buildPortals() {
    final n    = _shapes.length;
    final cols = n <= 4 ? 2 : n <= 6 ? 3 : n <= 8 ? 4 : 5;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 8, mainAxisSpacing: 8,
        childAspectRatio: 0.90,
      ),
      itemCount: n,
      itemBuilder: (_, i) {
        final shape    = _shapes[i];
        final matched  = _matchedShapes.containsKey(shape.name);
        final hovered  = _hoveredPortal  == shape.name;
        final rejected = _rejectedPortal == shape.name;

        return DragTarget<ShapeData>(
          onWillAccept: (_) {
            if (!matched) setState(() => _hoveredPortal = shape.name);
            return !matched;
          },
          onLeave:  (_) => setState(() => _hoveredPortal = null),
          onAccept: (d) => _onDrop(d, shape.name),
          builder: (_, candidates, __) {
            return AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.translate(
                  offset: Offset(rejected ? _shakeAnim.value : 0, 0),
                  child: child),
              child: _PortalBox(
                shape:       shape,
                matched:     matched,
                hovered:     hovered,
                rejected:    rejected,
                portalCtrl:  _portalCtrl,
                popScale:    matched ? _popScale[shape.name] : null,
              ),
            );
          },
        );
      },
    );
  }

  // ── FUN FACT ───────────────────────────────────────────────
  Widget _buildFunFact() {
    return ScaleTransition(
      scale: _funFactAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFFD700)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.35),
              blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          const Text('💡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(child: Text(_lastFunFact ?? '',
              style: const TextStyle(fontFamily: 'Fredoka One',
                  fontSize: 13, color: Colors.white, height: 1.3))),
        ]),
      ),
    );
  }

  // ── PLANETS (draggables) ───────────────────────────────────
  Widget _buildPlanets() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.80), width: 1.5),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Drag shapes to their boxes! 🎯',
            style: TextStyle(fontFamily: 'Fredoka One', fontSize: 13,
                color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        Expanded(child: Center(child: AnimatedBuilder(
          animation: _floatCtrl,
          builder: (_, __) => Wrap(
            spacing: 10, runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _planetOrder.map((shape) {
              final isMatched = _matchedShapes.containsKey(shape.name);
              final floatDy   = sin(_floatCtrl.value * pi +
                  _planetOrder.indexOf(shape) * 0.7) * 5;

              final tile = Transform.translate(
                offset: Offset(0, isMatched ? 0 : floatDy),
                child: _PlanetTile(shape: shape, isMatched: isMatched),
              );

              if (isMatched) return tile;

              return Draggable<ShapeData>(
                data: shape,
                onDragStarted: () => HapticFeedback.selectionClick(),
                feedback: Material(color: Colors.transparent,
                    child: SizedBox(width: 68, height: 68,
                        child: CustomPaint(painter: ShapeCustomPainter(
                            type: shape.painterType,
                            color: shape.color, glow: shape.glow,
                            glowRadius: 16)))),
                childWhenDragging: Opacity(opacity: 0.25, child: tile),
                child: tile,
              );
            }).toList(),
          ),
        ))),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PORTAL BOX — drop target
//  When matched: renders the actual shape (full-size, glowing)
//  with a pop-in scale animation.
// ═══════════════════════════════════════════════════════════════
class _PortalBox extends StatelessWidget {
  final ShapeData            shape;
  final bool                 matched, hovered, rejected;
  final AnimationController  portalCtrl;
  final Animation<double>?   popScale;

  const _PortalBox({
    required this.shape,
    required this.matched,
    required this.hovered,
    required this.rejected,
    required this.portalCtrl,
    required this.popScale,
  });

  @override
  Widget build(BuildContext context) {
    // Colours
    Color borderColor = matched
        ? shape.color
        : hovered
        ? const Color(0xFFFF6B35)
        : rejected
        ? const Color(0xFFEF4444)
        : shape.color.withOpacity(0.35);

    double borderW = matched ? 3.0 : hovered || rejected ? 3.5 : 2.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: matched
            ? shape.color.withOpacity(0.14)
            : hovered
            ? const Color(0xFFFF6B35).withOpacity(0.08)
            : Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: borderW),
        boxShadow: [
          if (matched)
            BoxShadow(color: shape.glow.withOpacity(0.50),
                blurRadius: 18, spreadRadius: 1),
          if (hovered)
            BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.40),
                blurRadius: 14),
          if (rejected)
            BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.45),
                blurRadius: 14),
          if (!matched && !hovered && !rejected)
            BoxShadow(color: Colors.black.withOpacity(0.06),
                blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Stack(alignment: Alignment.center, children: [
        // Spinning dashed ring (only when unmatched)
        if (!matched)
          Positioned.fill(child: AnimatedBuilder(
            animation: portalCtrl,
            builder: (_, __) => Transform.rotate(
              angle: portalCtrl.value * 2 * pi,
              child: CustomPaint(painter: _DashedRingPainter(
                  color: shape.color.withOpacity(hovered ? 0.60 : 0.25))),
            ),
          )),

        // Content
        Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Shape
              Flexible(
                child: matched
                    ? _MatchedShape(shape: shape, popScale: popScale)
                    : _GhostShape(shape: shape),
              ),
              const SizedBox(height: 3),
              // Name label
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  shape.name,
                  style: TextStyle(
                    fontFamily: 'Fredoka One',
                    fontSize: 12,
                    color: matched
                        ? shape.color
                        : Colors.grey.shade600,
                  ),
                ),
              ),
              // ✓ badge when matched
              if (matched)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text('✓',
                      style: TextStyle(fontSize: 10, color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

// Matched shape stays visible with pop-in animation
class _MatchedShape extends StatelessWidget {
  final ShapeData           shape;
  final Animation<double>?  popScale;
  const _MatchedShape({required this.shape, required this.popScale});

  @override
  Widget build(BuildContext context) {
    final painter = ShapeCustomPainter(
        type: shape.painterType, color: shape.color,
        glow: shape.glow, glowRadius: 12);
    if (popScale == null) {
      return AspectRatio(aspectRatio: 1,
          child: CustomPaint(painter: painter));
    }
    return AnimatedBuilder(
      animation: popScale!,
      builder: (_, __) => Transform.scale(
        scale: popScale!.value.clamp(0.0, 1.4),
        child: AspectRatio(aspectRatio: 1,
            child: CustomPaint(painter: painter)),
      ),
    );
  }
}

// Ghost shape (dashed outline) shown before matching
class _GhostShape extends StatelessWidget {
  final ShapeData shape;
  const _GhostShape({required this.shape});
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: CustomPaint(painter: ShapeCustomPainter(
        type: shape.painterType, color: shape.color,
        glow: shape.glow, isGhost: true)),
  );
}

// ═══════════════════════════════════════════════════════════════
//  PLANET TILE  (draggable shape at bottom)
// ═══════════════════════════════════════════════════════════════
class _PlanetTile extends StatelessWidget {
  final ShapeData shape;
  final bool      isMatched;
  const _PlanetTile({required this.shape, required this.isMatched});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isMatched ? 0.25 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 54, height: 54,
            child: CustomPaint(painter: isMatched
                ? ShapeCustomPainter(type: shape.painterType,
                color: Colors.grey.shade400, glow: Colors.grey)
                : ShapeCustomPainter(type: shape.painterType,
                color: shape.color, glow: shape.glow, glowRadius: 10))),
        const SizedBox(height: 3),
        FittedBox(fit: BoxFit.scaleDown,
            child: Text(shape.name,
                style: TextStyle(fontFamily: 'Fredoka One', fontSize: 11,
                    color: isMatched
                        ? Colors.grey.shade400
                        : Colors.grey.shade700))),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  DASHED RING PAINTER (portal idle spinner)
// ═══════════════════════════════════════════════════════════════
class _DashedRingPainter extends CustomPainter {
  final Color color;
  const _DashedRingPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2;
    final r  = min(cx, cy) - 5;
    final p  = Paint()
      ..color = color ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 ..strokeCap = StrokeCap.round;
    const dashes = 10;
    for (int i = 0; i < dashes; i++) {
      final a1 = 2 * pi * i / dashes;
      final a2 = 2 * pi * (i + 0.52) / dashes;
      canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r),
          a1, a2 - a1, false, p);
    }
  }
  @override bool shouldRepaint(_DashedRingPainter o) => o.color != color;
}

// ═══════════════════════════════════════════════════════════════
//  BRIGHT BUTTON
// ═══════════════════════════════════════════════════════════════
class _BrightBtn extends StatelessWidget {
  final String label; final VoidCallback onTap;
  final Color color; final Color? textColor;
  const _BrightBtn({required this.label, required this.onTap,
    required this.color, this.textColor});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: color.withOpacity(0.40),
                  blurRadius: 10, offset: const Offset(0, 4))]),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontFamily: 'Fredoka One',
              fontSize: 15, color: textColor ?? Colors.white))));
}

// ═══════════════════════════════════════════════════════════════
//  AD BANNER BAR
// ═══════════════════════════════════════════════════════════════
class _AdBannerBar extends StatefulWidget {
  final BannerAd? bannerAd; final bool isLoaded;
  const _AdBannerBar({required this.bannerAd, required this.isLoaded});
  @override State<_AdBannerBar> createState() => _AdBannerBarState();
}
class _AdBannerBarState extends State<_AdBannerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _s;
  late final Animation<double>   _a;
  @override void initState() {
    super.initState();
    _s = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _a = CurvedAnimation(parent: _s, curve: Curves.easeInOut);
  }
  @override void dispose() { _s.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final adH = (widget.bannerAd?.size.height.toDouble() ?? 50.0).clamp(40.0, 90.0);
    return SafeArea(top: false,
        child: Container(
          height: adH + 10,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)]),
            boxShadow: [BoxShadow(
                color: Color(0x226C63FF), blurRadius: 12,
                offset: Offset(0, -3))],
          ),
          child: widget.isLoaded && widget.bannerAd != null
              ? Center(child: SizedBox(
              height: adH,
              width:  widget.bannerAd!.size.width.toDouble(),
              child:  AdWidget(ad: widget.bannerAd!)))
              : AnimatedBuilder(animation: _a, builder: (_, __) {
            final t = _a.value;
            return Padding(padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 5),
                child: Row(children: [
                  Opacity(opacity: .5+t*.5,
                      child: const Text('🪐', style: TextStyle(fontSize: 16))),
                  const SizedBox(width: 8),
                  Expanded(child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(height: 26,
                          color: Colors.white.withOpacity(.14+t*.14),
                          alignment: Alignment.center,
                          child: Text('✨  Advertisement  ✨',
                              style: TextStyle(fontFamily: 'Fredoka One', fontSize: 11,
                                  color: Colors.white.withOpacity(.65+t*.25)))))),
                  const SizedBox(width: 8),
                  Opacity(opacity: .5+t*.5,
                      child: const Text('🌈', style: TextStyle(fontSize: 16))),
                ]));
          }),
        ));
  }
}

// ── Helpers ────────────────────────────────────────────────────
class _BgDot {
  final double x, y, size;
  final Color  color;
  _BgDot({required this.x, required this.y,
    required this.size, required this.color});
}

const List<Color> _kBrightPalette = [
  Color(0xFFFF6B35), Color(0xFFFFD700), Color(0xFF6C63FF),
  Color(0xFF00D4AA), Color(0xFFFF6B9D), Color(0xFF22C55E),
  Color(0xFF0EA5E9), Color(0xFFEC4899),
];