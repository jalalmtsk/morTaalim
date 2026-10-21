import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Le petit marché — a souk adventure: shopping list, weighing, paying.
// 12 levels in 3 worlds:
//   1–4  "I recognise"  fill the basket from the shopping list
//   5–8  "I weigh"      reach the right weight on the scale
//   9–12 "I count"      pay with coins, then give the change
// ═══════════════════════════════════════════════════════════════════════════

const String mkDir = 'assets/images/Games/Market/';
String mk(String n) => '$mkDir$n.webp';

const Color mkInk = Color(0xFF3A1C8C);
const Color mkInkSoft = Color(0xFF6A5A9E);
const Color mkOrange = Color(0xFFF26B1D);
const Color mkTeal = Color(0xFF14A3A8);
const Color mkCream = Color(0xFFFFF7E8);
const Color mkRed = Color(0xFFE5484D);
const Color mkGreen = Color(0xFF22A35A);

TextStyle mkText(double size, {Color color = mkInk, FontWeight weight = FontWeight.w700, double? height}) =>
    TextStyle(fontFamily: 'Fredoka', fontSize: size, color: color, fontWeight: weight, height: height);

// ── items ──────────────────────────────────────────────────────────────────

class MkItem {
  final String id;
  final Map<String, List<String>> name; // lang → [one, many]
  const MkItem(this.id, this.name);
  String get asset => mk('mk_it_$id');
  String get sign => mk('mk_sign_$id');
  String label(BuildContext c, int n) {
    final l = name[mkLang(c)] ?? name['en']!;
    return n == 1 ? l[0] : l[1];
  }
}

const List<MkItem> mkItems = [
  MkItem('apple', {'fr': ['pomme', 'pommes'], 'en': ['apple', 'apples'], 'ar': ['تفاحة', 'تفاحات'], 'de': ['Apfel', 'Äpfel']}),
  MkItem('orange', {'fr': ['orange', 'oranges'], 'en': ['orange', 'oranges'], 'ar': ['برتقالة', 'برتقالات'], 'de': ['Orange', 'Orangen']}),
  MkItem('banana', {'fr': ['banane', 'bananes'], 'en': ['banana', 'bananas'], 'ar': ['موزة', 'موزات'], 'de': ['Banane', 'Bananen']}),
  MkItem('tomato', {'fr': ['tomate', 'tomates'], 'en': ['tomato', 'tomatoes'], 'ar': ['طماطم', 'طماطم'], 'de': ['Tomate', 'Tomaten']}),
  MkItem('carrot', {'fr': ['carotte', 'carottes'], 'en': ['carrot', 'carrots'], 'ar': ['جزرة', 'جزرات'], 'de': ['Karotte', 'Karotten']}),
  MkItem('bread', {'fr': ['pain', 'pains'], 'en': ['bread', 'breads'], 'ar': ['خبزة', 'خبزات'], 'de': ['Brot', 'Brote']}),
];

MkItem mkItem(String id) => mkItems.firstWhere((i) => i.id == id);

// ── levels ─────────────────────────────────────────────────────────────────

enum MkKind { basket, scale, pay, change }

class MkLevel {
  final int n; // 1..12
  final MkKind kind;
  const MkLevel(this.n, this.kind);
  int get world => n <= 4 ? 0 : (n <= 8 ? 1 : 2);
  String title(BuildContext c) => mkT(c, 'l${n}t');
  String sub(BuildContext c) => mkT(c, 'l${n}s');
}

const List<MkLevel> mkLevels = [
  MkLevel(1, MkKind.basket), MkLevel(2, MkKind.basket), MkLevel(3, MkKind.basket), MkLevel(4, MkKind.basket),
  MkLevel(5, MkKind.scale), MkLevel(6, MkKind.scale), MkLevel(7, MkKind.scale), MkLevel(8, MkKind.scale),
  MkLevel(9, MkKind.pay), MkLevel(10, MkKind.pay), MkLevel(11, MkKind.change), MkLevel(12, MkKind.change),
];

/// A shopping-list round.
class MkList {
  final Map<String, int> want; // item id → how many
  final List<String> stalls; // items on sale (includes the wanted ones)
  const MkList(this.want, this.stalls);

  static MkList make(int n, Random r) {
    final (types, minQ, maxQ, stalls) = switch (n) {
      1 => (2, 1, 2, 3),
      2 => (3, 1, 3, 4),
      3 => (3, 2, 4, 6),
      _ => (4, 1, 5, 6),
    };
    final all = [...mkItems.map((i) => i.id)]..shuffle(r);
    final sale = all.take(stalls).toList();
    final wanted = [...sale]..shuffle(r);
    return MkList({for (final id in wanted.take(types)) id: minQ + r.nextInt(maxQ - minQ + 1)}, sale);
  }
}

/// A weighing round: put fruits on the scale until it shows [target] grams.
class MkWeigh {
  final String item;
  final int target;
  final List<int> slots; // weight of the fruit in each tray slot (infinite supply)
  const MkWeigh(this.item, this.target, this.slots);

