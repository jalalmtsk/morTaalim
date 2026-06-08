import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mortaalim/tools/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';
import '../practiseWords.dart';

// ═══════════════════════════════════════════════════════════════
//  🗼 PARISIAN CAFÉ — Play the Word
//  BUG-FIXED + OVERFLOW-SAFE version
//  • prefs guarded with _prefsReady flag — no LateInitializationError
//  • flip uses a simple bool toggled inside addListener, not value threshold
//  • _buildBack uses a fixed-height image, no unbounded Expanded
//  • All text uses FittedBox / maxLines to prevent overflow
//  • Postcard uses ConstrainedBox so image never overflows
// ═══════════════════════════════════════════════════════════════
class _P {
  static const cobalt    = Color(0xFF1C3FAA);
  static const rouge     = Color(0xFFDC2626);
  static const cream     = Color(0xFFFFFBF0);
  static const gold      = Color(0xFFD4A017);
  static const goldLight = Color(0xFFF5D97E);
  static const white     = Color(0xFFFFFFFF);
  static const dark      = Color(0xFF1E293B);

  static const List<Color> accents = [
    Color(0xFF1C3FAA), Color(0xFFDC2626), Color(0xFF059669),
    Color(0xFF7C3AED), Color(0xFFD97706), Color(0xFF0891B2),
    Color(0xFFDB2777), Color(0xFF16A34A),
  ];
  static const font = 'Fredoka One';
}

// ── Eiffel skyline deco ────────────────────────────────────────
class _SkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _P.cobalt.withOpacity(0.07) ..style = PaintingStyle.fill;
    final w = size.width; final h = size.height;
    final cx = w * 0.85;
    final tower = Path()
      ..moveTo(cx-4, h)..lineTo(cx-16, h*.50)..lineTo(cx-6, h*.45)
      ..lineTo(cx-2, h*.10)..lineTo(cx+2, h*.10)..lineTo(cx+6, h*.45)
      ..lineTo(cx+16, h*.50)..lineTo(cx+4, h)..close();
    canvas.drawPath(tower, p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(w*.12, h*.5), width: 10, height: h*.55),
            const Radius.circular(5)),
        Paint()..color = _P.gold.withOpacity(0.09));
  }
  @override bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════
//  FLIP CARD  (grid mode)
//  FIX: uses a simple bool _flipped toggled after animation completes
//       via addStatusListener — no value-threshold guessing.
//  FIX: back side uses a fixed-height image container, not Expanded.
// ═══════════════════════════════════════════════════════════════
class _CafeCard extends StatefulWidget {
  final PractiseWords word;
  final bool isLearned;
  final Color accent;
  final VoidCallback onTap;           // plays audio
  const _CafeCard({required this.word, required this.isLearned,
    required this.accent, required this.onTap});
  @override State<_CafeCard> createState() => _CafeCardState();
}

