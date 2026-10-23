import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'm1_text.dart';
import 'sc_assets.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Mathématiques — 1re année primaire.
// Five games, each with its own path of levels (modes × number ranges):
//   train     Le train des nombres   reconnaître · compter · mettre en ordre
//   basket    Les paniers à compter  je compte · je remplis · je compare
//   add       Les additions magiques avec des objets · sur une ligne · petits problèmes
//   treasure  Les trésors à retirer  j'enlève · je compte le reste · petits problèmes
//   shape     Le village des formes  je reconnais · je trie · je construis · les suites
// ═══════════════════════════════════════════════════════════════════════════

const String m1Dir = 'assets/images/Games/Math1/';
String m1(String n) => n.startsWith('sc_') ? '$scDir$n.webp' : '${m1Dir}m1_$n.webp';

/// Path of a scene picture: math ones are m1_bg_<name>, science ones sc_bg_<name>.
String m1BgPath(String a) => a.startsWith('sc_') ? m1(a) : '${m1Dir}m1_bg_$a.webp';

/// height / width of every sprite.
const Map<String, double> m1R = {
  'apple': 1.075, 'node_blue': 0.74, 'bubble': 0.6477, 'bubble_blue': 0.6789, 'apple2': 1.13, 'apples3': 0.7933, 'arc_arrow': 0.3095, 'arrow_dash': 1.45,
  'arrow_dl': 1.0922, 'arrow_dr': 1.1324, 'arrow_purple': 1.8182, 'arrow_up': 1.54, 'badge': 0.8219,
  'basket_3': 0.835, 'basket_apples': 0.8091, 'basket_apples2': 0.7233, 'basket_empty': 0.8483,
  'basket_gems': 0.8067, 'basket_green': 0.9393, 'basket_oranges': 0.7727, 'basket_pears': 0.7818,
  'basket_red': 0.9495, 'bell': 1.345, 'block_house': 0.5, 'blocks': 0.7933, 'book': 0.8938, 'bridge': 0.27,
  'btn_back': 1.0179, 'btn_back_b': 0.995, 'btn_back_p': 1.0192, 'btn_check': 0.2751, 'btn_hint_round': 1.0231,
  'btn_hint_sq': 0.8393, 'btn_home': 1.0065, 'btn_music': 1.0188, 'btn_music_p': 1.0403, 'btn_orange': 0.2651,
  'btn_pause': 0.9763, 'btn_play': 0.4539, 'btn_play_leaf': 0.2429, 'btn_play_small': 0.6043,
  'btn_restart_sq': 0.8393, 'btn_sound': 1.0299, 'btn_sound_p': 1.0129, 'btn_sound_t': 1.0, 'btn_teal': 0.2955,
  'bunny': 1.1522, 'bush1': 0.4356, 'bush2': 0.4182, 'card5': 1.0562, 'check': 1.02, 'chest': 1.081,
  'chest_gems': 0.6576, 'coin': 1.0045, 'conductor_point': 1.4103, 'conductor_wave': 1.4029,
  'cube_blue': 0.9882, 'cube_blue2': 0.9357, 'cube_green': 0.9774, 'cube_orange': 0.9706,
  'cube_purple': 0.9225, 'cube_red': 0.9348, 'cube_stack': 0.5848, 'cube_yellow': 0.9552, 'dot_b': 1.0253,
  'dot_blue': 0.9938, 'dot_o': 1.0127, 'ear': 1.3333, 'engine': 1.1149, 'engine2': 0.6667, 'equals': 0.7,
  'explorer_kneel': 1.1261, 'explorer_point': 1.0565, 'fox': 1.2775, 'fox_conductor': 0.8974,
  'fox_happy': 0.8696, 'frame_gold': 0.2213, 'frame_gold_sm': 0.5373, 'frame_leaf': 0.9969, 'gem': 0.8542,
  'gem_b': 1.1087, 'gem_g': 1.1544, 'gem_o': 1.1449, 'gem_p': 1.1295, 'gem_purple': 1.1667, 'gem_slot': 1.275,
  'hand_apple': 0.9567, 'hand_apple2': 0.6121, 'hand_card': 0.9367, 'hand_gem': 0.9909, 'hand_l': 1.0,
  'hand_point': 1.0462, 'hand_r': 0.9939, 'hand_tap': 1.165, 'house_circle': 1.0325, 'house_shop': 0.9316,
  'house_square': 1.0653, 'house_triangle': 1.0906, 'hut_blue': 0.828, 'hut_circle': 1.1794, 'hut_red': 0.85,
  'hut_square': 1.1853, 'hut_triangle': 1.1824, 'hut_yellow': 0.7316, 'ic_basket': 0.8875, 'ic_minus': 0.4067,
  'ic_plus': 1.0268, 'ic_shapes': 0.7478, 'island': 0.5171, 'kid_cheer': 1.0048, 'kid_fists': 1.0522,
  'kid_point': 0.8587, 'node_done': 0.74, 'node_lock': 0.73, 'node_now': 0.7026, 'numline': 0.2985,
  'orange': 0.945, 'pear': 1.3, 'pill_minus': 0.4078, 'plank_book': 0.2294, 'plank_leaf': 0.2991,
  'plus': 0.9803, 'plus2': 0.9706, 'rails': 0.2575, 'ribbon': 0.2195, 'robot_123': 0.9977,
  'robot_jump': 1.0952, 'robot_plus': 0.837, 'robot_point_l': 0.9065, 'robot_point_r': 1.1609,
  'robot_relax': 0.8381, 'robot_small': 1.45, 'robot_thumb': 0.75, 'robot_tri': 1.13, 'robot_wink': 1.0944,
  'sh_circle_blue': 0.995, 'sh_circle_red': 0.995, 'sh_circle_red2': 0.9848, 'sh_square_blue': 0.9944,
  'sh_square_green': 1.015, 'sh_square_yellow': 0.995, 'sh_triangle_orange': 0.865, 'sh_triangle_purple': 0.86,
  'sh_triangle_yellow': 0.87, 'shell': 0.6577, 'shelter': 0.8684, 'sign_cloud': 0.415, 'sign_cloud2': 0.38,
  'sign_cloud3': 0.4064, 'sign_jungle': 0.5875, 'sign_jungle2': 0.3563, 'sign_leaf': 0.4676,
  'sign_leaf2': 0.4949, 'sign_plank': 0.5063, 'sign_star': 0.2462, 'sign_wood': 0.4714, 'sign_wood2': 0.582,
  'sorter': 0.2766, 'star': 0.95, 'station': 0.7481, 'thumb_add': 0.375, 'thumb_basket': 0.375,
  'thumb_shape': 0.375, 'thumb_train': 0.375, 'thumb_treasure': 0.375, 'tile_b': 0.965, 'tile_r': 0.995,
  'tile_y': 0.975, 'topbar': 0.2711, 'toy_train': 0.2883, 'train_0123': 0.3719, 'tray6': 0.21,
  'trophy': 0.8269, 'tunnel': 0.7761, 'wagon_dash': 0.8067, 'wagon_g': 1.0888, 'wagon_p': 1.1032,
  'wagon_r': 1.0808, 'wagon_y': 1.0731,
};
double m1Ratio(String n) => m1R[n] ?? scR[n] ?? 1.0;

