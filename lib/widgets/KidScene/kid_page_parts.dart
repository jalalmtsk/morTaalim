import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

/// Shared pieces for the full-screen section pages (Games, Courses, …).

const String kidCoinAsset = 'assets/images/UI/KidScene/home_coin.webp';
const String kidGemAsset = 'assets/images/UI/KidScene/home_gem.webp';
const Color kidCardCream = Color(0xFFFFFAF0);

/// Full-screen scene background (the valley by default) with a light wash.
class KidPageBackground extends StatelessWidget {
  final String asset;
  final double wash;
  final Alignment alignment;
  const KidPageBackground(
      {super.key, this.asset = KidAssets.valleyBg, this.wash = 0.16, this.alignment = Alignment.center});

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(child: Image.asset(asset, fit: BoxFit.cover, alignment: alignment)),
        if (wash > 0) Positioned.fill(child: ColoredBox(color: Colors.white.withOpacity(wash))),
      ]);
}

/// Back button · big title · gold pill · gem pill.
class KidPageHeader extends StatelessWidget {
  final double scale;
  final String title;
  final int gold, gems;
  final bool showBack; // false on the bottom-bar tabs
  const KidPageHeader(
      {super.key, required this.scale, required this.title, required this.gold, required this.gems, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return SizedBox(
      height: 50 * s,
      child: Row(
        children: [
          if (showBack) ...[
            KidBackButton(
              size: 46 * s,
              onTap: () {
                Provider.of<AudioManager>(context, listen: false).playEventSound('cancelButton');
                Navigator.of(context).maybePop();
              },
            ),
            SizedBox(width: 8 * s),
          ] else
            SizedBox(width: 4 * s),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: showBack ? Alignment.center : AlignmentDirectional.centerStart,
              child: Text(title, maxLines: 1, style: kidTitleStyle(34 * s)),
            ),
          ),
          SizedBox(width: 8 * s),
          KidCurrencyPill(scale: s, icon: kidCoinAsset, value: gold, label: tr(context).goldLabel),
          SizedBox(width: 6 * s),
          KidCurrencyPill(scale: s, icon: kidGemAsset, value: gems, label: tr(context).gemsLabel),
        ],
      ),
    );
  }
}

class KidCurrencyPill extends StatelessWidget {
  final double scale;
  final String icon, label;
  final int value;
  const KidCurrencyPill({super.key, required this.scale, required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final h = 36 * s;
    return Semantics(
      label: '$label $value',
      child: Container(
        height: h,
        padding: EdgeInsetsDirectional.only(start: 3 * s, end: 12 * s),
        decoration: BoxDecoration(
          color: KidColors.cream,
          borderRadius: BorderRadius.circular(h),
          boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset(icon, width: h * 0.88, height: h * 0.88),
          SizedBox(width: 4 * s),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Text('$value',
                key: ValueKey(value), style: kidBodyStyle(16 * s, color: KidColors.ink, weight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

/// White-rimmed cream card used for tiles and bottom goal cards.
BoxDecoration kidCardDecoration(double radius, {double shadow = 0.16}) => BoxDecoration(
      color: kidCardCream,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(shadow), blurRadius: 14, offset: const Offset(0, 6))],
    );

/// When an item has no illustrated art yet: its own square icon floating on a
/// soft gradient with twinkling stars.
class KidIconArt extends StatelessWidget {
  final String image;
  final List<Color> colors;
  final Animation<double> idle;
  final double phase, scale;
  const KidIconArt({super.key, required this.image, required this.colors, required this.idle, this.phase = 0, required this.scale});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final p in const [(0.12, 0.2, 13.0), (0.86, 0.18, 10.0), (0.8, 0.8, 12.0), (0.16, 0.82, 9.0)])
            Align(
              alignment: Alignment(p.$1 * 2 - 1, p.$2 * 2 - 1),
              child: AnimatedBuilder(
                animation: idle,
                builder: (_, c) =>
                    Opacity(opacity: 0.55 + 0.45 * sin((idle.value * 6 + p.$1 + phase) * 2 * pi).abs(), child: c),
                child: Icon(Icons.star_rounded, color: Colors.white, size: p.$3 * s),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(10 * s),
            child: AnimatedBuilder(
              animation: idle,
              builder: (_, c) =>
                  Transform.translate(offset: Offset(0, sin((idle.value * 4 + phase) * 2 * pi) * 3 * s), child: c),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18 * s),
                  child: Image.asset(image, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin rounded progress bar (grey track, yellow fill).
class KidProgressBar extends StatelessWidget {
  final double value, height, width;
  const KidProgressBar({super.key, required this.value, required this.height, this.width = double.infinity});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        width: width,
        child: Stack(children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFFDCD6E6))),
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            widthFactor: value.clamp(0.0, 1.0),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFD84A), Color(0xFFFFB21A)]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