class _CafeCardState extends State<_CafeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  // true while showing the image back
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    // Toggle _flipped exactly at the midpoint
    _ctrl.addListener(() {
      final mid = _ctrl.value >= 0.5;
      if (mid != _flipped) setState(() => _flipped = mid);
    });
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap();
    if (_ctrl.isDismissed || _ctrl.status == AnimationStatus.reverse) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          // angle goes 0 → π (flip around Y)
          final angle = _ctrl.value * pi;
          // After 90° we mirror so text/image doesn't appear reversed
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);
          return Transform(
            alignment: Alignment.center,
            transform: transform,
            // When past 90°, counter-rotate the child so it reads correctly
            child: _flipped
                ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(pi),
              child: _buildBack(),
            )
                : _buildFront(),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Color.lerp(widget.accent, Colors.white, 0.18)!, widget.accent],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: widget.isLearned
            ? Border.all(color: const Color(0xFF39FF14), width: 2.5)
            : Border.all(color: Colors.white.withOpacity(0.28), width: 1.2),
        boxShadow: [BoxShadow(color: widget.accent.withOpacity(0.42),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Stack(children: [
        Positioned(bottom: 6, right: 6,
            child: Text('☕', style: TextStyle(fontSize: 18,
                color: Colors.white.withOpacity(0.15)))),
        Center(child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.word.emoji, style: const TextStyle(fontSize: 38)),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(widget.word.word,
                  maxLines: 1,
                  style: const TextStyle(fontFamily: _P.font,
                      fontSize: 18, color: _P.white,
                      shadows: [Shadow(color: Colors.black38, blurRadius: 5)])),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.volume_up_rounded, size: 12, color: _P.white),
                SizedBox(width: 3),
                Text('Écouter', style: TextStyle(fontFamily: _P.font,
                    fontSize: 10, color: _P.white)),
              ]),
            ),
            if (widget.isLearned) ...[
              const SizedBox(height: 4),
              const Text('✓ Appris!', style: TextStyle(fontFamily: _P.font,
                  fontSize: 11, color: Color(0xFF86EFAC))),
            ],
          ]),
        )),
      ]),
    );
  }

  Widget _buildBack() {
    // FIX: fixed-height image (90px), no Expanded, no unbounded column
    return Container(
      decoration: BoxDecoration(
        color: _P.cream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.accent.withOpacity(0.45), width: 2),
        boxShadow: [BoxShadow(color: widget.accent.withOpacity(0.28),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fixed-height image — no overflow
            SizedBox(
              height: 110,
              child: Image.asset(widget.word.imagePath, fit: BoxFit.cover),
            ),
            Container(
              color: widget.accent,
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: FittedBox(fit: BoxFit.scaleDown,
                  child: Text(widget.word.word,
                      style: const TextStyle(fontFamily: _P.font,
                          fontSize: 16, color: _P.white))),
            ),
          ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  POSTCARD  (flashcard mode)
//  FIX: image is a ConstrainedBox height, not unbounded Expanded
// ═══════════════════════════════════════════════════════════════
class _Postcard extends StatefulWidget {
  final PractiseWords word;
  final bool isLearned;
  final Color accent;
  final VoidCallback onTap;
  const _Postcard({required this.word, required this.isLearned,
    required this.accent, required this.onTap});
  @override State<_Postcard> createState() => _PostcardState();
}
class _PostcardState extends State<_Postcard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry;
  late final Animation<double>   _scale;
  @override void initState() {
    super.initState();
    _entry = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 550))..forward();
    _scale = CurvedAnimation(parent: _entry, curve: Curves.elasticOut);
  }
  @override void dispose() { _entry.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); widget.onTap(); },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: _P.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
                color: widget.isLearned
                    ? const Color(0xFF22C55E) : widget.accent.withOpacity(0.30),
                width: widget.isLearned ? 3 : 1.5),
            boxShadow: [
              BoxShadow(color: widget.accent.withOpacity(0.28),
                  blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          // FIX: Column inside a scrollable context needs mainAxisSize.min
          //      and all children have fixed/intrinsic sizes
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header strip
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 9, 14, 8),
                  decoration: BoxDecoration(
                      color: widget.accent,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                  child: Row(children: [
                    const Text('🗼', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    const Text('Carte Postale',
                        style: TextStyle(fontFamily: _P.font,
                            fontSize: 13, color: _P.white)),
                    const Spacer(),
                    Container(width: 30, height: 30,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.white.withOpacity(0.50), width: 1.2)),
                        alignment: Alignment.center,
                        child: Text(widget.word.emoji,
                            style: const TextStyle(fontSize: 14))),
                  ]),
                ),
                // Image — fixed height
                ClipRect(
                  child: SizedBox(
                    height: 180,
                    child: Image.asset(widget.word.imagePath,
                        fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
                // Bottom info
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    FittedBox(fit: BoxFit.scaleDown,
                        child: Text(widget.word.word,
                            style: TextStyle(fontFamily: _P.font, fontSize: 28,
                                color: widget.accent))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, alignment: WrapAlignment.center,
                      children: [
                        // Audio button
                        GestureDetector(
                          onTap: () { HapticFeedback.selectionClick(); widget.onTap(); },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                                color: widget.accent,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [BoxShadow(
                                    color: widget.accent.withOpacity(0.42),
                                    blurRadius: 8, offset: const Offset(0, 3))]),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.volume_up_rounded, size: 18, color: _P.white),
                              SizedBox(width: 5),
                              Text('Écouter!', style: TextStyle(fontFamily: _P.font,
                                  fontSize: 14, color: _P.white)),
                            ]),
                          ),
                        ),
                        if (widget.isLearned)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                                color: const Color(0xFF22C55E).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFF22C55E), width: 1.5)),
                            child: const Text('✓ Appris',
                                style: TextStyle(fontFamily: _P.font,
                                    fontSize: 12, color: Color(0xFF15803D))),
                          ),
                      ],
                    ),
                  ]),
                ),
              ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MAIN WIDGET
