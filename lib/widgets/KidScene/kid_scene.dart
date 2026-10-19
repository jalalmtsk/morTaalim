import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Shared building blocks for the illustrated first-run screens
/// (Login → Welcome → Language → Name).
///
/// Every screen is designed on a 941 × 1672 canvas (the size of the
/// background artwork). [KidSceneGeometry] maps those design pixels onto the
/// real screen so sprites stay glued to the painted scenery on any phone.
class KidAssets {
  KidAssets._();
  static const String dir = 'assets/images/UI/KidScene/';

  // Backgrounds
  static const String loginBg = '${dir}login_bg.webp';
  static const String welcomeBg = '${dir}onboarding_welcome_bg.webp';
  static const String valleyBg = '${dir}onboarding_valley_bg.webp';

  // Login sprites
  static const String logo = '${dir}logo.webp';
  static const String mascot = '${dir}mascot.webp';
  static const String rocket = '${dir}rocket.webp';
  static const String pencil = '${dir}pencil.webp';
  static const String globe = '${dir}globe.webp';
  static const String letterA = '${dir}letter_a.webp';
  static const String blocks = '${dir}blocks.webp';
  static const String starBig = '${dir}star_big.webp';
  static const String starSmall = '${dir}star_small.webp';
  static const String icGlobe = '${dir}ic_globe.webp';
  static const String icChevron = '${dir}ic_chevron.webp';
  static const String icLock = '${dir}ic_lock.webp';

  // Onboarding sprites
  static const String wordmark = '${dir}wordmark.webp';
  static const String mascotWalk = '${dir}mascot_walk.webp';
  static const String blocksAbc = '${dir}blocks_abc.webp';
  static const String blocks123 = '${dir}blocks_123.webp';
  static const String globe2 = '${dir}globe2.webp';
  static const String star2 = '${dir}star2.webp';
  static const String backBtn = '${dir}back_btn.webp';
  static const String mascotSign = '${dir}mascot_sign.webp';
  static const String mascotWave = '${dir}mascot_wave.webp';
  static const String island = '${dir}island.webp';
  static const String star5Big = '${dir}star5_big.webp';
  static const String star5Small = '${dir}star5_small.webp';
  static const String exclaim = '${dir}exclaim.webp';
  static const String pencilYellow = '${dir}pencil_yellow.webp';
  static const String icPencilPurple = '${dir}ic_pencil_purple.webp';
  static const String mascotGlobe = '${dir}mascot_globe.webp';
  static const String pinOrange = '${dir}pin_orange.webp';
  static const String icPinPurple = '${dir}ic_pin_purple.webp';
  static const String mascotStudent = '${dir}mascot_student.webp';
  static const String books = '${dir}books.webp';
  static const String school = '${dir}school.webp';
  static const String bookStar = '${dir}book_star.webp';
  static const String mascotPeek = '${dir}mascot_peek.webp';
  static const String avatarMascot = '${dir}avatar_mascot.webp';

  // Age page
  static const String ageAbc = '${dir}age_abc.webp';
  static const String ageBook = '${dir}age_book.webp';
  static const String ageMascot = '${dir}age_mascot.webp';
  static const String agePlanet = '${dir}age_planet.webp';
  static const String ageRocket = '${dir}age_rocket.webp';

  // Final loading screen
  static const String ldAbc = '${dir}ld_abc.webp';
  static const String ldBook = '${dir}ld_book.webp';
  static const String ldGlobe = '${dir}ld_globe.webp';
  static const String ldMascot = '${dir}ld_mascot.webp';
  static const String ldPencil = '${dir}ld_pencil.webp';
  static const String ldRays = '${dir}ld_rays.webp';
  static const String ldSchool = '${dir}ld_school.webp';
  static const String ldSparkle = '${dir}ld_sparkle.webp';
  static const String ldStar = '${dir}ld_star.webp';
  static const String ldSwirl = '${dir}ld_swirl.webp';

  // Flags
  static const String flagMa = '${dir}flag_ma.webp';
  static const String flagFr = '${dir}flag_fr.webp';
  static const String flagUk = '${dir}flag_uk.webp';
  static const String flagDe = '${dir}flag_de.webp';
  static const String flagZgh = '${dir}flag_zgh.webp';