const Color m1Ink = Color(0xFF3F1A9B);
const Color m1InkSoft = Color(0xFF6A5A92);
const Color m1Blue = Color(0xFF1F6FE0);
const Color m1Teal = Color(0xFF14B3C7);
const Color m1Orange = Color(0xFFF7811E);
const Color m1Green = Color(0xFF2FAE48);
const Color m1Red = Color(0xFFE5404A);
const Color m1Yellow = Color(0xFFFFC21A);
const Color m1Purple = Color(0xFF7B3FE4);
const Color m1Cream = Color(0xFFFFF8E8);
const Color m1Line = Color(0xFFF1D9A6);

/// Colours used for big digits (like the number cards of the mockups).
const List<Color> m1DigitColors = [
  Color(0xFF7B3FE4), Color(0xFFE5404A), Color(0xFFF7811E), Color(0xFFF5B400), Color(0xFF2FAE48),
  Color(0xFF14A9C7), Color(0xFF1F6FE0), Color(0xFFB04FE0), Color(0xFFE5408A), Color(0xFF8D45E8),
];
Color m1DigitColor(int n) => m1DigitColors[n.abs() % m1DigitColors.length];

TextStyle m1Text(double size, {Color color = m1Ink, FontWeight weight = FontWeight.w700, double? height}) =>
    TextStyle(fontFamily: 'Fredoka', fontSize: size, color: color, fontWeight: weight, height: height);

/// Text with a soft outline (titles, big numbers).
Widget m1Outlined(String t, double size,
        {Key? key, Color color = m1Ink, Color outline = Colors.white, double stroke = 0.16, int maxLines = 1, TextAlign align = TextAlign.center, double? height}) =>
    Stack(key: key, children: [
      Text(t,
          maxLines: maxLines,
          textAlign: align,
          style: m1Text(size, weight: FontWeight.w800, height: height).copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * stroke
              ..strokeJoin = StrokeJoin.round
              ..color = outline,
            shadows: [Shadow(color: Colors.black.withOpacity(0.22), offset: Offset(0, size * 0.06), blurRadius: size * 0.06)],
          )),
      Text(t, maxLines: maxLines, textAlign: align, style: m1Text(size, color: color, weight: FontWeight.w800, height: height)),
    ]);

/// A big colourful number like on the mockups' answer cards.
Widget m1Number(int n, double size, {Key? key, Color? color}) => m1Outlined('$n', size, key: key, color: color ?? m1DigitColor(n), stroke: 0.12);

// ── sound & voice ──────────────────────────────────────────────────────────

void m1Sound(BuildContext c, String key) {
  try {
    Provider.of<AudioManager>(c, listen: false).playEventSound(key);
  } catch (_) {}
}

void m1Sfx(BuildContext c, String file) {
  try {
    Provider.of<AudioManager>(c, listen: false).playSfx('assets/audios/UI_Audio/SFX_Audio/$file');
  } catch (_) {}
}

