import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_page_parts.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

import 'alpha_draw_data.dart';
import 'alpha_draw_page.dart';
import 'alpha_draw_ui.dart';

/// Tile + glyph sprite for each language (grid order = mock-up order).
const Map<String, String> _tileKey = {
  'arabic': 'ar', 'french': 'fr', 'english': 'en',
  'amazigh': 'zgh', 'russian': 'ru', 'japanese': 'ja',
  'greek': 'el', 'chinese': 'zh', 'korean': 'ko',
};
const List<String> _gridOrder = [
  'arabic', 'french', 'english', 'amazigh', 'russian', 'japanese', 'greek', 'chinese', 'korean',
];

/// Glyph sprite aspect (height / width) so it can be sized by height.
const Map<String, double> _glyphAspect = {
  'ar': 2.6571, 'fr': 0.6667, 'en': 0.7143, 'zgh': 1.1892, 'ru': 1.1867,
  'ja': 0.978, 'el': 0.9149, 'zh': 0.8571, 'ko': 0.9474,
};

/// Path of the dotted "A" in ad_dotsA.webp (fractions of the image).
const List<List<Offset>> _dotsAPath = [
  [Offset(0.071, 0.915), Offset(0.498, 0.074), Offset(0.924, 0.919)],
  [Offset(0.30, 0.676), Offset(0.70, 0.676)],
];

/// Alpha Draw home: pick a language and a mode, then start writing.
class AlphaDrawMenuPage extends StatefulWidget {
  const AlphaDrawMenuPage({super.key});
  @override
  State<AlphaDrawMenuPage> createState() => _AlphaDrawMenuPageState();
}