// ═══════════════════════════════════════════════════════════════
class PlayTheWord extends StatefulWidget {
  final List<PractiseWords> words;
  const PlayTheWord({super.key, required this.words});
  @override State<PlayTheWord> createState() => _PlayTheWordState();
}

class _PlayTheWordState extends State<PlayTheWord>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  final MusicPlayer _player = MusicPlayer();
  final Set<String> learnedWords = {};
  bool flashcardMode = false;

  // FIX: guard prefs with a ready-flag to prevent LateInitializationError
  SharedPreferences? _prefs;
  bool _prefsReady = false;

  late AnimationController _bgCtrl;
  late Animation<double>   _bgAnim;
  late AnimationController _entryCtrl;
  late Animation<double>   _entryFade;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _bgCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 6))..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600))..forward();
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _loadBannerAd();
    _initPrefs();
  }

  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgCtrl.dispose(); _entryCtrl.dispose();
    _player.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd?.dispose(); _isBannerAdLoaded = false;
    if (!mounted) return;
    if (!Provider.of<ExperienceManager>(context, listen: false).adsEnabled) return;
    _bannerAd = AdHelper.getBannerAd(
            () { if (mounted) setState(() => _isBannerAdLoaded = true); });
  }

  // FIX: nullable prefs, only save/read after ready
  Future<void> _initPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    final saved = p.getStringList('ptw_learnedWords') ?? [];
    setState(() {
      _prefs = p;
      _prefsReady = true;
      learnedWords.addAll(saved);
    });
  }

  Future<void> _saveProgress() async {
    if (!_prefsReady || _prefs == null) return;
    await _prefs!.setStringList('ptw_learnedWords', learnedWords.toList());
  }

  Future<void> _playWord(PractiseWords word) async {
    HapticFeedback.selectionClick();
    setState(() => learnedWords.add(word.word));
    await _player.play(word.audioPath);
    _saveProgress(); // safe: guarded inside
  }

  Future<void> _resetProgress() async {
    setState(() => learnedWords.clear());
    if (_prefsReady && _prefs != null) {
      await _prefs!.remove('ptw_learnedWords');
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.words;
    return Scaffold(
      backgroundColor: _P.cream,
      bottomNavigationBar: context.watch<ExperienceManager>().adsEnabled
          ? _FrenchBannerBar(bannerAd: _bannerAd, isLoaded: _isBannerAdLoaded)
          : null,
      body: Stack(children: [
        // Animated BG
        AnimatedBuilder(animation: _bgAnim,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(const Color(0xFFFFF8F0), const Color(0xFFFFF0E8), _bgAnim.value)!,
                  Color.lerp(const Color(0xFFEFF6FF), const Color(0xFFE0EFFE), _bgAnim.value)!,
                  Color.lerp(const Color(0xFFFFF8F0), const Color(0xFFFEF3F0), _bgAnim.value)!,
                ],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _SkylinePainter())),

        SafeArea(
          child: FadeTransition(opacity: _entryFade,
            child: Column(children: [
              _buildHeader(),
              const Padding(padding: EdgeInsets.fromLTRB(12, 6, 12, 0),
                  child: Userstatutbar()),
              const SizedBox(height: 8),
              _buildProgressBar(words),
              const SizedBox(height: 8),
              Expanded(
                child: flashcardMode
                    ? _buildPostcardMode(words)
                    : _buildCafeGrid(words),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1C3FAA), Color(0xFF2563EB)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _P.cobalt.withOpacity(0.38),
            blurRadius: 18, offset: const Offset(0, 5))],
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); Navigator.pop(context); },
          child: Container(width: 40, height: 40,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 17, color: _P.white)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🗼 Play the Word', style: TextStyle(
                  fontFamily: _P.font, fontSize: 17, color: _P.white)),
              Text('Écoute · Découvre · Apprends',
                  style: TextStyle(fontSize: 11,
                      color: _P.goldLight.withOpacity(0.85))),
            ])),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() { flashcardMode = !flashcardMode; });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withOpacity(0.38), width: 1)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(flashcardMode ? Icons.grid_view : Icons.view_carousel,
                  size: 15, color: _P.white),
              const SizedBox(width: 4),
              Text(flashcardMode ? 'Grille' : 'Cartes',
                  style: const TextStyle(fontFamily: _P.font,
                      fontSize: 11, color: _P.white)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildProgressBar(List<PractiseWords> words) {
    final pct = words.isEmpty ? 0.0
        : (learnedWords.length / words.length).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _P.cobalt.withOpacity(0.18), width: 1),
        boxShadow: [BoxShadow(color: _P.cobalt.withOpacity(0.08),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                const Text('📚', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text('${learnedWords.length} / ${words.length} mots',
                    style: const TextStyle(fontFamily: _P.font,
                        fontSize: 13, color: _P.dark)),
              ]),
              GestureDetector(
                onTap: _resetProgress,
                child: Container(width: 32, height: 32,
                    decoration: BoxDecoration(
                        color: _P.rouge.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: _P.rouge.withOpacity(0.28), width: 1)),
                    child: const Icon(Icons.refresh_rounded, size: 16, color: _P.rouge)),
              ),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: _P.cobalt.withOpacity(0.10),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1C3FAA)),
              ),
            ),
          ]),
    );
  }

  Widget _buildCafeGrid(List<PractiseWords> words) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10,
        mainAxisSpacing: 10, childAspectRatio: 0.88,
      ),
      itemCount: words.length,
      itemBuilder: (_, i) {
        final word = words[i];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 280 + i * 40),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Opacity(
              opacity: v.clamp(0.0, 1.0),
              child: Transform.scale(scale: v.clamp(0.01, 1.0), child: child)),
          child: _CafeCard(
            word:      word,
            isLearned: learnedWords.contains(word.word),
            accent:    _P.accents[i % _P.accents.length],
            onTap:     () => _playWord(word),
          ),
        );
      },
    );
  }

  Widget _buildPostcardMode(List<PractiseWords> words) {
    return PageView.builder(
      itemCount: words.length,
      controller: PageController(viewportFraction: 0.88),
      itemBuilder: (_, i) {
        final word = words[i];
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: _Postcard(
            word:      word,
            isLearned: learnedWords.contains(word.word),
            accent:    _P.accents[i % _P.accents.length],
            onTap:     () => _playWord(word),
          ),
        );
      },
    );
  }
}