class M1Voice {
  static final FlutterTts _tts = FlutterTts();
  static bool muted = false;
  static Future<void> say(BuildContext c, String text) async {
    if (muted || text.isEmpty) return;
    try {
      final lang = switch (m1Lang(c)) { 'fr' => 'fr-FR', 'ar' => 'ar-SA', _ => 'en-US' };
      await _tts.stop();
      await _tts.setLanguage(lang);
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.12);
      await _tts.speak(text);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

// ── progress ───────────────────────────────────────────────────────────────

class M1Store {
  static String _k(String game, int level) => 'm1_${game}_$level';

  static Future<List<int>> stars(String game, int count) async {
    final p = await SharedPreferences.getInstance();
    return [for (var i = 0; i < count; i++) p.getInt(_k(game, i)) ?? 0];
  }

  /// Saves if better; returns the stars there were before.
  static Future<int> record(String game, int level, int stars) async {
    final p = await SharedPreferences.getInstance();
    final old = p.getInt(_k(game, level)) ?? 0;
    if (stars > old) await p.setInt(_k(game, level), stars);
    return old;
  }

  static bool unlocked(List<int> stars, int level) => level == 0 || (level - 1 < stars.length && stars[level - 1] > 0);

  /// First level not finished yet (or the last one).
  static int next(List<int> stars) {
    for (var i = 0; i < stars.length; i++) {
      if (stars[i] == 0) return i;
    }
    return stars.length - 1;
  }

  static Future<bool> seenHelp(String game) async => (await SharedPreferences.getInstance()).getBool('m1_help_$game') ?? false;
  static Future<void> setSeenHelp(String game) async => (await SharedPreferences.getInstance()).setBool('m1_help_$game', true);
}

// ── layout ─────────────────────────────────────────────────────────────────

bool m1Rtl(BuildContext c) => Directionality.of(c) == TextDirection.rtl;

class _M1FrameMark extends InheritedWidget {
  const _M1FrameMark({required super.child});
  @override
  bool updateShouldNotify(_M1FrameMark oldWidget) => false;
}

/// Lays the page out on a phone-sized design canvas (390 wide, at least 780
/// high) and scales it to the real screen.
class M1Frame extends StatelessWidget {
  final Widget child;
  const M1Frame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (context.dependOnInheritedWidgetOfExactType<_M1FrameMark>() != null) return child;
    final mq = MediaQuery.of(context);
    final W = mq.size.width, H = mq.size.height;
    if (W <= 0 || H <= 0) return child;
    final k = min(min(W / 390, H / 780), 1.35).toDouble();
    final dw = W / k, dh = H / k;
    EdgeInsets d(EdgeInsets e) => EdgeInsets.fromLTRB(e.left / k, e.top / k, e.right / k, e.bottom / k);
    return _M1FrameMark(
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

/// Full-screen scene picture, top-anchored, with drifting sparkles.
class M1Bg extends StatelessWidget {
  final String asset;
  final bool sparkles;
  const M1Bg({super.key, required this.asset, this.sparkles = true});
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        const ColoredBox(color: Color(0xFFF6E9C8)),
        Image.asset(m1BgPath(asset), fit: BoxFit.cover, alignment: Alignment.topCenter),
        if (sparkles) const IgnorePointer(child: M1Sparkles()),
      ]);
}

/// Shows a sprite at [width] keeping its ratio.
Widget m1Img(String name, double width, {BoxFit fit = BoxFit.contain, Key? key}) =>
    Image.asset(m1(name), key: key, width: width, height: width * m1Ratio(name), fit: fit, gaplessPlayback: true);

// ── buttons ────────────────────────────────────────────────────────────────

class M1Press extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? label;
  final String sound;
  const M1Press({super.key, required this.child, required this.onTap, this.scale = 0.9, this.label, this.sound = 'clickButton'});
  @override
  State<M1Press> createState() => _M1PressState();
}

class _M1PressState extends State<M1Press> {
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
                  if (widget.sound.isNotEmpty) m1Sound(context, widget.sound);
                  widget.onTap!();
                },
          child: AnimatedScale(
            scale: _down ? widget.scale : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      );
}

/// Round sprite button (back, sound, music, home, pause, hint …).
Widget m1Round(BuildContext c, String sprite, double size, VoidCallback onTap, {bool flipRtl = false, String? label}) => M1Press(
      onTap: onTap,
      label: label,
      child: Transform.flip(flipX: flipRtl && m1Rtl(c), child: Image.asset(m1(sprite), width: size, height: size, fit: BoxFit.contain)),
    );

/// Text inside a fractional area of a sprite.
Widget m1OnSprite(String sprite, double width, Widget child,
    {EdgeInsets area = const EdgeInsets.fromLTRB(0.12, 0.2, 0.12, 0.2), Alignment align = Alignment.center, bool flip = false}) {
  final h = width * m1Ratio(sprite);
  return SizedBox(
    width: width,
    height: h,
    child: Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(child: Transform.flip(flipX: flip, child: Image.asset(m1(sprite), fit: BoxFit.fill))),
      Positioned(
        left: width * area.left,
        right: width * area.right,
        top: h * area.top,
        bottom: h * area.bottom,
        child: Align(alignment: align, child: FittedBox(fit: BoxFit.scaleDown, child: child)),
      ),
    ]),
  );
}

/// The big orange "Jouer ▶" button (sprite with the play arrow) plus label.
class M1PlayButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double width;
  final String sprite;
  final Animation<double>? pulse;
  const M1PlayButton({super.key, required this.label, required this.onTap, required this.width, this.sprite = 'btn_play', this.pulse});
  @override
  Widget build(BuildContext context) {
    final h = width * m1Ratio(sprite);
    // where the white arrow sits on each sprite, so the label goes to its right
    final (double l, double r, double t, double b) = switch (sprite) {
      'btn_play_leaf' => (0.4, 0.14, 0.18, 0.24),
      'btn_play_small' => (0.38, 0.1, 0.2, 0.22),
      _ => (0.4, 0.08, 0.16, 0.2),
    };
    Widget btn = SizedBox(
      width: width,
      height: h,
      child: Stack(children: [
        Positioned.fill(child: Image.asset(m1(sprite), fit: BoxFit.fill)),
        Positioned(
          left: width * l,
          right: width * r,
          top: h * t,
          bottom: h * b,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: m1Outlined(label, h * 0.42, color: Colors.white, outline: const Color(0xFFC84A06), stroke: 0.12),
          ),
        ),
      ]),
    );
    if (pulse != null) {
      btn = AnimatedBuilder(animation: pulse!, builder: (_, c) => Transform.scale(scale: 1 + 0.035 * sin(pulse!.value * 2 * pi * 3), child: c), child: btn);
    }
    return Opacity(opacity: onTap == null ? 0.55 : 1, child: M1Press(onTap: onTap, label: label, sound: 'PopButton', child: btn));
  }
}

