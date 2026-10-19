import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';

import 'piano_forte_data.dart';

// ── art ───────────────────────────────────────────────────────────────────
const String pfImgBack = '${pfDir}pf_back.webp';
const String pfImgGear = '${pfDir}pf_gear.webp';
const String pfImgSign = '${pfDir}pf_sign.webp';
const String pfImgRobot = '${pfDir}pf_robot.webp';
const String pfImgRobotPoint = '${pfDir}pf_robot_point.webp';
const String pfImgRobotBody = '${pfDir}pf_robot_body.webp';
const String pfImgArmBaton = '${pfDir}pf_robot_arm_baton.webp';
const String pfImgArmFist = '${pfDir}pf_robot_arm_fist.webp';
const String pfImgFaceHappy = '${pfDir}pf_face_happy.webp';
const String pfImgFaceLaugh = '${pfDir}pf_face_laugh.webp';
const String pfImgFaceWow = '${pfDir}pf_face_wow.webp';
const String pfImgStage = '${pfDir}pf_stage.webp';
const String pfImgArc = '${pfDir}pf_arc.webp';
const String pfImgBubble = '${pfDir}pf_bubble.webp';
const String pfImgSpeaker = '${pfDir}pf_speaker.webp';
const String pfImgPause = '${pfDir}pf_pause.webp';
const String pfImgRestart = '${pfDir}pf_restart.webp';
const String pfImgTurtle = '${pfDir}pf_turtle.webp';
const String pfImgHand = '${pfDir}pf_hand.webp';
const String pfImgRipple = '${pfDir}pf_ripple.webp';
const String pfImgCheck = '${pfDir}pf_check.webp';
const String pfImgClose = '${pfDir}pf_close.webp';
const String pfImgBook = '${pfDir}pf_book.webp';
const String pfImgFolder = '${pfDir}pf_folder.webp';
const String pfImgStar = '${pfDir}pf_star.webp';
const String pfImgLeaf = '${pfDir}pf_leaf.webp';
const String pfImgRibbon = '${pfDir}pf_ribbon.webp';
const String pfImgRec = '${pfDir}pf_rec.webp';
const String pfImgPlay = '${pfDir}pf_play.webp';
const String pfImgRestartIcon = '${pfDir}pf_restart_icon.webp';
const String pfImgSparkleGold = '${pfDir}pf_sparkle_gold.webp';
const String pfImgSparkleBlue = '${pfDir}pf_sparkle_blue.webp';
const String pfImgClef = '${pfDir}pf_clef.webp';
const List<String> pfImgNotes = [
  '${pfDir}pf_note_yellow.webp',
  '${pfDir}pf_note_cyan.webp',
  '${pfDir}pf_note_pink.webp',
  '${pfDir}pf_note_purple.webp',
  '${pfDir}pf_note_green.webp',
];
const String pfImgBg = '${pfDir}it_page_bg.webp';

const Color pfInk = Color(0xFF2D0B57);
const Color pfPurple = Color(0xFF6B2FD6);
const Color pfPurpleDeep = Color(0xFF4A1BA8);
const Color pfCream = Color(0xFFFFF5E1);
const Color pfGold = Color(0xFFE9B44C);
const Color pfCyan = Color(0xFF2FE3F0);
const Color pfGreen = Color(0xFF3CC85A);
const Color pfOrange = Color(0xFFFF8A1A);

/// Cream panel with a golden rim (cards, pills, sheets).
BoxDecoration pfPanel(double r, {Color color = pfCream, double rim = 2.5, double shadow = 0.2}) => BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: pfGold, width: rim),
      boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(shadow), blurRadius: 14, offset: const Offset(0, 5))],
    );

TextStyle pfTitle(double size, {Color color = pfInk}) =>
    TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: size, height: 1.05, color: color);

TextStyle pfBody(double size, {Color color = pfInk, FontWeight weight = FontWeight.w600}) =>
    TextStyle(fontFamily: 'Fredoka', fontWeight: weight, fontSize: size, height: 1.15, color: color);

// ── sound ─────────────────────────────────────────────────────────────────