  static MkWeigh make(int n, Random r) {
    final item = ['apple', 'orange', 'tomato'][r.nextInt(3)];
    return switch (n) {
      5 => MkWeigh(item, 500, const [250, 250, 250, 250]),
      6 => MkWeigh(item, 1000, const [250, 250, 250, 250]),
      7 => MkWeigh(item, [750, 1000, 1250][r.nextInt(3)], const [250, 500, 250, 500]),
      _ => MkWeigh(item, [1500, 1750, 2000][r.nextInt(3)], const [250, 500, 750, 500]),
    };
  }
}

/// A paying round (pay) or a change round (change).
class MkMoney {
  final List<(String, int)> lines; // receipt: item id, price in DH
  final int given; // change rounds: what the customer gives
  final List<int> coins; // coins in the purse
  const MkMoney(this.lines, this.given, this.coins);
  int get total => lines.fold(0, (a, l) => a + l.$2);
  int get change => given - total;

  static MkMoney make(int n, Random r) {
    List<(String, int)> lines(int count, int lo, int hi) {
      final ids = [...mkItems.map((i) => i.id)]..shuffle(r);
      return [for (final id in ids.take(count)) (id, lo + r.nextInt(hi - lo + 1))];
    }

    return switch (n) {
      9 => MkMoney(lines(2, 1, 4), 0, const [1, 2, 5]),
      10 => MkMoney(lines(3, 2, 6), 0, const [1, 2, 5, 10]),
      11 => MkMoney(lines(2, 1, 4), 10, const [1, 2, 5]),
      _ => MkMoney(lines(3, 2, 5), 20, const [1, 2, 5, 10]),
    };
  }
}

String mkCoin(int v) => mk(switch (v) { 1 => 'mk_c1', 2 => 'mk_c2', 5 => 'mk_c5', _ => 'mk_c10' });

// ── progress ───────────────────────────────────────────────────────────────

class MkStore {
  static String _k(int n) => 'mk_stars_$n';

  static Future<List<int>> stars() async {
    final p = await SharedPreferences.getInstance();
    return [for (final l in mkLevels) p.getInt(_k(l.n)) ?? 0];
  }

  /// Saves if better. Returns (new stars won, first time finished).
  static Future<(int, bool)> record(int n, int stars) async {
    final p = await SharedPreferences.getInstance();
    final old = p.getInt(_k(n)) ?? 0;
    if (stars > old) await p.setInt(_k(n), stars);
    return (max(0, stars - old), old == 0);
  }

  static bool unlocked(List<int> stars, int n) => n == 1 || (stars.length >= n - 1 && stars[n - 2] > 0);

  /// First level not finished yet (or the last one).
  static int next(List<int> stars) {
    for (var i = 0; i < stars.length; i++) {
      if (stars[i] == 0) return i + 1;
    }
    return mkLevels.length;
  }

  static Future<bool> seenHelp() async => (await SharedPreferences.getInstance()).getBool('mk_help') ?? false;
  static Future<void> setSeenHelp() async => (await SharedPreferences.getInstance()).setBool('mk_help', true);
}

// ── sound & voice ──────────────────────────────────────────────────────────

void mkSound(BuildContext c, String key) {
  try {
    Provider.of<AudioManager>(c, listen: false).playEventSound(key);
  } catch (_) {}
}

void mkSfx(BuildContext c, String file) {
  try {
    Provider.of<AudioManager>(c, listen: false).playSfx('assets/audios/UI_Audio/SFX_Audio/$file');
  } catch (_) {}
}

