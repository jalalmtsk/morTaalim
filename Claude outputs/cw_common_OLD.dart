import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Shared look of the "Collection world" (hub + the five islands)
// ═══════════════════════════════════════════════════════════════════════════

const String cwDir = 'assets/images/UI/CollectionWorld/';
String cw(String name) => '$cwDir$name.webp';
const String cwWorldBg = 'assets/images/UI/KidScene/it_page_bg.webp';

const Color cwInk = Color(0xFF2A1366);
const Color cwInkSoft = Color(0xFF6B5A9E);
const Color cwPurple = Color(0xFF6D3BF5);
const Color cwPurpleDeep = Color(0xFF4A1FB8);
const Color cwTeal = Color(0xFF13B5AE);
const Color cwCream = Color(0xFFFFF8EC);
const Color cwGold = Color(0xFFFFC21A);

TextStyle cwText(double size, {Color color = cwInk, FontWeight weight = FontWeight.w700, double? height}) =>
    TextStyle(fontFamily: 'Fredoka', fontSize: size, color: color, fontWeight: weight, height: height);

void cwSound(BuildContext context, String key) {
  try {
    Provider.of<AudioManager>(context, listen: false).playEventSound(key);
  } catch (_) {}
}

/// Opens an island with a soft zoom.
Future<T?> cwOpen<T>(BuildContext context, Widget page) {
  cwSound(context, 'clickButton');
  return Navigator.of(context).push<T>(PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a, __, child) {
      final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: c,
        child: ScaleTransition(scale: Tween(begin: 1.08, end: 1.0).animate(c), child: child),
      );
    },
  ));
}

bool cwRtl(BuildContext c) => Directionality.of(c) == TextDirection.rtl;

// ── text ────────────────────────────────────────────────────────────────────

String cwLang(BuildContext c) {
  final l = Localizations.localeOf(c).languageCode;
  return const ['fr', 'en', 'ar', 'de'].contains(l) ? l : (l == 'zgh' ? 'fr' : 'en');
}

String cwT(BuildContext c, String key, [Map<String, Object>? args]) {
  var s = _cwStrings[cwLang(c)]?[key] ?? _cwStrings['en']![key] ?? key;
  args?.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

/// Picks the right language from a {fr,en,ar,de} map.
String cwPick(BuildContext c, Map<String, String> m) => m[cwLang(c)] ?? m['en'] ?? m.values.first;

// ── pieces ──────────────────────────────────────────────────────────────────

class CwPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? label;
  const CwPress({super.key, required this.child, required this.onTap, this.scale = 0.93, this.label});
  @override
  State<CwPress> createState() => _CwPressState();
}

class _CwPressState extends State<CwPress> {
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
          child: AnimatedScale(
            scale: _down ? widget.scale : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      );
}

/// Sky world behind every screen ([night] = treasure cave look).
class CwWorldBg extends StatelessWidget {
  final bool night;
  const CwWorldBg({super.key, this.night = false});
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Image.asset(cwWorldBg, fit: BoxFit.cover),
        if (night)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCC1B1250), Color(0xB3261A6B), Color(0xE6130C38)],
              ),
            ),
          ),
      ]);
}

/// Twinkling stars / magic dust over a scene.
class CwSparkles extends StatelessWidget {
  final Animation<double> idle;
  final int count;
  final int seed;
  final Color color;
  const CwSparkles({super.key, required this.idle, this.count = 14, this.seed = 3, this.color = const Color(0xFFFFE27A)});
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: idle,
          builder: (_, __) => CustomPaint(painter: _SparklePainter(idle.value, count, seed, color)),
        ),
      );
}

