import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'shape_data.dart';
import 'shape_sorter_page.dart';
import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';

// ═══════════════════════════════════════════════════════════════
//  🌈 SHAPE PLANET ACADEMY — Level Select  (BRIGHT version)
//  Candy-gradient background, floating animated shapes,
//  vibrant level cards, banner ad at bottom.
// ═══════════════════════════════════════════════════════════════

class ShapeSorterApp extends StatelessWidget {
  const ShapeSorterApp({super.key});
  @override
  Widget build(BuildContext context) => const DifficultySelectionPage();
}

class DifficultySelectionPage extends StatefulWidget {
  const DifficultySelectionPage({super.key});
  @override
  State<DifficultySelectionPage> createState() =>
      _DifficultySelectionPageState();
}

class _DifficultySelectionPageState extends State<DifficultySelectionPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  late final AnimationController _bgCtrl;    // gradient pulse
  late final AnimationController _floatCtrl; // shapes float
  late final AnimationController _entryCtrl; // page entry

  // Banner ad
  BannerAd? _bannerAd;
  bool      _bannerLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _bgCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 6))..repeat(reverse: true);

    _floatCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat(reverse: true);

    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700))..forward();

    _loadBannerAd();
  }

  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgCtrl.dispose(); _floatCtrl.dispose(); _entryCtrl.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd?.dispose(); _bannerLoaded = false;
    if (!mounted) return;
    if (!Provider.of<ExperienceManager>(context, listen: false).adsEnabled) return;
    _bannerAd = AdHelper.getBannerAd(
            () { if (mounted) setState(() => _bannerLoaded = true); });
  }

  @override
  Widget build(BuildContext context) {
    final adsOn = context.watch<ExperienceManager>().adsEnabled;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      bottomNavigationBar: adsOn
          ? _MainBannerBar(bannerAd: _bannerAd, isLoaded: _bannerLoaded)
          : null,
      body: Stack(children: [
        // ── ANIMATED GRADIENT BG ──────────────────────────
        AnimatedBuilder(animation: _bgCtrl, builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(const Color(0xFFFFF3E0), const Color(0xFFFFE8F5),
                    _bgCtrl.value)!,
                Color.lerp(const Color(0xFFE8F4FF), const Color(0xFFF0EDFF),
                    _bgCtrl.value)!,
                Color.lerp(const Color(0xFFFFFBE0), const Color(0xFFF5FFEB),
                    _bgCtrl.value)!,
              ],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
        )),

        // ── DECORATIVE LARGE BLOBS ────────────────────────
        Positioned(top: -60, right: -60,
            child: _Blob(200, const Color(0xFFFF6B9D).withOpacity(0.12))),
        Positioned(top: 200, left: -50,
            child: _Blob(160, const Color(0xFF6C63FF).withOpacity(0.10))),
        Positioned(bottom: 100, right: -40,
            child: _Blob(140, const Color(0xFFFFD700).withOpacity(0.14))),
        Positioned(bottom: -40, left: 40,
            child: _Blob(120, const Color(0xFF00D4AA).withOpacity(0.12))),

        // ── CONTENT ──────────────────────────────────────
        SafeArea(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                  begin: const Offset(0, 0.04), end: Offset.zero)
                  .animate(CurvedAnimation(
                  parent: _entryCtrl, curve: Curves.easeOut)),
              child: Column(children: [
                _buildHeader(context),
                const SizedBox(height: 10),
                _buildShapeShowcase(),
                const SizedBox(height: 10),
                Expanded(child: _buildLevelList(context)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── HEADER ───────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFFFF6B9D)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.40),
            blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); Navigator.pop(context); },
          child: Container(width: 42, height: 42,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('🌈 Shape Academy!',
              style: TextStyle(fontFamily: 'Fredoka One',
                  fontSize: 22, color: Colors.white,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 6)])),
          Text('Pick a level and start sorting! 🎯',
              style: TextStyle(fontSize: 12,
                  color: Colors.white.withOpacity(0.80))),
        ])),
        // Bouncing emoji
        AnimatedBuilder(animation: _floatCtrl, builder: (_, __) =>
            Transform.translate(
                offset: Offset(0, sin(_floatCtrl.value * pi) * 6),
                child: const Text('🪐', style: TextStyle(fontSize: 32)))),
      ]),
    );
  }

  // ── SHAPE SHOWCASE ────────────────────────────────────────
  Widget _buildShapeShowcase() {
    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: kAllShapes.length,
        itemBuilder: (_, i) {
          final s = kAllShapes[i];
          return AnimatedBuilder(animation: _floatCtrl, builder: (_, __) {
            final dy = sin(_floatCtrl.value * pi + i * 0.55) * 6;
            return Transform.translate(
              offset: Offset(0, dy),
              child: Container(
                width: 52, height: 52,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                    color: s.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: s.color.withOpacity(0.30), width: 1.2)),
                padding: const EdgeInsets.all(6),
                child: CustomPaint(
                    painter: ShapeCustomPainter(
                        type: s.painterType, color: s.color,
                        glow: s.glow, glowRadius: 4)),
              ),
            );
          });
        },
      ),
    );
  }

  // ── LEVEL LIST ───────────────────────────────────────────
  Widget _buildLevelList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      itemCount: kLevels.length,
      itemBuilder: (_, i) {
        final lvl = kLevels[i];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + i * 70),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Opacity(
              opacity: v.clamp(0.0, 1.0),
              child: Transform.translate(
                  offset: Offset((1 - v) * 50, 0), child: child)),
          child: _LevelCard(
            level: lvl, index: i,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ShapeSorterPage(level: lvl)));
            },
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  LEVEL CARD  — bright, colourful, child-friendly
// ═══════════════════════════════════════════════════════════════
class _LevelCard extends StatefulWidget {
  final ShapeLevel   level;
  final int          index;
  final VoidCallback onTap;
  const _LevelCard({required this.level, required this.index, required this.onTap});
  @override State<_LevelCard> createState() => _LevelCardState();
}
class _LevelCardState extends State<_LevelCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double>   _scale;
  @override void initState() {
    super.initState();
    _press = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 90));
    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }
  @override void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final lvl    = widget.level;
    final shapes = kAllShapes.take(lvl.shapeCount).toList();

    return GestureDetector(
      onTapDown:   (_) => _press.forward(),
      onTapUp:     (_) => _press.reverse(),
      onTapCancel: ()  => _press.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.80),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: lvl.color.withOpacity(0.45), width: 2.5),
            boxShadow: [
              BoxShadow(color: lvl.glow.withOpacity(0.30),
                  blurRadius: 16, offset: const Offset(0, 5)),
              BoxShadow(color: Colors.black.withOpacity(0.04),
                  blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(children: [
            // Level emoji circle
            Container(width: 58, height: 58,
                decoration: BoxDecoration(
                    color: lvl.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: lvl.color.withOpacity(0.55), width: 2.5),
                    boxShadow: [BoxShadow(
                        color: lvl.glow.withOpacity(0.40), blurRadius: 10)]),
                alignment: Alignment.center,
                child: Text(lvl.emoji,
                    style: const TextStyle(fontSize: 28))),
            const SizedBox(width: 14),
            // Info
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lvl.name,
                  style: TextStyle(fontFamily: 'Fredoka One',
                      fontSize: 20, color: lvl.color)),
              Text(lvl.subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              // Mini shape preview
              Row(children: shapes.take(6).map((s) => Container(
                width: 24, height: 24,
                margin: const EdgeInsets.only(right: 5),
                child: CustomPaint(painter: ShapeCustomPainter(
                    type: s.painterType, color: s.color, glow: s.glow)),
              )).toList()),
            ])),
            const SizedBox(width: 10),
            // Play arrow
            Container(width: 40, height: 40,
                decoration: BoxDecoration(
                    color: lvl.color,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                        color: lvl.color.withOpacity(0.50),
                        blurRadius: 10, offset: const Offset(0, 4))]),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 24)),
          ]),
        ),
      ),
    );
  }
}

