import 'dart:math';

import 'package:flutter/material.dart';

import '../../../widgets/KidScene/kid_scene.dart';
import 'magic_paint_data.dart';

const Color mpPurple = Color(0xFF5B21C9);
const Color mpInk = Color(0xFF3A1580);
const Color mpCream = Color(0xFFFFF8EA);
const Color mpCreamEdge = Color(0xFFF1DDB6);
const Color mpCyan = Color(0xFF22D3EE);

TextStyle mpTitle(double size, {Color color = mpInk}) =>
    TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: size, height: 1.1, color: color);

BoxDecoration mpCard(double s, {double radius = 24, Color fill = mpCream, Color border = Colors.white, Color? glow}) => BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(radius * s),
      border: Border.all(color: border, width: 2.5 * s),
      boxShadow: [
        BoxShadow(color: (glow ?? const Color(0xFF6A3A12)).withOpacity(glow == null ? 0.2 : 0.55), blurRadius: (glow == null ? 10 : 14) * s, offset: Offset(0, (glow == null ? 4 : 0) * s)),
      ],
    );

/// Round cream icon button (undo / redo / small actions).
class MpRoundButton extends StatelessWidget {
  final double size;
  final Widget child;
  final VoidCallback? onTap;
  const MpRoundButton({super.key, required this.size, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: KidPressable(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: mpCream,
            border: Border.all(color: Colors.white, width: size * 0.05),
            boxShadow: [BoxShadow(color: const Color(0xFF6A3A12).withOpacity(0.25), blurRadius: size * 0.16, offset: Offset(0, size * 0.06))],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Top bar: back · "Peinture magique" · gear.
class MpTopBar extends StatelessWidget {
  final double scale;
  final String title;
  final VoidCallback onBack, onGear;
  const MpTopBar({super.key, required this.scale, required this.title, required this.onBack, required this.onGear});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      height: 64 * s,
      child: Row(children: [
        KidPressable(onTap: onBack, child: Transform.flip(flipX: rtl, child: Image.asset(mpImgBack, width: 52 * s, height: 52 * s))),
        SizedBox(width: 8 * s),
        Expanded(
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              height: 54 * s,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 14 * s),
              decoration: mpCard(s, radius: 30),
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(title, style: mpTitle(30 * s, color: mpPurple))),
            ),
            PositionedDirectional(end: 26 * s, top: -7 * s, child: Image.asset(mpImgStar, width: 18 * s)),
          ]),
        ),
        SizedBox(width: 8 * s),
        KidPressable(onTap: onGear, child: Image.asset(mpImgGear, width: 52 * s, height: 52 * s)),
      ]),
    );
  }
}

