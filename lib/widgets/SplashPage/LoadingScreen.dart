import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../tools/audio_tool/Audio_Manager.dart';

/// Loading screen shown after the company logo.
/// Two illustrated themes (Adventure / Library) take turns, one per launch.
class LoadingScreen extends StatefulWidget {
  final double progress;
  final bool loadingComplete;

  const LoadingScreen({
    super.key,
    required this.progress,
    required this.loadingComplete,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LD {
  static const String dir = 'assets/images/UI/Loading/';
  // Adventure
  static const String bgA = '${dir}loading_bg_adventure.webp';
  static const String cloud = '${dir}ld_cloud.webp'; // 503 × 241
  static const String logoA = '${dir}ld_logo_a.webp'; // 475 × 231
  static const String panelA = '${dir}ld_panel_a.webp'; // 817 × 244
  static const String trackA = '${dir}ld_track_a.webp'; // 506 × 64
  static const String fillA = '${dir}ld_fill_a.webp'; // 361 × 64
  static const String star = '${dir}ld_star.webp';
  static const String flower = '${dir}ld_flower.webp'; // 142 × 240
  // Library
  static const String bgB = '${dir}loading_bg_library.webp';
  static const String bookB = '${dir}ld_book_b.webp'; // 340 × 177
  static const String wordB = '${dir}ld_word_b.webp'; // 663 × 177
  static const String lantern = '${dir}ld_lantern.webp'; // 140 × 342
  static const String panelB = '${dir}ld_panel_b.webp'; // 628 × 197
  static const String trackB = '${dir}ld_track_b.webp'; // 422 × 64
  static const String fillB = '${dir}ld_fill_b.webp'; // 436 × 64
  static const String bookIcon = '${dir}ld_bookicon.webp';
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  bool? _library; // null until the alternating choice is read
  int _tip = 0;
  Timer? _tipTimer;
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  // Faster clock for the characters (breathing, bobbing, floating icons).
  late final AnimationController _life = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();

  @override
  void initState() {
    super.initState();
    Provider.of<AudioManager>(context, listen: false).playSfx('assets/audios/AppLogoSound.mp3');
    _pickTheme();
    _tipTimer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (mounted) setState(() => _tip++);
    });
  }

  /// Alternates Adventure / Library on every launch → each shows equally often.
  Future<void> _pickTheme() async {
    var lib = Random().nextBool();
    try {
      final p = await SharedPreferences.getInstance();
      final last = p.getBool('loading_theme_library');
      if (last != null) lib = !last;
      await p.setBool('loading_theme_library', lib);
    } catch (_) {}
    if (mounted) setState(() => _library = lib);
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _idle.dispose();
    _intro.dispose();
    _life.dispose();
    super.dispose();
  }

  String _t(String key) {
    final code = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final lang = _txt.containsKey(code) ? code : (code == 'zgh' ? 'fr' : 'en');
    return _txt[lang]![key] ?? _txt['en']![key]!;
  }

  Widget _rise(double from, Widget child) {
    final a = CurvedAnimation(parent: _intro, curve: Interval(from, min(1.0, from + 0.55), curve: Curves.easeOutBack));
    return AnimatedBuilder(
      animation: a,
      builder: (_, c) => Opacity(
        opacity: a.value.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - a.value) * 30), child: c),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lib = _library;
    return ColoredBox(
      color: lib == true ? const Color(0xFF6B3A1E) : const Color(0xFF8FD3FF),
      child: lib == null
          ? const SizedBox.expand()
          : LayoutBuilder(builder: (context, c) {
              final w = c.maxWidth, h = c.maxHeight;
              final s = min(w / 400, h / 760);
              return Stack(children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _idle,
                    builder: (_, child) => Transform.scale(scale: 1.04 + 0.02 * sin(_idle.value * 2 * pi), child: child),
                    child: _LiveScene(library: lib, t: _idle, life: _life),
                  ),
                ),
                Positioned.fill(child: IgnorePointer(child: _Sparkles(anim: _idle, warm: lib))),
                if (lib) ..._library_(w, h, s) else ..._adventure(w, h, s),
              ]);
            }),
    );
  }

  // ─── Adventure ──────────────────────────────────────────────────────────

  List<Widget> _adventure(double w, double h, double s) {
    final cloudW = min(w * 0.86, 420.0 * s);
    final panelW = min(w * 0.94, 480.0 * s);
    return [
      Positioned(
        top: MediaQuery.paddingOf(context).top + 8 * s,
        left: 0,
        right: 0,
        child: _rise(
          0.0,
          Center(
            child: SizedBox(
              width: cloudW,
              height: cloudW * 241 / 503,
              child: Stack(children: [
                Positioned.fill(child: Image.asset(_LD.cloud, fit: BoxFit.fill)),
                Align(
                  alignment: const Alignment(0, -0.25),
                  child: AnimatedBuilder(
                    animation: _idle,
                    builder: (_, c) => Transform.scale(scale: 1 + 0.025 * sin(_idle.value * 4 * pi), child: c),
                    child: Image.asset(_LD.logoA, width: cloudW * 0.66),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, 0.72),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: cloudW * 0.12),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_t('taglineA'), style: _style(cloudW * 0.05, const Color(0xFF3B1A8C), FontWeight.w700)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: MediaQuery.paddingOf(context).bottom + 12 * s,
        child: _rise(
          0.25,
          Center(
            child: SizedBox(
              width: panelW,
              height: panelW * 244 / 817 * 1.25,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned.fill(child: Image.asset(_LD.panelA, fit: BoxFit.fill)),
                Positioned(
                  left: -panelW * 0.05,
                  bottom: -panelW * 0.04,
                  child: Image.asset(_LD.flower, height: panelW * 0.26),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: panelW * 0.1, vertical: panelW * 0.04),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _title(widget.loadingComplete ? 'ready' : 'titleA', panelW * 0.058, const Color(0xFF2A1366)),
                      SizedBox(height: panelW * 0.025),
                      _bar(panelW * 0.78, _LD.trackA, _LD.fillA, _LD.star, 506, 361),
                      SizedBox(height: panelW * 0.012),
                      Text('${_t('loading')}  ${(widget.progress * 100).clamp(0, 100).toInt()}%',
                          style: _style(panelW * 0.034, const Color(0xFF4A4E7A), FontWeight.w600)),
                      SizedBox(height: panelW * 0.012),
                      _divider(panelW * 0.62),
                      SizedBox(height: panelW * 0.01),
                      _tipLine(panelW * 0.034, const Color(0xFF2A2F7A)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    ];
  }

  // ─── Library ────────────────────────────────────────────────────────────

  // ignore: non_constant_identifier_names
  List<Widget> _library_(double w, double h, double s) {
    final logoW = min(w * 0.78, 380.0 * s);
    final panelW = min(w * 0.94, 480.0 * s);
    return [
      Positioned(
        top: MediaQuery.paddingOf(context).top + 14 * s,
        left: 0,
        right: 0,
        child: _rise(
          0.0,
          Column(children: [
            AnimatedBuilder(
              animation: _idle,
              builder: (_, c) => Transform.translate(offset: Offset(0, sin(_idle.value * 4 * pi) * 3 * s), child: c),
              child: Image.asset(_LD.bookB, width: logoW * 0.4),
            ),
            Image.asset(_LD.wordB, width: logoW),
            SizedBox(height: 2 * s),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(_t('taglineB'),
                  style: _style(logoW * 0.05, const Color(0xFF3A1C0C), FontWeight.w700, serif: true)
                      .copyWith(shadows: [Shadow(color: Colors.white.withOpacity(0.7), blurRadius: 6)])),
            ),
          ]),
        ),
      ),
      Positioned(
        top: 0,
        right: w * 0.03,
        child: AnimatedBuilder(
          animation: _idle,
          builder: (_, c) => Transform.rotate(
            angle: sin(_idle.value * 2 * pi) * 0.06,
            alignment: Alignment.topCenter,
            child: c,
          ),
          child: Image.asset(_LD.lantern, height: 130 * s),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: MediaQuery.paddingOf(context).bottom + 14 * s,
        child: _rise(
          0.25,
          Center(
            child: SizedBox(
              width: panelW,
              height: panelW * 197 / 628 * 1.1,
              child: Stack(children: [
                Positioned.fill(child: Image.asset(_LD.panelB, fit: BoxFit.fill)),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: panelW * 0.1, vertical: panelW * 0.05),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _title(widget.loadingComplete ? 'ready' : 'titleB', panelW * 0.058, const Color(0xFF3A1C0C), serif: true),
                      SizedBox(height: panelW * 0.03),
                      _bar(panelW * 0.8, _LD.trackB, _LD.fillB, _LD.bookIcon, 422, 436),
                      SizedBox(height: panelW * 0.02),
                      Text('${_t('loading')}  ${(widget.progress * 100).clamp(0, 100).toInt()}%',
                          style: _style(panelW * 0.034, const Color(0xFF4B2A7A), FontWeight.w600, serif: true)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    ];
  }

  // ─── Parts ──────────────────────────────────────────────────────────────

  TextStyle _style(double size, Color color, FontWeight weight, {bool serif = false}) => TextStyle(
        fontFamily: serif ? null : 'Fredoka',
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.15,
        decoration: TextDecoration.none,
      );

  Widget _title(String key, double size, Color color, {bool serif = false}) => FittedBox(
        fit: BoxFit.scaleDown,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(_t(key), key: ValueKey(key), style: _style(size, color, FontWeight.w700, serif: serif)),
        ),
      );

  Widget _tipLine(double size, Color color) {
    final tips = ['tip1', 'tip2', 'tip3', 'tip4'];
    final key = tips[_tip % tips.length];
    return SizedBox(
      height: size * 1.5,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
        child: FittedBox(
          key: ValueKey(key),
          fit: BoxFit.scaleDown,
          child: Text(_t(key), style: _style(size, color, FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _divider(double width) => SizedBox(
        width: width,
        child: Row(children: [
          Expanded(child: Container(height: 2, color: const Color(0xFFD9B45A))),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.auto_awesome, size: 12, color: Color(0xFFD9A93A)),
          ),
          Expanded(child: Container(height: 2, color: const Color(0xFFD9B45A))),
        ]),
      );

  /// Sprite bar: track + fill revealed by progress, with an icon riding the tip.
  Widget _bar(double width, String track, String fill, String tip, double trackW, double fillW) {
    final h = width * 0.11;
    const nativeH = 64.0;
    final scale = h / nativeH;
    final innerW = width / scale; // width at native sprite scale (always ≥ sprite caps)
    final v = widget.progress.isNaN ? 0.0 : widget.progress.clamp(0.0, 1.0).toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: v),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (_, p, __) => SizedBox(
        width: width,
        height: h * 1.5,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.centerLeft, children: [
          Positioned(
            left: 0,
            right: 0,
            top: h * 0.25,
            height: h,
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(
                width: innerW,
                height: nativeH,
                child: Stack(children: [
                  Positioned.fill(
                    child: Image.asset(track, centerSlice: Rect.fromLTRB(34, 18, trackW - 34, 46), fit: BoxFit.fill),
                  ),
                  if (p > 0)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: max(nativeH * 0.9, innerW * p),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(nativeH / 2),
                        child: OverflowBox(
                          alignment: Alignment.centerLeft,
                          minWidth: innerW,
                          maxWidth: innerW,
                          child: Image.asset(fill, centerSlice: Rect.fromLTRB(34, 18, fillW - 34, 46), fit: BoxFit.fill),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ),
          Positioned(
            left: (width * p - h * 0.75).clamp(0.0, width - h * 1.5),
            top: 0,
            child: AnimatedBuilder(
              animation: _idle,
              builder: (_, c) => Transform.rotate(angle: sin(_idle.value * 2 * pi * 3) * 0.12, child: c),
              child: Image.asset(tip, width: h * 1.5, height: h * 1.5),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Soft twinkling sparkles over the background.
class _Sparkles extends StatelessWidget {
  final Animation<double> anim;
  final bool warm;
  const _Sparkles({required this.anim, required this.warm});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: anim,
        builder: (_, __) => CustomPaint(painter: _SparklePainter(anim.value, warm)),
      );
}

class _SparklePainter extends CustomPainter {
  final double t;
  final bool warm;
  _SparklePainter(this.t, this.warm);

  static final List<List<double>> _pts = () {
    final r = Random(11);
    return [for (var i = 0; i < 26; i++) [r.nextDouble(), r.nextDouble() * 0.75, r.nextDouble(), 2 + r.nextDouble() * 3.5]];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final color = warm ? const Color(0xFFFFE08A) : Colors.white;
    for (final p in _pts) {
      final a = (sin((t + p[2]) * 2 * pi * 2) + 1) / 2;
      if (a < 0.15) continue;
      final c = Offset(p[0] * size.width, p[1] * size.height + sin((t + p[2]) * 2 * pi) * 6);
      final r = p[3] * (0.6 + 0.6 * a);
      final paint = Paint()..color = color.withOpacity(0.85 * a);
      final path = Path()
        ..moveTo(c.dx, c.dy - r * 2)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r * 2, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r * 2)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r * 2, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r * 2);
      canvas.drawPath(path, paint);
      canvas.drawCircle(c, r * 1.6, Paint()..color = color.withOpacity(0.18 * a));
    }
  }

  @override
  bool shouldRepaint(_SparklePainter o) => o.t != t;
}

const Map<String, Map<String, String>> _txt = {
  'en': {
    'taglineA': 'A world of adventures awaits!',
    'taglineB': 'Every page opens a new world',
    'titleA': 'Preparing your adventure...',
    'titleB': 'Opening a world of wonder...',
    'ready': 'Ready, let\'s go!',
    'loading': 'Loading...',
    'tip1': 'Learn, play, and discover something new.',
    'tip2': 'Every lesson gives you stars and coins!',
    'tip3': 'Collect badges and unlock new frames.',
    'tip4': 'Try a puzzle in Puzzle Land today!',
  },
  'fr': {
    'taglineA': 'Un monde d\'aventures t\'attend !',
    'taglineB': 'Chaque page ouvre un nouveau monde',
    'titleA': 'Préparation de ton aventure...',
    'titleB': 'Ouverture d\'un monde merveilleux...',
    'ready': 'C\'est prêt, on y va !',
    'loading': 'Chargement...',
    'tip1': 'Apprends, joue et découvre quelque chose de nouveau.',
    'tip2': 'Chaque leçon te donne des étoiles et des pièces !',
    'tip3': 'Collectionne des badges et débloque des cadres.',
    'tip4': 'Essaie un puzzle dans Puzzle Land aujourd\'hui !',
  },
  'ar': {
    'taglineA': 'عالم من المغامرات في انتظارك!',
    'taglineB': 'كل صفحة تفتح عالماً جديداً',
    'titleA': 'نجهّز مغامرتك...',
    'titleB': 'نفتح عالماً من العجائب...',
    'ready': 'جاهز، هيا بنا!',
    'loading': 'جارٍ التحميل...',
    'tip1': 'تعلّم والعب واكتشف شيئاً جديداً.',
    'tip2': 'كل درس يمنحك نجوماً وقطعاً ذهبية!',
    'tip3': 'اجمع الأوسمة وافتح إطارات جديدة.',
    'tip4': 'جرّب لغزاً في أرض الألغاز اليوم!',
  },
  'de': {
    'taglineA': 'Eine Welt voller Abenteuer wartet!',
    'taglineB': 'Jede Seite öffnet eine neue Welt',
    'titleA': 'Dein Abenteuer wird vorbereitet...',
    'titleB': 'Eine Welt voller Wunder öffnet sich...',
    'ready': 'Fertig, los geht\'s!',
    'loading': 'Wird geladen...',
    'tip1': 'Lerne, spiele und entdecke etwas Neues.',
    'tip2': 'Jede Lektion bringt dir Sterne und Münzen!',
    'tip3': 'Sammle Abzeichen und schalte Rahmen frei.',
    'tip4': 'Probier heute ein Puzzle in Puzzle Land!',
  },
};

// ─── Living characters ───────────────────────────────────────────────────────

enum _Act { bob, breathe, sleep, float, wag }

class _Part {
  final String id;
  final double x, y, h, aspect; // in the 941 × 1672 artwork
  final _Act act;
  final double phase;
  const _Part(this.id, this.x, this.y, this.h, this.aspect, this.act, [this.phase = 0]);
}

const List<_Part> _advParts = [
  _Part('robot', 30, 640, 430, 0.6714, _Act.bob, 0.0),
  _Part('fox', 510, 750, 345, 0.8095, _Act.wag, 0.3),
  _Part('boy', 290, 500, 590, 0.6238, _Act.breathe, 0.6),
  _Part('puzzle', 40, 370, 150, 1.0, _Act.float, 0.1),
  _Part('abc', 215, 330, 135, 1.0978, _Act.float, 0.35),
  _Part('globe', 395, 355, 105, 1.0549, _Act.float, 0.6),
  _Part('brush', 490, 390, 170, 1.2595, _Act.float, 0.85),
];

const List<_Part> _libParts = [
  _Part('robot', 290, 505, 500, 0.683, _Act.bob, 0.0),
  _Part('book', 250, 930, 290, 1.5607, _Act.breathe, 0.2),
  _Part('island', 395, 800, 250, 1.0641, _Act.float, 0.0),
  _Part('globe', 735, 745, 85, 1.0662, _Act.float, 0.2),
  _Part('palette', 715, 840, 75, 1.1187, _Act.float, 0.45),
  _Part('abc', 575, 860, 95, 0.9064, _Act.float, 0.7),
  _Part('puzzle', 740, 910, 55, 0.9739, _Act.float, 0.9),
  _Part('boy', 10, 735, 365, 0.7699, _Act.breathe, 0.1),
  _Part('girl', 635, 760, 360, 0.7971, _Act.breathe, 0.55),
  _Part('fox', 0, 1000, 270, 1.1471, _Act.sleep, 0.0),
];

/// Background + characters that bob, breathe, float and snooze.
class _LiveScene extends StatelessWidget {
  final bool library;
  final Animation<double> t, life;
  const _LiveScene({required this.library, required this.t, required this.life});

  static const double _w = 941, _h = 1672;

  @override
  Widget build(BuildContext context) {
    final parts = library ? _libParts : _advParts;
    final pre = library ? 'lib' : 'adv';
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _w,
        height: _h,
        child: AnimatedBuilder(
          animation: life,
          builder: (_, __) {
            final v = life.value * 2 * pi; // 12 s loop
            return Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(child: Image.asset(library ? _LD.bgB : _LD.bgA, fit: BoxFit.cover)),
              for (final p in parts) _part(p, pre, v),
              if (library) ..._zzz(v),
            ]);
          },
        ),
      ),
    );
  }

  Widget _part(_Part p, String pre, double v) {
    final w = p.h * p.aspect;
    final ph = p.phase * 2 * pi;
    Offset off = Offset.zero;
    double rot = 0, sx = 1, sy = 1;
    Alignment anchor = Alignment.bottomCenter;
    switch (p.act) {
      case _Act.bob: // robots hover and tilt
        off = Offset(0, sin(v * 4 + ph) * 9);
        rot = sin(v * 2 + ph) * 0.025;
      case _Act.breathe: // kids breathe and sway
        sy = 1 + sin(v * 5 + ph) * 0.012;
        sx = 1 - sin(v * 5 + ph) * 0.006;
        rot = sin(v * 2 + ph) * 0.018;
      case _Act.sleep: // sleeping fox: slow deep breaths
        sy = 1 + (sin(v * 3 + ph) + 1) * 0.018;
        sx = 1 + (sin(v * 3 + ph) + 1) * 0.006;
      case _Act.wag: // fox bounces and tilts its head
        off = Offset(0, -max(0, sin(v * 6 + ph)) * 7);
        rot = sin(v * 3 + ph) * 0.03;
        anchor = const Alignment(-0.2, 1);
      case _Act.float: // icons drift and spin a little
        off = Offset(sin(v * 3 + ph) * 6, sin(v * 4 + ph) * 12);
        rot = sin(v * 2 + ph) * 0.12;
        anchor = Alignment.center;
    }
    return Positioned(
      left: p.x,
      top: p.y,
      width: w,
      height: p.h,
      child: Transform.translate(
        offset: off,
        child: Transform(
          alignment: anchor,
          transform: Matrix4.identity()
            ..rotateZ(rot)
            ..scale(sx, sy),
          child: Image.asset('${_LD.dir}chars/${pre}_${p.id}.webp', fit: BoxFit.contain, filterQuality: FilterQuality.medium),
        ),
      ),
    );
  }

  /// Little "z" bubbles rising from the sleeping fox.
  List<Widget> _zzz(double v) => [
        for (var i = 0; i < 3; i++)
          Builder(builder: (_) {
            final k = ((v / (2 * pi) * 3) + i / 3) % 1.0;
            return Positioned(
              left: 300 + k * 40 + i * 6,
              top: 1010 - k * 110,
              child: Opacity(
                opacity: (1 - k) * (k < 0.1 ? k * 10 : 1),
                child: Text('z',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w700,
                      fontSize: 34 + k * 22,
                      color: const Color(0xFFFFF4D6),
                      decoration: TextDecoration.none,
                      shadows: const [Shadow(color: Color(0xFF8A4B12), blurRadius: 6)],
                    )),
              ),
            );
          }),
      ];
}

// ─── Library scene as a puppet: every body part moves on its own ────────────

class _P {
  final double cx, cy, w, aspect; // centre + width in the 941 × 1672 artwork
  const _P(this.cx, this.cy, this.w, this.aspect);
  double get h => w * aspect;
}

const Map<String, _P> _lp = {
  'lantern_a': _P(150, 190, 95, 3.2838),
  'lantern_b': _P(800, 170, 80, 3.6752),
  'vines': _P(470, 70, 520, 0.4641),
  'cloud': _P(820, 520, 170, 0.614),
  'isle_a': _P(150, 560, 120, 1.0733),
  'isle_b': _P(820, 640, 95, 1.1271),
  'glow': _P(610, 1000, 420, 0.919),
  'castle': _P(630, 915, 230, 1.2751),
  'ring': _P(610, 1040, 300, 0.6959),
  'book_open': _P(610, 1110, 360, 0.3057),
  'robot_robe': _P(395, 855, 250, 0.7437),
  'robot_hand': _P(560, 830, 190, 0.4684),
  'robot_book': _P(265, 900, 95, 1.2222),
  'robot_head': _P(390, 700, 245, 0.7407),
  'robot_eyes_open': _P(400, 712, 150, 0.4733),
  'robot_eyes_happy': _P(400, 712, 150, 0.4609),
  'robot_glasses': _P(395, 612, 130, 0.3475),
  'globe': _P(800, 770, 90, 1.2478),
  'palette': _P(770, 880, 95, 0.8792),
  'blk_a': _P(560, 940, 52, 1.0),
  'blk_b': _P(612, 948, 52, 1.0071),
  'blk_c': _P(664, 940, 52, 1.0),
  'puzzle': _P(790, 960, 60, 0.9886),
  'cushion': _P(190, 1205, 330, 0.4734),
  'fox_tail': _P(300, 1150, 150, 0.8394),
  'fox_body': _P(180, 1135, 280, 0.6183),
  'fox_head': _P(95, 1110, 170, 0.7282),
  'fox_ear_l': _P(45, 1050, 45, 1.1143),
  'fox_ear_r': _P(125, 1048, 45, 1.1038),
  'boy_hoodie': _P(165, 1000, 300, 0.7177),
  'boy_head': _P(150, 875, 235, 0.9398),
  'boy_hands': _P(190, 975, 170, 1.0439),
  'boy_lid_l': _P(160.6, 901.2, 60.9, 0.6933),
  'boy_lid_r': _P(216.5, 890.6, 46.7, 0.7571),
  'girl': _P(790, 935, 320, 1.0992),
  'girl_lid_l': _P(707.1, 943.2, 59.8, 0.6627),
  'girl_lid_r': _P(775.9, 959.5, 68.9, 0.7),
  'sparkles': _P(600, 780, 200, 1.1145),
  'page_r': _P(700, 1095, 190, 0.6046),
  'trail': _P(520, 960, 200, 0.8741),
  'sparkle_big': _P(700, 840, 70, 1.047),
};

class _PuppetLibrary extends StatefulWidget {
  final Animation<double> life; // 12 s loop
  const _PuppetLibrary({required this.life});

  @override
  State<_PuppetLibrary> createState() => _PuppetLibraryState();
}

class _PuppetLibraryState extends State<_PuppetLibrary> with SingleTickerProviderStateMixin {
  // the castle island rises out of the book once, then floats
  late final AnimationController _rise = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..forward();

  @override
  void dispose() {
    _rise.dispose();
    super.dispose();
  }

  static const double _w = 941, _h = 1672;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) => FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _w,
          height: _h,
          child: AnimatedBuilder(
            animation: Listenable.merge([widget.life, _rise]),
            builder: (_, __) => Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(child: Image.asset(_LD.bgB, fit: BoxFit.cover)),
              _fitLayer(c, _w, _h, const Offset(470, 1150), _parts()),
            ]),
          ),
        ),
      ),
    );
  }

  /// Seconds into the 12 s loop.
  double get _sec => widget.life.value * 12;

  /// 0→1→0 pulse lasting [len] seconds that starts at [at] (looping).
  double _pulse(double at, double len) {
    final d = (_sec - at) % 12;
    if (d < 0 || d > len) return 0;
    return sin(d / len * pi);
  }

  bool _within(double at, double len) {
    final d = (_sec - at) % 12;
    return d >= 0 && d <= len;
  }

  Widget _img(String n, {double dx = 0, double dy = 0, double rot = 0, double sx = 1, double sy = 1, double opacity = 1,
      Alignment anchor = Alignment.center, double scale = 1, Offset? pivot}) {
    final p = _lp[n]!;
    final w = p.w * scale, h = p.h * scale;
    if (pivot != null) {
      // rotate around a shared scene point (e.g. a neck) so face parts stay glued to the head
      anchor = Alignment((pivot.dx - (p.cx - w / 2)) / w * 2 - 1, (pivot.dy - (p.cy - h / 2)) / h * 2 - 1);
    }
    return Positioned(
      left: p.cx - w / 2 + dx,
      top: p.cy - h / 2 + dy,
      width: w,
      height: h,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0).toDouble(),
          child: Transform(
            alignment: anchor,
            transform: Matrix4.identity()
              ..rotateZ(rot)
              ..scale(sx, sy),
            child: Image.asset('${_LD.dir}lib/$n.webp', fit: BoxFit.fill, filterQuality: FilterQuality.medium),
          ),
        ),
      ),
    );
  }

  List<Widget> _parts() {
    final v = widget.life.value * 2 * pi; // one turn per 12 s
    final rise = Curves.easeOutBack.transform(_rise.value);

    // robot: whole body bobs; head tilts; hand waves; happy eyes now and then
    final rBob = sin(v * 4) * 7;
    final headTilt = sin(v * 2) * 0.05 + _pulse(5.0, 1.4) * 0.08;
    final happy = _within(5.0, 1.4) || _within(10.6, 0.2);
    final wave = sin(v * 6) * 0.12 - 0.05;

    // boy: head sways; blinks
    final boyTilt = sin(v * 2 + 1) * 0.045;
    final boyBlink = _within(2.1, 0.16) || _within(7.4, 0.16) || _within(7.7, 0.14);
    // girl: gentle sway; blinks
    final girlTilt = sin(v * 2 + 2.4) * 0.03;
    final girlBlink = _within(3.6, 0.16) || _within(9.1, 0.16);

    // fox: breathing body, nodding head, ear twitches, swishing tail
    final breath = (sin(v * 3) + 1) / 2;
    final earL = _pulse(4.0, 0.35) * 0.35 + _pulse(10.2, 0.3) * 0.3;
    final earR = _pulse(4.2, 0.35) * -0.35;
    final tail = sin(v * 2) * 0.08 + _pulse(8.0, 0.8) * 0.18;

    // book page flips every 4 s
    final flipT = ((_sec % 4) - 2.6) / 1.0; // flips during 2.6–3.6 s of each 4 s
    final flipping = flipT >= 0 && flipT <= 1;
    final flip = flipping ? cos(Curves.easeInOut.transform(flipT) * pi) : 1.0;

    // castle island: rises from the book, then floats
    final castleDy = (1 - rise) * 170 + sin(v * 3) * 9;

    // hanging-head pivot helper: rotate around the neck (bottom centre)
    Widget head(String n, double rot, Offset neck, {double dy = 0}) => _img(n, rot: rot, dy: dy, pivot: neck);
    const robotNeck = Offset(392, 790), boyNeck = Offset(160, 975), girlNeck = Offset(800, 1080);

    return [
      // decor
      _img('lantern_a', rot: sin(v * 2) * 0.05, anchor: Alignment.topCenter),
      _img('lantern_b', rot: sin(v * 2 + 1.3) * 0.06, anchor: Alignment.topCenter),
      _img('vines', dy: sin(v * 2) * 3),
      _img('cloud', dx: sin(v) * 26),
      _img('isle_a', dy: sin(v * 3) * 10),
      _img('isle_b', dy: sin(v * 3 + 2) * 8),
      // magic above the book
      _img('glow', opacity: 0.55 + 0.25 * sin(v * 4) + 0.2 * rise, scale: 0.9 + 0.08 * sin(v * 4)),
      _img('castle', dy: castleDy, opacity: rise, scale: 0.6 + 0.4 * rise),
      _img('ring', rot: v, opacity: 0.85 * rise, sx: 1, sy: 1),
      _img('trail', opacity: (0.5 + 0.5 * sin(v * 3)) * rise, dy: -sin(v * 2) * 10),
      _img('book_open'),
      _img('page_r', sx: flip, anchor: Alignment.centerLeft, dy: -6 * (1 - flip.abs())),
      // floating little things
      _img('globe', dy: sin(v * 4) * 8, rot: sin(v * 2) * 0.08),
      _img('palette', dy: sin(v * 4 + 1) * 9, rot: sin(v * 3) * 0.12),
      _img('blk_a', dy: sin(v * 5) * 7 - 18 * rise, rot: sin(v * 3) * 0.2),
      _img('blk_b', dy: sin(v * 5 + 1) * 7 - 26 * rise, rot: sin(v * 3 + 1) * 0.2),
      _img('blk_c', dy: sin(v * 5 + 2) * 7 - 18 * rise, rot: sin(v * 3 + 2) * 0.2),
      _img('puzzle', dy: sin(v * 4 + 2) * 8, rot: v),
      // robot
      _img('robot_book', dy: rBob, rot: sin(v * 2) * 0.04),
      _img('robot_robe', dy: rBob),
      _img('robot_hand', dy: rBob, rot: wave, anchor: Alignment.centerLeft),
      head('robot_head', headTilt, robotNeck, dy: rBob),
      head(happy ? 'robot_eyes_happy' : 'robot_eyes_open', headTilt, robotNeck, dy: rBob),
      head('robot_glasses', headTilt, robotNeck, dy: rBob),
      // fox on its cushion
      _img('cushion'),
      _img('fox_tail', rot: tail, anchor: Alignment.centerLeft),
      _img('fox_body', sy: 1 + breath * 0.035, sx: 1 + breath * 0.012, anchor: Alignment.bottomCenter),
      _img('fox_ear_l', rot: -earL, anchor: Alignment.bottomCenter, dy: -breath * 4),
      _img('fox_ear_r', rot: -earR, anchor: Alignment.bottomCenter, dy: -breath * 4),
      _img('fox_head', dy: -breath * 4, rot: sin(v * 2) * 0.03, anchor: Alignment.bottomCenter),
      // boy
      _img('boy_hoodie', sy: 1 + sin(v * 5) * 0.01, anchor: Alignment.bottomCenter),
      head('boy_head', boyTilt, boyNeck),
      if (boyBlink) head('boy_lid_l', boyTilt, boyNeck),
      if (boyBlink) head('boy_lid_r', boyTilt, boyNeck),
      _img('boy_hands', dy: sin(v * 5) * 2),
      // girl
      head('girl', girlTilt, girlNeck),
      if (girlBlink) head('girl_lid_l', girlTilt, girlNeck),
      if (girlBlink) head('girl_lid_r', girlTilt, girlNeck),
      // sparkles
      _img('sparkles', opacity: 0.4 + 0.6 * ((sin(v * 6) + 1) / 2), scale: 0.9 + 0.1 * sin(v * 6)),
      _img('sparkle_big', opacity: _pulse(1.0, 1.2) + _pulse(6.5, 1.2), rot: v * 2, scale: 0.6 + 0.6 * (_pulse(1.0, 1.2) + _pulse(6.5, 1.2))),
    ];
  }
}

// ─── Adventure scene as a puppet ───────────────────────────────────────────

const Map<String, _P> _ap = {
  'boy_arm_r_up': _P(535.1, 816.2, 89.6, 1.3233),
  'boy_arm_r_lo': _P(584.1, 889.0, 139.3, 0.6763),
  'boy_leg_l': _P(432.9, 1026.2, 135.1, 0.9303),
  'boy_leg_r': _P(507.1, 1022.0, 136.5, 1.0255),
  'boy_torso': _P(460.9, 858.2, 177.8, 1.3716),
  'boy_arm_l_up': _P(375.5, 816.2, 85.4, 1.3231),
  'boy_arm_l_lo': _P(367.1, 891.8, 107.8, 0.6442),
  'compass': _P(348.9, 947.8, 63.0, 1.5253),
  'boy_head': _P(453.9, 634.2, 265.3, 0.8513),
  'boy_lid_l': _P(454.6, 648.2, 50.4, 1.1212),
  'boy_lid_r': _P(520.4, 648.2, 47.6, 1.2135),
  'backpack': _P(104.0, 890.0, 151.8, 0.928),
  'robot_leg_l': _P(144.9, 1012.1, 96.4, 1.3677),
  'robot_leg_r': _P(199.7, 1010.1, 80.5, 1.6591),
  'robot_arm_l': _P(85.5, 939.5, 87.1, 1.7801),
  'robot_body': _P(170.0, 901.9, 145.2, 0.8996),
  'robot_arm_r': _P(257.1, 934.9, 130.0, 1.1122),
  'robot_head': _P(166.7, 771.2, 227.0, 0.7147),
  'robot_eyes': _P(174.0, 768.6, 135.3, 0.6213),
  'robot_eyes_happy': _P(174.0, 768.6, 135.3, 0.6128),
  'fox_tail': _P(721.0, 944.3, 113.3, 1.2315),
  'fox_leg1': _P(623.6, 1021.3, 50.6, 1.8198),
  'fox_leg3': _P(691.9, 1019.1, 50.6, 1.8447),
  'fox_leg0': _P(638.0, 1043.3, 55.0, 1.7727),
  'fox_leg2': _P(674.2, 1043.3, 55.0, 1.8447),
  'fox_body': _P(655.0, 936.0, 111.7, 1.0419),
  'fox_head': _P(646.8, 804.0, 160.1, 1.053),
  'fox_lid_l': _P(631.9, 814.5, 39.6, 1.1829),
  'fox_lid_r': _P(685.2, 814.5, 38.5, 1.2436),
  'cloud': _P(140, 300, 230, 0.5725),
  'isle': _P(820, 560, 150, 1.0035),
  'pz_r': _P(70, 420, 70, 1.0307),
  'pz_b': _P(140, 470, 62, 1.1184),
  'pz_g': _P(95, 520, 58, 1.0881),
  'pz_y': _P(165, 400, 52, 1.0613),
  'blk_a': _P(245, 400, 62, 0.9464),
  'blk_b': _P(300, 420, 62, 0.9294),
  'blk_c': _P(355, 400, 62, 0.9314),
  'globe': _P(455, 400, 95, 0.9621),
  'brush': _P(575, 450, 130, 0.9167),
  'rainbow': _P(665, 440, 170, 0.7082),
  'note1': _P(620, 560, 52, 1.2803),
  'note2': _P(680, 590, 58, 1.1274),
  'star_big': _P(760, 700, 70, 0.9493),
  'sparkles': _P(540, 330, 170, 0.8735),
  'glow': _P(455, 400, 200, 0.9838),
  'ring': _P(455, 405, 160, 0.5968),
  'cloud_b': _P(800, 250, 200, 0.5725),
};

const Offset _boyNeck = Offset(460.9, 741.3);
const Offset _boyShL = Offset(375.5, 776.3);
const Offset _boyShR = Offset(547.0, 776.3);
const Offset _boyElR = Offset(550.5, 877.8);
const Offset _boyElL = Offset(347.5, 867.3);
const Offset _compassTop = Offset(348.9, 919.8);
const Offset _robotNeck = Offset(170.0, 837.2);
const Offset _robotShL = Offset(110.6, 876.8);
const Offset _robotShR = Offset(229.4, 876.8);
const Offset _foxNeck = Offset(652.2, 875.5);
const Offset _foxTail = Offset(685.2, 982.8);

/// Characters layer, shrunk around the floor point [floor] so nobody is cut off
/// on phones narrower than the artwork (the background stays full-bleed).
Widget _fitLayer(BoxConstraints c, double w, double h, Offset floor, List<Widget> parts) {
  final cover = max(c.maxWidth / w, c.maxHeight / h);
  final visible = c.maxWidth / cover; // scene width actually on screen
  final k = min(1.0, (visible - 30) / 960);
  return Positioned.fill(
    child: Transform(
      alignment: Alignment(floor.dx / w * 2 - 1, floor.dy / h * 2 - 1),
      transform: Matrix4.identity()..scale(k, k),
      child: Stack(clipBehavior: Clip.none, children: parts),
    ),
  );
}

/// Places one puppet part from [map] (scene coords), optionally rotating around a shared [pivot].
Widget _puppet(Map<String, _P> map, String folder, String n,
    {double dx = 0, double dy = 0, double rot = 0, double sx = 1, double sy = 1, double opacity = 1, double scale = 1,
    Alignment anchor = Alignment.center, Offset? pivot}) {
  final p = map[n]!;
  final w = p.w * scale, h = p.h * scale;
  if (pivot != null) {
    anchor = Alignment((pivot.dx - (p.cx - w / 2)) / w * 2 - 1, (pivot.dy - (p.cy - h / 2)) / h * 2 - 1);
  }
  final file = n == 'cloud_b' ? 'cloud' : n;
  return Positioned(
    left: p.cx - w / 2 + dx,
    top: p.cy - h / 2 + dy,
    width: w,
    height: h,
    child: IgnorePointer(
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0).toDouble(),
        child: Transform(
          alignment: anchor,
          transform: Matrix4.identity()
            ..rotateZ(rot)
            ..scale(sx, sy),
          child: Image.asset('${_LD.dir}$folder/$file.webp', fit: BoxFit.fill, filterQuality: FilterQuality.medium),
        ),
      ),
    ),
  );
}

class _PuppetAdventure extends StatelessWidget {
  final Animation<double> life; // 12 s loop
  const _PuppetAdventure({required this.life});

  static const double _w = 941, _h = 1672;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) => FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _w,
          height: _h,
          child: AnimatedBuilder(
            animation: life,
            builder: (_, __) => Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(child: Image.asset(_LD.bgA, fit: BoxFit.cover)),
              _fitLayer(c, _w, _h, const Offset(470, 1095), _parts()),
            ]),
          ),
        ),
      ),
    );
  }

  double get _sec => life.value * 12;
  double _pulse(double at, double len) {
    final d = (_sec - at) % 12;
    if (d < 0 || d > len) return 0;
    return sin(d / len * pi);
  }

  bool _within(double at, double len) {
    final d = (_sec - at) % 12;
    return d >= 0 && d <= len;
  }

  Widget _i(String n, {double dx = 0, double dy = 0, double rot = 0, double sx = 1, double sy = 1, double opacity = 1, double scale = 1,
          Alignment anchor = Alignment.center, Offset? pivot}) =>
      _puppet(_ap, 'adv', n, dx: dx, dy: dy, rot: rot, sx: sx, sy: sy, opacity: opacity, scale: scale, anchor: anchor, pivot: pivot);

  List<Widget> _parts() {
    final v = life.value * 2 * pi; // one turn per 12 s
    final step = v * 12; // 6 steps per loop

    // boy: marches in place, points, looks around, blinks
    final legL = max(0.0, sin(step)), legR = max(0.0, -sin(step));
    final bBob = -(legL + legR) * 6;
    final bHead = sin(v * 2) * 0.05 + _pulse(6.0, 1.2) * 0.08;
    final bBlink = _within(1.8, 0.15) || _within(6.9, 0.15) || _within(7.2, 0.13);
    final point = sin(v * 4) * 0.06 + _pulse(3.0, 1.0) * -0.18;
    final swingL = sin(step) * 0.12;

    // robot: hovers, swings arms, happy face now and then
    final rBob = sin(v * 4) * 8;
    final rHead = sin(v * 2 + 1) * 0.06;
    final happy = _within(4.5, 1.3) || _within(9.8, 0.25);
    final armL = sin(step + pi) * 0.14, armR = sin(step) * 0.14 - _pulse(8.0, 1.5) * 0.5;
    final rLegL = max(0.0, sin(step + 0.6)) * 5, rLegR = max(0.0, -sin(step + 0.6)) * 5;

    // fox: wags, cocks its head, blinks, taps a paw
    final wag = sin(v * 10) * 0.22;
    final fHead = sin(v * 2 + 2) * 0.05 + _pulse(5.0, 1.0) * 0.14;
    final fBlink = _within(2.9, 0.15) || _within(8.6, 0.15);
    final fBreath = (sin(v * 4) + 1) / 2;
    final paw = _pulse(10.0, 0.5) * 12 + _pulse(10.6, 0.5) * 12;

    return [
      // sky
      _i('cloud', dx: sin(v) * 30),
      _i('cloud_b', dx: -sin(v + 1) * 36),
      _i('isle', dy: sin(v * 3) * 12),
      _i('sparkles', opacity: 0.35 + 0.65 * ((sin(v * 6) + 1) / 2), scale: 0.9 + 0.12 * sin(v * 6)),
      _i('glow', opacity: 0.45 + 0.3 * sin(v * 4), scale: 1 + 0.1 * sin(v * 4)),
      _i('ring', rot: v * 2, dy: sin(v * 4) * 8),
      _i('globe', dy: sin(v * 4) * 8, rot: v * 0.5),
      _i('rainbow', opacity: 0.55 + 0.45 * ((sin(v * 3) + 1) / 2), scale: 0.92 + 0.08 * sin(v * 3)),
      _i('brush', rot: sin(v * 6) * 0.25, anchor: Alignment.topRight, dy: sin(v * 4) * 5),
      _i('note1', dy: sin(v * 6) * 12, rot: sin(v * 3) * 0.2, opacity: 0.6 + 0.4 * sin(v * 6).abs()),
      _i('note2', dy: sin(v * 6 + 1.5) * 12, rot: sin(v * 3 + 1) * 0.2, opacity: 0.6 + 0.4 * sin(v * 6 + 1.5).abs()),
      _i('pz_r', dy: sin(v * 4) * 10, rot: sin(v * 2) * 0.4),
      _i('pz_b', dy: sin(v * 4 + 1) * 10, rot: sin(v * 2 + 1) * 0.4),
      _i('pz_g', dy: sin(v * 4 + 2) * 10, rot: sin(v * 2 + 2) * 0.4),
      _i('pz_y', dy: sin(v * 4 + 3) * 10, rot: sin(v * 2 + 3) * 0.4),
      _i('blk_a', dy: sin(v * 5) * 9 - _pulse(2.0, 0.6) * 20, rot: sin(v * 3) * 0.15),
      _i('blk_b', dy: sin(v * 5 + 1) * 9 - _pulse(2.3, 0.6) * 20, rot: sin(v * 3 + 1) * 0.15),
      _i('blk_c', dy: sin(v * 5 + 2) * 9 - _pulse(2.6, 0.6) * 20, rot: sin(v * 3 + 2) * 0.15),
      _i('star_big', rot: v, scale: 0.8 + 0.3 * ((sin(v * 6) + 1) / 2)),
      // robot
      _i('backpack', dy: rBob, rot: sin(v * 4) * 0.03),
      _i('robot_leg_l', dy: rBob * 0.4 - rLegL),
      _i('robot_leg_r', dy: rBob * 0.4 - rLegR),
      _i('robot_arm_l', dy: rBob, rot: armL, pivot: _robotShL),
      _i('robot_body', dy: rBob),
      _i('robot_arm_r', dy: rBob, rot: armR, pivot: _robotShR),
      _i('robot_head', dy: rBob, rot: rHead, pivot: _robotNeck),
      _i(happy ? 'robot_eyes_happy' : 'robot_eyes', dy: rBob, rot: rHead, pivot: _robotNeck),
      // fox
      _i('fox_tail', rot: wag, pivot: _foxTail),
      _i('fox_leg1'),
      _i('fox_leg3'),
      _i('fox_leg0', dy: -paw),
      _i('fox_leg2'),
      _i('fox_body', sy: 1 + fBreath * 0.025, anchor: Alignment.bottomCenter),
      _i('fox_head', rot: fHead, pivot: _foxNeck, dy: -fBreath * 3),
      if (fBlink) _i('fox_lid_l', rot: fHead, pivot: _foxNeck, dy: -fBreath * 3),
      if (fBlink) _i('fox_lid_r', rot: fHead, pivot: _foxNeck, dy: -fBreath * 3),
      // boy
      _i('boy_arm_r_up', dy: bBob, rot: point * 0.5, pivot: _boyShR),
      _i('boy_arm_r_lo', dy: bBob, rot: point, pivot: _boyShR),
      _i('boy_leg_l', dy: -legL * 14, rot: -legL * 0.06),
      _i('boy_leg_r', dy: -legR * 14, rot: legR * 0.06),
      _i('boy_torso', dy: bBob),
      _i('boy_arm_l_up', dy: bBob, rot: swingL, pivot: _boyShL),
      _i('boy_arm_l_lo', dy: bBob, rot: swingL, pivot: _boyShL),
      _i('compass', dy: bBob, rot: swingL + sin(v * 8) * 0.25, pivot: _compassTop),
      _i('boy_head', dy: bBob, rot: bHead, pivot: _boyNeck),
      if (bBlink) _i('boy_lid_l', dy: bBob, rot: bHead, pivot: _boyNeck),
      if (bBlink) _i('boy_lid_r', dy: bBob, rot: bHead, pivot: _boyNeck),
    ];
  }
}