/// One preloaded player per key → a tap sounds instantly; the same key can be
/// re-struck, different keys overlap like a real piano.
class PfSoundBank {
  final List<AudioPlayer> _players = List.generate(pfKeyCount, (_) => AudioPlayer());
  PfInstrument? _loaded;
  double _volume = 0.8;

  Future<void> load(PfInstrument instrument) async {
    if (_loaded == instrument) return;
    _loaded = instrument;
    await Future.wait([
      for (int k = 0; k < pfKeyCount; k++)
        () async {
          try {
            await _players[k].setAsset(pfNoteAsset(instrument, k));
            await _players[k].setVolume(_volume);
          } catch (_) {}
        }(),
    ]);
  }

  Future<void> setVolume(double v) async {
    _volume = v;
    for (final p in _players) {
      try {
        await p.setVolume(v);
      } catch (_) {}
    }
  }

  Future<void> play(int key) async {
    if (key < 0 || key >= pfKeyCount) return;
    final p = _players[key];
    try {
      await p.seek(Duration.zero);
      p.play();
    } catch (_) {}
  }

  Future<void> stopAll() async {
    for (final p in _players) {
      try {
        await p.pause();
      } catch (_) {}
    }
  }

  void dispose() {
    for (final p in _players) {
      p.dispose();
    }
  }
}

// ── small pieces ──────────────────────────────────────────────────────────

/// Sprite button that squashes when pressed.
class PfSpriteButton extends StatelessWidget {
  final String asset;
  final double size;
  final VoidCallback? onTap;
  final String? label;
  final bool glow;
  final bool flipForRtl;
  const PfSpriteButton(
      {super.key, required this.asset, required this.size, this.onTap, this.label, this.glow = false, this.flipForRtl = false});

  @override
  Widget build(BuildContext context) {
    final rtl = flipForRtl && Directionality.of(context) == TextDirection.rtl;
    Widget img = Image.asset(asset, width: size, height: size, fit: BoxFit.contain, filterQuality: FilterQuality.medium);
    if (rtl) img = Transform.flip(flipX: true, child: img);
    return KidPressable(
      onTap: onTap,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: pfCyan.withOpacity(glow ? 0.75 : 0), blurRadius: size * 0.35, spreadRadius: 1)],
        ),
        child: img,
      ),
    );
  }
}

/// Orange round button drawn in code (used for "play" next to the pause sprite).
class PfOrangeIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback? onTap;
  final String? label;
  const PfOrangeIcon({super.key, required this.icon, required this.size, this.onTap, this.label});

  @override
  Widget build(BuildContext context) => KidPressable(
        onTap: onTap,
        semanticLabel: label,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
                center: Alignment(-0.3, -0.4), colors: [Color(0xFFFFB347), Color(0xFFFF7A00), Color(0xFFE85D00)]),
            border: Border.all(color: const Color(0xFFFFD36B), width: size * 0.07),
            boxShadow: [
              BoxShadow(color: const Color(0xFFB54800).withOpacity(0.5), offset: Offset(0, size * 0.05), blurRadius: size * 0.08),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: size * 0.55),
        ),
      );
}

