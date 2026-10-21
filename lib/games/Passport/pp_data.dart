import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pp_strings.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Le passeport magique — travel the world with Waki.
// Each stage ("escale"): observe a monument → find 3 details → rebuild the
// postcard → stamp the passport.
// ═══════════════════════════════════════════════════════════════════════════

const String ppDir = 'assets/images/Games/Passport/';
String pp(String n) => '$ppDir$n.webp';

const Color ppInk = Color(0xFF3B1A9A);
const Color ppInkSoft = Color(0xFF5E4E8E);
const Color ppOrange = Color(0xFFF26B1D);
const Color ppGold = Color(0xFFFFB21A);
const Color ppTeal = Color(0xFF13A6B8);
const Color ppGreen = Color(0xFF2BB24C);
const Color ppRed = Color(0xFFE5484D);
const Color ppCream = Color(0xFFFFF8EA);
const Color ppBlue = Color(0xFF1D5FD1);
const Color ppBrown = Color(0xFF5A3518);

TextStyle ppText(double size, {Color color = ppInk, FontWeight weight = FontWeight.w700, double? height}) =>
    TextStyle(fontFamily: 'Fredoka', fontSize: size, color: color, fontWeight: weight, height: height);

// ── data ───────────────────────────────────────────────────────────────────

class PpDetail {
  final String id;
  final double x, y, r; // centre as fractions of the picture, radius as a fraction of its width
  const PpDetail(this.id, this.x, this.y, this.r);
  String name(BuildContext c) => ppT(c, 'd_$id');
}

class PpStage {
  final String id;
  final String country;
  final double aspect; // width / height of the picture
  final List<PpDetail> details;
  final String? stampArt; // hand-drawn stamp, otherwise a generated one
  const PpStage(this.id, this.country, this.aspect, this.details, {this.stampArt});
  String get scene => pp('pp_sc_$id');
  String title(BuildContext c) => ppT(c, 's_$id');
  String city(BuildContext c) => ppT(c, 'c_$id');
  String fact(BuildContext c) => ppT(c, 'f_$id');
  PpCountry get land => ppCountry(country);
  int get index => land.stages.indexOf(this); // 0-based inside its country

  /// Puzzle grid (cols, rows): grows with the stage, follows the picture shape.
  (int, int) get grid {
    final level = land.id == 'MA' ? index : index + 3;
    final n = level <= 1 ? 4 : (level <= 4 ? 6 : 9);
    if (n == 4) return (2, 2);
    if (n == 9) return (3, 3);
    return aspect >= 1 ? (3, 2) : (2, 3);
  }
}

class PpCountry {
  final String id;
  final String card;
  final Color color;
  final String? seal;
  final int need; // stamps needed to unlock
  final List<PpStage> stages;
  const PpCountry(this.id, this.card, this.color, this.need, this.stages, {this.seal});
  String name(BuildContext c) => ppT(c, 'k_$id');
  String desc(BuildContext c) => ppT(c, 'kd_$id');
}

