import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import 'package:mortaalim/tools/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import '../../XpSystem.dart';
import '../../tools/Ads_Manager.dart';
import '../practiseWords.dart';

// ═══════════════════════════════════════════════════════════════
//  🎨 ART GALLERY — Match Word to Image
//  Theme: A chic French art gallery. The word is displayed like
//  a placard. Four paintings hang on the wall — tap the right one.
//  Pastel gallery palette with gilded frames.
// ═══════════════════════════════════════════════════════════════
class _G {
  static const wall      = Color(0xFFF5F0E8);  // gallery wall
  static const wallDeep  = Color(0xFFEDE6D6);
  static const gold      = Color(0xFFD4A017);
  static const goldLight = Color(0xFFF5D97E);
  static const cobalt    = Color(0xFF1C3FAA);
  static const rouge     = Color(0xFFDC2626);
  static const dark      = Color(0xFF2C2C2C);
  static const white     = Color(0xFFFFFFFF);

  static const List<Color> frameColors = [
    Color(0xFFD4A017), // antique gold
    Color(0xFF8B4513), // walnut brown
    Color(0xFF1C3FAA), // cobalt blue frame
    Color(0xFF2C7A2C), // gallery green
  ];

  static const String font = 'Fredoka One';
}

// ═══════════════════════════════════════════════════════════════
//  WRAPPER
// ═══════════════════════════════════════════════════════════════
class MatchWordToImage extends StatefulWidget {
  final List<PractiseWords> words;
  const MatchWordToImage({super.key, required this.words});
  @override State<MatchWordToImage> createState() => _MatchWordToImageState();
}

