import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:provider/provider.dart';

import 'mk_data.dart';

/// One level of Le petit marché.
class MarketPlay extends StatefulWidget {
  final MkLevel level;
  const MarketPlay({super.key, required this.level});
  @override
  State<MarketPlay> createState() => _MarketPlayState();
}

class _Flight {
  final Widget child;
  final Offset from, to;
  final double size;
  final AnimationController c;
  _Flight(this.child, this.from, this.to, this.size, this.c);
}

class _MarketPlayState extends State<MarketPlay> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _bump = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  final Random _rng = Random();
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _dropKey = GlobalKey(); // basket / bowl / coin tray
  final Map<String, GlobalKey> _srcKeys = {};
  final List<_Flight> _flights = [];

  MkLevel get _lv => widget.level;
  int _mistakes = 0, _hints = 0;
  bool _leaving = false, _over = false;
  String _say = '';

  // basket
  late MkList _list;
  bool _listPhase = true;
  final List<String> _basket = [];
  // scale
  late MkWeigh _weigh;
  final List<int> _bowl = [];
  // money
  late MkMoney _money;
  final List<int> _tray = [];

  @override
  void initState() {
    super.initState();
    _list = MkList.make(_lv.n, _rng);
    _weigh = MkWeigh.make(_lv.n, _rng);
    _money = MkMoney.make(_lv.n, _rng);
    _listPhase = _lv.kind == MkKind.basket;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _say = _intro());
      MkVoice.say(context, _say);
    });
  }

  @override
  void dispose() {
    MkVoice.stop();
    for (final f in _flights) {
      f.c.dispose();
    }
    _idle.dispose();
    _bump.dispose();
    _shake.dispose();
    super.dispose();
  }

  String _intro() => switch (_lv.kind) {
        MkKind.basket => mkT(context, 'listSay'),
        MkKind.scale => mkT(context, 'weighSay', {'item': mkItem(_weigh.item).label(context, 2), 'w': mkGrams(context, _weigh.target)}),
        MkKind.pay => mkT(context, 'paySay', {'n': _money.total}),
        MkKind.change => mkT(context, 'changeSay', {'n': _money.given}),
      };

  GlobalKey _key(String id) => _srcKeys.putIfAbsent(id, () => GlobalKey());

  // ── leaving ───────────────────────────────────────────────────────────────

  void _leave([int? result]) {
    if (_leaving) return;
    MkVoice.stop();
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  void _restart() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => MarketPlay(level: _lv),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
  }

  Future<void> _askQuit() async {
    mkSound(context, 'clickButton');
    final quit = await _dialog<bool>(_QuitDialog());
    if (quit == true && mounted) _leave();
  }

  Future<void> _pause() async {
    mkSound(context, 'clickButton');
    final r = await _dialog<String>(_PauseDialog());
    if (!mounted) return;
    if (r == 'restart') _restart();
    if (r == 'map') _leave();
  }

  Future<T?> _dialog<T>(Widget child) => showGeneralDialog<T>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'mk',
        barrierColor: const Color(0x99301A6B),
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, __, ___) => child,
        transitionBuilder: (_, a, __, c) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
      );

  // ── flying things ─────────────────────────────────────────────────────────

  Offset? _centerOf(GlobalKey k) {
    final box = k.currentContext?.findRenderObject() as RenderBox?;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || stack == null || !box.hasSize) return null;
    return stack.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  }

  void _fly(GlobalKey from, Widget child, double size, {VoidCallback? onLand}) {
    final a = _centerOf(from), b = _centerOf(_dropKey);
    if (a == null || b == null) {
      onLand?.call();
      return;
    }
    final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    final f = _Flight(child, a, b + Offset((_rng.nextDouble() - 0.5) * 40, -10), size, c);
    setState(() => _flights.add(f));
    c.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _flights.remove(f));
      c.dispose();
      onLand?.call();
      _bump.forward(from: 0);
    });
  }

  // ── checking ──────────────────────────────────────────────────────────────

  Future<void> _wrong(String msg) async {
    _mistakes++;
    HapticFeedback.mediumImpact();
    mkSfx(context, 'Invalid_SFX.mp3');
    _shake.forward(from: 0);
    setState(() => _say = msg);
    MkVoice.say(context, msg);
    final r = await _dialog<String>(_TryDialog(message: msg));
    if (r == 'hint' && mounted) _hint();
  }

  void _hint() {
    _hints++;
    mkSound(context, 'PopButton');
    final msg = _hintText();
    setState(() => _say = msg);
    MkVoice.say(context, msg);
    _dialog<void>(_HintDialog(message: msg));
  }

  String _hintText() {
    switch (_lv.kind) {
      case MkKind.basket:
        for (final e in _list.want.entries) {
          final have = _basket.where((b) => b == e.key).length;
          if (have < e.value) return mkT(context, 'hintBasket', {'n': e.value - have, 'item': mkItem(e.key).label(context, e.value - have)});
          if (have > e.value) return mkT(context, 'tooMany', {'item': mkItem(e.key).label(context, 2)});
        }
        for (final b in _basket) {
          if (!_list.want.containsKey(b)) return mkT(context, 'notList', {'item': mkItem(b).label(context, 2)});
        }
        return mkT(context, 'allGood');
      case MkKind.scale:
        final grams = _bowl.fold(0, (a, b) => a + b);
        if (grams < _weigh.target) return mkT(context, 'hintScale', {'w': mkGrams(context, _weigh.target - grams)});
        if (grams > _weigh.target) return mkT(context, 'hintScaleOver', {'w': mkGrams(context, grams - _weigh.target)});
        return mkT(context, 'allGood');
      case MkKind.pay:
      case MkKind.change:
        final goal = _lv.kind == MkKind.pay ? _money.total : _money.change;
        final cur = _tray.fold(0, (a, b) => a + b);
        if (cur > goal) return mkT(context, 'payMore', {'n': cur - goal});
        if (cur == goal) return mkT(context, 'allGood');
        final left = goal - cur;
        final coin = _money.coins.where((c) => c <= left).fold<int>(0, (a, b) => max(a, b));
        return mkT(context, 'hintPay', {'n': coin});
    }
  }

  void _verify() {
    if (_over) return;
    mkSound(context, 'clickButton');
    switch (_lv.kind) {
      case MkKind.basket:
        for (final b in _basket.toSet()) {
          if (!_list.want.containsKey(b)) {
            _wrong(mkT(context, 'notList', {'item': mkItem(b).label(context, 2)}));
            return;
          }
        }
        for (final e in _list.want.entries) {
          final have = _basket.where((b) => b == e.key).length;
          if (have < e.value) {
            {
            _wrong(mkT(context, 'missing', {'n': e.value - have, 'item': mkItem(e.key).label(context, e.value - have)}));
            return;
          }
          }
          if (have > e.value) {
            _wrong(mkT(context, 'tooMany', {'item': mkItem(e.key).label(context, 2)}));
            return;
          }
        }
      case MkKind.scale:
        final grams = _bowl.fold(0, (a, b) => a + b);
        if (grams > _weigh.target) {
            _wrong(mkT(context, 'tooHeavy'));
            return;
          }
        if (grams < _weigh.target) {
            _wrong(mkT(context, 'notEnough'));
            return;
          }
      case MkKind.pay:
      case MkKind.change:
        final goal = _lv.kind == MkKind.pay ? _money.total : _money.change;
        final cur = _tray.fold(0, (a, b) => a + b);
        if (cur < goal) {
            _wrong(mkT(context, 'payLess', {'n': goal - cur}));
            return;
          }
        if (cur > goal) {
            _wrong(mkT(context, 'payMore', {'n': cur - goal}));
            return;
          }
    }
    _win();
  }

  Future<void> _win() async {
    _over = true;
    final stars = (_mistakes == 0 && _hints == 0) ? 3 : (_mistakes + _hints <= 2 ? 2 : 1);
    final (fresh, first) = await MkStore.record(_lv.n, stars);
    if (!mounted) return;
    final gold = first ? 10 + _lv.n * 2 : 3 + fresh * 2;
    var gems = (stars == 3 && fresh > 0) ? 1 : 0;
    final badge = _lv.n == mkLevels.length && first;
    if (badge) gems += 3;
    mkSfx(context, 'MarimbaWin_SFX.mp3');
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    xp.addGold(context, gold);
    if (gems > 0) xp.addGems(context, gems);
    xp.addXP(4 + stars * 3, context: context);
    MkVoice.say(context, '${mkT(context, 'bravo1')} ${mkT(context, 'bravo2')}');
    final r = await Navigator.of(context).push<String>(PageRouteBuilder<String>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => _EndPage(level: _lv, stars: stars, gold: gold, gems: gems, badge: badge),
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
    ));
    if (!mounted) return;
    switch (r) {
      case 'next':
        _leave(_lv.n < mkLevels.length ? _lv.n + 1 : null);
      case 'again':
        _restart();
      default:
        _leave();
    }
  }

  // ═════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) => MkFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = mkScale(context);
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 520.0);
    final (t1, t2) = switch (_lv.kind) {
      MkKind.basket => _listPhase ? (mkT(context, 'listTitle1'), mkT(context, 'listTitle2')) : (mkT(context, 'fillTitle1'), mkT(context, 'fillTitle2')),
      MkKind.scale => (mkT(context, 'weighTitle1'), mkT(context, 'weighTitle2')),
      MkKind.pay => (mkT(context, 'payTitle1'), mkT(context, 'payTitle2')),
      MkKind.change => (mkT(context, 'changeTitle1'), mkT(context, 'changeTitle2')),
    };

    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askQuit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2D19A),
        body: Stack(key: _stackKey, children: [
          Positioned.fill(child: MkBg(alt: _lv.kind != MkKind.basket || !_listPhase)),
          SafeArea(
            child: Center(
              child: SizedBox(
                width: w,
                child: Column(children: [
                  // header
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8 * s),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      mkRound(context, 'mk_back', 44 * s, _askQuit, flipRtl: true),
                      Expanded(
                        child: Center(
                          child: MkTitle(top: t1, bottom: t2, pill: mkT(context, 'level', {'n': _lv.n}), width: min(w * 0.64, 270 * s)),
                        ),
                      ),
                      Column(children: [
                        mkRound(context, 'mk_pause', 44 * s, _pause),
                        if (!(_lv.kind == MkKind.basket && _listPhase)) ...[
                          SizedBox(height: 4 * s),
                          MkPress(
                            onTap: _hint,
                            label: mkT(context, 'hint'),
                            child: AnimatedBuilder(
                              animation: _idle,
                              builder: (_, c) => Transform.rotate(angle: sin(_idle.value * 2 * pi * 2) * 0.08, child: c),
                              child: Image.asset(mk('mk_bulb'), width: 44 * s),
                            ),
                          ),
                        ],
                      ]),
                    ]),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      transitionBuilder: (c, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(position: Tween(begin: const Offset(0.15, 0), end: Offset.zero).animate(a), child: c),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey('${_lv.kind}$_listPhase'),
                        child: switch (_lv.kind) {
                          MkKind.basket => _listPhase ? _listView(s, w) : _stallView(s, w),
                          MkKind.scale => _scaleView(s, w),
                          MkKind.pay => _moneyView(s, w, change: false),
                          MkKind.change => _moneyView(s, w, change: true),
                        },
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
          // flying items
          for (final f in _flights)
            AnimatedBuilder(
              animation: f.c,
              builder: (_, __) {
                final t = Curves.easeInOut.transform(f.c.value);
                final p = Offset.lerp(f.from, f.to, t)! + Offset(0, -sin(t * pi) * 120);
                final sc = 1 + sin(t * pi) * 0.3 - t * 0.25;
                return Positioned(
                  left: p.dx - f.size / 2,
                  top: p.dy - f.size / 2,
                  width: f.size,
                  height: f.size,
                  child: IgnorePointer(child: Transform.rotate(angle: t * pi * 0.6, child: Transform.scale(scale: sc, child: f.child))),
                );
              },
            ),
        ]),
      ),
    );
  }

  Widget _robotSay(double s, {double width = 200, String robot = 'mk_robot_point', double h = 90}) => IgnorePointer(
        child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
          AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi * 2) * 3 * s), child: c),
            child: Transform.flip(flipX: mkRtl(context), child: Image.asset(mk(robot), height: h * s)),
          ),
          if (_say.isNotEmpty) Padding(padding: EdgeInsets.only(bottom: h * 0.45 * s), child: MkBubble(text: _say, width: width * s)),
        ]),
      );

  Widget _shaking(Widget child) => AnimatedBuilder(
        animation: _shake,
        builder: (_, c) => Transform.translate(offset: Offset(sin(_shake.value * pi * 6) * 8 * (1 - _shake.value), 0), child: c),
        child: child,
      );

  Widget _bumping(Widget child) => AnimatedBuilder(
        animation: _bump,
        builder: (_, c) => Transform.scale(scale: 1 + sin(_bump.value * pi) * 0.06, child: c),
        child: child,
      );

  // ═════════════════════════════════════════════════════════════════════════
  // 1. Shopping list
  // ═════════════════════════════════════════════════════════════════════════

  Widget _listView(double s, double w) {
    final entries = _list.want.entries.toList();
    return LayoutBuilder(builder: (_, c) {
      final boardW = min(w * 0.7, c.maxHeight * 0.55 / 1.186);
      return Column(children: [
        Expanded(
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
            PositionedDirectional(
              start: -6,
              top: c.maxHeight * 0.1,
              child: AnimatedBuilder(
                animation: _idle,
                builder: (_, ch) => Transform.translate(offset: Offset(0, sin(_idle.value * 2 * pi * 2) * 4 * s), child: ch),
                child: Transform.flip(flipX: mkRtl(context), child: Image.asset(mk('mk_robot_point'), height: boardW * 0.5)),
              ),
            ),
            Positioned(
              left: (c.maxWidth - boardW) / 2 + boardW * 0.1,
              top: 0,
              width: boardW,
              height: boardW * 1.186,
              child: Stack(children: [
                Positioned.fill(child: Image.asset(mk('mk_clipboard'), fit: BoxFit.fill)),
                Positioned(
                  left: boardW * 0.08,
                  right: boardW * 0.06,
                  top: boardW * 0.2,
                  bottom: boardW * 0.08,
                  child: Column(children: [
                    for (var i = 0; i < entries.length; i++) ...[
                      if (i > 0) Image.asset(mk('mk_divider'), width: boardW * 0.8),
                      Expanded(child: _listRow(s, boardW, entries[i].key, entries[i].value, i)),
                    ],
                  ]),
                ),
              ]),
            ),
          ]),
        ),
        MkBubble(text: _say.isEmpty ? mkT(context, 'listSay') : _say, width: min(w * 0.7, 280 * s)),
        AnimatedBuilder(
          animation: _idle,
          builder: (_, ch) => Transform.scale(scale: 1 + 0.03 * sin(_idle.value * 2 * pi * 3), child: ch),
          child: Image.asset(mk('mk_basket'), height: 76 * s),
        ),
        SizedBox(height: 6 * s),
        MkPlayButton(
          label: mkT(context, 'goMarket'),
          onTap: () {
            mkSound(context, 'PopButton');
            setState(() {
              _listPhase = false;
              _say = mkT(context, 'tapFruit');
            });
            MkVoice.say(context, _say);
          },
          width: min(w * 0.72, 300 * s),
          s: s,
          pulse: _idle,
        ),
        SizedBox(height: 4 * s),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 4 * s),
          decoration: BoxDecoration(color: mkCream, borderRadius: BorderRadius.circular(20 * s)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.hourglass_bottom_rounded, size: 15 * s, color: mkInk),
            SizedBox(width: 4 * s),
            Text(mkT(context, 'noTimer'), style: mkText(12 * s, weight: FontWeight.w600)),
          ]),
        ),
        SizedBox(height: 8 * s),
      ]);
    });
  }

  Widget _listRow(double s, double bw, String id, int n, int i) {
    final it = mkItem(id);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + i * 180),
      curve: Curves.easeOutBack,
      builder: (_, v, c) => Opacity(opacity: v.clamp(0.0, 1.0), child: Transform.translate(offset: Offset((1 - v) * 40, 0), child: c)),
      child: Row(children: [
        SizedBox(
          width: bw * 0.3,
          child: Stack(alignment: Alignment.center, children: [
            for (var k = 0; k < min(n, 3); k++)
              Transform.translate(
                offset: Offset((k - (min(n, 3) - 1) / 2) * bw * 0.06, -k * bw * 0.01),
                child: Image.asset(it.asset, height: bw * 0.15),
              ),
          ]),
        ),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$n', style: mkText(bw * 0.12, weight: FontWeight.w800, height: 1)),
            FittedBox(fit: BoxFit.scaleDown, child: Text(it.label(context, n), style: mkText(bw * 0.055, weight: FontWeight.w600))),
          ]),
        ),
        Image.asset(mk('mk_box'), width: bw * 0.1),
        SizedBox(width: bw * 0.03),
        MkPress(
          onTap: () => MkVoice.say(context, '$n ${it.label(context, n)}'),
          label: it.label(context, n),
          child: Image.asset(mk('mk_speaker'), width: bw * 0.13),
        ),
      ]),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 2. Fill the basket
  // ═════════════════════════════════════════════════════════════════════════

  void _addToBasket(String id) {
    if (_over) return;
    mkSound(context, 'PopButton');
    _fly(_key('stall_$id'), Image.asset(mkItem(id).asset), 72, onLand: () {
      setState(() => _basket.add(id));
      final want = _list.want[id];
      final have = _basket.where((b) => b == id).length;
      if (want != null && have == want) {
        mkSfx(context, 'CorrectAnwser_SFX.mp3');
        setState(() => _say = '${mkT(context, 'good')} ✔');
      }
    });
  }

  void _removeLast() {
    if (_basket.isEmpty) return;
    mkSound(context, 'cancelButton');
    setState(() => _basket.removeLast());
  }

  Widget _stallView(double s, double w) {
    return LayoutBuilder(builder: (_, c) {
      final cols = 3;
      final rows = (_list.stalls.length / cols).ceil();
      final cellW = (w - 24 * s) / cols;
      final cellH = min(cellW * 0.95, (c.maxHeight * 0.42) / rows);
      return Column(children: [
        _tracker(s, w),
        SizedBox(height: 6 * s),
        // stalls
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12 * s),
          child: Wrap(alignment: WrapAlignment.center, children: [
            for (final id in _list.stalls) SizedBox(width: cellW, height: cellH, child: _stall(s, id, cellW, cellH)),
          ]),
        ),
        // basket area
        Expanded(
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
            Positioned(
              bottom: 0,
              child: _shaking(_bumping(SizedBox(
                key: _dropKey,
                width: min(w * 0.62, 250 * s),
                height: min(w * 0.62, 250 * s) * 0.6529,
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned.fill(child: Image.asset(mk('mk_basket'), fit: BoxFit.fill)),
                  // contents peeking out of the basket
                  Positioned(
                    left: 0,
                    right: 0,
                    top: -30 * s,
                    height: 70 * s,
                    child: _basketPile(s, min(w * 0.62, 250 * s)),
                  ),
                ]),
              ))),
            ),
            PositionedDirectional(
              start: 0,
              bottom: 0,
              child: _robotSay(s, width: 150, robot: 'mk_robot_think', h: 74),
            ),
            if (_basket.isNotEmpty)
              PositionedDirectional(
                end: w * 0.06,
                bottom: 30 * s,
                child: mkRound(context, 'mk_minus', 46 * s, _removeLast, label: mkT(context, 'remove')),
              ),
          ]),
        ),
        SizedBox(height: 6 * s),
        MkPlayButton(label: mkT(context, 'check'), onTap: _basket.isEmpty ? null : _verify, width: min(w * 0.8, 320 * s), s: s, pulse: _idle),
        SizedBox(height: 8 * s),
      ]);
    });
  }

  Widget _basketPile(double s, double bw) {
    final n = _basket.length;
    // big fruits: up to 4 per row, rows stack upwards out of the basket
    const perRow = 4;
    final item = min(66 * s, bw * 0.3);
    final rowW = bw * 0.8;
    return Stack(clipBehavior: Clip.none, children: [
      for (var i = 0; i < n; i++)
        () {
          final row = i ~/ perRow, col = i % perRow;
          final inRow = min(perRow, n - row * perRow);
          final step = inRow > 1 ? (rowW - item) / (perRow - 1) : 0.0;
          final startX = (bw - (step * (inRow - 1) + item)) / 2 + (row.isOdd ? step * 0.5 : 0);
          return Positioned(
            left: startX + col * step,
            top: 34 * s - row * item * 0.55 + ((i * 13) % 3) * 3 * s,
            child: TweenAnimationBuilder<double>(
              key: ValueKey('b$i${_basket[i]}'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.elasticOut,
              builder: (_, v, c) => Transform.scale(scale: v, child: c),
              child: Transform.rotate(angle: ((i * 7) % 5 - 2) * 0.1, child: Image.asset(mkItem(_basket[i]).asset, width: item, height: item, fit: BoxFit.contain)),
            ),
          );
        }(),
    ]);
  }

  Widget _tracker(double s, double w) {
    final entries = _list.want.entries.toList();
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12 * s),
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
      decoration: BoxDecoration(
        color: mkCream,
        borderRadius: BorderRadius.circular(26 * s),
        border: Border.all(color: const Color(0xFFF2B33D), width: 2.5 * s),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8 * s, offset: Offset(0, 3 * s))],
      ),
      child: Row(children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) Container(width: 1.5 * s, height: 40 * s, color: const Color(0xFFF2B33D)),
          Expanded(child: _trackCell(s, entries[i].key, entries[i].value)),
        ],
      ]),
    );
  }

  Widget _trackCell(double s, String id, int want) {
    final have = _basket.where((b) => b == id).length;
    final done = have == want;
    final over = have > want;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Image.asset(mkItem(id).asset, height: 32 * s),
      SizedBox(width: 4 * s),
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text('$have/$want', style: mkText(15 * s, color: over ? mkRed : (done ? mkGreen : mkInk))),
        if (done)
          Image.asset(mk('mk_check'), height: 15 * s)
        else
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (var k = 0; k < min(want, 5); k++)
              Container(
                width: 7 * s,
                height: 7 * s,
                margin: EdgeInsets.symmetric(horizontal: 1 * s),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: k < have ? (over ? mkRed : const Color(0xFFE53935)) : Colors.white,
                  border: Border.all(color: const Color(0xFFB9B2C9), width: 1),
                ),
              ),
          ]),
      ]),
    ]);
  }

  Widget _stall(double s, String id, double cw, double ch) {
    final it = mkItem(id);
    return MkPress(
      onTap: () => _addToBasket(id),
      label: it.label(context, 1),
      child: Padding(
        padding: EdgeInsets.all(3 * s),
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
          // crate
          Positioned(bottom: 0, left: 0, right: 0, child: Image.asset(mk('mk_crate'), width: cw * 0.95)),
          // pile of fruits in the crate
          Positioned(
            key: _key('stall_$id'),
            bottom: cw * 0.95 * 0.32,
            left: cw * 0.08,
            right: cw * 0.08,
            height: ch * 0.4,
            child: Stack(clipBehavior: Clip.none, children: [
              for (var k = 0; k < 5; k++)
                Positioned(
                  left: (k % 3) * cw * 0.22 + (k ~/ 3) * cw * 0.1,
                  bottom: (k ~/ 3) * ch * 0.1,
                  child: Image.asset(it.asset, width: cw * 0.32),
                ),
            ]),
          ),
          // chalk sign
          Positioned(top: 0, child: Image.asset(it.sign, height: ch * 0.36)),
        ]),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 3. Scale
  // ═════════════════════════════════════════════════════════════════════════

  int get _weight => _bowl.fold(0, (a, b) => a + b);
  double _bowlBase = 70; // fruit size of a 750 g piece, updated on layout

  /// Fruit size grows clearly with its weight: 250 g small, 500 g medium, 750 g big.
  static double _fruitSize(int g, double base) => base * (0.5 + 0.5 * g.clamp(100, 1000) / 750);

  /// Little gram sticker shown on every fruit (tray and bowl).
  Widget _gramTag(int g, double s, {double size = 11}) => Container(
        padding: EdgeInsets.symmetric(horizontal: 5 * s, vertical: 1 * s),
        decoration: BoxDecoration(
          color: g >= 750 ? mkRed : (g >= 500 ? mkOrange : mkGreen),
          borderRadius: BorderRadius.circular(9 * s),
          border: Border.all(color: Colors.white, width: 1.5 * s),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3 * s, offset: Offset(0, 1 * s))],
        ),
        child: Text('$g g', style: mkText(size * s, color: Colors.white, weight: FontWeight.w800, height: 1.1)),
      );

  /// Fruits piled in the bowl: each one sized by its weight, rows centred, never spilling out.
  List<Widget> _bowlPile(double s, double bw, double bowlH, MkItem it) {
    final out = <Widget>[];
    final maxRow = bw * 0.82;
    var row = <int>[];
    final rows = <List<int>>[];
    var rowW = 0.0;
    for (var i = 0; i < _bowl.length; i++) {
      final sz = _fruitSize(_bowl[i], _bowlBase) * 0.78; // overlap a bit
      if (row.isNotEmpty && rowW + sz > maxRow) {
        rows.add(row);
        row = [];
        rowW = 0;
      }
      row.add(i);
      rowW += sz;
    }
    if (row.isNotEmpty) rows.add(row);
    for (var r = 0; r < rows.length; r++) {
      final ids = rows[r];
      final total = ids.fold<double>(0, (a, i) => a + _fruitSize(_bowl[i], _bowlBase) * 0.78);
      var x = (bw - total) / 2 + (r.isOdd ? _bowlBase * 0.15 : 0);
      for (final i in ids) {
        final sz = _fruitSize(_bowl[i], _bowlBase);
        out.add(Positioned(
          left: x - sz * 0.11,
          bottom: bowlH * 0.42 + r * _bowlBase * 0.5,
          child: TweenAnimationBuilder<double>(
            key: ValueKey('bowl$i'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.elasticOut,
            builder: (_, v, ch) => Transform.scale(scale: v, child: ch),
            child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
              Transform.rotate(
                angle: ((i * 7) % 5 - 2) * 0.08,
                child: Image.asset(it.asset, width: sz, height: sz, fit: BoxFit.contain),
              ),
              Positioned(bottom: -4 * s, child: _gramTag(_bowl[i], s, size: 9.5)),
            ]),
          ),
        ));
        x += sz * 0.78;
      }
    }
    return out;
  }

  void _addToBowl(int i) {
    if (_over) return;
    mkSound(context, 'PopButton');
    final g = _weigh.slots[i];
    _fly(_key('slot_$i'), Image.asset(mkItem(_weigh.item).asset), _fruitSize(g, _bowlBase), onLand: () {
      setState(() => _bowl.add(g));
      if (_weight == _weigh.target) {
        mkSfx(context, 'CorrectAnwser_SFX.mp3');
        setState(() => _say = mkT(context, 'allGood'));
      }
    });
  }

  Widget _scaleView(double s, double w) {
    final it = mkItem(_weigh.item);
    final cur = _weight;
    final ratio = (cur / _weigh.target).clamp(0.0, 1.5);
    final over = cur > _weigh.target;
    final ok = cur == _weigh.target;
    final instruction = mkT(context, 'prepare', {'w': mkGrams(context, _weigh.target), 'item': it.label(context, 2)});
    return LayoutBuilder(builder: (_, c) {
      final scaleW = min(w * 0.62, c.maxHeight * 0.42);
      _bowlBase = scaleW * 0.9 * 0.36;
      return Column(children: [
        // instruction
        Container(
          margin: EdgeInsets.symmetric(horizontal: 12 * s),
          padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 6 * s),
          decoration: BoxDecoration(
            color: mkCream,
            borderRadius: BorderRadius.circular(26 * s),
            border: Border.all(color: const Color(0xFFF2B33D), width: 2.5 * s),
          ),
          child: Row(children: [
            mkRound(context, 'mk_sound_or', 36 * s, () => MkVoice.say(context, instruction)),
            SizedBox(width: 8 * s),
            Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(instruction, style: mkText(18 * s)))),
            Image.asset(it.asset, height: 34 * s),
          ]),
        ),
        // scale scene
        Expanded(
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
            PositionedDirectional(end: -8 * s, top: 0, child: Image.asset(mk('mk_seller'), height: c.maxHeight * 0.5)),
            PositionedDirectional(start: 0, top: 0, child: _robotSay(s, width: 150, robot: 'mk_robot_think', h: 70)),
            Positioned(
              bottom: 0,
              child: _shaking(_bumping(SizedBox(
                width: scaleW,
                height: scaleW * (0.4722 + 0.36),
                child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
                  Positioned(bottom: 0, child: Image.asset(mk('mk_scale'), width: scaleW)),
                  // digital display
                  Positioned(
                    bottom: scaleW * 0.4722 * 0.24,
                    width: scaleW * 0.45,
                    height: scaleW * 0.4722 * 0.32,
                    child: Center(
                      child: FittedBox(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: cur.toDouble()),
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOut,
                          builder: (_, v, __) => Text('${v.round()} g', style: mkText(30 * s, color: over ? mkRed : (ok ? mkGreen : mkInk), weight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ),
                  // bowl + fruits
                  Positioned(
                    key: _dropKey,
                    bottom: scaleW * 0.4722 * 0.72,
                    child: SizedBox(
                      width: scaleW * 0.9,
                      height: scaleW * 0.9 * 0.4375 + _bowlBase * 1.6,
                      child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
                        ..._bowlPile(s, scaleW * 0.9, scaleW * 0.9 * 0.4375, it),
                        Positioned(bottom: 0, child: Image.asset(mk('mk_bowl'), width: scaleW * 0.9)),
                      ]),
                    ),
                  ),
                ]),
              ))),
            ),
          ]),
        ),
        // goal + progress
        mkLabel(mkT(context, 'goal', {'w': '${_weigh.target} g'}), s, width: 190),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 4 * s),
          padding: EdgeInsets.fromLTRB(14 * s, 8 * s, 14 * s, 6 * s),
          decoration: BoxDecoration(color: mkCream, borderRadius: BorderRadius.circular(22 * s), border: Border.all(color: const Color(0xFFF2B33D), width: 2 * s)),
          child: Column(children: [
            Container(
              height: 14 * s,
              decoration: BoxDecoration(color: const Color(0xFFD8D2C6), borderRadius: BorderRadius.circular(8 * s)),
              alignment: AlignmentDirectional.centerStart,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                widthFactor: max(0.02, min(1.0, ratio.toDouble())),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: over ? [const Color(0xFFFF8A8A), mkRed] : (ok ? [const Color(0xFF6EE7A0), mkGreen] : [const Color(0xFFFFB25B), mkOrange])),
                    borderRadius: BorderRadius.circular(8 * s),
                  ),
                ),
              ),
            ),
            SizedBox(height: 2 * s),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('0 g', style: mkText(11 * s, weight: FontWeight.w600)),
              Text('${_weigh.target ~/ 2} g', style: mkText(11 * s, weight: FontWeight.w600)),
              Text('${_weigh.target} g', style: mkText(11 * s, weight: FontWeight.w600)),
            ]),
          ]),
        ),
        // tray of fruits + buttons
        Row(children: [
          SizedBox(width: 8 * s),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1 / 0.437,
              child: LayoutBuilder(builder: (_, tc) {
                final tw = tc.maxWidth;
                return Stack(children: [
                  Positioned.fill(child: Image.asset(mk('mk_tray4'), fit: BoxFit.fill)),
                  for (var i = 0; i < 4; i++)
                    Positioned(
                      left: tw * (0.06 + i * 0.225),
                      width: tw * 0.2,
                      top: tw * 0.437 * 0.1,
                      bottom: tw * 0.437 * 0.12,
                      child: MkPress(
                        onTap: () => _addToBowl(i),
                        label: '${_weigh.slots[i]} g',
                        child: Column(children: [
                          Expanded(
                            child: Center(
                              key: _key('slot_$i'),
                              child: Image.asset(it.asset, width: _fruitSize(_weigh.slots[i], tw * 0.19), height: _fruitSize(_weigh.slots[i], tw * 0.19), fit: BoxFit.contain),
                            ),
                          ),
                          FittedBox(child: _gramTag(_weigh.slots[i], s, size: 12)),
                        ]),
                      ),
                    ),
                ]);
              }),
            ),
          ),
          SizedBox(width: 6 * s),
          Column(mainAxisSize: MainAxisSize.min, children: [
            mkRound(context, 'mk_minus', 44 * s, () {
              if (_bowl.isEmpty) return;
              mkSound(context, 'cancelButton');
              setState(() => _bowl.removeLast());
            }, label: mkT(context, 'remove')),
            Text(mkT(context, 'remove'), style: mkText(10.5 * s)),
            SizedBox(height: 4 * s),
            mkRound(context, 'mk_restart', 44 * s, () {
              mkSound(context, 'cancelButton');
              setState(() => _bowl.clear());
            }, label: mkT(context, 'restart')),
            Text(mkT(context, 'restart'), style: mkText(10.5 * s)),
          ]),
          SizedBox(width: 8 * s),
        ]),
        Container(
          margin: EdgeInsets.only(top: 4 * s),
          padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 3 * s),
          decoration: BoxDecoration(color: mkCream, borderRadius: BorderRadius.circular(16 * s)),
          child: Text('1 kg = 1000 g', style: mkText(14 * s)),
        ),
        SizedBox(height: 4 * s),
        MkPlayButton(label: mkT(context, 'verify'), onTap: _bowl.isEmpty ? null : _verify, width: min(w * 0.72, 290 * s), s: s, pulse: _idle),
        SizedBox(height: 6 * s),
      ]);
    });
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 4. Pay / give change
  // ═════════════════════════════════════════════════════════════════════════

  int get _trayTotal => _tray.fold(0, (a, b) => a + b);

  void _addCoin(int v) {
    if (_over) return;
    mkSound(context, 'clickButton');
    _fly(_key('coin_$v'), MkCoin(value: v, size: 52), 52, onLand: () {
      setState(() => _tray.add(v));
      final goal = _lv.kind == MkKind.pay ? _money.total : _money.change;
      if (_trayTotal == goal) mkSfx(context, 'CorrectAnwser_SFX.mp3');
    });
  }

  Widget _moneyView(double s, double w, {required bool change}) {
    final goal = change ? _money.change : _money.total;
    final cur = _trayTotal;
    final ok = cur == goal;
    return LayoutBuilder(builder: (_, c) {
      final topH = c.maxHeight * 0.36;
      return Column(children: [
        // characters + receipt
        SizedBox(
          height: topH,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              flex: 9,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned(left: 0, right: 0, top: 0, bottom: topH * 0.25, child: Image.asset(mk('mk_seller'), fit: BoxFit.contain, alignment: Alignment.topCenter)),
                Positioned(left: 0, bottom: 0, child: _robotSay(s, width: 140, robot: 'mk_robot_think', h: 66)),
              ]),
            ),
            Expanded(flex: 11, child: change ? _changeTicket(s, topH) : _receipt(s, topH)),
          ]),
        ),
        if (change)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4 * s),
            child: _equation(s, w, cur),
          ),
        // tray with placed coins
        _labelTeal(s, change ? mkT(context, 'myChange', {'n': cur}) : mkT(context, 'putCoins')),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10 * s),
            child: _shaking(_bumping(Container(
              key: _dropKey,
              decoration: BoxDecoration(
                image: DecorationImage(image: AssetImage(mk('mk_tray_wide')), fit: BoxFit.fill),
              ),
              padding: EdgeInsets.fromLTRB(20 * s, 12 * s, 14 * s, 14 * s),
              child: Row(children: [
                Expanded(
                  child: Center(
                    child: Wrap(alignment: WrapAlignment.center, spacing: 4 * s, runSpacing: 2 * s, children: [
                      for (var i = 0; i < _tray.length; i++)
                        MkPress(
                          onTap: () {
                            mkSound(context, 'cancelButton');
                            setState(() => _tray.removeAt(i));
                          },
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey('t$i${_tray[i]}${_tray.length}'),
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.elasticOut,
                            builder: (_, v, ch) => Transform.scale(scale: v, child: ch),
                            child: MkCoin(value: _tray[i], size: (_tray[i] == 10 ? 50 : 42) * s),
                          ),
                        ),
                    ]),
                  ),
                ),
                if (!change)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 78 * s,
                    padding: EdgeInsets.symmetric(vertical: 6 * s),
                    decoration: BoxDecoration(
                      color: ok ? const Color(0xFFE9FBE5) : mkCream,
                      borderRadius: BorderRadius.circular(14 * s),
                      border: Border.all(color: ok ? mkGreen : const Color(0xFFF2B33D), width: 2 * s),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      FittedBox(child: Text('$cur / $goal DH', style: mkText(14 * s, color: ok ? mkGreen : (cur > goal ? mkRed : mkInk)))),
                      if (ok) Image.asset(mk('mk_check'), height: 30 * s),
                    ]),
                  ),
              ]),
            ))),
          ),
        ),
        // purse
        _labelTeal(s, change ? mkT(context, 'pick') : mkT(context, 'purse')),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10 * s),
          child: AspectRatio(
            aspectRatio: 1 / 0.24,
            child: LayoutBuilder(builder: (_, pc) {
              final pw = pc.maxWidth;
              final coins = _money.coins;
              return Stack(children: [
                Positioned.fill(child: Image.asset(mk('mk_tray4b'), fit: BoxFit.fill)),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: pw * 0.04, vertical: 4 * s),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      for (final v in coins)
                        MkPress(
                          onTap: () => _addCoin(v),
                          label: '$v DH',
                          child: AnimatedBuilder(
                            animation: _idle,
                            builder: (_, ch) => Transform.translate(offset: Offset(0, sin((_idle.value * 2 + v * 0.13) * 2 * pi) * 2 * s), child: ch),
                            child: SizedBox(key: _key('coin_$v'), child: MkCoin(value: v, size: min(pw * 0.19, 66 * s))),
                          ),
                        ),
                    ]),
                  ),
                ),
              ]);
            }),
          ),
        ),
        SizedBox(height: 6 * s),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          MkPlayButton(
            label: change ? mkT(context, 'giveBtn') : mkT(context, 'payBtn', {'n': goal}),
            onTap: _tray.isEmpty ? null : _verify,
            width: min(w * 0.62, 250 * s),
            s: s,
            pulse: _idle,
          ),
          SizedBox(width: 6 * s),
          MkPress(
            onTap: () {
              mkSound(context, 'cancelButton');
              setState(() => _tray.clear());
            },
            label: mkT(context, 'clear'),
            child: SizedBox(
              width: 86 * s,
              child: Column(children: [
                Image.asset(mk('mk_btn_reset'), width: 70 * s),
                FittedBox(fit: BoxFit.scaleDown, child: Text(mkT(context, 'clear'), style: mkText(11.5 * s))),
              ]),
            ),
          ),
        ]),
        Text('· ${mkT(context, 'fake')} ·', style: mkText(10.5 * s, color: mkInkSoft, weight: FontWeight.w600)),
        SizedBox(height: 4 * s),
      ]);
    });
  }

  Widget _labelTeal(double s, String text) => Padding(
        padding: EdgeInsets.symmetric(vertical: 3 * s),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 4 * s),
          decoration: BoxDecoration(
            color: mkCream,
            borderRadius: BorderRadius.circular(20 * s),
            border: Border.all(color: mkTeal, width: 2.5 * s),
          ),
          child: Text('✦ $text ✦', style: mkText(15 * s)),
        ),
      );

  Widget _receipt(double s, double h) => Container(
        decoration: BoxDecoration(image: DecorationImage(image: AssetImage(mk('mk_receipt')), fit: BoxFit.fill)),
        padding: EdgeInsets.fromLTRB(14 * s, h * 0.08, 14 * s, h * 0.06),
        child: Column(children: [
          for (final (id, price) in _money.lines)
            Expanded(
              child: Row(children: [
                Image.asset(mkItem(id).asset, height: h * 0.13),
                SizedBox(width: 6 * s),
                Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(_cap(mkItem(id).label(context, 2)), style: mkText(15 * s)))),
                Text('$price DH', style: mkText(16 * s, color: mkRed)),
              ]),
            ),
          Container(
            margin: EdgeInsets.only(top: 2 * s),
            padding: EdgeInsets.symmetric(vertical: 4 * s),
            decoration: BoxDecoration(color: mkCream, borderRadius: BorderRadius.circular(16 * s), border: Border.all(color: const Color(0xFFF2B33D), width: 2 * s)),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: 'Total : ', style: mkText(16 * s)),
                  TextSpan(text: '${_money.total} DH', style: mkText(20 * s, color: mkRed)),
                ])),
              ),
            ),
          ),
        ]),
      );

  Widget _changeTicket(double s, double h) => Container(
        decoration: BoxDecoration(image: DecorationImage(image: AssetImage(mk('mk_receipt')), fit: BoxFit.fill)),
        padding: EdgeInsets.fromLTRB(12 * s, h * 0.07, 10 * s, h * 0.05),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(mkT(context, 'price'), style: mkText(13 * s)))),
            _box(s, '${_money.total} DH', mkInk),
          ]),
          SizedBox(height: 4 * s),
          Text(mkT(context, 'gives'), style: mkText(13 * s)),
          Expanded(
            child: Row(children: [
              Expanded(child: Image.asset(mk('mk_kid_note'), fit: BoxFit.contain)),
              _box(s, '${_money.given} DH', mkRed),
            ]),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 3 * s),
            decoration: BoxDecoration(color: mkCream, borderRadius: BorderRadius.circular(14 * s), border: Border.all(color: const Color(0xFFF2B33D), width: 1.5 * s)),
            child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(mkT(context, 'howMuch'), style: mkText(13 * s)))),
          ),
        ]),
      );

  Widget _box(double s, String t, Color c) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 2 * s),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10 * s), border: Border.all(color: const Color(0xFFF2B33D), width: 2 * s)),
        child: Text(t, style: mkText(17 * s, color: c)),
      );

  Widget _equation(double s, double w, int cur) {
    final ew = min(w * 0.9, 380 * s);
    Widget cell(String t, Color c) => Expanded(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(t, style: mkText(20 * s, color: c)))));
    final full = _money.total + cur;
    return SizedBox(
      width: ew,
      height: ew * 0.1558,
      child: Stack(children: [
        Positioned.fill(child: Image.asset(mk('mk_equation'), fit: BoxFit.fill)),
        Positioned.fill(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: ew * 0.07),
              child: Row(children: [
                cell('${_money.total} DH', mkInk),
                SizedBox(width: ew * 0.1),
                cell('$cur DH', mkTeal),
                SizedBox(width: ew * 0.1),
                cell('$full DH', full == _money.given ? mkGreen : (full > _money.given ? mkRed : mkOrange)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  String _cap(String t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
}

// ═════════════════════════════════════════════════════════════════════════════
// Dialogs
// ═════════════════════════════════════════════════════════════════════════════

class _DialogFrame extends StatelessWidget {
  final Widget child;
  const _DialogFrame({required this.child});
  @override
  Widget build(BuildContext context) => MkFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final w = min(MediaQuery.sizeOf(context).width - 28, 420.0);
    final s = mkScale(context);
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: w,
          child: Stack(children: [
            Positioned.fill(child: Image.asset(mk('mk_dialog'), fit: BoxFit.fill)),
            Padding(padding: EdgeInsets.fromLTRB(24 * s, 22 * s, 24 * s, 22 * s), child: child),
          ]),
        ),
      ),
    );
  }
}

class _TryDialog extends StatelessWidget {
  final String message;
  const _TryDialog({required this.message});
  @override
  Widget build(BuildContext context) => MkFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = mkScale(context);
    return _DialogFrame(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(mkT(context, 'effort'), textAlign: TextAlign.center, style: mkText(23 * s)),
        SizedBox(height: 8 * s),
        Row(children: [
          Image.asset(mk('mk_robot_apple'), height: 90 * s),
          SizedBox(width: 10 * s),
          Expanded(child: Text(message, style: mkText(16 * s, color: mkInkSoft, weight: FontWeight.w600))),
        ]),
        SizedBox(height: 12 * s),
        Row(children: [
          Expanded(child: MkFlatButton(label: mkT(context, 'retry'), onTap: () => Navigator.pop(context, 'retry'), width: 160 * s, s: s)),
          SizedBox(width: 8 * s),
          Expanded(child: MkFlatButton(label: mkT(context, 'hint'), teal: true, onTap: () => Navigator.pop(context, 'hint'), width: 160 * s, s: s)),
        ]),
      ]),
    );
  }
}

