import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/Manager/lesson_progress.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/tools/Ads_Manager.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_page_parts.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

import 'alpha_draw_data.dart';
import 'alpha_draw_ui.dart';

const List<Color> _inks = [Color(0xFF5B21E6), Color(0xFF1FB8EE), Color(0xFFFF5FA8)];
const List<String> _inkSprites = ['ad_color_purple', 'ad_color_cyan', 'ad_color_pink'];
const Color _guide = Color(0xFF5B2BD9);
const Color _ghost = Color(0xFFE4D6FF);
const Color _ghostEdge = Color(0xFFB99BF5);

/// The 100 × 100 letter box (see alpha_draw_data.dart) placed on the board.
class _Box {
  final Offset origin;
  final double side;
  const _Box(this.origin, this.side);
  double get k => side / 100;
  Offset toScreen(Offset p) => origin + p * k;
  Offset toBox(Offset p) => (p - origin) / k;
}

/// What the child must cover, in letter-box units.
class _Target {
  final List<Offset> points;
  final double cover; // a target point counts as covered within this distance
  final double inside; // a drawn point counts as on the letter within this distance
  const _Target(this.points, this.cover, this.inside);
}

TextPainter _glyph(String ch, Color color) => TextPainter(
      text: TextSpan(text: ch, style: TextStyle(fontSize: 78, fontWeight: FontWeight.w700, color: color, height: 1.0)),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

Offset _glyphOffset(TextPainter tp) => Offset((100 - tp.width) / 2, (100 - tp.height) / 2);

List<Offset> _resample(List<Offset> line, double step) {
  if (line.isEmpty) return const [];
  final out = <Offset>[line.first];
  for (int i = 1; i < line.length; i++) {
    final a = line[i - 1], b = line[i];
    final d = (b - a).distance;
    final n = max(1, (d / step).ceil());
    for (int k = 1; k <= n; k++) {
      out.add(Offset.lerp(a, b, k / n)!);
    }
  }
  return out;
}

double _length(List<Offset> l) {
  var d = 0.0;
  for (int i = 1; i < l.length; i++) {
    d += (l[i] - l[i - 1]).distance;
  }
  return d;
}

class AlphaDrawPage extends StatefulWidget {
  final String language;
  final AdMode mode;
  const AlphaDrawPage({super.key, required this.language, this.mode = AdMode.trace});

  @override
  State<AlphaDrawPage> createState() => _AlphaDrawPageState();
}

class _AlphaDrawPageState extends State<AlphaDrawPage> with TickerProviderStateMixin {
  late AdLanguage _lang = adLanguage(widget.language);
  late AdMode _mode = widget.mode;
  int _i = 0;
  bool _lower = false;
  int _ink = 0;
  Set<String> _done = {};

  // drawing, in letter-box units
  final List<List<Offset>> _strokes = [];
  final List<int> _strokeInk = [];

  // result of "Vérifier"
  int? _stars; // null = not checked yet
  String _robotKey = 'yourTurn';

  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  late final AnimationController _demo = AnimationController(vsync: this);
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final AnimationController _bump = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  final Set<String> _demoed = {};
  final Map<String, _Target> _targets = {};
  final ScrollController _strip = ScrollController();
  final FlutterTts _tts = FlutterTts();
  bool _checking = false;
  int? _pointer; // finger currently drawing

  BannerAd? _banner;
  bool _bannerLoaded = false;

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);
  ExperienceManager get _xp => Provider.of<ExperienceManager>(context, listen: false);

  AdLetter get _letter => _lang.letters[_i];
  String get _char => _lower && _lang.hasCase ? _letter.char.toLowerCase() : _letter.char;
  List<List<Offset>>? get _guides => adStrokes(_char);

  @override
  void initState() {
    super.initState();
    _banner = AdHelper.getBannerAd(() {
      if (mounted) setState(() => _bannerLoaded = true);
    });
    _openLanguage(_lang, first: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    KidAssets.precache(context, [
      '${adDir}ad_robot_point.webp', '${adDir}ad_pencil.webp', '${adDir}ad_plane.webp',
      '${adDir}ad_tile_blank.webp', '${adDir}ad_tile_sel.webp',
      for (final c in _inkSprites) '$adDir$c.webp',
    ]);
  }

  @override
  void dispose() {
    _tts.stop();
    _idle.dispose();
    _demo.dispose();
    _pop.dispose();
    _bump.dispose();
    _strip.dispose();
    _banner?.dispose();
    super.dispose();
  }

  // ── navigation between letters / languages ───────────────────────────────

  Future<void> _openLanguage(AdLanguage l, {bool first = false}) async {
    final idx = await AdStore.lastIndex(l.code);
    final done = await AdStore.done(l.code);
    AdStore.setLastLanguage(l.code);
    if (!mounted) return;
    setState(() {
      _lang = l;
      _i = idx.clamp(0, l.letters.length - 1);
      _lower = false;
      _done = done;
    });
    try {
      await _tts.setLanguage(l.tts);
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.15);
    } catch (_) {}
    _letterChanged(speak: true);
  }

  void _goTo(int i, {bool lower = false}) {
    if (i == _i && lower == _lower) return;
    _audio.playEventSound('clickButton2');
    setState(() {
      _i = i;
      _lower = lower;
    });
    AdStore.setLastIndex(_lang.code, i);
    _letterChanged(speak: true);
  }

  void _next() {
    if (_lang.hasCase && !_lower) {
      _goTo(_i, lower: true);
    } else {
      _goTo((_i + 1) % _lang.letters.length);
    }
  }

  void _letterChanged({bool speak = false}) {
    _pointer = null;
    _demo.stop();
    _demo.value = 0;
    setState(() {
      _strokes.clear();
      _strokeInk.clear();
      _stars = null;
      _robotKey = _mode == AdMode.trace && _guides != null ? 'startDot' : 'yourTurn';
    });
    _pop.reset();
    _bump.forward(from: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollStrip());
    if (speak) _speak();
    if (_mode == AdMode.trace && _guides != null && !_demoed.contains(_char)) {
      _demoed.add(_char);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted && _strokes.isEmpty) _playDemo(sound: false);
      });
    }
  }

  void _scrollStrip() {
    if (!_strip.hasClients) return;
    final tile = 64.0 * _scale(context) + 8;
    final target = (_i * tile - _strip.position.viewportDimension / 2 + tile / 2).clamp(0.0, _strip.position.maxScrollExtent);
    _strip.animateTo(target, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  Future<void> _speak() async {
    final l = _letter;
    final say = l.speak ?? (_lang.hasCase ? _letter.char : l.name);
    final word = l.word;
    String text = say;
    if (word != null && word != l.char) {
      text = switch (_lang.code) {
        'french' => '$say, comme $word',
        'english' => '$say, is for $word',
        _ => '$say. $word',
      };
    }
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  // ── tools ────────────────────────────────────────────────────────────────

  void _undo() {
    if (_strokes.isEmpty) return;
    _audio.playEventSound('cancelButton');
    setState(() {
      _strokes.removeLast();
      _strokeInk.removeLast();
      _stars = null;
    });
  }

  void _clear() {
    if (_strokes.isEmpty) return;
    _audio.playEventSound('cancelButton');
    setState(() {
      _strokes.clear();
      _strokeInk.clear();
      _stars = null;
      _robotKey = 'yourTurn';
    });
  }

  void _playDemo({bool sound = true}) {
    final g = _guides;
    if (sound) _audio.playEventSound('clickButton2');
    if (g == null || _mode == AdMode.free) {
      _speak();
      _bump.forward(from: 0);
      return;
    }
    final len = g.fold<double>(0, (a, s) => a + _length(s));
    _demo.duration = Duration(milliseconds: (len * 16 + g.length * 250).clamp(1200, 5000).round());
    setState(() => _robotKey = 'watch');
    _demo.forward(from: 0).whenComplete(() {
      if (mounted && _robotKey == 'watch') setState(() => _robotKey = 'yourTurn');
    });
  }

  // ── drawing ──────────────────────────────────────────────────────────────

  void _penDown(Offset boxPoint) {
    if (_demo.isAnimating) {
      _demo.stop();
      _demo.value = 1; // keep the shown path as a guide under the child's line
    }
    _audio.playSfx('assets/audios/writting.mp3');
    setState(() {
      if (_stars != null) {
        final passed = _stars! > 0;
        _stars = null;
        if (passed && _mode != AdMode.free) {
          _strokes.clear();
          _strokeInk.clear();
        }
      }
      _strokes.add([boxPoint]);
      _strokeInk.add(_ink);
      if (_robotKey != 'yourTurn') _robotKey = 'yourTurn';
    });
  }

  void _penMove(Offset boxPoint) {
    if (_strokes.isEmpty) return;
    final s = _strokes.last;
    if ((s.last - boxPoint).distance < 0.8) return;
    setState(() => s.add(boxPoint));
  }

  // ── checking ─────────────────────────────────────────────────────────────

  Future<_Target> _target(String ch) async {
    final cached = _targets[ch];
    if (cached != null) return cached;
    final g = adStrokes(ch);
    _Target t;
    if (g != null) {
      t = _Target([for (final s in g) ..._resample(s, 2)], 9, 12);
    } else {
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      final tp = _glyph(ch, Colors.black);
      tp.paint(canvas, _glyphOffset(tp));
      final img = await rec.endRecording().toImage(100, 100);
      final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      final pts = <Offset>[];
      if (data != null) {
        for (int y = 0; y < 100; y += 2) {
          for (int x = 0; x < 100; x += 2) {
            if (data.getUint8((y * 100 + x) * 4 + 3) > 80) pts.add(Offset(x + 0.5, y + 0.5));
          }
        }
      }
      t = _Target(pts, 8, 7);
    }
    _targets[ch] = t;
    return t;
  }

  Future<void> _check() async {
    if (_checking) return;
    final drawn = [for (final s in _strokes) ..._resample(s, 2)];
    if (_mode == AdMode.free) {
      if (drawn.length < 6) {
        _audio.playEventSound('invalid');
        setState(() => _robotKey = 'drawMore');
        _bump.forward(from: 0);
        return;
      }
      _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/MarimbaWin_SFX.mp3');
      setState(() {
        _stars = 3;
        _robotKey = 'nice';
      });
      _pop.forward(from: 0);
      _bump.forward(from: 0);
      return;
    }
    _checking = true;
    try {
      final t = await _target(_char);
      if (!mounted || t.points.isEmpty) return;
      final cover = drawn.isEmpty
          ? 0.0
          : t.points.where((p) => drawn.any((d) => (d - p).distanceSquared <= t.cover * t.cover)).length / t.points.length;
      final inside = drawn.isEmpty
          ? 0.0
          : drawn.where((d) => t.points.any((p) => (d - p).distanceSquared <= t.inside * t.inside)).length / drawn.length;

      int stars;
      if (cover >= 0.85 && inside >= 0.82) {
        stars = 3;
      } else if (cover >= 0.7 && inside >= 0.68) {
        stars = 2;
      } else if (cover >= 0.5 && inside >= 0.55) {
        stars = 1;
      } else {
        stars = 0;
      }
      final key = stars == 3
          ? 'bravo'
          : stars > 0
              ? 'almost'
              : cover < 0.5
                  ? 'drawMore'
                  : 'stayInside';
      setState(() {
        _stars = stars;
        _robotKey = key;
      });
      _pop.forward(from: 0);
      _bump.forward(from: 0);
      if (stars == 0) {
        _audio.playEventSound('invalid');
        return;
      }
      _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/MarimbaWin_SFX.mp3');
      if (stars == 3) _confetti();
      final total = await AdStore.learn(_lang.code, _char);
      if (total != null && mounted) {
        setState(() => _done.add(_char));
        ActivityLog.markToday();
        _xp.addXP(1 + stars, context: context);
        if (total % 10 == 0) {
          _xp.addTokenBanner(context, 1);
          _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory1_SFX.mp3');
        }
      }
    } finally {
      _checking = false;
    }
  }

  void _confetti() {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: Center(child: Lottie.asset('assets/animations/UI_Animations/Confetti1.json', width: 460, height: 460, repeat: false)),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 2800), entry.remove);
  }

  // ── language picker ──────────────────────────────────────────────────────

  Future<void> _pickLanguage() async {
    _audio.playEventSound('clickButton2');
    final s = _scale(context);
    final picked = await showModalBottomSheet<AdLanguage>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.75, maxWidth: 600),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: EdgeInsets.fromLTRB(14 * s, 10 * s, 14 * s, 14 * s),
        decoration: adPillDecoration(30 * s),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: adLavender, borderRadius: BorderRadius.circular(5))),
            SizedBox(height: 10 * s),
            Text(adText(ctx, 'chooseLang'), style: kidTitleStyle(22 * s, color: adInk).copyWith(shadows: const [])),
            SizedBox(height: 10 * s),
            Flexible(
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 10 * s,
                crossAxisSpacing: 10 * s,
                childAspectRatio: 0.9,
                children: [
                  for (final l in adLanguages)
                    Builder(builder: (_) {
                      final open = l.cost == 0 || _xp.isLanguageUnlocked(l.code);
                      final sel = l.code == _lang.code;
                      return KidPressable(
                        onTap: open ? () => Navigator.pop(ctx, l) : null,
                        child: Opacity(
                          opacity: open ? 1 : 0.5,
                          child: Container(
                            padding: EdgeInsets.all(6 * s),
                            decoration: adPillDecoration(18 * s, selected: sel),
                            child: Column(children: [
                              Expanded(child: Image.asset(l.tile, fit: BoxFit.contain)),
                              SizedBox(height: 4 * s),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(children: [
                                  if (!open) Icon(Icons.lock_rounded, size: 14 * s, color: adInk),
                                  Text(l.native, style: kidBodyStyle(14 * s, color: adInk, weight: FontWeight.w700)),
                                ]),
                              ),
                            ]),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
    if (picked != null && picked.code != _lang.code && mounted) {
      _audio.playEventSound('PopButton');
      _openLanguage(picked);
    }
  }

  // ── build ────────────────────────────────────────────────────────────────

  double _scale(BuildContext c) {
    final size = MediaQuery.sizeOf(c);
    final w = min(size.width, 600.0) - 28;
    // shrink a little on short screens so the board keeps room
    final hs = (size.height - 120) / 700;
    return min((w / 380), hs).clamp(0.78, 1.35).toDouble();
  }

  String _instruction(BuildContext c) {
    final name = (_lang.code == 'arabic' && adLang(c) == 'ar' && _letter.speak != null)
        ? _letter.speak!
        : (_lang.hasCase ? _char : _letter.name);
    final k = switch (_mode) { AdMode.trace => 'traceLetter', AdMode.practice => 'writeLetter', AdMode.free => 'drawLetter' };
    return adText(c, k).replaceAll('{L}', name);
  }

  String _subtitle(BuildContext c) => switch (_mode) {
        AdMode.trace => adText(c, _guides != null ? 'followDots' : 'followShape'),
        AdMode.practice => adText(c, 'practiceSub'),
        AdMode.free => adText(c, 'freeSub'),
      };

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 600.0) - 24;
    final s = _scale(context);
    final showAd = context.select<ExperienceManager, bool>((x) => x.adsEnabled) && _banner != null && _bannerLoaded;

    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(children: [
        const Positioned.fill(child: KidPageBackground(asset: '${adDir}it_page_bg.webp', wash: 0.03)),
        SafeArea(
          bottom: false,
          child: Center(
            child: SizedBox(
              width: w,
              child: LayoutBuilder(builder: (context, cons) {
                final bottomGap = 10 * s + (showAd ? 0 : pad.bottom);
                final caseH = _lang.hasCase ? 46 * s : 0.0;
                // every fixed row has an exact height, so the board gets the rest
                final fixed = 6 + 64 * s + 8 * s + 46 * s + 8 * s + 74 * s + 6 * s + 59 * s + caseH + 8 * s +
                    26 * s + 56 * s + 10 * s + 66 * s + bottomGap;
                final minBoard = min(w * 0.82, 420.0);
                final free = cons.maxHeight - fixed;
                final scroll = free < minBoard;
                final board = SizedBox(width: double.infinity, height: scroll ? minBoard : free, child: _boardArea(s));
                final column = Column(children: [
                  const SizedBox(height: 6),
                  SizedBox(height: 64 * s, child: AdHeader(s: s)),
                  SizedBox(height: 8 * s),
                  SizedBox(height: 46 * s, child: _topRow(s)),
                  SizedBox(height: 8 * s),
                  SizedBox(height: 74 * s, child: _instructionBubble(s)),
                  SizedBox(height: 6 * s),
                  SizedBox(height: 59 * s, child: _letterStrip(s)),
                  if (_lang.hasCase) ...[SizedBox(height: 6 * s), SizedBox(height: 40 * s, child: _caseToggle(s))],
                  SizedBox(height: 8 * s),
                  board,
                  SizedBox(height: 26 * s),
                  SizedBox(height: 56 * s, child: _toolbar(s)),
                  SizedBox(height: 10 * s),
                  SizedBox(height: 66 * s, child: Center(child: _bottomButtons(s))),
                  SizedBox(height: bottomGap),
                ]);
                return scroll
                    ? SingleChildScrollView(physics: const BouncingScrollPhysics(), child: column)
                    : column;
              }),
            ),
          ),
        ),
      ]),
      bottomNavigationBar: showAd
          ? SafeArea(
              child: SizedBox(
                height: _banner!.size.height.toDouble(),
                width: _banner!.size.width.toDouble(),
                child: FamilyAdBanner(bannerAd: _banner, isLoaded: _bannerLoaded),
              ),
            )
          : null,
    );
  }

  Widget _topRow(double s) {
    Widget pill(Widget child, {VoidCallback? onTap}) => KidPressable(
          onTap: onTap,
          pressedScale: onTap == null ? 1 : 0.95,
          child: Container(
            height: 46 * s,
            padding: EdgeInsets.symmetric(horizontal: 16 * s),
            decoration: adPillDecoration(30 * s),
            alignment: Alignment.center,
            child: child,
          ),
        );
    return Row(children: [
      Expanded(
        child: pill(
          onTap: _pickLanguage,
          Row(children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(_lang.native, style: kidTitleStyle(22 * s, color: adInk).copyWith(shadows: const [])),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: adInk, size: 28 * s),
          ]),
        ),
      ),
      SizedBox(width: 10 * s),
      Expanded(
        child: pill(
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${_i + 1} / ${_lang.letters.length}',
                textDirection: TextDirection.ltr, style: kidTitleStyle(22 * s, color: adInk).copyWith(shadows: const [])),
          ),
        ),
      ),
    ]);
  }

  Widget _instructionBubble(double s) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 8 * s),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: AdBubble(
            key: ValueKey('$_char$_mode'),
            tail: AdTail.bottomLeft,
            sparks: true,
            padding: EdgeInsets.fromLTRB(34 * s, 4 * s, 34 * s, 4 * s),
            child: SizedBox(
              width: double.infinity,
              child: Column(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.center, children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_instruction(context),
                      maxLines: 1, style: kidTitleStyle(26 * s, color: adInk).copyWith(shadows: const [], height: 1.15)),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_subtitle(context), maxLines: 1, style: kidBodyStyle(13.5 * s, color: adInk, weight: FontWeight.w600)),
                ),
              ]),
            ),
          ),
        ),
      );

  Widget _letterStrip(double s) {
    final tile = 64.0 * s;
    return SizedBox(
      height: tile * 0.92,
      child: Directionality(
        textDirection: _lang.rtl ? TextDirection.rtl : TextDirection.ltr,
        child: ListView.separated(
          controller: _strip,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _lang.letters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final l = _lang.letters[i];
            final sel = i == _i;
            final shown = _lower && _lang.hasCase ? l.char.toLowerCase() : l.char;
            final done = _done.contains(shown);
            return KidPressable(
              onTap: () => _goTo(i, lower: _lower),
              pressedScale: 0.9,
              child: SizedBox(
                width: tile,
                child: Stack(alignment: Alignment.center, children: [
                  Positioned.fill(
                    child: Image.asset('$adDir${sel ? 'ad_tile_sel' : 'ad_tile_blank'}.webp', fit: BoxFit.fill),
                  ),
                  Padding(
                    padding: EdgeInsets.all(tile * 0.16),
                    child: FittedBox(
                      child: Text(shown, style: kidTitleStyle(34 * s, color: adInk).copyWith(shadows: const [], height: 1.1)),
                    ),
                  ),
                  if (done)
                    PositionedDirectional(
                      top: tile * 0.04,
                      end: tile * 0.06,
                      child: Icon(Icons.star_rounded, color: const Color(0xFFFFB800), size: tile * 0.28, shadows: const [
                        Shadow(color: Colors.white, blurRadius: 3),
                      ]),
                    ),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _caseToggle(double s) {
    Widget chip(bool lower) {
      final sel = _lower == lower;
      final sample = lower ? _letter.char.toLowerCase() : _letter.char;
      return KidPressable(
        onTap: () => _goTo(_i, lower: lower),
        pressedScale: 0.94,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40 * s,
          padding: EdgeInsets.symmetric(horizontal: 16 * s),
          decoration: adPillDecoration(30 * s,
              selected: sel, fill: sel ? const Color(0xFFE3F7FF) : adCream, border: sel ? adCyan : adLavender),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(sample, style: kidTitleStyle(22 * s, color: adInk).copyWith(shadows: const [])),
            SizedBox(width: 8 * s),
            Text(adText(context, lower ? 'lower' : 'upper'), style: kidBodyStyle(15 * s, color: adInk, weight: FontWeight.w700)),
          ]),
        ),
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [chip(false), SizedBox(width: 12 * s), chip(true)]);
  }

  // ── board ────────────────────────────────────────────────────────────────

  Widget _boardArea(double s) => LayoutBuilder(builder: (context, c) {
        final bw = c.maxWidth, bh = c.maxHeight;
        final frame = 9 * s;
        final innerW = bw - frame * 2, innerH = bh - frame * 2;
        final side = min(innerW, innerH) * 0.84;
        final box = _Box(Offset(frame + (innerW - side) / 2, frame + (innerH - side) / 2 - 4 * s), side);
        final word = _letter.word != null && _letter.word != _letter.char;
        final cardFits = word && (innerW - side) / 2 >= innerW * 0.2;
        final robotH = min(150 * s, bh * 0.42);

        return Stack(clipBehavior: Clip.none, fit: StackFit.expand, children: [
          // frame
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30 * s),
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE2D2FF), Color(0xFFB993FF), Color(0xFFD7C3FF)]),
                border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
                boxShadow: [
                  BoxShadow(color: adPurple.withOpacity(0.35), blurRadius: 18),
                  BoxShadow(color: const Color(0xFF4B2A9A).withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 6)),
                ],
              ),
              padding: EdgeInsets.all(frame),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF8),
                  borderRadius: BorderRadius.circular(22 * s),
                  boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4, spreadRadius: -1)],
                ),
              ),
            ),
          ),
          // letter + drawing
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26 * s),
              child: RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                gestures: {
                  EagerGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                    (_) {},
                  ),
                },
                child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) {
                  if (_pointer != null) return;
                  _pointer = e.pointer;
                  _penDown(box.toBox(e.localPosition));
                },
                onPointerMove: (e) {
                  if (e.pointer == _pointer) _penMove(box.toBox(e.localPosition));
                },
                onPointerUp: (e) {
                  if (e.pointer == _pointer) _pointer = null;
                },
                onPointerCancel: (e) {
                  if (e.pointer == _pointer) _pointer = null;
                },
                child: AnimatedBuilder(
                  animation: Listenable.merge([_demo, _bump]),
                  builder: (_, __) => CustomPaint(
                    size: Size(bw, bh),
                    painter: _BoardPainter(
                      box: box,
                      char: _char,
                      guides: _guides,
                      mode: _mode,
                      strokes: _strokes,
                      strokeInk: _strokeInk,
                      demo: _demo.value,
                      demoOn: _demo.value > 0,
                      bump: _bump.value,
                      inner: Rect.fromLTWH(frame, frame, innerW, innerH),
                      repaintKey: _strokes.fold<int>(0, (a, l) => a + l.length),
                    ),
                  ),
                ),
                ),
              ),
            ),
          ),
          // pencil during the demo (always a positioned, non-hit-testable layer
          // so it can never change the board's size or swallow touches)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _demo,
                builder: (_, __) {
                  final g = _guides;
                  if (g == null || !(_demo.value > 0 && _demo.value < 1)) return const SizedBox.expand();
                  final p = box.toScreen(_demoPoint(g, _demo.value));
                  final ph = 70 * s, pw = ph * 0.734;
                  return Stack(clipBehavior: Clip.none, children: [
                    Positioned(
                      left: p.dx - pw * 0.06,
                      top: p.dy - ph * 0.96,
                      child: Image.asset('${adDir}ad_pencil.webp', width: pw, height: ph),
                    ),
                  ]);
                },
              ),
            ),
          ),
          // word card
          if (cardFits)
            PositionedDirectional(
              top: frame + 8 * s,
              end: frame + 8 * s,
              width: min(innerW * 0.3, 150 * s),
              child: _wordCard(s),
            ),
          // name pill on the bottom edge
          Positioned(
            left: 0,
            right: 0,
            bottom: -18 * s,
            child: Center(child: _namePill(s, withWord: word && !cardFits)),
          ),
          // robot
          PositionedDirectional(
            start: -18 * s,
            bottom: -6 * s,
            height: robotH,
            child: IgnorePointer(child: _robot(s, robotH)),
          ),
          // result
          if (_stars != null)
            Positioned(
              left: 0,
              right: 0,
              top: frame + 10 * s,
              child: Center(child: _resultBadge(s)),
            ),
        ]);
      });

  Offset _demoPoint(List<List<Offset>> g, double t) {
    final total = g.fold<double>(0, (a, s) => a + _length(s));
    var left = total * t;
    for (final s in g) {
      final l = _length(s);
      if (left <= l) return _pointAt(s, left);
      left -= l;
    }
    return g.last.last;
  }

  Widget _wordCard(double s) {
    final l = _letter;
    final latin = _lang.code == 'french' || _lang.code == 'english';
    final head = latin ? _char : l.char;
    final connector = _lang.code == 'french' ? ' comme ' : _lang.code == 'english' ? ' is for ' : '  ';
    return KidPressable(
      onTap: () {
        _audio.playEventSound('clickButton2');
        _speak();
      },
      pressedScale: 0.95,
      child: Container(
        padding: EdgeInsets.fromLTRB(8 * s, 6 * s, 8 * s, 6 * s),
        decoration: adPillDecoration(18 * s, border: const Color(0xFFE6DCF8)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            SizedBox(height: 54 * s, child: Center(child: adWordPicture(l.emoji ?? '⭐', 54 * s))),
            PositionedDirectional(
              top: -2 * s,
              end: -4 * s,
              child: adRoundBtn(26 * s, Icons.volume_up_rounded, () {
                _audio.playEventSound('clickButton2');
                _speak();
              }),
            ),
          ]),
          SizedBox(height: 3 * s),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: head, style: kidTitleStyle(18 * s, color: const Color(0xFFE5243B)).copyWith(shadows: const [])),
                TextSpan(text: connector, style: kidBodyStyle(13 * s, color: adInk, weight: FontWeight.w600)),
                TextSpan(text: l.word, style: kidBodyStyle(15 * s, color: adInk, weight: FontWeight.w700)),
              ]),
              maxLines: 1,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _namePill(double s, {required bool withWord}) {
    final l = _letter;
    final label = _lang.hasCase ? _char : l.name;
    return KidPressable(
      onTap: () {
        _audio.playEventSound('clickButton2');
        _speak();
      },
      pressedScale: 0.95,
      child: Container(
        height: 42 * s,
        padding: EdgeInsetsDirectional.fromSTEB(4 * s, 3 * s, 18 * s, 3 * s),
        decoration: adPillDecoration(30 * s),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          adRoundBtn(34 * s, Icons.volume_up_rounded, () {
            _audio.playEventSound('clickButton2');
            _speak();
          }),
          SizedBox(width: 10 * s),
          Text(label, style: kidTitleStyle(21 * s, color: adInk).copyWith(shadows: const [])),
          if (withWord) ...[
            SizedBox(width: 8 * s),
            if (l.emoji != null) SizedBox(height: 28 * s, child: adWordPicture(l.emoji!, 28 * s)),
            SizedBox(width: 4 * s),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 120 * s),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(l.word!, style: kidBodyStyle(16 * s, color: adInk, weight: FontWeight.w700)),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _robot(double s, double h) {
    final msg = adText(context, _robotKey);
    return AnimatedBuilder(
      animation: Listenable.merge([_idle, _bump]),
      builder: (_, child) {
        final hop = sin(_bump.value * pi) * -10 * s;
        final bob = sin(_idle.value * 2 * pi) * 3 * s;
        return Transform.translate(offset: Offset(0, hop + bob), child: child);
      },
      child: SizedBox(
        width: h * 1.25,
        child: Stack(clipBehavior: Clip.none, children: [
          PositionedDirectional(
            start: 0,
            bottom: 0,
            height: h * 0.72,
            child: Transform.flip(
              flipX: Directionality.of(context) == TextDirection.rtl,
              child: Image.asset('${adDir}ad_robot_point.webp', fit: BoxFit.contain),
            ),
          ),
          PositionedDirectional(
            start: 0,
            top: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: h * 1.1),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: AdBubble(
                  key: ValueKey(msg),
                  tail: AdTail.bottomLeft,
                  sparks: true,
                  padding: EdgeInsets.fromLTRB(20 * s, 6 * s, 20 * s, 6 * s),
                  child: Text(msg,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: kidTitleStyle(14.5 * s, color: adInk).copyWith(shadows: const [], height: 1.1)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _resultBadge(double s) {
    final stars = _stars ?? 0;
    return ScaleTransition(
      scale: CurvedAnimation(parent: _pop, curve: Curves.elasticOut),
      child: IgnorePointer(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 6 * s),
          decoration: adPillDecoration(30 * s, selected: stars == 3),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (int k = 0; k < 3; k++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 2 * s),
                child: Image.asset(
                  '$adDir${k < stars ? 'games_star_on' : 'games_star_off'}.webp',
                  width: (k == 1 ? 38 : 30) * s,
                  height: (k == 1 ? 38 : 30) * s,
                ),
              ),
          ]),
        ),
      ),
    );
  }

  // ── toolbar & bottom ─────────────────────────────────────────────────────

  Widget _toolbar(double s) {
    Widget tool(IconData icon, String key, VoidCallback onTap, {bool flip = false}) => Expanded(
          child: KidPressable(
            onTap: onTap,
            pressedScale: 0.92,
            child: Container(
              height: 44 * s,
              padding: EdgeInsets.symmetric(horizontal: 6 * s),
              decoration: adPillDecoration(16 * s, border: const Color(0xFFEDE3FB)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Transform.flip(
                  flipX: flip && Directionality.of(context) == TextDirection.rtl,
                  child: Icon(icon, color: adInk, size: 22 * s),
                ),
                SizedBox(width: 4 * s),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(adText(context, key), maxLines: 1, style: kidBodyStyle(14 * s, color: adInk, weight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ),
        );

    return Container(
      padding: EdgeInsets.all(6 * s),
      decoration: adPillDecoration(24 * s, border: const Color(0xFFF1E3C8)),
      child: Row(children: [
        tool(Icons.undo_rounded, 'undo', _undo, flip: true),
        SizedBox(width: 5 * s),
        tool(Icons.delete_outline_rounded, 'clear', _clear),
        SizedBox(width: 5 * s),
        tool(Icons.replay_rounded, 'replay', _playDemo, flip: true),
        Container(width: 1.5, height: 30 * s, margin: EdgeInsets.symmetric(horizontal: 7 * s), color: const Color(0xFFE6DCF8)),
        for (int k = 0; k < _inks.length; k++)
          KidPressable(
            onTap: () {
              _audio.playEventSound('toggleButton');
              setState(() => _ink = k);
            },
            pressedScale: 0.85,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38 * s,
              height: 38 * s,
              margin: EdgeInsets.symmetric(horizontal: 1.5 * s),
              padding: EdgeInsets.all(_ink == k ? 0 : 4 * s),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: _ink == k ? [BoxShadow(color: _inks[k].withOpacity(0.55), blurRadius: 9, spreadRadius: 1)] : const [],
              ),
              child: Image.asset('$adDir${_inkSprites[k]}.webp', fit: BoxFit.contain),
            ),
          ),
      ]),
    );
  }

  Widget _bottomButtons(double s) {
    final hasInk = _strokes.isNotEmpty;
    final passed = (_stars ?? 0) > 0;
    return Row(children: [
      SizedBox(width: 50 * s),
      Expanded(
        child: AdYellowButton(
          s: s,
          height: 64,
          label: adText(context, _mode == AdMode.free ? 'done' : 'check'),
          leading: adCheckBadge(44 * s),
          onTap: hasInk ? _check : null,
        ),
      ),
      SizedBox(width: 10 * s),
      AnimatedScale(
        scale: passed ? 1.12 : 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: adRoundBtn(54 * s, Icons.arrow_forward_rounded, () {
          _audio.playEventSound('clickButton');
          _next();
        }, flipRtl: true, context: context),
      ),
    ]);
  }
}

Offset _pointAt(List<Offset> l, double dist) {
  if (l.length < 2) return l.first;
  var left = dist;
  for (int i = 1; i < l.length; i++) {
    final d = (l[i] - l[i - 1]).distance;
    if (left <= d) return Offset.lerp(l[i - 1], l[i], d == 0 ? 0 : left / d)!;
    left -= d;
  }
  return l.last;
}

class _BoardPainter extends CustomPainter {
  final _Box box;
  final String char;
  final List<List<Offset>>? guides;
  final AdMode mode;
  final List<List<Offset>> strokes;
  final List<int> strokeInk;
  final double demo;
  final bool demoOn;
  final double bump;
  final Rect inner;
  final int repaintKey;

  _BoardPainter({
    required this.box,
    required this.char,
    required this.guides,
    required this.mode,
    required this.strokes,
    required this.strokeInk,
    required this.demo,
    required this.demoOn,
    required this.bump,
    required this.inner,
    required this.repaintKey,
  });

  Path _path(List<Offset> pts) {
    final p = Path();
    if (pts.isEmpty) return p;
    final a = box.toScreen(pts.first);
    p.moveTo(a.dx, a.dy);
    if (pts.length == 1) {
      p.lineTo(a.dx + 0.01, a.dy);
    }
    for (int i = 1; i < pts.length; i++) {
      final b = box.toScreen(pts[i]);
      p.lineTo(b.dx, b.dy);
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = box.k;

    // writing lines
    final line = Paint()
      ..color = const Color(0xFFD9CBF7)
      ..strokeWidth = 1.6;
    for (final y in [45.0, 84.0]) {
      final yy = box.origin.dy + y * k;
      for (double x = inner.left + 14; x < inner.right - 14; x += 14) {
        canvas.drawLine(Offset(x, yy), Offset(min(x + 7, inner.right - 14), yy), line);
      }
    }

    final pulse = 1 + sin(bump * pi) * 0.04;
    canvas.save();
    final c = box.toScreen(const Offset(50, 50));
    canvas.translate(c.dx, c.dy);
    canvas.scale(pulse);
    canvas.translate(-c.dx, -c.dy);

    // ghost letter
    if (mode != AdMode.free) {
      final opacity = mode == AdMode.practice ? 0.7 : 1.0;
      final g = guides;
      if (g != null) {
        for (final s in g) {
          final p = _path(s);
          canvas.drawPath(
              p,
              Paint()
                ..color = _ghostEdge.withOpacity(opacity)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 19 * k
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round);
          canvas.drawPath(
              p,
              Paint()
                ..color = _ghost.withOpacity(opacity)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 15.5 * k
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round);
          canvas.drawPath(
              p,
              Paint()
                ..color = Colors.white.withOpacity(0.55 * opacity)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 4 * k
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round);
        }
      } else {
        canvas.save();
        canvas.translate(box.origin.dx, box.origin.dy);
        canvas.scale(k);
        final edge = TextPainter(
          text: TextSpan(
              text: char,
              style: TextStyle(
                  fontSize: 78,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 2.6
                    ..strokeJoin = StrokeJoin.round
                    ..color = _ghostEdge.withOpacity(opacity))),
          textDirection: TextDirection.ltr,
        )..layout();
        final tp = _glyph(char, _ghost.withOpacity(opacity));
        tp.paint(canvas, _glyphOffset(tp));
        edge.paint(canvas, _glyphOffset(edge));
        canvas.restore();
      }

      // stroke-order guides
      if (mode == AdMode.trace && g != null) {
        final dash = Paint()
          ..color = _guide
          ..strokeWidth = max(2.6, 3.0 * k)
          ..strokeCap = StrokeCap.round;
        for (final s in g) {
          final pts = _resample(s, 1).map(box.toScreen).toList();
          if (pts.length < 2) continue;
          // dashes
          var acc = 0.0;
          const on = 4.5, gap = 3.5;
          for (int i = 1; i < pts.length; i++) {
            final seg = (pts[i] - pts[i - 1]).distance;
            final phase = (acc % ((on + gap) * k));
            if (phase < on * k) canvas.drawLine(pts[i - 1], pts[i], dash);
            acc += seg;
          }
          // arrow head
          final end = pts.last;
          final before = pts[max(0, pts.length - 1 - (6 * k).round().clamp(2, 40))];
          final dir = end - before;
          if (dir.distance > 0.5) {
            final u = dir / dir.distance;
            final n = Offset(-u.dy, u.dx);
            final a = 5.5 * k;
            final head = Path()
              ..moveTo(end.dx + u.dx * a * 0.4, end.dy + u.dy * a * 0.4)
              ..lineTo(end.dx - u.dx * a + n.dx * a * 0.75, end.dy - u.dy * a + n.dy * a * 0.75)
              ..lineTo(end.dx - u.dx * a - n.dx * a * 0.75, end.dy - u.dy * a - n.dy * a * 0.75)
              ..close();
            canvas.drawPath(head, Paint()..color = _guide);
          }
        }
        // numbered start dots
        for (int i = 0; i < g.length; i++) {
          final p = box.toScreen(g[i].first);
          final r = max(10.0, 6.2 * k);
          canvas.drawCircle(p + const Offset(0, 1.5), r, Paint()..color = const Color(0xFF0E7A34));
          canvas.drawCircle(
              p,
              r,
              Paint()
                ..shader = const RadialGradient(center: Alignment(-0.3, -0.4), colors: [Color(0xFF5FE07F), Color(0xFF17A34A)])
                    .createShader(Rect.fromCircle(center: p, radius: r)));
          canvas.drawCircle(
              p,
              r,
              Paint()
                ..color = Colors.white
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.8);
          final tp = TextPainter(
            text: TextSpan(
                text: '${i + 1}',
                style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: r * 1.15, color: Colors.white, height: 1)),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
        }
      }
    }

    // demo stroke (cyan glossy line that grows)
    final g = guides;
    if (demoOn && g != null) {
      final total = g.fold<double>(0, (a, s) => a + _length(s));
      var left = total * demo;
      for (final s in g) {
        if (left <= 0) break;
        final l = _length(s);
        final part = <Offset>[s.first];
        var rem = min(left, l);
        for (int i = 1; i < s.length && rem > 0; i++) {
          final d = (s[i] - s[i - 1]).distance;
          if (rem >= d) {
            part.add(s[i]);
            rem -= d;
          } else {
            part.add(Offset.lerp(s[i - 1], s[i], rem / d)!);
            rem = 0;
          }
        }
        left -= l;
        final path = _path(part);
        if (demo < 1) {
          _ink(canvas, path, const Color(0xFF34C6F2), k);
        } else {
          // finished: leave a clear cyan track to trace over
          canvas.drawPath(
              path,
              Paint()
                ..color = const Color(0xFF34C6F2).withOpacity(0.30)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 14 * k
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round);
          canvas.drawPath(
              path,
              Paint()
                ..color = const Color(0xFF1FA9DB).withOpacity(0.75)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3 * k
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round);
        }
      }
    }
    canvas.restore();

    // child's strokes
    for (int i = 0; i < strokes.length; i++) {
      _ink(canvas, _path(strokes[i]), _inks[strokeInk[i] % _inks.length], k);
    }
  }

  void _ink(Canvas canvas, Path p, Color color, double k) {
    final w = 7.5 * k;
    canvas.drawPath(
        p,
        Paint()
          ..color = Color.lerp(color, Colors.black, 0.25)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = w + 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    canvas.drawPath(
        p,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    canvas.save();
    canvas.translate(-w * 0.14, -w * 0.18);
    canvas.drawPath(
        p,
        Paint()
          ..color = Colors.white.withOpacity(0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.28
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BoardPainter o) =>
      o.repaintKey != repaintKey ||
      o.strokes.length != strokes.length ||
      o.char != char ||
      o.mode != mode ||
      o.demo != demo ||
      o.bump != bump ||
      o.box.side != box.side ||
      o.box.origin != box.origin ||
      !identical(o.strokeInk, strokeInk);
}
