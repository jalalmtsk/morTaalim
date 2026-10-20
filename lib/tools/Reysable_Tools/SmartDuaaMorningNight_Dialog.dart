import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Manager/Services/CardVisibiltyManager.dart';

/// Shows the illustrated duaa of the moment (morning / evening / bedtime).
Future<void> showDuaaDialog(BuildContext context) => showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => const DuaaDialog(),
      transitionBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    );

enum _Period { morning, evening, night }

_Period _periodNow() {
  final h = DateTime.now().hour;
  if (h >= 4 && h < 12) return _Period.morning;
  if (h >= 12 && h < 20) return _Period.evening;
  return _Period.night;
}

class _Look {
  final String scene, medal, robot, listenBtn, mainBtn, lantern, flowers;
  final List<Color> sky; // full-screen tint
  final bool sleepy;
  const _Look(this.scene, this.medal, this.robot, this.listenBtn, this.mainBtn, this.lantern, this.flowers, this.sky, this.sleepy);
}

const String _dir = 'assets/images/UI/Duaa/';
const Map<_Period, _Look> _looks = {
  _Period.morning: _Look('scene_morning', 'medal_morning', 'robot', 'btn_listen_morning', 'btn_main_morning', 'lantern_bush', 'flowers',
      [Color(0x00FFE7B0), Color(0x33FFB86B)], false),
  _Period.evening: _Look('scene_evening', 'medal_evening', 'robot_evening', 'btn_listen_evening', 'btn_main_evening', 'lantern', 'flowers',
      [Color(0x55A04BC8), Color(0x88FF8A5B)], false),
  _Period.night: _Look('scene_night', 'medal_night', 'robot_night', 'btn_listen_night', 'btn_main_night', 'lantern_night',
      'flowers_night', [Color(0xB0120C48), Color(0xCC1B1460)], true),
};

/// The duaa itself (authentic adhkar).
const Map<_Period, String> _arabic = {
  _Period.morning: 'اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ',
  _Period.evening: 'اللَّهُمَّ بِكَ أَمْسَيْنَا وَبِكَ أَصْبَحْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ الْمَصِيرُ',
  _Period.night: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
};

class DuaaDialog extends StatefulWidget {
  const DuaaDialog({Key? key}) : super(key: key);

  @override
  State<DuaaDialog> createState() => _DuaaDialogState();
}