/// The hanging wooden-gold sign: "Piano Forte · par MoorTaalim".
class PfSign extends StatelessWidget {
  final double width;
  final String title, subtitle;
  const PfSign({super.key, required this.width, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final h = width * 188 / 545;
    return SizedBox(
      width: width,
      height: h,
      child: Stack(fit: StackFit.expand, children: [
        Image.asset(pfImgSign, fit: BoxFit.fill),
        Padding(
          padding: EdgeInsets.fromLTRB(width * 0.13, h * 0.33, width * 0.13, h * 0.1),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(title, maxLines: 1, style: pfTitle(width * 0.13, color: const Color(0xFF3A0E7A))),
              ),
            ),
            Flexible(
              flex: 1,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(subtitle, maxLines: 1, style: pfBody(width * 0.055, color: const Color(0xFF3A0E7A), weight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Two-way cream toggle with a glossy purple pill (Apprendre / Jeu libre).
class PfModeToggle extends StatelessWidget {
  final double s;
  final int index;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onTap;
  const PfModeToggle(
      {super.key, required this.s, required this.index, required this.labels, required this.icons, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50 * s,
      padding: EdgeInsets.all(4 * s),
      decoration: pfPanel(30 * s),
      child: LayoutBuilder(builder: (context, c) {
        final half = c.maxWidth / 2;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final left = rtl ? (index == 0 ? half : 0.0) : (index == 0 ? 0.0 : half);
        return Stack(children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            left: left,
            top: 0,
            bottom: 0,
            width: half,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26 * s),
                gradient: const LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8B5CF6), Color(0xFF5B21D6)]),
                boxShadow: [BoxShadow(color: pfPurple.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
              ),
            ),
          ),
          Row(children: [
            for (int i = 0; i < 2; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(icons[i], size: 24 * s, color: i == index ? Colors.white : pfPurpleDeep),
                        SizedBox(width: 8 * s),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: pfBody(17 * s, color: i == index ? Colors.white : pfInk, weight: FontWeight.w700),
                          child: Text(labels[i]),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ]);
      }),
    );
  }
}

/// Green progress bar on a beige track.
class PfBar extends StatelessWidget {
  final double value, height;
  const PfBar({super.key, required this.value, required this.height});

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE6D8BE),
          borderRadius: BorderRadius.circular(height),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              widthFactor: value.clamp(0.0, 1.0),
              heightFactor: 1,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8BEA74), Color(0xFF2FB344)]),
                ),
              ),
            ),
          ),
        ),
      );
}

enum PfChipState { done, current, todo }

/// One note of the song: green + check when played, glowing cyan for the
/// next one, cream for later notes.
class PfNoteChip extends StatelessWidget {
  final double size;
  final int keyIndex;
  final String name;
  final PfChipState state;
  const PfNoteChip({super.key, required this.size, required this.keyIndex, required this.name, required this.state});

  @override
  Widget build(BuildContext context) {
    final color = pfColorOf(keyIndex);
    final (bg, rim, glow) = switch (state) {
      PfChipState.done => (const Color(0xFFD8F7C8), const Color(0xFF8EDC74), 0.0),
      PfChipState.current => (const Color(0xFFBFF6FF), pfCyan, 0.8),
      PfChipState.todo => (const Color(0xFFFFF4E0), const Color(0xFFF0DDBA), 0.0),
    };
    final noteColor = state == PfChipState.done ? const Color(0xFF22A33A) : color;
    return SizedBox(
      width: size,
      height: size * 1.12,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(size * 0.22),
              border: Border.all(color: rim, width: size * 0.045),
              boxShadow: [
                BoxShadow(color: pfCyan.withOpacity(glow), blurRadius: size * 0.3, spreadRadius: 1),
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.music_note_rounded, color: noteColor, size: size * 0.52),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(name, style: pfBody(size * 0.24, color: state == PfChipState.done ? const Color(0xFF1E7A2E) : pfInk, weight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
        if (state == PfChipState.done)
          Positioned(
            top: -size * 0.14,
            right: -size * 0.12,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.elasticOut,
              builder: (_, v, c) => Transform.scale(scale: v, child: c),
              child: Image.asset(pfImgCheck, width: size * 0.36, height: size * 0.36),
            ),
          ),
      ]),
    );
  }
}

/// Cream pill with a purple slider and speaker icon.
class PfVolumePill extends StatelessWidget {
  final double s;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  const PfVolumePill({super.key, required this.s, required this.value, required this.onChanged, this.onChangeEnd});

  @override
  Widget build(BuildContext context) => Container(
        height: 54 * s,
        padding: EdgeInsetsDirectional.fromSTEB(14 * s, 0, 6 * s, 0),
        decoration: pfPanel(30 * s),
        child: Row(children: [
          Icon(value <= 0.01 ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: pfPurpleDeep, size: 28 * s),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 9 * s,
                activeTrackColor: pfPurple,
                inactiveTrackColor: const Color(0xFFE6D8BE),
                thumbColor: const Color(0xFFFFB21A),
                overlayColor: const Color(0x33FFB21A),
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12 * s, elevation: 3),
                trackShape: const RoundedRectSliderTrackShape(),
              ),
              child: Slider(value: value.clamp(0.0, 1.0), onChanged: onChanged, onChangeEnd: onChangeEnd),
            ),
          ),
        ]),
      );
}

