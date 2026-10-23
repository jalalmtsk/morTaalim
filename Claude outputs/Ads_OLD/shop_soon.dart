import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';

/// "The shop is getting ready" — shown while the shop is closed.
/// A little striped-awning shop, a swinging "Bientôt" sign, floating
/// coins / gems / stars and the robot waving. Tap anything for a bounce.
class ShopSoonPage extends StatefulWidget {
  final bool embedded;
  const ShopSoonPage({super.key, this.embedded = false});
  @override
  State<ShopSoonPage> createState() => _ShopSoonPageState();
}

class _ShopSoonPageState extends State<ShopSoonPage> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  late final AnimationController _tap = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  static const _ink = Color(0xFF3F1A9B);

  @override
  void dispose() {
    _loop.dispose();
    _in.dispose();
    _tap.dispose();
    super.dispose();
  }

  Map<String, String> _txt(BuildContext c) {
    switch (Localizations.localeOf(c).languageCode) {
      case 'ar':
        return {
          'title': 'المتجر يتحضّر!',
          'sign': 'قريبًا',
          'body': 'نحن نرتّب الرفوف ونجهّز مفاجآت رائعة لك.',
          'tip': 'واصل اللعب واجمع النجوم والجواهر… ستحتاجها قريبًا!',
          'btn': 'حسنًا، سأعود!',
        };
      case 'en':
        return {
          'title': 'The shop is getting ready!',
          'sign': 'Soon',
          'body': 'We are filling the shelves with lovely surprises for you.',
          'tip': 'Keep playing and collect gold and gems… you\'ll need them soon!',
          'btn': 'Okay, I\'ll be back!',
        };
      default:
        return {
          'title': 'La boutique se prépare !',
          'sign': 'Bientôt',
          'body': 'On range les étagères et on prépare de jolies surprises pour toi.',
          'tip': 'Continue à jouer et garde tes pièces et tes gemmes… tu en auras besoin bientôt !',
          'btn': 'D\'accord, je reviens !',
        };
    }
  }

  void _boing() {
    try {
      Provider.of<AudioManager>(context, listen: false).playEventSound('PopButton');
    } catch (_) {}
    _tap.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final t = _txt(context);
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final shopW = min(w * 0.82, 360.0);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4DE),
      body: Stack(children: [
        // soft sky gradient + light blobs
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFBFE9FF), Color(0xFFFFF1D6), Color(0xFFFFE0B8)],
                stops: [0, 0.55, 1],
              ),
            ),
          ),
        ),
        Positioned.fill(child: AnimatedBuilder(animation: _loop, builder: (_, __) => CustomPaint(painter: _SkyPainter(_loop.value)))),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(children: [
                if (!widget.embedded) ...[
                  _round(Icons.arrow_back_rounded, () => Navigator.pop(context)),
                  const SizedBox(width: 8),
                ],
                const Expanded(child: Userstatutbar()),
              ]),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, bc) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: bc.maxHeight),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const SizedBox(height: 8),
                      // title
                      _pop(0.0, Text(
                        t['title']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: min(30, w * 0.075),
                          fontWeight: FontWeight.w900,
                          color: _ink,
                          shadows: const [Shadow(color: Colors.white, blurRadius: 0, offset: Offset(0, 3))],
                        ),
                      )),
                      const SizedBox(height: 14),
                      // the little shop
                      GestureDetector(onTap: _boing, child: _shop(shopW, t['sign']!)),
                      const SizedBox(height: 18),
                      _pop(0.35, _card(w, t)),
                      const SizedBox(height: 18),
                      _pop(0.55, _button(w, t['btn']!)),
                      const SizedBox(height: 20),
                    ]),
                  ),
                );
              }),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _pop(double delay, Widget child) => AnimatedBuilder(
        animation: _in,
        builder: (_, c) {
          final v = ((_in.value - delay) / (1 - delay)).clamp(0.0, 1.0);
          final e = Curves.elasticOut.transform(v);
          return Opacity(opacity: v.clamp(0.0, 1.0), child: Transform.scale(scale: 0.6 + 0.4 * e, child: c));
        },
        child: child,
      );

  Widget _round(IconData i, VoidCallback onTap) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Padding(padding: const EdgeInsets.all(10), child: Icon(i, color: const Color(0xFFFF6F3C)))),
      );

  /// The shop front: striped awning, closed window with goodies, swinging sign.
  Widget _shop(double sw, String sign) {
    final sh = sw * 0.95;
    return AnimatedBuilder(
      animation: Listenable.merge([_loop, _in, _tap]),
      builder: (_, __) {
        final t = _loop.value;
        final drop = Curves.bounceOut.transform(_in.value.clamp(0.0, 1.0));
        final tp = _tap.value;
        final squash = 1 + sin(tp * pi * 3) * 0.05 * (1 - tp);
        return Transform.translate(
          offset: Offset(0, (1 - drop) * -120),
          child: Transform.scale(
            scaleY: squash,
            scaleX: 2 - squash,
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: sw,
              height: sh,
              child: Stack(clipBehavior: Clip.none, children: [
                // building
                Positioned(
                  left: sw * 0.06,
                  right: sw * 0.06,
                  top: sh * 0.18,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8EC),
                      borderRadius: BorderRadius.circular(sw * 0.06),
                      border: Border.all(color: const Color(0xFFF1C27D), width: 4),
                      boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 8))],
                    ),
                  ),
                ),
                // window with goodies behind a sleepy curtain
                Positioned(
                  left: sw * 0.16,
                  right: sw * 0.16,
                  top: sh * 0.36,
                  height: sh * 0.36,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(sw * 0.05),
                    child: Stack(children: [
                      Positioned.fill(child: Container(color: const Color(0xFFD9F1FF))),
                      // shelf goodies bobbing
                      for (var i = 0; i < 4; i++)
                        Positioned(
                          left: sw * (0.04 + i * 0.16),
                          bottom: sh * 0.04 + sin((t + i * 0.25) * 2 * pi) * 3,
                          child: Icon(const [Icons.toys_rounded, Icons.diamond_rounded, Icons.emoji_events_rounded, Icons.palette_rounded][i],
                              size: sw * 0.11, color: const [Color(0xFFFF8A3D), Color(0xFF7B3FE4), Color(0xFFFFC21A), Color(0xFF14B3C7)][i]),
                        ),
                      Positioned(left: 0, right: 0, bottom: sh * 0.025, child: Container(height: 5, color: const Color(0xFFC98B4E))),
                      // curtain half-closed, swaying
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: sh * (0.15 + 0.015 * sin(t * 2 * pi)),
                        child: CustomPaint(painter: _CurtainPainter()),
                      ),
                    ]),
                  ),
                ),
                // door
                Positioned(
                  left: sw * 0.42,
                  right: sw * 0.42,
                  bottom: 0,
                  height: sh * 0.2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFC98B4E),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(sw * 0.08)),
                      border: Border.all(color: const Color(0xFF8A5229), width: 3),
                    ),
                    child: const Align(alignment: Alignment(0.6, 0.1), child: CircleAvatar(radius: 3.5, backgroundColor: Color(0xFFFFD54A))),
                  ),
                ),
                // awning
                Positioned(left: 0, right: 0, top: sh * 0.1, height: sh * 0.2, child: CustomPaint(painter: _AwningPainter(t))),
                // roof sign
                Positioned(
                  left: sw * 0.22,
                  right: sw * 0.22,
                  top: -sh * 0.02,
                  height: sh * 0.13,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF9B62F2), Color(0xFF6A2BC2)]),
                      borderRadius: BorderRadius.circular(sh * 0.07),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: const Color(0xFF6A2BC2).withOpacity(0.4), blurRadius: 10)],
                    ),
                    child: const FittedBox(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.storefront_rounded, color: Colors.white),
                          SizedBox(width: 6),
                          Icon(Icons.auto_awesome, color: Color(0xFFFFD54A)),
                        ]),
                      ),
                    ),
                  ),
                ),
                // swinging "Bientôt" sign on the door
                Positioned(
                  left: sw * 0.3,
                  right: sw * 0.3,
                  top: sh * 0.62,
                  child: Transform.rotate(
                    alignment: Alignment.topCenter,
                    angle: sin(t * 2 * pi * 2) * 0.09 + sin(tp * pi * 4) * 0.25 * (1 - tp),
                    child: Column(children: [
                      SizedBox(width: sw * 0.18, height: 12, child: CustomPaint(painter: _StringPainter())),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6F3C),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
                        ),
                        child: FittedBox(child: Text(sign, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))),
                      ),
                    ]),
                  ),
                ),
                // robot waving at the side
                Positioned(
                  right: -sw * 0.08,
                  bottom: -6 + sin(t * 2 * pi * 2).abs() * 6,
                  child: Transform.rotate(
                    angle: sin(t * 2 * pi * 2) * 0.05,
                    child: Image.asset('assets/images/Games/French1/fr_robot_point.webp', height: sh * 0.42,
                        errorBuilder: (_, __, ___) => const SizedBox()),
                  ),
                ),
                // floating coins & gems
                for (var i = 0; i < 6; i++)
                  Positioned(
                    left: sw * [0.0, 0.88, 0.08, 0.84, 0.46, 0.2][i],
                    top: sh * [0.3, 0.32, 0.62, 0.0, -0.12, -0.06][i] + sin((t * 2 + i * 0.3) * pi) * 8,
                    child: Transform.rotate(
                      angle: sin((t + i * 0.2) * 2 * pi) * 0.3,
                      child: Image.asset(
                        i.isEven ? 'assets/images/Games/Math1/m1_coin.webp' : 'assets/images/Games/Math1/m1_gem.webp',
                        width: sw * (i < 2 ? 0.11 : 0.08),
                        errorBuilder: (_, __, ___) => Icon(i.isEven ? Icons.monetization_on_rounded : Icons.diamond_rounded,
                            color: i.isEven ? const Color(0xFFFFC21A) : const Color(0xFF7B3FE4), size: sw * 0.09),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _card(double w, Map<String, String> t) => Container(
        width: min(w - 40, 380.0),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1D9A6), width: 2.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Column(children: [
          Text(t['body']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink, height: 1.3)),
          const SizedBox(height: 10),
          // "loading the shelves" bar
          AnimatedBuilder(
            animation: _loop,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 14,
                child: Stack(children: [
                  Container(color: const Color(0xFFEDE4FF)),
                  FractionallySizedBox(
                    widthFactor: 0.72,
                    child: Container(
                      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF9B62F2), Color(0xFFFF6FA5), Color(0xFFFFC21A)])),
                    ),
                  ),
                  // shine running on the bar
                  Align(
                    alignment: Alignment(-1.2 + 2.4 * ((_loop.value * 2) % 1.0), 0),
                    child: Container(width: 30, color: Colors.white.withOpacity(0.45)),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.lightbulb_rounded, color: Color(0xFFFFB800), size: 26),
            const SizedBox(width: 8),
            Expanded(child: Text(t['tip']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6A5A92), height: 1.3))),
          ]),
        ]),
      );

  Widget _button(double w, String label) => AnimatedBuilder(
        animation: _loop,
        builder: (_, c) => Transform.scale(scale: 1 + 0.03 * sin(_loop.value * 2 * pi * 3), child: c),
        child: GestureDetector(
          onTap: () {
            _boing();
            if (!widget.embedded) Navigator.maybePop(context);
          },
          child: Container(
            width: min(w - 80, 300.0),
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFA23A), Color(0xFFF2620C)]),
              borderRadius: BorderRadius.circular(27),
              border: Border.all(color: const Color(0xFFFFD35A), width: 2.5),
              boxShadow: const [BoxShadow(color: Color(0xFFC9480A), offset: Offset(0, 4))],
            ),
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          ),
        ),
      );
}