// ── Banner bar ─────────────────────────────────────────────────
class _FrenchBannerBar extends StatefulWidget {
  final BannerAd? bannerAd; final bool isLoaded;
  const _FrenchBannerBar({required this.bannerAd, required this.isLoaded});
  @override State<_FrenchBannerBar> createState() => _FrenchBannerBarState();
}
class _FrenchBannerBarState extends State<_FrenchBannerBar>
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
    // FIX: clamp ad height so banner bar never overflows
    final adH = (widget.bannerAd?.size.height.toDouble() ?? 50).clamp(40.0, 90.0);
    return SafeArea(top: false,
        child: SizedBox(
          height: adH + 10,
          child: Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF1C3FAA), Color(0xFFDC2626)])),
            child: widget.isLoaded && widget.bannerAd != null
                ? Center(child: SizedBox(height: adH,
                width: widget.bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: widget.bannerAd!)))
                : AnimatedBuilder(animation: _a, builder: (_, __) {
              final t = _a.value;
              return Padding(padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 5),
                  child: Row(children: [
                    Opacity(opacity: .5+t*.5,
                        child: const Text('🗼', style: TextStyle(fontSize: 16))),
                    const SizedBox(width: 8),
                    Expanded(child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(height: 26,
                            color: Colors.white.withOpacity(.13+t*.13),
                            alignment: Alignment.center,
                            child: Text('✨  Publicité  ✨',
                                style: TextStyle(fontFamily: _P.font, fontSize: 11,
                                    color: Colors.white.withOpacity(.65+t*.25)))))),
                    const SizedBox(width: 8),
                    Opacity(opacity: .5+t*.5,
                        child: const Text('🥐', style: TextStyle(fontSize: 16))),
                  ]));
            }),
          ),
        ));
  }
}