class _SparklePainter extends CustomPainter {
  final double t;
  final int count, seed;
  final Color color;
  _SparklePainter(this.t, this.count, this.seed, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(seed);
    for (var i = 0; i < count; i++) {
      final x = r.nextDouble() * size.width;
      final y0 = r.nextDouble() * size.height;
      final speed = 0.5 + r.nextDouble();
      final phase = r.nextDouble();
      final tt = (t * speed + phase) % 1.0;
      final o = sin(tt * pi);
      final y = y0 - tt * 18;
      final rad = (2.5 + r.nextDouble() * 3.5) * (0.6 + o * 0.6);
      final p = Paint()..color = color.withOpacity(o * 0.95);
      final path = Path()
        ..moveTo(x, y - rad)
        ..quadraticBezierTo(x, y, x + rad, y)
        ..quadraticBezierTo(x, y, x, y + rad)
        ..quadraticBezierTo(x, y, x - rad, y)
        ..quadraticBezierTo(x, y, x, y - rad)
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter o) => o.t != t;
}

/// Gentle up/down float.
class CwFloat extends StatelessWidget {
  final Animation<double> idle;
  final double amp, speed, phase, tilt;
  final Widget child;
  const CwFloat({super.key, required this.idle, required this.child, this.amp = 5, this.speed = 1, this.phase = 0, this.tilt = 0});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: idle,
        builder: (_, c) {
          final v = sin((idle.value * speed + phase) * 2 * pi);
          return Transform.translate(
            offset: Offset(0, v * amp),
            child: tilt == 0 ? c : Transform.rotate(angle: v * tilt, child: c),
          );
        },
        child: child,
      );
}

/// Round back button (sprite).
class CwBack extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;
  const CwBack({super.key, required this.size, this.onTap});
  @override
  Widget build(BuildContext context) => CwPress(
        label: MaterialLocalizations.of(context).backButtonTooltip,
        onTap: onTap ??
            () {
              cwSound(context, 'cancelButton');
              Navigator.of(context).maybePop();
            },
        child: Transform.flip(flipX: cwRtl(context), child: Image.asset(cw('col_back'), width: size, height: size)),
      );
}

/// Title pill with stars (sprite) + optional subtitle line under the title.
class CwTitlePill extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double s;
  final bool dark;
  const CwTitlePill({super.key, required this.title, this.subtitle, required this.s, this.dark = false});
  @override
  Widget build(BuildContext context) {
    final h = subtitle == null ? 54 * s : 66 * s;
    return SizedBox(
      height: h,
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(
          child: Image.asset(dark ? cw('tr_bar_purple') : cw('col_title_pill'), fit: BoxFit.fill),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 30 * s),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(title, maxLines: 1, style: cwText(24 * s, color: dark ? Colors.white : cwPurpleDeep)),
            ),
            if (subtitle != null)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(subtitle!,
                    maxLines: 1,
                    style: cwText(13 * s, color: dark ? const Color(0xFFFFE9A8) : cwInkSoft, weight: FontWeight.w600)),
              ),
          ]),
        ),
      ]),
    );
  }
}

/// Small count chip ("8 avatars unlocked").
class CwChip extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Widget? leading;
  final double s;
  final bool dark;
  const CwChip({super.key, required this.text, this.icon, this.leading, required this.s, this.dark = false});
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 5 * s),
        decoration: BoxDecoration(
          color: dark ? const Color(0xCC2A1366) : cwCream.withOpacity(0.95),
          borderRadius: BorderRadius.circular(30 * s),
          border: Border.all(color: dark ? const Color(0x66FFFFFF) : Colors.white, width: 1.5 * s),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6 * s, offset: Offset(0, 2 * s))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (leading != null) ...[leading!, SizedBox(width: 6 * s)],
          if (icon != null) ...[Icon(icon, size: 17 * s, color: dark ? cwGold : cwPurple), SizedBox(width: 6 * s)],
          Text(text, style: cwText(14 * s, color: dark ? Colors.white : cwInk, weight: FontWeight.w600)),
        ]),
      );
}

/// Speech bubble sprite with text.
class CwBubble extends StatelessWidget {
  final String text;
  final double width;
  final bool flip;
  const CwBubble({super.key, required this.text, required this.width, this.flip = false});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: width * 0.4818,
        child: Stack(children: [
          Positioned.fill(child: Transform.flip(flipX: flip, child: Image.asset(cw('col_bubble'), fit: BoxFit.fill))),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(width * 0.08, width * 0.04, width * 0.08, width * 0.14),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(text, textAlign: TextAlign.center, maxLines: 2, style: cwText(width * 0.075, color: cwPurpleDeep)),
                ),
              ),
            ),
          ),
        ]),
      );
}