class _DuaaDialogState extends State<DuaaDialog> with TickerProviderStateMixin {
  final _Period _p = _periodNow();
  late final _Look _look = _looks[_p]!;
  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;
  bool _hideNext = false;
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..forward();
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/MarimbaWinA1_SFX.mp3');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final n in [_look.scene, _look.medal, _look.robot]) {
      precacheImage(AssetImage('$_dir$n.webp'), context);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _in.dispose();
    _idle.dispose();
    super.dispose();
  }

  String _t(String key) {
    final code = Localizations.localeOf(context).languageCode;
    final lang = _txt.containsKey(code) ? code : (code == 'zgh' ? 'fr' : 'en');
    return _txt[lang]![key] ?? _txt['en']![key]!;
  }

  String get _k => _p.name;

  Future<void> _listen() async {
    _audio.playEventSound('toggleButton');
    if (_speaking) {
      await _tts.stop();
      setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    final wasMuted = _audio.isBgMuted;
    if (!wasMuted) await _audio.toggleBgMute();
    try {
      await _tts.setLanguage('ar');
      await _tts.setSpeechRate(0.38);
      await _tts.setPitch(1.05);
      await _tts.awaitSpeakCompletion(true);
      await _tts.speak(_arabic[_p]!);
    } catch (_) {}
    if (!wasMuted && _audio.isBgMuted) await _audio.toggleBgMute();
    if (mounted) setState(() => _speaking = false);
  }

  /// Main button: first time per period each day gives a little reward.
  Future<void> _done() async {
    _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/StarSound.mp3');
    try {
      final now = DateTime.now();
      final key = 'duaa_done_${now.year}-${now.month}-${now.day}_${_p.name}';
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(key) ?? false)) {
        await prefs.setBool(key, true);
        if (mounted) Provider.of<ExperienceManager>(context, listen: false).addGold(context, 5);
      }
    } catch (_) {}
    _close();
  }

  void _close() {
    _tts.stop();
    if (_hideNext) context.read<CardVisibilityManager>().toggleDuaaDialog(false);
    if (mounted) Navigator.of(context).pop();
  }

  Animation<double> _seg(double a, double b, [Curve c = Curves.easeOutBack]) =>
      CurvedAnimation(parent: _in, curve: Interval(a, b, curve: c));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width - 36, 430.0);
    final s = w / 380;
    return Material(
      type: MaterialType.transparency,
      child: Stack(children: [
        // dreamy background
        Positioned.fill(
          child: Image.asset('assets/images/UI/Loading/loading_bg_adventure.webp', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _look.sky),
            ),
          ),
        ),
        Positioned.fill(child: IgnorePointer(child: _Twinkles(anim: _idle, night: _p == _Period.night))),
        // corner lantern + flowers
        Positioned(
          left: -10,
          bottom: pad.bottom - 6,
          child: _sway(Image.asset('$_dir${_look.lantern}.webp', height: 150 * s), 0.0, rotate: true),
        ),
        Positioned(
          right: -14,
          bottom: pad.bottom - 10,
          child: _sway(Image.asset('$_dir${_look.flowers}.webp', height: 120 * s), 1.4),
        ),
        // the card
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(top: pad.top + 70 * s, bottom: pad.bottom + 24),
            child: ScaleTransition(
              scale: Tween(begin: 0.85, end: 1.0).animate(_seg(0, 0.45)),
              child: FadeTransition(opacity: _seg(0, 0.3, Curves.easeOut), child: _card(w, s)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sway(Widget child, double phase, {bool rotate = false}) => AnimatedBuilder(
        animation: _idle,
        builder: (_, c) {
          final v = sin(_idle.value * 2 * pi + phase);
          return rotate
              ? Transform.rotate(angle: v * 0.04, alignment: Alignment.topCenter, child: c)
              : Transform.translate(offset: Offset(0, v * 3), child: c);
        },
        child: child,
      );

  Widget _card(double w, double s) {
    final sceneH = w * 0.52;
    final top = 64 * s; // room for the arch + medallion
    return SizedBox(
      width: w,
      child: Stack(clipBehavior: Clip.none, children: [
        // purple ogee arch behind the medallion
        Positioned(
          left: w * 0.2,
          right: w * 0.2,
          top: 0,
          height: top + 30 * s,
          child: CustomPaint(painter: _ArchPainter()),
        ),
        // cream card
        Container(
          margin: EdgeInsets.only(top: top),
          padding: EdgeInsets.fromLTRB(14 * s, 14 * s, 14 * s, 16 * s),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9EC),
            borderRadius: BorderRadius.circular(30 * s),
            border: Border.all(color: const Color(0xFFE8B94A), width: 4),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 26, offset: const Offset(0, 12)),
              BoxShadow(color: const Color(0xFFFFE08A).withOpacity(0.5), blurRadius: 30, spreadRadius: -6),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // scene
            FadeTransition(
              opacity: _seg(0.1, 0.45, Curves.easeOut),
              child: Container(
                height: sceneH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24 * s), bottom: Radius.circular(40 * s)),
                  border: Border.all(color: const Color(0xFFF1D58A), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22 * s), bottom: Radius.circular(38 * s)),
                  child: AnimatedBuilder(
                    animation: _idle,
                    builder: (_, c) => Transform.scale(scale: 1.08 + 0.025 * sin(_idle.value * 2 * pi), child: c),
                    child: Image.asset('$_dir${_look.scene}.webp', fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10 * s),
            // title with gold ornaments
            FadeTransition(
              opacity: _seg(0.3, 0.6, Curves.easeOut),
              child: Row(children: [
                Image.asset('${_dir}orn_left.webp', width: 46 * s),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_t('title_$_k'),
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.w700,
                          fontSize: 30 * s,
                          color: const Color(0xFF3A1478),
                          shadows: [Shadow(color: Colors.white, blurRadius: 4 * s)],
                        )),
                  ),
                ),
                Image.asset('${_dir}orn_right.webp', width: 46 * s),
              ]),
            ),
            Text(_t('sub_$_k'),
                style: TextStyle(fontFamily: 'Fredoka', fontSize: 15 * s, color: const Color(0xFF4A3A78), fontWeight: FontWeight.w500)),
            SizedBox(height: 10 * s),
            // the duaa
            FadeTransition(
              opacity: _seg(0.45, 0.8, Curves.easeOut),
              child: AnimatedBuilder(
                animation: _idle,
                builder: (_, c) => DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: _speaking
                        ? [BoxShadow(color: const Color(0xFFFFD45C).withOpacity(0.35 + 0.25 * sin(_idle.value * 2 * pi * 6).abs()), blurRadius: 24)]
                        : null,
                  ),
                  child: c,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 * s),
                  child: Text(
                    _arabic[_p]!,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: (_p == _Period.night ? 34 : 27) * s,
                      height: 1.75,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF241050),
                    ),
                  ),
                ),
              ),
            ),
            if (_t('mean_$_k').isNotEmpty) ...[
              SizedBox(height: 6 * s),
              FadeTransition(
                opacity: _seg(0.55, 0.85, Curves.easeOut),
                child: Text(_t('mean_$_k'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Fredoka', fontSize: 15 * s, height: 1.35, color: const Color(0xFF2D2450))),
              ),
            ],
            SizedBox(height: 14 * s),
            // buttons
            ScaleTransition(
              scale: _seg(0.65, 0.95),
              child: Column(children: [
                _spriteButton(_look.listenBtn, w * 0.6, _speaking ? _t('stop') : _t('listen'), _listen, textStart: 0.36),
                SizedBox(height: 10 * s),
                AnimatedBuilder(
                  animation: _idle,
                  builder: (_, c) => Transform.scale(scale: 1 + 0.025 * sin(_idle.value * 2 * pi * 2), child: c),
                  child: _spriteButton(_look.mainBtn, w * 0.86, _t('main_$_k'), _done,
                      textStart: _p == _Period.morning ? 0.3 : (_p == _Period.night ? 0.36 : 0.26), big: true),
                ),
                SizedBox(height: 10 * s),
                _pillButton(s),
                SizedBox(height: 6 * s),
                GestureDetector(
                  onTap: () => setState(() => _hideNext = !_hideNext),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_hideNext ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        size: 18 * s, color: const Color(0xFF8A7A9E)),
                    SizedBox(width: 4 * s),
                    Text(_t('dontShow'), style: TextStyle(fontFamily: 'Fredoka', fontSize: 12.5 * s, color: const Color(0xFF8A7A9E))),
                  ]),
                ),
              ]),
            ),
          ]),
        ),
        // medallion on the arch, with slow light rays behind
        Positioned(
          left: 0,
          right: 0,
          top: -18 * s,
          child: Center(
            child: ScaleTransition(
              scale: _seg(0.15, 0.55),
              child: SizedBox(
                width: 118 * s,
                height: 118 * s,
                child: Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                  AnimatedBuilder(
                    animation: _idle,
                    builder: (_, __) => Transform.rotate(
                      angle: _idle.value * 2 * pi / 3,
                      child: CustomPaint(size: Size(170 * s, 170 * s), painter: _RaysPainter(_p == _Period.night)),
                    ),
                  ),
                  Image.asset('$_dir${_look.medal}.webp', width: (_p == _Period.morning ? 150 : 112) * s, fit: BoxFit.contain),
                ]),
              ),
            ),
          ),
        ),
        // robot peeking over the top-left edge
        Positioned(
          left: -18 * s,
          top: top - 66 * s,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.5), end: Offset.zero).animate(_seg(0.4, 0.8)),
            child: AnimatedBuilder(
              animation: _idle,
              builder: (_, c) => Transform.rotate(
                angle: sin(_idle.value * 2 * pi * (_look.sleepy ? 1 : 2)) * (_look.sleepy ? 0.05 : 0.03),
                alignment: Alignment.bottomCenter,
                child: c,
              ),
              child: Image.asset('$_dir${_look.robot}.webp', width: 112 * s),
            ),
          ),
        ),
        if (_look.sleepy) ..._zzz(s, top),
        // birds on the top-right edge
        Positioned(
          right: -6 * s,
          top: top - (_look.sleepy ? 50 : 62) * s,
          child: AnimatedBuilder(
            animation: _idle,
            builder: (_, c) => Transform.translate(
              offset: Offset(0, _look.sleepy ? 0 : -sin(_idle.value * 2 * pi * 3).abs() * 5 * s),
              child: c,
            ),
            child: _look.sleepy
                ? Image.asset('${_dir}birds_branch.webp', width: 118 * s)
                : Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Image.asset('${_dir}bird_blue.webp', width: 62 * s),
                    Image.asset('${_dir}bird_small.webp', width: 40 * s),
                  ]),
          ),
        ),
        // close
        Positioned(
          right: 10 * s,
          top: top + 12 * s,
          child: GestureDetector(
            onTap: () {
              _audio.playEventSound('cancelButton');
              _close();
            },
            child: Image.asset('${_dir}close.webp', width: 40 * s),
          ),
        ),
      ]),
    );
  }

  List<Widget> _zzz(double s, double top) => [
        for (var i = 0; i < 3; i++)
          Positioned(
            left: 70 * s + i * 8 * s,
            top: top - 70 * s - i * 14 * s,
            child: AnimatedBuilder(
              animation: _idle,
              builder: (_, __) {
                final k = ((_idle.value * 3) + i / 3) % 1.0;
                return Opacity(
                  opacity: (1 - k).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(k * 10 * s, -k * 26 * s),
                    child: Text('z',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.w700,
                          fontSize: (14 + k * 10) * s,
                          color: Colors.white,
                          shadows: const [Shadow(color: Color(0xFF3A1478), blurRadius: 6)],
                        )),
                  ),
                );
              },
            ),
          ),
      ];

  /// Button sprite (icon baked on the left) with live, translated text.
  Widget _spriteButton(String sprite, double width, String label, VoidCallback onTap, {double textStart = 0.34, bool big = false}) {
    final sizes = _sizes[sprite]!;
    final h = width * sizes[1] / sizes[0];
    return _Press(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: h,
        child: Stack(children: [
          Positioned.fill(child: Image.asset('$_dir$sprite.webp', fit: BoxFit.fill)),
          Positioned(
            left: width * textStart,
            right: width * 0.07,
            top: 0,
            bottom: h * 0.08,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w700,
                      fontSize: h * (big ? 0.36 : 0.38),
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black.withOpacity(0.25), blurRadius: 3, offset: const Offset(0, 1.5))],
                    )),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _pillButton(double s) => _Press(
        onTap: () {
          _audio.playEventSound('cancelButton');
          _close();
        },
        child: SizedBox(
          width: 150 * s,
          height: 150 * s * 86 / 263,
          child: Stack(alignment: Alignment.center, children: [
            Positioned.fill(child: Image.asset('${_dir}pill.webp', fit: BoxFit.fill)),
            Text(_t('close'), style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: 17 * s, color: const Color(0xFF6B3A12))),
          ]),
        ),
      );
}