// ═══════════════════════════════════════════════════════════════
//  FRAMED PAINTING WIDGET
// ═══════════════════════════════════════════════════════════════
class _FramedPainting extends StatefulWidget {
  final PractiseWords option;
  final Color frameColor;
  final bool? isCorrect; // null=unanswered, true=correct, false=wrong
  final VoidCallback onTap;
  final int index;
  const _FramedPainting({required this.option, required this.frameColor,
    required this.isCorrect, required this.onTap, required this.index});
  @override State<_FramedPainting> createState() => _FramedPaintingState();
}
class _FramedPaintingState extends State<_FramedPainting>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double>   _scale;
  @override void initState() {
    super.initState();
    _press = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 90));
    _scale = Tween<double>(begin: 1.0, end: 0.91)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }
  @override void dispose() { _press.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    Color outerFrame = widget.frameColor;
    Color glow = Colors.transparent;
    if (widget.isCorrect == true)  { outerFrame = const Color(0xFF22C55E); glow = const Color(0xFF22C55E); }
    if (widget.isCorrect == false) { outerFrame = _G.rouge; glow = _G.rouge; }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 250 + widget.index * 80),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.scale(scale: v.clamp(0.01, 1.0), child: child)),
      child: GestureDetector(
        onTapDown: (_) => _press.forward(),
        onTapUp:   (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        onTap: widget.isCorrect == null ? widget.onTap : null,
        child: AnimatedBuilder(animation: _scale,
          builder: (_, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: Container(
            decoration: BoxDecoration(
              color: outerFrame,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(color: outerFrame.withOpacity(0.50),
                    blurRadius: widget.isCorrect != null ? 22 : 10,
                    offset: const Offset(0, 4)),
                if (glow != Colors.transparent)
                  BoxShadow(color: glow.withOpacity(0.45), blurRadius: 30),
              ],
            ),
            padding: const EdgeInsets.all(6),
            child: Container(
              decoration: BoxDecoration(
                  color: const Color(0xFFFAF5E4),
                  borderRadius: BorderRadius.circular(3)),
              padding: const EdgeInsets.all(4),
              child: Stack(children: [
                // Painting image
                ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Image.asset(widget.option.imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity, height: double.infinity)),
                // Result badge
                if (widget.isCorrect != null)
                  Positioned.fill(child: Container(
                    color: (widget.isCorrect! ? const Color(0xFF22C55E)
                        : _G.rouge).withOpacity(0.30),
                    alignment: Alignment.center,
                    child: Text(widget.isCorrect! ? '✓' : '✗',
                        style: TextStyle(
                          fontFamily: _G.font, fontSize: 48,
                          color: widget.isCorrect! ? const Color(0xFF22C55E)
                              : _G.rouge,
                          shadows: const [Shadow(color: Colors.black26,
                              blurRadius: 8)],
                        )),
                  )),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MAIN STATE
// ═══════════════════════════════════════════════════════════════
class _MatchWordToImageState extends State<MatchWordToImage>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  final MusicPlayer _player = MusicPlayer();
  final MusicPlayer _bgMusic = MusicPlayer();
  final Random _rng = Random();

  late List<PractiseWords> _options;
  late PractiseWords       _currentWord;
  int   _score          = 0;
  int   _streak         = 0;
  int?  _selectedIndex;  // index in _options
  bool? _selectedCorrect;
  bool  _isProcessing   = false;

  // Feedback animation controllers
  late AnimationController _feedbackCtrl;
  late Animation<double>   _feedbackScale;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _bgMusic.play("assets/audios/sound_track/SakuraGirlYay_BcG.mp3", loop: true);
    _bgMusic.setVolume(0.07);
    _player.setVolume(1);

    _feedbackCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _feedbackScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.20), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.20, end: 1.0),  weight: 60),
    ]).animate(CurvedAnimation(parent: _feedbackCtrl,
        curve: Curves.easeOut));

    _generateNewRound();
    _loadBannerAd();
  }

  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose(); _bgMusic.dispose();
    _feedbackCtrl.dispose();
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

  Future<void> _generateNewRound() async {
    final pool = [...widget.words]..shuffle(_rng);
    _options     = pool.take(4).toList();
    _currentWord = _options[_rng.nextInt(4)];
    _selectedIndex   = null;
    _selectedCorrect = null;
    _isProcessing    = false;
    await _player.play(_currentWord.audioPath);
    setState(() {});
  }

  Future<void> _handleSelection(int index) async {
    if (_isProcessing) return;
    _isProcessing = true;
    HapticFeedback.selectionClick();

    final selected = _options[index];
    final isCorrect = selected.word == _currentWord.word;

    setState(() {
      _selectedIndex   = index;
      _selectedCorrect = isCorrect;
    });

    _feedbackCtrl.reset();
    _feedbackCtrl.forward();

    if (isCorrect) {
      _streak++;
      Provider.of<ExperienceManager>(context, listen: false)
          .addXP(1, context: context);
      HapticFeedback.lightImpact();
      setState(() => _score++);
      await _player.play('assets/audios/QuizGame_Sounds/correct.mp3');
    } else {
      _streak = 0;
      HapticFeedback.heavyImpact();
      await _player.play('assets/audios/QuizGame_Sounds/incorrect.mp3');
    }

    await Future.delayed(const Duration(milliseconds: 1050));
    if (mounted) _generateNewRound();
  }

  // ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _G.wall,
      bottomNavigationBar: context.watch<ExperienceManager>().adsEnabled
          ? _GalleryBannerBar(bannerAd: _bannerAd, isLoaded: _isBannerAdLoaded)
          : null,
      body: Stack(children: [
        // Gallery wall texture
        Positioned.fill(child: CustomPaint(painter: _WallTexturePainter())),

        SafeArea(
          child: Column(children: [
            _buildHeader(),
            const SizedBox(height: 8),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                child: Userstatutbar()),
            const SizedBox(height: 10),
            // Score + streak HUD
            _buildHUD(),
            const SizedBox(height: 12),
            // Word placard
            _buildPlacard(),
            const SizedBox(height: 14),
            // 4 framed paintings
            Expanded(child: _buildGallery()),
          ]),
        ),

        // Feedback lottie overlay
        if (_selectedCorrect != null)
          IgnorePointer(child: ScaleTransition(
            scale: _feedbackScale,
            child: Container(
              color: Colors.black.withOpacity(0.22),
              alignment: Alignment.center,
              child: SizedBox(width: 180, height: 180,
                  child: Lottie.asset(
                      _selectedCorrect!
                          ? 'assets/animations/QuizzGame_Animation/DoneAnimation.json'
                          : 'assets/animations/QuizzGame_Animation/wrong.json',
                      repeat: false)),
            ),
          )),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [_G.gold, const Color(0xFFB8860B)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: _G.gold.withOpacity(0.50),
            blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); Navigator.pop(context); },
          child: Container(width: 40, height: 40,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 17, color: _G.white)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎨 Galerie d\'Art', style: TextStyle(
                  fontFamily: _G.font, fontSize: 18, color: _G.white,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 6)])),
              Text('Associe le mot à l\'image !',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.80))),
            ])),
        // Replay audio button
        GestureDetector(
          onTap: () => _player.play(_currentWord.audioPath),
          child: Container(width: 44, height: 44,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.5)),
              child: const Icon(Icons.volume_up_rounded,
                  size: 22, color: _G.white)),
        ),
      ]),
    );
  }

  Widget _buildHUD() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        // Score
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.70),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _G.gold.withOpacity(0.50), width: 1.5),
              boxShadow: [BoxShadow(color: _G.gold.withOpacity(0.18),
                  blurRadius: 8)]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('⭐', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 5),
            Text('$_score', style: const TextStyle(
                fontFamily: _G.font, fontSize: 18, color: _G.dark)),
          ]),
        ),
        const SizedBox(width: 10),
        // Streak — Flexible so it doesn't force row overflow
        if (_streak >= 2)
          Flexible(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFFD700)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.50),
                    blurRadius: 10)]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🔥', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 5),
              Text('× $_streak', style: const TextStyle(
                  fontFamily: _G.font, fontSize: 16, color: _G.white)),
            ]),
          )),
        const Spacer(),
        // Emoji of current word
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.70),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _G.cobalt.withOpacity(0.25), width: 1.2)),
          child: Text(_currentWord.emoji,
              style: const TextStyle(fontSize: 22)),
        ),
      ]),
    );
  }

  Widget _buildPlacard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _G.gold, width: 3),
        boxShadow: [
          BoxShadow(color: _G.gold.withOpacity(0.35), blurRadius: 16,
              offset: const Offset(0, 5)),
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
        ],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        // Speaker
        GestureDetector(
          onTap: () { HapticFeedback.selectionClick();
          _player.play(_currentWord.audioPath); },
          child: Container(width: 44, height: 44,
              decoration: BoxDecoration(
                  color: _G.cobalt.withOpacity(0.10),
                  shape: BoxShape.circle,
                  border: Border.all(color: _G.cobalt.withOpacity(0.35), width: 1.5)),
              child: const Icon(Icons.volume_up_rounded,
                  size: 22, color: _G.cobalt)),
        ),
        const SizedBox(width: 14),
        Flexible(child: FittedBox(fit: BoxFit.scaleDown,
            child: Text(_currentWord.word,
                maxLines: 1,
                style: const TextStyle(fontFamily: _G.font, fontSize: 32,
                    color: _G.cobalt,
                    shadows: [Shadow(color: Colors.black12, blurRadius: 4)])))),
        const SizedBox(width: 14),
        Text(_currentWord.emoji, style: const TextStyle(fontSize: 28)),
      ]),
    );
  }

  Widget _buildGallery() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(_options.length, (i) {
          bool? correct;
          if (_selectedIndex == i) correct = _selectedCorrect;

          return _FramedPainting(
            option:     _options[i],
            frameColor: _G.frameColors[i % _G.frameColors.length],
            isCorrect:  correct,
            onTap:      () => _handleSelection(i),
            index:      i,
          );
        }),
      ),
    );
  }
}