const List<PpCountry> ppCountries = [
  PpCountry('MA', 'pp_card_kasbah', Color(0xFFE5484D), 0, seal: 'pp_seal_MA', [
    PpStage('oudayas', 'MA', 1.3877, [PpDetail('tower', .40, .22, .07), PpDetail('waves', .2, .8, .09), PpDetail('palm', .73, .37, .06)]),
    PpStage('chefchaouen', 'MA', 1.2198, [PpDetail('lantern', .67, .27, .06), PpDetail('door', .25, .45, .07), PpDetail('pot', .19, .89, .07)]),
    PpStage('rabat', 'MA', 0.8070, [PpDetail('palm', .6, .53, .09), PpDetail('column', .59, .9, .09), PpDetail('motif', .2, .13, .11)],
        stampArt: 'pp_ink_rabat'),
    PpStage('fes', 'MA', 1.4329, [PpDetail('rosette', .65, .47, .06), PpDetail('arch', .64, .82, .09), PpDetail('zellige', .62, .1, .08)]),
    PpStage('marrakech', 'MA', 1.0623, [PpDetail('minaret', .5, .2, .08), PpDetail('palm', .12, .42, .09), PpDetail('flowers', .86, .9, .09)]),
    PpStage('atlas', 'MA', 1.2507, [PpDetail('mountain', .6, .15, .09), PpDetail('tower', .55, .33, .06), PpDetail('river', .66, .92, .07)]),
    PpStage('souk', 'MA', 1.1129, [PpDetail('lantern', .42, .35, .06), PpDetail('carpet', .18, .42, .07), PpDetail('vase', .24, .88, .06)]),
    PpStage('essaouira', 'MA', 1.6355, [PpDetail('tower', .45, .26, .05), PpDetail('gate', .57, .7, .05), PpDetail('boat', .75, .84, .06)]),
  ]),
  PpCountry('FR', 'pp_card_paris2', Color(0xFF2F6BE0), 0, seal: 'pp_seal_FR', [
    PpStage('paris2', 'FR', 2.2676, [PpDetail('eiffel', .55, .35, .06), PpDetail('lamp', .27, .38, .045), PpDetail('tree', .06, .75, .05)]),
    PpStage('paris', 'FR', 1.1367, [PpDetail('top', .48, .12, .07), PpDetail('arch', .5, .8, .08), PpDetail('flowers', .87, .92, .08)]),
  ]),
  PpCountry('EG', 'pp_card_egypt', Color(0xFF239B4B), 0, seal: 'pp_seal_EG', [
    PpStage('egypt', 'EG', 2.3, [PpDetail('sphinx', .27, .55, .06), PpDetail('pyramid', .6, .3, .07), PpDetail('palm', .9, .35, .05)]),
    PpStage('gizeh', 'EG', 1.2227, [PpDetail('pyramid', .48, .22, .08), PpDetail('small', .36, .62, .06), PpDetail('palm', .9, .62, .07)]),
  ]),
  PpCountry('JP', 'pp_card_japan', Color(0xFFD63A6A), 0, [
    PpStage('japan', 'JP', 2.3, [PpDetail('torii', .2, .45, .06), PpDetail('mountain', .5, .15, .07), PpDetail('pagoda', .81, .5, .06)]),
  ]),
  PpCountry('IT', 'pp_card_italy', Color(0xFFB4651E), 6, [
    PpStage('italy', 'IT', 2.3, [PpDetail('colosseum', .4, .5, .08), PpDetail('lamp', .945, .36, .045), PpDetail('olive', .15, .85, .06)]),
  ]),
  PpCountry('BR', 'pp_card_brazil', Color(0xFF7A2BE0), 10, [
    PpStage('brazil', 'BR', 2.3, [PpDetail('statue', .25, .22, .05), PpDetail('sugarloaf', .6, .42, .07), PpDetail('boats', .83, .92, .05)]),
  ]),
];

PpCountry ppCountry(String id) => ppCountries.firstWhere((c) => c.id == id);
final List<PpStage> ppStages = [for (final c in ppCountries) ...c.stages];
PpStage ppStage(String id) => ppStages.firstWhere((s) => s.id == id);

// ── progress ───────────────────────────────────────────────────────────────

class PpProgress {
  final Map<String, int> stars; // stage id → best stars (0 = not done)
  final String? newest;
  const PpProgress(this.stars, this.newest);
  int of(String id) => stars[id] ?? 0;
  bool done(String id) => of(id) > 0;
  int get stamps => stars.values.where((v) => v > 0).length;
  bool countryOpen(PpCountry c) => stamps >= c.need;
  int doneIn(PpCountry c) => c.stages.where((s) => done(s.id)).length;
  bool countryDone(PpCountry c) => doneIn(c) == c.stages.length;
  bool stageOpen(PpStage s) {
    if (!countryOpen(s.land)) return false;
    final i = s.index;
    return i == 0 || done(s.land.stages[i - 1].id);
  }

  /// Next stage to play inside a country (or its last one).
  PpStage nextIn(PpCountry c) => c.stages.firstWhere((s) => !done(s.id), orElse: () => c.stages.last);

  /// Next stage to play overall.
  PpStage get next {
    for (final c in ppCountries) {
      if (!countryOpen(c)) continue;
      for (final s in c.stages) {
        if (!done(s.id)) return s;
      }
    }
    return ppStages.first;
  }
}