// ── Blob deco ─────────────────────────────────────────────────
class _Blob extends StatelessWidget {
  final double size; final Color color;
  const _Blob(this.size, this.color);
  @override Widget build(BuildContext context) => Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

// ═══════════════════════════════════════════════════════════════
//  MAIN SCREEN BANNER AD BAR
// ═══════════════════════════════════════════════════════════════
class _MainBannerBar extends StatefulWidget {
  final BannerAd? bannerAd; final bool isLoaded;
  const _MainBannerBar({required this.bannerAd, required this.isLoaded});
  @override State<_MainBannerBar> createState() => _MainBannerBarState();
}
class _MainBannerBarState extends State<_MainBannerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _s;
  late final Animation<double>   _a;
  @override void initState() {
    super.initState();
    _s = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _a = CurvedAnimation(parent: _s, curve: Curves.easeInOut);
  }
  @override void dispose() { _s.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final adH = (widget.bannerAd?.size.height.toDouble() ?? 50.0).clamp(40.0, 90.0);
    return SafeArea(top: false,
        child: Container(
          height: adH + 10,
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFFD700)])),
          child: widget.isLoaded && widget.bannerAd != null
              ? Center(child: SizedBox(
              height: adH,
              width: widget.bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: widget.bannerAd!)))
              : AnimatedBuilder(animation: _a, builder: (_, __) {
            final t = _a.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              child: Row(children: [
                Opacity(opacity: .5+t*.5,
                    child: const Text('🌈', style: TextStyle(fontSize: 16))),
                const SizedBox(width: 8),
                Expanded(child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(height: 26,
                        color: Colors.white.withOpacity(.14+t*.14),
                        alignment: Alignment.center,
                        child: Text('✨  Advertisement  ✨',
                            style: TextStyle(fontFamily: 'Fredoka One',
                                fontSize: 11,
                                color: Colors.white.withOpacity(.65+t*.25)))))),
                const SizedBox(width: 8),
                Opacity(opacity: .5+t*.5,
                    child: const Text('⭐', style: TextStyle(fontSize: 16))),
              ]),
            );
          }),
        ));
  }
}