/// Colorier | Dessiner | Mes créations.
class MpTabs extends StatelessWidget {
  final double scale;
  final int index;
  final ValueChanged<int> onTap;
  const MpTabs({super.key, required this.scale, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final items = [
      (Icons.palette_rounded, mpText(context, 'color')),
      (Icons.edit_rounded, mpText(context, 'draw')),
      (Icons.image_rounded, mpText(context, 'mine')),
    ];
    return Container(
      height: 50 * s,
      padding: EdgeInsets.all(4 * s),
      decoration: mpCard(s, radius: 28),
      child: Row(children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) Container(width: 1.5 * s, height: 26 * s, color: mpCreamEdge),
          Expanded(
            flex: i == 2 ? 13 : 10,
            child: KidPressable(
              onTap: () => onTap(i),
              pressedScale: 0.95,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22 * s),
                  gradient: i == index ? const LinearGradient(colors: [Color(0xFFFFE066), Color(0xFFFFC21A)], begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
                  boxShadow: i == index ? [BoxShadow(color: const Color(0xFFFFB000).withOpacity(0.45), blurRadius: 8 * s)] : null,
                ),
                padding: EdgeInsets.symmetric(horizontal: 6 * s),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(items[i].$1, color: mpPurple, size: 22 * s),
                    SizedBox(width: 5 * s),
                    Text(items[i].$2, style: mpTitle(16 * s)),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

/// Small hint pill with an icon.
class MpHint extends StatelessWidget {
  final double scale;
  final IconData icon;
  final String text;
  const MpHint({super.key, required this.scale, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      height: 34 * s,
      padding: EdgeInsets.symmetric(horizontal: 14 * s),
      decoration: mpCard(s, radius: 20),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: mpPurple, size: 20 * s),
        SizedBox(width: 6 * s),
        Flexible(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: FittedBox(key: ValueKey(text), fit: BoxFit.scaleDown, child: Text(text, style: mpTitle(14.5 * s))),
          ),
        ),
      ]),
    );
  }
}

/// Leafy banner ("Laisse parler ton imagination !", "Mon petit musée").
class MpBanner extends StatelessWidget {
  final double scale;
  final String title;
  final String? subtitle;
  final double height;
  const MpBanner({super.key, required this.scale, required this.title, this.subtitle, this.height = 54});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return SizedBox(
      height: height * s,
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(child: Image.asset(mpImgBanner, fit: BoxFit.fill)),
        Padding(
          padding: EdgeInsets.fromLTRB(70 * s, 4 * s, 70 * s, 6 * s),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(title, style: mpTitle((subtitle == null ? 19 : 28) * s, color: subtitle == null ? mpInk : mpPurple)))),
            if (subtitle != null) FittedBox(fit: BoxFit.scaleDown, child: Text(subtitle!, style: mpTitle(13 * s))),
          ]),
        ),
      ]),
    );
  }
}

/// Square tool button; selected = cyan glow.
class MpToolButton extends StatelessWidget {
  final double size;
  final String image;
  final bool selected;
  final bool round;
  final VoidCallback onTap;
  const MpToolButton({super.key, required this.size, required this.image, required this.selected, required this.onTap, this.round = false});

  @override
  Widget build(BuildContext context) {
    return KidPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        padding: EdgeInsets.all(size * (round ? 0.04 : 0.12)),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDDF9FF) : mpCream,
          borderRadius: BorderRadius.circular(size * (round ? 0.5 : 0.24)),
          border: Border.all(color: selected ? mpCyan : Colors.white, width: size * 0.045),
          boxShadow: [
            if (selected) BoxShadow(color: mpCyan.withOpacity(0.6), blurRadius: size * 0.2),
            BoxShadow(color: const Color(0xFF6A3A12).withOpacity(0.15), blurRadius: size * 0.08, offset: Offset(0, size * 0.04)),
          ],
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: selected ? 1.08 : 1,
          child: Image.asset(image, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Scrollable row of colour dots; the selected one shows a check.
class MpColorRow extends StatelessWidget {
  final double scale;
  final Color selected;
  final ValueChanged<Color> onPick;
  const MpColorRow({super.key, required this.scale, required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final d = 40 * s;
    return SizedBox(
      height: d + 12 * s,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 6 * s),
        itemCount: mpColors.length,
        separatorBuilder: (_, __) => SizedBox(width: 7 * s),
        itemBuilder: (_, i) {
          final c = mpColors[i];
          final on = c.value == selected.value;
          final light = c.computeLuminance() > 0.6;
          return KidPressable(
            onTap: () => onPick(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: d,
              height: d,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.45),
                  colors: [Color.lerp(c, Colors.white, 0.4)!, c, Color.lerp(c, Colors.black, 0.15)!],
                  stops: const [0, 0.6, 1],
                ),
                border: Border.all(color: on ? Colors.white : (light ? mpCreamEdge : Colors.white.withOpacity(0.6)), width: on ? 3 * s : 1.5 * s),
                boxShadow: [
                  if (on) BoxShadow(color: c == Colors.white ? mpCyan : c.withOpacity(0.8), blurRadius: 10 * s, spreadRadius: 1 * s),
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 3 * s, offset: Offset(0, 2 * s)),
                ],
              ),
              child: on ? Icon(Icons.check_rounded, color: light ? mpPurple : Colors.white, size: d * 0.55) : null,
            ),
          );
        },
      ),
    );
  }
}

