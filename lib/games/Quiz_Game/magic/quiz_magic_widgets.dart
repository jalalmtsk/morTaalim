import 'dart:math';

import 'package:flutter/material.dart';

import '../../../widgets/KidScene/kid_scene.dart';
import '../ModeSelectorPage.dart';
import 'quiz_magic_data.dart';

const Color qmPurple = Color(0xFF5B21C9);
const Color qmInk = Color(0xFF3A1580);
const Color qmCream = Color(0xFFFFF8EA);
const Color qmGold = Color(0xFFF5C24A);
const Color qmGreen = Color(0xFF34C759);
const Color qmRed = Color(0xFFFF4D6A);
const Color qmTeal = Color(0xFF16A6B0);

TextStyle qmTitle(double size, {Color color = qmInk}) => TextStyle(
      fontFamily: 'Fredoka',
      fontWeight: FontWeight.w700,
      fontSize: size,
      height: 1.1,
      color: color,
    );

BoxDecoration qmCard(double s, {Color border = qmGold, double radius = 24, Color fill = qmCream, Color? glow}) =>
    BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(radius * s),
      border: Border.all(color: border, width: 3 * s),
      boxShadow: [
        BoxShadow(color: (glow ?? qmPurple).withOpacity(glow == null ? 0.18 : 0.45), blurRadius: (glow == null ? 12 : 18) * s, offset: Offset(0, 5 * s)),
      ],
    );

/// Text with a thick outline, used for the big result titles.
class QmOutlinedText extends StatelessWidget {
  final String text;
  final double size;
  final Color fill, stroke;
  final List<Color>? gradient;
  const QmOutlinedText(this.text, {super.key, required this.size, this.fill = Colors.white, this.stroke = qmPurple, this.gradient});

  @override
  Widget build(BuildContext context) {
    final base = qmTitle(size);
    Widget inner = Text(text, textAlign: TextAlign.center, style: base.copyWith(color: fill));
    if (gradient != null) {
      inner = ShaderMask(
        shaderCallback: (r) => LinearGradient(colors: gradient!, begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(r),
        child: Text(text, textAlign: TextAlign.center, style: base.copyWith(color: Colors.white)),
      );
    }
    return Stack(alignment: Alignment.center, children: [
      Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: base.fontFamily,
          fontWeight: base.fontWeight,
          fontSize: base.fontSize,
          height: base.height,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = size * 0.16
            ..strokeJoin = StrokeJoin.round
            ..color = stroke,
          shadows: [Shadow(color: Colors.black.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 3))],
        ),
      ),
      inner,
    ]);
  }
}

// ── top bar ────────────────────────────────────────────────────────────────

class QmTopBar extends StatelessWidget {
  final double scale;
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final VoidCallback? onGear;
  const QmTopBar({super.key, required this.scale, required this.title, required this.onBack, this.onGear, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final btn = 48 * s;
    return SizedBox(
      height: 70 * s,
      child: Row(children: [
        KidPressable(
          onTap: onBack,
          child: Transform.flip(flipX: rtl, child: Image.asset(qmImgBack, width: btn, height: btn)),
        ),
        Expanded(
          child: Center(
            child: SizedBox(
              width: 240 * s,
              height: 70 * s,
              child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                Positioned.fill(child: Image.asset(qmImgTitle, fit: BoxFit.fill)),
                Padding(
                  padding: EdgeInsets.fromLTRB(26 * s, 8 * s, 26 * s, 6 * s),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(title, style: qmTitle(28 * s, color: qmPurple)),
                  ),
                ),
                if (subtitle != null)
                  Positioned(
                    bottom: -10 * s,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 2 * s),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF8A3FF0), Color(0xFF5B21C9)]),
                        borderRadius: BorderRadius.circular(14 * s),
                        border: Border.all(color: qmGold, width: 2 * s),
                      ),
                      child: Text('★ $subtitle ★', style: qmTitle(13 * s, color: Colors.white)),
                    ),
                  ),
              ]),
            ),
          ),
        ),
        onGear == null
            ? SizedBox(width: btn)
            : KidPressable(onTap: onGear, child: Image.asset(qmImgGear, width: btn, height: btn)),
      ]),
    );
  }
}