class PpStore {
  static String _k(String id) => 'pp_st_$id';

  static Future<PpProgress> load() async {
    final p = await SharedPreferences.getInstance();
    return PpProgress({for (final s in ppStages) s.id: p.getInt(_k(s.id)) ?? 0}, p.getString('pp_new'));
  }

  /// Saves if better. Returns (new stars won, first time).
  static Future<(int, bool)> record(String id, int stars) async {
    final p = await SharedPreferences.getInstance();
    final old = p.getInt(_k(id)) ?? 0;
    if (stars > old) await p.setInt(_k(id), stars);
    if (old == 0) await p.setString('pp_new', id);
    return (max(0, stars - old), old == 0);
  }

  static Future<bool> seenHelp() async => (await SharedPreferences.getInstance()).getBool('pp_help') ?? false;
  static Future<void> setSeenHelp() async => (await SharedPreferences.getInstance()).setBool('pp_help', true);
}

// ── sound & voice ──────────────────────────────────────────────────────────

void ppSound(BuildContext c, String key) {
  try {
    Provider.of<AudioManager>(c, listen: false).playEventSound(key);
  } catch (_) {}
}

void ppSfx(BuildContext c, String file) {
  try {
    Provider.of<AudioManager>(c, listen: false).playSfx('assets/audios/UI_Audio/SFX_Audio/$file');
  } catch (_) {}
}

class PpVoice {
  static final FlutterTts _tts = FlutterTts();
  static Future<void> say(BuildContext c, String text) async {
    try {
      final lang = switch (ppLang(c)) { 'fr' => 'fr-FR', 'ar' => 'ar-SA', 'de' => 'de-DE', _ => 'en-US' };
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

// ── layout ─────────────────────────────────────────────────────────────────

bool ppRtl(BuildContext c) => Directionality.of(c) == TextDirection.rtl;

double ppScale(BuildContext c) {
  final size = MediaQuery.sizeOf(c);
  final pad = MediaQuery.paddingOf(c);
  final h = size.height - pad.vertical;
  return min(min(size.width, 520.0) / 390, h / 800).clamp(0.72, 1.3).toDouble();
}

class _PpFrameMark extends InheritedWidget {
  const _PpFrameMark({required super.child});
  @override
  bool updateShouldNotify(_PpFrameMark oldWidget) => false;
}

/// Phone-sized design canvas (≈390 wide) scaled to the real screen, system
/// font size ignored, so every device shows the same centred layout.
class PpFrame extends StatelessWidget {
  final Widget child;
  const PpFrame({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    if (context.dependOnInheritedWidgetOfExactType<_PpFrameMark>() != null) return child;
    final mq = MediaQuery.of(context);
    final W = mq.size.width, H = mq.size.height;
    if (W <= 0 || H <= 0) return child;
    final k = min(min(W / 390, H / 780), 1.35).toDouble();
    final dw = W / k, dh = H / k;
    EdgeInsets d(EdgeInsets e) => EdgeInsets.fromLTRB(e.left / k, e.top / k, e.right / k, e.bottom / k);
    return _PpFrameMark(
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

class PpBg extends StatelessWidget {
  final String asset;
  const PpBg({super.key, this.asset = 'pp_bg'});
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Image.asset(pp(asset), fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white.withOpacity(0.05), const Color(0xFFFFF1D6).withOpacity(0.3)],
            ),
          ),
        ),
      ]);
}

// ── buttons ────────────────────────────────────────────────────────────────

class PpPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? label;
  const PpPress({super.key, required this.child, required this.onTap, this.scale = 0.92, this.label});
  @override
  State<PpPress> createState() => _PpPressState();
}

class _PpPressState extends State<PpPress> {
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

Widget ppRound(BuildContext c, String sprite, double size, VoidCallback onTap, {bool flipRtl = false, String? label}) => PpPress(
      onTap: onTap,
      label: label,
      child: Transform.flip(flipX: flipRtl && ppRtl(c), child: Image.asset(pp(sprite), width: size, height: size, fit: BoxFit.contain)),
    );

/// Sprite button with white (or ink) text; [start]/[end] = label area as fractions of the width.
class PpButton extends StatelessWidget {
  final String sprite;
  final double ratio;
  final String label;
  final VoidCallback? onTap;
  final double width;
  final double start, end;
  final Animation<double>? pulse;
  final Color color, shadow;
  final Widget? icon;
  final bool arrow;
  const PpButton({
    super.key,
    required this.sprite,
    required this.ratio,
    required this.label,
    required this.onTap,
    required this.width,
    this.start = 0.1,
    this.end = 0.1,
    this.pulse,
    this.color = Colors.white,
    this.shadow = const Color(0xFFB4410A),
    this.icon,
    this.arrow = false,
  });

