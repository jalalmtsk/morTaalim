import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Mon jardin vivant — sow a seed, take care of it, watch it grow.
// 12 levels in 3 garden areas, 6 plants to discover:
//   1–4  "Les premières pousses"  plant + water
//   5–8  "Le potager"             seeds, water & light, plant parts
//   9–12 "La serre des découvertes" recognise seeds, several days, life cycle
// ═══════════════════════════════════════════════════════════════════════════

const String jdDir = 'assets/images/Games/Garden/';
String jd(String n) => '$jdDir$n.webp';

const Color jdInk = Color(0xFF4A1D9E);
const Color jdInkSoft = Color(0xFF6B5A92);
const Color jdBrown = Color(0xFF4E2C12);
const Color jdTeal = Color(0xFF13A6B8);
const Color jdOrange = Color(0xFFF26B1D);
const Color jdGreen = Color(0xFF2E9E3E);
const Color jdRed = Color(0xFFE5484D);
const Color jdCream = Color(0xFFFFF8EA);
const Color jdBlue = Color(0xFF1D5FD1);

TextStyle jdText(double size, {Color color = jdBrown, FontWeight weight = FontWeight.w700, double? height}) =>
    TextStyle(fontFamily: 'Fredoka', fontSize: size, color: color, fontWeight: weight, height: height);

// ── plants ─────────────────────────────────────────────────────────────────

enum JdLight { shade, half, sun }

class JdPlant {
  final String id;
  final JdLight light;
  final Color seedColor;
  const JdPlant(this.id, this.light, this.seedColor);
  String name(BuildContext c) => jdT(c, id);
  String my(BuildContext c) => jdT(c, '${id}_my');
  String the(BuildContext c) => jdT(c, '${id}_the');
  String seedOf(BuildContext c) => jdT(c, '${id}_seed');
  String grown(BuildContext c) => jdT(c, '${id}_grown');
  String fact(BuildContext c) => jdT(c, '${id}_fact');
  String get pot => jd('jd_pot_$id');
  String get packet => jd('jd_pk_$id');
}

const List<JdPlant> jdPlants = [
  JdPlant('bean', JdLight.sun, Color(0xFFF1E3C2)),
  JdPlant('sunflower', JdLight.sun, Color(0xFF3A3A3A)),
  JdPlant('radish', JdLight.half, Color(0xFF8A5A3A)),
  JdPlant('basil', JdLight.sun, Color(0xFF1F1F1F)),
  JdPlant('tomato', JdLight.sun, Color(0xFFE8D9A8)),
  JdPlant('carrot', JdLight.half, Color(0xFF9C6B3E)),
];

JdPlant jdPlant(String id) => jdPlants.firstWhere((p) => p.id == id);

// ── levels ─────────────────────────────────────────────────────────────────

enum JdGrow { watch, parts, order }

class JdLevel {
  final int n; // 1..12
  final String plantId;
  final int seedPick; // 0 no seed choice, 1 with names, 2 pictures only
  final int days; // days of care
  final bool light; // the child chooses the light
  final JdGrow grow;
  const JdLevel(this.n, this.plantId, this.seedPick, this.days, this.light, this.grow);
  JdPlant get plant => jdPlant(plantId);
  int get world => n <= 4 ? 0 : (n <= 8 ? 1 : 2);
  String title(BuildContext c) => plant.my(c);
  String sub(BuildContext c) => jdT(c, switch (grow) { JdGrow.watch => 'subWatch', JdGrow.parts => 'subParts', JdGrow.order => 'subOrder' });
}

const List<JdLevel> jdLevels = [
  JdLevel(1, 'bean', 0, 1, false, JdGrow.watch),
  JdLevel(2, 'sunflower', 0, 1, false, JdGrow.watch),
  JdLevel(3, 'radish', 1, 1, true, JdGrow.watch),
  JdLevel(4, 'basil', 1, 1, true, JdGrow.parts),
  JdLevel(5, 'tomato', 1, 2, true, JdGrow.parts),
  JdLevel(6, 'carrot', 1, 2, true, JdGrow.order),
  JdLevel(7, 'bean', 2, 2, true, JdGrow.parts),
  JdLevel(8, 'sunflower', 2, 2, true, JdGrow.order),
  JdLevel(9, 'radish', 2, 3, true, JdGrow.parts),
  JdLevel(10, 'basil', 2, 3, true, JdGrow.order),
  JdLevel(11, 'tomato', 2, 3, true, JdGrow.order),
  JdLevel(12, 'carrot', 2, 3, true, JdGrow.parts),
];

// ── progress ───────────────────────────────────────────────────────────────

class JdStore {
  static String _k(int n) => 'jd_stars_$n';

  static Future<List<int>> stars() async {
    final p = await SharedPreferences.getInstance();
    return [for (final l in jdLevels) p.getInt(_k(l.n)) ?? 0];
  }

  /// Saves if better. Returns (new stars won, first time finished, new plant discovered).
  static Future<(int, bool, bool)> record(int n, int stars) async {
    final p = await SharedPreferences.getInstance();
    final before = discoveredFrom([for (final l in jdLevels) p.getInt(_k(l.n)) ?? 0]);
    final old = p.getInt(_k(n)) ?? 0;
    if (stars > old) await p.setInt(_k(n), stars);
    final plant = jdLevels[n - 1].plantId;
    final fresh = !before.contains(plant);
    if (fresh) await p.setString('jd_new', plant);
    return (max(0, stars - old), old == 0, fresh);
  }

  static bool unlocked(List<int> stars, int n) => n == 1 || (stars.length >= n - 1 && stars[n - 2] > 0);

  static int next(List<int> stars) {
    for (var i = 0; i < stars.length; i++) {
      if (stars[i] == 0) return i + 1;
    }
    return jdLevels.length;
  }

  static Set<String> discoveredFrom(List<int> stars) => {
        for (var i = 0; i < jdLevels.length; i++)
          if (i < stars.length && stars[i] > 0) jdLevels[i].plantId,
      };

  static Future<String?> newest() async => (await SharedPreferences.getInstance()).getString('jd_new');

  static Future<bool> seenHelp() async => (await SharedPreferences.getInstance()).getBool('jd_help') ?? false;
  static Future<void> setSeenHelp() async => (await SharedPreferences.getInstance()).setBool('jd_help', true);
}

// ── sound & voice ──────────────────────────────────────────────────────────

void jdSound(BuildContext c, String key) {
  try {
    Provider.of<AudioManager>(c, listen: false).playEventSound(key);
  } catch (_) {}
}

void jdSfx(BuildContext c, String file) {
  try {
    Provider.of<AudioManager>(c, listen: false).playSfx('assets/audios/UI_Audio/SFX_Audio/$file');
  } catch (_) {}
}

class JdVoice {
  static final FlutterTts _tts = FlutterTts();
  static Future<void> say(BuildContext c, String text) async {
    try {
      final lang = switch (jdLang(c)) { 'fr' => 'fr-FR', 'ar' => 'ar-SA', 'de' => 'de-DE', _ => 'en-US' };
      await _tts.stop();
      await _tts.setLanguage(lang);
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.1);
      await _tts.speak(text);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

// ── layout helpers ─────────────────────────────────────────────────────────

bool jdRtl(BuildContext c) => Directionality.of(c) == TextDirection.rtl;

double jdScale(BuildContext c) {
  final size = MediaQuery.sizeOf(c);
  final pad = MediaQuery.paddingOf(c);
  final h = size.height - pad.vertical;
  return min(min(size.width, 520.0) / 390, h / 800).clamp(0.72, 1.3).toDouble();
}

class _JdFrameMark extends InheritedWidget {
  const _JdFrameMark({required super.child});
  @override
  bool updateShouldNotify(_JdFrameMark oldWidget) => false;
}

/// Lays the page out on a phone-sized design canvas (≈390 wide) and scales it
/// to the real screen so every device shows the same centred layout.
class JdFrame extends StatelessWidget {
  final Widget child;
  const JdFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (context.dependOnInheritedWidgetOfExactType<_JdFrameMark>() != null) return child;
    final mq = MediaQuery.of(context);
    final W = mq.size.width, H = mq.size.height;
    if (W <= 0 || H <= 0) return child;
    final k = min(min(W / 390, H / 780), 1.35).toDouble();
    final dw = W / k, dh = H / k;
    EdgeInsets d(EdgeInsets e) => EdgeInsets.fromLTRB(e.left / k, e.top / k, e.right / k, e.bottom / k);
    return _JdFrameMark(
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: dw,
          height: dh,
          child: MediaQuery(
            data: mq.copyWith(
              size: Size(dw, dh),
              padding: d(mq.padding),
              viewPadding: d(mq.viewPadding),
              viewInsets: d(mq.viewInsets),
              textScaler: TextScaler.noScaling,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class JdBg extends StatelessWidget {
  final String asset;
  const JdBg({super.key, this.asset = 'jd_bg'});
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Image.asset(jd(asset), fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white.withOpacity(0.05), const Color(0xFFFFF3D6).withOpacity(0.22)],
            ),
          ),
        ),
             const JdAmbientLeaves(),
      ]);
}

// ── buttons ────────────────────────────────────────────────────────────────

class JdPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? label;
  const JdPress({super.key, required this.child, required this.onTap, this.scale = 0.92, this.label});
  @override
  State<JdPress> createState() => _JdPressState();
}