class _AwningPainter extends CustomPainter {
  final double t;
  _AwningPainter(this.t);
  @override
  void paint(Canvas canvas, Size s) {
    const n = 7;
    final sw = s.width / n;
    final bottom = s.height * 0.72;
    for (var i = 0; i < n; i++) {
      final p = Paint()..color = i.isEven ? const Color(0xFFFF6F8E) : Colors.white;
      final x = i * sw;
      final wave = sin((t * 2 + i * 0.15) * pi * 2) * 2;
      final path = Path()
        ..moveTo(x + sw * 0.08, 0)
        ..lineTo(x + sw * 0.92, 0)
        ..lineTo(x + sw, bottom)
        ..quadraticBezierTo(x + sw / 2, s.height + wave, x, bottom)
        ..close();
      canvas.drawPath(path, p);
      canvas.drawPath(path, Paint()
        ..color = const Color(0xFFE04A6B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, -4, s.width, 8), const Radius.circular(4)), Paint()..color = const Color(0xFFE04A6B));
  }

  @override
  bool shouldRepaint(covariant _AwningPainter old) => old.t != t;
}

class _CurtainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = const Color(0xFFB98CFF);
    final path = Path()..moveTo(0, 0)..lineTo(s.width, 0)..lineTo(s.width, s.height * 0.7);
    const folds = 6;
    for (var i = folds; i >= 0; i--) {
      final x = s.width * i / folds;
      path.quadraticBezierTo(x + s.width / folds / 2, s.height * (i.isEven ? 1.0 : 0.75), x, s.height * 0.7);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _StringPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = const Color(0xFF8A5229)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(s.width / 2, 0), Offset(0, s.height), p);
    canvas.drawLine(Offset(s.width / 2, 0), Offset(s.width, s.height), p);
    canvas.drawCircle(Offset(s.width / 2, 0), 3, Paint()..color = const Color(0xFFFFD54A));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _SkyPainter extends CustomPainter {
  final double t;
  _SkyPainter(this.t);
  @override
  void paint(Canvas canvas, Size s) {
    // drifting clouds
    final cloud = Paint()..color = Colors.white.withOpacity(0.8);
    for (var i = 0; i < 3; i++) {
      final x = ((t + i / 3) % 1.0) * (s.width + 160) - 80;
      final y = s.height * (0.08 + 0.09 * i);
      final r = 18.0 + i * 4;
      canvas.drawCircle(Offset(x, y), r, cloud);
      canvas.drawCircle(Offset(x + r, y - r * 0.4), r * 1.2, cloud);
      canvas.drawCircle(Offset(x + r * 2.2, y), r, cloud);
    }
    // twinkles
    final rnd = Random(7);
    for (var i = 0; i < 14; i++) {
      final x = rnd.nextDouble() * s.width, y = rnd.nextDouble() * s.height;
      final a = (sin((t * 3 + i * 0.37) * 2 * pi) + 1) / 2;
      canvas.drawCircle(Offset(x, y), 1.5 + 2 * a, Paint()..color = const Color(0xFFFFD54A).withOpacity(0.25 + 0.5 * a));
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) => old.t != t;
}