/// Flat orange button drawn in code (any width) — "Vérifier", "Niveau suivant".
class M1OrangeButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final double width, height;
  final Color top, bottom, edge;
  final Animation<double>? pulse;
  const M1OrangeButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.width,
    this.height = 56,
    this.icon,
    this.top = const Color(0xFFFFA23A),
    this.bottom = const Color(0xFFF2620C),
    this.edge = const Color(0xFFC9480A),
    this.pulse,
  });
  @override
  Widget build(BuildContext context) {
    Widget b = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]),
        border: Border.all(color: const Color(0xFFFFD35A), width: 2.5),
        boxShadow: [
          BoxShadow(color: edge, offset: const Offset(0, 4)),
          BoxShadow(color: bottom.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(children: [
        Positioned(
          left: height * 0.35,
          right: height * 0.35,
          top: 4,
          height: height * 0.28,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.28), borderRadius: BorderRadius.circular(height)),
          ),
        ),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: height * 0.3),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: height * 0.52, shadows: [Shadow(color: edge, offset: const Offset(0, 2))]),
                  SizedBox(width: height * 0.15),
                ],
                m1Outlined(label, height * 0.42, color: Colors.white, outline: edge, stroke: 0.12),
              ]),
            ),
          ),
        ),
      ]),
    );
    if (pulse != null) {
      b = AnimatedBuilder(animation: pulse!, builder: (_, c) => Transform.scale(scale: 1 + 0.03 * sin(pulse!.value * 2 * pi * 3), child: c), child: b);
    }
    return AnimatedOpacity(
      opacity: onTap == null ? 0.5 : 1,
      duration: const Duration(milliseconds: 200),
      child: M1Press(onTap: onTap, label: label, sound: 'PopButton', child: b),
    );
  }
}

/// Cream pill with a purple outline and an icon ("Mes niveaux", "Comment jouer ?").
class M1OutlineButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final double width, height;
  final Color fill, line;
  const M1OutlineButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.width,
    this.height = 42,
    this.fill = m1Cream,
    this.line = const Color(0xFF5B2BB5),
  });
  @override
  Widget build(BuildContext context) => M1Press(
        onTap: onTap,
        label: label,
        child: Container(
          width: width,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: height * 0.3),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: line, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 3))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(width: height * 0.55, height: height * 0.55, child: FittedBox(child: icon)),
            SizedBox(width: height * 0.2),
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: m1Text(height * 0.38)))),
          ]),
        ),
      );
}

/// Purple "levels" bars icon.
class M1BarsIcon extends StatelessWidget {
  final double size;
  final Color color;
  const M1BarsIcon({super.key, this.size = 22, this.color = const Color(0xFF4A1D9E)});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          for (final f in const [0.45, 0.7, 1.0])
            Container(width: size * 0.22, height: size * f, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * 0.05))),
        ]),
      );
}

/// Purple disc with a white "?".
Widget m1QuestionIcon(double size) => Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Color(0xFF4A1D9E), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text('?', style: m1Text(size * 0.68, color: Colors.white, weight: FontWeight.w800, height: 1.1)),
    );

// ── panels ─────────────────────────────────────────────────────────────────

/// Soft cream card with a golden rim, like the UI sheets.
class M1Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color fill, rim;
  final bool glow;
  final double rimWidth;
  final double? width, height;
  const M1Card({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 22,
    this.fill = m1Cream,
    this.rim = m1Line,
    this.glow = false,
    this.rimWidth = 2.5,
    this.width,
    this.height,
  });
  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(fill, Colors.white, 0.45)!, fill],
          ),
          border: Border.all(color: rim, width: rimWidth),
          boxShadow: [
            if (glow) BoxShadow(color: rim.withOpacity(0.75), blurRadius: 16, spreadRadius: 1),
            BoxShadow(color: const Color(0xFF8A5A1A).withOpacity(0.18), offset: const Offset(0, 5), blurRadius: 8),
          ],
        ),
        child: child,
      );
}

/// Golden-rimmed big board (additions & treasure panels).
class M1GoldBoard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  const M1GoldBoard({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.radius = 28});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFD866), Color(0xFFF2A812)]),
          boxShadow: [
            BoxShadow(color: const Color(0xFFB66A00).withOpacity(0.35), offset: const Offset(0, 6), blurRadius: 10),
            BoxShadow(color: const Color(0xFFFFD35A).withOpacity(0.5), blurRadius: 18),
          ],
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius - 5),
            color: const Color(0xFFFFF6E2),
            border: Border.all(color: const Color(0xFFFFF0C4), width: 2),
          ),
          child: child,
        ),
      );
}

/// Cream rounded tile for an answer (big number inside).
class M1Tile extends StatelessWidget {
  final Widget child;
  final double width, height;
  final M1TileState state;
  final Color? rim;
  const M1Tile({super.key, required this.child, required this.width, required this.height, this.state = M1TileState.idle, this.rim});
  @override
  Widget build(BuildContext context) {
    final border = switch (state) {
      M1TileState.good => const Color(0xFF39C35A),
      M1TileState.bad => const Color(0xFFFF6B6B),
      M1TileState.selected => const Color(0xFF39B8F2),
      M1TileState.idle => rim ?? const Color(0xFFF0DDB2),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(min(width, height) * 0.22),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: switch (state) {
            M1TileState.good => const [Color(0xFFEFFFE9), Color(0xFFD5F7CB)],
            M1TileState.bad => const [Color(0xFFFFF1F0), Color(0xFFFFDCDC)],
            _ => const [Color(0xFFFFFDF6), Color(0xFFFFF1D6)],
          },
        ),
        border: Border.all(color: border, width: state == M1TileState.idle ? 2.5 : 4),
        boxShadow: [
          BoxShadow(color: const Color(0xFFC49A52).withOpacity(0.45), offset: const Offset(0, 5)),
          if (state != M1TileState.idle) BoxShadow(color: border.withOpacity(0.55), blurRadius: 14),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

enum M1TileState { idle, selected, good, bad }

/// Shakes its child when [trigger] changes (wrong answer).
class M1Shake extends StatefulWidget {
  final Widget child;
  final int trigger;
  const M1Shake({super.key, required this.child, required this.trigger});
  @override
  State<M1Shake> createState() => _M1ShakeState();
}

class _M1ShakeState extends State<M1Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  @override
  void didUpdateWidget(M1Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && widget.trigger > 0) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, c) => Transform.translate(offset: Offset(sin(_c.value * pi * 6) * 9 * (1 - _c.value), 0), child: c),
        child: widget.child,
      );
}