// ── progress ───────────────────────────────────────────────────────────────

class QmProgress extends StatelessWidget {
  final double scale;
  final String label;
  final double value;
  final int stars;
  final bool showStars;
  const QmProgress({super.key, required this.scale, required this.label, required this.value, required this.stars, this.showStars = true});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      height: 38 * s,
      padding: EdgeInsets.symmetric(horizontal: 12 * s),
      decoration: BoxDecoration(
        color: qmCream,
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(color: const Color(0xFFF1D9A8), width: 2 * s),
        boxShadow: [BoxShadow(color: qmPurple.withOpacity(0.15), blurRadius: 8 * s, offset: Offset(0, 3 * s))],
      ),
      child: Row(children: [
        Text(label, style: qmTitle(14 * s)),
        SizedBox(width: 10 * s),
        Expanded(
          child: Container(
            height: 14 * s,
            decoration: BoxDecoration(
              color: const Color(0xFFEAD9C2),
              borderRadius: BorderRadius.circular(8 * s),
            ),
            alignment: AlignmentDirectional.centerStart,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: value.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => FractionallySizedBox(
                widthFactor: max(0.06, v),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8 * s),
                    gradient: const LinearGradient(colors: [Color(0xFF32D3F5), Color(0xFF1C8DE8)]),
                    border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5 * s),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showStars) SizedBox(width: 8 * s),
        if (showStars)
          for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.only(left: 1 * s),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: c),
              child: Image.asset(i < stars ? qmImgStar : qmImgStarEmpty, key: ValueKey(i < stars), width: 24 * s, height: 24 * s),
            ),
          ),
      ]),
    );
  }
}

// ── category pill ──────────────────────────────────────────────────────────

class QmCategoryPill extends StatelessWidget {
  final double scale;
  final QmCategory category;
  final String lang;
  final double height;
  const QmCategoryPill({super.key, required this.scale, required this.category, required this.lang, this.height = 40});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final h = height * s;
    return Container(
      height: h,
      padding: EdgeInsetsDirectional.only(end: 14 * s),
      decoration: BoxDecoration(
        color: qmCream,
        borderRadius: BorderRadius.circular(h),
        border: Border.all(color: qmTeal.withOpacity(0.75), width: 2.5 * s),
        boxShadow: [BoxShadow(color: qmPurple.withOpacity(0.15), blurRadius: 8 * s, offset: Offset(0, 3 * s))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        QmCategoryIcon(category: category, size: h + 6 * s),
        SizedBox(width: 6 * s),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(qmCatName(category, lang), style: qmTitle(h * 0.42)),
          ),
        ),
      ]),
    );
  }
}

class QmCategoryIcon extends StatelessWidget {
  final QmCategory category;
  final double size;
  const QmCategoryIcon({super.key, required this.category, required this.size});

  @override
  Widget build(BuildContext context) {
    if (category.id == 'animals') return Image.asset(qmImgPaw, width: size, height: size);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(colors: [Color(0xFF3FD0D6), Color(0xFF0F8C98)]),
        border: Border.all(color: Colors.white, width: size * 0.07),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: size * 0.12, offset: Offset(0, size * 0.05))],
      ),
      child: Text(category.emoji, style: TextStyle(fontSize: size * 0.46)),
    );
  }
}

// ── robot with speech bubble ───────────────────────────────────────────────

enum QmMood { idle, happy, sad }

