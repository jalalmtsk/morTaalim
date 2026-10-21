import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/Manager/models/avatar_catalog.dart';
import 'package:mortaalim/Manager/models/banner_catalog.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/screens/main_home_screen/Profile/Badges/badge_catalog.dart';
import 'package:mortaalim/screens/main_home_screen/Profile/Customize/profile_look.dart';
import 'package:provider/provider.dart';

import 'world/cw_avatars.dart';
import 'world/cw_badges.dart';
import 'world/cw_banners.dart';
import 'world/cw_common.dart';
import 'world/cw_frames.dart';
import 'world/cw_treasures.dart';

/// "My wonderful world": the collection hub, a map of five floating islands.
class MyCollectionPage extends StatefulWidget {
  final bool embedded; // shown as a bottom-bar tab: no back button
  const MyCollectionPage({super.key, this.embedded = false});

  @override
  State<MyCollectionPage> createState() => _MyCollectionPageState();
}

class _Island {
  final String key, asset;
  final double x, y, w; // in map-width units
  final double aspect; // sprite height / width
  final bool labelStart; // label on the start side
  const _Island(this.key, this.asset, this.x, this.y, this.w, this.aspect, {this.labelStart = false});
}

const List<_Island> _islands = [
  _Island('avatars', 'col_isl_avatars', 0.0, 0.0, 0.56, 1.0477),
  _Island('banners', 'col_isl_banners', 0.44, 0.33, 0.56, 0.9727),
  _Island('frames', 'col_isl_frames', 0.0, 0.76, 0.56, 0.9476),
  _Island('treasures', 'col_isl_treasures', 0.44, 1.09, 0.56, 0.8262),
  _Island('badges', 'col_isl_badges', 0.24, 1.45, 0.56, 1.0249),
];