/// Gentle floating (up/down + tilt) for characters and props.
class M1Float extends StatefulWidget {
  final Widget child;
  final double amp, tilt;
  final Duration period;
  final double phase;
  const M1Float({super.key, required this.child, this.amp = 5, this.tilt = 0.02, this.period = const Duration(milliseconds: 2600), this.phase = 0});
  @override
  State<M1Float> createState() => _M1FloatState();
}

class _M1FloatState extends State<M1Float> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, c) {
          final t = (_c.value + widget.phase) * 2 * pi;
          return Transform.translate(
            offset: Offset(0, sin(t) * widget.amp),
            child: Transform.rotate(angle: sin(t + 0.6) * widget.tilt, child: c),
          );
        },
        child: widget.child,
      );
}

/// Pops in with a bounce after [delay].
class M1PopIn extends StatelessWidget {
  final Widget child;
  final int delay; // ms
  final double from;
  const M1PopIn({super.key, required this.child, this.delay = 0, this.from = 0.4});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 520 + delay),
        curve: Interval(delay / (520 + delay), 1, curve: Curves.easeOutBack),
        builder: (_, v, c) => Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(scale: from + (1 - from) * v, child: c),
        ),
        child: child,
      );
}

/// Slides up and fades in after [delay].
class M1SlideIn extends StatelessWidget {
  final Widget child;
  final int delay;
  final double dy;
  const M1SlideIn({super.key, required this.child, this.delay = 0, this.dy = 30});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 480 + delay),
        curve: Interval(delay / (480 + delay), 1, curve: Curves.easeOutCubic),
        builder: (_, v, c) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, dy * (1 - v)), child: c)),
        child: child,
      );
}

/// Speech bubble (cream, with a tail to the left or right).
class M1Bubble extends StatelessWidget {
  final String text;
  final double width;
  final bool tailRight;
  final bool blue;
  const M1Bubble({super.key, required this.text, required this.width, this.tailRight = false, this.blue = false});
  @override
  Widget build(BuildContext context) {
    final tr = tailRight != m1Rtl(context);
    final sprite = blue ? 'bubble_blue' : 'bubble';
    final h = width * m1Ratio(sprite);
    return SizedBox(
      width: width,
      height: h,
      child: Stack(children: [
        Positioned.fill(child: Transform.flip(flipX: tr, child: Image.asset(m1(sprite), fit: BoxFit.fill))),
        Positioned(
          left: width * 0.08,
          right: width * 0.08,
          top: h * 0.1,
          bottom: h * (blue ? 0.3 : 0.28),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
              child: FittedBox(
                key: ValueKey(text),
                fit: BoxFit.scaleDown,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width * 0.84),
                  child: Text(text, textAlign: TextAlign.center, maxLines: 3, style: m1Text(width * 0.088, height: 1.15)),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Instruction pill with a speaker button that reads it aloud.
class M1SayPill extends StatelessWidget {
  final String text;
  final double width;
  final double height;
  final bool blue;
  const M1SayPill({super.key, required this.text, required this.width, this.height = 52, this.blue = false});
  @override
  Widget build(BuildContext context) => M1Press(
        onTap: () => M1Voice.say(context, text),
        scale: 0.97,
        label: text,
        sound: '',
        child: Container(
          width: width,
          height: height,
          padding: EdgeInsetsDirectional.only(start: 6, end: height * 0.35),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9EA),
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: blue ? const Color(0xFF55B9F5) : m1Line, width: blue ? 3 : 2.5),
            boxShadow: [
              BoxShadow(color: const Color(0xFFB98B3E).withOpacity(0.25), offset: const Offset(0, 4), blurRadius: 6),
              if (blue) BoxShadow(color: const Color(0xFF55B9F5).withOpacity(0.35), blurRadius: 12),
            ],
          ),
          child: Row(children: [
            Container(
              width: height - 12,
              height: height - 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8A4BEA), Color(0xFF5A1FB8)]),
              ),
              child: Icon(Icons.volume_up_rounded, color: Colors.white, size: height * 0.46),
            ),
            SizedBox(width: height * 0.22),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, 0.35), end: Offset.zero).animate(a), child: c)),
                child: Align(
                  key: ValueKey(text),
                  alignment: AlignmentDirectional.centerStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: width * 0.78),
                      child: Text(text, maxLines: 2, style: m1Text(height * 0.36, height: 1.12)),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      );
}

/// Round progress dots (green = done, blue = now, grey = to come).
class M1Dots extends StatelessWidget {
  final int total, done;
  final double size;
  final List<bool>? perfect; // optional per-challenge result
  const M1Dots({super.key, required this.total, required this.done, this.size = 18, this.perfect});
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: size * 0.6, vertical: size * 0.45),
        decoration: BoxDecoration(
          color: m1Cream,
          borderRadius: BorderRadius.circular(size * 2),
          border: Border.all(color: m1Line, width: 2),
          boxShadow: [BoxShadow(color: const Color(0xFFB98B3E).withOpacity(0.25), offset: const Offset(0, 3), blurRadius: 5)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              margin: EdgeInsets.symmetric(horizontal: size * 0.14),
              width: i == done ? size * 1.15 : size,
              height: i == done ? size * 1.15 : size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.4),
                  colors: i < done
                      ? const [Color(0xFF8BEA6E), Color(0xFF2FAE48)]
                      : i == done
                          ? const [Color(0xFF7CC7FF), Color(0xFF1F6FE0)]
                          : const [Color(0xFFE6DED0), Color(0xFFC9BFAE)],
                ),
                boxShadow: [BoxShadow(color: const Color(0xFF1F6FE0).withOpacity(i == done ? 0.5 : 0), blurRadius: 8)],
              ),
            ),
        ]),
      );
}

