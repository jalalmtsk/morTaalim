import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';
import '../../main.dart';
import '../../tools/Ads_Manager.dart';
import '../../tools/audio_tool/Audio_Manager.dart';
import '../../widgets/userStatutBar.dart';

// ═══════════════════════════════════════════════════════════════
//  THEME
// ═══════════════════════════════════════════════════════════════
class _S {
  static const skyA  = Color(0xFF5C35CC);
  static const skyB  = Color(0xFFB01FBF);
  static const skyC  = Color(0xFFE84C00);
  static const lime  = Color(0xFF00E676);
  static const rose  = Color(0xFFFF1744);
  static const gold  = Color(0xFFFFD740);
  static const white = Color(0xFFFFFFFF);
  static const dark  = Color(0xFF12003E);
  static const font  = 'Fredoka';

  static const List<Color> wordColors = [
    Color(0xFFFF6D00), Color(0xFF00BCD4), Color(0xFFFF4081),
    Color(0xFF76FF03), Color(0xFFFFD740), Color(0xFFE040FB),
    Color(0xFF00E5FF), Color(0xFFFF5722),
  ];

  // Tile normal gradient stops
  static const tileTop = Color(0x44FFFFFF);
  static const tileMid = Color(0x22FFFFFF);
}

// ═══════════════════════════════════════════════════════════════
//  LANGUAGE DATA
// ═══════════════════════════════════════════════════════════════
enum _Lang { en, fr }

class _LangCfg {
  final String flag, label;
  final List<String> words;
  const _LangCfg({required this.flag, required this.label, required this.words});
}

const Map<_Lang, _LangCfg> _kLangs = {
  _Lang.en: _LangCfg(flag: '🇬🇧', label: 'English', words: [
    'CAT','DOG','SUN','BEE','ANT','FOX','HEN',
    'FISH','STAR','MOON','BIRD','BEAR','WOLF',
    'CAKE','TREE','LION','BOAT','MILK','ROSE',
    'APPLE','HOUSE','HORSE','SHARK','TIGER',
  ]),
  _Lang.fr: _LangCfg(flag: '🇫🇷', label: 'Français', words: [
    'CHAT','LUNE','LION','ANE','ROI','MER','FEU',
    'CHIEN','LAPIN','NUAGE','ARBRE','FLEUR','POMME',
    'CANARD','OISEAU','SOLEIL','GATEAU','HERBE',
    'MAISON','CHEVAL','AVION','DANSE','MAGIE',
  ]),
};

// ═══════════════════════════════════════════════════════════════
//  BOARD CELL
// ═══════════════════════════════════════════════════════════════
class _Cell {
  final int r, c;
  const _Cell(this.r, this.c);
  @override bool operator ==(Object o) => o is _Cell && o.r == r && o.c == c;
  @override int get hashCode => Object.hash(r, c);
  bool isNeighborOf(_Cell o) =>
      (r - o.r).abs() <= 1 && (c - o.c).abs() <= 1 && !(r == o.r && c == o.c);
}

// ═══════════════════════════════════════════════════════════════
//  BOARD GENERATOR
// ═══════════════════════════════════════════════════════════════
class _Gen {
  static const _dirs = [
    [0,1],[1,0],[1,1],[1,-1],[0,-1],[-1,0],[-1,1],[-1,-1],
  ];
  static final _rnd = Random();

  static ({List<List<String>> board, List<String> placed}) build(
      List<String> allWords, int sz) {
    final sorted = [...allWords]..sort((a, b) => b.length.compareTo(a.length));
    return _attempt(sorted, sz, 0);
  }