/// Teal "Equipped" chip.
class CwEquipped extends StatelessWidget {
  final double s;
  final String text;
  const CwEquipped({super.key, required this.s, required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 4 * s),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF34D9CF), cwTeal]),
          borderRadius: BorderRadius.circular(30 * s),
          border: Border.all(color: Colors.white, width: 2 * s),
          boxShadow: [BoxShadow(color: cwTeal.withOpacity(0.45), blurRadius: 10 * s)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 17 * s),
          SizedBox(width: 5 * s),
          Text(text, style: cwText(15 * s, color: Colors.white)),
        ]),
      );
}

/// Name plaque (cream pill with a golden rim).
class CwPlaque extends StatelessWidget {
  final double s;
  final String text;
  final double width;
  final double fontSize;
  const CwPlaque({super.key, required this.s, required this.text, required this.width, this.fontSize = 18});
  @override
  Widget build(BuildContext context) => Container(
        width: width,
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 5 * s),
        decoration: BoxDecoration(
          color: cwCream,
          borderRadius: BorderRadius.circular(30 * s),
          border: Border.all(color: const Color(0xFFE8C77A), width: 2 * s),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6 * s, offset: Offset(0, 3 * s))],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text, maxLines: 1, style: cwText(fontSize * s)),
        ),
      );
}

/// Big sprite button with live text. Disabled = faded and not tappable.
class CwButton extends StatelessWidget {
  final String asset;
  final String label;
  final VoidCallback? onTap;
  final double width, aspect; // aspect = height / width of the sprite
  final double s;
  final Color textColor;
  final Widget? leading;
  final Animation<double>? pulse;
  const CwButton({
    super.key,
    required this.asset,
    required this.label,
    required this.onTap,
    required this.width,
    required this.aspect,
    required this.s,
    this.textColor = Colors.white,
    this.leading,
    this.pulse,
  });
  @override
  Widget build(BuildContext context) {
    final h = max(50 * s, width * aspect);
    Widget b = CwPress(
      onTap: onTap,
      label: label,
      child: SizedBox(
        width: width,
        height: h,
        child: Stack(alignment: Alignment.center, children: [
          Positioned.fill(child: Image.asset(asset, fit: BoxFit.fill)),
          Padding(
            padding: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 4 * s),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (leading != null) ...[leading!, SizedBox(width: 8 * s)],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label,
                      maxLines: 1,
                      style: cwText(21 * s, color: textColor).copyWith(
                        shadows: textColor == Colors.white
                            ? [Shadow(color: Colors.black.withOpacity(0.25), offset: const Offset(0, 1.5), blurRadius: 1)]
                            : null,
                      )),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
    if (onTap == null) return Opacity(opacity: 0.55, child: b);
    if (pulse != null) {
      b = AnimatedBuilder(
        animation: pulse!,
        builder: (_, c) => Transform.scale(scale: 1 + 0.025 * sin(pulse!.value * 2 * pi * 3), child: c),
        child: b,
      );
    }
    return b;
  }
}

/// "Back to my world" link.
class CwBackLink extends StatelessWidget {
  final double s;
  final bool dark;
  const CwBackLink({super.key, required this.s, this.dark = false});
  @override
  Widget build(BuildContext context) => CwPress(
        onTap: () {
          cwSound(context, 'cancelButton');
          Navigator.of(context).maybePop();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6 * s, horizontal: 10 * s),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Transform.flip(
              flipX: cwRtl(context),
              child: Icon(Icons.chevron_left_rounded, color: dark ? cwPurpleDeep : cwPurple, size: 24 * s),
            ),
            SizedBox(width: 4 * s),
            Text(cwT(context, 'backWorld'), style: cwText(15.5 * s, color: dark ? cwPurpleDeep : cwPurple, weight: FontWeight.w600)),
          ]),
        ),
      );
}