/// Title sign: a sprite with a big title and an optional subtitle placed on it.
class M1Sign extends StatelessWidget {
  final String sprite;
  final String title;
  final String? title2;
  final String? sub;
  final double width;
  const M1Sign({super.key, required this.sprite, required this.title, this.title2, this.sub, required this.width});

  // (title area l,t,r,b), (sub area l,t,r,b), dark wood?
  static const Map<String, (List<double>, List<double>, bool)> _areas = {
    'sign_plank': ([0.12, 0.16, 0.12, 0.38], [0.22, 0.73, 0.22, 0.07], false),
    'sign_cloud': ([0.08, 0.12, 0.08, 0.16], [0, 0, 0, 0], false),
    'sign_cloud2': ([0.12, 0.1, 0.12, 0.3], [0.27, 0.73, 0.27, 0.08], false),
    'sign_cloud3': ([0.1, 0.08, 0.1, 0.34], [0.27, 0.74, 0.27, 0.08], false),
    'sign_star': ([0.18, 0.08, 0.18, 0.46], [0.3, 0.6, 0.3, 0.12], false),
    'sign_leaf': ([0.08, 0.2, 0.08, 0.34], [0.17, 0.72, 0.19, 0.08], false),
    'sign_leaf2': ([0.08, 0.25, 0.08, 0.32], [0.2, 0.74, 0.12, 0.06], false),
    'sign_wood': ([0.06, 0.2, 0.06, 0.24], [0.27, 0.8, 0.27, 0.05], true),
    'sign_wood2': ([0.06, 0.22, 0.06, 0.26], [0.3, 0.77, 0.3, 0.05], true),
    'sign_jungle': ([0.05, 0.3, 0.05, 0.25], [0.14, 0.8, 0.14, 0.05], true),
    'sign_jungle2': ([0.14, 0.12, 0.14, 0.48], [0.16, 0.6, 0.16, 0.18], true),
    'sc_sign_wood': ([0.16, 0.38, 0.16, 0.36], [0.32, 0.72, 0.32, 0.06], false),
    'sc_sign_wood2': ([0.12, 0.3, 0.12, 0.4], [0.28, 0.7, 0.28, 0.08], false),
    'sc_sign_cloud': ([0.14, 0.08, 0.14, 0.34], [0.3, 0.78, 0.3, 0.05], false),
    'sc_sign_cloud2': ([0.12, 0.06, 0.12, 0.3], [0.3, 0.8, 0.3, 0.04], false),
    'sc_sign_leafp': ([0.12, 0.14, 0.12, 0.4], [0.28, 0.68, 0.28, 0.1], false),
    'sc_sign_purple': ([0.12, 0.14, 0.12, 0.4], [0.28, 0.66, 0.28, 0.12], false),
    'sc_sign_leafy': ([0.12, 0.1, 0.12, 0.36], [0.2, 0.72, 0.2, 0.08], false),
    'sc_sign_leafy2': ([0.14, 0.08, 0.14, 0.36], [0.2, 0.74, 0.2, 0.06], false),
    'sc_sign_leafy3': ([0.14, 0.24, 0.14, 0.32], [0.3, 0.74, 0.3, 0.06], false),
    'sc_sign_leafy4': ([0.14, 0.2, 0.14, 0.48], [0.22, 0.6, 0.22, 0.12], false),
  };

  @override
  Widget build(BuildContext context) {
    final a = _areas[sprite] ?? ([0.1, 0.15, 0.1, 0.3], [0.25, 0.72, 0.25, 0.08], false);
    final h = width * m1Ratio(sprite);
    final dark = a.$3;
    final t = a.$1, sb = a.$2;
    final big = h * (1 - t[1] - t[3]) * (title2 == null ? 0.78 : 0.44);
    final col1 = dark ? const Color(0xFFFFC93A) : m1Ink;
    final col2 = dark ? const Color(0xFFB98CFF) : m1Orange;
    final outline = dark ? const Color(0xFF5A2A0E) : Colors.white;
    return SizedBox(
      width: width,
      height: h,
      child: Stack(children: [
        Positioned.fill(child: Image.asset(m1(sprite), fit: BoxFit.fill)),
        Positioned(
          left: width * t[0],
          right: width * t[2],
          top: h * t[1],
          bottom: h * t[3],
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                m1Outlined(title, big, color: col1, outline: outline, stroke: dark ? 0.2 : 0.16, height: 1.05),
                if (title2 != null) m1Outlined(title2!, big, color: col2, outline: outline, stroke: dark ? 0.2 : 0.16, height: 1.05),
              ]),
            ),
          ),
        ),
        if (sub != null && sb[1] > 0)
          Positioned(
            left: width * sb[0],
            right: width * sb[2],
            top: h * sb[1],
            bottom: h * sb[3],
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(sub!, maxLines: 1, style: m1Text(h * (1 - sb[1] - sb[3]) * 0.62, color: dark ? const Color(0xFF4E2C12) : m1Ink)),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Swings a hanging sign a little, like it was just hung.
class M1Swing extends StatelessWidget {
  final Widget child;
  const M1Swing({super.key, required this.child});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1600),
        builder: (_, v, c) => Transform.rotate(
          alignment: Alignment.topCenter,
          angle: sin(v * pi * 4) * 0.06 * (1 - v),
          child: Transform.translate(offset: Offset(0, -60 * pow(1 - min(1, v * 2.5), 2).toDouble()), child: c),
        ),
        child: child,
      );
}

// ── effects ────────────────────────────────────────────────────────────────

