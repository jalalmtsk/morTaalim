import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';

import 'animal_sounds_data.dart';

const Color asTeal = Color(0xFF19C2C9);
const Color asTealDeep = Color(0xFF0E9AA7);
const Color asCream = Color(0xFFFFF6E3);
const Color asGreen = Color(0xFF3CC85A);
const Color asRed = Color(0xFFFF5A5A);

const String asSign = '${asDir}as_sign.webp';
const String asRobot = '${asDir}as_robot.webp';
const String asBanner = '${asDir}as_banner.webp';
const String asSoundOn = '${asDir}as_sound_on.webp';
const String asSoundOff = '${asDir}as_sound_off.webp';
const String asNoteYellow = '${asDir}as_note_yellow.webp';
const String asNoteBlue = '${asDir}as_note_blue.webp';
const String asSparkle = '${asDir}as_sparkle.webp';
const String asWaves = '${asDir}as_waves.webp';
const String asPaw = '${asDir}as_paw.webp';
const String asPageBg = '${asDir}it_page_bg.webp';

const List<String> asUiAssets = [
  asSign, asRobot, asBanner, asSoundOn, asSoundOff, asNoteYellow, asNoteBlue, asSparkle, asWaves, asPaw, asPageBg,
];

/// Plays one animal at a time (a new tap stops the previous sound) and follows
/// the app's sound-effects volume. Long recordings are cut after [max].
class AsVoice {
  final AudioPlayer _p = AudioPlayer();
  Timer? _cap;

  Future<Duration> play(String asset, AudioManager audio, {Duration max = const Duration(seconds: 5)}) async {
    _cap?.cancel();
    try {
      await _p.stop();
      final d = await _p.setAsset(asset) ?? const Duration(seconds: 2);
      await _p.setVolume(audio.isSfxMuted ? 0 : audio.sfxVolume);
      _p.play();
      final len = d < max ? d : max;
      _cap = Timer(len, () => _p.stop());
      return len;
    } catch (_) {
      return const Duration(seconds: 1);
    }
  }

  Future<void> stop() async {
    _cap?.cancel();
    try {
      await _p.stop();
    } catch (_) {}
  }

  void dispose() {
    _cap?.cancel();
    _p.dispose();
  }
}

/// Cream pill with a white rim and soft purple shadow.
BoxDecoration asPill(double r, {Color color = asCream}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.16), blurRadius: 10, offset: const Offset(0, 4))],
    );

/// Big white title with a thick purple outline (like the mockup).
class AsTitle extends StatelessWidget {
  final String text;
  final double size;
  const AsTitle(this.text, {super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: size, height: 1.1, letterSpacing: -0.3);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Stack(children: [
        Text(text,
            maxLines: 1,
            style: base.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = size * 0.17
                ..strokeJoin = StrokeJoin.round
                ..color = KidColors.purpleDeep,
              shadows: [Shadow(color: KidColors.purpleDeep.withOpacity(0.45), blurRadius: size * 0.1, offset: Offset(0, size * 0.08))],
            )),
        Text(text, maxLines: 1, style: base.copyWith(color: Colors.white)),
      ]),
    );
  }
}

/// Segmented cream bar; the selected tab is a glossy teal pill.
class AsTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onTap;
  final double s;
  const AsTabs({super.key, required this.labels, required this.index, required this.onTap, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46 * s,
      padding: EdgeInsets.all(4 * s),
      decoration: asPill(30 * s),
      child: Row(children: [
        for (int i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.symmetric(horizontal: 2 * s),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24 * s),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: i == index ? const [Color(0xFF45E3DA), asTealDeep] : const [Color(0x00FFFFFF), Color(0x00FFFFFF)],
                  ),
                  boxShadow: [
                    BoxShadow(color: asTealDeep.withOpacity(i == index ? 0.35 : 0), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4 * s),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(labels[i],
                        maxLines: 1,
                        style: kidBodyStyle(16 * s, color: i == index ? Colors.white : KidColors.ink, weight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Paw · label · green bar.
class AsProgressPill extends StatelessWidget {
  final double s;
  final String label;
  final double value;
  const AsProgressPill({super.key, required this.s, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52 * s,
      padding: EdgeInsetsDirectional.fromSTEB(14 * s, 6 * s, 18 * s, 6 * s),
      decoration: asPill(30 * s),
      child: Row(children: [
        Image.asset(asPaw, width: 28 * s, height: 28 * s * 37 / 46),
        SizedBox(width: 12 * s),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, maxLines: 1, style: kidBodyStyle(15 * s, color: KidColors.ink, weight: FontWeight.w700)),
              ),
              SizedBox(height: 5 * s),
              AsBar(value: value, height: 10 * s),
            ],
          ),
        ),
      ]),
    );
  }
}

class AsBar extends StatelessWidget {
  final double value, height;
  const AsBar({super.key, required this.value, required this.height});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: SizedBox(
          height: height,
          child: Stack(children: [
            const Positioned.fill(child: ColoredBox(color: Color(0xFFE2D9C8))),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              alignment: AlignmentDirectional.centerStart,
              widthFactor: value.clamp(0.0, 1.0),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8BEA74), Color(0xFF2FB344)]),
                ),
              ),
            ),
          ]),
        ),
      );
}

enum AsMark { none, right, wrong }

/// One animal: its scene, the animal, its name and the speaker button.
class AsCard extends StatelessWidget {
  final AsAnimal animal;
  final double s;
  final bool active; // its sound is playing
  final int bounce; // change it to replay the little jump
  final bool showSound;
  final bool showName;
  final bool showBubble;
  final AsMark mark;
  final bool dim;
  final VoidCallback? onTap;