/// Glossy orange pill with icon (Terminer / Enregistrer / Créer un dessin).
class MpOrangeButton extends StatelessWidget {
  final double scale;
  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final double height;
  const MpOrangeButton({super.key, required this.scale, required this.label, required this.icon, required this.onTap, this.height = 58});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final h = height * s;
    return KidPressable(
      onTap: onTap,
      child: Container(
        height: h,
        padding: EdgeInsets.symmetric(horizontal: 18 * s),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(h),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFB63D), Color(0xFFFF7A10)]),
          border: Border.all(color: const Color(0xFFFFD08A), width: 2.5 * s),
          boxShadow: [
            BoxShadow(color: const Color(0xFFD9570A), offset: Offset(0, 4 * s)),
            BoxShadow(color: const Color(0xFFFF7110).withOpacity(0.4), blurRadius: 14 * s, offset: Offset(0, 6 * s)),
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(height: h * 0.55, child: FittedBox(fit: BoxFit.contain, child: icon)),
          SizedBox(width: 10 * s),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  style: mpTitle(h * 0.42, color: Colors.white).copyWith(shadows: [
                    Shadow(color: const Color(0xFFB24A00).withOpacity(0.8), offset: Offset(0, 2 * s), blurRadius: 2 * s),
                  ])),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Cream pill with icon (Galerie / Nouveau).
class MpCreamButton extends StatelessWidget {
  final double scale;
  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final double height;
  const MpCreamButton({super.key, required this.scale, required this.label, required this.icon, required this.onTap, this.height = 58});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final h = height * s;
    return KidPressable(
      onTap: onTap,
      child: Container(
        height: h,
        padding: EdgeInsets.symmetric(horizontal: 14 * s),
        decoration: mpCard(s, radius: 26),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(height: h * 0.5, child: FittedBox(fit: BoxFit.contain, child: icon)),
          SizedBox(width: 8 * s),
          Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: mpTitle(h * 0.34)))),
        ]),
      ),
    );
  }
}

/// Robot with a speech bubble.
class MpRobotTalk extends StatelessWidget {
  final double scale;
  final String image;
  final String text;
  final Animation<double> idle;
  final double height;
  final bool bubbleLeft;
  const MpRobotTalk({super.key, required this.scale, required this.image, required this.text, required this.idle, this.height = 120, this.bubbleLeft = true});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return SizedBox(
      width: height * 0.95 * s,
      height: height * s,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          top: height * 0.22 * s,
          child: AnimatedBuilder(
            animation: idle,
            builder: (_, c) => Transform.translate(
              offset: Offset(0, sin(idle.value * 2 * pi) * 3 * s),
              child: Transform.rotate(angle: sin(idle.value * 4 * pi) * 0.03, alignment: Alignment.bottomCenter, child: c),
            ),
            child: Image.asset(image, fit: BoxFit.contain, alignment: Alignment.bottomCenter),
          ),
        ),
        Positioned(
          top: -6 * s,
          left: bubbleLeft ? -40 * s : null,
          right: bubbleLeft ? null : -30 * s,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
            child: SizedBox(
              key: ValueKey(text),
              width: 96 * s,
              height: 62 * s,
              child: Stack(alignment: Alignment.center, children: [
                Positioned.fill(child: Transform.flip(flipX: !bubbleLeft, child: Image.asset(mpImgBubble, fit: BoxFit.fill))),
                Padding(
                  padding: EdgeInsets.fromLTRB(8 * s, 4 * s, 8 * s, 14 * s),
                  child: FittedBox(fit: BoxFit.scaleDown, child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 90 * s), child: Text(text, textAlign: TextAlign.center, style: mpTitle(14 * s)))),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Places a widget inside the paper area of an easel image.
class MpEasel extends StatelessWidget {
  final String image;
  final double aspect; // image h / w
  final Rect paper; // paper rect as fractions of the image
  final Widget child;
  final List<Widget> overlays; // positioned relative to the easel box
  const MpEasel({super.key, required this.image, required this.aspect, required this.paper, required this.child, this.overlays = const []});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      var w = c.maxWidth;
      var h = w * aspect;
      if (h > c.maxHeight) {
        h = c.maxHeight;
        w = h / aspect;
      }
      return Center(
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(child: Image.asset(image, fit: BoxFit.fill)),
            Positioned(left: paper.left * w, top: paper.top * h, width: paper.width * w, height: paper.height * h, child: child),
            ...overlays,
          ]),
        ),
      );
    });
  }
}