  /// Warm the image cache so nothing pops in during the intro animation.
  static void precache(BuildContext context, List<String> assets) {
    for (final a in assets) {
      precacheImage(AssetImage(a), context);
    }
  }
}

class KidColors {
  KidColors._();
  static const Color ink = Color(0xFF2D0B57); // titles
  static const Color inkSoft = Color(0xFF3B2465); // subtitles
  static const Color muted = Color(0xFF6E6787);
  static const Color purple = Color(0xFF7B3FE4);
  static const Color purpleDeep = Color(0xFF5B21C9);
  static const Color purpleLight = Color(0xFFEDE4FF);
  static const Color lavender = Color(0xFFCDBDF4);
  static const Color cream = Color(0xFFFFFBF3);
  static const Color orangeTop = Color(0xFFFFB63D);
  static const Color orange = Color(0xFFFF8D1E);
  static const Color orangeDeep = Color(0xFFFF7110);
  static const Color orangeLip = Color(0xFFD9570A);
  static const Color sky = Color(0xFF45AEEE);
}

/// Rounded, bold Fredoka text used for titles on the illustrated screens.
TextStyle kidTitleStyle(double size, {Color color = KidColors.ink}) => TextStyle(
      fontFamily: 'Fredoka',
      fontWeight: FontWeight.w700,
      fontSize: size,
      height: 1.04,
      color: color,
      letterSpacing: -0.2,
      shadows: [
        Shadow(color: Colors.white.withOpacity(0.95), blurRadius: size * 0.22),
        Shadow(color: Colors.white.withOpacity(0.6), blurRadius: size * 0.5),
      ],
    );

TextStyle kidBodyStyle(double size,
        {Color color = KidColors.inkSoft, FontWeight weight = FontWeight.w500}) =>
    TextStyle(
      fontFamily: 'Fredoka',
      fontWeight: weight,
      fontSize: size,
      height: 1.2,
      color: color,
    );

/// Maps the 941 × 1672 design canvas onto the screen.
///
/// The artwork is always fitted by *height*, so the sky at the top and the
/// cream cloud panel at the bottom are never cut. Narrow phones crop the
/// sides a little; wide screens (tablets, foldables) get blurred side fill.
class KidSceneGeometry {
  static const double designW = 941;
  static const double designH = 1672;

  final Size screen;

  /// design px → logical px
  final double s;

  /// x offset of the canvas (negative when the sides are cropped)
  final double dx;

  const KidSceneGeometry._(this.screen, this.s, this.dx);

  factory KidSceneGeometry(Size screen) {
    final s = screen.height / designH;
    return KidSceneGeometry._(screen, s, (screen.width - designW * s) / 2);
  }

  double get canvasW => designW * s;
  double get visibleLeft => max(0.0, dx);
  double get visibleWidth => min(screen.width, canvasW);

  double x(double v) => dx + v * s;
  double y(double v) => v * s;
  double l(double v) => v * s;

  /// Left edge for an element, nudged inward on narrow phones so at most
  /// [bleed] of its width leaves the visible area.
  double fitLeft(double left, double width,
      {double bleed = 0.12, double margin = 4}) {
    final px = x(left), w = l(width);
    final minL = visibleLeft + margin - w * bleed;
    final maxL = visibleLeft + visibleWidth - margin - w * (1 - bleed);
    if (maxL < minL) return px;
    return px.clamp(minL, maxL).toDouble();
  }

  /// A design width, capped to the visible width minus side padding.
  double contentWidth(double designWidth, {double pad = 20}) =>
      min(l(designWidth), visibleWidth - pad * 2);

  /// A design length clamped between [lo] and [hi] logical px.
  double lc(double v, double lo, double hi) => l(v).clamp(lo, hi).toDouble();
}

/// The painted background, height-fitted, with blurred side fill on wide
/// screens. Wrapped in a RepaintBoundary so it rasterizes once.
class KidSceneBackground extends StatelessWidget {
  final String asset;
  final KidSceneGeometry g;