const Map<String, List<int>> _sizes = {
  'btn_listen_morning': [450, 110],
  'btn_main_morning': [484, 111],
  'btn_listen_evening': [333, 104],
  'btn_main_evening': [319, 112],
  'btn_listen_night': [516, 110],
  'btn_main_night': [596, 126],
};

class _Press extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Press({required this.child, required this.onTap});

  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          widget.onTap();
        },
        child: AnimatedScale(scale: _down ? 0.93 : 1, duration: const Duration(milliseconds: 110), child: widget.child),
      );
}

/// Purple Moroccan arch with a gold rim (behind the medallion).
class _ArchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.62)
      ..quadraticBezierTo(w * 0.04, h * 0.42, w * 0.2, h * 0.42)
      ..quadraticBezierTo(w * 0.3, h * 0.42, w * 0.34, h * 0.26)
      ..quadraticBezierTo(w * 0.42, h * 0.1, w * 0.5, 0)
      ..quadraticBezierTo(w * 0.58, h * 0.1, w * 0.66, h * 0.26)
      ..quadraticBezierTo(w * 0.7, h * 0.42, w * 0.8, h * 0.42)
      ..quadraticBezierTo(w * 0.96, h * 0.42, w, h * 0.62)
      ..lineTo(w, h)
      ..close();
    canvas.drawShadow(p, Colors.black, 6, false);
    canvas.drawPath(
      p,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7B3FC8), Color(0xFF4A1E8C)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = const Color(0xFFE8B94A),
    );
  }

  @override
  bool shouldRepaint(_ArchPainter o) => false;
}