class _JdPressState extends State<JdPress> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: widget.onTap == null
              ? null
              : (_) {
                  setState(() => _down = false);
                  widget.onTap!();
                },
          child: AnimatedScale(scale: _down ? widget.scale : 1, duration: const Duration(milliseconds: 110), child: widget.child),
        ),
      );
}

Widget jdRound(BuildContext c, String sprite, double size, VoidCallback onTap, {bool flipRtl = false, String? label}) => JdPress(
      onTap: onTap,
      label: label,
      child: Transform.flip(flipX: flipRtl && jdRtl(c), child: Image.asset(jd(sprite), width: size, height: size, fit: BoxFit.contain)),
    );

/// Sprite button with a label area given as fractions of the sprite width.
class JdSpriteButton extends StatelessWidget {
  final String sprite;
  final double ratio; // height / width of the sprite
  final double start, end; // label area (fractions of width)
  final String label;
  final String? sub;
  final VoidCallback? onTap;
  final double width;
  final Animation<double>? pulse;
  final Color shadow;
  const JdSpriteButton({
    super.key,
    required this.sprite,
    required this.ratio,
    required this.label,
    required this.onTap,
    required this.width,
    this.start = 0.3,
    this.end = 0.1,
    this.sub,
    this.pulse,
    this.shadow = const Color(0xFFB4410A),
  });

  @override
  Widget build(BuildContext context) {
    final h = width * ratio;
    Widget b = JdPress(
      onTap: onTap,
      label: label,
      child: SizedBox(
        width: width,
        height: h,
        child: Stack(children: [
          Positioned.fill(child: Transform.flip(flipX: jdRtl(context), child: Image.asset(jd(sprite), fit: BoxFit.fill))),
          PositionedDirectional(
            start: width * start,
            end: width * end,
            top: h * 0.08,
            bottom: h * 0.14,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(label,
                      maxLines: 1,
                      style: jdText(h * (sub == null ? 0.4 : 0.32), color: Colors.white, weight: FontWeight.w800)
                          .copyWith(shadows: [Shadow(color: shadow, offset: const Offset(0, 2), blurRadius: 1)])),
                  if (sub != null)
                    Text(sub!, maxLines: 1, style: jdText(h * 0.17, color: Colors.white.withOpacity(0.92), weight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
    if (onTap == null) return Opacity(opacity: 0.55, child: b);
    if (pulse != null) {
      b = AnimatedBuilder(
        animation: pulse!,
        builder: (_, c) => Transform.scale(scale: 1 + 0.025 * sin(pulse!.value * 2 * pi * 4), child: c),
        child: b,
      );
    }
    return b;
  }
}

/// The big orange "▶ Jouer" button.
Widget jdPlay(String label, VoidCallback? onTap, double width, {Animation<double>? pulse, String? sub}) =>
    JdSpriteButton(sprite: onTap == null ? 'jd_btn_dim' : 'jd_btn_go', ratio: 0.2432, start: 0.27, end: 0.12, label: label, onTap: onTap, width: width, pulse: pulse, sub: sub);

/// Orange / teal flat buttons used in dialogs.
class JdFlatButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double width;
  final bool teal;
  const JdFlatButton({super.key, required this.label, required this.onTap, required this.width, this.teal = false});
  @override
  Widget build(BuildContext context) {
    final h = width * 0.3354;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: JdPress(
        onTap: onTap,
        label: label,
        child: SizedBox(
          width: width,
          height: h,
          child: Stack(alignment: Alignment.center, children: [
            Positioned.fill(child: Image.asset(jd(teal ? 'jd_btn_cy' : 'jd_btn_or'), fit: BoxFit.fill)),
            Padding(
              padding: EdgeInsets.fromLTRB(h * 0.4, 0, h * 0.4, h * 0.08),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    style: jdText(h * 0.46, color: Colors.white, weight: FontWeight.w800)
                        .copyWith(shadows: [Shadow(color: teal ? const Color(0xFF0B6F80) : const Color(0xFFB4410A), offset: const Offset(0, 1.5))])),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Cream pill with an icon (or a small picture) and a label.
class JdPill extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final double s;
  final Color border;
  const JdPill({super.key, required this.label, required this.icon, required this.onTap, required this.s, this.border = const Color(0xFF6A3FC4)});
  @override
  Widget build(BuildContext context) => JdPress(
        onTap: onTap,
        label: label,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 7 * s),
          decoration: BoxDecoration(
            color: jdCream,
            borderRadius: BorderRadius.circular(30 * s),
            border: Border.all(color: border, width: 2.4 * s),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6 * s, offset: Offset(0, 3 * s))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            icon,
            SizedBox(width: 8 * s),
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: jdText(16 * s, color: jdInk)))),
          ]),
        ),
      );
}

// ── titles & bubbles ───────────────────────────────────────────────────────

Widget jdOutlined(String t, Color c, double size, {double stroke = 0.16, Color outline = Colors.white, TextAlign align = TextAlign.center}) =>
    Stack(children: [
      Text(t,
          maxLines: 1,
          textAlign: align,
          style: jdText(size, weight: FontWeight.w800).copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * stroke
              ..strokeJoin = StrokeJoin.round
              ..color = outline,
            shadows: [Shadow(color: Colors.black.withOpacity(0.18), offset: Offset(0, size * 0.06), blurRadius: size * 0.05)],
          )),
      Text(t, maxLines: 1, textAlign: align, style: jdText(size, color: c, weight: FontWeight.w800)),
    ]);

/// Leafy wooden plank title — purple first line, teal second line.
class JdTitle extends StatelessWidget {
  final String top, bottom;
  final double width;
  final String? sub; // small plank under the board
  const JdTitle({super.key, required this.top, required this.bottom, required this.width, this.sub});
  @override
  Widget build(BuildContext context) {
    final withSub = sub != null;
    final h = width * (withSub ? 0.428 : 0.3404);
    return SizedBox(
      width: width,
      height: h,
      child: Stack(children: [
        Positioned.fill(child: Image.asset(jd(withSub ? 'jd_title_sub' : 'jd_title_leafy'), fit: BoxFit.fill)),
        Positioned(
          left: width * 0.12,
          right: width * 0.12,
          top: h * (withSub ? 0.1 : 0.14),
          bottom: h * (withSub ? 0.36 : 0.16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              jdOutlined(top, const Color(0xFF6B2BD9), width * 0.105),
              if (bottom.isNotEmpty) Transform.translate(offset: Offset(0, -width * 0.02), child: jdOutlined(bottom, const Color(0xFF14A7B5), width * 0.105)),
            ]),
          ),
        ),
        if (withSub)
          Positioned(
            left: width * 0.3,
            right: width * 0.3,
            bottom: h * 0.08,
            height: h * 0.2,
            child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(sub!, style: jdText(width * 0.055)))),
          ),
      ]),
    );
  }
}