class QmRobot extends StatelessWidget {
  final double scale;
  final QmMood mood;
  final String bubble;
  final Animation<double> idle;
  const QmRobot({super.key, required this.scale, required this.mood, required this.bubble, required this.idle});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final happy = mood == QmMood.happy;
    final robotW = (happy ? 128 : 112) * s;
    return SizedBox(
      width: 200 * s,
      height: 100 * s,
      child: Stack(clipBehavior: Clip.none, children: [
        // robot
        PositionedDirectional(
          start: 0,
          bottom: 0,
          child: AnimatedBuilder(
            animation: idle,
            builder: (_, c) {
              final t = idle.value * 2 * pi;
              final hop = happy ? (sin(t * 4).abs() * 6 * s) : sin(t) * 2.5 * s;
              final tilt = mood == QmMood.sad ? sin(t) * 0.03 - 0.05 : sin(t * 2) * 0.03;
              return Transform.translate(offset: Offset(0, -hop), child: Transform.rotate(angle: tilt, alignment: Alignment.bottomCenter, child: c));
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Image.asset(
                happy ? qmImgRobotPeek : qmImgRobotStand,
                key: ValueKey(happy),
                width: robotW,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        // bubble
        PositionedDirectional(
          end: 0,
          top: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
            child: SizedBox(
              key: ValueKey(bubble),
              width: 92 * s,
              height: 66 * s,
              child: Stack(alignment: Alignment.center, children: [
                Positioned.fill(child: Image.asset(qmImgBubble, fit: BoxFit.fill)),
                Padding(
                  padding: EdgeInsets.fromLTRB(10 * s, 6 * s, 8 * s, 16 * s),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 90 * s),
                      child: Text(bubble, textAlign: TextAlign.center, style: qmTitle(15 * s, color: qmPurple)),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── question card ──────────────────────────────────────────────────────────

class QmSpeaker extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;
  const QmSpeaker({super.key, required this.size, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return SizedBox(width: size);
    return KidPressable(onTap: onTap, child: Image.asset(qmImgSpeaker, width: size, height: size));
  }
}

class QmQuestionCard extends StatelessWidget {
  final double scale;
  final String text;
  final VoidCallback? onSpeak;
  const QmQuestionCard({super.key, required this.scale, required this.text, this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      constraints: BoxConstraints(minHeight: 84 * s),
      padding: EdgeInsetsDirectional.fromSTEB(18 * s, 12 * s, 10 * s, 12 * s),
      decoration: qmCard(s, radius: 28),
      child: Row(children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              text,
              key: ValueKey(text),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: qmTitle(text.length > 60 ? 18 * s : 21 * s, color: qmPurple),
            ),
          ),
        ),
        SizedBox(width: 8 * s),
        QmSpeaker(size: 52 * s, onTap: onSpeak),
      ]),
    );
  }
}

// ── answer picture ─────────────────────────────────────────────────────────

/// Picture for an answer: its image when one exists, a paint swatch for a
/// colour, otherwise a big friendly word card.
class QmAnswerArt extends StatelessWidget {
  final String? artKey;
  final String text;
  final double radius;
  const QmAnswerArt({super.key, required this.artKey, required this.text, required this.radius});

  static bool hasPicture(String? key) => QmAssets.has(key) || qmSwatches.containsKey(key);

  @override
  Widget build(BuildContext context) {
    final k = artKey;
    Widget child;
    if (QmAssets.has(k)) {
      child = Image.asset(qmAnswerAsset(k!), fit: BoxFit.cover, filterQuality: FilterQuality.medium);
    } else if (qmSwatches.containsKey(k)) {
      child = LayoutBuilder(builder: (_, c) {
        final d = min(c.maxWidth, c.maxHeight) * 0.66;
        final col = qmSwatches[k]!;
        return Center(
          child: Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.4),
                colors: [Color.lerp(col, Colors.white, 0.45)!, col, Color.lerp(col, Colors.black, 0.18)!],
                stops: const [0, 0.55, 1],
              ),
              border: Border.all(color: Colors.white, width: d * 0.06),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: d * 0.12, offset: Offset(0, d * 0.05))],
            ),
          ),
        );
      });
    } else {
      child = Center(
        child: Padding(
          padding: EdgeInsets.all(radius * 0.4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, textAlign: TextAlign.center, style: qmTitle(qmIsNumber(text) ? 64 : 34, color: qmPurple)),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDDF1FF), Color(0xFFF4FBE9)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

// ── answer tile ────────────────────────────────────────────────────────────

enum QmTileState { idle, correct, wrong, faded }

class QmAnswerTile extends StatelessWidget {
  final double scale;
  final String letter;
  final String text;
  final String? artKey;
  final QmTileState state;
  final bool selected;
  final Color selectedColor;
  final bool hidden; // removed by the hint joker
  final VoidCallback? onTap;
  const QmAnswerTile({
    super.key,
    required this.scale,
    required this.letter,
    required this.text,
    required this.artKey,
    required this.state,
    this.selected = false,
    this.selectedColor = const Color(0xFF2E8BFF),
    this.hidden = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final pic = QmAnswerArt.hasPicture(artKey);
    final border = switch (state) {
      QmTileState.correct => qmGreen,
      QmTileState.wrong => qmRed,
      _ => selected ? selectedColor : const Color(0xFF9B7BE0),
    };
    final fill = switch (state) {
      QmTileState.correct => const Color(0xFFEFFFF0),
      QmTileState.wrong => const Color(0xFFFFEFF1),
      _ => qmCream,
    };
    final glow = switch (state) {
      QmTileState.correct => qmGreen,
      QmTileState.wrong => qmRed,
      _ => selected ? selectedColor : null,
    };
    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.all(7 * s),
      decoration: qmCard(s, border: border, fill: fill, radius: 22, glow: glow),
      child: Column(children: [
        Expanded(child: QmAnswerArt(artKey: artKey, text: text, radius: 16 * s)),
        if (pic)
          Padding(
            padding: EdgeInsets.only(top: 4 * s),
            child: SizedBox(
              height: 22 * s,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(text, style: qmTitle(18 * s)),
              ),
            ),
          ),
      ]),
    );
    final badge = switch (state) {
      QmTileState.correct => qmImgBadgeOk,
      QmTileState.wrong => qmImgBadgeX,
      _ => null,
    };
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: hidden ? 0.18 : (state == QmTileState.faded ? 0.55 : 1),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        scale: hidden ? 0.86 : (state == QmTileState.correct || selected ? 1.04 : 1),
        child: KidPressable(
          onTap: hidden ? null : onTap,
          pressedScale: 0.95,
          semanticLabel: text,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(child: tile),
            PositionedDirectional(
              start: 4 * s,
              top: 4 * s,
              child: SizedBox(
                width: 34 * s,
                height: 34 * s,
                child: Stack(alignment: Alignment.center, children: [
                  Image.asset(qmImgLetter, width: 34 * s, height: 34 * s),
                  Text(letter, style: qmTitle(17 * s, color: qmPurple)),
                ]),
              ),
            ),
            if (badge != null)
              PositionedDirectional(
                end: -6 * s,
                top: -8 * s,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.elasticOut,
                  builder: (_, v, c) => Transform.scale(scale: v, child: c),
                  child: Image.asset(badge, width: 44 * s, height: 44 * s),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ── feedback panel ─────────────────────────────────────────────────────────

class QmFeedbackPanel extends StatelessWidget {
  final double scale;
  final bool correct;
  final String title;
  final String line;
  final String? artKey;
  final String answerText;
  final String continueLabel;
  final VoidCallback? onSpeak;
  final VoidCallback onContinue;
  const QmFeedbackPanel({
    super.key,
    required this.scale,
    required this.correct,
    required this.title,
    required this.line,
    required this.artKey,
    required this.answerText,
    required this.continueLabel,
    required this.onSpeak,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final border = correct ? const Color(0xFF8BD650) : qmGold;
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        margin: EdgeInsets.only(top: correct ? 0 : 18 * s),
        padding: EdgeInsets.fromLTRB(16 * s, correct ? 12 * s : 26 * s, 16 * s, 14 * s),
        decoration: qmCard(s, border: border, radius: 28, glow: correct ? qmGreen : null),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (correct)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset(qmImgStar, width: 24 * s),
              SizedBox(width: 6 * s),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(title, style: qmTitle(28 * s, color: const Color(0xFF2E9E3A))),
                ),
              ),
              SizedBox(width: 6 * s),
              Image.asset(qmImgStar, width: 24 * s),
            ]),
          SizedBox(height: 8 * s),
          Row(children: [
            if (!correct && QmAnswerArt.hasPicture(artKey))
              Padding(
                padding: EdgeInsetsDirectional.only(end: 10 * s),
                child: Container(
                  width: 66 * s,
                  height: 66 * s,
                  padding: EdgeInsets.all(3 * s),
                  decoration: qmCard(s, border: qmGreen, radius: 16),
                  child: QmAnswerArt(artKey: artKey, text: answerText, radius: 12 * s),
                ),
              ),
            Expanded(
              child: Text(line, textAlign: correct ? TextAlign.center : TextAlign.start, style: kidBodyStyle(16 * s, color: qmInk, weight: FontWeight.w600)),
            ),
            SizedBox(width: 6 * s),
            QmSpeaker(size: 46 * s, onTap: onSpeak),
          ]),
          SizedBox(height: 12 * s),
          KidButton(label: continueLabel, onPressed: onContinue, width: 250 * s, height: 54 * s, showArrow: false),
        ]),
      ),
      if (!correct)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 22 * s, vertical: 5 * s),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE1E1),
                borderRadius: BorderRadius.circular(30 * s),
                border: Border.all(color: const Color(0xFFFFB4B4), width: 2.5 * s),
                boxShadow: [BoxShadow(color: qmRed.withOpacity(0.25), blurRadius: 8 * s, offset: Offset(0, 3 * s))],
              ),
              child: Text(title, style: qmTitle(24 * s, color: const Color(0xFFE5273F))),
            ),
          ),
        ),
    ]);
  }
}