  const KidSceneBackground({super.key, required this.asset, required this.g});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (g.dx > 0.5) ...[
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Image.asset(asset, fit: BoxFit.cover, gaplessPlayback: true),
            ),
            ColoredBox(color: Colors.white.withOpacity(0.12)),
          ],
          Positioned(
            left: g.dx,
            top: 0,
            width: g.canvasW,
            height: g.screen.height,
            child: Image.asset(
              asset,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// A sprite placed in design coordinates, with an entrance animation and a
/// gentle idle loop (bob / sway / rotate / twinkle).
///
/// [idle] should be a repeating 0→1 controller; [speed] is an integer number
/// of cycles per loop so the motion is seamless.
class SceneSprite extends StatelessWidget {
  final KidSceneGeometry g;
  final String asset;

  /// design px
  final double left, top, width;

  /// image height / width
  final double aspect;

  final Animation<double> idle;
  final Animation<double> intro;
  final double introFrom, introTo;

  /// Idle motion, in design px / radians.
  final double bob, sway, rot, phase;
  final int speed;

  /// true → pops in with a bouncy scale; false → fades and rises.
  final bool pop;

  /// Sparkle-style pulsing (scale + opacity).
  final bool twinkle;

  /// Keep the sprite inside the visible area on narrow phones.
  final bool fitInside;

  /// Optional one-shot "jump" (0→1) e.g. when the mascot is tapped.
  final Animation<double>? jump;

  /// Painted on top of the image, in the sprite's own box (moves with it).
  final Widget? overlay;

  final VoidCallback? onTap;

  const SceneSprite({
    super.key,
    required this.g,
    required this.asset,
    required this.left,
    required this.top,
    required this.width,
    required this.aspect,
    required this.idle,
    required this.intro,
    this.introFrom = 0,
    this.introTo = 0.6,
    this.bob = 0,
    this.sway = 0,
    this.rot = 0,
    this.phase = 0,
    this.speed = 1,
    this.pop = true,
    this.twinkle = false,
    this.fitInside = true,
    this.jump,
    this.overlay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = g.l(width), h = w * aspect;
    final left0 = fitInside ? g.fitLeft(left, width) : g.x(left);

    Widget child = SizedBox(
      width: w,
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(asset,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true),
          if (overlay != null) overlay!,
        ],
      ),
    );

    final listenables = <Listenable>[idle, intro, if (jump != null) jump!];
    child = AnimatedBuilder(
      animation: Listenable.merge(listenables),
      child: child,
      builder: (context, c) {
        final a = 2 * pi * (idle.value * speed + phase);
        final span = (introTo - introFrom).abs() < 1e-6 ? 1.0 : (introTo - introFrom);
        final p = ((intro.value - introFrom) / span).clamp(0.0, 1.0);
        final fade = Curves.easeOut.transform(p);
        final back = Curves.easeOutBack.transform(p);

        double scale = pop ? (0.35 + 0.65 * back) : 1.0;
        double opacity = fade;
        double dy = sin(a) * g.l(bob) + (pop ? 0 : (1 - fade) * g.l(70));
        final dx = sin(a) * g.l(sway);
        double angle = sin(a + 1.3) * rot;

        if (twinkle) {
          final tw = 0.5 + 0.5 * sin(a);
          scale *= 0.72 + 0.34 * tw;
          opacity *= 0.55 + 0.45 * tw;
          angle += 0.25 * sin(a * 0.5);
        }

        if (jump != null && jump!.value > 0) {
          final j = jump!.value;
          dy -= sin(pi * j) * g.l(90);
          // squash on take-off & landing
          final squash = j < 0.15
              ? 1 - (j / 0.15) * 0.08
              : (j > 0.85 ? 1 - ((1 - j) / 0.15) * 0.08 : 1.0);
          scale *= 1.0;
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.rotate(
                angle: angle + sin(2 * pi * j) * 0.06,
                child: Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.diagonal3Values(
                      scale * (2 - squash), scale * squash, 1),
                  child: c,
                ),
              ),
            ),
          );
        }

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(scale: scale, child: c),
            ),
          ),
        );
      },
    );

    if (onTap != null) {
      child = GestureDetector(
          behavior: HitTestBehavior.opaque, onTap: onTap, child: child);
    }

    return Positioned(left: left0, top: g.y(top), width: w, height: h, child: child);
  }
}