class _HintDialog extends StatelessWidget {
  final String message;
  const _HintDialog({required this.message});
  @override
  Widget build(BuildContext context) => MkFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = mkScale(context);
    return _DialogFrame(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(mkT(context, 'hintTitle'), style: mkText(23 * s)),
        SizedBox(height: 8 * s),
        Row(children: [
          Image.asset(mk('mk_robot_happy'), height: 90 * s),
          SizedBox(width: 6 * s),
          Image.asset(mk('mk_bulb'), height: 50 * s),
          SizedBox(width: 6 * s),
          Expanded(child: Text(message, style: mkText(16 * s, color: mkInkSoft, weight: FontWeight.w600))),
        ]),
        SizedBox(height: 12 * s),
        MkFlatButton(label: mkT(context, 'understood'), onTap: () => Navigator.pop(context), width: 230 * s, s: s),
      ]),
    );
  }
}

class _PauseDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MkFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = mkScale(context);
    return _DialogFrame(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(mkT(context, 'pause'), style: mkText(25 * s)),
        SizedBox(height: 6 * s),
        Row(children: [
          Image.asset(mk('mk_robot_sleep'), height: 110 * s),
          SizedBox(width: 8 * s),
          Expanded(
            child: Column(children: [
              MkFlatButton(label: mkT(context, 'resume'), onTap: () => Navigator.pop(context, 'resume'), width: 190 * s, s: s),
              SizedBox(height: 6 * s),
              MkFlatButton(label: mkT(context, 'restart'), teal: true, onTap: () => Navigator.pop(context, 'restart'), width: 190 * s, s: s),
              SizedBox(height: 4 * s),
              TextButton.icon(
                onPressed: () => Navigator.pop(context, 'map'),
                icon: Icon(Icons.map_rounded, color: mkTeal, size: 20 * s),
                label: Text(mkT(context, 'map'), style: mkText(14 * s).copyWith(decoration: TextDecoration.underline)),
              ),
            ]),
          ),
        ]),
      ]),
    );
  }
}