/// Speech bubble: blue with white text, or white with blue text.
class JdBubble extends StatelessWidget {
  final String text;
  final double width;
  final bool white;
  const JdBubble({super.key, required this.text, required this.width, this.white = false});
  @override
  Widget build(BuildContext context) {
    final ratio = white ? 0.5333 : 0.6094;
    return SizedBox(
      width: width,
      height: width * ratio,
      child: Stack(children: [
        Positioned.fill(child: Transform.flip(flipX: jdRtl(context), child: Image.asset(jd(white ? 'jd_bubble_blue' : 'jd_bubble'), fit: BoxFit.fill))),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(width * 0.09, width * ratio * 0.12, width * 0.07, width * ratio * 0.3),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: FittedBox(
                  key: ValueKey(text),
                  fit: BoxFit.scaleDown,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: width * 0.85),
                    child: Text(text,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        style: jdText(width * 0.08, color: Colors.white, weight: FontWeight.w700)
                            .copyWith(shadows: const [Shadow(color: Color(0x66002A80), offset: Offset(0, 1.5))])),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Cream instruction pill with a speaker (reads the text aloud).
class JdSayPill extends StatelessWidget {
  final String text;
  final double width;
  final Widget? trailing;
  const JdSayPill({super.key, required this.text, required this.width, this.trailing});
  @override
  Widget build(BuildContext context) {
    final h = width * 0.3238;
    return JdPress(
      onTap: () => JdVoice.say(context, text),
      scale: 0.97,
      label: text,
      child: SizedBox(
        width: width,
        height: h,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(child: Transform.flip(flipX: jdRtl(context), child: Image.asset(jd('jd_say'), fit: BoxFit.fill))),
          PositionedDirectional(
            start: width * 0.2,
            end: trailing == null ? width * 0.05 : h * 1.05,
            top: h * 0.08,
            bottom: h * 0.28,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(a), child: c)),
                child: FittedBox(
                  key: ValueKey(text),
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: width * 0.7),
                    child: Text(text, maxLines: 2, style: jdText(h * 0.24, height: 1.15)),
                  ),
                ),
              ),
            ),
          ),
          if (trailing != null) PositionedDirectional(end: h * 0.15, top: h * 0.06, bottom: h * 0.3, width: h * 0.8, child: trailing!),
        ]),
      ),
    );
  }
}

/// Text written on a sprite (plank, pill …) inside the given fractional area.
Widget jdOnSprite(String sprite, double width, double ratio, Widget child, {EdgeInsets area = const EdgeInsets.fromLTRB(0.12, 0.2, 0.12, 0.2)}) {
  final h = width * ratio;
  return SizedBox(
    width: width,
    height: h,
    child: Stack(children: [
      Positioned.fill(child: Image.asset(jd(sprite), fit: BoxFit.fill)),
      Positioned(
        left: width * area.left,
        right: width * area.right,
        top: h * area.top,
        bottom: h * area.bottom,
        child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: child)),
      ),
    ]),
  );
}

/// Seeds of a plant: real pictures for the bean and the sunflower, small
/// painted seeds for the others.
class JdSeed extends StatelessWidget {
  final JdPlant plant;
  final double size;
  const JdSeed({super.key, required this.plant, required this.size});
  @override
  Widget build(BuildContext context) {
    if (plant.id == 'bean') return Image.asset(jd('jd_bean'), width: size, height: size, fit: BoxFit.contain);
    if (plant.id == 'sunflower') return Image.asset(jd('jd_seeds_sun'), width: size, height: size, fit: BoxFit.contain);
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _SeedPainter(plant)));
  }
}

class _SeedPainter extends CustomPainter {
  final JdPlant plant;
  _SeedPainter(this.plant);
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(plant.id.hashCode);
    final c = size.center(Offset.zero);
    final small = plant.id == 'carrot' || plant.id == 'basil';
    final n = small ? 9 : 6;
    for (var i = 0; i < n; i++) {
      final a = r.nextDouble() * 2 * pi;
      final d = r.nextDouble() * size.width * 0.26;
      final p = c + Offset(cos(a) * d, sin(a) * d * 0.7);
      final w = size.width * (small ? 0.1 : 0.17), h = w * (plant.id == 'radish' ? 0.9 : 0.62);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(r.nextDouble() * pi);
      final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
      canvas.drawOval(rect.shift(Offset(0, h * 0.25)), Paint()..color = Colors.black.withOpacity(0.18));
      canvas.drawOval(rect, Paint()..color = plant.seedColor);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-w * 0.15, -h * 0.18), width: w * 0.4, height: h * 0.3),
        Paint()..color = Colors.white.withOpacity(0.35),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SeedPainter o) => o.plant != plant;
}

