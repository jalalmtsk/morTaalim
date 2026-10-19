import 'dart:math';

import 'package:flutter/material.dart';

/// Glossy 3D progress bar built from the sliced bar sprites
/// (assets/images/UI/Bars/). Round ends never stretch: the sprites are drawn
/// as 9-slice at their native 64px height, then scaled to [height].
class GlossyBar extends StatelessWidget {
  final double value; // 0..1
  final double height;
  final double? width;
  final String color; // one of [colors]
  final Duration duration;

  const GlossyBar({
    super.key,
    required this.value,
    required this.height,
    this.width,
    this.color = 'gold',
    this.duration = const Duration(milliseconds: 650),
  });

  static const String dir = 'assets/images/UI/Bars/';
  static const String track = '${dir}bar_track.webp';
  static String fill(String c) => '${dir}bar_$c.webp';

  /// Representative colour of every bar sprite (used by [forColor]).
  static const Map<String, Color> colors = {
    'gold': Color(0xFFFFC21A),
    'amber': Color(0xFFFFA51F),
    'orange': Color(0xFFFF8A1E),
    'coral': Color(0xFFFF7A6B),
    'red': Color(0xFFF0303A),
    'rose': Color(0xFFFF3D7F),
    'pink': Color(0xFFFF4FB0),
    'magenta': Color(0xFFE23BE0),
    'purple': Color(0xFF9B4DF0),
    'violet': Color(0xFFB06BF5),
    'indigo': Color(0xFF3A3FE0),
    'royal': Color(0xFF2E6BEF),
    'blue': Color(0xFF2F8BF0),
    'sky': Color(0xFF5BB8F5),
    'cyan': Color(0xFF2FD3F0),
    'aqua': Color(0xFF3FE0F0),
    'teal': Color(0xFF1FC8B0),
    'emerald': Color(0xFF22C55E),
    'green': Color(0xFF34C853),
    'lime': Color(0xFF8BE01F),
    'yellow': Color(0xFFF5E21F),
    'peach': Color(0xFFFFB48A),
    'lavender': Color(0xFFB79BF5),
    'mint': Color(0xFF6EE7B0),
  };

  /// Closest glossy bar for an arbitrary colour (keeps old colour choices meaningful).
  static String forColor(Color c) {
    var best = 'gold';
    var bestD = double.infinity;
    colors.forEach((k, v) {
      final d = pow(v.red - c.red, 2) + pow(v.green - c.green, 2) + pow(v.blue - c.blue, 2);
      if (d < bestD) {
        bestD = d.toDouble();
        best = k;
      }
    });
    return best;
  }

  static const double _h = 64; // native sprite height
  static const Rect _trackSlice = Rect.fromLTRB(34, 18, 550, 46); // track is 584 wide
  static const Rect _fillSlice = Rect.fromLTRB(32, 18, 322, 46); // fills are 355–369 wide → caps ≤ 79 px

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth.isFinite ? c.maxWidth : 120.0;
        final k = _h / height;
        final iw = max(w * k, _h * 1.7); // inner width at native scale (≥ track caps)
        return FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: iw,
            height: _h,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value.isNaN ? 0 : value.clamp(0.0, 1.0).toDouble()),
              duration: duration,
              curve: Curves.easeOutCubic,
              builder: (_, v, __) {
                // A 9-slice can't be drawn narrower than its two end caps (≤ 79 px), so keep ≥ 1.6 × height.
                final fw = v <= 0 ? 0.0 : min(iw, max(_h * 1.6, iw * v));
                return Stack(children: [
                  Positioned.fill(
                    child: Image.asset(track, centerSlice: _trackSlice, fit: BoxFit.fill, filterQuality: FilterQuality.medium),
                  ),
                  if (fw > 0)
                    PositionedDirectional(
                      start: 0,
                      top: 0,
                      bottom: 0,
                      width: fw,
                      child: Image.asset(fill(color), centerSlice: _fillSlice, fit: BoxFit.fill, filterQuality: FilterQuality.medium),
                    ),
                ]);
              },
            ),
          ),
        );
      }),
    );
  }
}