/// Fades + slides a block in during the intro.
class KidIntro extends StatelessWidget {
  final Animation<double> intro;
  final double from, to, rise;
  final Widget child;

  const KidIntro({
    super.key,
    required this.intro,
    required this.child,
    this.from = 0.4,
    this.to = 1.0,
    this.rise = 24,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: intro,
      child: child,
      builder: (context, c) {
        final p = Curves.easeOutCubic
            .transform(((intro.value - from) / (to - from)).clamp(0.0, 1.0));
        return Opacity(
          opacity: p,
          child: Transform.translate(offset: Offset(0, (1 - p) * rise), child: c),
        );
      },
    );
  }
}

/// Big glossy orange 3D pill button with press-down, shine sweep and glow.
class KidButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double width;
  final double height;
  final bool showArrow;

  const KidButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.width,
    required this.height,
    this.loading = false,
    this.showArrow = true,
  });

  @override
  State<KidButton> createState() => _KidButtonState();
}

class _KidButtonState extends State<KidButton> with TickerProviderStateMixin {
  late final AnimationController _press =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
  late final AnimationController _shine =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))
        ..repeat();

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  void dispose() {
    _press.dispose();
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `width: double.infinity` means "fill the parent" — resolve it to a real
    // number, because the shine sweep and 3D lip are positioned from it.
    if (widget.width.isFinite) return _buildSized(context, widget.width);
    return LayoutBuilder(
      builder: (context, c) =>
          _buildSized(context, c.maxWidth.isFinite ? c.maxWidth : 280.0),
    );
  }

  Widget _buildSized(BuildContext context, double w) {
    final h = widget.height, lip = h * 0.09, r = h / 2;
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _press.forward() : null,
        onTapUp: _enabled
            ? (_) {
                _press.reverse();
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: () => _press.reverse(),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: widget.onPressed == null ? 0.5 : 1,
          child: AnimatedBuilder(
            animation: Listenable.merge([_press, _shine]),
            builder: (context, _) {
              final p = _press.value;
              final sv = _shine.value;
              final shineP = (sv / 0.32).clamp(0.0, 1.0);
              final glow = 0.5 + 0.5 * sin(sv * 2 * pi);
              return SizedBox(
                width: w,
                height: h + lip,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 3D lip + soft glow
                    Positioned(
                      left: 0,
                      right: 0,
                      top: lip,
                      height: h,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: KidColors.orangeLip,
                          borderRadius: BorderRadius.circular(r),
                          boxShadow: [
                            BoxShadow(
                              color: KidColors.orangeDeep
                                  .withOpacity(_enabled ? 0.28 + 0.14 * glow : 0.15),
                              blurRadius: h * (0.35 + 0.15 * glow),
                              offset: Offset(0, h * 0.16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // face
                    Positioned(
                      left: 0,
                      right: 0,
                      top: lip * p,
                      height: h,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(r),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    KidColors.orangeTop,
                                    KidColors.orange,
                                    KidColors.orangeDeep
                                  ],
                                  stops: [0, 0.55, 1],
                                ),
                              ),
                            ),
                            // top gloss
                            Positioned(
                              left: r * 0.55,
                              right: r * 0.55,
                              top: h * 0.07,
                              height: h * 0.34,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(h),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withOpacity(0.55),
                                      Colors.white.withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // shine sweep
                            if (_enabled && sv < 0.32)
                              Positioned(
                                top: -h * 0.2,
                                bottom: -h * 0.2,
                                left: -w * 0.3 + w * 1.6 * shineP,
                                width: w * 0.16,
                                child: Transform(
                                  transform: Matrix4.skewX(-0.35),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        Colors.white.withOpacity(0),
                                        Colors.white.withOpacity(0.38),
                                        Colors.white.withOpacity(0),
                                      ]),
                                    ),
                                  ),
                                ),
                              ),
                            Center(
                              child: widget.loading
                                  ? SizedBox(
                                      width: h * 0.42,
                                      height: h * 0.42,
                                      child: const CircularProgressIndicator(
                                          strokeWidth: 3.2, color: Colors.white),
                                    )
                                  : Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: h * 0.4),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              widget.label,
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontFamily: 'Fredoka',
                                                fontWeight: FontWeight.w700,
                                                fontSize: h * 0.4,
                                                height: 1.0,
                                                color: Colors.white,
                                                shadows: [
                                                  Shadow(
                                                    color: const Color(0x80B34400),
                                                    offset: Offset(0, h * 0.03),
                                                    blurRadius: h * 0.05,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (widget.showArrow) ...[
                                              SizedBox(width: h * 0.16),
                                              Icon(Icons.arrow_forward_rounded,
                                                  color: Colors.white,
                                                  size: h * 0.44,
                                                  shadows: const [
                                                    Shadow(
                                                        color: Color(0x80B34400),
                                                        offset: Offset(0, 1.5),
                                                        blurRadius: 2)
                                                  ]),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Wraps any widget with a springy press-scale.
class KidPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final String? semanticLabel;

  const KidPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.92,
    this.semanticLabel,
  });

  @override
  State<KidPressable> createState() => _KidPressableState();
}

class _KidPressableState extends State<KidPressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          widget.onTap?.call();
        },
        child: AnimatedScale(
          scale: _down ? widget.pressedScale : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Round purple back button (sprite), mirrored for RTL.
class KidBackButton extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const KidBackButton({super.key, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return KidPressable(
      onTap: onTap,
      semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
      child: Transform.flip(
        flipX: rtl,
        child: Image.asset(KidAssets.backBtn,
            width: size, height: size * 162 / 161, filterQuality: FilterQuality.medium),
      ),
    );
  }
}

/// Page dots: lavender circles + a purple pill for the active page.
class KidDots extends StatelessWidget {
  final int count;
  final int active;
  final double size;

  const KidDots({super.key, required this.count, required this.active, this.size = 11});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final on = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          // No overshooting curve here: it would lerp width/blur below zero.
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(horizontal: size * 0.45),
          width: on ? size * 2.6 : size,
          height: size,
          decoration: BoxDecoration(
            color: on ? KidColors.purple : KidColors.lavender.withOpacity(0.85),
            borderRadius: BorderRadius.circular(size),
            // Same shadow list in both states (transparent when inactive) so
            // the decoration tween never interpolates from/to null.
            boxShadow: [
              BoxShadow(
                  color: KidColors.purple.withOpacity(on ? 0.35 : 0.0),
                  blurRadius: size * 0.8,
                  offset: Offset(0, size * 0.2)),
            ],
          ),
        );
      }),
    );
  }
}