// ── Wall texture painter ────────────────────────────────────────
class _WallTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _G.gold.withOpacity(0.04) ..strokeWidth = 1;
    // Subtle vertical stripe texture
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Baseboard
    canvas.drawRect(
        Rect.fromLTWH(0, size.height - 18, size.width, 18),
        Paint()..color = _G.gold.withOpacity(0.10));
  }
  @override bool shouldRepaint(_) => false;
}

// ── Gallery Banner bar ──────────────────────────────────────────
class _GalleryBannerBar extends StatefulWidget {
  final BannerAd? bannerAd; final bool isLoaded;
  const _GalleryBannerBar({required this.bannerAd, required this.isLoaded});
  @override State<_GalleryBannerBar> createState() => _GalleryBannerBarState();
}
class _GalleryBannerBarState extends State<_GalleryBannerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _s;
  late final Animation<double> _a;
  @override void initState() {
    super.initState();
    _s = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _a = CurvedAnimation(parent: _s, curve: Curves.easeInOut);
  }
  @override void dispose() { _s.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final adH = (widget.bannerAd?.size.height?.toDouble() ?? 50.0).clamp(40.0, 90.0);
    return SafeArea(top: false,
        child: Container(
          height: adH + 10,
          decoration: BoxDecoration(
              color: _G.wallDeep,
              border: Border(top: BorderSide(
                  color: _G.gold.withOpacity(0.40), width: 2))),
          child: widget.isLoaded && widget.bannerAd != null
              ? Center(child: SizedBox(height: adH,
              width: widget.bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: widget.bannerAd!)))
              : AnimatedBuilder(animation: _a, builder: (_, __) {
            final t = _a.value;
            return Padding(padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 6),
                child: Row(children: [
                  Opacity(opacity: 0.5+t*0.5,
                      child: const Text('🖼️', style: TextStyle(fontSize: 18))),
                  const SizedBox(width: 10),
                  Expanded(child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(height: 28,
                          color: _G.gold.withOpacity(0.10+t*0.12),
                          alignment: Alignment.center,
                          child: Text('✨  Publicité  ✨',
                              style: TextStyle(fontFamily: 'Fredoka One', fontSize: 12,
                                  color: _G.gold.withOpacity(0.65+t*0.25)))))),
                  const SizedBox(width: 10),
                  Opacity(opacity: 0.5+t*0.5,
                      child: const Text('🖼️', style: TextStyle(fontSize: 18))),
                ]));
          }),
        ));
  }
}