/// Soft light rays turning behind the medallion.
class _RaysPainter extends CustomPainter {
  final bool night;
  _RaysPainter(this.night);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final paint = Paint()
      ..shader = RadialGradient(colors: [
        (night ? const Color(0xFFBFD4FF) : const Color(0xFFFFE9A0)).withOpacity(0.55),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: c, radius: r));
    for (var i = 0; i < 12; i++) {
      final a = i * pi / 6;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + cos(a - 0.09) * r, c.dy + sin(a - 0.09) * r)
        ..lineTo(c.dx + cos(a + 0.09) * r, c.dy + sin(a + 0.09) * r)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter o) => false;
}

/// Twinkling stars / sparkles over the background.
class _Twinkles extends StatelessWidget {
  final Animation<double> anim;
  final bool night;
  const _Twinkles({required this.anim, required this.night});

  static final List<List<double>> _pts = () {
    final r = Random(5);
    return [for (var i = 0; i < 24; i++) [r.nextDouble(), r.nextDouble() * 0.85, r.nextDouble(), 1.5 + r.nextDouble() * 3]];
  }();

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: anim,
        builder: (_, __) => CustomPaint(painter: _TwinklePainter(anim.value, night)),
      );
}

class _TwinklePainter extends CustomPainter {
  final double t;
  final bool night;
  _TwinklePainter(this.t, this.night);