/// Drifting sparkles over the scene.
class M1Sparkles extends StatefulWidget {
  final int count;
  const M1Sparkles({super.key, this.count = 16});
  @override
  State<M1Sparkles> createState() => _M1SparklesState();
}

class _M1SparklesState extends State<M1Sparkles> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(painter: _SparklePainter(_c.value, widget.count), size: Size.infinite));
}

class _SparklePainter extends CustomPainter {
  final double t;
  final int n;
  _SparklePainter(this.t, this.n);
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(7);
    for (var i = 0; i < n; i++) {
      final x = r.nextDouble() * size.width;
      final sp = 0.4 + r.nextDouble() * 0.6;
      final y = size.height - ((t * sp + r.nextDouble()) % 1.0) * size.height;
      final tw = (sin((t * 20 + i) * 1.3) + 1) / 2;
      final rad = 1.5 + r.nextDouble() * 2.5;
      final p = Paint()..color = (i.isEven ? Colors.white : const Color(0xFFFFE27A)).withOpacity(0.25 + 0.5 * tw);
      _star(canvas, Offset(x + sin(t * 2 * pi * 3 + i) * 10, y), rad * (0.7 + tw * 0.6), p);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter o) => o.t != t;
}

void _star(Canvas canvas, Offset p, double rad, Paint paint) {
  final path = Path()
    ..moveTo(p.dx, p.dy - rad * 1.8)
    ..quadraticBezierTo(p.dx, p.dy, p.dx + rad * 1.8, p.dy)
    ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + rad * 1.8)
    ..quadraticBezierTo(p.dx, p.dy, p.dx - rad * 1.8, p.dy)
    ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - rad * 1.8)
    ..close();
  canvas.drawPath(path, paint);
}

/// Star burst centred in its box, driven by [t] 0→1.
class M1Burst extends CustomPainter {
  final double t;
  final int seed;
  M1Burst(this.t, {this.seed = 3});
  static const _c = [Color(0xFFFFC21A), Color(0xFF7DDB5A), Color(0xFF34D9CF), Color(0xFFFF8FB5), Color(0xFFFFFFFF), Color(0xFFB98CFF)];
  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final c = size.center(Offset.zero);
    final r = Random(seed);
    final e = Curves.easeOutCubic.transform(t);
    for (var i = 0; i < 22; i++) {
      final a = i / 22 * 2 * pi + r.nextDouble() * 0.4;
      final d = (0.3 + r.nextDouble() * 0.5) * size.shortestSide * e;
      final rad = (3 + r.nextDouble() * 4) * (1 - t * 0.5);
      _star(canvas, c + Offset(cos(a), sin(a)) * d, rad, Paint()..color = _c[i % _c.length].withOpacity((1 - t).clamp(0.0, 1.0)));
    }
  }

  @override
  bool shouldRepaint(M1Burst o) => o.t != t;
}

/// Confetti rain driven by [t] 0→1 (one fall).
class M1Confetti extends CustomPainter {
  final double t;
  M1Confetti(this.t);
  static const _c = [Color(0xFFFFC21A), Color(0xFF7DDB5A), Color(0xFF34D9CF), Color(0xFFFF6FA5), Color(0xFF7B3FE4), Color(0xFFF7811E)];
  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final r = Random(5);
    for (var i = 0; i < 70; i++) {
      final x0 = r.nextDouble() * size.width;
      final delay = r.nextDouble() * 0.35;
      final v = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (v <= 0) continue;
      final y = -20 + v * (size.height + 40) * (0.7 + r.nextDouble() * 0.5);
      final x = x0 + sin(v * 8 + i) * 22;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(v * 10 + i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 9, height: 5), const Radius.circular(2)),
        Paint()..color = _c[i % _c.length].withOpacity(1 - v * 0.6),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(M1Confetti o) => o.t != t;
}

/// Tapping hand that hovers over a spot to show what to do.
class M1HintHand extends StatefulWidget {
  final double size;
  final String sprite;
  const M1HintHand({super.key, this.size = 56, this.sprite = 'hand_tap'});
  @override
  State<M1HintHand> createState() => _M1HintHandState();
}

class _M1HintHandState extends State<M1HintHand> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, c) => Transform.translate(
            offset: Offset(_c.value * 6, _c.value * 10),
            child: Transform.scale(scale: 1 - _c.value * 0.08, child: c),
          ),
          child: m1Img(widget.sprite, widget.size),
        ),
      );
}

/// Full screen "Bravo !" with a robot, shown for a moment.
Future<void> m1Cheer(BuildContext context, String text, {String robot = 'robot_thumb'}) async {
  final entry = OverlayEntry(builder: (_) => _M1CheerOverlay(text: text, robot: robot));
  Overlay.of(context).insert(entry);
  await Future.delayed(const Duration(milliseconds: 1500));
  entry.remove();
}

class _M1CheerOverlay extends StatefulWidget {
  final String text, robot;
  const _M1CheerOverlay({required this.text, required this.robot});
  @override
  State<_M1CheerOverlay> createState() => _M1CheerOverlayState();
}

class _M1CheerOverlayState extends State<_M1CheerOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final t = _c.value;
            final inV = Curves.easeOutBack.transform((t / 0.3).clamp(0.0, 1.0));
            final out = ((t - 0.8) / 0.2).clamp(0.0, 1.0);
            return Opacity(
              opacity: 1 - out,
              child: Stack(children: [
                Positioned.fill(child: ColoredBox(color: Colors.black.withOpacity(0.18 * (1 - out)))),
                Positioned.fill(child: CustomPaint(painter: M1Confetti(t))),
                Center(
                  child: Transform.scale(
                    scale: 0.3 + 0.7 * inV,
                    child: Material(
                      type: MaterialType.transparency,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Image.asset(m1(widget.robot), width: 170),
                        const SizedBox(height: 6),
                        m1Outlined(widget.text, 44, color: m1Yellow, outline: m1Ink, stroke: 0.2),
                      ]),
                    ),
                  ),
                ),
              ]),
            );
          },
        ),
      );
}