  static ({List<List<String>> board, List<String> placed}) _attempt(
      List<String> words, int sz, int depth) {
    if (depth > 20) {
      return (board: List.generate(sz, (_) => List.generate(sz, (_) => 'A')), placed: []);
    }
    final b = List.generate(sz, (_) => List.generate(sz, (_) => ''));
    final placed = <String>[];

    for (final word in words) {
      bool ok = false;
      for (int t = 0; t < 300 && !ok; t++) {
        final dir = _dirs[_rnd.nextInt(_dirs.length)];
        final r = _rnd.nextInt(sz), c = _rnd.nextInt(sz);
        if (_can(b, word, r, c, dir[0], dir[1], sz)) {
          _place(b, word, r, c, dir[0], dir[1]);
          placed.add(word);
          ok = true;
        }
      }
    }

    int empty = 0;
    for (int r = 0; r < sz; r++)
      for (int c = 0; c < sz; c++)
        if (b[r][c].isEmpty) empty++;

    if (empty > sz * sz * 0.20 && depth < 15) {
      return _attempt([...words]..shuffle(_rnd), sz, depth + 1);
    }

    // Fill gaps with short words
    const fillers = ['IT','OR','IS','AT','TO','IN','ON','UP','GO','DO','BE','ME','WE','US','AN','IF','HI'];
    int fi = 0;
    for (int r = 0; r < sz && fi < fillers.length; r++) {
      for (int c = 0; c < sz && fi < fillers.length; c++) {
        if (b[r][c].isEmpty) {
          final w = fillers[fi];
          for (final dir in [[0,1],[1,0],[0,-1],[-1,0]]) {
            if (_can(b, w, r, c, dir[0], dir[1], sz)) {
              _place(b, w, r, c, dir[0], dir[1]);
              if (!placed.contains(w)) placed.add(w);
              fi++;
              break;
            }
          }
        }
      }
    }

    // Last-resort single cells
    const alpha = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (int r = 0; r < sz; r++)
      for (int c = 0; c < sz; c++)
        if (b[r][c].isEmpty) b[r][c] = alpha[_rnd.nextInt(alpha.length)];

    return (board: b, placed: placed);
  }

  static bool _can(List<List<String>> b, String w, int r, int c, int dr, int dc, int sz) {
    for (int i = 0; i < w.length; i++) {
      final nr = r+i*dr, nc = c+i*dc;
      if (nr < 0 || nr >= sz || nc < 0 || nc >= sz) return false;
      if (b[nr][nc].isNotEmpty && b[nr][nc] != w[i]) return false;
    }
    return true;
  }

  static void _place(List<List<String>> b, String w, int r, int c, int dr, int dc) {
    for (int i = 0; i < w.length; i++) b[r+i*dr][c+i*dc] = w[i];
  }