  /// The big orange call-to-action (sparkles).
  factory PpButton.main(String label, VoidCallback? onTap, double width, {Animation<double>? pulse}) => PpButton(
        sprite: onTap == null ? 'pp_btn_grey' : 'pp_btn_main',
        ratio: onTap == null ? 0.2857 : 0.3612,
        label: label,
        onTap: onTap,
        width: width,
        start: 0.12,
        end: 0.12,
        pulse: pulse,
        shadow: onTap == null ? const Color(0xFF6F6F6F) : const Color(0xFFB4410A),
        arrow: true,
      );

  /// Orange button with the plane (start of a journey).
  factory PpButton.plane(String label, VoidCallback? onTap, double width, {Animation<double>? pulse}) => PpButton(
        sprite: 'pp_btn_plane',
        ratio: 0.2795,
        label: label,
        onTap: onTap,
        width: width,
        start: 0.26,
        end: 0.13,
        pulse: pulse,
      );

  @override
  Widget build(BuildContext context) {
    final h = width * ratio;
    Widget b = PpPress(
      onTap: onTap,
      label: label,
      child: SizedBox(
        width: width,
        height: h,
        child: Stack(children: [
          Positioned.fill(child: Transform.flip(flipX: ppRtl(context) && sprite == 'pp_btn_plane', child: Image.asset(pp(sprite), fit: BoxFit.fill))),
          PositionedDirectional(
            start: width * start,
            end: width * end,
            top: h * 0.06,
            bottom: h * 0.12,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[icon!, SizedBox(width: h * 0.12)],
                  Text(label,
                      maxLines: 1,
                      style: ppText(h * 0.42, color: color, weight: FontWeight.w800)
                          .copyWith(shadows: color == Colors.white ? [Shadow(color: shadow, offset: const Offset(0, 2), blurRadius: 1)] : null)),
                  if (arrow) ...[
                    SizedBox(width: h * 0.1),
                    Icon(ppRtl(context) ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: color, size: h * 0.55),
                  ],
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
    if (pulse != null && onTap != null) {
      b = AnimatedBuilder(
        animation: pulse!,
        builder: (_, c) => Transform.scale(scale: 1 + 0.025 * sin(pulse!.value * 2 * pi * 4), child: c),
        child: b,
      );
    }
    return b;
  }
}

/// Dialog buttons (orange / teal).
Widget ppFlat(String label, VoidCallback? onTap, double width, {bool teal = false, IconData? icon}) => PpButton(
      sprite: teal ? 'pp_btn_cy' : 'pp_btn_or',
      ratio: teal ? 0.3204 : 0.2968,
      label: label,
      onTap: onTap,
      width: width,
      start: 0.1,
      end: 0.1,
      shadow: teal ? const Color(0xFF0B6F80) : const Color(0xFFB4410A),
      icon: icon == null ? null : Icon(icon, color: Colors.white, size: width * 0.11),
    );

/// Cream pill with a coloured border, an icon and a label.
class PpPill extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final double s;
  final Color border;
  final double font;
  const PpPill({super.key, required this.label, required this.icon, required this.onTap, required this.s, this.border = const Color(0xFF5B34C9), this.font = 15});
  @override
  Widget build(BuildContext context) => PpPress(
        onTap: onTap,
        label: label,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 7 * s),
          decoration: BoxDecoration(
            color: ppCream,
            borderRadius: BorderRadius.circular(30 * s),
            border: Border.all(color: border, width: 2.4 * s),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6 * s, offset: Offset(0, 3 * s))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            icon,
            SizedBox(width: 8 * s),
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: ppText(font * s, color: ppInk)))),
          ]),
        ),
      );
}