// ── shared bits for the menu and the duel ──────────────────────────────────

/// Round avatar picture with an optional coloured ring.
class QmAvatar extends StatelessWidget {
  final String avatar;
  final double size;
  final Color? ring;
  const QmAvatar({super.key, required this.avatar, required this.size, this.ring});

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(qmAvatarAsset(avatar), width: size, height: size, fit: BoxFit.contain);
    if (ring == null) return img;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: ring!.withOpacity(0.55), blurRadius: size * 0.18, spreadRadius: size * 0.02)],
      ),
      child: img,
    );
  }
}

/// Yellow "VS" on the purple winged shield.
class QmVsBadge extends StatelessWidget {
  final double width;
  const QmVsBadge({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.63,
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(child: Image.asset(qmImgVs, fit: BoxFit.contain)),
        Padding(
          padding: EdgeInsets.only(bottom: width * 0.06),
          child: QmOutlinedText('VS', size: width * 0.26, stroke: const Color(0xFF6A1FB8), gradient: const [Color(0xFFFFF27A), Color(0xFFFFA51F)]),
        ),
      ]),
    );
  }
}

/// Cream card with a tab-shaped title on top ("★ Choisis ton thème ★").
class QmSection extends StatelessWidget {
  final double scale;
  final String title;
  final Widget child;
  final Color border;
  const QmSection({super.key, required this.scale, required this.title, required this.child, this.border = qmGold});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        width: double.infinity,
        margin: EdgeInsets.only(top: 18 * s),
        padding: EdgeInsets.fromLTRB(10 * s, 26 * s, 10 * s, 10 * s),
        decoration: qmCard(s, border: border, radius: 24),
        child: child,
      ),
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 4 * s),
            decoration: BoxDecoration(
              color: qmCream,
              borderRadius: BorderRadius.circular(20 * s),
              border: Border.all(color: border, width: 2.5 * s),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Image.asset(qmImgStar, width: 20 * s),
              SizedBox(width: 6 * s),
              Text(title, style: qmTitle(19 * s)),
              SizedBox(width: 6 * s),
              Image.asset(qmImgStar, width: 20 * s),
            ]),
          ),
        ),
      ),
    ]);
  }
}