const Rect mpTallPaper = Rect.fromLTWH(0.058, 0.143, 0.873, 0.693);
const double mpTallAspect = 758 / 505;
const Rect mpWidePaper = Rect.fromLTWH(0.056, 0.128, 0.888, 0.694);
const double mpWideAspect = 638 / 700;

/// Settings dialog.
Future<void> mpOpenSettings(BuildContext context, {required bool showModel, required ValueChanged<bool> onShowModel, required bool sounds, required ValueChanged<bool> onSounds}) async {
  var m = showModel, so = sounds;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => KidDialog(
        title: mpText(context, 'settings'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          SwitchListTile(
            value: m,
            activeColor: mpPurple,
            contentPadding: EdgeInsets.zero,
            title: Text(mpText(context, 'showModel'), style: kidBodyStyle(16, color: mpInk, weight: FontWeight.w600)),
            onChanged: (v) {
              setD(() => m = v);
              onShowModel(v);
            },
          ),
          SwitchListTile(
            value: so,
            activeColor: mpPurple,
            contentPadding: EdgeInsets.zero,
            title: Text(mpText(context, 'sounds'), style: kidBodyStyle(16, color: mpInk, weight: FontWeight.w600)),
            onChanged: (v) {
              setD(() => so = v);
              onSounds(v);
            },
          ),
        ]),
        actions: [
          KidButton(label: mpText(context, 'ok'), onPressed: () => Navigator.of(ctx).pop(), width: 180, height: 52, showArrow: false),
        ],
      ),
    ),
  );
}

/// Picture picker: the coloring pages (+ a blank page when [withBlank]).
Future<String?> mpPickPage(BuildContext context, {bool withBlank = false}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, ctrl) => Container(
        decoration: const BoxDecoration(
          color: mpCream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFFFFC21A), width: 3)),
        ),
        child: Column(children: [
          const SizedBox(height: 10),
          Container(width: 48, height: 5, decoration: BoxDecoration(color: mpCreamEdge, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 10),
          Text(mpText(context, 'choosePicture'), style: mpTitle(22, color: mpPurple)),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.count(
              controller: ctrl,
              crossAxisCount: 3,
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.78,
              children: [
                if (withBlank)
                  _PickTile(
                    label: mpText(context, 'blankPage'),
                    onTap: () => Navigator.of(ctx).pop('__blank__'),
                    child: Center(child: Image.asset(mpImgBrushPlus, width: 52, color: mpPurple)),
                  ),
                for (final p in mpPages)
                  _PickTile(
                    label: p.title(context),
                    onTap: () => Navigator.of(ctx).pop(p.id),
                    child: Image.asset(p.lines, fit: BoxFit.contain),
                  ),
              ],
            ),
          ),
        ]),
      ),
    ),
  );
}

class _PickTile extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback onTap;
  const _PickTile({required this.label, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.95,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: mpCard(1, radius: 18, border: const Color(0xFFB79BEA)),
        child: Column(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(color: Colors.white, child: SizedBox.expand(child: child)),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: mpTitle(14))),
        ]),
      ),
    );
  }
}