  static List<_Cell>? findWord(List<List<String>> board, String word, int sz) {
    for (int r = 0; r < sz; r++) {
      for (int c = 0; c < sz; c++) {
        for (final dir in _dirs) {
          final cells = <_Cell>[];
          bool ok = true;
          for (int i = 0; i < word.length; i++) {
            final nr = r+i*dir[0], nc = c+i*dir[1];
            if (nr<0||nr>=sz||nc<0||nc>=sz||board[nr][nc]!=word[i]) { ok=false; break; }
            cells.add(_Cell(nr, nc));
          }
          if (ok) return cells;
        }
      }
    }
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════
//  FOUND-WORD OVERLAY PAINTER
//  Draws a rounded rectangle highlight behind each found word,
//  plus the active drag path on top.
//
//  KEY FIX: tile centre = pad + tileW/2 + col*(tileW+gap)
//           NOT (col * step + step/2 + pad)  ← that was wrong
// ═══════════════════════════════════════════════════════════════
class _BoardPainter extends CustomPainter {
  final List<_Cell> dragPath;
  final Map<_Cell, Color> foundCells;  // cell → its word colour
  final Map<String, ({List<_Cell> cells, Color color})> foundWords;
  final double tileW;   // actual tile width (without gap)
  final double gap;     // gap between tiles
  final double pad;     // board internal padding

  const _BoardPainter({
    required this.dragPath,
    required this.foundCells,
    required this.foundWords,
    required this.tileW,
    required this.gap,
    required this.pad,
  });

  // Pixel centre of a cell
  Offset _centre(_Cell c) {
    final x = pad + c.c * (tileW + gap) + tileW / 2;
    final y = pad + c.r * (tileW + gap) + tileW / 2;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw a soft rounded-rect highlight for each FOUND word
    for (final entry in foundWords.entries) {
      final cells = entry.value.cells;
      final color = entry.value.color;
      if (cells.isEmpty) continue;
      final paint = Paint()
        ..color = color.withOpacity(0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      for (final c in cells) {
        final cx = pad + c.c * (tileW + gap);
        final cy = pad + c.r * (tileW + gap);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - 2, cy - 2, tileW + 4, tileW + 4),
            const Radius.circular(12),
          ),
          paint,
        );
      }
    }

    // 2. Draw the active drag path
    if (dragPath.length >= 2) {
      final stroke = Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..strokeWidth = tileW * 0.30
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final dot = Paint()
        ..color = Colors.white.withOpacity(0.60)
        ..style = PaintingStyle.fill;

      final pts = dragPath.map(_centre).toList();
      final p = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < pts.length; i++) p.lineTo(pts[i].dx, pts[i].dy);
      canvas.drawPath(p, stroke);
      for (final pt in pts) canvas.drawCircle(pt, tileW * 0.12, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter o) =>
      o.dragPath != dragPath || o.foundCells != foundCells;
}

// ═══════════════════════════════════════════════════════════════
//  TILE WIDGET
// ═══════════════════════════════════════════════════════════════
enum _TileState { normal, dragging, foundPerm, wrongFlash }

class _Tile extends StatefulWidget {
  final String letter;
  final _TileState state;
  final Color foundColor;
  const _Tile({required this.letter, required this.state, this.foundColor = _S.lime});
  @override State<_Tile> createState() => _TileState2();
}

class _TileState2 extends State<_Tile> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 160));
  late final Animation<double> _sc = Tween(begin: 1.0, end: 1.15)
      .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));

  @override
  void didUpdateWidget(_Tile old) {
    super.didUpdateWidget(old);
    if (widget.state == _TileState.dragging && old.state != _TileState.dragging) {
      _ac.forward(from: 0).then((_) => _ac.reverse());
    }
  }

  @override void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    Color bg; Color fg; Color bdrColor; double bdrW = 2.0;

    switch (widget.state) {
      case _TileState.foundPerm:
        bg = widget.foundColor;
        fg = Colors.white;
        bdrColor = Colors.white.withOpacity(0.95);
        bdrW = 2.5;
      case _TileState.wrongFlash:
        bg = _S.rose;
        fg = Colors.white;
        bdrColor = Colors.white;
      case _TileState.dragging:
        bg = _S.skyC;
        fg = Colors.white;
        bdrColor = Colors.white;
        bdrW = 2.5;
      case _TileState.normal:
        bg = Colors.white.withOpacity(0.17);
        fg = Colors.white;
        bdrColor = Colors.white.withOpacity(0.40);
    }

    return AnimatedBuilder(
      animation: _sc,
      builder: (_, child) => Transform.scale(scale: _sc.value, child: child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: bdrColor, width: bdrW),
          boxShadow: widget.state == _TileState.foundPerm
              ? [BoxShadow(color: widget.foundColor.withOpacity(0.65), blurRadius: 10, offset: const Offset(0, 3))]
              : widget.state == _TileState.dragging
              ? [BoxShadow(color: _S.skyC.withOpacity(0.55), blurRadius: 12, offset: const Offset(0, 3))]
              : [const BoxShadow(color: Color(0x1F000000), blurRadius: 3, offset: Offset(0, 2))],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(widget.letter,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  fontFamily: _S.font,
                  color: fg,
                  shadows: const [Shadow(color: Colors.black26, blurRadius: 3)],
                )),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  BANNER AD BAR