/// Segmented tabs (purple or teal).
class CwTabs extends StatelessWidget {
  final double s;
  final List<String> labels;
  final List<IconData>? icons;
  final int index;
  final ValueChanged<int> onTap;
  final Color color;
  const CwTabs({super.key, required this.s, required this.labels, this.icons, required this.index, required this.onTap, this.color = cwPurple});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
        final w = c.maxWidth / labels.length;
        final h = 42 * s;
        return Container(
          height: h,
          decoration: BoxDecoration(
            color: const Color(0xFFF3ECDD),
            borderRadius: BorderRadius.circular(h / 2),
            border: Border.all(color: Colors.white, width: 2 * s),
          ),
          child: Stack(children: [
            AnimatedPositionedDirectional(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              start: w * index,
              top: 0,
              bottom: 0,
              width: w - 4 * s,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(h / 2),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8 * s, offset: Offset(0, 3 * s))],
                ),
              ),
            ),
            Row(children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      cwSound(context, 'toggleButton');
                      onTap(i);
                    },
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (icons != null) ...[
                            Icon(icons![i], size: 17 * s, color: i == index ? Colors.white : cwInkSoft),
                            SizedBox(width: 5 * s),
                          ],
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: cwText(15 * s, color: i == index ? Colors.white : cwInk, weight: FontWeight.w600),
                            child: Text(labels[i]),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
            ]),
          ]),
        );
      });
}

/// Layout shared by the five islands: header, magical hero, cream panel.
class CwIslandLayout extends StatelessWidget {
  final double s;
  final Widget header;
  final double heroHeight;
  final Widget hero;
  final Widget panel;
  final bool night;
  const CwIslandLayout({
    super.key,
    required this.s,
    required this.header,
    required this.heroHeight,
    required this.hero,
    required this.panel,
    this.night = false,
  });
  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: night ? const Color(0xFF1B1250) : const Color(0xFFBFE6FF),
      body: Stack(children: [
        Positioned.fill(child: CwWorldBg(night: night)),
        Column(children: [
          SizedBox(height: pad.top + 4 * s),
          header,
          SizedBox(height: heroHeight, child: hero),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 10 * s),
              padding: EdgeInsets.fromLTRB(12 * s, 12 * s, 12 * s, pad.bottom + 6 * s),
              decoration: BoxDecoration(
                color: cwCream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30 * s)),
                border: Border.all(color: night ? const Color(0xFFE8C77A) : Colors.white, width: 3 * s),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 18 * s, offset: Offset(0, -4 * s))],
              ),
              child: panel,
            ),
          ),
        ]),
      ]),
    );
  }
}

/// Panel title with little leaf flourishes.
class CwPanelTitle extends StatelessWidget {
  final double s;
  final String text;
  final Color color;
  const CwPanelTitle({super.key, required this.s, required this.text, this.color = cwInk});
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.auto_awesome, size: 16 * s, color: cwGold),
        SizedBox(width: 8 * s),
        Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, style: cwText(22 * s, color: color)))),
        SizedBox(width: 8 * s),
        Icon(Icons.auto_awesome, size: 16 * s, color: cwGold),
      ]);
}

/// Grey-out filter for locked things.
const ColorFilter cwGrey = ColorFilter.matrix([
  0.33, 0.45, 0.12, 0, 18, //
  0.33, 0.45, 0.12, 0, 18,
  0.33, 0.45, 0.12, 0, 22,
  0, 0, 0, 1, 0,
]);

/// Dark silhouette for undiscovered treasures.
const ColorFilter cwSilhouette = ColorFilter.matrix([
  0, 0, 0, 0, 52, //
  0, 0, 0, 0, 40,
  0, 0, 0, 0, 92,
  0, 0, 0, 0.92, 0,
]);

/// Scale for a page: phones ≈ 1.0, small phones smaller, tablets a bit bigger.
double cwScale(BuildContext context) {
  final w = min(MediaQuery.sizeOf(context).width, 560.0);
  return (w / 390).clamp(0.8, 1.35).toDouble();
}