// ── titles, bubbles ────────────────────────────────────────────────────────

Widget ppOutlined(String t, Color c, double size, {double stroke = 0.18, Color outline = Colors.white, List<Color>? gradient}) {
  final fill = Text(t,
      maxLines: 1,
      style: gradient == null
          ? ppText(size, color: c, weight: FontWeight.w800)
          : TextStyle(
              fontFamily: 'Fredoka',
              fontSize: size,
              fontWeight: FontWeight.w800,
              foreground: Paint()
                ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: gradient)
                    .createShader(Rect.fromLTWH(0, 0, size * t.length * 0.6, size * 1.25)),
            ));
  return Stack(children: [
    Text(t,
        maxLines: 1,
        style: ppText(size, weight: FontWeight.w800).copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = size * stroke
            ..strokeJoin = StrokeJoin.round
            ..color = outline,
          shadows: [Shadow(color: Colors.black.withOpacity(0.25), offset: Offset(0, size * 0.07), blurRadius: size * 0.06)],
        )),
    fill,
  ]);
}

const List<Color> ppGoldText = [Color(0xFFFFE066), Color(0xFFFF9F1A)];
const List<Color> ppPurpleText = [Color(0xFF7B3CF0), Color(0xFF3B1A9A)];

/// Screen title: small caption, then a purple word and a golden word on the cream band.
class PpHeader extends StatelessWidget {
  final String? caption;
  final String a, b;
  final double width;
  final bool ribbon; // red ribbon version (country pages)
  const PpHeader({super.key, this.caption, required this.a, required this.b, required this.width, this.ribbon = false});
  @override
  Widget build(BuildContext context) {
    final h = width * (ribbon ? 0.2871 : 0.2339);
    final size = width * 0.105;
    return SizedBox(
      width: width,
      height: h + size * 0.55,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
        Positioned(left: 0, right: 0, bottom: 0, height: h, child: Image.asset(pp(ribbon ? 'pp_title_red' : 'pp_header'), fit: BoxFit.fill)),
        Positioned(
          left: width * (ribbon ? 0.2 : 0.06),
          right: width * 0.05,
          top: 0,
          bottom: h * 0.12,
          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (caption != null)
              FittedBox(fit: BoxFit.scaleDown, child: Text(caption!, style: ppText(width * 0.042, color: ppInk))),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  ppOutlined(a, ppInk, size, gradient: ppPurpleText),
                  if (b.isNotEmpty) ...[SizedBox(width: size * 0.25), ppOutlined(b, ppGold, size * 1.05, gradient: ppGoldText)],
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Big two-line celebration title on the cloud with rays.
class PpCloudTitle extends StatelessWidget {
  final String a, b;
  final double width;
  final bool confetti;
  final bool goldFirst;
  const PpCloudTitle({super.key, required this.a, required this.b, required this.width, this.confetti = false, this.goldFirst = false});
  @override
  Widget build(BuildContext context) {
    final h = width * (confetti ? 0.5089 : 0.5232);
    return SizedBox(
      width: width,
      height: h,
      child: Stack(children: [
        Positioned.fill(child: Image.asset(pp(confetti ? 'pp_cloud_confetti' : 'pp_cloud_rays'), fit: BoxFit.fill)),
        Positioned(
          left: width * 0.14,
          right: width * 0.14,
          top: h * (confetti ? 0.3 : 0.3),
          bottom: h * (confetti ? 0.18 : 0.1),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ppOutlined(a, goldFirst ? ppGold : ppInk, width * 0.12, gradient: goldFirst ? ppGoldText : ppPurpleText),
              Transform.translate(
                offset: Offset(0, -width * 0.02),
                child: ppOutlined(b, goldFirst ? ppInk : ppGold, width * 0.1, gradient: goldFirst ? ppPurpleText : ppGoldText),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Cream instruction band with the speaker (reads the text aloud).
class PpSay extends StatelessWidget {
  final String text;
  final double width;
  const PpSay({super.key, required this.text, required this.width});
  @override
  Widget build(BuildContext context) {
    final h = width * 0.1742;
    return PpPress(
      onTap: () => PpVoice.say(context, text),
      scale: 0.97,
      label: text,
      child: SizedBox(
        width: width,
        height: h,
        child: Stack(children: [
          Positioned.fill(child: Image.asset(pp('pp_say'), fit: BoxFit.fill)),
          Positioned(
            left: width * 0.17,
            right: width * 0.05,
            top: h * 0.1,
            bottom: h * 0.14,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: FittedBox(key: ValueKey(text), fit: BoxFit.scaleDown, child: Text(text, style: ppText(h * 0.4))),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Speech bubble (tail at the bottom start).
class PpBubble extends StatelessWidget {
  final String text;
  final double width;
  const PpBubble({super.key, required this.text, required this.width});
  @override
  Widget build(BuildContext context) {
    final h = width * 0.575;
    return SizedBox(
      width: width,
      height: h,
      child: Stack(children: [
        Positioned.fill(child: Transform.flip(flipX: ppRtl(context), child: Image.asset(pp('pp_bubble'), fit: BoxFit.fill))),
        Positioned(
          left: width * 0.1,
          right: width * 0.07,
          top: h * 0.08,
          bottom: h * 0.26,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: FittedBox(
                key: ValueKey(text),
                fit: BoxFit.scaleDown,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width * 0.82),
                  child: Text(text, textAlign: TextAlign.center, maxLines: 3, style: ppText(width * 0.085, height: 1.12)),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Text written inside a sprite, in a fractional area.
Widget ppOnSprite(String sprite, double width, double ratio, Widget child, {EdgeInsets area = const EdgeInsets.fromLTRB(0.1, 0.15, 0.1, 0.15)}) {
  final h = width * ratio;
  return SizedBox(
    width: width,
    height: h,
    child: Stack(children: [
      Positioned.fill(child: Image.asset(pp(sprite), fit: BoxFit.fill)),
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

// ── pictures ───────────────────────────────────────────────────────────────

/// A stage picture in a white rounded frame (postcard look).
class PpPhoto extends StatelessWidget {
  final PpStage stage;
  final double width;
  final double radius;
  final double border;
  const PpPhoto({super.key, required this.stage, required this.width, this.radius = 14, this.border = 4});
  @override
  Widget build(BuildContext context) => Container(
        width: width,
        padding: EdgeInsets.all(border),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius + border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: AspectRatio(aspectRatio: stage.aspect, child: Image.asset(stage.scene, fit: BoxFit.cover)),
        ),
      );
}

/// Round zoom on one detail of a stage picture.
class PpDetailCrop extends StatelessWidget {
  final PpStage stage;
  final PpDetail detail;
  final double size;
  final double zoom; // how many detail diameters fit in the circle
  const PpDetailCrop({super.key, required this.stage, required this.detail, required this.size, this.zoom = 1.5});
  @override
  Widget build(BuildContext context) {
    final w = size / (detail.r * 2 * zoom);
    final h = w / stage.aspect;
    var left = size / 2 - detail.x * w;
    var top = size / 2 - detail.y * h;
    // keep the picture covering the whole circle
    left = left.clamp(size - w, 0.0).toDouble();
    if (h >= size) top = top.clamp(size - h, 0.0).toDouble();
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(clipBehavior: Clip.hardEdge, children: [
          Positioned(left: left, top: top, width: w, height: h, child: Image.asset(stage.scene, fit: BoxFit.fill, filterQuality: FilterQuality.medium)),
        ]),
      ),
    );
  }
}

/// One piece of the postcard puzzle.
class PpPiece extends StatelessWidget {
  final PpStage stage;
  final int col, row, cols, rows;
  final double w, h; // size of the piece
  const PpPiece({super.key, required this.stage, required this.col, required this.row, required this.cols, required this.rows, required this.w, required this.h});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(min(w, h) * 0.08),
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(clipBehavior: Clip.hardEdge, children: [
            Positioned(left: -col * w, top: -row * h, width: w * cols, height: h * rows, child: Image.asset(stage.scene, fit: BoxFit.fill)),
          ]),
        ),
      );
}

/// The stamp of a stage: hand-drawn when available, otherwise the picture
/// printed in ink inside a postal ring.
class PpStamp extends StatelessWidget {
  final PpStage stage;
  final double size;
  final double opacity;
  const PpStamp({super.key, required this.stage, required this.size, this.opacity = 1});
  @override
  Widget build(BuildContext context) {
    final c = stage.land.color;
    Widget body;
    if (stage.stampArt != null) {
      body = Image.asset(pp(stage.stampArt!), width: size, height: size);
    } else {
      final r = c.red / 255, g = c.green / 255, b = c.blue / 255;
      // ink = colour × darkness of the picture
      final ink = ColorFilter.matrix(<double>[
        0, 0, 0, 0, r * 255, //
        0, 0, 0, 0, g * 255,
        0, 0, 0, 0, b * 255,
        -0.35, -0.6, -0.15, 0, 255 * 0.98,
      ]);
      body = SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(c),
          child: Padding(
            padding: EdgeInsets.all(size * 0.15),
            child: ClipOval(child: ColorFiltered(colorFilter: ink, child: Image.asset(stage.scene, fit: BoxFit.cover))),
          ),
        ),
      );
    }
    return Opacity(opacity: opacity, child: Transform.rotate(angle: -0.12, child: body));
  }
}

class _RingPainter extends CustomPainter {
  final Color c;
  _RingPainter(this.c);
  @override
  void paint(Canvas canvas, Size size) {
    final ctr = size.center(Offset.zero);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..color = c.withOpacity(0.9);
    canvas.drawCircle(ctr, size.width * 0.46, p..strokeWidth = size.width * 0.045);
    canvas.drawCircle(ctr, size.width * 0.385, p..strokeWidth = size.width * 0.018);
    // little stars
    final star = Paint()..color = c.withOpacity(0.9);
    for (final a in [pi * 0.15, pi * 0.85]) {
      final q = ctr + Offset(cos(a), -sin(a)) * size.width * 0.42;
      canvas.drawCircle(q, size.width * 0.02, star);
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.c != c;
}

/// Star burst at the centre of the box, driven by [t] (0→1).
class PpBurst extends CustomPainter {
  final double t;
  final int seed;
  PpBurst(this.t, {this.seed = 3});
  static const _c = [Color(0xFFFFC21A), Color(0xFF7DDB5A), Color(0xFF34D9CF), Color(0xFFFF8FB5), Color(0xFF8B5CFF)];
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
  bool shouldRepaint(PpBurst o) => o.t != t;
}

/// Falling confetti, driven by a repeating 0→1 value.
class PpConfetti extends CustomPainter {
  final double t;
  PpConfetti(this.t);
  static const _c = [Color(0xFFFFC21A), Color(0xFFFF6FB5), Color(0xFF34D9CF), Color(0xFF8B5CFF), Color(0xFF2F7DE8), Color(0xFFFF8A3D)];
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(7);
    for (var i = 0; i < 34; i++) {
      final x0 = r.nextDouble() * size.width;
      final speed = 0.5 + r.nextDouble() * 0.8;
      final y = ((t * speed + r.nextDouble()) % 1.0) * (size.height + 40) - 20;
      final x = x0 + sin(t * 2 * pi * 2 + i) * 14;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 2 * pi * (i.isEven ? 2 : -2) + i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 7 + r.nextDouble() * 5, height: 12), const Radius.circular(2)),
        Paint()..color = _c[i % _c.length],
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(PpConfetti o) => o.t != t;
}

/// Segmented progress bar (green done, sand left).
Widget ppProgress(int done, int total, double width, double s) => Container(
      width: width,
      padding: EdgeInsets.all(4 * s),
      decoration: BoxDecoration(
        color: ppCream,
        borderRadius: BorderRadius.circular(14 * s),
        border: Border.all(color: const Color(0xFFF0C77A), width: 2 * s),
      ),
      child: Row(children: [
        for (var i = 0; i < total; i++)
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              height: 12 * s,
              margin: EdgeInsets.symmetric(horizontal: 1.5 * s),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: i < done ? const [Color(0xFF7DEB5A), Color(0xFF22A84A)] : const [Color(0xFFE8DCC6), Color(0xFFD9CBB0)],
                ),
                borderRadius: BorderRadius.circular(8 * s),
              ),
            ),
          ),
      ]),
    );
