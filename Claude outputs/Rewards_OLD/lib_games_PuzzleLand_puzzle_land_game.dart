import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/games/BrainBuilder/bb_common.dart' show BBTitle, BBPill, bbCream, bbInk;
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

import 'pz_common.dart';

/// One Puzzle Land round: drag the jigsaw pieces from the tray onto the board.
class PuzzleLandGame extends StatefulWidget {
  final String picture;
  final int difficulty; // 0 easy (3×3), 1 medium (4×4), 2 hard (5×5)
  const PuzzleLandGame({super.key, required this.picture, required this.difficulty});

  @override
  State<PuzzleLandGame> createState() => _PuzzleLandGameState();
}

class _PuzzleLandGameState extends State<PuzzleLandGame> with TickerProviderStateMixin {
  static const int _hintCost = 10;

  late final int _n = pzGrid[widget.difficulty];
  late final PZCut _cut = PZCut(_n, widget.picture.hashCode ^ (widget.difficulty * 7919));
  late final String _img = PZAssets.picture(widget.picture);
  final Set<int> _placed = {};
  List<int> _tray = [];
  int _mistakes = 0, _hintsUsed = 0, _hintsLeft = 3, _prevStars = 0;
  int? _hintPiece; // piece whose slot is glowing
  int? _popPiece; // last placed piece (pop animation)
  bool _preview = false, _won = false;
  String? _tipKey;
  Timer? _tipTimer, _previewTimer, _hintTimer;
  final GlobalKey _fieldKey = GlobalKey();
  final Random _rnd = Random();

  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  late final ConfettiController _confetti = ConfettiController(duration: const Duration(seconds: 2));

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);
  int get _total => _n * _n;

  @override
  void initState() {
    super.initState();
    _shuffle();
    PZProgress.starsOf(widget.picture, widget.difficulty).then((v) {
      if (mounted) setState(() => _prevStars = v);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(AssetImage(_img), context);
    for (final a in [PZAssets.bg, PZAssets.board, PZAssets.tray, PZAssets.winFrame]) {
      precacheImage(AssetImage(a), context);
    }
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _previewTimer?.cancel();
    _hintTimer?.cancel();
    _idle.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _shuffle() {
    _tray = [for (var i = 0; i < _total; i++) if (!_placed.contains(i)) i]..shuffle(_rnd);
  }

  void _say(String key) {
    _tipTimer?.cancel();
    setState(() => _tipKey = key);
    _tipTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _tipKey = null);
    });
  }

  int get _stars {
    var s = _mistakes <= max(1, _n - 2) ? 3 : (_mistakes <= _n * 2 ? 2 : 1);
    if (_hintsUsed > 0) s = min(s, 2);
    return s;
  }

  // ─── Gameplay ───────────────────────────────────────────────────────────

  void _drop(int piece, Offset pointerGlobal, double cell) {
    if (_won) return;
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pieceBox = PZPiece.boxFor(cell);
    final local = box.globalToLocal(pointerGlobal + Offset(0, -pieceBox * 0.1));
    final r = piece ~/ _n, c = piece % _n;
    final target = Offset((c + 0.5) * cell, (r + 0.5) * cell);
    if ((local - target).distance <= cell * 0.45) {
      _place(piece);
    } else {
      _mistakes++;
      HapticFeedback.lightImpact();
      _audio.playEventSound('invalid');
      _say('almost');
    }
  }

  void _place(int piece) {
    _audio.playEventSound('starSound');
    HapticFeedback.selectionClick();
    setState(() {
      _placed.add(piece);
      _tray.remove(piece);
      _popPiece = piece;
      if (_hintPiece == piece) _hintPiece = null;
    });
    if (_placed.length == _total) {
      _win();
    } else {
      _say(_placed.length >= _total * 0.6 ? 'great' : 'nice');
    }
  }

  void _useHint() {
    if (_won || _tray.isEmpty) return;
    if (_hintsLeft <= 0) {
      _buyHints();
      return;
    }
    _audio.playEventSound('PopButton');
    final piece = _tray.first;
    _hintTimer?.cancel();
    setState(() {
      _hintsLeft--;
      _hintsUsed++;
      _hintPiece = piece;
    });
    _say('hintTip');
    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _hintPiece = null);
    });
  }

  Future<void> _buyHints() async {
    _audio.playEventSound('clickButton2');
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: KidColors.purpleDeep.withOpacity(0.35),
      builder: (ctx) => KidDialog(
        headerAsset: PZAssets.hint,
        headerAspect: 389 / 185,
        title: pzT(ctx, 'moreHints'),
        message: pzT(ctx, 'moreHintsMsg', {'n': _hintCost}),
        actions: [
          KidOutlineButton(label: MaterialLocalizations.of(ctx).cancelButtonLabel, onTap: () => Navigator.pop(ctx, false)),
          const SizedBox(height: 10),
          KidButton(
            label: pzT(ctx, 'buy'),
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

  void _togglePreview() {
    _audio.playEventSound('toggleButton');
    _previewTimer?.cancel();
    setState(() => _preview = !_preview);
    if (_preview) {
      _previewTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _preview = false);
      });
    }
  }

  void _reset() {
    _audio.playEventSound('clickButton2');
    setState(() {
      _placed.clear();
      _mistakes = 0;
      _hintPiece = null;
      _popPiece = null;
      _won = false;
      _shuffle();
    });
  }

  Future<void> _toggleSound() async {
    final a = _audio;
    final mute = !(a.isBgMuted && a.isSfxMuted);
    if (a.isBgMuted != mute) await a.toggleBgMute();
    if (a.isSfxMuted != mute) await a.toggleSfxMute();
    if (mounted) setState(() {});
  }

  Future<void> _win() async {
    setState(() => _won = true);
    final stars = _stars;
    final gold = pzReward(widget.difficulty, stars, _prevStars);
    final newStars = max(0, stars - _prevStars);
    await PZProgress.record(widget.picture, widget.difficulty, stars);
    _confetti.play();
    _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/${stars == 3 ? 'VictoryOrchestral_SFX' : 'victory2_SFX'}.mp3');
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    if (gold > 0) xp.addGold(context, gold);
    if (newStars > 0) xp.addXP(4 + newStars * 3, context: context);

    final pi = pzPictures.indexOf(widget.picture);
    final hasNext = widget.difficulty < pzGrid.length - 1 || pi < pzPictures.length - 1;
    final res = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => _WinCard(image: _img, stars: stars, gold: gold, hasNext: hasNext),
      transitionBuilder: (_, a, __, child) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: child),
      ),
    );
    if (!mounted) return;
    _prevStars = max(_prevStars, stars);
    if (res == 'next' && hasNext) {
      final nextPic = widget.difficulty < pzGrid.length - 1 ? widget.picture : pzPictures[pi + 1];
      final nextDiff = widget.difficulty < pzGrid.length - 1 ? widget.difficulty + 1 : 0;
      // Hand the next puzzle back to the menu so it refreshes progress first.
      Navigator.pop(context, (nextPic, nextDiff));
    } else if (res == 'replay') {
      _reset();
    } else {
      Navigator.pop(context);
    }
  }

  // ─── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8FD3FF),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(PZAssets.bg, fit: BoxFit.cover)),
          SafeArea(child: LayoutBuilder(builder: _layout)),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
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
    final s = min(width / 400, c.maxHeight / 860).clamp(0.62, 1.4).toDouble();
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
            FittedBox(fit: BoxFit.scaleDown, child: BBTitle(pzT(context, 'goal'), size: 30 * s)),
            SizedBox(height: 2 * s),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 4 * s),
              decoration: BoxDecoration(color: const Color(0xFFEDE6FF).withOpacity(0.92), borderRadius: BorderRadius.circular(20)),
              child: Text(pzT(context, 'sub'), style: kidBodyStyle(14 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)),
            ),
            SizedBox(height: 6 * s),
            Expanded(
              child: LayoutBuilder(builder: (_, bc) {
                final side = min(bc.maxWidth - 28 * s, bc.maxHeight - 16 * s);
                return Center(child: _board(side, s));
              }),
            ),
            _tray_(s, width),
            SizedBox(height: 4 * s),
            SizedBox(
              height: 22 * s,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Row(
                  key: ValueKey(_tipKey),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: const Color(0xFFFFC21A), size: 16 * s),
                    SizedBox(width: 6 * s),
                    Text(pzT(context, _tipKey ?? 'great'),
                        style: kidBodyStyle(15 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)
                            .copyWith(shadows: const [Shadow(color: Colors.white, blurRadius: 8)])),
                    SizedBox(width: 6 * s),
                    Icon(Icons.auto_awesome_rounded, color: const Color(0xFFFFC21A), size: 16 * s),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4 * s),
            _bottomBar(s),
            SizedBox(height: 6 * s),
          ],
        ),
      ),
    );
  }

  Widget _spriteButton(String asset, double size, VoidCallback onTap, {bool flip = false, Widget? overlay}) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return KidPressable(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(children: [
          Positioned.fill(child: Transform.flip(flipX: flip && rtl, child: Image.asset(asset, fit: BoxFit.contain))),
          if (overlay != null) Positioned.fill(child: overlay),
        ]),
      ),
    );
  }

  Widget _header(double s) {
    final a = _audio;
    final muted = a.isBgMuted && a.isSfxMuted;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12 * s),
      child: Row(children: [
        _spriteButton(PZAssets.back, 52 * s, () {
          _audio.playEventSound('cancelButton');
          Navigator.maybePop(context);
        }, flip: true),
        Expanded(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: BBTitle(pzT(context, 'title'), size: 34 * s)))),
        _spriteButton(PZAssets.sound, 52 * s, _toggleSound,
            overlay: muted ? Icon(Icons.close_rounded, color: const Color(0xFFFF4D6D), size: 40 * s) : null),
      ]),
    );
  }

  Widget _statsPill(double s) {
    final reward = pzReward(widget.difficulty, _stars, _prevStars);
    final diffKey = const ['easy', 'medium', 'hard'][widget.difficulty];
    return BBPill(
      height: 52 * s,
      padding: EdgeInsets.symmetric(horizontal: 8 * s),
      child: Row(children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
          decoration: BoxDecoration(color: const Color(0xFFE6E0FA), borderRadius: BorderRadius.circular(30)),
          child: Text('${pzT(context, diffKey)} · ${_n}×$_n',
              style: kidBodyStyle(15 * s, color: bbInk, weight: FontWeight.w700)),
        ),
        Expanded(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 2 * s),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: Image.asset(i < _stars ? PZAssets.star : PZAssets.starOff,
                      key: ValueKey(i < _stars), width: (i == 1 ? 32 : 28) * s, height: (i == 1 ? 32 : 28) * s),
                ),
              ),
          ]),
        ),
        Container(width: 2, height: 28 * s, color: const Color(0xFFEDE3CF)),
        SizedBox(width: 8 * s),
        Image.asset(PZAssets.coin, width: 28 * s, height: 28 * s),
        SizedBox(width: 6 * s),
        Text(reward > 0 ? '+$reward' : '✓', style: kidBodyStyle(18 * s, color: bbInk, weight: FontWeight.w700)),
        SizedBox(width: 8 * s),
      ]),
    );
  }

  Widget _board(double side, double s) {
    final h = PZAssets.boardHole;
    final fieldW = side * (h[2] - h[0]);
    final fieldH = side * (h[3] - h[1]);
    final field = min(fieldW, fieldH);
    final cell = field / _n;
    return SizedBox(
      width: side,
      height: side,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: side * h[0],
            top: side * h[1],
            width: fieldW,
            height: fieldH,
            child: DecoratedBox(
              decoration: BoxDecoration(color: const Color(0xFFF4F0FF), borderRadius: BorderRadius.circular(side * 0.04)),
            ),
          ),
          Positioned.fill(child: Image.asset(PZAssets.board, fit: BoxFit.fill)),
          Positioned(
            left: side * h[0] + (fieldW - field) / 2,
            top: side * h[1] + (fieldH - field) / 2,
            width: field,
            height: field,
            child: DragTarget<int>(
              onWillAcceptWithDetails: (_) => !_won,
              onAcceptWithDetails: (d) => _drop(d.data, d.offset, cell),
              builder: (_, candidates, __) => _field(field, cell, candidates.isNotEmpty),
            ),
          ),
          Positioned(
            bottom: -14 * s,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 4 * s),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: Text(pzT(context, 'piecesN', {'n': _placed.length, 't': _total}),
                    style: kidBodyStyle(15 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const ColorFilter _ghost = ColorFilter.matrix([
    0.18, 0.18, 0.18, 0, 150, //
    0.16, 0.16, 0.16, 0, 140,
    0.20, 0.20, 0.20, 0, 190,
    0, 0, 0, 1, 0,
  ]);

  Widget _field(double field, double cell, bool hovering) {
    final box = PZPiece.boxFor(cell);
    final m = cell * PZCut.margin;
    return ClipRRect(
      key: _fieldKey,
      borderRadius: BorderRadius.circular(cell * 0.12),
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cell * 0.12),
              child: Opacity(
                opacity: 0.55,
                child: ColorFiltered(colorFilter: _ghost, child: Image.asset(_img, fit: BoxFit.cover)),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: PZGridPainter(_cut, cell))),
          if (hovering)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cell * 0.12),
                  border: Border.all(color: const Color(0xFF22C7DE).withOpacity(0.7), width: 3),
                ),
              ),
            ),
          for (final p in _placed)
            Positioned(
              left: (p % _n) * cell - m,
              top: (p ~/ _n) * cell - m,
              width: box,
              height: box,
              child: TweenAnimationBuilder<double>(
                key: ValueKey('placed$p'),
                tween: Tween(begin: p == _popPiece ? 1.18 : 1.0, end: 1.0),
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutBack,
                builder: (_, v, c) => Transform.scale(scale: v, child: c),
                child: PZPiece(cut: _cut, image: _img, row: p ~/ _n, col: p % _n, cell: cell),
              ),
            ),
          if (_hintPiece != null)
            Positioned(
              left: (_hintPiece! % _n) * cell,
              top: (_hintPiece! ~/ _n) * cell,
              width: cell,
              height: cell,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _idle,
                  builder: (_, __) {
                    final t = (sin(_idle.value * 2 * pi * 2) + 1) / 2;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(cell * 0.16),
                        color: const Color(0xFFFFE066).withOpacity(0.25 + 0.25 * t),
                        border: Border.all(color: const Color(0xFFFFC21A), width: 3),
                        boxShadow: [BoxShadow(color: const Color(0xFFFFC21A).withOpacity(0.6), blurRadius: 10 + 10 * t)],
                      ),
                    );
                  },
                ),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _preview || _won ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(cell * 0.12),
                  child: Image.asset(_img, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: non_constant_identifier_names
  Widget _tray_(double s, double width) {
    final h = 124 * s;
    final item = 100 * s;
    // Same piece scale as on the board, so the dragged piece matches its slot.
    final boardCell = _boardCellGuess(s, width);
    return Padding(
      padding: EdgeInsets.fromLTRB(12 * s, 18 * s, 12 * s, 0),
      child: SizedBox(
        height: h,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: Image.asset(PZAssets.tray, fit: BoxFit.fill)),
            if (_tray.isEmpty)
              Center(child: Image.asset(PZAssets.star, width: 56 * s, height: 56 * s))
            else
              ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 10 * s),
                itemCount: _tray.length,
                separatorBuilder: (_, __) => SizedBox(width: 6 * s),
                itemBuilder: (_, i) => _trayPiece(_tray[i], item, boardCell, s, showHand: i == 0),
              ),
          ],
        ),
      ),
    );
  }

  double? _lastCell;
  double _boardCellGuess(double s, double width) => _lastCell ?? (width - 60 * s) * 0.86 / _n;

  Widget _trayPiece(int p, double item, double boardCell, double s, {bool showHand = false}) {
    final cell = _currentCell ?? boardCell;
    final pieceBox = PZPiece.boxFor(cell);
    final piece = PZPiece(cut: _cut, image: _img, row: p ~/ _n, col: p % _n, cell: cell);
    final thumb = SizedBox(width: item, height: item, child: FittedBox(fit: BoxFit.contain, child: piece));
    final glowing = p == _hintPiece;
    final tutorial = showHand && _placed.isEmpty && widget.difficulty == 0 && widget.picture == pzPictures.first;
    return Draggable<int>(
      data: p,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () => _audio.playEventSound('clickButton'),
      feedback: Material(
        type: MaterialType.transparency,
        child: Transform.translate(
          offset: Offset(-pieceBox / 2, -pieceBox * 0.6),
          child: PZPiece(cut: _cut, image: _img, row: p ~/ _n, col: p % _n, cell: cell, lifted: true),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: thumb),
      child: Stack(clipBehavior: Clip.none, children: [
        glowing
            ? AnimatedBuilder(
                animation: _idle,
                builder: (_, c) => Transform.scale(scale: 1 + 0.06 * sin(_idle.value * 2 * pi * 2), child: c),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: const Color(0xFFFFC21A).withOpacity(0.7), blurRadius: 16)],
                  ),
                  child: thumb,
                ),
              )
            : thumb,
        if (tutorial)
          Positioned(
            left: -8 * s,
            bottom: -10 * s,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _idle,
                builder: (_, c) => Transform.translate(offset: Offset(0, -sin(_idle.value * 2 * pi) * 8 * s), child: c),
                child: Image.asset(PZAssets.hand, width: 46 * s),
              ),
            ),
          ),
      ]),
    );
  }

  double? get _currentCell {
    final ctx = _fieldKey.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return _lastCell = box.size.width / _n;
  }

  Widget _bottomBar(double s) {
    Widget pill(String icon, String label, VoidCallback onTap) => Expanded(
          child: KidPressable(
            onTap: onTap,
            child: BBPill(
              height: 56 * s,
              padding: EdgeInsets.symmetric(horizontal: 10 * s),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.asset(icon, width: 34 * s, height: 34 * s),
                SizedBox(width: 6 * s),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label, style: kidBodyStyle(16 * s, color: bbInk, weight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ),
        );
    final empty = _hintsLeft <= 0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12 * s),
      child: Row(children: [
        pill(PZAssets.eye, pzT(context, 'preview'), _togglePreview),
        SizedBox(width: 8 * s),
        Expanded(
          child: KidPressable(
            onTap: _useHint,
            child: Stack(clipBehavior: Clip.none, children: [
              Container(
                height: 60 * s,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 8 * s),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: const LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE66B), Color(0xFFFFBE1A)]),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: const Color(0xFFE08A00).withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  AnimatedBuilder(
                    animation: _idle,
                    builder: (_, c) => Transform.rotate(angle: sin(_idle.value * 2 * pi) * 0.08, child: c),
                    child: Icon(Icons.lightbulb_rounded, color: const Color(0xFFFFF7D1), size: 30 * s,
                        shadows: const [Shadow(color: Color(0xFFE08A00), blurRadius: 6)]),
                  ),
                  SizedBox(width: 4 * s),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(pzT(context, 'hint'), style: kidBodyStyle(20 * s, color: bbInk, weight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),
              PositionedDirectional(
                top: -8 * s,
                end: -4 * s,
                child: Container(
                  width: 28 * s,
                  height: 28 * s,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: empty ? const Color(0xFF22B573) : const Color(0xFFE8740C),
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: empty
                      ? Icon(Icons.add_rounded, color: Colors.white, size: 18 * s)
                      : Text('$_hintsLeft', style: kidBodyStyle(14 * s, color: Colors.white, weight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
        SizedBox(width: 8 * s),
        pill(PZAssets.reset, pzT(context, 'reset'), _reset),
      ]),
    );
  }
}

class _WinCard extends StatefulWidget {
  final String image;
  final int stars, gold;
  final bool hasNext;
  const _WinCard({required this.image, required this.stars, required this.gold, required this.hasNext});

  @override
  State<_WinCard> createState() => _WinCardState();
}

class _WinCardState extends State<_WinCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.stars; i++) {
      Future.delayed(Duration(milliseconds: 400 + i * 300), () {
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
    final fw = w * 0.72, fh = fw * 438 / 395;
    final h = PZAssets.winHole;
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: w,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: bbCream,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFB79CFF), width: 4),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FittedBox(fit: BoxFit.scaleDown, child: BBTitle(pzT(context, widget.stars == 3 ? 'perfect' : 'done'), size: 32)),
            const SizedBox(height: 4),
            SizedBox(
              width: fw,
              height: fh,
              child: Stack(children: [
                Positioned(
                  left: fw * h[0],
                  top: fh * h[1],
                  width: fw * (h[2] - h[0]),
                  height: fh * (h[3] - h[1]),
                  child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset(widget.image, fit: BoxFit.cover)),
                ),
                Positioned.fill(child: Image.asset(PZAssets.winFrame, fit: BoxFit.fill)),
              ]),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: EdgeInsets.only(left: 4, right: 4, bottom: i == 1 ? 8 : 0),
                    child: ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _c,
                        curve: Interval(0.2 + i * 0.2, min(1.0, 0.55 + i * 0.2), curve: Curves.elasticOut),
                      ),
                      child: Image.asset(i < widget.stars ? PZAssets.star : PZAssets.starOff,
                          width: i == 1 ? 60 : 50, height: i == 1 ? 60 : 50),
                    ),
                  ),
              ],
            ),
            if (widget.gold > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFFF1C2), borderRadius: BorderRadius.circular(30)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Image.asset(PZAssets.coin, width: 28, height: 28),
                  const SizedBox(width: 6),
                  Text('+${widget.gold}', style: kidBodyStyle(22, color: bbInk, weight: FontWeight.w700)),
                ]),
              ),
            ],
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: KidOutlineButton(label: pzT(context, 'replay'), onTap: () => Navigator.pop(context, 'replay'))),
              const SizedBox(width: 10),
              Expanded(
                child: KidButton(
                  label: widget.hasNext ? pzT(context, 'next') : MaterialLocalizations.of(context).closeButtonLabel,
                  width: double.infinity,
                  height: 54,
                  onPressed: () => Navigator.pop(context, widget.hasNext ? 'next' : 'menu'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