/// Cream pill with an icon and a label (Changer de chanson, Mes mélodies…).
class PfPillButton extends StatelessWidget {
  final double s;
  final double height;
  final Widget icon;
  final String label;
  final bool chevron;
  final bool enabled;
  final bool active;
  final VoidCallback? onTap;
  const PfPillButton({
    super.key,
    required this.s,
    required this.icon,
    required this.label,
    this.height = 54,
    this.chevron = false,
    this.enabled = true,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return KidPressable(
      onTap: enabled ? onTap : null,
      pressedScale: enabled ? 0.95 : 1,
      semanticLabel: label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : 0.55,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: height * s,
          padding: EdgeInsets.symmetric(horizontal: 12 * s),
          decoration: pfPanel(30 * s, color: !enabled ? const Color(0xFFE4E1EA) : active ? const Color(0xFFFFE3E0) : pfCream).copyWith(
            boxShadow: [
              BoxShadow(color: (active ? Colors.red : KidColors.purpleDeep).withOpacity(active ? 0.35 : 0.18), blurRadius: active ? 16 : 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            icon,
            SizedBox(width: 8 * s),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, maxLines: 1, style: pfBody(16 * s, weight: FontWeight.w700, color: enabled ? pfInk : const Color(0xFF8E8A99))),
              ),
            ),
            if (chevron) ...[
              SizedBox(width: 4 * s),
              Icon(rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: pfPurpleDeep, size: 26 * s),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Footer ribbon: ★ text ★
class PfFooter extends StatelessWidget {
  final double s;
  final String text;
  const PfFooter({super.key, required this.s, required this.text});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          height: 38 * s,
          padding: EdgeInsets.symmetric(horizontal: 14 * s),
          decoration: pfPanel(22 * s),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Image.asset(pfImgStar, width: 20 * s, height: 20 * s),
            SizedBox(width: 8 * s),
            Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1, style: pfTitle(17 * s)))),
            SizedBox(width: 8 * s),
            Image.asset(pfImgStar, width: 20 * s, height: 20 * s),
          ]),
        ),
      );
}

// ── robot on its stage ────────────────────────────────────────────────────

enum PfFace { happy, laugh, wow }