class MkVoice {
  static final FlutterTts _tts = FlutterTts();
  static Future<void> say(BuildContext c, String text) async {
    try {
      final lang = switch (mkLang(c)) { 'fr' => 'fr-FR', 'ar' => 'ar-SA', 'de' => 'de-DE', _ => 'en-US' };
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

// ── widgets ────────────────────────────────────────────────────────────────

bool mkRtl(BuildContext c) => Directionality.of(c) == TextDirection.rtl;

double mkScale(BuildContext c) {
  final size = MediaQuery.sizeOf(c);
  final pad = MediaQuery.paddingOf(c);
  final h = size.height - pad.vertical;
  return min(min(size.width, 520.0) / 390, h / 800).clamp(0.72, 1.3).toDouble();
}

class MkPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? label;
  const MkPress({super.key, required this.child, required this.onTap, this.scale = 0.92, this.label});
  @override
  State<MkPress> createState() => _MkPressState();
}

class _MkPressState extends State<MkPress> {
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

Widget mkRound(BuildContext c, String sprite, double size, VoidCallback onTap, {bool flipRtl = false, String? label}) => MkPress(
      onTap: onTap,
      label: label,
      child: Transform.flip(flipX: flipRtl && mkRtl(c), child: Image.asset(mk(sprite), width: size, height: size)),
    );

/// Big orange button (sprite with a play triangle on the start side).
class MkPlayButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double width, s;
  final Animation<double>? pulse;
  const MkPlayButton({super.key, required this.label, required this.onTap, required this.width, required this.s, this.pulse});
  @override
  Widget build(BuildContext context) {
    final h = width * 0.3;
    Widget b = MkPress(
      onTap: onTap,
      label: label,
      child: SizedBox(
        width: width,
        height: h,
        child: Stack(children: [
          Positioned.fill(child: Transform.flip(flipX: mkRtl(context), child: Image.asset(mk('mk_btn_play'), fit: BoxFit.fill))),
          PositionedDirectional(
            start: width * 0.26,
            end: width * 0.06,
            top: 0,
            bottom: h * 0.06,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    style: mkText(h * 0.4, color: Colors.white)
                        .copyWith(shadows: const [Shadow(color: Color(0xFFB4410A), offset: Offset(0, 2), blurRadius: 1)])),
              ),
            ),
          ),
        ]),
      ),
    );
    if (onTap == null) return Opacity(opacity: 0.5, child: b);
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

/// Plain sprite button (orange / teal) with a label.
class MkFlatButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double width, s;
  final bool teal;
  final IconData? icon;
  const MkFlatButton({super.key, required this.label, required this.onTap, required this.width, required this.s, this.teal = false, this.icon});
  @override
  Widget build(BuildContext context) {
    final h = width * 0.26;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: MkPress(
        onTap: onTap,
        label: label,
        child: SizedBox(
          width: width,
          height: h,
          child: Stack(alignment: Alignment.center, children: [
            Positioned.fill(child: Image.asset(mk(teal ? 'mk_btn_teal' : 'mk_btn_orange'), fit: BoxFit.fill)),
            Padding(
              padding: EdgeInsets.fromLTRB(12 * s, 0, 12 * s, 3 * s),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[Icon(icon, color: Colors.white, size: h * 0.45), SizedBox(width: 6 * s)],
                  Text(label, style: mkText(h * 0.4, color: Colors.white)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Cream pill button (Reset / Map …).
class MkPillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final double s;
  const MkPillButton({super.key, required this.label, required this.icon, required this.onTap, required this.s, this.iconColor = mkRed});
  @override
  Widget build(BuildContext context) => MkPress(
        onTap: onTap,
        label: label,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 8 * s),
          decoration: BoxDecoration(
            color: mkCream,
            borderRadius: BorderRadius.circular(30 * s),
            border: Border.all(color: const Color(0xFFF2B33D), width: 2.5 * s),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6 * s, offset: Offset(0, 3 * s))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: iconColor, size: 22 * s),
            SizedBox(width: 6 * s),
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: mkText(15 * s)))),
          ]),
        ),
      );
}

/// Moroccan arch title plaque with a two-colour title.
class MkTitle extends StatelessWidget {
  final String top, bottom;
  final String? pill;
  final double width;
  const MkTitle({super.key, required this.top, required this.bottom, required this.width, this.pill});
  @override
  Widget build(BuildContext context) {
    final withPill = pill != null;
    final h = width * (withPill ? 0.4788 : 0.4019);
    Widget word(String t, Color c, double size) => Stack(children: [
          Text(t,
              maxLines: 1,
              style: mkText(size, weight: FontWeight.w800).copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = size * 0.16
                  ..strokeJoin = StrokeJoin.round
                  ..color = Colors.white,
              )),
          Text(t, maxLines: 1, style: mkText(size, color: c, weight: FontWeight.w800)),
        ]);
    return SizedBox(
      width: width,
      height: h,
      child: Stack(children: [
        Positioned.fill(child: Image.asset(mk(withPill ? 'mk_title_sub' : 'mk_title'), fit: BoxFit.fill)),
        Positioned(
          left: width * 0.12,
          right: width * 0.12,
          top: h * 0.26,
          bottom: h * (withPill ? 0.3 : 0.12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              word(top, const Color(0xFF5A1FB0), width * 0.09),
              if (bottom.isNotEmpty) word(bottom, mkOrange, width * 0.095),
            ]),
          ),
        ),
        if (withPill)
          Positioned(
            left: width * 0.32,
            right: width * 0.32,
            bottom: h * 0.07,
            height: h * 0.15,
            child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text('✦ $pill ✦', style: mkText(width * 0.04, color: mkInk)))),
          ),
      ]),
    );
  }
}

/// Speech bubble (tail at the bottom start).
class MkBubble extends StatelessWidget {
  final String text;
  final double width;
  const MkBubble({super.key, required this.text, required this.width});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: width * 0.5,
        child: Stack(children: [
          Positioned.fill(child: Transform.flip(flipX: !mkRtl(context), child: Image.asset(mk('mk_bubble'), fit: BoxFit.fill))),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(width * 0.08, width * 0.04, width * 0.08, width * 0.15),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: FittedBox(
                    key: ValueKey(text),
                    fit: BoxFit.scaleDown,
                    child: Text(text, textAlign: TextAlign.center, maxLines: 3, style: mkText(width * 0.075, color: const Color(0xFF1C3E9C))),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );
}

/// A Moroccan-style coin with its value.
class MkCoin extends StatelessWidget {
  final int value;
  final double size;
  const MkCoin({super.key, required this.value, required this.size});
  @override
  Widget build(BuildContext context) {
    final dark = value == 1 ? const Color(0xFF7A3A1C) : (value == 2 ? const Color(0xFF5E6470) : const Color(0xFF7A5410));
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        Image.asset(mkCoin(value), width: size, height: size, fit: BoxFit.contain),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$value', style: mkText(size * 0.36, color: dark, weight: FontWeight.w800, height: 1)),
          Text('DH', style: mkText(size * 0.14, color: dark, weight: FontWeight.w700, height: 1)),
        ]),
      ]),
    );
  }
}