/// Falling leaves & sparkles, driven by a repeating 0→1 value.
class JdLeafRain extends CustomPainter {
  final double t;
  JdLeafRain(this.t);
  static const _c = [Color(0xFF7BCB3C), Color(0xFF3FA34D), Color(0xFFFFC93C), Color(0xFFFF9F43), Color(0xFF58C4F0)];
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(11);
    for (var i = 0; i < 26; i++) {
      final x0 = r.nextDouble() * size.width;
      final speed = 0.6 + r.nextDouble() * 0.8;
      final y = ((t * speed + r.nextDouble()) % 1.0) * (size.height + 60) - 30;
      final x = x0 + sin((t * 2 * pi * 2) + i) * 18;
      final rot = t * 2 * pi * (r.nextBool() ? 1 : -1) + i;
      final w = 9 + r.nextDouble() * 8;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      final p = Path()
        ..moveTo(0, -w)
        ..quadraticBezierTo(w * 0.7, 0, 0, w)
        ..quadraticBezierTo(-w * 0.7, 0, 0, -w)
        ..close();
      canvas.drawPath(p, Paint()..color = _c[i % _c.length].withOpacity(0.9));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(JdLeafRain o) => o.t != t;
}

/// Star burst at the centre of the box, driven by [t] (0→1).
class JdBurst extends CustomPainter {
  final double t;
  final int seed;
  JdBurst(this.t, {this.seed = 3});
  static const _c = [Color(0xFFFFC21A), Color(0xFF7DDB5A), Color(0xFF34D9CF), Color(0xFFFF8FB5), Color(0xFFFFFFFF)];
  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final c = size.center(Offset.zero);
    final r = Random(seed);
    final e = Curves.easeOutCubic.transform(t);
    for (var i = 0; i < 18; i++) {
      final a = i / 18 * 2 * pi + r.nextDouble() * 0.4;
      final d = (0.3 + r.nextDouble() * 0.45) * size.shortestSide * e;
      final p = c + Offset(cos(a), sin(a)) * d;
      final rad = (3 + r.nextDouble() * 4) * (1 - t * 0.5);
      final paint = Paint()..color = _c[i % _c.length].withOpacity((1 - t).clamp(0.0, 1.0));
      final path = Path()
        ..moveTo(p.dx, p.dy - rad * 1.6)
        ..quadraticBezierTo(p.dx, p.dy, p.dx + rad * 1.6, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + rad * 1.6)
        ..quadraticBezierTo(p.dx, p.dy, p.dx - rad * 1.6, p.dy)
        ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - rad * 1.6)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(JdBurst o) => o.t != t;
}

/// Shows a plant pot: coloured when discovered, grey with a lock otherwise.
class JdPot extends StatelessWidget {
  final JdPlant plant;
  final bool locked;
  final double height;
  const JdPot({super.key, required this.plant, required this.height, this.locked = false});
  static const _grey = ColorFilter.matrix(<double>[
    0.33, 0.45, 0.12, 0, 18, //
    0.33, 0.45, 0.12, 0, 18,
    0.33, 0.45, 0.12, 0, 18,
    0, 0, 0, 1, 0,
  ]);
  @override
  Widget build(BuildContext context) {
    final img = Image.asset(plant.pot, height: height, fit: BoxFit.contain);
    if (!locked) return img;
    return Stack(alignment: Alignment.center, children: [
      ColorFiltered(colorFilter: _grey, child: img),
      Positioned(bottom: height * 0.12, child: Image.asset(jd('jd_lock'), height: height * 0.26)),
    ]);
  }
}

// ── text ───────────────────────────────────────────────────────────────────

String jdLang(BuildContext c) {
  final l = Localizations.localeOf(c).languageCode;
  return const ['fr', 'en', 'ar', 'de'].contains(l) ? l : (l == 'zgh' ? 'fr' : 'en');
}

String jdT(BuildContext c, String key, [Map<String, Object>? args]) {
  var s = _s[jdLang(c)]?[key] ?? _s['en']![key] ?? _s['fr']![key] ?? key;
  args?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

String jdTitleFor(String localeName) {
  final code = localeName.split(RegExp('[_-]')).first;
  final lang = _s.containsKey(code) ? code : (code == 'zgh' ? 'fr' : 'en');
  return _s[lang]!['gameName']!;
}

const Map<String, Map<String, String>> _s = {
  'fr': {
    'gameName': 'Mon jardin vivant',
    't1': 'Mon', 't2': 'jardin', 't3': 'vivant', 'tag': 'Une petite graine,\nune grande aventure !',
    'w0': 'Je plante', 'w1': 'Je prends soin', 'w2': 'Je découvre',
    'a0': 'Les premières pousses', 'a1': 'Le potager', 'a2': 'La serre des découvertes',
    'sign0': 'Observer', 'sign1': 'Semer', 'sign2': 'Cultiver',
    'play': 'Jouer', 'choose': 'Choisir un niveau', 'how': 'Comment jouer ?',
    'myGarden': 'Mon jardin :', 'found': '{n} plantes\ndécouvertes',
    'mapTitle1': 'Les sentiers', 'mapTitle2': 'du jardin', 'level': 'Niveau {n}', 'locked': 'Termine le niveau précédent d\'abord !',
    'subWatch': 'Sème, arrose et observe !', 'subParts': 'Découvre les parties de la plante', 'subOrder': 'Range les étapes de la croissance',
    // help
    'h1': 'Sème', 'h2': 'Prends soin', 'h3': 'Observe', 'helpNote': 'Dans le jeu, les plantes poussent plus vite !', 'go': 'C\'est parti !',
    // intro
    'introStep1': 'Sème une graine', 'introStep2': 'Arrose doucement', 'introStep3': 'Observe la pousse',
    'introSay': 'Une graine a besoin de soins pour grandir !', 'fast': 'Dans ce jeu, le temps passe plus vite.', 'toGarden': 'Au jardin !',
    // seed
    'seedT1': 'Choisis ta', 'seedT2': 'graine', 'seedSay': 'Trouve {seed} !', 'seedSayPic': 'Quelle graine donne cette plante ?',
    'seedWrong': 'Oups ! Ce n\'est pas {seed}.', 'plantThis': 'Planter cette graine', 'seedPick': 'Touche un sachet',
    // plant
    'plantT1': 'Je plante', 'step0': 'Creuse', 'step1': 'Sème', 'step2': 'Recouvre',
    'say0': 'Prends la pelle et creuse un petit trou.', 'say1': 'Glisse la graine dans le petit trou.', 'say2': 'Recouvre la graine avec de la terre.',
    'dig': 'Encore ! Creuse un peu plus.', 'wrongTool': 'Pas cet outil ! Regarde l\'étape.', 'stepDone': 'Bravo !',
    'continue': 'Continuer', 'needStep0': 'Creuse d\'abord le trou.', 'needStep1': 'Place d\'abord la graine.', 'needStep2': 'Recouvre d\'abord la graine.',
    'trowel': 'Pelle', 'scoop': 'Terre',
    // care
    'careT1': 'Je prends soin', 'careT2': 'de ma plante', 'water': 'Eau', 'light': 'Lumière',
    'dry': 'Sec', 'humid': 'Humide', 'wet': 'Trop mouillé', 'waterBtn': 'Arroser un peu', 'observe': 'Observer la suite',
    'shade': 'Ombre', 'half': 'Mi-ombre', 'sun': 'Soleil',
    'soilDry': 'La terre est un peu sèche.', 'soilOk': 'La terre est humide, c\'est parfait !', 'soilWet': 'La terre est trempée !',
    'careSay': 'Arrose doucement, puis observe la terre !', 'careSayLight': 'Arrose, puis choisis la bonne lumière !',
    'stillDry': 'La terre est encore sèche. Arrose encore un peu !', 'chooseLight': 'Choisis où mettre ta plante.',
    'lightFixed': 'Aujourd\'hui, la plante est déjà au bon endroit.', 'day': 'Jour {d} / {n}', 'nextDay': 'Le lendemain…',
    'fastNote': 'Croissance accélérée dans le jeu.', 'dried': 'La terre a séché pendant la nuit.',
    // grow
    'growT1': 'Regarde,', 'growT2': 'ça pousse !', 'above': 'Au-dessus', 'under': 'Sous la terre',
    'leaves': 'Les feuilles', 'stem': 'La tige', 'roots': 'Les racines',
    'sayLeaves': 'Les feuilles attrapent la lumière du soleil.', 'sayStem': 'La tige porte les feuilles vers la lumière.',
    'sayRoots': 'Les racines absorbent l\'eau dans la terre.',
    'st0': 'Graine', 'st1': 'Racine', 'st2': 'Pousse', 'st3': 'Feuilles',
    'watchFast': 'Voir la croissance\nen accéléré', 'grew': 'Ma plante a grandi !', 'realDays': 'Croissance accélérée · En vrai, il faut plusieurs jours.',
    'watchFirst': 'Regarde d\'abord la croissance !', 'touch': 'Touche : {part}', 'goodPart': 'Oui ! {part} !', 'wrongPart': 'Non, cherche encore !',
    'orderSay': 'Touche les étapes dans le bon ordre !', 'orderWrong': 'Pas encore ! Quelle étape vient avant ?', 'orderDone': 'Bravo, tout est dans l\'ordre !',
    // dialogs
    'wellDone': 'Bien joué !', 'justRight': 'La terre est juste assez humide.', 'tooWet': 'Un peu trop d\'eau', 'tooWetSub': 'Arrête d\'arroser et laisse la terre sécher.',
    'watch': 'Observer', 'hint': 'Un indice', 'hintTitle': 'Un petit indice', 'understood': 'J\'ai compris !',
    'hintLight': 'Les feuilles ont besoin de lumière.', 'hintHalf': 'Cette plante aime un peu d\'ombre.', 'hintWater': 'Arrose jusqu\'à la zone verte « Humide ».',
    'hintSeed': 'Regarde bien le dessin sur le sachet.', 'hintPlant': 'Fais glisser le bon outil sur le pot.', 'hintGrow': 'Graine → Racine → Pousse → Feuilles',
    'pause': 'Petite pause', 'pauseSub': 'Fais une pause, ton jardin t\'attend !', 'resume': 'Reprendre', 'restart': 'Recommencer', 'map': 'Carte des niveaux',
    'quitQ': 'Retour à la carte ?', 'quitSub': 'Ce niveau recommencera au début.', 'keep': 'Continuer à jouer', 'quit': 'Quitter le niveau',
    // end
    'bravo1': 'Bravo,', 'bravo2': 'petit jardinier !', 'c0': 'Graine bien semée', 'c1': 'Arrosage adapté', 'c2': 'Bonne lumière',
    'rewards': 'Tes récompenses', 'badge': 'Badge débloqué', 'badgeName': 'Petite main verte', 'newPlant': 'Nouvelle plante !',
    'next': 'Niveau suivant', 'seeGarden': 'Voir mon jardin', 'again': 'Rejouer', 'allDone': 'Tu as fini tout le jardin !',
    // garden
    'gardenT1': 'Mon', 'gardenT2': 'jardin', 'gardenCount': '{n} plantes découvertes sur 6', 'new': 'Nouveau', 'replayGrow': 'Revoir sa croissance',
    'gardenGrows': 'Ton jardin grandit avec toi !', 'plantNew': 'Planter une nouvelle graine', 'lockedPlant': 'Plante encore cachée… Continue à jouer !',
    // plants
    'bean': 'Haricot', 'bean_my': 'Mon haricot', 'bean_the': 'Le haricot', 'bean_seed': 'la graine de haricot', 'bean_grown': 'Ton haricot a bien grandi !',
    'bean_fact': 'Une graine peut devenir une nouvelle plante.',
    'sunflower': 'Tournesol', 'sunflower_my': 'Mon tournesol', 'sunflower_the': 'Le tournesol', 'sunflower_seed': 'la graine de tournesol',
    'sunflower_grown': 'Ton tournesol a bien grandi !', 'sunflower_fact': 'Le tournesol tourne sa fleur vers le soleil.',
    'radish': 'Radis', 'radish_my': 'Mon radis', 'radish_the': 'Le radis', 'radish_seed': 'la graine de radis', 'radish_grown': 'Ton radis a bien grandi !',
    'radish_fact': 'Le radis pousse très vite, et on mange sa racine !',
    'basil': 'Basilic', 'basil_my': 'Mon basilic', 'basil_the': 'Le basilic', 'basil_seed': 'la graine de basilic', 'basil_grown': 'Ton basilic a bien grandi !',
    'basil_fact': 'Le basilic sent très bon et aime la chaleur.',
    'tomato': 'Tomate', 'tomato_my': 'Ma tomate', 'tomato_the': 'La tomate', 'tomato_seed': 'la graine de tomate', 'tomato_grown': 'Ta tomate a bien grandi !',
    'tomato_fact': 'La tomate a besoin de beaucoup de soleil pour rougir.',
    'carrot': 'Carotte', 'carrot_my': 'Ma carotte', 'carrot_the': 'La carotte', 'carrot_seed': 'la graine de carotte', 'carrot_grown': 'Ta carotte a bien grandi !',
    'carrot_fact': 'La carotte est une racine qui pousse sous la terre.',
  },
  'en': {
    'gameName': 'My Living Garden',
    't1': 'My', 't2': 'living', 't3': 'garden', 'tag': 'A tiny seed,\na big adventure!',
    'w0': 'I plant', 'w1': 'I take care', 'w2': 'I discover',
    'a0': 'First sprouts', 'a1': 'The vegetable patch', 'a2': 'Discovery greenhouse',
    'sign0': 'Observe', 'sign1': 'Sow', 'sign2': 'Grow',
    'play': 'Play', 'choose': 'Choose a level', 'how': 'How to play?',
    'myGarden': 'My garden:', 'found': '{n} plants\ndiscovered',
    'mapTitle1': 'Garden', 'mapTitle2': 'paths', 'level': 'Level {n}', 'locked': 'Finish the previous level first!',
    'subWatch': 'Sow, water and watch!', 'subParts': 'Discover the parts of the plant', 'subOrder': 'Put the growth steps in order',
    'h1': 'Sow', 'h2': 'Take care', 'h3': 'Observe', 'helpNote': 'In the game, plants grow faster!', 'go': 'Let\'s go!',
    'introStep1': 'Sow a seed', 'introStep2': 'Water gently', 'introStep3': 'Watch it sprout',
    'introSay': 'A seed needs care to grow!', 'fast': 'In this game, time goes faster.', 'toGarden': 'To the garden!',
    'seedT1': 'Choose your', 'seedT2': 'seed', 'seedSay': 'Find {seed}!', 'seedSayPic': 'Which seed gives this plant?',
    'seedWrong': 'Oops! That is not {seed}.', 'plantThis': 'Plant this seed', 'seedPick': 'Tap a packet',
    'plantT1': 'I plant', 'step0': 'Dig', 'step1': 'Sow', 'step2': 'Cover',
    'say0': 'Take the trowel and dig a small hole.', 'say1': 'Drop the seed into the little hole.', 'say2': 'Cover the seed with soil.',
    'dig': 'Again! Dig a bit more.', 'wrongTool': 'Not this tool! Look at the step.', 'stepDone': 'Well done!',
    'continue': 'Continue', 'needStep0': 'Dig the hole first.', 'needStep1': 'Place the seed first.', 'needStep2': 'Cover the seed first.',
    'trowel': 'Trowel', 'scoop': 'Soil',
    'careT1': 'I take care', 'careT2': 'of my plant', 'water': 'Water', 'light': 'Light',
    'dry': 'Dry', 'humid': 'Moist', 'wet': 'Too wet', 'waterBtn': 'Water a little', 'observe': 'See what happens',
    'shade': 'Shade', 'half': 'Half-shade', 'sun': 'Sun',
    'soilDry': 'The soil is a bit dry.', 'soilOk': 'The soil is moist, perfect!', 'soilWet': 'The soil is soaked!',
    'careSay': 'Water gently, then look at the soil!', 'careSayLight': 'Water, then choose the right light!',
    'stillDry': 'The soil is still dry. Water a little more!', 'chooseLight': 'Choose where to put your plant.',
    'lightFixed': 'Today the plant is already in the right place.', 'day': 'Day {d} / {n}', 'nextDay': 'The next day…',
    'fastNote': 'Growth is faster in the game.', 'dried': 'The soil dried during the night.',
    'growT1': 'Look,', 'growT2': 'it\'s growing!', 'above': 'Above', 'under': 'Under the soil',
    'leaves': 'The leaves', 'stem': 'The stem', 'roots': 'The roots',
    'sayLeaves': 'The leaves catch the sunlight.', 'sayStem': 'The stem carries the leaves up to the light.',
    'sayRoots': 'The roots drink water from the soil.',
    'st0': 'Seed', 'st1': 'Root', 'st2': 'Sprout', 'st3': 'Leaves',
    'watchFast': 'Watch it grow\nfast', 'grew': 'My plant has grown!', 'realDays': 'Fast growth · In real life it takes several days.',
    'watchFirst': 'Watch it grow first!', 'touch': 'Touch: {part}', 'goodPart': 'Yes! {part}!', 'wrongPart': 'No, look again!',
    'orderSay': 'Touch the steps in the right order!', 'orderWrong': 'Not yet! Which step comes before?', 'orderDone': 'Great, everything is in order!',
    'wellDone': 'Well done!', 'justRight': 'The soil is just moist enough.', 'tooWet': 'A bit too much water', 'tooWetSub': 'Stop watering and let the soil dry.',
    'watch': 'Observe', 'hint': 'A hint', 'hintTitle': 'A little hint', 'understood': 'Got it!',
    'hintLight': 'Leaves need light.', 'hintHalf': 'This plant likes a little shade.', 'hintWater': 'Water until the green "Moist" zone.',
    'hintSeed': 'Look closely at the picture on the packet.', 'hintPlant': 'Drag the right tool onto the pot.', 'hintGrow': 'Seed → Root → Sprout → Leaves',
    'pause': 'Little break', 'pauseSub': 'Take a break, your garden is waiting!', 'resume': 'Resume', 'restart': 'Restart', 'map': 'Level map',
    'quitQ': 'Back to the map?', 'quitSub': 'This level will start again.', 'keep': 'Keep playing', 'quit': 'Leave the level',
    'bravo1': 'Well done,', 'bravo2': 'little gardener!', 'c0': 'Seed well sown', 'c1': 'Right watering', 'c2': 'Good light',
    'rewards': 'Your rewards', 'badge': 'Badge unlocked', 'badgeName': 'Little green thumb', 'newPlant': 'New plant!',
    'next': 'Next level', 'seeGarden': 'See my garden', 'again': 'Play again', 'allDone': 'You finished the whole garden!',
    'gardenT1': 'My', 'gardenT2': 'garden', 'gardenCount': '{n} of 6 plants discovered', 'new': 'New', 'replayGrow': 'Watch it grow again',
    'gardenGrows': 'Your garden grows with you!', 'plantNew': 'Plant a new seed', 'lockedPlant': 'Still hidden… keep playing!',
    'bean': 'Bean', 'bean_my': 'My bean', 'bean_the': 'The bean', 'bean_seed': 'the bean seed', 'bean_grown': 'Your bean has grown!',
    'bean_fact': 'A seed can become a whole new plant.',
    'sunflower': 'Sunflower', 'sunflower_my': 'My sunflower', 'sunflower_the': 'The sunflower', 'sunflower_seed': 'the sunflower seed',
    'sunflower_grown': 'Your sunflower has grown!', 'sunflower_fact': 'The sunflower turns its flower towards the sun.',
    'radish': 'Radish', 'radish_my': 'My radish', 'radish_the': 'The radish', 'radish_seed': 'the radish seed', 'radish_grown': 'Your radish has grown!',
    'radish_fact': 'Radishes grow very fast, and we eat their root!',
    'basil': 'Basil', 'basil_my': 'My basil', 'basil_the': 'Basil', 'basil_seed': 'the basil seed', 'basil_grown': 'Your basil has grown!',
    'basil_fact': 'Basil smells lovely and likes warm weather.',
    'tomato': 'Tomato', 'tomato_my': 'My tomato', 'tomato_the': 'The tomato', 'tomato_seed': 'the tomato seed', 'tomato_grown': 'Your tomato has grown!',
    'tomato_fact': 'Tomatoes need lots of sun to turn red.',
    'carrot': 'Carrot', 'carrot_my': 'My carrot', 'carrot_the': 'The carrot', 'carrot_seed': 'the carrot seed', 'carrot_grown': 'Your carrot has grown!',
    'carrot_fact': 'A carrot is a root that grows under the soil.',
  },
  'ar': {
    'gameName': 'حديقتي الحيّة',
    't1': 'حديقتي', 't2': 'الحيّة', 't3': '', 'tag': 'بذرة صغيرة،\nمغامرة كبيرة!',
    'w0': 'أزرع', 'w1': 'أعتني', 'w2': 'أكتشف',
    'a0': 'البراعم الأولى', 'a1': 'حديقة الخضر', 'a2': 'بيت الاكتشافات',
    'sign0': 'ألاحظ', 'sign1': 'أزرع', 'sign2': 'أعتني',
    'play': 'العب', 'choose': 'اختر مستوى', 'how': 'كيف ألعب؟',
    'myGarden': 'حديقتي:', 'found': '{n} نباتات\nمكتشفة',
    'mapTitle1': 'ممرات', 'mapTitle2': 'الحديقة', 'level': 'المستوى {n}', 'locked': 'أكمل المستوى السابق أولاً!',
    'subWatch': 'ازرع، اسقِ ولاحظ!', 'subParts': 'اكتشف أجزاء النبتة', 'subOrder': 'رتّب مراحل النمو',
    'h1': 'أزرع', 'h2': 'أعتني', 'h3': 'ألاحظ', 'helpNote': 'في اللعبة، تنمو النباتات بسرعة أكبر!', 'go': 'هيا بنا!',
    'introStep1': 'ازرع بذرة', 'introStep2': 'اسقِ بلطف', 'introStep3': 'لاحظ البرعم',
    'introSay': 'البذرة تحتاج إلى عناية لتكبر!', 'fast': 'في هذه اللعبة، يمر الوقت بسرعة.', 'toGarden': 'إلى الحديقة!',
    'seedT1': 'اختر', 'seedT2': 'بذرتك', 'seedSay': 'ابحث عن {seed}!', 'seedSayPic': 'أي بذرة تعطي هذه النبتة؟',
    'seedWrong': 'أوه! هذه ليست {seed}.', 'plantThis': 'ازرع هذه البذرة', 'seedPick': 'المس كيساً',
    'plantT1': 'أزرع', 'step0': 'أحفر', 'step1': 'أزرع', 'step2': 'أغطّي',
    'say0': 'خذ المجرفة واحفر حفرة صغيرة.', 'say1': 'ضع البذرة في الحفرة الصغيرة.', 'say2': 'غطِّ البذرة بالتراب.',
    'dig': 'مرة أخرى! احفر قليلاً.', 'wrongTool': 'ليست هذه الأداة! انظر إلى المرحلة.', 'stepDone': 'أحسنت!',
    'continue': 'تابع', 'needStep0': 'احفر الحفرة أولاً.', 'needStep1': 'ضع البذرة أولاً.', 'needStep2': 'غطِّ البذرة أولاً.',
    'trowel': 'مجرفة', 'scoop': 'تراب',
    'careT1': 'أعتني', 'careT2': 'بنبتتي', 'water': 'الماء', 'light': 'الضوء',
    'dry': 'جاف', 'humid': 'رطب', 'wet': 'مبلل جداً', 'waterBtn': 'اسقِ قليلاً', 'observe': 'لاحظ ما يحدث',
    'shade': 'ظل', 'half': 'نصف ظل', 'sun': 'شمس',
    'soilDry': 'التراب جاف قليلاً.', 'soilOk': 'التراب رطب، ممتاز!', 'soilWet': 'التراب مبلل جداً!',
    'careSay': 'اسقِ بلطف، ثم لاحظ التراب!', 'careSayLight': 'اسقِ، ثم اختر الضوء المناسب!',
    'stillDry': 'التراب ما زال جافاً. اسقِ قليلاً!', 'chooseLight': 'اختر أين تضع نبتتك.',
    'lightFixed': 'اليوم النبتة في المكان المناسب.', 'day': 'اليوم {d} / {n}', 'nextDay': 'في اليوم التالي…',
    'fastNote': 'النمو أسرع في اللعبة.', 'dried': 'جفّ التراب خلال الليل.',
    'growT1': 'انظر،', 'growT2': 'إنها تنمو!', 'above': 'فوق التراب', 'under': 'تحت التراب',
    'leaves': 'الأوراق', 'stem': 'الساق', 'roots': 'الجذور',
    'sayLeaves': 'الأوراق تلتقط ضوء الشمس.', 'sayStem': 'الساق تحمل الأوراق نحو الضوء.', 'sayRoots': 'الجذور تمتص الماء من التراب.',
    'st0': 'بذرة', 'st1': 'جذر', 'st2': 'برعم', 'st3': 'أوراق',
    'watchFast': 'شاهد النمو\nبسرعة', 'grew': 'نبتتي كبرت!', 'realDays': 'نمو سريع · في الحقيقة يحتاج عدة أيام.',
    'watchFirst': 'شاهد النمو أولاً!', 'touch': 'المس: {part}', 'goodPart': 'نعم! {part}!', 'wrongPart': 'لا، ابحث مرة أخرى!',
    'orderSay': 'المس المراحل بالترتيب الصحيح!', 'orderWrong': 'ليس بعد! أي مرحلة تأتي قبل؟', 'orderDone': 'رائع، كل شيء مرتب!',
    'wellDone': 'أحسنت!', 'justRight': 'التراب رطب بالقدر المناسب.', 'tooWet': 'ماء كثير قليلاً', 'tooWetSub': 'توقف عن السقي واترك التراب يجف.',
    'watch': 'لاحظ', 'hint': 'تلميح', 'hintTitle': 'تلميح صغير', 'understood': 'فهمت!',
    'hintLight': 'الأوراق تحتاج إلى الضوء.', 'hintHalf': 'هذه النبتة تحب قليلاً من الظل.', 'hintWater': 'اسقِ حتى المنطقة الخضراء «رطب».',
    'hintSeed': 'انظر جيداً إلى الصورة على الكيس.', 'hintPlant': 'اسحب الأداة الصحيحة إلى الأصيص.', 'hintGrow': 'بذرة ← جذر ← برعم ← أوراق',
    'pause': 'استراحة صغيرة', 'pauseSub': 'استرح، حديقتك تنتظرك!', 'resume': 'تابع', 'restart': 'من جديد', 'map': 'خريطة المستويات',
    'quitQ': 'العودة إلى الخريطة؟', 'quitSub': 'سيبدأ هذا المستوى من جديد.', 'keep': 'تابع اللعب', 'quit': 'غادر المستوى',
    'bravo1': 'برافو،', 'bravo2': 'أيها البستاني الصغير!', 'c0': 'بذرة مزروعة جيداً', 'c1': 'سقي مناسب', 'c2': 'ضوء جيد',
    'rewards': 'مكافآتك', 'badge': 'شارة جديدة', 'badgeName': 'اليد الخضراء الصغيرة', 'newPlant': 'نبتة جديدة!',
    'next': 'المستوى التالي', 'seeGarden': 'شاهد حديقتي', 'again': 'العب مجدداً', 'allDone': 'أكملت الحديقة كلها!',
    'gardenT1': 'حديقتي', 'gardenT2': '', 'gardenCount': '{n} من 6 نباتات مكتشفة', 'new': 'جديد', 'replayGrow': 'شاهد نموها مجدداً',
    'gardenGrows': 'حديقتك تكبر معك!', 'plantNew': 'ازرع بذرة جديدة', 'lockedPlant': 'ما زالت مخفية… تابع اللعب!',
    'bean': 'فاصوليا', 'bean_my': 'فاصوليتي', 'bean_the': 'الفاصوليا', 'bean_seed': 'بذرة الفاصوليا', 'bean_grown': 'فاصوليتك كبرت!',
    'bean_fact': 'البذرة يمكن أن تصبح نبتة جديدة.',
    'sunflower': 'دوار الشمس', 'sunflower_my': 'دوار الشمس خاصتي', 'sunflower_the': 'دوار الشمس', 'sunflower_seed': 'بذرة دوار الشمس',
    'sunflower_grown': 'دوار الشمس كبر!', 'sunflower_fact': 'دوار الشمس يدير زهرته نحو الشمس.',
    'radish': 'فجل', 'radish_my': 'فجلي', 'radish_the': 'الفجل', 'radish_seed': 'بذرة الفجل', 'radish_grown': 'فجلك كبر!',
    'radish_fact': 'الفجل ينمو بسرعة، ونأكل جذره!',
    'basil': 'ريحان', 'basil_my': 'ريحاني', 'basil_the': 'الريحان', 'basil_seed': 'بذرة الريحان', 'basil_grown': 'ريحانك كبر!',
    'basil_fact': 'الريحان رائحته طيبة ويحب الدفء.',
    'tomato': 'طماطم', 'tomato_my': 'طماطمي', 'tomato_the': 'الطماطم', 'tomato_seed': 'بذرة الطماطم', 'tomato_grown': 'طماطمك كبرت!',
    'tomato_fact': 'الطماطم تحتاج إلى الكثير من الشمس لتحمرّ.',
    'carrot': 'جزر', 'carrot_my': 'جزرتي', 'carrot_the': 'الجزر', 'carrot_seed': 'بذرة الجزر', 'carrot_grown': 'جزرتك كبرت!',
    'carrot_fact': 'الجزرة جذر ينمو تحت التراب.',
  },
  'de': {
    'gameName': 'Mein lebendiger Garten',
    't1': 'Mein', 't2': 'lebendiger', 't3': 'Garten', 'tag': 'Ein kleiner Samen,\nein großes Abenteuer!',
    'w0': 'Ich pflanze', 'w1': 'Ich pflege', 'w2': 'Ich entdecke',
    'a0': 'Erste Sprossen', 'a1': 'Der Gemüsegarten', 'a2': 'Das Entdecker-Gewächshaus',
    'sign0': 'Beobachten', 'sign1': 'Säen', 'sign2': 'Pflegen',
    'play': 'Spielen', 'choose': 'Level wählen', 'how': 'Wie spielt man?',
    'myGarden': 'Mein Garten:', 'found': '{n} Pflanzen\nentdeckt',
    'mapTitle1': 'Die Gartenwege', 'mapTitle2': '', 'level': 'Level {n}', 'locked': 'Schaffe zuerst das vorige Level!',
    'subWatch': 'Säen, gießen und beobachten!', 'subParts': 'Entdecke die Teile der Pflanze', 'subOrder': 'Ordne die Wachstumsschritte',
    'h1': 'Säen', 'h2': 'Pflegen', 'h3': 'Beobachten', 'helpNote': 'Im Spiel wachsen Pflanzen schneller!', 'go': 'Los geht\'s!',
    'introStep1': 'Säe einen Samen', 'introStep2': 'Gieße sanft', 'introStep3': 'Beobachte den Spross',
    'introSay': 'Ein Samen braucht Pflege, um zu wachsen!', 'fast': 'In diesem Spiel vergeht die Zeit schneller.', 'toGarden': 'Ab in den Garten!',
    'seedT1': 'Wähle deinen', 'seedT2': 'Samen', 'seedSay': 'Finde {seed}!', 'seedSayPic': 'Welcher Samen wird zu dieser Pflanze?',
    'seedWrong': 'Hoppla! Das ist nicht {seed}.', 'plantThis': 'Diesen Samen pflanzen', 'seedPick': 'Tippe auf eine Tüte',
    'plantT1': 'Ich pflanze', 'step0': 'Graben', 'step1': 'Säen', 'step2': 'Zudecken',
    'say0': 'Nimm die Schaufel und grabe ein kleines Loch.', 'say1': 'Leg den Samen in das kleine Loch.', 'say2': 'Bedecke den Samen mit Erde.',
    'dig': 'Nochmal! Grab ein bisschen mehr.', 'wrongTool': 'Nicht dieses Werkzeug! Schau auf den Schritt.', 'stepDone': 'Super!',
    'continue': 'Weiter', 'needStep0': 'Grab zuerst das Loch.', 'needStep1': 'Leg zuerst den Samen hinein.', 'needStep2': 'Bedecke zuerst den Samen.',
    'trowel': 'Schaufel', 'scoop': 'Erde',
    'careT1': 'Ich pflege', 'careT2': 'meine Pflanze', 'water': 'Wasser', 'light': 'Licht',
    'dry': 'Trocken', 'humid': 'Feucht', 'wet': 'Zu nass', 'waterBtn': 'Ein wenig gießen', 'observe': 'Weiter beobachten',
    'shade': 'Schatten', 'half': 'Halbschatten', 'sun': 'Sonne',
    'soilDry': 'Die Erde ist etwas trocken.', 'soilOk': 'Die Erde ist feucht, perfekt!', 'soilWet': 'Die Erde ist klatschnass!',
    'careSay': 'Gieße sanft und schau dir die Erde an!', 'careSayLight': 'Gieße und wähle das richtige Licht!',
    'stillDry': 'Die Erde ist noch trocken. Gieß noch ein wenig!', 'chooseLight': 'Wähle, wo deine Pflanze stehen soll.',
    'lightFixed': 'Heute steht die Pflanze schon am richtigen Platz.', 'day': 'Tag {d} / {n}', 'nextDay': 'Am nächsten Tag…',
    'fastNote': 'Im Spiel wächst alles schneller.', 'dried': 'Die Erde ist in der Nacht getrocknet.',
    'growT1': 'Schau,', 'growT2': 'es wächst!', 'above': 'Oben', 'under': 'Unter der Erde',
    'leaves': 'Die Blätter', 'stem': 'Der Stiel', 'roots': 'Die Wurzeln',
    'sayLeaves': 'Die Blätter fangen das Sonnenlicht ein.', 'sayStem': 'Der Stiel trägt die Blätter zum Licht.', 'sayRoots': 'Die Wurzeln trinken Wasser aus der Erde.',
    'st0': 'Samen', 'st1': 'Wurzel', 'st2': 'Spross', 'st3': 'Blätter',
    'watchFast': 'Wachstum im\nZeitraffer', 'grew': 'Meine Pflanze ist gewachsen!', 'realDays': 'Zeitraffer · In echt dauert es mehrere Tage.',
    'watchFirst': 'Schau dir zuerst das Wachstum an!', 'touch': 'Tippe auf: {part}', 'goodPart': 'Ja! {part}!', 'wrongPart': 'Nein, such noch einmal!',
    'orderSay': 'Tippe die Schritte in der richtigen Reihenfolge!', 'orderWrong': 'Noch nicht! Welcher Schritt kommt davor?', 'orderDone': 'Super, alles in der richtigen Reihenfolge!',
    'wellDone': 'Gut gemacht!', 'justRight': 'Die Erde ist genau feucht genug.', 'tooWet': 'Ein bisschen zu viel Wasser', 'tooWetSub': 'Hör auf zu gießen und lass die Erde trocknen.',
    'watch': 'Beobachten', 'hint': 'Ein Tipp', 'hintTitle': 'Ein kleiner Tipp', 'understood': 'Verstanden!',
    'hintLight': 'Blätter brauchen Licht.', 'hintHalf': 'Diese Pflanze mag ein bisschen Schatten.', 'hintWater': 'Gieße bis zur grünen Zone „Feucht“.',
    'hintSeed': 'Schau dir das Bild auf der Tüte genau an.', 'hintPlant': 'Zieh das richtige Werkzeug auf den Topf.', 'hintGrow': 'Samen → Wurzel → Spross → Blätter',
    'pause': 'Kleine Pause', 'pauseSub': 'Mach eine Pause, dein Garten wartet!', 'resume': 'Weiter', 'restart': 'Neu starten', 'map': 'Levelkarte',
    'quitQ': 'Zurück zur Karte?', 'quitSub': 'Dieses Level beginnt dann von vorn.', 'keep': 'Weiterspielen', 'quit': 'Level verlassen',
    'bravo1': 'Bravo,', 'bravo2': 'kleiner Gärtner!', 'c0': 'Samen gut gesät', 'c1': 'Richtig gegossen', 'c2': 'Gutes Licht',
    'rewards': 'Deine Belohnungen', 'badge': 'Abzeichen', 'badgeName': 'Kleiner grüner Daumen', 'newPlant': 'Neue Pflanze!',
    'next': 'Nächstes Level', 'seeGarden': 'Mein Garten', 'again': 'Nochmal', 'allDone': 'Du hast den ganzen Garten geschafft!',
    'gardenT1': 'Mein', 'gardenT2': 'Garten', 'gardenCount': '{n} von 6 Pflanzen entdeckt', 'new': 'Neu', 'replayGrow': 'Wachstum nochmal ansehen',
    'gardenGrows': 'Dein Garten wächst mit dir!', 'plantNew': 'Neuen Samen pflanzen', 'lockedPlant': 'Noch versteckt… spiel weiter!',
    'bean': 'Bohne', 'bean_my': 'Meine Bohne', 'bean_the': 'Die Bohne', 'bean_seed': 'den Bohnensamen', 'bean_grown': 'Deine Bohne ist gewachsen!',
    'bean_fact': 'Aus einem Samen kann eine neue Pflanze werden.',
    'sunflower': 'Sonnenblume', 'sunflower_my': 'Meine Sonnenblume', 'sunflower_the': 'Die Sonnenblume', 'sunflower_seed': 'den Sonnenblumensamen',
    'sunflower_grown': 'Deine Sonnenblume ist gewachsen!', 'sunflower_fact': 'Die Sonnenblume dreht ihre Blüte zur Sonne.',
    'radish': 'Radieschen', 'radish_my': 'Mein Radieschen', 'radish_the': 'Das Radieschen', 'radish_seed': 'den Radieschensamen',
    'radish_grown': 'Dein Radieschen ist gewachsen!', 'radish_fact': 'Radieschen wachsen sehr schnell – wir essen ihre Wurzel!',
    'basil': 'Basilikum', 'basil_my': 'Mein Basilikum', 'basil_the': 'Das Basilikum', 'basil_seed': 'den Basilikumsamen',
    'basil_grown': 'Dein Basilikum ist gewachsen!', 'basil_fact': 'Basilikum duftet gut und mag es warm.',
    'tomato': 'Tomate', 'tomato_my': 'Meine Tomate', 'tomato_the': 'Die Tomate', 'tomato_seed': 'den Tomatensamen', 'tomato_grown': 'Deine Tomate ist gewachsen!',
    'tomato_fact': 'Tomaten brauchen viel Sonne, um rot zu werden.',
    'carrot': 'Karotte', 'carrot_my': 'Meine Karotte', 'carrot_the': 'Die Karotte', 'carrot_seed': 'den Karottensamen', 'carrot_grown': 'Deine Karotte ist gewachsen!',
    'carrot_fact': 'Die Karotte ist eine Wurzel, die unter der Erde wächst.',
  },
};


// ── fun: self-animating helpers ────────────────────────────────────────────

/// Gently floats (and optionally tilts) its child forever.
class JdFloat extends StatefulWidget {
  final Widget child;
  final double amp, tilt, scale;
  final Duration period;
  final double phase;
  const JdFloat({super.key, required this.child, this.amp = 4, this.tilt = 0, this.scale = 0, this.period = const Duration(milliseconds: 2400), this.phase = 0});
  @override
  State<JdFloat> createState() => _JdFloatState();
}

class _JdFloatState extends State<JdFloat> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, ch) {
          final v = sin((_c.value + widget.phase) * 2 * pi);
          return Transform.translate(
            offset: Offset(0, v * widget.amp),
            child: Transform.rotate(angle: v * widget.tilt, child: Transform.scale(scale: 1 + v * widget.scale, child: ch)),
          );
        },
        child: widget.child,
      );
}