/// Small green check badge in a corner.
class QmCheck extends StatelessWidget {
  final double size;
  const QmCheck({super.key, required this.size});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.elasticOut,
        builder: (_, v, c) => Transform.scale(scale: v, child: c),
        child: Image.asset(qmImgCheck, width: size, height: size),
      );
}

/// Level chip (leaf / star / lightning).
class QmLevelChip extends StatelessWidget {
  final double scale;
  final int level;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const QmLevelChip({super.key, required this.scale, required this.level, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return KidPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 38 * s,
        padding: EdgeInsets.symmetric(horizontal: 8 * s),
        decoration: BoxDecoration(
          gradient: selected ? const LinearGradient(colors: [Color(0xFF3CD07A), Color(0xFF14A05A)]) : null,
          color: selected ? null : qmCream,
          borderRadius: BorderRadius.circular(20 * s),
          border: Border.all(color: selected ? const Color(0xFF9CF5BF) : const Color(0xFFF1D9A8), width: 2 * s),
          boxShadow: selected ? [BoxShadow(color: qmGreen.withOpacity(0.45), blurRadius: 10 * s)] : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          selected && level == 0
              ? ColorFiltered(
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  child: Image.asset(qmLevelIcons[level], height: 20 * s),
                )
              : Image.asset(qmLevelIcons[level], height: 20 * s),
          SizedBox(width: 5 * s),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: qmTitle(15 * s, color: selected ? Colors.white : qmInk)),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Theme picture tile with its name.
class QmThemeTile extends StatelessWidget {
  final double scale;
  final QmTheme theme;
  final String lang;
  final bool selected;
  final VoidCallback onTap;
  const QmThemeTile({super.key, required this.scale, required this.theme, required this.lang, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.95,
      child: Stack(clipBehavior: Clip.none, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.all(5 * s),
          decoration: qmCard(s,
              border: selected ? qmGreen : const Color(0xFFB79BEA), radius: 18, glow: selected ? qmGreen : null),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AspectRatio(
              aspectRatio: 2.1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13 * s),
                child: Image.asset(theme.image, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 3 * s),
            SizedBox(
              height: 20 * s,
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(qmThemeName(theme, lang), style: qmTitle(16 * s))),
            ),
          ]),
        ),
        if (selected) PositionedDirectional(end: -6 * s, top: -8 * s, child: QmCheck(size: 34 * s)),
      ]),
    );
  }
}

