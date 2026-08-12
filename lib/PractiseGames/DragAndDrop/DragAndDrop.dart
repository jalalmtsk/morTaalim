import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import 'package:mortaalim/tools/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import '../../XpSystem.dart';
import '../../tools/AD_Tools/adLabel.dart';
import '../../tools/Ads_Manager.dart';
import '../practiseWords.dart';

// ═══════════════════════════════════════════════════════════════
//  🎪 FRENCH CIRCUS — Drag & Drop Match
//  Theme: A vibrant circus tent! Drag the glowing word banner
//  onto the matching act poster (image tent).
//  Bold red + gold + purple + turquoise circus palette.
//  Timer preserved + best time trophy. Confetti on completion.
// ═══════════════════════════════════════════════════════════════
class _Z {
  static const red      = Color(0xFFDC2626);
  static const gold     = Color(0xFFD4A017);
  static const goldMid  = Color(0xFFF5D97E);
  static const purple   = Color(0xFF7B2FFF);
  static const teal     = Color(0xFF00D4AA);
  static const cream    = Color(0xFFFFF8F0);
  static const dark     = Color(0xFF1A0A0A);
  static const white    = Color(0xFFFFFFFF);

  // Banner colours per word (cycling)
  static const List<Color> bannerColors = [
    Color(0xFFDC2626), Color(0xFF7B2FFF),
    Color(0xFF0EA5E9), Color(0xFF22C55E),
    Color(0xFFD4A017), Color(0xFFEC4899),
  ];

  static const String font = 'Fredoka One';
}

// ═══════════════════════════════════════════════════════════════
//  TENT STRIPE PAINTER  (circus tent background)
// ═══════════════════════════════════════════════════════════════
class _TentBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stripeW = size.width / 8;
    for (int i = 0; i < 8; i++) {
      final paint = Paint()
        ..color = (i.isEven ? _Z.red : _Z.white).withOpacity(0.06)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
          Rect.fromLTWH(i * stripeW, 0, stripeW, size.height), paint);
    }
    // Top pennant strip
    final pennant = Paint()
      ..color = _Z.gold.withOpacity(0.14) ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 6), pennant);
  }
  @override bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════
//  LOADING OVERLAY
// ═══════════════════════════════════════════════════════════════
class _CircusLoader extends StatefulWidget {
  final String message;
  const _CircusLoader({required this.message});
  @override State<_CircusLoader> createState() => _CircusLoaderState();
}
class _CircusLoaderState extends State<_CircusLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  @override void initState() {
    super.initState();
    _spin = AnimationController(vsync: this,
        duration: const Duration(seconds: 1))..repeat();
  }
  @override void dispose() { _spin.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.black.withOpacity(0.68),
        child: Center(child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (_, v, child) =>
              Transform.scale(scale: v.clamp(0.0, 1.0), child: child),
          child: Container(
            width: 230,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFDC2626), Color(0xFF7B2FFF)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [BoxShadow(
                  color: _Z.red.withOpacity(0.55), blurRadius: 40)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedBuilder(animation: _spin,
                  builder: (_, __) => Transform.rotate(
                      angle: _spin.value * 2 * pi,
                      child: const Text('🎪', style: TextStyle(fontSize: 56)))),
              const SizedBox(height: 16),
              AnimatedBuilder(animation: _spin,
                  builder: (_, __) => Row(mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final dy = sin((_spin.value*2*pi)-i*pi/3)*6;
                        return Transform.translate(offset: Offset(0, dy),
                            child: Container(width: 10, height: 10,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                    color: _Z.bannerColors[i].withOpacity(0.90),
                                    shape: BoxShape.circle)));
                      }))),
              const SizedBox(height: 12),
              Text(widget.message, textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: _Z.font,
                      fontSize: 15, color: _Z.white)),
            ]),
          ),
        )));
  }
}