// ═══════════════════════════════════════════════════════════════
class _BannerBar extends StatefulWidget {
  final BannerAd? bannerAd; final bool isLoaded;
  const _BannerBar({required this.bannerAd, required this.isLoaded});
  @override State<_BannerBar> createState() => _BannerBarState();
}
class _BannerBarState extends State<_BannerBar> with SingleTickerProviderStateMixin {
  late final AnimationController _sh = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  late final Animation<double> _sa = CurvedAnimation(parent: _sh, curve: Curves.easeInOut);
  @override void dispose() { _sh.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final adH = (widget.bannerAd?.size.height ?? 50).toDouble();
    return SafeArea(
      top: false,
      child: Container(
        height: adH + 10,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [_S.skyA, _S.skyB]),
          boxShadow: [BoxShadow(color: Color(0x445C35CC), blurRadius: 12, offset: Offset(0, -4))],
        ),
        child: widget.isLoaded && widget.bannerAd != null
            ? Center(child: SizedBox(height: adH, width: widget.bannerAd!.size.width.toDouble(),
            child: AdWidget(ad: widget.bannerAd!)))
            : AnimatedBuilder(animation: _sa, builder: (_, __) {
          final t = _sa.value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(children: [
              Opacity(opacity: 0.5+t*0.5, child: const Text('🌟', style: TextStyle(fontSize: 18))),
              const SizedBox(width: 10),
              Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(height: 28,
                      color: Colors.white.withOpacity(0.16+t*0.16),
                      alignment: Alignment.center,
                      child: Text('✨  Advertisement  ✨',
                          style: TextStyle(fontFamily: _S.font, fontSize: 12,
                              color: Colors.white.withOpacity(0.55+t*0.35)))))),
              const SizedBox(width: 10),
              Opacity(opacity: 0.5+t*0.5, child: const Text('🌟', style: TextStyle(fontSize: 18))),
            ]),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  FUN LOADER
// ═══════════════════════════════════════════════════════════════
class _FunLoader extends StatefulWidget {
  final String msg;
  const _FunLoader({required this.msg});
  @override State<_FunLoader> createState() => _FunLoaderState();
}
class _FunLoaderState extends State<_FunLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 900))..repeat();
  final _icons = ['🎯','⭐','🎉','🌈','🚀','🎊'];
  int _ei = 0;
  @override void initState() {
    super.initState();
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 280));
      if (!mounted) return false;
      setState(() => _ei = (_ei+1) % _icons.length);
      return true;
    });
  }
  @override void dispose() { _spin.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black.withOpacity(0.65),
    child: Center(child: Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_S.skyA, _S.skyB],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [BoxShadow(color: _S.skyA.withOpacity(0.60), blurRadius: 40, offset: const Offset(0,12))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(animation: _spin,
            builder: (_,__) => Transform.rotate(angle: _spin.value*2*pi,
                child: Text(_icons[_ei], style: const TextStyle(fontSize: 52)))),
        const SizedBox(height: 14),
        Text(widget.msg, textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: _S.font, fontSize: 16, color: _S.white)),
      ]),
    )),
  );
}

// ═══════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════════
class WordBoardGame extends StatefulWidget {
  const WordBoardGame({super.key});
  @override State<WordBoardGame> createState() => _WordBoardGameState();
}