/// Pops its child in with a springy bounce the first time it is built.
class JdPopIn extends StatelessWidget {
  final Widget child;
  final int delayMs;
  const JdPopIn({super.key, required this.child, this.delayMs = 0});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 650 + delayMs),
        curve: Interval(delayMs / (650 + delayMs), 1, curve: Curves.elasticOut),
        builder: (_, v, c) => Transform.scale(scale: v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: c)),
        child: child,
      );
}

/// Slow drifting leaves in the background of every screen.
class JdAmbientLeaves extends StatefulWidget {
  final int count;
  const JdAmbientLeaves({super.key, this.count = 10});
  @override
  State<JdAmbientLeaves> createState() => _JdAmbientLeavesState();
}

class _JdAmbientLeavesState extends State<JdAmbientLeaves> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(painter: _AmbientPainter(_c.value, widget.count), size: Size.infinite)),
      );
}

class _AmbientPainter extends CustomPainter {
  final double t;
  final int n;
  _AmbientPainter(this.t, this.n);
  static const _c = [Color(0xFF7BCB3C), Color(0xFF4FB84A), Color(0xFFFFD34D), Color(0xFFFFFFFF)];
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(5);
    for (var i = 0; i < n; i++) {
      final speed = 0.5 + r.nextDouble() * 0.7;
      final y = ((t * speed + r.nextDouble()) % 1.0) * (size.height + 40) - 20;
      final x = r.nextDouble() * size.width + sin((t * 6 + i) * pi) * 22;
      final w = 6 + r.nextDouble() * 7;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 2 * pi * 3 * (i.isEven ? 1 : -1) + i);
      final col = _c[i % _c.length];
      if (col == const Color(0xFFFFFFFF)) {
        // little sparkle
        canvas.drawCircle(Offset.zero, w * 0.35, Paint()..color = Colors.white.withOpacity(0.7));
      } else {
        final p = Path()
          ..moveTo(0, -w)
          ..quadraticBezierTo(w * 0.7, 0, 0, w)
          ..quadraticBezierTo(-w * 0.7, 0, 0, -w)
          ..close();
        canvas.drawPath(p, Paint()..color = col.withOpacity(0.55));
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter o) => o.t != t;
}

