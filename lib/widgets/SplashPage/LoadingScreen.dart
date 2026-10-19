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
                    child: Image.asset(lib ? _LD.bgB : _LD.bgA, fit: BoxFit.cover),
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