/// Cream rounded dialog shell in the same style as the screens.
class KidDialog extends StatelessWidget {
  final String? headerAsset;
  final double headerAspect;
  final String title;
  final String? message;
  final Widget? content;
  final List<Widget> actions;

  const KidDialog({
    super.key,
    this.headerAsset,
    this.headerAspect = 1,
    required this.title,
    this.message,
    this.content,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final headerH = headerAsset == null ? 0.0 : 96.0;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: EdgeInsets.only(top: headerH * 0.55),
              padding: EdgeInsets.fromLTRB(22, headerH * 0.5 + 18, 22, 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFFFFF), KidColors.cream],
                ),
                border: Border.all(color: KidColors.lavender, width: 2.5),
                boxShadow: [
                  BoxShadow(
                      color: KidColors.purpleDeep.withOpacity(0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 12)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      textAlign: TextAlign.center,
                      style: kidBodyStyle(22, color: KidColors.ink, weight: FontWeight.w700)),
                  if (message != null) ...[
                    const SizedBox(height: 10),
                    Text(message!,
                        textAlign: TextAlign.center,
                        style: kidBodyStyle(15, color: KidColors.muted)),
                  ],
                  if (content != null) ...[const SizedBox(height: 16), content!],
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        for (int i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          Expanded(child: actions[i]),
                        ]
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (headerAsset != null)
              Image.asset(headerAsset!,
                  height: headerH, width: headerH / headerAspect, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}

/// Secondary outlined pill used in dialogs.
class KidOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double height;

  const KidOutlineButton(
      {super.key, required this.label, required this.onTap, this.height = 54});

  @override
  Widget build(BuildContext context) {
    return KidPressable(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(height),
          border: Border.all(color: KidColors.purple, width: 2.5),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: kidBodyStyle(height * 0.34,
                    color: KidColors.purple, weight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