const Map<String, Map<String, String>> _cwStrings = {
  'en': {
    'worldTitle': 'My wonderful world',
    'worldSub': 'Explore your collections',
    'worldOf': '{name}’s world',
    'worldOfNoName': 'My world',
    'ask': 'Which island do you want to visit?',
    'avatars': 'Avatars',
    'banners': 'Banners',
    'frames': 'Frames',
    'treasures': 'Treasures',
    'badges': 'Badges',
    'backWorld': 'Back to my world',
    'equipped': 'Equipped',
    'avTitle': 'Avatar island',
    'avCount': '{n} avatars unlocked',
    'avAsk': 'Choose your buddy!',
    'all': 'All',
    'kids': 'Kids',
    'friends': 'Buddies',
    'avChoose': 'Choose this avatar',
    'avAlready': 'This avatar is already equipped.',
    'avHint': 'Tap an avatar to try it on!',
    'bnTitle': 'Banner island',
    'bnCount': '{n} banners unlocked',
    'bnPick': 'Choose your scenery',
    'bnChoose': 'Choose this banner',
    'bnAlready': 'This banner is already equipped.',
    'bnHint': 'Tap a banner to see it on the easel!',
    'inShop': 'Find it in the shop',
    'goShop': 'Go to the shop',
    'frTitle': 'Frame workshop',
    'frCount': '{n} frames unlocked',
    'frPick': 'A frame for your adventure',
    'frChoose': 'Choose this frame',
    'frAlready': 'This frame is already equipped.',
    'frLevel': 'Unlocks at level {n}',
    'frGems': '{n} gems in the shop',
    'noFrame': 'No frame',
    'trTitle': 'Treasure cave',
    'trCount': '{n} treasures found',
    'trCabinet': 'My cabinet of wonders',
    'story': 'See its story',
    'hidden': 'Hidden treasure',
    'toFind': 'To find it: {how}',
    'bdTitle': 'Badge garden',
    'bdCount': '{n} / {t}',
    'bdUnlocked': 'unlocked',
    'tabAll': 'All',
    'tabEarned': 'Earned',
    'tabLocked': 'To discover',
    'got': 'Earned',
    'nextBadge': 'Next badge: {name}',
    'left': '{n} more to go',
    'allBadges': 'You earned every badge! 🌟',
    'nothing': 'Nothing here yet',
    'close': 'Close',
  },
  'fr': {
    'worldTitle': 'Mon monde merveilleux',
    'worldSub': 'Explore tes collections',
    'worldOf': 'Le monde de {name}',
    'worldOfNoName': 'Mon monde',
    'ask': 'Quelle île veux-tu visiter ?',
    'avatars': 'Avatars',
    'banners': 'Bannières',
    'frames': 'Cadres',
    'treasures': 'Trésors',
    'badges': 'Badges',
    'backWorld': 'Retour à mon monde',
    'equipped': 'Équipé',
    'avTitle': 'L’île des avatars',
    'avCount': '{n} avatars débloqués',
    'avAsk': 'Choisis ton compagnon !',
    'all': 'Tous',
    'kids': 'Personnages',
    'friends': 'Compagnons',
    'avChoose': 'Choisir cet avatar',
    'avAlready': 'Cet avatar est déjà équipé.',
    'avHint': 'Touche un avatar pour l’essayer !',
    'bnTitle': 'L’île des bannières',
    'bnCount': '{n} bannières débloquées',
    'bnPick': 'Choisis ton décor',
    'bnChoose': 'Choisir cette bannière',
    'bnAlready': 'Cette bannière est déjà équipée.',
    'bnHint': 'Touche une bannière pour la voir sur le chevalet !',
    'inShop': 'À trouver dans la boutique',
    'goShop': 'Aller à la boutique',
    'frTitle': 'L’atelier des cadres',
    'frCount': '{n} cadres débloqués',
    'frPick': 'Un cadre pour ton aventure',
    'frChoose': 'Choisir ce cadre',
    'frAlready': 'Ce cadre est déjà équipé.',
    'frLevel': 'Débloqué au niveau {n}',
    'frGems': '{n} gemmes dans la boutique',
    'noFrame': 'Sans cadre',
    'trTitle': 'La grotte des trésors',
    'trCount': '{n} trésors découverts',
    'trCabinet': 'Mon cabinet des merveilles',
    'story': 'Voir son histoire',
    'hidden': 'Trésor caché',
    'toFind': 'Pour le trouver : {how}',
    'bdTitle': 'Le jardin des badges',
    'bdCount': '{n} / {t}',
    'bdUnlocked': 'débloqués',
    'tabAll': 'Tous',
    'tabEarned': 'Obtenus',
    'tabLocked': 'À découvrir',
    'got': 'Obtenu',
    'nextBadge': 'Prochain badge : {name}',
    'left': 'Encore {n}',
    'allBadges': 'Tu as tous les badges ! 🌟',
    'nothing': 'Rien ici pour l’instant',
    'close': 'Fermer',
  },
  'ar': {
    'worldTitle': 'عالمي العجيب',
    'worldSub': 'استكشف مجموعاتك',
    'worldOf': 'عالم {name}',
    'worldOfNoName': 'عالمي',
    'ask': 'أي جزيرة تريد أن تزور؟',
    'avatars': 'الشخصيات',
    'banners': 'الخلفيات',
    'frames': 'الإطارات',
    'treasures': 'الكنوز',
    'badges': 'الأوسمة',
    'backWorld': 'العودة إلى عالمي',
    'equipped': 'مُفعّل',
    'avTitle': 'جزيرة الشخصيات',
    'avCount': '{n} شخصيات مفتوحة',
    'avAsk': 'اختر رفيقك!',
    'all': 'الكل',
    'kids': 'الأطفال',
    'friends': 'الرفاق',
    'avChoose': 'اختر هذه الشخصية',
    'avAlready': 'هذه الشخصية مفعّلة.',
    'avHint': 'اضغط على شخصية لتجربتها!',
    'bnTitle': 'جزيرة الخلفيات',
    'bnCount': '{n} خلفيات مفتوحة',
    'bnPick': 'اختر منظرك',
    'bnChoose': 'اختر هذه الخلفية',
    'bnAlready': 'هذه الخلفية مفعّلة.',
    'bnHint': 'اضغط على خلفية لتراها على اللوحة!',
    'inShop': 'تجدها في المتجر',
    'goShop': 'اذهب إلى المتجر',
    'frTitle': 'ورشة الإطارات',
    'frCount': '{n} إطارات مفتوحة',
    'frPick': 'إطار لمغامرتك',
    'frChoose': 'اختر هذا الإطار',
    'frAlready': 'هذا الإطار مفعّل.',
    'frLevel': 'يُفتح في المستوى {n}',
    'frGems': '{n} جواهر في المتجر',
    'noFrame': 'بدون إطار',
    'trTitle': 'مغارة الكنوز',
    'trCount': '{n} كنوز مكتشفة',
    'trCabinet': 'خزانة عجائبي',
    'story': 'شاهد قصته',
    'hidden': 'كنز مخفي',
    'toFind': 'لتجده: {how}',
    'bdTitle': 'حديقة الأوسمة',
    'bdCount': '{n} / {t}',
    'bdUnlocked': 'مفتوحة',
    'tabAll': 'الكل',
    'tabEarned': 'المكتسبة',
    'tabLocked': 'لاكتشافها',
    'got': 'مكتسب',
    'nextBadge': 'الوسام التالي: {name}',
    'left': 'بقي {n}',
    'allBadges': 'ربحت كل الأوسمة! 🌟',
    'nothing': 'لا شيء هنا بعد',
    'close': 'إغلاق',
  },
  'de': {
    'worldTitle': 'Meine Wunderwelt',
    'worldSub': 'Entdecke deine Sammlungen',
    'worldOf': '{name}s Welt',
    'worldOfNoName': 'Meine Welt',
    'ask': 'Welche Insel willst du besuchen?',
    'avatars': 'Avatare',
    'banners': 'Banner',
    'frames': 'Rahmen',
    'treasures': 'Schätze',
    'badges': 'Abzeichen',
    'backWorld': 'Zurück zu meiner Welt',
    'equipped': 'Ausgewählt',
    'avTitle': 'Avatar-Insel',
    'avCount': '{n} Avatare freigeschaltet',
    'avAsk': 'Wähle deinen Begleiter!',
    'all': 'Alle',
    'kids': 'Kinder',
    'friends': 'Begleiter',
    'avChoose': 'Diesen Avatar wählen',
    'avAlready': 'Dieser Avatar ist schon ausgewählt.',
    'avHint': 'Tippe auf einen Avatar zum Anprobieren!',
    'bnTitle': 'Banner-Insel',
    'bnCount': '{n} Banner freigeschaltet',
    'bnPick': 'Wähle deine Kulisse',
    'bnChoose': 'Dieses Banner wählen',
    'bnAlready': 'Dieses Banner ist schon ausgewählt.',
    'bnHint': 'Tippe auf ein Banner, um es auf der Staffelei zu sehen!',
    'inShop': 'Im Shop zu finden',
    'goShop': 'Zum Shop',
    'frTitle': 'Rahmen-Werkstatt',
    'frCount': '{n} Rahmen freigeschaltet',
    'frPick': 'Ein Rahmen für dein Abenteuer',
    'frChoose': 'Diesen Rahmen wählen',
    'frAlready': 'Dieser Rahmen ist schon ausgewählt.',
    'frLevel': 'Ab Level {n}',
    'frGems': '{n} Edelsteine im Shop',
    'noFrame': 'Kein Rahmen',
    'trTitle': 'Schatzhöhle',
    'trCount': '{n} Schätze gefunden',
    'trCabinet': 'Mein Wunderschrank',
    'story': 'Seine Geschichte',
    'hidden': 'Versteckter Schatz',
    'toFind': 'So findest du ihn: {how}',
    'bdTitle': 'Abzeichen-Garten',
    'bdCount': '{n} / {t}',
    'bdUnlocked': 'offen',
    'tabAll': 'Alle',
    'tabEarned': 'Verdient',
    'tabLocked': 'Zu entdecken',
    'got': 'Verdient',
    'nextBadge': 'Nächstes Abzeichen: {name}',
    'left': 'Noch {n}',
    'allBadges': 'Du hast alle Abzeichen! 🌟',
    'nothing': 'Hier ist noch nichts',
    'close': 'Schließen',
  },
};