// ═══════════════════════════════════════════════════════════════
//  WORD BANNER  (draggable)
// ═══════════════════════════════════════════════════════════════
class _WordBanner extends StatelessWidget {
  final PractiseWords item;
  final Color color;
  final bool isMatched;
  const _WordBanner({required this.item, required this.color,
    required this.isMatched});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isMatched ? 0.30 : 1.0,
      duration: const Duration(milliseconds: 350),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMatched ? null : LinearGradient(
              colors: [
                Color.lerp(color, Colors.white, 0.20)!,
                color,
                Color.lerp(color, Colors.black, 0.18)!,
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
          color: isMatched ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isMatched ? Colors.grey.shade400 : Colors.white.withOpacity(0.50),
              width: 2),
          boxShadow: isMatched ? null : [
            BoxShadow(color: color.withOpacity(0.60),
                blurRadius: 10, offset: const Offset(0, 4)),
            BoxShadow(color: color.withOpacity(0.25),
                blurRadius: 18, spreadRadius: 1),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(item.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(item.word,
              style: TextStyle(
                fontFamily: _Z.font, fontSize: 16,
                color: isMatched ? Colors.grey.shade500 : _Z.white,
                shadows: isMatched ? null : const [
                  Shadow(color: Colors.black38, blurRadius: 4,
                      offset: Offset(0, 1))],
              )),
          if (isMatched) ...[
            const SizedBox(width: 6),
            const Text('✓', style: TextStyle(color: Colors.green,
                fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  IMAGE DROP TARGET  (the circus act poster / tent)
// ═══════════════════════════════════════════════════════════════
class _ImageTarget extends StatefulWidget {
  final PractiseWords item;
  final bool isMatched;
  final Color accentColor;
  final void Function(String word) onAccept;
  const _ImageTarget({required this.item, required this.isMatched,
    required this.accentColor, required this.onAccept});
  @override State<_ImageTarget> createState() => _ImageTargetState();
}
class _ImageTargetState extends State<_ImageTarget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;
  late final Animation<double>   _popScale;
  bool _isHovered = false;

  @override void initState() {
    super.initState();
    _pop = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _popScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0),  weight: 60),
    ]).animate(CurvedAnimation(parent: _pop, curve: Curves.easeOut));
  }
  @override void dispose() { _pop.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAccept: (_) { setState(() => _isHovered = true); return !widget.isMatched; },
      onLeave: (_)  { setState(() => _isHovered = false); },
      onAccept: (word) {
        setState(() => _isHovered = false);
        if (!widget.isMatched) {
          _pop.reset(); _pop.forward();
          widget.onAccept(word);
        }
      },
      builder: (ctx, candidates, _) {
        final hovering = candidates.isNotEmpty || _isHovered;

        return AnimatedBuilder(animation: _popScale,
          builder: (_, child) =>
              Transform.scale(scale: _popScale.value, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: widget.isMatched
                      ? const Color(0xFF22C55E)
                      : hovering
                      ? _Z.gold
                      : Colors.white.withOpacity(0.40),
                  width: widget.isMatched ? 3.5 : hovering ? 3 : 1.5),
              boxShadow: [
                BoxShadow(
                    color: widget.isMatched
                        ? const Color(0xFF22C55E).withOpacity(0.50)
                        : hovering
                        ? _Z.gold.withOpacity(0.55)
                        : Colors.black.withOpacity(0.15),
                    blurRadius: widget.isMatched || hovering ? 22 : 8,
                    offset: const Offset(0, 4)),
                if (hovering)
                  BoxShadow(color: _Z.gold.withOpacity(0.35), blurRadius: 30),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Stack(fit: StackFit.expand, children: [
                // Image
                Image.asset(widget.item.imagePath, fit: BoxFit.cover),

                // Hover glow overlay
                if (hovering && !widget.isMatched)
                  Container(color: _Z.gold.withOpacity(0.22)),

                // Matched overlay
                if (widget.isMatched)
                  Container(
                    color: const Color(0xFF22C55E).withOpacity(0.25),
                    alignment: Alignment.center,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Text('✓', style: TextStyle(
                              fontSize: 14, color: _Z.white,
                              fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Text(widget.item.word, style: const TextStyle(
                              fontFamily: _Z.font, fontSize: 13, color: _Z.white)),
                        ]),
                      ),
                    ]),
                  ),

                // Hovering prompt
                if (hovering && !widget.isMatched)
                  const Positioned(
                    bottom: 4,
                    child: Center(child: Text('⬇️ Lâche ici!',
                        style: TextStyle(fontFamily: _Z.font,
                            fontSize: 11, color: _Z.white))),
                  ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  MAIN WIDGET
// ═══════════════════════════════════════════════════════════════
class DragDropGame extends StatefulWidget {
  final List<PractiseWords> items;
  final int difficulty;
  const DragDropGame({super.key, required this.items, this.difficulty = 4});
  @override State<DragDropGame> createState() => _DragDropGameState();
}

class _DragDropGameState extends State<DragDropGame>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  final Map<String, String> _matched = {};
  late List<PractiseWords> _currentItems;
  final MusicPlayer _audioPlayer   = MusicPlayer();
  final MusicPlayer _bgMusic       = MusicPlayer();

  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  Duration _bestTime   = Duration.zero;
  bool _showLoader     = false;
  bool _showConfetti   = false;

  late AnimationController _bgCtrl;
  late AnimationController _entryCtrl;
  late Animation<double>   _entryFade;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _bgCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 8))..repeat();
    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600))..forward();
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _bgMusic.play("assets/audios/sound_track/SakuraGirl_bkG.mp3", loop: true);
    _bgMusic.setVolume(0.20);

    _startGame();
    _loadBannerAd();
  }

  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgCtrl.dispose(); _entryCtrl.dispose();
    _audioPlayer.dispose(); _bgMusic.dispose();
    _timer?.cancel();
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

  void _startGame() {
    _matched.clear();
    _showConfetti = false;
    final shuffled = [...widget.items]..shuffle();
    _currentItems = shuffled.take(widget.difficulty).toList();
    _stopwatch.reset();
    _stopwatch.start();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100),
            (_) { if (mounted) setState(() {}); });
    setState(() {});
  }

  Future<void> _playAudio(bool correct) async {
    await _audioPlayer.stop();
    _audioPlayer.setVolume(0.85);
    await _audioPlayer.play(correct
        ? 'assets/audios/QuizGame_Sounds/correct.mp3'
        : 'assets/audios/QuizGame_Sounds/incorrect.mp3');
  }

  void _checkCompletion() {
    if (_matched.length == _currentItems.length) {
      _stopwatch.stop();
      _timer?.cancel();

      final current = _stopwatch.elapsed;
      if (_bestTime == Duration.zero || current < _bestTime) {
        _bestTime = current;
      }
      HapticFeedback.heavyImpact();
      setState(() => _showConfetti = true);

      Future.delayed(const Duration(milliseconds: 500), _showCompletionDialog);
    }
  }

  void _showCompletionDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFF7B2FFF)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(
                color: _Z.red.withOpacity(0.50), blurRadius: 36)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎪', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 10),
            const Text('Bravo!', style: TextStyle(fontFamily: _Z.font,
                fontSize: 32, color: _Z.gold)),
            const SizedBox(height: 8),
            Text('Tu as tout associé!\nTemps: ${_formatTime(_stopwatch.elapsed)}',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: _Z.font, fontSize: 16,
                    color: Colors.white.withOpacity(0.85))),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 200), () {
                  setState(() => _showLoader = true);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _startGame();
                    setState(() => _showLoader = false);
                  });
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 14),
                decoration: BoxDecoration(
                    color: _Z.gold,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(
                        color: _Z.gold.withOpacity(0.55), blurRadius: 14)]),
                child: const Text('🎭 Rejouer!', style: TextStyle(
                    fontFamily: _Z.font, fontSize: 20, color: _Z.dark)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  String _formatTime(Duration d) =>
      "${d.inSeconds}.${(d.inMilliseconds % 1000 ~/ 100)}s";

  // ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final total = _currentItems.length;
    final done  = _matched.length;

    return Scaffold(
      backgroundColor: _Z.cream,
      bottomNavigationBar: context.watch<ExperienceManager>().adsEnabled
          ? FamilyAdBanner(bannerAd: _bannerAd, isLoaded: _isBannerAdLoaded)
          : null,
      body: Stack(children: [
        // Tent BG texture
        Positioned.fill(child: CustomPaint(painter: _TentBgPainter())),
        // Animated gradient wash
        AnimatedBuilder(animation: _bgCtrl,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [
                      Color.lerp(const Color(0xFFFFF8F0), const Color(0xFFFFF0E0),
                          sin(_bgCtrl.value * 2 * pi) * 0.5 + 0.5)!,
                      Color.lerp(const Color(0xFFF5F0FF), const Color(0xFFEDE8FF),
                          sin(_bgCtrl.value * 2 * pi + 1) * 0.5 + 0.5)!,
                      Color.lerp(const Color(0xFFFFF8F0), const Color(0xFFFFF2E8),
                          sin(_bgCtrl.value * 2 * pi + 2) * 0.5 + 0.5)!,
                    ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
            )),

        SafeArea(
          child: FadeTransition(opacity: _entryFade,
            child: Column(children: [
              _buildHeader(),
              const Padding(padding: EdgeInsets.fromLTRB(12, 6, 12, 0),
                  child: Userstatutbar()),
              const SizedBox(height: 8),
              _buildHUD(done, total),
              const SizedBox(height: 10),
              // Image drop targets
              Expanded(child: _buildTargetGrid()),
              // Draggable word banners
              _buildBannerRow(),
              const SizedBox(height: 12),
            ]),
          ),
        ),

        // Confetti
        if (_showConfetti)
          IgnorePointer(child: Align(alignment: Alignment.topCenter,
              child: SizedBox(width: double.infinity, height: 300,
                  child: Lottie.asset(
                      'assets/animations/QuizzGame_Animation/DoneAnimation.json',
                      repeat: false)))),

        if (_showLoader) const _CircusLoader(message: '🎪 Nouveau jeu...'),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFDC2626), Color(0xFF7B2FFF)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: _Z.red.withOpacity(0.45),
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
                  size: 17, color: _Z.white)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎪 Cirque des Mots!', style: TextStyle(
                  fontFamily: _Z.font, fontSize: 18, color: _Z.white,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 6)])),
              Text('Glisse le mot sur la bonne image!',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: _Z.goldMid.withOpacity(0.90))),
            ])),
        // Restart
        GestureDetector(
          onTap: _startGame,
          child: Container(width: 40, height: 40,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.40), width: 1.5)),
              child: const Icon(Icons.refresh_rounded, size: 20, color: _Z.white)),
        ),
      ]),
    );
  }

  Widget _buildHUD(int done, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _Z.gold.withOpacity(0.35), width: 1.2),
            boxShadow: [BoxShadow(color: _Z.gold.withOpacity(0.12),
                blurRadius: 10)]),
        child: Column(children: [
          Row(children: [
            Expanded(child: Row(children: [
              const Text('✅', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child:
              Text('$done / $total', style: const TextStyle(
                  fontFamily: _Z.font, fontSize: 14, color: _Z.dark)))),
            ])),
            Expanded(child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('⏱️', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child:
              Text(_formatTime(_stopwatch.elapsed),
                  style: const TextStyle(fontFamily: _Z.font,
                      fontSize: 14, color: _Z.dark)))),
            ]))),
            Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              const Text('🏆', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Flexible(child: FittedBox(fit: BoxFit.scaleDown, child:
              Text(_bestTime == Duration.zero ? '--' : _formatTime(_bestTime),
                  style: TextStyle(fontFamily: _Z.font, fontSize: 14,
                      color: _Z.gold)))),
            ])),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(children: [
              Container(height: 10, color: _Z.gold.withOpacity(0.15)),
              FractionallySizedBox(
                widthFactor: (done / total).clamp(0.0, 1.0),
                child: Container(height: 10,
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Color(0xFFDC2626), Color(0xFFD4A017), Color(0xFF22C55E)
                        ]))),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildTargetGrid() {
    final cols = _currentItems.length <= 4 ? 2 : 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: 12, mainAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: _currentItems.map((item) {
          final isMatched = _matched[item.imagePath] == item.word;
          return _ImageTarget(
            item:        item,
            isMatched:   isMatched,
            accentColor: _Z.bannerColors[_currentItems.indexOf(item) % _Z.bannerColors.length],
            onAccept: (word) async {
              if (word == item.word) {
                _matched[item.imagePath] = word;
                HapticFeedback.lightImpact();
                await _playAudio(true);
              } else {
                HapticFeedback.heavyImpact();
                await _playAudio(false);
              }
              setState(() {});
              _checkCompletion();
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBannerRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _Z.gold.withOpacity(0.35), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
              blurRadius: 10)]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Instruction chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
              color: _Z.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _Z.red.withOpacity(0.30), width: 1)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Text('👆', style: TextStyle(fontSize: 14)),
            SizedBox(width: 6),
            Text('Glisse le mot!', style: TextStyle(fontFamily: _Z.font,
                fontSize: 13, color: _Z.red)),
          ]),
        ),
        const SizedBox(height: 10),
        // Banners
        Wrap(
          spacing: 10, runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _currentItems.asMap().entries.map((entry) {
            final i    = entry.key;
            final item = entry.value;
            final isMatched = _matched.containsValue(item.word);
            final color = _Z.bannerColors[i % _Z.bannerColors.length];

            if (isMatched) {
              return _WordBanner(item: item, color: color, isMatched: true);
            }

            return Draggable<String>(
              data: item.word,
              feedback: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Color.lerp(color, Colors.white, 0.20)!,
                      color]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: color.withOpacity(0.70), blurRadius: 16)],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(item.word, style: const TextStyle(
                        fontFamily: _Z.font, fontSize: 18, color: _Z.white)),
                  ]),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.35,
                child: _WordBanner(item: item, color: color, isMatched: false),
              ),
              onDragStarted: () => HapticFeedback.selectionClick(),
              child: _WordBanner(item: item, color: color, isMatched: false),
            );
          }).toList(),
        ),
      ]),
    );
  }
}