/// The conductor robot standing on the glowing stage, with the rainbow staff
/// behind him, a speech bubble and little notes. [beat] bumps when a note is
/// played: he bounces and waves.
class PfStageView extends StatelessWidget {
  final double s;
  final Animation<double> idle;
  final Animation<double> beat;
  final PfFace face;
  final String bubble;
  final int bubbleTick;
  final int beatCount; // alternates the conducting stroke (down / side)
  const PfStageView({
    super.key,
    required this.s,
    required this.idle,
    required this.beat,
    required this.face,
    required this.bubble,
    required this.bubbleTick,
    this.beatCount = 0,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final stageW = min(w * 0.62, 330 * s);
        final stageH = stageW * 216 / 700;
        final robotH = min(h - stageH * 0.45, 200 * s).clamp(40.0, 400.0).toDouble();
        final robotW = robotH * 416 / 455;
        final arcW = min(w * 0.98, 460 * s);
        final arcH = arcW * 299 / 517;
        final bubbleW = min(w * 0.4, 170 * s);
        return Stack(clipBehavior: Clip.none, children: [
          // rainbow staff with notes
          Positioned(
            left: (w - arcW) / 2,
            bottom: stageH * 0.3,
            width: arcW,
            height: min(arcH, h * 0.95),
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: idle,
                builder: (_, ch) => Opacity(opacity: 0.75 + 0.25 * sin(idle.value * 2 * pi), child: ch),
                child: Image.asset(pfImgArc, fit: BoxFit.contain),
              ),
            ),
          ),
          // stage
          Positioned(
            left: (w - stageW) / 2,
            bottom: 0,
            width: stageW,
            height: stageH,
            child: Image.asset(pfImgStage, fit: BoxFit.fill),
          ),
          // robot
          Positioned(
            left: (w - robotW) / 2,
            bottom: stageH * 0.42,
            width: robotW,
            height: robotH,
            child: AnimatedBuilder(
              animation: Listenable.merge([idle, beat]),
              builder: (_, __) {
                // conducting: each note = one quick stroke of the baton that
                // springs back; strokes alternate down / out like a 2-beat pattern
                final v = beat.value;
                final stroke = v <= 0 || v >= 1 ? 0.0 : sin(pi * min(1.0, v * 1.35));
                final down = beatCount.isEven;
                final t = idle.value * 2 * pi;
                final baton = sin(t * 3) * 0.07 + (down ? -0.42 : 0.24) * stroke;
                final fist = sin(t * 3 + 1.2) * 0.05 + (down ? 0.10 : -0.20) * stroke;
                final bob = sin(t * 2) * 3 * s - stroke * 6 * s;
                return Transform.translate(
                  offset: Offset(0, bob),
                  child: Transform.rotate(
                    angle: sin(t) * 0.025 + (down ? 0.02 : -0.02) * stroke,
                    alignment: Alignment.bottomCenter,
                    child: Transform.scale(
                      scale: 1 + stroke * 0.03,
                      alignment: Alignment.bottomCenter,
                      child: _Robot(face: face, baton: baton, fist: fist, sparkle: stroke),
                    ),
                  ),
                );
              },
            ),
          ),
          // speech bubble
          Positioned(
            left: (w + robotW) / 2 - robotW * 0.12,
            top: max(0, h - stageH * 0.42 - robotH - 4 * s),
            width: bubbleW,
            height: bubbleW * 128 / 309 * 1.1,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (ch, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: ch),
              child: Stack(key: ValueKey(bubbleTick), fit: StackFit.expand, children: [
                Image.asset(pfImgBubble, fit: BoxFit.fill),
                Padding(
                  padding: EdgeInsets.fromLTRB(bubbleW * 0.08, 4 * s, bubbleW * 0.06, bubbleW * 0.11),
                  child: Center(
                    child: Text(bubble,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: pfBody(min(15 * s, bubbleW * 0.095), weight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ),
          // floating notes
          for (final p in const [(0.08, 0.15, 0, 0.0), (0.16, 0.5, 2, 0.3), (0.86, 0.62, 3, 0.6), (0.9, 0.2, 1, 0.8)])
            Positioned(
              left: w * p.$1 - 14 * s,
              top: h * p.$2,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: idle,
                  builder: (_, ch) {
                    final t = (idle.value + p.$4) * 2 * pi;
                    return Transform.translate(
                      offset: Offset(0, sin(t) * 6 * s),
                      child: Transform.rotate(angle: sin(t * 0.5) * 0.15, child: ch),
                    );
                  },
                  child: Image.asset(pfImgNotes[p.$3], width: 28 * s, height: 28 * s, fit: BoxFit.contain),
                ),
              ),
            ),
        ]);
      });
}

/// The conductor robot, rigged from three layers (body, baton arm, fist arm)
/// so the arms can move, with the visor swapped for the current expression.
class _Robot extends StatelessWidget {
  final PfFace face;
  final double baton, fist; // arm angles (radians, clockwise)
  final double sparkle; // 0‥1 flash at the baton tip
  const _Robot({required this.face, required this.baton, required this.fist, required this.sparkle});

  // measured on the 416 × 455 art
  static const _w = 416.0, _h = 455.0;
  static const _batonPivot = Offset(124, 268);
  static const _fistPivot = Offset(290, 272);
  static const _batonTip = Offset(62, 112);

  static Alignment _align(Offset p) => Alignment(p.dx / _w * 2 - 1, p.dy / _h * 2 - 1);

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final faceAsset = switch (face) {
          PfFace.happy => pfImgFaceHappy,
          PfFace.laugh => pfImgFaceLaugh,
          PfFace.wow => pfImgFaceWow,
        };
        // where the baton tip ends up after the arm turns
        final d = _batonTip - _batonPivot;
        final tip = Offset(
          _batonPivot.dx + d.dx * cos(baton) - d.dy * sin(baton),
          _batonPivot.dy + d.dx * sin(baton) + d.dy * cos(baton),
        );
        final spark = w * 0.16;
        Widget layer(String asset) => Positioned.fill(child: Image.asset(asset, fit: BoxFit.fill, filterQuality: FilterQuality.medium));
        return Stack(clipBehavior: Clip.none, children: [
          // the fist arm sits behind the body edge, the baton arm in front
          Positioned.fill(
            child: Transform.rotate(angle: fist, alignment: _align(_fistPivot), child: Image.asset(pfImgArmFist, fit: BoxFit.fill)),
          ),
          layer(pfImgRobotBody),
          Positioned(
            left: w * 0.3094,
            top: h * 0.2110,
            width: w * 0.4724,
            height: h * 0.2462,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Image.asset(faceAsset, key: ValueKey(faceAsset), fit: BoxFit.fill),
            ),
          ),
          Positioned.fill(
            child: Transform.rotate(angle: baton, alignment: _align(_batonPivot), child: Image.asset(pfImgArmBaton, fit: BoxFit.fill)),
          ),
          if (sparkle > 0.05)
            Positioned(
              left: tip.dx / _w * w - spark / 2,
              top: tip.dy / _h * h - spark / 2,
              width: spark,
              height: spark,
              child: IgnorePointer(
                child: Opacity(
                  opacity: sparkle.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.6 + sparkle * 0.6,
                    child: Transform.rotate(angle: sparkle * 1.2, child: Image.asset(pfImgSparkleGold, fit: BoxFit.contain)),
                  ),
                ),
              ),
            ),
        ]);
      });
}