class _MyCollectionPageState extends State<MyCollectionPage> with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();
  CwProgress _p = CwProgress.empty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _idle.dispose();
    _intro.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await CwProgress.load(context);
    if (mounted) setState(() => _p = p);
  }

  Future<void> _open(String key) async {
    final Widget page = switch (key) {
      'avatars' => const CwAvatarsPage(),
      'banners' => const CwBannersPage(),
      'frames' => const CwFramesPage(),
      'treasures' => const CwTreasuresPage(),
      _ => const CwBadgesPage(),
    };
    await cwOpen(context, page);
    if (mounted) _load();
  }

  int _count(String key, ExperienceManager xp) => switch (key) {
        'avatars' => AvatarCatalog.sanitizeUnlocked(xp.unlockedAvatars).length,
        'banners' => BannerCatalog.sanitizeUnlocked(xp.unlockedBanners).length,
        'frames' => AvatarFrames.all.where((f) => AvatarFrames.owned(f, xp.level, xp.unlockedAvatarFrames)).length,
        'treasures' => _p.treasuresFound,
        _ => appBadges.where((b) => b.earned(_p.stats)).length,
      };

  @override
  Widget build(BuildContext context) {
    final xp = context.watch<ExperienceManager>();
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final s = cwScale(context);
    final mapW = min(size.width, 560.0);
    final name = xp.userProfile.fullName.trim();
    final hasName = name.isNotEmpty && name != 'Player';

    return Scaffold(
      backgroundColor: const Color(0xFFBFE6FF),
      body: Stack(children: [
        const Positioned.fill(child: CwWorldBg()),
        Positioned.fill(child: CwSparkles(idle: _idle, count: 22, seed: 11, color: Colors.white)),
        Column(children: [
          SizedBox(height: pad.top + 4 * s),
          // header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12 * s),
            child: Row(children: [
              if (!widget.embedded) CwBack(size: 50 * s) else SizedBox(width: 50 * s),
              Expanded(
                child: _pop(0.0, 0.3, CwTitlePill(title: cwT(context, 'worldTitle'), subtitle: cwT(context, 'worldSub'), s: s)),
              ),
              SizedBox(width: 50 * s),
            ]),
          ),
          SizedBox(height: 6 * s),
          _pop(
            0.1,
            0.4,
            CwChip(
              s: s,
              text: hasName ? cwT(context, 'worldOf', {'name': name}) : cwT(context, 'worldOfNoName'),
              leading: FramedAvatar(avatar: xp.selectedAvatar, frame: '', size: 30 * s),
            ),
          ),
          // the map
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(bottom: widget.embedded ? 110 : pad.bottom + 16),
              child: Center(child: _map(mapW, s, xp)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _pop(double a, double b, Widget child) {
    final c = CurvedAnimation(parent: _intro, curve: Interval(a, b, curve: Curves.easeOutBack));
    return FadeTransition(
      opacity: CurvedAnimation(parent: _intro, curve: Interval(a, min(1.0, b), curve: Curves.easeOut)),
      child: ScaleTransition(scale: Tween(begin: 0.6, end: 1.0).animate(c), child: child),
    );
  }

  Widget _map(double w, double s, ExperienceManager xp) {
    final h = w * 2.12;
    Offset anchor(_Island i) => Offset((i.x + i.w / 2) * w, (i.y + i.w * i.aspect * 0.72) * w);
    return SizedBox(
      width: w,
      height: h,
      child: Stack(clipBehavior: Clip.none, children: [
        // stepping-stone bridges between islands
        Positioned.fill(
          child: _pop(
            0.25,
            0.7,
            CustomPaint(painter: _BridgePainter([for (final i in _islands) anchor(i)], s)),
          ),
        ),
        for (var k = 0; k < _islands.length; k++) _island(_islands[k], k, w, s, xp),
        // guide robot
        Positioned(
          left: 4 * s,
          top: w * 1.62,
          child: IgnorePointer(
            child: _pop(
              0.65,
              1.0,
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CwFloat(idle: _idle, amp: 3, speed: 2, child: CwBubble(text: cwT(context, 'ask'), width: w * 0.42)),
                CwFloat(
                  idle: _idle,
                  amp: 5,
                  speed: 1.5,
                  phase: 0.3,
                  tilt: 0.04,
                  child: Image.asset(cw('col_robot_wave'), width: w * 0.26),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _island(_Island i, int k, double w, double s, ExperienceManager xp) {
    final iw = i.w * w;
    final ih = iw * i.aspect;
    final label = cwT(context, i.key);
    final n = _count(i.key, xp);
    return Positioned(
      left: i.x * w,
      top: i.y * w,
      width: iw,
      height: ih + 30 * s,
      child: _pop(
        0.15 + k * 0.1,
        0.55 + k * 0.1,
        CwPress(
          onTap: () => _open(i.key),
          scale: 0.95,
          label: label,
          child: Stack(clipBehavior: Clip.none, children: [
            // soft glow under the island
            Positioned(
              left: iw * 0.1,
              right: iw * 0.1,
              top: ih * 0.55,
              height: ih * 0.4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.55), blurRadius: 40 * s, spreadRadius: 4 * s)],
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              width: iw,
              height: ih,
              child: CwFloat(
                idle: _idle,
                amp: 5 * s,
                speed: 1,
                phase: k * 0.21,
                child: Image.asset(cw(i.asset), width: iw, height: ih, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: ih * 0.78,
              child: Center(child: _label(s, label, n)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _label(double s, String text, int n) => Container(
        padding: EdgeInsetsDirectional.fromSTEB(16 * s, 6 * s, 8 * s, 6 * s),
        decoration: BoxDecoration(
          color: cwCream,
          borderRadius: BorderRadius.circular(30 * s),
          border: Border.all(color: Colors.white, width: 2 * s),
          boxShadow: [BoxShadow(color: const Color(0xFF3B2A8A).withOpacity(0.25), blurRadius: 10 * s, offset: Offset(0, 4 * s))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(text, style: cwText(18 * s)),
          SizedBox(width: 8 * s),
          Container(
            constraints: BoxConstraints(minWidth: 26 * s),
            height: 26 * s,
            padding: EdgeInsets.symmetric(horizontal: 6 * s),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: cwPurple, borderRadius: BorderRadius.circular(20 * s)),
            child: Text('$n', style: cwText(14 * s, color: Colors.white)),
          ),
          SizedBox(width: 2 * s),
          Transform.flip(
            flipX: cwRtl(context),
            child: Icon(Icons.chevron_right_rounded, color: cwPurple, size: 24 * s),
          ),
        ]),
      );
}

/// Pastel stepping stones winding from island to island.
class _BridgePainter extends CustomPainter {
  final List<Offset> pts;
  final double s;
  _BridgePainter(this.pts, this.s);

  static const _colors = [Color(0xFFFFC7E3), Color(0xFFB9ECFF), Color(0xFFFFF0A8), Color(0xFFDCCBFF)];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i + 1 < pts.length; i++) {
      final a = pts[i], b = pts[i + 1];
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 + 26 * s);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy + 20 * s, b.dx, b.dy);
      for (final m in path.computeMetrics()) {
        var k = 0;
        for (double d = 40 * s; d < m.length - 40 * s; d += 17 * s) {
          final t = m.getTangentForOffset(d);
          if (t == null) continue;
          canvas.save();
          canvas.translate(t.position.dx, t.position.dy);
          canvas.rotate(t.angle);
          final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 13 * s, height: 9 * s), Radius.circular(4 * s));
          canvas.drawRRect(r.shift(Offset(0, 2 * s)), Paint()..color = Colors.black.withOpacity(0.12));
          canvas.drawRRect(r, Paint()..color = _colors[k % _colors.length]);
          canvas.drawRRect(
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4 * s
              ..color = Colors.white,
          );
          canvas.restore();
          k++;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BridgePainter o) => o.pts != pts || o.s != s;
}