  const AsCard({
    super.key,
    required this.animal,
    required this.s,
    this.active = false,
    this.bounce = 0,
    this.showSound = true,
    this.showName = true,
    this.showBubble = true,
    this.mark = AsMark.none,
    this.dim = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = 22 * s;
    final rim = switch (mark) {
      AsMark.right => asGreen,
      AsMark.wrong => asRed,
      AsMark.none => active ? asTeal : Colors.white,
    };
    final lit = mark != AsMark.none || active;
    final bw = lit ? 3.5 * s : 2.5 * s;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.95,
      semanticLabel: animal.name(context),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: dim ? 0.45 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: asCream,
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: rim, width: bw),
            boxShadow: [
              BoxShadow(
                color: (lit ? rim : KidColors.purpleDeep).withOpacity(lit ? 0.55 : 0.16),
                blurRadius: lit ? 18 : 10,
                spreadRadius: lit ? 1 : 0,
                offset: Offset(0, lit ? 0 : 4),
              ),
            ],
          ),
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth, h = c.maxHeight;
            final picH = showName ? h * 0.80 : h;
            final btn = min(44 * s, h * 0.34);
            return Stack(clipBehavior: Clip.none, children: [
              // scene + animal
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: picH,
                child: ClipPath(
                  clipper: _AsWaveClip(radius: max(0, r - bw), wave: showName),
                  child: Stack(fit: StackFit.expand, children: [
                    Image.asset(animal.scene, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
                    Padding(
                      padding: EdgeInsets.fromLTRB(w * 0.07, picH * 0.07, w * 0.07, picH * (showName ? 0.10 : 0.05)),
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(bounce),
                        tween: Tween(begin: bounce == 0 ? 1.0 : 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 750),
                        builder: (_, v, child) {
                          final k = sin(v * pi * 3) * (1 - v);
                          return Transform(
                            alignment: Alignment.bottomCenter,
                            transform: Matrix4.identity()
                              ..translate(0.0, -k.abs() * 10 * s)
                              ..scale(1 - k * 0.06, 1 + k * 0.08),
                            child: child,
                          );
                        },
                        child: Image.asset(animal.sprite,
                            fit: BoxFit.contain, alignment: Alignment.bottomCenter, filterQuality: FilterQuality.medium),
                      ),
                    ),
                  ]),
                ),
              ),
              // name
              if (showName)
                PositionedDirectional(
                  start: 12 * s,
                  end: showSound ? btn + 10 * s : 12 * s,
                  bottom: 0,
                  height: h - picH + 2 * s,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(animal.name(context),
                          maxLines: 1, style: kidTitleStyle(21 * s).copyWith(shadows: const [])),
                    ),
                  ),
                ),
              // speaker
              if (showSound)
                PositionedDirectional(
                  end: 6 * s,
                  bottom: 5 * s,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                    child: Image.asset(active ? asSoundOn : asSoundOff,
                        key: ValueKey(active), width: btn, height: btn, filterQuality: FilterQuality.medium),
                  ),
                ),
              // "Woof!"
              if (showBubble && active)
                PositionedDirectional(
                  top: 6 * s,
                  end: 6 * s,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('b$bounce'),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) => Transform.scale(scale: v, alignment: Alignment.bottomLeft, child: child),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: w * 0.62),
                      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
                      decoration: asPill(16 * s, color: Colors.white),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(animal.bubble(context),
                            maxLines: 1, style: kidBodyStyle(15 * s, color: KidColors.ink, weight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
              // right / wrong badge
              if (mark != AsMark.none)
                PositionedDirectional(
                  top: -8 * s,
                  start: -8 * s,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) => Transform.scale(scale: v, child: child),
                    child: Container(
                      width: 34 * s,
                      height: 34 * s,
                      decoration: BoxDecoration(
                        color: mark == AsMark.right ? asGreen : asRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
                      ),
                      child: Icon(mark == AsMark.right ? Icons.check_rounded : Icons.close_rounded,
                          color: Colors.white, size: 22 * s),
                    ),
                  ),
                ),
            ]);
          }),
        ),
      ),
    );
  }
}

/// Rounded top; with [wave] the bottom curves up towards the speaker button.
class _AsWaveClip extends CustomClipper<Path> {
  final double radius;
  final bool wave;
  const _AsWaveClip({required this.radius, required this.wave});

  @override
  Path getClip(Size z) {
    final w = z.width, h = z.height, r = radius;
    final p = Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r);
    if (!wave) {
      p
        ..lineTo(w, h - r)
        ..quadraticBezierTo(w, h, w - r, h)
        ..lineTo(r, h)
        ..quadraticBezierTo(0, h, 0, h - r)
        ..close();
      return p;
    }
    p
      ..lineTo(w, h * 0.74)
      ..cubicTo(w * 0.86, h * 0.72, w * 0.80, h, w * 0.60, h)
      ..lineTo(0, h)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(covariant _AsWaveClip old) => old.radius != radius || old.wave != wave;
}

/// Small floating decoration (music note, sparkle) that bobs and twinkles.
class AsFloaty extends StatelessWidget {
  final String asset;
  final double size;
  final Animation<double> idle;
  final double phase;
  const AsFloaty({super.key, required this.asset, required this.size, required this.idle, this.phase = 0});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: idle,
          builder: (_, c) {
            final t = (idle.value + phase) * 2 * pi;
            return Transform.translate(
              offset: Offset(0, sin(t) * size * 0.12),
              child: Transform.rotate(angle: sin(t * 0.5) * 0.12, child: Opacity(opacity: 0.75 + 0.25 * sin(t * 2).abs(), child: c)),
            );
          },
          child: Image.asset(asset, width: size, height: size, fit: BoxFit.contain),
        ),
      );
}