// ── keyboard ──────────────────────────────────────────────────────────────

/// Purple-and-gold kids keyboard: 8 white keys (Do → Do aigu) and 5 black
/// keys, drawn to fit any width. Multi-touch; sliding a finger plays the next
/// key. [glow] = the key to play next, [lit] = keys being demonstrated.
class PfKeyboard extends StatefulWidget {
  final double s;
  final List<String> names;
  final bool showNames;
  final int? glow;
  final Set<int> lit;
  final Widget? topBar;
  final double topBarHeight;
  final ValueChanged<int> onKeyDown;
  final int? hintKey; // shows the pointing hand + ripple on this key
  final Animation<double>? idle;
  const PfKeyboard({
    super.key,
    required this.s,
    required this.names,
    required this.showNames,
    required this.onKeyDown,
    this.glow,
    this.lit = const {},
    this.topBar,
    this.topBarHeight = 0,
    this.hintKey,
    this.idle,
  });

  @override
  State<PfKeyboard> createState() => _PfKeyboardState();
}

class _PfKeyboardState extends State<PfKeyboard> {
  final Map<int, int> _byPointer = {}; // pointer → key
  Set<int> get _down => _byPointer.values.toSet();
  Size _keysSize = Size.zero;

  int? _keyAt(Offset p) {
    final w = _keysSize.width, h = _keysSize.height;
    if (w <= 0 || p.dx < 0 || p.dy < 0 || p.dx > w || p.dy > h) return null;
    final ww = w / 8;
    final bw = ww * 0.6, bh = h * 0.6;
    if (p.dy <= bh) {
      for (final k in pfBlackKeys) {
        final cx = (pfBlackAfter(k) + 1) * ww;
        if ((p.dx - cx).abs() <= bw / 2) return k;
      }
    }
    final i = (p.dx / ww).floor().clamp(0, 7);
    return pfWhiteKeys[i];
  }

  void _press(int pointer, int? key) {
    if (key == null) return;
    if (_byPointer[pointer] == key) return;
    setState(() => _byPointer[pointer] = key);
    widget.onKeyDown(key);
  }