class _WordBoardGameState extends State<WordBoardGame>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  static const int _sz  = 6;
  static const double _pad = 10.0;   // board internal padding
  static const double _gap = 10.0;   // gap between tiles

  _Lang _lang = _Lang.en;

  late List<List<String>> _board;
  late List<String> _targets;
  late List<String> _placed;
  final _found    = <String>[];
  final _foundMap = <String, ({List<_Cell> cells, Color color})>{};
  final _foundCells = <_Cell, Color>{};

  List<_Cell> _path     = [];
  bool _dragging        = false;
  double _tileW         = 0;  // actual tile pixel width (no gap)
  Set<_Cell> _wrongFlash = {};
  int _colorIdx         = 0;

  bool _showLoader = false;
  String _loaderMsg = '';

  late AnimationController _entryCtrl;
  late Animation<double>   _entryFade;
  late Animation<Offset>   _entrySlide;
  late ConfettiController  _confetti;

  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 480))..forward();
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _startGame();
    _loadBannerAd();
  }

  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entryCtrl.dispose(); _confetti.dispose(); _bannerAd?.dispose();
    super.dispose();
  }

  @override void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd?.dispose(); _bannerLoaded = false;
    if (!mounted) return;
    if (!Provider.of<ExperienceManager>(context, listen: false).adsEnabled) return;
    _bannerAd = AdHelper.getBannerAd(() { if (mounted) setState(() => _bannerLoaded = true); });
  }

  void _startGame() {
    final cfg = _kLangs[_lang]!;
    final shuffled = [...cfg.words]..shuffle();
    final result = _Gen.build(shuffled, _sz);
    _board  = result.board;
    _placed = result.placed;

    final available = _placed.where((w) => cfg.words.contains(w)).toList()..shuffle();
    _targets = available.take(8).toList();

    _found.clear(); _foundMap.clear(); _foundCells.clear();
    _path.clear(); _dragging = false; _wrongFlash = {}; _colorIdx = 0;
    _entryCtrl.reset(); _entryCtrl.forward();
  }

  void _newGame() { setState(_startGame); HapticFeedback.mediumImpact(); }
  void _setLang(_Lang l) { setState(() { _lang = l; _startGame(); }); }

  // ── Cell hit-test — EXACT match to painter formula ──────────
  // tile centre x = _pad + col*(tileW+gap) + tileW/2
  // So col = floor((x - _pad) / (tileW + gap))
  _Cell? _cellAt(Offset pos) {
    if (_tileW <= 0) return null;
    final step = _tileW + _gap;
    final rr = ((pos.dy - _pad) / step).floor();
    final cc = ((pos.dx - _pad) / step).floor();
    if (rr >= 0 && rr < _sz && cc >= 0 && cc < _sz) return _Cell(rr, cc);
    return null;
  }

  void _onStart(Offset pos) {
    final cell = _cellAt(pos);
    if (cell == null) return;
    setState(() { _path = [cell]; _dragging = true; });
    HapticFeedback.selectionClick();
  }

  void _onMove(Offset pos) {
    if (!_dragging) return;
    final cell = _cellAt(pos);
    if (cell == null) return;
    final idx = _path.indexOf(cell);
    List<_Cell> np;
    if (idx >= 0) {
      np = _path.sublist(0, idx+1);
    } else {
      if (_path.isNotEmpty && _path.last.isNeighborOf(cell)) {
        np = [..._path, cell];
        HapticFeedback.selectionClick();
      } else return;
    }
    setState(() => _path = np);
  }

  void _onEnd() {
    if (!_dragging) return;
    _dragging = false;
    final word  = _path.map((c) => _board[c.r][c.c]).join();
    final cells = List<_Cell>.from(_path);
    setState(() => _path = []);

    if (_targets.contains(word) && !_found.contains(word)) {
      final boardCells = _Gen.findWord(_board, word, _sz) ?? cells;
      final color = _S.wordColors[_colorIdx % _S.wordColors.length];
      _colorIdx++;
      setState(() {
        _found.add(word);
        _foundMap[word] = (cells: boardCells, color: color);
        for (final c in boardCells) _foundCells[c] = color;
      });
      _audio().playSfx('assets/audios/QuizGame_Sounds/correct.mp3');
      HapticFeedback.heavyImpact();
      Provider.of<ExperienceManager>(context, listen: false).addXP(5, context: context);
      if (_found.length >= _targets.length) Future.delayed(const Duration(milliseconds: 700), _onWin);
    } else if (word.length > 1 && !_found.contains(word)) {
      final wrongSet = Set<_Cell>.from(cells);
      setState(() { _wrongFlash = wrongSet; });
      _audio().playSfx('assets/audios/QuizGame_Sounds/incorrect.mp3');
      HapticFeedback.heavyImpact();
      Timer(const Duration(milliseconds: 520), () {
        if (mounted) setState(() => _wrongFlash = {});
      });
    }
  }

  void _onWin() {
    _confetti.play();
    _audio().playSfx('assets/audios/UI_Audio/SFX_Audio/VictoryOrchestral_SFX.mp3');
    _audio().playSfx('assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3');
    Provider.of<ExperienceManager>(context, listen: false)
      ..addTokenBanner(context, 1)
      ..addXP(30, context: context);
    _showWinDialog();
  }

  void _showWinDialog() {
    final stars = _starCount();
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(26, 26, 26, 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_S.skyA, _S.skyB, _S.skyC],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.55), width: 2),
            boxShadow: [BoxShadow(color: _S.skyA.withOpacity(0.60), blurRadius: 40, offset: const Offset(0,12))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 130, height: 130,
                child: Lottie.asset('assets/animations/QuizzGame_Animation/Champion.json', repeat: true)),
            Text(_langLabel('winTitle'), textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: _S.font, fontSize: 26, color: _S.white,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 6)])),
            const SizedBox(height: 4),
            Text(_langLabel('winSub'), textAlign: TextAlign.center,
                style: TextStyle(fontFamily: _S.font, fontSize: 14, color: Colors.white.withOpacity(0.85))),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(i < stars ? '⭐' : '☆',
                        style: TextStyle(fontSize: i < stars ? 36 : 26,
                            color: i < stars ? _S.gold : Colors.white30))))),
            const SizedBox(height: 18),
            _FlatBtn(label: '🎮 ${_langLabel('again')}',
                color: _S.lime.withOpacity(0.90), shadowColor: _S.lime,
                onTap: () { Navigator.pop(context); _newGame(); }),
            const SizedBox(height: 8),
            _FlatBtn(label: '🏠 ${_langLabel('exit')}',
                color: Colors.white.withOpacity(0.22), borderColor: Colors.white.withOpacity(0.60),
                onTap: () {
                  _audio().playEventSound('cancelButton');
                  Navigator.pop(context);
                  _withLoader(message: '👋 See you soon!',
                      action: () => AdHelper.showInterstitialAd(
                          onDismissed: () { if (mounted) Navigator.pop(context); }, context: context));
                }),
          ]),
        ),
      ),
    );
  }

  Future<bool> _confirmQuit() async {
    final audio = Provider.of<AudioManager>(context, listen: false);
    final quit = await showDialog<bool>(
      context: context, barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_S.skyA, _S.skyB],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: _S.skyA.withOpacity(0.55), blurRadius: 30, offset: const Offset(0,10))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🤔', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            Text(tr(context).areYouSureQuitGame, textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: _S.font, fontSize: 20, color: _S.white)),
            const SizedBox(height: 6),
            Text(tr(context).youWillLoseYourProgress, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75))),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _FlatBtn(label: tr(context).cancel,
                  color: Colors.white.withOpacity(0.22), borderColor: Colors.white.withOpacity(0.50),
                  onTap: () { audio.playEventSound('cancelButton'); Navigator.pop(ctx, false); })),
              const SizedBox(width: 12),
              Expanded(child: _FlatBtn(label: tr(context).ok, color: _S.rose,
                  onTap: () { audio.playEventSound('clickButton'); Navigator.pop(ctx, true); })),
            ]),
          ]),
        ),
      ),
    );
    if (quit ?? false) {
      await _withLoader(message: '👋 See you soon!',
          action: () => AdHelper.showInterstitialAd(
              onDismissed: () { if (mounted) Navigator.pop(context, true); }, context: context));
      return true;
    }
    return false;
  }

  Future<void> _withLoader({required String message, required Future<void> Function() action}) async {
    setState(() { _showLoader = true; _loaderMsg = message; });
    await Future.delayed(const Duration(milliseconds: 300));
    await action();
    if (mounted) setState(() => _showLoader = false);
  }

  AudioManager _audio() => Provider.of<AudioManager>(context, listen: false);
  int _starCount() {
    final r = _targets.isEmpty ? 0.0 : _found.length / _targets.length;
    return r >= 1.0 ? 3 : r >= 0.6 ? 2 : 1;
  }

  String _langLabel(String key) {
    const L = {
      _Lang.en: {'winTitle':'You Won! 🎉','winSub':'Amazing! All words found!','again':'Play Again',
        'exit':'Back to games','tracing':'Tracing','findWords':'Find the hidden words!'},
      _Lang.fr: {'winTitle':'Bravo! 🎉','winSub':'Incroyable! Tous les mots!','again':'Rejouer',
        'exit':'Retour','tracing':'Sélection','findWords':'Trouve les mots cachés!'},
    };
    return L[_lang]![key] ?? key;
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final selWord = _path.map((c) => _board[c.r][c.c]).join();
    return WillPopScope(
      onWillPop: () async {
        final q = await _confirmQuit();
        if (q) _audio().playEventSound('cancelButton');
        return q;
      },
      child: Scaffold(
        bottomNavigationBar: context.watch<ExperienceManager>().adsEnabled
            ? _BannerBar(bannerAd: _bannerAd, isLoaded: _bannerLoaded) : null,
        body: Stack(children: [
          // Static gradient BG — no AnimationController = zero lag
          Container(decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF4A27B0), Color(0xFF9A1AAA), Color(0xFFD43800)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
          )),

          // Static decorative blobs
          Positioned(top: -80, right: -80,
              child: _Blob(160, Colors.white.withOpacity(0.07))),
          Positioned(top: 180, left: -60,
              child: _Blob(110, Colors.white.withOpacity(0.06))),
          Positioned(bottom: 220, right: -50,
              child: _Blob(130, Colors.white.withOpacity(0.06))),
          Positioned(bottom: -70, left: 30,
              child: _Blob(100, Colors.white.withOpacity(0.05))),

          SafeArea(
            child: FadeTransition(
              opacity: _entryFade,
              child: SlideTransition(
                position: _entrySlide,
                child: Column(children: [
                  // ── UserStatutBar ────────────────────────────
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Userstatutbar(),
                  ),
                  const SizedBox(height: 8),

                  // ── HUD ──────────────────────────────────────
                  _buildHUD(),
                  const SizedBox(height: 8),

                  // ── Prompt ───────────────────────────────────
                  _buildPrompt(),
                  const SizedBox(height: 7),

                  // ── Word pills (scrollable) ───────────────────
                  _buildWordPills(),
                  const SizedBox(height: 7),

                  // ── Board ────────────────────────────────────
                  Expanded(child: _buildBoard()),
                  const SizedBox(height: 6),

                  // ── Selection bar ─────────────────────────────
                  _buildSelBar(selWord),
                  const SizedBox(height: 8),
                ]),
              ),
            ),
          ),

          // Confetti
          Align(alignment: Alignment.topCenter,
              child: IgnorePointer(child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.07, numberOfParticles: 50, gravity: 0.28,
                colors: [_S.skyA, _S.skyB, _S.skyC, _S.lime, _S.gold, Colors.cyan, Colors.pinkAccent],
              ))),

          if (_showLoader) _FunLoader(msg: _loaderMsg),
        ]),
      ),
    );
  }

  // ── HUD: back | [EN  FR lang pill] | score | refresh ────────
  // Uses Flexible to avoid overflow on narrow screens
  Widget _buildHUD() {
    final pct = (_targets.isEmpty ? 0.0 : _found.length / _targets.length).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.40), width: 1.5),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            // Back
            _HudBtn(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () async {
                if (await _confirmQuit()) {
                  _audio().playEventSound('cancelButton');
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
            const SizedBox(width: 8),

            // Lang switcher — Flexible so it shrinks on small screens
            Flexible(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                ),
                child: Row(children: _Lang.values.map((l) {
                  final cfg = _kLangs[l]!;
                  final active = l == _lang;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () { _audio().playEventSound('PopButton'); _setLang(l); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: active ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: active
                              ? [BoxShadow(color: Colors.white.withOpacity(0.35), blurRadius: 8)]
                              : null,
                        ),
                        child: Center(child: Text(
                          '${cfg.flag}  ${cfg.label}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: _S.font, fontSize: 13, fontWeight: FontWeight.w700,
                            color: active ? _S.skyA : Colors.white.withOpacity(0.80),
                          ),
                        )),
                      ),
                    ),
                  );
                }).toList()),
              ),
            ),

            const SizedBox(width: 8),
            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: _S.gold.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _S.gold.withOpacity(0.65), width: 1.2),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('✅', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 3),
                Text('${_found.length}/${_targets.length}',
                    style: const TextStyle(fontFamily: _S.font, fontSize: 14, color: _S.white)),
              ]),
            ),
            const SizedBox(width: 6),
            // Refresh
            _HudBtn(icon: Icons.refresh_rounded,
                onTap: () { _audio().playEventSound('PopButton'); _newGame(); }),
          ]),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(children: [
              Container(height: 9, color: Colors.white.withOpacity(0.18)),
              FractionallySizedBox(widthFactor: pct,
                  child: Container(height: 9,
                      decoration: const BoxDecoration(gradient: LinearGradient(
                          colors: [_S.gold, _S.lime, Color(0xFF00E5FF)])))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildPrompt() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('🔍', style: TextStyle(fontSize: 15)),
        const SizedBox(width: 8),
        Text(_langLabel('findWords'),
            style: const TextStyle(fontFamily: _S.font, fontSize: 14, color: _S.white,
                shadows: [Shadow(color: Colors.black26, blurRadius: 3)])),
      ]),
    );
  }

  Widget _buildWordPills() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _targets.map((w) {
          final ok = _found.contains(w);
          final color = ok ? (_foundMap[w]?.color ?? _S.lime) : null;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: ok ? color!.withOpacity(0.85) : Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                  color: ok ? color! : Colors.white.withOpacity(0.45), width: 2),
              boxShadow: ok
                  ? [BoxShadow(color: color!.withOpacity(0.50), blurRadius: 8)] : null,
            ),
            child: Text(w, style: TextStyle(
              fontFamily: _S.font, fontSize: 13, fontWeight: FontWeight.w600,
              color: ok ? _S.dark : _S.white,
              decoration: ok ? TextDecoration.lineThrough : null,
              decorationColor: _S.dark, decorationThickness: 2.5,
            )),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBoard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(builder: (ctx, box) {
        // ── Compute exact tile size ──────────────────────────
        // available = box.maxWidth
        // total = 2*_pad + _sz*tileW + (_sz-1)*_gap
        // → tileW = (available - 2*_pad - (_sz-1)*_gap) / _sz
        final available = box.maxWidth;
        // Floor to nearest 0.5px so accumulated tile+gap never exceeds available
        _tileW = ((available - 2 * _pad - (_sz - 1) * _gap) / _sz * 2).floorToDouble() / 2;
        final boardH = 2 * _pad + _sz * _tileW + (_sz - 1) * _gap;

        return Container(
          width: available,
          height: boardH,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.38), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: GestureDetector(
              onPanStart:  (d) => _onStart(d.localPosition),
              onPanUpdate: (d) => _onMove(d.localPosition),
              onPanEnd:    (_) => _onEnd(),
              onPanCancel: _onEnd,
              child: Stack(children: [
                // ── Tiles ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(_pad),
                  child: SizedBox(
                    width: _sz * _tileW + (_sz - 1) * _gap,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_sz, (r) => Padding(
                        padding: EdgeInsets.only(bottom: r < _sz-1 ? _gap : 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: List.generate(_sz, (c) {
                            final cell = _Cell(r, c);
                            _TileState ts;
                            Color fc = _S.lime;
                            if (_wrongFlash.contains(cell)) {
                              ts = _TileState.wrongFlash;
                            } else if (_foundCells.containsKey(cell)) {
                              ts = _TileState.foundPerm;
                              fc = _foundCells[cell]!;
                            } else if (_path.contains(cell)) {
                              ts = _TileState.dragging;
                            } else {
                              ts = _TileState.normal;
                            }
                            return Padding(
                              padding: EdgeInsets.only(right: c < _sz-1 ? _gap : 0),
                              child: SizedBox(
                                width: _tileW, height: _tileW,
                                child: _Tile(letter: _board[r][c], state: ts, foundColor: fc),
                              ),
                            );
                          }),
                        ),
                      )),
                    ),
                  ),
                ),

                // ── Overlay: found-word glow + drag path ──
                IgnorePointer(child: CustomPaint(
                  size: Size(available, boardH),
                  painter: _BoardPainter(
                    dragPath:   _path,
                    foundCells: _foundCells,
                    foundWords: _foundMap,
                    tileW: _tileW,
                    gap:   _gap,
                    pad:   _pad,
                  ),
                )),
              ]),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSelBar(String word) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.40), width: 1.5),
        ),
        child: Row(children: [
          const Text('✍️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(_langLabel('tracing'),
              style: TextStyle(fontFamily: _S.font, fontSize: 12,
                  color: Colors.white.withOpacity(0.60))),
          const SizedBox(width: 8),
          Expanded(child: Text(word,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: _S.font, fontSize: 22, fontWeight: FontWeight.w700,
                color: _S.white, letterSpacing: 3,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
              ))),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════
class _HudBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HudBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 40, height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.50), width: 1.5),
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    ),
  );
}

class _Blob extends StatelessWidget {
  final double size; final Color color;
  const _Blob(this.size, this.color);
  @override Widget build(BuildContext context) =>
      Container(width: size, height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class _FlatBtn extends StatelessWidget {
  final String label; final VoidCallback onTap;
  final Color color; final Color? borderColor, shadowColor;
  const _FlatBtn({required this.label, required this.onTap, required this.color,
    this.borderColor, this.shadowColor});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: borderColor != null ? Border.all(color: borderColor!, width: 1.8) : null,
        boxShadow: shadowColor != null
            ? [BoxShadow(color: shadowColor!.withOpacity(0.50), blurRadius: 14, offset: const Offset(0,5))]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(fontFamily: _S.font, fontSize: 17, color: _S.white,
          shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
    ),
  );
}