/// Cream label pill with Moroccan drops.
Widget mkLabel(String text, double s, {double width = 180, Color color = mkInk, bool teal = false}) => SizedBox(
      width: width * s,
      height: width * s * (teal ? 0.1415 : 0.3739) * (teal ? 1.6 : 0.8),
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(child: Image.asset(mk(teal ? 'mk_label_teal' : 'mk_label'), fit: BoxFit.fill)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18 * s),
          child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, style: mkText(16 * s, color: color))),
        ),
      ]),
    );

/// Burst of colourful stars at the centre of the box, driven by [t] (0→1).
class MkBurstPainter extends CustomPainter {
  final double t;
  final int seed;
  MkBurstPainter(this.t, {this.seed = 3});
  static const _c = [Color(0xFFFFC21A), Color(0xFFFF6FB5), Color(0xFF34D9CF), Color(0xFF8B5CFF), Color(0xFF7DDB5A)];
  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final c = size.center(Offset.zero);
    final r = Random(seed);
    final e = Curves.easeOutCubic.transform(t);
    for (var i = 0; i < 20; i++) {
      final a = i / 20 * 2 * pi + r.nextDouble() * 0.4;
      final d = (0.3 + r.nextDouble() * 0.5) * size.shortestSide * e;
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
  bool shouldRepaint(MkBurstPainter o) => o.t != t;
}

/// Souk background with a soft warm wash.
class MkBg extends StatelessWidget {
  final bool alt;
  const MkBg({super.key, this.alt = false});
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Image.asset(mk(alt ? 'mk_bg2' : 'mk_bg'), fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white.withOpacity(0.0), const Color(0xFFFFE7C2).withOpacity(0.25)],
            ),
          ),
        ),
      ]);
}


// ── responsive frame ───────────────────────────────────────────────────────
// Lays the page out on a phone-sized design canvas (≈390 wide) and scales it
// to the real screen, so every device shows the same centred layout. The
// system font size is ignored here (big system fonts broke the layout).

class _MkFrameMark extends InheritedWidget {
  const _MkFrameMark({required super.child});
  @override
  bool updateShouldNotify(_MkFrameMark oldWidget) => false;
}