class _QuitDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MkFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = mkScale(context);
    return _DialogFrame(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(mkT(context, 'quitQ'), textAlign: TextAlign.center, style: mkText(23 * s)),
        SizedBox(height: 6 * s),
        Image.asset(mk('mk_map_scroll'), height: 90 * s),
        SizedBox(height: 4 * s),
        Text(mkT(context, 'quitSub'), textAlign: TextAlign.center, style: mkText(14 * s, color: mkInkSoft, weight: FontWeight.w600)),
        SizedBox(height: 10 * s),
        MkFlatButton(label: mkT(context, 'keep'), onTap: () => Navigator.pop(context, false), width: 250 * s, s: s),
        SizedBox(height: 6 * s),
        MkFlatButton(label: mkT(context, 'quit'), teal: true, onTap: () => Navigator.pop(context, true), width: 250 * s, s: s),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// End screen — "Bravo, petit marchand !"
// ═════════════════════════════════════════════════════════════════════════════

class _EndPage extends StatefulWidget {
  final MkLevel level;
  final int stars, gold, gems;
  final bool badge;
  const _EndPage({required this.level, required this.stars, required this.gold, required this.gems, required this.badge});
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

  Animation<double> _seg(double a, double b, [Curve c = Curves.easeOutBack]) => CurvedAnimation(parent: _a, curve: Interval(a, b, curve: c));

  @override
  Widget build(BuildContext context) => MkFrame(child: Builder(builder: _page));

  Widget _page(BuildContext context) {
    final s = mkScale(context);
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 520.0);
    final world = widget.level.world;
    final last = widget.level.n == mkLevels.length;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(children: [
          Positioned.fill(child: ColoredBox(color: const Color(0xFF2A145C).withOpacity(0.55))),
          // confetti
          Positioned.fill(
            child: IgnorePointer(child: AnimatedBuilder(animation: _idle, builder: (_, __) => CustomPaint(painter: _Confetti(_idle.value)))),
          ),
          SafeArea(
            child: Center(
              child: SizedBox(
                width: w,
                child: Column(children: [
                  SizedBox(height: 4 * s),
                  ScaleTransition(
                    scale: _seg(0.0, 0.3),
                    child: MkTitle(top: mkT(context, 'bravo1'), bottom: mkT(context, 'bravo2'), pill: mkT(context, 'mission'), width: min(w * 0.86, 360 * s)),
                  ),
                  // stars
                  ScaleTransition(
                    scale: _seg(0.2, 0.55, Curves.elasticOut),
                    child: widget.stars == 3
                        ? Image.asset(mk('mk_stars_glow'), height: 86 * s)
                        : Image.asset(mk('mk_stars${widget.stars}'), height: 64 * s),
                  ),
                  Expanded(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Expanded(
                        flex: 11,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(-0.4, 0), end: Offset.zero).animate(_seg(0.25, 0.6, Curves.easeOutCubic)),
                          child: AnimatedBuilder(
                            animation: _idle,
                            builder: (_, c) => Transform.translate(offset: Offset(0, -sin(_idle.value * 2 * pi * 2).abs() * 5 * s), child: c),
                            child: Image.asset(mk('mk_party'), fit: BoxFit.contain, alignment: Alignment.bottomCenter),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 8,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0.5, 0), end: Offset.zero).animate(_seg(0.3, 0.65, Curves.easeOutCubic)),
                          child: Padding(
                            padding: EdgeInsets.only(right: 8 * s, bottom: 8 * s),
                            child: Container(
                              padding: EdgeInsets.all(8 * s),
                              decoration: BoxDecoration(
                                color: mkCream,
                                borderRadius: BorderRadius.circular(18 * s),
                                border: Border.all(color: const Color(0xFFF2B33D), width: 2 * s),
                              ),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                for (var i = 0; i < 3; i++)
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 3 * s),
                                    child: Opacity(
                                      opacity: i <= world ? 1 : 0.35,
                                      child: Row(children: [
                                        i <= world
                                            ? Image.asset(mk('mk_check'), width: 24 * s)
                                            : Icon(Icons.radio_button_unchecked_rounded, size: 24 * s, color: mkInkSoft),
                                        SizedBox(width: 6 * s),
                                        Expanded(child: Text(mkT(context, 'r$i'), style: mkText(13.5 * s))),
                                      ]),
                                    ),
                                  ),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  // rewards + badge
                  ScaleTransition(
                    scale: _seg(0.5, 0.8),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12 * s),
                      child: Row(children: [
                        Expanded(
                          child: _card(
                            s,
                            mkT(context, 'rewards'),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                              _reward(s, Icons.monetization_on_rounded, const Color(0xFFF2A900), '+${widget.gold}'),
                              if (widget.gems > 0) _reward(s, Icons.diamond_rounded, const Color(0xFF2E9BFF), '+${widget.gems}'),
                            ]),
                          ),
                        ),
                        if (widget.badge) ...[
                          SizedBox(width: 8 * s),
                          Expanded(
                            child: _card(
                              s,
                              mkT(context, 'badge'),
                              Stack(alignment: Alignment.bottomCenter, children: [
                                Image.asset(mk('mk_badge'), height: 74 * s),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 6 * s),
                                  child: Text(mkT(context, 'badgeName'), style: mkText(11 * s, color: Colors.white)),
                                ),
                              ]),
                            ),
                          ),
                        ],
                      ]),
                    ),
                  ),
                  SizedBox(height: 10 * s),
                  ScaleTransition(
                    scale: _seg(0.65, 0.95),
                    child: MkPlayButton(
                      label: last ? mkT(context, 'map') : mkT(context, 'next'),
                      onTap: () {
                        mkSound(context, 'PopButton');
                        Navigator.pop(context, last ? 'map' : 'next');
                      },
                      width: min(w * 0.78, 310 * s),
                      s: s,
                      pulse: _idle,
                    ),
                  ),
                  SizedBox(height: 8 * s),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    MkPillButton(label: mkT(context, 'again'), icon: Icons.refresh_rounded, onTap: () => Navigator.pop(context, 'again'), s: s),
                    SizedBox(width: 10 * s),
                    MkPillButton(label: mkT(context, 'map'), icon: Icons.map_rounded, iconColor: mkTeal, onTap: () => Navigator.pop(context, 'map'), s: s),
                  ]),
                  SizedBox(height: 10 * s),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _card(double s, String title, Widget child) => Container(
        padding: EdgeInsets.fromLTRB(8 * s, 6 * s, 8 * s, 8 * s),
        decoration: BoxDecoration(
          color: mkCream,
          borderRadius: BorderRadius.circular(20 * s),
          border: Border.all(color: mkTeal, width: 2.5 * s),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: mkText(15 * s)),
          SizedBox(height: 4 * s),
          child,
        ]),
      );

  Widget _reward(double s, IconData icon, Color c, String t) => Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _idle,
          builder: (_, ch) => Transform.scale(scale: 1 + 0.08 * sin(_idle.value * 2 * pi * 3), child: ch),
          child: Icon(icon, color: c, size: 46 * s, shadows: [Shadow(color: c.withOpacity(0.5), blurRadius: 12)]),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 2 * s),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12 * s), border: Border.all(color: const Color(0xFFF2B33D), width: 1.5 * s)),
          child: Text(t, style: mkText(17 * s, color: mkRed)),
        ),
      ]);
}

class _Confetti extends CustomPainter {
  final double t;
  _Confetti(this.t);
  static const _c = [Color(0xFFFFC21A), Color(0xFFFF6FB5), Color(0xFF34D9CF), Color(0xFF8B5CFF), Color(0xFF7DDB5A), Color(0xFFFF8A3D)];
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(5);
    for (var i = 0; i < 46; i++) {
      final x0 = r.nextDouble() * size.width;
      final sp = 0.6 + r.nextDouble() * 0.8;
      final ph = r.nextDouble();
      final y = ((t * sp + ph) % 1.0) * (size.height + 40) - 20;
      final x = x0 + sin((t * 3 + ph) * 2 * pi) * 18;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((t * 6 + ph) * 2 * pi);
      canvas.drawRect(const Rect.fromLTWH(-4, -2, 8, 4), Paint()..color = _c[i % _c.length]);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti o) => o.t != t;
}