  void _release(int pointer) {
    if (_byPointer.remove(pointer) != null) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final rim = 7 * s;
    return Directionality(
      textDirection: TextDirection.ltr, // keys always go low → high left to right
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30 * s),
          gradient: const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE08A), Color(0xFFE0A33A)]),
          boxShadow: [
            BoxShadow(color: KidColors.purpleDeep.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        padding: EdgeInsets.all(3 * s),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(27 * s),
            gradient: const LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8A4BF0), Color(0xFF5420C2), Color(0xFF3E168F)]),
          ),
          padding: EdgeInsets.fromLTRB(rim, rim, rim, rim * 1.3),
          child: Column(children: [
            if (widget.topBar != null) SizedBox(height: widget.topBarHeight, child: widget.topBar),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A0E66),
                  borderRadius: BorderRadius.circular(16 * s),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 6, spreadRadius: -2)],
                ),
                padding: EdgeInsets.fromLTRB(4 * s, 3 * s, 4 * s, 4 * s),
                child: LayoutBuilder(builder: (context, c) {
                  _keysSize = Size(c.maxWidth, c.maxHeight);
                  final w = c.maxWidth, h = c.maxHeight;
                  final ww = w / 8;
                  final bw = ww * 0.6, bh = h * 0.6;
                  return Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (e) => _press(e.pointer, _keyAt(e.localPosition)),
                    onPointerMove: (e) {
                      final k = _keyAt(e.localPosition);
                      if (k == null) {
                        _release(e.pointer);
                      } else {
                        _press(e.pointer, k);
                      }
                    },
                    onPointerUp: (e) => _release(e.pointer),
                    onPointerCancel: (e) => _release(e.pointer),
                    child: Stack(clipBehavior: Clip.none, children: [
                      for (int i = 0; i < 8; i++)
                        Positioned(
                          left: i * ww + 1.5 * s,
                          top: 0,
                          width: ww - 3 * s,
                          height: h,
                          child: _WhiteKey(
                            s: s,
                            color: pfColorOf(pfWhiteKeys[i]),
                            name: widget.names[pfWhiteKeys[i]],
                            showName: widget.showNames,
                            down: _down.contains(pfWhiteKeys[i]),
                            glow: widget.glow == pfWhiteKeys[i],
                            lit: widget.lit.contains(pfWhiteKeys[i]),
                          ),
                        ),
                      for (final k in pfBlackKeys)
                        Positioned(
                          left: (pfBlackAfter(k) + 1) * ww - bw / 2,
                          top: 0,
                          width: bw,
                          height: bh,
                          child: _BlackKey(
                            s: s,
                            name: widget.names[k],
                            showName: widget.showNames && widget.glow == k,
                            down: _down.contains(k),
                            glow: widget.glow == k,
                            lit: widget.lit.contains(k),
                          ),
                        ),
                      if (widget.hintKey != null && widget.idle != null)
                        _HintHand(s: s, center: pfKeyCenter(widget.hintKey!, Size(w, h)), idle: widget.idle!),
                    ]),
                  );
                }),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Centre of a key inside the keys area of [PfKeyboard] (for the hint hand).
Offset pfKeyCenter(int key, Size keysArea) {
  final ww = keysArea.width / 8;
  if (pfIsBlack(key)) return Offset((pfBlackAfter(key) + 1) * ww, keysArea.height * 0.32);
  return Offset((pfWhiteKeys.indexOf(key) + 0.5) * ww, keysArea.height * 0.72);
}

/// "Tap here": a pulsing ripple under a pointing hand.
class _HintHand extends StatelessWidget {
  final double s;
  final Offset center;
  final Animation<double> idle;
  const _HintHand({required this.s, required this.center, required this.idle});