class MkFrame extends StatelessWidget {
  final Widget child;
  const MkFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (context.dependOnInheritedWidgetOfExactType<_MkFrameMark>() != null) return child;
    final mq = MediaQuery.of(context);
    final W = mq.size.width, H = mq.size.height;
    if (W <= 0 || H <= 0) return child;
    final k = min(min(W / 390, H / 780), 1.35).toDouble();
    final dw = W / k, dh = H / k;
    EdgeInsets d(EdgeInsets e) => EdgeInsets.fromLTRB(e.left / k, e.top / k, e.right / k, e.bottom / k);
    return _MkFrameMark(
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

// ── text ───────────────────────────────────────────────────────────────────

String mkLang(BuildContext c) {
  final l = Localizations.localeOf(c).languageCode;
  return const ['fr', 'en', 'ar', 'de'].contains(l) ? l : (l == 'zgh' ? 'fr' : 'en');
}

String mkT(BuildContext c, String key, [Map<String, Object>? args]) {
  var s = _s[mkLang(c)]?[key] ?? _s['en']![key] ?? key;
  args?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

String mkTitleFor(String localeName) {
  final code = localeName.split(RegExp('[_-]')).first;
  final lang = _s.containsKey(code) ? code : (code == 'zgh' ? 'fr' : 'en');
  return '${_s[lang]!['title1']!} ${_s[lang]!['title2']!}';
}

/// "1 kg 250 g" style weights.
String mkGrams(BuildContext c, int g) {
  if (g >= 1000 && g % 1000 == 0) return '${g ~/ 1000} kg';
  return '$g g';
}

const Map<String, Map<String, String>> _s = {
  'fr': {
    'title1': 'Le petit', 'title2': 'marché', 'tag': 'Une aventure au souk !',
    'w0': 'Les courses', 'w1': 'La balance', 'w2': 'La monnaie',
    's0': 'Je reconnais', 's1': 'Je pèse', 's2': 'Je compte',
    'play': 'Jouer', 'choose': 'Choisir un niveau', 'how': 'Comment jouer ?', 'done': '{n} niveaux terminés',
    'mapTitle1': 'Les chemins', 'mapTitle2': 'du souk', 'level': 'Niveau {n}', 'locked': 'Termine le niveau précédent !',
    'listTitle1': 'Ma liste', 'listTitle2': 'de courses', 'listSay': 'Regarde les images et remplis ton panier !',
    'goMarket': 'Au marché !', 'noTimer': 'À ton rythme · Sans chrono',
    'fillTitle1': 'Je remplis', 'fillTitle2': 'mon panier', 'check': 'Vérifier mon panier',
    'tapFruit': 'Touche un fruit pour le mettre dans le panier !',
    'missing': 'Il manque encore {n} {item} !', 'tooMany': 'Il y a trop de {item} !', 'notList': 'Les {item} ne sont pas sur la liste !',
    'weighTitle1': 'La juste', 'weighTitle2': 'mesure', 'prepare': 'Prépare {w} de {item}',
    'weighSay': 'Ajoute des {item} pour atteindre {w} !', 'goal': 'Objectif : {w}', 'remove': 'Retirer', 'restart': 'Recommencer',
    'verify': 'Vérifier', 'tooHeavy': 'Trop lourd ! Retire un fruit.', 'notEnough': 'Pas encore assez, ajoute un fruit !',
    'payTitle1': 'Je paie', 'payTitle2': 'mes courses', 'paySay': 'Choisis les pièces pour faire {n} DH.',
    'putCoins': 'Pose tes pièces ici', 'purse': 'Mon porte-monnaie', 'payBtn': 'Payer {n} DH', 'clear': 'Tout retirer',
    'fake': 'Monnaie du jeu · Aucun achat réel', 'payLess': 'Il manque {n} DH !', 'payMore': 'C’est trop, {n} DH en plus !',
    'changeTitle1': 'Je rends', 'changeTitle2': 'la monnaie', 'price': 'Prix des courses :', 'gives': 'Le client donne :',
    'howMuch': 'Combien dois-tu rendre ?', 'myChange': 'Ma monnaie : {n} DH', 'pick': 'Choisis tes pièces',
    'giveBtn': 'Rendre la monnaie', 'changeSay': 'Compte jusqu’à {n} pour vérifier !',
    'bravo1': 'Bravo,', 'bravo2': 'petit marchand !', 'mission': 'Mission accomplie !', 'rewards': 'Récompenses', 'badge': 'Badge débloqué',
    'badgeName': 'Petit marchand', 'next': 'Niveau suivant', 'again': 'Rejouer', 'map': 'Carte des niveaux',
    'r0': 'Liste complétée', 'r1': 'Bonne mesure', 'r2': 'Compte juste',
    'good': 'Bien joué !', 'goodSub': 'Tu as trouvé la bonne quantité !', 'continue': 'Continuer',
    'effort': 'Encore un petit effort !', 'retry': 'Réessayer', 'hint': 'Un indice', 'hintTitle': 'Un petit indice',
    'pause': 'Petite pause', 'resume': 'Reprendre', 'quitQ': 'Retour à la carte ?', 'quitSub': 'Ce niveau recommencera au début.',
    'keep': 'Continuer à jouer', 'quit': 'Quitter le niveau', 'go': 'C’est parti !', 'understood': 'J’ai compris !',
    'h1': 'Regarde la liste', 'h2': 'Touche les fruits', 'h3': 'Vérifie tes courses',
    'hintBasket': 'Ajoute encore {n} {item}.', 'hintScale': 'Il manque {w}.', 'hintScaleOver': 'Retire {w}.',
    'hintPay': 'Essaie avec une pièce de {n} DH.', 'allGood': 'Tout est bon, appuie sur Vérifier !',
    'l1t': 'Mes premières courses', 'l1s': 'Remplis le panier avec Waki !', 'l2t': 'Le panier du matin', 'l2s': 'Trois produits à trouver',
    'l3t': 'Le grand marché', 'l3s': 'Compte bien chaque fruit', 'l4t': 'Le panier de fête', 'l4s': 'Une longue liste !',
    'l5t': 'Premiers pas sur la balance', 'l5s': 'Pèse 500 g de fruits', 'l6t': 'Un kilo tout rond', 'l6s': '1 kg = 1000 g',
    'l7t': 'La juste mesure', 'l7s': 'Pèse les fruits avec Waki !', 'l8t': 'Le grand pesage', 'l8s': 'Mélange les poids',
    'l9t': 'Ma première pièce', 'l9s': 'Paie avec 1, 2 et 5 DH', 'l10t': 'Je paie mes courses', 'l10s': 'Paie le bon prix',
    'l11t': 'Je rends la monnaie', 'l11s': 'Le client donne 10 DH', 'l12t': 'Le marchand malin', 'l12s': 'Le client donne 20 DH',
  },
  'en': {
    'title1': 'The little', 'title2': 'market', 'tag': 'An adventure in the souk!',
    'w0': 'Shopping', 'w1': 'The scale', 'w2': 'The money',
    's0': 'I recognise', 's1': 'I weigh', 's2': 'I count',
    'play': 'Play', 'choose': 'Choose a level', 'how': 'How to play?', 'done': '{n} levels done',
    'mapTitle1': 'The souk', 'mapTitle2': 'paths', 'level': 'Level {n}', 'locked': 'Finish the level before!',
    'listTitle1': 'My shopping', 'listTitle2': 'list', 'listSay': 'Look at the pictures and fill your basket!',
    'goMarket': 'To the market!', 'noTimer': 'At your own pace · No timer',
    'fillTitle1': 'I fill', 'fillTitle2': 'my basket', 'check': 'Check my basket',
    'tapFruit': 'Tap a fruit to put it in the basket!',
    'missing': 'You still need {n} {item}!', 'tooMany': 'Too many {item}!', 'notList': '{item} are not on the list!',
    'weighTitle1': 'Just the', 'weighTitle2': 'right weight', 'prepare': 'Prepare {w} of {item}',
    'weighSay': 'Add {item} to reach {w}!', 'goal': 'Goal: {w}', 'remove': 'Remove', 'restart': 'Restart',
    'verify': 'Check', 'tooHeavy': 'Too heavy! Take one off.', 'notEnough': 'Not enough yet, add a fruit!',
    'payTitle1': 'I pay for', 'payTitle2': 'my shopping', 'paySay': 'Pick coins to make {n} DH.',
    'putCoins': 'Put your coins here', 'purse': 'My purse', 'payBtn': 'Pay {n} DH', 'clear': 'Clear all',
    'fake': 'Game money · No real purchase', 'payLess': '{n} DH missing!', 'payMore': 'Too much, {n} DH extra!',
    'changeTitle1': 'I give', 'changeTitle2': 'the change', 'price': 'Shopping price:', 'gives': 'The customer gives:',
    'howMuch': 'How much change?', 'myChange': 'My change: {n} DH', 'pick': 'Pick your coins',
    'giveBtn': 'Give the change', 'changeSay': 'Count up to {n} to check!',
    'bravo1': 'Well done,', 'bravo2': 'little merchant!', 'mission': 'Mission complete!', 'rewards': 'Rewards', 'badge': 'Badge unlocked',
    'badgeName': 'Little merchant', 'next': 'Next level', 'again': 'Play again', 'map': 'Level map',
    'r0': 'List done', 'r1': 'Right weight', 'r2': 'Right money',
    'good': 'Well done!', 'goodSub': 'You found the right amount!', 'continue': 'Continue',
    'effort': 'One more try!', 'retry': 'Try again', 'hint': 'A hint', 'hintTitle': 'A little hint',
    'pause': 'Little break', 'resume': 'Resume', 'quitQ': 'Back to the map?', 'quitSub': 'This level will start again.',
    'keep': 'Keep playing', 'quit': 'Quit the level', 'go': 'Let’s go!', 'understood': 'Got it!',
    'h1': 'Look at the list', 'h2': 'Tap the fruits', 'h3': 'Check your shopping',
    'hintBasket': 'Add {n} more {item}.', 'hintScale': '{w} missing.', 'hintScaleOver': 'Take off {w}.',
    'hintPay': 'Try a {n} DH coin.', 'allGood': 'All good, tap Check!',
    'l1t': 'My first shopping', 'l1s': 'Fill the basket with Waki!', 'l2t': 'The morning basket', 'l2s': 'Three things to find',
    'l3t': 'The big market', 'l3s': 'Count every fruit', 'l4t': 'The party basket', 'l4s': 'A long list!',
    'l5t': 'First steps on the scale', 'l5s': 'Weigh 500 g of fruit', 'l6t': 'One whole kilo', 'l6s': '1 kg = 1000 g',
    'l7t': 'Just the right weight', 'l7s': 'Weigh fruit with Waki!', 'l8t': 'The big weigh-in', 'l8s': 'Mix the weights',
    'l9t': 'My first coin', 'l9s': 'Pay with 1, 2 and 5 DH', 'l10t': 'I pay for my shopping', 'l10s': 'Pay the right price',
    'l11t': 'I give the change', 'l11s': 'The customer gives 10 DH', 'l12t': 'The clever merchant', 'l12s': 'The customer gives 20 DH',
  },
  'ar': {
    'title1': 'السوق', 'title2': 'الصغير', 'tag': 'مغامرة في السوق!',
    'w0': 'التسوّق', 'w1': 'الميزان', 'w2': 'النقود',
    's0': 'أتعرّف', 's1': 'أزن', 's2': 'أحسب',
    'play': 'العب', 'choose': 'اختر مستوى', 'how': 'كيف ألعب؟', 'done': '{n} مستويات مكتملة',
    'mapTitle1': 'دروب', 'mapTitle2': 'السوق', 'level': 'المستوى {n}', 'locked': 'أكمل المستوى السابق!',
    'listTitle1': 'قائمة', 'listTitle2': 'مشترياتي', 'listSay': 'انظر إلى الصور واملأ سلّتك!',
    'goMarket': 'إلى السوق!', 'noTimer': 'على راحتك · بدون وقت',
    'fillTitle1': 'أملأ', 'fillTitle2': 'سلّتي', 'check': 'تحقّق من سلّتي',
    'tapFruit': 'اضغط على الفاكهة لتضعها في السلّة!',
    'missing': 'ما زال ينقص {n} {item}!', 'tooMany': '{item} أكثر من اللازم!', 'notList': '{item} ليست في القائمة!',
    'weighTitle1': 'الوزن', 'weighTitle2': 'الصحيح', 'prepare': 'حضّر {w} من {item}',
    'weighSay': 'أضف {item} لتصل إلى {w}!', 'goal': 'الهدف: {w}', 'remove': 'إزالة', 'restart': 'من جديد',
    'verify': 'تحقّق', 'tooHeavy': 'ثقيل جداً! أزل فاكهة.', 'notEnough': 'ليس بعد، أضف فاكهة!',
    'payTitle1': 'أدفع', 'payTitle2': 'ثمن مشترياتي', 'paySay': 'اختر القطع لتكوّن {n} درهم.',
    'putCoins': 'ضع قطعك هنا', 'purse': 'محفظتي', 'payBtn': 'ادفع {n} درهم', 'clear': 'إزالة الكل',
    'fake': 'نقود اللعبة · لا شراء حقيقي', 'payLess': 'ينقص {n} درهم!', 'payMore': 'كثير، {n} درهم زائدة!',
    'changeTitle1': 'أُرجع', 'changeTitle2': 'الباقي', 'price': 'ثمن المشتريات:', 'gives': 'الزبون يعطي:',
    'howMuch': 'كم يجب أن تُرجع؟', 'myChange': 'الباقي: {n} درهم', 'pick': 'اختر قطعك',
    'giveBtn': 'أرجع الباقي', 'changeSay': 'احسب حتى {n} لتتأكد!',
    'bravo1': 'أحسنت،', 'bravo2': 'أيها التاجر الصغير!', 'mission': 'المهمة أُنجزت!', 'rewards': 'المكافآت', 'badge': 'وسام جديد',
    'badgeName': 'التاجر الصغير', 'next': 'المستوى التالي', 'again': 'العب مجدداً', 'map': 'خريطة المستويات',
    'r0': 'القائمة مكتملة', 'r1': 'وزن صحيح', 'r2': 'حساب صحيح',
    'good': 'أحسنت!', 'goodSub': 'وجدت الكمية الصحيحة!', 'continue': 'متابعة',
    'effort': 'مجهود صغير بعد!', 'retry': 'أعد المحاولة', 'hint': 'تلميح', 'hintTitle': 'تلميح صغير',
    'pause': 'استراحة', 'resume': 'متابعة', 'quitQ': 'العودة إلى الخريطة؟', 'quitSub': 'سيبدأ هذا المستوى من جديد.',
    'keep': 'واصل اللعب', 'quit': 'غادر المستوى', 'go': 'هيا بنا!', 'understood': 'فهمت!',
    'h1': 'انظر إلى القائمة', 'h2': 'اضغط على الفواكه', 'h3': 'تحقّق من مشترياتك',
    'hintBasket': 'أضف {n} {item} أخرى.', 'hintScale': 'ينقص {w}.', 'hintScaleOver': 'أزل {w}.',
    'hintPay': 'جرّب قطعة {n} درهم.', 'allGood': 'كل شيء صحيح، اضغط تحقّق!',
    'l1t': 'أول مشترياتي', 'l1s': 'املأ السلّة مع واكي!', 'l2t': 'سلّة الصباح', 'l2s': 'ثلاثة أشياء لتجدها',
    'l3t': 'السوق الكبير', 'l3s': 'احسب كل فاكهة', 'l4t': 'سلّة العيد', 'l4s': 'قائمة طويلة!',
    'l5t': 'أول خطوة على الميزان', 'l5s': 'زِن 500 غ من الفواكه', 'l6t': 'كيلو كامل', 'l6s': '1 كغ = 1000 غ',
    'l7t': 'الوزن الصحيح', 'l7s': 'زِن الفواكه مع واكي!', 'l8t': 'الوزن الكبير', 'l8s': 'اخلط الأوزان',
    'l9t': 'أول قطعة نقود', 'l9s': 'ادفع بـ 1 و2 و5 دراهم', 'l10t': 'أدفع مشترياتي', 'l10s': 'ادفع الثمن الصحيح',
    'l11t': 'أُرجع الباقي', 'l11s': 'الزبون يعطي 10 دراهم', 'l12t': 'التاجر الذكي', 'l12s': 'الزبون يعطي 20 درهماً',
  },
  'de': {
    'title1': 'Der kleine', 'title2': 'Markt', 'tag': 'Ein Abenteuer im Souk!',
    'w0': 'Einkaufen', 'w1': 'Die Waage', 'w2': 'Das Geld',
    's0': 'Ich erkenne', 's1': 'Ich wiege', 's2': 'Ich zähle',
    'play': 'Spielen', 'choose': 'Level wählen', 'how': 'Wie spielt man?', 'done': '{n} Level geschafft',
    'mapTitle1': 'Die Wege', 'mapTitle2': 'des Souks', 'level': 'Level {n}', 'locked': 'Schaffe erst das Level davor!',
    'listTitle1': 'Meine', 'listTitle2': 'Einkaufsliste', 'listSay': 'Schau dir die Bilder an und füll deinen Korb!',
    'goMarket': 'Auf zum Markt!', 'noTimer': 'In deinem Tempo · Ohne Uhr',
    'fillTitle1': 'Ich fülle', 'fillTitle2': 'meinen Korb', 'check': 'Korb prüfen',
    'tapFruit': 'Tippe auf Obst, um es in den Korb zu legen!',
    'missing': 'Es fehlen noch {n} {item}!', 'tooMany': 'Zu viele {item}!', 'notList': '{item} stehen nicht auf der Liste!',
    'weighTitle1': 'Das richtige', 'weighTitle2': 'Gewicht', 'prepare': 'Wiege {w} {item} ab',
    'weighSay': 'Leg {item} dazu bis {w}!', 'goal': 'Ziel: {w}', 'remove': 'Weg', 'restart': 'Neu',
    'verify': 'Prüfen', 'tooHeavy': 'Zu schwer! Nimm eins weg.', 'notEnough': 'Noch nicht genug, leg eins dazu!',
    'payTitle1': 'Ich bezahle', 'payTitle2': 'den Einkauf', 'paySay': 'Wähle Münzen für {n} DH.',
    'putCoins': 'Leg deine Münzen hierhin', 'purse': 'Mein Geldbeutel', 'payBtn': '{n} DH zahlen', 'clear': 'Alles weg',
    'fake': 'Spielgeld · Kein echter Kauf', 'payLess': 'Es fehlen {n} DH!', 'payMore': 'Zu viel, {n} DH mehr!',
    'changeTitle1': 'Ich gebe', 'changeTitle2': 'das Wechselgeld', 'price': 'Preis:', 'gives': 'Der Kunde gibt:',
    'howMuch': 'Wie viel gibst du zurück?', 'myChange': 'Wechselgeld: {n} DH', 'pick': 'Wähle deine Münzen',
    'giveBtn': 'Wechselgeld geben', 'changeSay': 'Zähl bis {n}, um zu prüfen!',
    'bravo1': 'Super,', 'bravo2': 'kleiner Händler!', 'mission': 'Mission geschafft!', 'rewards': 'Belohnungen', 'badge': 'Neues Abzeichen',
    'badgeName': 'Kleiner Händler', 'next': 'Nächstes Level', 'again': 'Nochmal', 'map': 'Level-Karte',
    'r0': 'Liste fertig', 'r1': 'Richtig gewogen', 'r2': 'Richtig gezählt',
    'good': 'Gut gemacht!', 'goodSub': 'Du hast die richtige Menge!', 'continue': 'Weiter',
    'effort': 'Noch ein kleiner Versuch!', 'retry': 'Nochmal', 'hint': 'Ein Tipp', 'hintTitle': 'Ein kleiner Tipp',
    'pause': 'Kleine Pause', 'resume': 'Weiter', 'quitQ': 'Zurück zur Karte?', 'quitSub': 'Das Level beginnt neu.',
    'keep': 'Weiterspielen', 'quit': 'Level verlassen', 'go': 'Los geht’s!', 'understood': 'Verstanden!',
    'h1': 'Schau auf die Liste', 'h2': 'Tippe auf das Obst', 'h3': 'Prüfe den Einkauf',
    'hintBasket': 'Leg noch {n} {item} dazu.', 'hintScale': 'Es fehlen {w}.', 'hintScaleOver': 'Nimm {w} weg.',
    'hintPay': 'Versuch eine {n}-DH-Münze.', 'allGood': 'Alles richtig, tippe auf Prüfen!',
    'l1t': 'Mein erster Einkauf', 'l1s': 'Füll den Korb mit Waki!', 'l2t': 'Der Morgenkorb', 'l2s': 'Drei Sachen finden',
    'l3t': 'Der große Markt', 'l3s': 'Zähl jedes Obst', 'l4t': 'Der Festkorb', 'l4s': 'Eine lange Liste!',
    'l5t': 'Erste Schritte auf der Waage', 'l5s': 'Wiege 500 g Obst', 'l6t': 'Ein ganzes Kilo', 'l6s': '1 kg = 1000 g',
    'l7t': 'Das richtige Gewicht', 'l7s': 'Wiege Obst mit Waki!', 'l8t': 'Das große Wiegen', 'l8s': 'Gewichte mischen',
    'l9t': 'Meine erste Münze', 'l9s': 'Zahl mit 1, 2 und 5 DH', 'l10t': 'Ich bezahle', 'l10s': 'Zahl den richtigen Preis',
    'l11t': 'Ich gebe Wechselgeld', 'l11s': 'Der Kunde gibt 10 DH', 'l12t': 'Der schlaue Händler', 'l12s': 'Der Kunde gibt 20 DH',
  },
};