/// Settings: voice on/off and (from the menu) the quiz language.
Future<void> qmOpenSettings(
  BuildContext context, {
  required QuizLanguage language,
  ValueChanged<QuizLanguage>? onLanguage,
  ValueChanged<bool>? onVoice,
}) async {
  final ui = qmUiLang(language);
  var lang = language;
  var voice = QmPrefs.voice;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => KidDialog(
        title: qmText(ui, 'settings'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          SwitchListTile(
            value: voice,
            activeColor: qmPurple,
            contentPadding: EdgeInsets.zero,
            title: Text(qmText(ui, 'voice'), style: kidBodyStyle(16, color: qmInk, weight: FontWeight.w600)),
            onChanged: (v) {
              setD(() => voice = v);
              QmPrefs.voice = v;
              onVoice?.call(v);
            },
          ),
          if (onLanguage != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(qmText(ui, 'language'), style: kidBodyStyle(15, color: qmInk, weight: FontWeight.w700)),
            ),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final l in QuizLanguage.values)
                ChoiceChip(
                  label: Text(qmLanguageNames[l] ?? l.name),
                  selected: l == lang,
                  selectedColor: const Color(0xFFE6D8FF),
                  onSelected: (_) {
                    setD(() => lang = l);
                    onLanguage(l);
                  },
                ),
            ]),
          ],
        ]),
        actions: [
          KidButton(
            label: qmText(ui, 'ok'),
            onPressed: () => Navigator.of(ctx).pop(),
            width: 180,
            height: 52,
            showArrow: false,
          ),
        ],
      ),
    ),
  );
}