/// "Bravo !" moment: Waki pops up with a thumbs-up and a burst of leaves.
Future<void> jdCheer(BuildContext context, String text, {String robot = 'jd_rb_thumb'}) async {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  late OverlayEntry e;
  e = OverlayEntry(builder: (_) => _CheerOverlay(text: text, robot: robot, onDone: () => e.remove()));
  overlay.insert(e);
}

class _CheerOverlay extends StatefulWidget {
  final String text, robot;
  final VoidCallback onDone;
  const _CheerOverlay({required this.text, required this.robot, required this.onDone});
  @override
  State<_CheerOverlay> createState() => _CheerOverlayState();
}

class _CheerOverlayState extends State<_CheerOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))
    ..forward().whenComplete(() => widget.onDone());
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = min(size.width, 420.0);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;
          final inT = Curves.elasticOut.transform((t / 0.45).clamp(0.0, 1.0));
          final out = t > 0.8 ? (1 - (t - 0.8) / 0.2) : 1.0;
          return Opacity(
            opacity: out.clamp(0.0, 1.0),
            child: Stack(children: [
              Positioned.fill(child: CustomPaint(painter: JdBurst(t, seed: 11))),
              Positioned(
                left: (size.width - w * 0.62) / 2,
                top: size.height * 0.3,
                width: w * 0.62,
                child: Transform.scale(
                  scale: inT,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Material(
                      type: MaterialType.transparency,
                      child: jdOutlined(widget.text, const Color(0xFF2E9E3E), w * 0.11, outline: Colors.white, stroke: 0.2),
                    ),
                    Image.asset(jd(widget.robot), width: w * 0.42),
                  ]),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}