class _AlphaDrawMenuPageState extends State<AlphaDrawMenuPage> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  // plays the little drawing inside the selected mode card
  late final AnimationController _modeAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  String _selected = 'french';
  AdMode _mode = AdMode.trace;
  Map<String, int> _done = {};
  bool _started = false;
  int _tapWiggle = 0;
  String? _wiggleCode;
  bool _hint = false;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _modeAnim.repeat();
    _armHint();
  }

  Future<void> _load() async {
    final last = await AdStore.lastLanguage();
    final mode = await AdStore.lastMode();
    final done = await AdStore.doneCounts();
    if (!mounted) return;
    final locale = Localizations.localeOf(context).languageCode;
    setState(() {
      _selected = last ?? (locale == 'ar' ? 'arabic' : locale == 'en' ? 'english' : 'french');
      if (!_unlocked(adLanguage(_selected))) _selected = 'french';
      _mode = mode;
      _done = done;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      KidAssets.precache(context, [
        '${adDir}it_page_bg.webp',
        '${adMenuDir}ad_robot_pen.webp', '${adMenuDir}ad_book.webp', '${adMenuDir}ad_bubble.webp',
        '${adMenuDir}ad_title_pill.webp', '${adMenuDir}ad_tray.webp', '${adMenuDir}ad_btn_yellow.webp',
        for (final k in _tileKey.values) ...['${adMenuDir}ad_tile_$k.webp', '${adMenuDir}ad_glyph_$k.webp'],
        for (var i = 1; i <= 6; i++) '${adMenuDir}ad_mtile$i.webp',
        '${adMenuDir}ad_pencil_big.webp', '${adMenuDir}ad_brush.webp',
      ]);
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _intro.dispose();
    _idle.dispose();
    _modeAnim.dispose();
    super.dispose();
  }

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);
  ExperienceManager get _xp => Provider.of<ExperienceManager>(context, listen: false);

  bool _unlocked(AdLanguage l) => l.cost == 0 || _xp.isLanguageUnlocked(l.code);

  /// After a few quiet seconds, a little hand shows the "Let's go" button.
  void _armHint() {
    _hintTimer?.cancel();
    if (_hint) setState(() => _hint = false);
    _hintTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => _hint = true);
    });
  }

  Future<void> _tapLanguage(AdLanguage l) async {
    _armHint();
    if (!_unlocked(l)) {
      _audio.playEventSound('clickButton2');
      final ok = await _askUnlock(l);
      if (ok != true || !mounted) return;
      if (!_xp.unlockLanguage(l.code, l.cost)) return;
      try {
        await _audio.playSfx('assets/audios/sound_effects/unlock_sound.mp3');
      } catch (_) {}
    } else {
      _audio.playEventSound('PopButton');
    }
    setState(() {
      _selected = l.code;
      _wiggleCode = l.code;
      _tapWiggle++;
    });
    AdStore.setLastLanguage(l.code);
  }

  void _tapMode(AdMode m) {
    _armHint();
    _audio.playEventSound('toggleButton');
    setState(() => _mode = m);
    AdStore.setLastMode(m);
    _modeAnim
      ..value = 0
      ..repeat();
  }

  Future<bool?> _askUnlock(AdLanguage l) {
    final enough = _xp.gold >= l.cost;
    final name = l.names[adLang(context)] ?? l.native;
    return showDialog<bool>(
      context: context,
      barrierColor: KidColors.purpleDeep.withOpacity(0.35),
      builder: (ctx) => KidDialog(
        title: adText(ctx, 'unlockTitle').replaceAll('{N}', name),
        message: adText(ctx, enough ? 'unlockMsg' : 'notEnough').replaceAll('{C}', '${l.cost}'),
        content: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 80, height: 66, child: _tileFace(1, l, showLabel: false)),
          const SizedBox(width: 14),
          Image.asset(kidCoinAsset, width: 34, height: 34),
          Text(' ${l.cost}', style: kidTitleStyle(26, color: adInk).copyWith(shadows: const [])),
        ]),
        actions: [
          if (enough)
            KidButton(label: adText(ctx, 'unlock'), onPressed: () => Navigator.pop(ctx, true), width: 220, height: 56, showArrow: false),
          KidOutlineButton(label: adText(ctx, enough ? 'later' : 'ok'), onTap: () => Navigator.pop(ctx, false)),
        ],
      ),
    );
  }

  Future<void> _start() async {
    _hintTimer?.cancel();
    final l = adLanguage(_selected);
    if (!_unlocked(l)) return _tapLanguage(l);
    _audio.playEventSound('PopButton');
    AdStore.setLastLanguage(l.code);
    AdStore.setLastMode(_mode);
    setState(() => _hint = false);
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => AlphaDrawPage(language: l.code, mode: _mode),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
    final done = await AdStore.doneCounts();
    if (mounted) setState(() => _done = done);
    _armHint();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final usableH = size.height - pad.top - pad.bottom;
    // the grid grows with the width, so the width is also limited by the height
    final w = min(min(size.width - 24, 520.0), usableH / 2.3);
    final s = (w / 376).clamp(0.6, 1.4).toDouble();
    Widget step(int i, Widget c) => KidIntro(intro: _intro, from: 0.06 * i, to: min(1.0, 0.45 + 0.06 * i), rise: 24, child: c);
    context.watch<ExperienceManager>(); // unlocks / gold

    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(children: [
        const Positioned.fill(child: KidPageBackground(asset: '${adDir}it_page_bg.webp', wash: 0.03)),
        SafeArea(
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                SizedBox(height: 6 * s),
                step(0, _header(s)),
                Expanded(child: step(1, _hero(s))),
                step(2, _lettersPanel(s, w)),
                SizedBox(height: 10 * s),
                step(4, _modeTray(s, w)),
                SizedBox(height: 4 * s),
                step(5, _starsRow(s)),
                SizedBox(height: 4 * s),
                step(6, _goButton(s, w)),
                SizedBox(height: 10 * s),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── header ───────────────────────────────────────────────────────────────

  Widget _header(double s) {
    final h = 62 * s;
    return SizedBox(
      height: h,
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(child: Image.asset('${adMenuDir}ad_title_pill.webp', fit: BoxFit.fill)),
        Row(children: [
          SizedBox(width: 6 * s),
          _spriteBtn(s, '${adMenuDir}ad_btn_back.webp', h - 12 * s, () {
            _audio.playEventSound('cancelButton');
            Navigator.of(context).maybePop();
          }, flipRtl: true),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Alpha Draw', style: kidTitleStyle(30 * s, color: adInk).copyWith(shadows: const [])),
            ),
          ),
          Consumer<AudioManager>(
            builder: (_, a, __) => Stack(alignment: Alignment.center, children: [
              Opacity(
                opacity: a.isBgMuted ? 0.55 : 1,
                child: _spriteBtn(s, '${adMenuDir}ad_btn_sound.webp', h - 12 * s, () {
                  a.playEventSound('toggleButton');
                  a.toggleBgMute();
                }),
              ),
              if (a.isBgMuted)
                IgnorePointer(child: Icon(Icons.block_rounded, color: const Color(0xFFFF4D6D), size: (h - 12 * s) * 0.9)),
            ]),
          ),
          SizedBox(width: 6 * s),
        ]),
      ]),
    );
  }

  Widget _spriteBtn(double s, String asset, double size, VoidCallback onTap, {bool flipRtl = false}) {
    final flip = flipRtl && Directionality.of(context) == TextDirection.rtl;
    return KidPressable(
      onTap: onTap,
      child: Transform.flip(flipX: flip, child: Image.asset(asset, width: size, height: size)),
    );
  }

  // ── hero: robot + bubble + floating letters ──────────────────────────────

  Widget _hero(double s) => LayoutBuilder(builder: (_, c) {
        final w = c.maxWidth, h = c.maxHeight;
        if (h < 60) return const SizedBox.shrink();
        final k = min(s, h / 190 * s).toDouble();
        return AnimatedBuilder(
          animation: _idle,
          builder: (_, __) {
            final t = _idle.value;
            double wave(double speed, double phase) => sin((t * speed + phase) * 2 * pi);
            Widget floatTile(String key, double size, double phase) => Transform.translate(
                  offset: Offset(0, wave(2, phase) * 6 * k),
                  child: Transform.rotate(
                    angle: wave(1, phase) * 0.12,
                    child: SizedBox(
                      width: size,
                      height: size * 0.82,
                      child: Stack(alignment: Alignment.center, children: [
                        Positioned.fill(child: Image.asset('${adMenuDir}ad_tile_$key.webp', fit: BoxFit.fill)),
                        _glyph(key, size * 0.5),
                      ]),
                    ),
                  ),
                );
            final robotH = min(h * 0.98, 190 * k);
            return Stack(clipBehavior: Clip.none, children: [
              // floating letter tiles
              PositionedDirectional(start: 0, top: h * 0.02, child: floatTile('ar', 62 * k, 0)),
              PositionedDirectional(start: 14 * k, top: h * 0.46, child: floatTile('fr', 58 * k, 0.4)),
              PositionedDirectional(end: 4 * k, bottom: h * 0.02, child: floatTile('ja', 60 * k, 0.7)),
              // twinkling stars
              for (var i = 0; i < 4; i++) _twinkle(w, h, k, i),
              // robot (sways and bobs)
              Positioned(
                left: w * 0.5 - robotH * 0.62,
                bottom: -6 * k + wave(1.5, 0).abs() * 4 * k,
                child: Transform.rotate(
                  angle: wave(1, 0.2) * 0.04,
                  alignment: Alignment.bottomCenter,
                  child: Image.asset('${adMenuDir}ad_robot_pen.webp', height: robotH),
                ),
              ),
              // speech bubble
              PositionedDirectional(
                end: 0,
                top: h * 0.04,
                child: Transform.scale(
                  scale: 1 + wave(2, 0.5) * 0.025,
                  child: SizedBox(
                    width: 150 * k,
                    height: 150 * k * 0.4295,
                    child: Stack(children: [
                      Positioned.fill(
                        child: Transform.flip(
                          flipX: Directionality.of(context) == TextDirection.rtl,
                          child: Image.asset('${adMenuDir}ad_bubble.webp', fit: BoxFit.fill),
                        ),
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(22 * k, 6 * k, 12 * k, 8 * k),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(adText(context, 'letsPlay'),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: kidTitleStyle(17 * k, color: adInk).copyWith(shadows: const [], height: 1.05)),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ]);
          },
        );
      });

  Widget _twinkle(double w, double h, double k, int i) {
    final r = Random(i * 13 + 5);
    final x = w * (0.18 + r.nextDouble() * 0.64), y = h * (0.05 + r.nextDouble() * 0.6);
    final o = sin(((_idle.value * 2 + i / 4) % 1.0) * pi);
    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: o.clamp(0.0, 1.0).toDouble(),
        child: Transform.scale(scale: 0.6 + o * 0.5, child: Image.asset('${adMenuDir}ad_star_on.webp', width: 18 * k)),
      ),
    );
  }

  Widget _glyph(String key, double height) {
    final a = _glyphAspect[key] ?? 1;
    // tall glyphs (Arabic ١) are limited by height, wide ones by width
    return Image.asset('${adMenuDir}ad_glyph_$key.webp', height: height, width: height / a, fit: BoxFit.contain);
  }

  // ── letters panel ────────────────────────────────────────────────────────

  Widget _lettersPanel(double s, double w) {
    final bookW = min(w * 0.82, 310 * s);
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        margin: EdgeInsets.only(top: bookW * 0.2708 * 0.55),
        padding: EdgeInsets.fromLTRB(12 * s, bookW * 0.2708 * 0.42, 12 * s, 10 * s),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8EC),
          borderRadius: BorderRadius.circular(30 * s),
          border: Border.all(color: const Color(0xFFA77BF0), width: 5 * s),
          boxShadow: [
            BoxShadow(color: const Color(0xFF8B5A2B).withOpacity(0.9), spreadRadius: 3 * s),
            BoxShadow(color: const Color(0xFF4B2A9A).withOpacity(0.28), blurRadius: 14 * s, offset: Offset(0, 6 * s)),
          ],
        ),
        child: Column(children: [
          _panelTitle(s),
          SizedBox(height: 8 * s),
          _grid(s),
        ]),
      ),
      // open book on top, with flowers on the corners
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Center(child: Image.asset('${adMenuDir}ad_book.webp', width: bookW)),
      ),
      PositionedDirectional(start: -10 * s, top: bookW * 0.2708 * 0.3, child: _flower(s, 'ad_flower1', 62, 0)),
      PositionedDirectional(end: -10 * s, top: bookW * 0.2708 * 0.3, child: _flower(s, 'ad_flower3', 54, 0.5)),
      PositionedDirectional(start: -14 * s, bottom: -10 * s, child: _flower(s, 'ad_flower2', 58, 0.25)),
    ]);
  }

  Widget _flower(double s, String name, double width, double phase) => AnimatedBuilder(
        animation: _idle,
        builder: (_, c) => Transform.rotate(angle: sin((_idle.value + phase) * 2 * pi) * 0.05, child: c),
        child: Image.asset('$adMenuDir$name.webp', width: width * s),
      );

  Widget _panelTitle(double s) {
    Widget dash(bool flip) => Transform.flip(
          flipX: flip,
          child: Transform.rotate(
            angle: -0.5,
            child: Container(
              width: 16 * s,
              height: 5 * s,
              decoration: BoxDecoration(color: adPurple, borderRadius: BorderRadius.circular(4 * s)),
            ),
          ),
        );
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      dash(false),
      SizedBox(width: 10 * s),
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(adText(context, 'pickLetters'), style: kidTitleStyle(25 * s, color: adInk).copyWith(shadows: const [])),
        ),
      ),
      SizedBox(width: 10 * s),
      dash(true),
    ]);
  }

  Widget _grid(double s) {
    final langs = [for (final c in _gridOrder) adLanguage(c)];
    return LayoutBuilder(builder: (_, c) {
      final gap = 8 * s;
      final tw = (c.maxWidth - gap * 2) / 3;
      final th = tw * 0.74;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final l in langs) SizedBox(width: tw, height: th, child: _langTile(s, l)),
      ]);
    });
  }

  Widget _langTile(double s, AdLanguage l) {
    final sel = l.code == _selected;
    final locked = !_unlocked(l);
    return KidPressable(
      onTap: () => _tapLanguage(l),
      pressedScale: 0.92,
      semanticLabel: l.names[adLang(context)] ?? l.native,
      child: AnimatedScale(
        scale: sel ? 1.05 : 1,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        child: Stack(clipBehavior: Clip.none, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18 * s),
              boxShadow: sel ? [BoxShadow(color: adCyan.withOpacity(0.75), blurRadius: 14 * s, spreadRadius: 2 * s)] : const [],
            ),
            child: locked
                ? ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      0.5, 0.4, 0.1, 0, 20, //
                      0.3, 0.6, 0.1, 0, 20,
                      0.3, 0.4, 0.3, 0, 20,
                      0, 0, 0, 0.85, 0,
                    ]),
                    child: _tileFace(s, l, selected: sel),
                  )
                : _tileFace(s, l, selected: sel),
          ),
          if (locked) Positioned(left: 0, right: 0, top: -6 * s, child: Center(child: _lockChip(s, l))),
          if (sel)
            PositionedDirectional(
              top: -12 * s,
              end: -10 * s,
              child: TweenAnimationBuilder<double>(
                key: ValueKey('badge_${l.code}'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.elasticOut,
                builder: (_, v, c) => Transform.scale(scale: v, child: c),
                child: Image.asset('${adMenuDir}ad_badge_star.webp', width: 34 * s),
              ),
            ),
        ]),
      ),
    );
  }

  /// Tile background + bouncing glyph + name.
  Widget _tileFace(double s, AdLanguage l, {bool selected = false, bool showLabel = true}) {
    final key = _tileKey[l.code] ?? 'fr';
    final name = l.names[adLang(context)] ?? l.native;
    final done = _done[l.code] ?? 0;
    return LayoutBuilder(builder: (_, c) {
      final h = c.maxHeight;
      final glyphH = h * (showLabel ? 0.5 : 0.62);
      Widget glyph = _glyph(key, glyphH);
      // the selected glyph keeps bouncing; a tapped one wiggles once
      glyph = AnimatedBuilder(
        animation: _idle,
        builder: (_, g) => Transform.translate(
          offset: Offset(0, selected ? -sin(_idle.value * 2 * pi * 4).abs() * h * 0.05 : 0),
          child: g,
        ),
        child: glyph,
      );
      if (_wiggleCode == l.code) {
        glyph = TweenAnimationBuilder<double>(
          key: ValueKey('wig_$_tapWiggle'),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          builder: (_, v, g) => Transform.rotate(angle: sin(v * pi * 4) * (1 - v) * 0.3, child: Transform.scale(scale: 1 + sin(v * pi) * 0.18, child: g)),
          child: glyph,
        );
      }
      return Stack(children: [
        Positioned.fill(child: Image.asset('${adMenuDir}ad_tile_$key.webp', fit: BoxFit.fill)),
        Positioned(
          left: 0,
          right: 0,
          top: h * (showLabel ? 0.1 : 0.19),
          height: glyphH,
          child: Center(child: glyph),
        ),
        if (showLabel)
          Positioned(
            left: 6 * s,
            right: 6 * s,
            bottom: h * 0.1,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(name, maxLines: 1, style: kidBodyStyle(14.5 * s, color: adInk, weight: FontWeight.w700)),
                if (done > 0)
                  Text(
                    adText(context, 'lettersDone')
                        .replaceAll('{D}', '$done')
                        .replaceAll('{T}', '${l.letters.length * (l.hasCase ? 2 : 1)}'),
                    maxLines: 1,
                    style: kidBodyStyle(10 * s, color: adGreen, weight: FontWeight.w700),
                  ),
              ]),
            ),
          ),
      ]);
    });
  }

  Widget _lockChip(double s, AdLanguage l) => Container(
        padding: EdgeInsets.symmetric(horizontal: 7 * s, vertical: 2 * s),
        decoration: BoxDecoration(
          color: adInk.withOpacity(0.88),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock_rounded, color: Colors.white, size: 13 * s),
          SizedBox(width: 2 * s),
          Image.asset(kidCoinAsset, width: 14 * s, height: 14 * s),
          Text('${l.cost}', style: kidBodyStyle(12 * s, color: Colors.white, weight: FontWeight.w700)),
        ]),
      );

  // ── mode tray ────────────────────────────────────────────────────────────

  Widget _modeTray(double s, double w) {
    return Container(
      padding: EdgeInsets.fromLTRB(10 * s, 10 * s, 10 * s, 10 * s),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(28 * s),
        border: Border.all(color: const Color(0xFFA77BF0), width: 4 * s),
        boxShadow: [BoxShadow(color: const Color(0xFF4B2A9A).withOpacity(0.22), blurRadius: 10 * s, offset: Offset(0, 5 * s))],
      ),
      child: Row(children: [
        Expanded(child: _modeCard(s, AdMode.trace, 1, adText(context, 'mTrace'))),
        SizedBox(width: 8 * s),
        Expanded(child: _modeCard(s, AdMode.practice, 3, adText(context, 'mTry'))),
        SizedBox(width: 8 * s),
        Expanded(child: _modeCard(s, AdMode.free, 5, adText(context, 'mDoodle'))),
      ]),
    );
  }

  /// [tile] = sprite number of the normal tile; +1 is the glowing selected one.
  Widget _modeCard(double s, AdMode m, int tile, String label) {
    final sel = m == _mode;
    return KidPressable(
      onTap: () => _tapMode(m),
      pressedScale: 0.92,
      semanticLabel: label,
      child: AspectRatio(
        aspectRatio: 1.3,
        child: AnimatedScale(
          scale: sel ? 1.04 : 0.97,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Image.asset('${adMenuDir}ad_mtile${sel ? tile + 1 : tile}.webp',
                    key: ValueKey(sel), fit: BoxFit.fill),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(8 * s, 6 * s, 8 * s, 4 * s),
                child: Column(children: [
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_modeAnim, _idle]),
                        builder: (_, __) {
                          // selected: replay the drawing; others rest finished
                          final raw = sel ? _modeAnim.value : 1.0;
                          final t = Curves.easeInOut.transform((raw / 0.8).clamp(0.0, 1.0));
                          return LayoutBuilder(builder: (_, c) => _modeArt(m, c.biggest, t, sel));
                        },
                      ),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label,
                        maxLines: 1, style: kidBodyStyle(15 * s, color: sel ? const Color(0xFF0B6B8F) : adInk, weight: FontWeight.w700)),
                  ),
                ]),
              ),
            ),
            if (sel)
              PositionedDirectional(
                top: -10 * s,
                end: -8 * s,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('mbadge_$m'),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.elasticOut,
                  builder: (_, v, c) => Transform.scale(scale: v, child: c),
                  child: Image.asset('${adMenuDir}ad_badge_check.webp', width: 30 * s),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  /// The little animated drawing inside each mode card. [t] 0→1 = progress.
  Widget _modeArt(AdMode m, Size box, double t, bool sel) {
    final idle = sin(_idle.value * 2 * pi * 3);
    if (m == AdMode.trace) {
        {
          // dotted A, a cyan line follows the dots, pencil on the tip
          final side = min(box.width * 0.78, box.height);
          final rect = Rect.fromLTWH((box.width - side) / 2 - box.width * 0.06, (box.height - side) / 2, side, side * 0.9628);
          final tip = _pointOnPath(_dotsAPath, t);
          final tipPx = Offset(rect.left + tip.dx * rect.width, rect.top + tip.dy * rect.height);
          return Stack(clipBehavior: Clip.none, children: [
            Positioned.fromRect(rect: rect, child: Image.asset('${adMenuDir}ad_dotsA.webp', fit: BoxFit.fill)),
            Positioned.fill(child: CustomPaint(painter: _TrailPainter(_dotsAPath, t, rect, sel ? 1 : 0.55))),
            _tool('${adMenuDir}ad_pencil_big.webp', tipPx, box.height * 0.62, 0.859, const Offset(0.03, 0.98),
                lift: sel ? idle * 1.5 : 0),
          ]);
        }
    }
    if (m == AdMode.practice) {
        {
          // dashed line on top, the pencil writes the solid line below
          final lw = box.width * 0.9;
          final left = (box.width - lw) / 2;
          final y1 = box.height * 0.22, y2 = box.height * 0.62;
          final tipPx = Offset(left + lw * t, y2 + lw * 0.1548 * 0.5 + sin(t * pi * 2) * lw * 0.03);
          return Stack(clipBehavior: Clip.none, children: [
            Positioned(left: left, top: y1, width: lw, child: Image.asset('${adMenuDir}ad_dashes.webp', width: lw)),
            Positioned(
              left: left,
              top: y2,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: t.clamp(0.001, 1.0).toDouble(),
                  child: Image.asset('${adMenuDir}ad_line_dark.webp', width: lw),
                ),
              ),
            ),
            _tool('${adMenuDir}ad_pencil_big.webp', tipPx, box.height * 0.62, 0.859, const Offset(0.03, 0.98),
                lift: sel ? idle * 1.5 : 0),
          ]);
        }
    }
    {
        {
          // rainbow squiggle painted by the brush + sparkles
          final rw = box.width * 0.88;
          final left = (box.width - rw) / 2;
          final top = box.height * 0.3;
          final tipPx = Offset(left + rw * t, top + rw * 0.3697 * (0.5 + 0.3 * sin(t * pi * 3)));
          final sparkle = sel ? (0.5 + 0.5 * sin(_idle.value * 2 * pi * 4)) : 0.8;
          return Stack(clipBehavior: Clip.none, children: [
            Positioned(
              left: left,
              top: top,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: t.clamp(0.001, 1.0).toDouble(),
                  child: Image.asset('${adMenuDir}ad_rainbow1.webp', width: rw),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Opacity(
                opacity: sparkle,
                child: Transform.scale(
                  scale: 0.8 + sparkle * 0.3,
                  child: Image.asset('${adMenuDir}ad_sparkles.webp', width: box.width * 0.3),
                ),
              ),
            ),
            _tool('${adMenuDir}ad_brush.webp', tipPx, box.height * 0.42, 1 / 0.6223, const Offset(0.88, 0.98),
                lift: sel ? idle * 1.5 : 0),
          ]);
        }
    }
  }

  /// Places a sprite so that its tip ([tipFrac] of the image) sits on [tip].
  Widget _tool(String asset, Offset tip, double height, double aspectWH, Offset tipFrac, {double lift = 0}) {
    final w = height * aspectWH;
    return Positioned(
      left: tip.dx - w * tipFrac.dx,
      top: tip.dy - height * tipFrac.dy - lift,
      child: IgnorePointer(child: Image.asset(asset, width: w, height: height)),
    );
  }

  Offset _pointOnPath(List<List<Offset>> path, double t) {
    double len(List<Offset> s) {
      var l = 0.0;
      for (var i = 1; i < s.length; i++) l += (s[i] - s[i - 1]).distance;
      return l;
    }

    final total = path.fold<double>(0, (a, s) => a + len(s));
    var left = total * t;
    for (final s in path) {
      for (var i = 1; i < s.length; i++) {
        final d = (s[i] - s[i - 1]).distance;
        if (left <= d) return Offset.lerp(s[i - 1], s[i], d == 0 ? 0 : left / d)!;
        left -= d;
      }
    }
    return path.last.last;
  }

  // ── stars + button ───────────────────────────────────────────────────────

  Widget _starsRow(double s) {
    final l = adLanguage(_selected);
    final total = l.letters.length * (l.hasCase ? 2 : 1);
    final done = _done[l.code] ?? 0;
    final stars = total == 0 ? 0 : (done >= total ? 3 : (done * 3 / total).floor());
    return SizedBox(
      height: 40 * s,
      width: 190 * s,
      child: Stack(alignment: Alignment.center, children: [
        Image.asset('${adMenuDir}ad_wave.webp', width: 180 * s),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (var i = 0; i < 3; i++)
            AnimatedBuilder(
              animation: _idle,
              builder: (_, c) => Transform.scale(
                scale: i < stars ? 1 + 0.08 * sin((_idle.value * 3 + i * 0.3) * 2 * pi) : 1,
                child: c,
              ),
              child: Image.asset('${adMenuDir}${i < stars ? 'ad_star_on' : 'ad_star_off'}.webp', width: 40 * s),
            ),
        ]),
      ]),
    );
  }

  Widget _goButton(double s, double w) {
    final bw = min(w * 0.8, 300 * s);
    final bh = bw * 0.3333;
    return SizedBox(
      width: bw + 40 * s,
      height: bh + 10 * s,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        AnimatedBuilder(
          animation: _idle,
          builder: (_, c) => Transform.scale(scale: 1 + 0.025 * sin(_idle.value * 2 * pi * 4), child: c),
          child: KidPressable(
            onTap: _start,
            pressedScale: 0.94,
            semanticLabel: adText(context, 'letsGo'),
            child: SizedBox(
              width: bw,
              height: bh,
              child: Stack(alignment: Alignment.center, children: [
                Positioned.fill(child: Image.asset('${adMenuDir}ad_btn_yellow.webp', fit: BoxFit.fill)),
                Padding(
                  padding: EdgeInsets.only(bottom: 4 * s),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Transform.flip(
                      flipX: Directionality.of(context) == TextDirection.rtl,
                      child: Image.asset('${adMenuDir}ad_play.webp', height: bh * 0.56),
                    ),
                    SizedBox(width: 12 * s),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(adText(context, 'letsGo'), style: kidTitleStyle(32 * s, color: adInk).copyWith(shadows: const [])),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
        // helping hand after a few quiet seconds
        if (_hint)
          PositionedDirectional(
            end: 0,
            bottom: -bh * 0.2,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _idle,
                builder: (_, c) {
                  final p = (_idle.value * 6) % 1.0;
                  final press = p < 0.25 ? sin(p / 0.25 * pi) : 0.0;
                  return Transform.translate(offset: Offset(-press * 8 * s, -press * 10 * s), child: c);
                },
                child: Image.asset('${adMenuDir}ad_hand.webp', width: 52 * s),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Glowing cyan line drawn over the dotted "A" up to [t].
class _TrailPainter extends CustomPainter {
  final List<List<Offset>> path;
  final double t;
  final Rect rect;
  final double strength;
  _TrailPainter(this.path, this.t, this.rect, this.strength);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    Offset px(Offset f) => Offset(rect.left + f.dx * rect.width, rect.top + f.dy * rect.height);
    double len(List<Offset> s) {
      var l = 0.0;
      for (var i = 1; i < s.length; i++) l += (s[i] - s[i - 1]).distance;
      return l;
    }

    final total = path.fold<double>(0, (a, s) => a + len(s));
    var left = total * t;
    final p = Path();
    for (final s in path) {
      if (left <= 0) break;
      p.moveTo(px(s.first).dx, px(s.first).dy);
      for (var i = 1; i < s.length; i++) {
        final d = (s[i] - s[i - 1]).distance;
        if (left >= d) {
          p.lineTo(px(s[i]).dx, px(s[i]).dy);
          left -= d;
        } else {
          final e = px(Offset.lerp(s[i - 1], s[i], left / d)!);
          p.lineTo(e.dx, e.dy);
          left = 0;
          break;
        }
      }
    }
    final w = rect.width * 0.075;
    canvas.drawPath(
      p,
      Paint()
        ..color = const Color(0xFF34C6F2).withOpacity(0.35 * strength)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.6),
    );
    canvas.drawPath(
      p,
      Paint()
        ..color = const Color(0xFF1FB8EE).withOpacity(0.95 * strength)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TrailPainter o) => o.t != t || o.rect != rect || o.strength != strength;
}