  @override
  Widget build(BuildContext context) {
    final ripple = 46 * s;
    final hand = 62 * s;
    final handH = hand * 205 / 167;
    // a zero-size anchor on the key centre; the art is placed around it
    return Positioned(
      left: center.dx,
      top: center.dy,
      width: 0,
      height: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: idle,
          builder: (_, __) {
            final t = (idle.value * 6) % 1.0; // ~1 s loop
            final press = sin(t * pi);
            return Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: -ripple / 2,
                top: -ripple / 2,
                width: ripple,
                height: ripple,
                child: Transform.scale(
                  scale: 0.7 + t * 0.6,
                  child: Opacity(opacity: (1 - t).clamp(0.0, 1.0), child: Image.asset(pfImgRipple, fit: BoxFit.contain)),
                ),
              ),
              // fingertip (top-right of the art) on the key
              Positioned(
                left: -hand * 0.86,
                top: -handH * 0.03 + press * 5 * s,
                width: hand,
                height: handH,
                child: Image.asset(pfImgHand, fit: BoxFit.contain),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _WhiteKey extends StatelessWidget {
  final double s;
  final Color color;
  final String name;
  final bool showName, down, glow, lit;
  const _WhiteKey({required this.s, required this.color, required this.name, required this.showName, required this.down, required this.glow, required this.lit});

  @override
  Widget build(BuildContext context) {
    final List<Color> face = down
        ? const [Color(0xFFE9E3F4), Color(0xFFD9D0EA)]
        : glow
            ? const [Color(0xFFCFFBFF), Color(0xFF6FE6F5)]
            : lit
                ? const [Color(0xFFFFF6C9), Color(0xFFFFD65A)]
                : const [Color(0xFFFFFFFF), Color(0xFFF3EEE6)];
    final halo = glow ? pfCyan : lit ? const Color(0xFFFFC21A) : Colors.transparent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      transform: Matrix4.translationValues(0, down ? 3 * s : 0, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4 * s), bottom: Radius.circular(12 * s)),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: face),
        border: Border.all(color: glow ? pfCyan : const Color(0xFFD8CFC0), width: glow ? 2.5 * s : 1),
        boxShadow: [
          BoxShadow(color: const Color(0xFFB9AEC9), offset: Offset(0, down ? 1.5 * s : 5 * s)),
          BoxShadow(color: halo.withOpacity(halo == Colors.transparent ? 0 : 0.85), blurRadius: 14 * s, spreadRadius: 1.5 * s),
        ],
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: 12 * s),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (showName)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(name, maxLines: 1, style: pfBody(15 * s, color: const Color(0xFF3A0E7A), weight: FontWeight.w700)),
              ),
            SizedBox(height: 5 * s),
            Container(
              width: 17 * s,
              height: 17 * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 4)],
                border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _BlackKey extends StatelessWidget {
  final double s;
  final String name;
  final bool showName, down, glow, lit;
  const _BlackKey({required this.s, required this.name, required this.showName, required this.down, required this.glow, required this.lit});

  @override
  Widget build(BuildContext context) {
    final halo = glow ? pfCyan : lit ? const Color(0xFFFFC21A) : Colors.transparent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      transform: Matrix4.translationValues(0, down ? 2 * s : 0, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(3 * s), bottom: Radius.circular(8 * s)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: down
              ? const [Color(0xFF3C3550), Color(0xFF241F33)]
              : glow
                  ? const [Color(0xFF1B6F7A), Color(0xFF0C3940)]
                  : lit
                      ? const [Color(0xFF7A5A12), Color(0xFF3A2A05)]
                      : const [Color(0xFF4A4A55), Color(0xFF111116)],
        ),
        border: Border.all(color: glow ? pfCyan : Colors.black, width: glow ? 2 * s : 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), offset: Offset(0, down ? 1 * s : 4 * s), blurRadius: 3 * s),
          BoxShadow(color: halo.withOpacity(halo == Colors.transparent ? 0 : 0.85), blurRadius: 12 * s, spreadRadius: 1 * s),
        ],
      ),
      child: Stack(children: [
        // glossy top
        Positioned(
          left: 3 * s,
          right: 3 * s,
          top: 3 * s,
          height: 12 * s,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3 * s),
              gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withOpacity(0.28), Colors.white.withOpacity(0)]),
            ),
          ),
        ),
        if (showName)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 6 * s),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(name, maxLines: 1, style: pfBody(11 * s, color: Colors.white, weight: FontWeight.w700)),
              ),
            ),
          ),
      ]),
    );
  }
}
