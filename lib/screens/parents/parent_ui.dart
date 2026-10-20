import 'package:flutter/material.dart';
import 'package:mortaalim/Manager/models/avatar_catalog.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

import 'parent_strings.dart';

/// Parents Space palette (calm, adult-friendly version of the kid style).
class PC {
  static const ink = Color(0xFF241356);
  static const sub = Color(0xFF6B6385);
  static const teal = Color(0xFF14A3A8);
  static const tealDeep = Color(0xFF0E7F86);
  static const tealSoft = Color(0xFFDDF5F3);
  static const cream = Color(0xFFFFFBF3);
  static const card = Color(0xFFFFFCF6);
  static const line = Color(0xFFEDE6D8);
  static const lav = Color(0xFFEDE9FB);
  static const orange = Color(0xFFFF8A1E);
  static const green = Color(0xFF22B573);
}

const String parentDir = 'assets/images/UI/Parents/';
String pa(String n) => '$parentDir$n.webp';

TextStyle ps(double size, {Color color = PC.ink, FontWeight w = FontWeight.w600, double h = 1.2}) =>
    TextStyle(fontFamily: 'Fredoka', fontSize: size, color: color, fontWeight: w, height: h);

/// Floating-islands background, softened.
class ParentBackground extends StatelessWidget {
  final Widget child;
  final bool dim;
  const ParentBackground({super.key, required this.child, this.dim = false});

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(child: Image.asset('assets/images/UI/Loading/loading_bg_adventure.webp', fit: BoxFit.cover)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white.withOpacity(dim ? 0.35 : 0.12), Colors.white.withOpacity(dim ? 0.75 : 0.55)],
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ]);
}

class PCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  const PCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color = PC.card, this.radius = 26});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [BoxShadow(color: const Color(0xFF3B2A7A).withOpacity(0.10), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: child,
      );
}

/// Teal pill switch.
class PSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const PSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 56,
          height: 32,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: value ? PC.teal : const Color(0xFFD5D2DC),
            boxShadow: value ? [BoxShadow(color: PC.teal.withOpacity(0.35), blurRadius: 8)] : null,
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            alignment: value ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 3, offset: const Offset(0, 1))],
              ),
            ),
          ),
        ),
      );
}

/// Round soft icon badge.
class PIcon extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  final double size;
  const PIcon(this.icon, {super.key, this.color = PC.teal, this.bg = PC.tealSoft, this.size = 46});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.32)),
        child: Icon(icon, color: color, size: size * 0.56),
      );
}

/// Orange full-width action button.
class PButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final List<Color> colors;
  const PButton(this.label, {super.key, this.icon, this.onTap, this.colors = const [Color(0xFFFFA43D), Color(0xFFFF7A12)]});

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.96,
      child: Opacity(
        opacity: on ? 1 : 0.55,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
            boxShadow: [BoxShadow(color: colors.last.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, color: Colors.white, size: 24), const SizedBox(width: 10)],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: ps(20, color: Colors.white, w: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Cream outlined button.
class PGhostButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const PGhostButton(this.label, {super.key, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => KidPressable(
        onTap: onTap,
        pressedScale: 0.96,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: PC.cream,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: PC.line, width: 2),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, color: PC.ink, size: 22), const SizedBox(width: 8)],
            Text(label, style: ps(17, w: FontWeight.w700)),
          ]),
        ),
      );
}

/// Child chip with avatar + name (only one child profile for now).
class ChildChip extends StatelessWidget {
  final bool showAge;
  const ChildChip({super.key, this.showAge = false});

  @override
  Widget build(BuildContext context) {
    final xp = Provider.of<ExperienceManager>(context);
    final name = childName(context);
    final age = xp.userProfile.age;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 16, 6),
      decoration: BoxDecoration(
        color: PC.cream,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: const Color(0xFF3B2A7A).withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
          radius: showAge ? 26 : 20,
          backgroundColor: PC.tealSoft,
          backgroundImage: AssetImage(AvatarCatalog.resolve(xp.selectedAvatar)),
        ),
        const SizedBox(width: 10),
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: ps(showAge ? 22 : 18, w: FontWeight.w700)),
          if (showAge && age > 0) Text(pT(context, 'ageN', {'n': age}), style: ps(14, color: PC.sub)),
        ]),
      ]),
    );
  }
}

String childName(BuildContext context) {
  final xp = Provider.of<ExperienceManager>(context, listen: false);
  final n = xp.userProfile.fullName.trim();
  return (n.isEmpty || n == 'Player') ? pT(context, 'yourChild') : n.split(' ').first;
}

/// Section title row inside a card.
class PTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? sub;
  final Widget? trailing;
  final Color color;
  const PTitle(this.icon, this.title, {super.key, this.sub, this.trailing, this.color = PC.teal});

  @override
  Widget build(BuildContext context) => Row(children: [
        PIcon(icon, color: color, bg: color.withOpacity(0.14), size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: ps(19, w: FontWeight.w700)),
            if (sub != null) Text(sub!, style: ps(13.5, color: PC.sub, w: FontWeight.w500)),
          ]),
        ),
        if (trailing != null) trailing!,
      ]);
}

void pSnack(BuildContext context, String msg, {bool ok = true}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ok ? PC.tealDeep : const Color(0xFFD9214E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Text(msg, style: ps(15, color: Colors.white)),
    ));
}