/// Opens a dialog with a pop animation.
Future<T?> m1Dialog<T>(BuildContext context, Widget child, {bool dismissible = true}) => showGeneralDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: 'close',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => child,
      transitionBuilder: (_, a, __, c) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
      ),
    );

/// Number words are left to the voice; this gives a shuffled list of answer choices around [answer].
List<int> m1Choices(int answer, Random rng, {int count = 3, int min0 = 0, int max0 = 20}) {
  final set = <int>{answer};
  var spread = 1;
  var guard = 0;
  while (set.length < count && guard++ < 200) {
    final d = (rng.nextInt(spread * 2 + 1) - spread);
    final v = answer + (d == 0 ? (rng.nextBool() ? 1 : -1) : d);
    if (v >= min0 && v <= max0) set.add(v);
    if (guard % 6 == 5) spread++;
  }
  var extra = max0 + 1;
  while (set.length < count) {
    set.add(extra++);
  }
  return set.toList()..shuffle(rng);
}

/// A row of answer tiles with big numbers. [onPick] returns true when right.
class M1ChoiceRow extends StatefulWidget {
  final List<int> options;
  final bool Function(int value) onPick;
  final double width, height;
  final bool enabled;
  final int? hintValue; // gently pulses this one when set
  const M1ChoiceRow({super.key, required this.options, required this.onPick, required this.width, this.height = 96, this.enabled = true, this.hintValue});
  @override
  State<M1ChoiceRow> createState() => _M1ChoiceRowState();
}

class _M1ChoiceRowState extends State<M1ChoiceRow> with SingleTickerProviderStateMixin {
  final Map<int, M1TileState> _st = {};
  final Map<int, int> _shake = {};
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _tap(int v) {
    if (!widget.enabled || _st[v] == M1TileState.good) return;
    final ok = widget.onPick(v);
    setState(() {
      _st[v] = ok ? M1TileState.good : M1TileState.bad;
      if (!ok) _shake[v] = (_shake[v] ?? 0) + 1;
    });
    if (!ok) {
      Future.delayed(const Duration(milliseconds: 750), () {
        if (mounted && _st[v] == M1TileState.bad) setState(() => _st[v] = M1TileState.idle);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.options.length;
    final gap = 12.0;
    final tw = min((widget.width - gap * (n - 1)) / n, widget.height * 1.25);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < n; i++) ...[
          if (i > 0) SizedBox(width: gap),
          M1PopIn(
            delay: 90 * i,
            child: M1Shake(
              trigger: _shake[widget.options[i]] ?? 0,
              child: M1Press(
                onTap: widget.enabled ? () => _tap(widget.options[i]) : null,
                sound: '',
                label: '${widget.options[i]}',
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, c) => Transform.scale(
                    scale: widget.hintValue == widget.options[i] ? 1 + 0.06 * _pulse.value : (_st[widget.options[i]] == M1TileState.good ? 1.08 : 1),
                    child: c,
                  ),
                  child: M1Tile(
                    width: tw,
                    height: widget.height,
                    state: widget.hintValue == widget.options[i] && _st[widget.options[i]] == null ? M1TileState.selected : (_st[widget.options[i]] ?? M1TileState.idle),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(padding: const EdgeInsets.all(6), child: m1Number(widget.options[i], widget.height * 0.62)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

/// Colourful number line (chips joined by a line), the [marked] ones lit.
class M1NumberLine extends StatelessWidget {
  final int from, to, step;
  final Set<int> marked;
  final int? glow;
  final double width;
  const M1NumberLine({super.key, required this.from, required this.to, this.step = 1, this.marked = const {}, this.glow, required this.width});
  static const _chip = [
    Color(0xFFD9D2EC), Color(0xFFFFA9C6), Color(0xFFFFC08A), Color(0xFFFFE07A), Color(0xFF9BE59A), Color(0xFF9EE6FA),
    Color(0xFF8DBBFF), Color(0xFFE2B4FF), Color(0xFFFFA9D5), Color(0xFFF7AAF2), Color(0xFFD9A6FF),
  ];
  @override
  Widget build(BuildContext context) {
    final nums = [for (var v = from; v <= to; v += step) v];
    final n = nums.length;
    final cw = min(34.0, (width - 24) / (n * 1.18));
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: m1Cream,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: m1Line, width: 2),
          boxShadow: [BoxShadow(color: const Color(0xFFB98B3E).withOpacity(0.25), offset: const Offset(0, 4), blurRadius: 6)],
        ),
        child: Stack(alignment: Alignment.center, children: [
          Positioned(left: cw / 2, right: cw / 2, child: Container(height: 2.5, color: const Color(0xFF5B2BB5))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (var i = 0; i < n; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: cw,
                height: cw * (nums[i] == glow ? 1.25 : 1),
                decoration: BoxDecoration(
                  color: marked.contains(nums[i]) || nums[i] == glow ? _chip[i % _chip.length] : const Color(0xFFF4EEE2),
                  borderRadius: BorderRadius.circular(cw * 0.25),
                  border: Border.all(
                    color: nums[i] == glow ? const Color(0xFF1F6FE0) : Color.lerp(_chip[i % _chip.length], Colors.black, 0.2)!,
                    width: nums[i] == glow ? 3 : 1.5,
                  ),
                  boxShadow: [if (nums[i] == glow) BoxShadow(color: const Color(0xFF39B8F2).withOpacity(0.7), blurRadius: 10)],
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(
                      marked.contains(nums[i]) || nums[i] == glow ? '${nums[i]}' : '${nums[i]}',
                      style: m1Text(cw * 0.55, color: marked.contains(nums[i]) || nums[i] == glow ? m1Ink : const Color(0xFFB9AE9C)),
                    ),
                  ),
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}