  @override
  void paint(Canvas canvas, Size size) {
    final col = night ? Colors.white : const Color(0xFFFFF2B8);
    for (final p in _Twinkles._pts) {
      final a = (sin((t + p[2]) * 2 * pi * 3) + 1) / 2;
      if (a < 0.2) continue;
      final c = Offset(p[0] * size.width, p[1] * size.height);
      final r = p[3] * (0.6 + 0.7 * a);
      final paint = Paint()..color = col.withOpacity(0.9 * a);
      final path = Path()
        ..moveTo(c.dx, c.dy - r * 2)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r * 2, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r * 2)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r * 2, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r * 2);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_TwinklePainter o) => o.t != t;
}

const Map<String, Map<String, String>> _txt = {
  'en': {
    'title_morning': 'Morning duaa',
    'sub_morning': 'A beautiful start to the day',
    'mean_morning': 'O Allah, by You we enter the morning and the evening, by You we live and die, and to You is the resurrection.',
    'main_morning': 'Start my day',
    'title_evening': 'Evening duaa',
    'sub_evening': 'A calm moment',
    'mean_evening': 'O Allah, by You we enter the evening and the morning, by You we live and die, and to You is the return.',
    'main_evening': 'Continue my evening',
    'title_night': 'Duaa before sleep',
    'sub_night': 'A peaceful night',
    'mean_night': 'In Your name, O Allah, I die and I live.',
    'main_night': 'Good night',
    'listen': 'Listen',
    'stop': 'Stop',
    'close': 'Close',
    'dontShow': "Don't show again",
  },
  'fr': {
    'title_morning': 'Douaa du matin',
    'sub_morning': 'Un beau début de journée',
    'mean_morning': 'Ô Allah, c\'est par Toi que nous entrons dans le matin et le soir, que nous vivons et mourons. Vers Toi sera la résurrection.',
    'main_morning': 'Commencer ma journée',
    'title_evening': 'Douaa du soir',
    'sub_evening': 'Un moment de calme',
    'mean_evening': 'Ô Allah, c\'est par Toi que nous entrons dans le soir et le matin, que nous vivons et mourons. Vers Toi est le retour.',
    'main_evening': 'Continuer ma soirée',
    'title_night': 'Douaa avant de dormir',
    'sub_night': 'Une nuit paisible',
    'mean_night': 'En Ton nom, ô Allah, je meurs et je vis.',
    'main_night': 'Bonne nuit',
    'listen': 'Écouter',
    'stop': 'Arrêter',
    'close': 'Fermer',
    'dontShow': 'Ne plus afficher',
  },
  'ar': {
    'title_morning': 'دعاء الصباح',
    'sub_morning': 'بداية جميلة ليومك',
    'mean_morning': '',
    'main_morning': 'أبدأ يومي',
    'title_evening': 'دعاء المساء',
    'sub_evening': 'لحظة هدوء',
    'mean_evening': '',
    'main_evening': 'أكمل مسائي',
    'title_night': 'دعاء النوم',
    'sub_night': 'ليلة هادئة',
    'mean_night': '',
    'main_night': 'تصبح على خير',
    'listen': 'استمع',
    'stop': 'إيقاف',
    'close': 'إغلاق',
    'dontShow': 'لا تُظهر مرة أخرى',
  },
  'de': {
    'title_morning': 'Morgen-Dua',
    'sub_morning': 'Ein schöner Start in den Tag',
    'mean_morning': 'O Allah, durch Dich beginnen wir den Morgen und den Abend, durch Dich leben und sterben wir, und zu Dir ist die Auferstehung.',
    'main_morning': 'Meinen Tag beginnen',
    'title_evening': 'Abend-Dua',
    'sub_evening': 'Ein ruhiger Moment',
    'mean_evening': 'O Allah, durch Dich beginnen wir den Abend und den Morgen, durch Dich leben und sterben wir, und zu Dir ist die Rückkehr.',
    'main_evening': 'Weiter in den Abend',
    'title_night': 'Dua vor dem Schlafen',
    'sub_night': 'Eine friedliche Nacht',
    'mean_night': 'In Deinem Namen, o Allah, sterbe ich und lebe ich.',
    'main_night': 'Gute Nacht',
    'listen': 'Anhören',
    'stop': 'Stopp',
    'close': 'Schließen',
    'dontShow': 'Nicht mehr anzeigen',
  },
};