/// Happy sound when something is equipped.
void cwCelebrate(BuildContext context) {
  try {
    Provider.of<AudioManager>(context, listen: false).playSfx('assets/audios/UI_Audio/SFX_Audio/MarimbaWin_SFX.mp3');
  } catch (_) {}
}

/// Burst of colourful stars, played by [anim] (0 → 1).
class CwBurst extends StatelessWidget {
  final Animation<double> anim;
  const CwBurst({super.key, required this.anim});
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: anim,
          builder: (_, __) => anim.value <= 0 || anim.value >= 1
              ? const SizedBox.expand()
              : CustomPaint(painter: _BurstPainter(anim.value)),
        ),
      );
}

class _BurstPainter extends CustomPainter {
  final double t;
  _BurstPainter(this.t);
  static const _c = [Color(0xFFFFC21A), Color(0xFFFF6FB5), Color(0xFF34D9CF), Color(0xFF8B5CFF), Color(0xFF7DDB5A)];
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = Random(7);
    final e = Curves.easeOutCubic.transform(t);
    for (var i = 0; i < 26; i++) {
      final a = i / 26 * 2 * pi + r.nextDouble() * 0.3;
      final dist = (0.25 + r.nextDouble() * 0.35) * size.shortestSide * e;
      final p = c + Offset(cos(a), sin(a)) * dist + Offset(0, 40 * t * t);
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
  bool shouldRepaint(_BurstPainter o) => o.t != t;
}
