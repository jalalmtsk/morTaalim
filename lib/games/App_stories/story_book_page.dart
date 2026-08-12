import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mortaalim/tools/Ads_Manager.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../XpSystem.dart';
import 'LanguageManager.dart';
import 'Stories.dart';
import 'story_page_widget.dart';
import 'story_quiz_page.dart';

// ─── Read speed ───────────────────────────────────────────────────────────────
enum ReadSpeed { slow, normal, fast }
extension ReadSpeedExt on ReadSpeed {
  double get rate => const [0.30, 0.48, 0.70][index];
  String get label => const ['🐢', '🐇', '🚀'][index];
}

// ─── Per-story theme ──────────────────────────────────────────────────────────
class StoryTheme {
  final List<Color> dayGradient;
  final List<Color> nightGradient;
  final Color accent;
  const StoryTheme({required this.dayGradient, required this.nightGradient, required this.accent});
}

const List<StoryTheme> kStoryThemes = [
  StoryTheme(
    dayGradient:   [Color(0xFFFFF3E0), Color(0xFFFFE0B2), Color(0xFFFFCC80)],
    nightGradient: [Color(0xFF1A0A00), Color(0xFF2C1200), Color(0xFF3E1A00)],
    accent: Color(0xFFFF7043),
  ),
  StoryTheme(
    dayGradient:   [Color(0xFFF1F8E9), Color(0xFFDCEDC8), Color(0xFFC5E1A5)],
    nightGradient: [Color(0xFF0A1200), Color(0xFF0D1F00), Color(0xFF142800)],
    accent: Color(0xFF43A047),
  ),
  StoryTheme(
    dayGradient:   [Color(0xFFE3F2FD), Color(0xFFBBDEFB), Color(0xFF90CAF9)],
    nightGradient: [Color(0xFF000D1A), Color(0xFF001933), Color(0xFF002347)],
    accent: Color(0xFF1E88E5),
  ),
];

StoryTheme themeFor(int i) => kStoryThemes[i % kStoryThemes.length];

// ═════════════════════════════════════════════════════════════════════════════
class StoryBookPage extends StatefulWidget {
  final Story story;
  final AppLanguage language;
  final int storyIndex;

  const StoryBookPage({
    super.key,
    required this.story,
    this.language = AppLanguage.en,
    this.storyIndex = 0,
  });

  @override
  State<StoryBookPage> createState() => _StoryBookPageState();
}

class _StoryBookPageState extends State<StoryBookPage> with TickerProviderStateMixin {
  BannerAd? _bannerAd;
  late final PageController _pageController;

  // ── TTS state ─────────────────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();
  // BUG FIX 3: single source of truth for playing state,
  // updated synchronously BEFORE any async tts call
  bool _isPlaying = false;
  int _highlightedWordIndex = -1;
  String voiceType = 'child_female';
  ReadSpeed _readSpeed = ReadSpeed.normal;

  int _currentPageIndex = 0;
  bool isNightMode = false;
  double _textSize = 32;
  AppLanguage _lang = AppLanguage.en;

  // ── Animations ────────────────────────────────────────────────────────────
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _isFlipping = false;
  late AnimationController _completionCtrl;
  late Animation<double> _completionScale;
  bool _showCompletion = false;
  int _starRating = 0;
  late AnimationController _bubbleCtrl;
  late Animation<double> _bubbleScale;
  bool _showBubble = false;
  String _bubbleText = '';

  late ConfettiController _confetti;
  late MusicPlayer _music;
  bool _isBannerAdLoaded = false;   // ← add this

  String get _progressKey => 'progress_${widget.story.title}';
  StoryTheme get _theme => themeFor(widget.storyIndex);
  Color get _nightText => isNightMode ? const Color(0xFFFFF3E0) : const Color(0xFF3E1A00);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _lang = widget.language;
    _initTts();
    _loadPrefs();
    _loadLanguage();
    _loadBannerAd();
    _restoreProgress();

    _music = MusicPlayer();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));

    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _bounceAnim = Tween(begin: 0.0, end: -10.0)
        .animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _flipAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));

    _completionCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _completionScale = CurvedAnimation(parent: _completionCtrl, curve: Curves.elasticOut);

    _bubbleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _bubbleScale = CurvedAnimation(parent: _bubbleCtrl, curve: Curves.elasticOut);

    _playBgMusic();
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _flipCtrl.dispose();
    _completionCtrl.dispose();
    _bubbleCtrl.dispose();
    _confetti.dispose();
    _bannerAd?.dispose();
    _tts.stop();
    _pageController.dispose();
    _music.dispose();
    super.dispose();
  }

  // ── Prefs ──────────────────────────────────────────────────────────────────
  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => isNightMode = p.getBool('nightMode') ?? false);
  }

  Future<void> _loadLanguage() async {
    final l = await LanguageManager.getLanguage();
    if (mounted) setState(() => _lang = l);
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _isBannerAdLoaded = false;
    _bannerAd = AdHelper.getBannerAd(() {
      if (mounted) setState(() => _isBannerAdLoaded = true);
    });
  }

  Future<void> _restoreProgress() async {
    final p = await SharedPreferences.getInstance();
    final saved = p.getInt(_progressKey) ?? 0;
    if (saved > 0 && saved < widget.story.pages.length && mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _showContinueDialog(saved);
    }
  }

  void _showContinueDialog(int page) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: isNightMode ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _theme.accent.withOpacity(0.4), width: 2),
              ),
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('📖', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 10),
                Text('Continue reading?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _nightText)),
                const SizedBox(height: 6),
                Text('You were on page ${page + 1}',
                    style: TextStyle(fontSize: 14, color: _nightText.withOpacity(0.6))),
                const SizedBox(height: 22),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _nightText,
                        side: BorderSide(color: _theme.accent.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Start over'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _theme.accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () { Navigator.pop(context); _goToPage(page, skipSave: true); },
                      child: const Text('Continue', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProgress(int page) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_progressKey, page);
  }

  // ── TTS ─────────────────────────────────────────────────────────────────────
  // BUG FIX 3 ROOT CAUSE: FlutterTts handlers fire on a background isolate.
  // setState from them is fine BUT the handler references can become stale.
  // Solution: re-register handlers every time we call speak(), never rely on
  // initState-registered handlers for the isPlaying flag.
  void _initTts() {
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(_readSpeed.rate);
    _tts.setPitch(voiceType == 'child_female' ? 1.3 : 0.9);

    // Progress handler: advances highlighted word index
    // BUG FIX 2: this correctly drives highlighting, but only works if
    // StoryPageWidget re-renders when _highlightedWordIndex changes.
    _tts.setProgressHandler((text, start, end, word) {
      if (!mounted) return;
      final words = widget.story.pages[_currentPageIndex].getWords(_lang);
      // Count words spoken so far by splitting the text up to 'end'
      final spokenText = text.substring(0, end);
      final spokenCount = spokenText.trim().split(RegExp(r'\s+')).length;
      final newIndex = (spokenCount - 1).clamp(0, words.length - 1);
      if (newIndex != _highlightedWordIndex) {
        setState(() => _highlightedWordIndex = newIndex);
      }
    });

    _tts.setCompletionHandler(() {
      if (!mounted) return;
      final isLast = _currentPageIndex == widget.story.pages.length - 1;
      setState(() {
        _isPlaying = false;
        _highlightedWordIndex = widget.story.pages[_currentPageIndex].getWords(_lang).length - 1;
      });
      if (isLast) Future.delayed(const Duration(milliseconds: 900), _triggerCompletion);
    });

    _tts.setCancelHandler(() {
      if (!mounted) return;
      setState(() => _isPlaying = false);
    });

    _tts.setErrorHandler((_) {
      if (!mounted) return;
      setState(() => _isPlaying = false);
    });
  }

  String _ttsLang(AppLanguage l) {
    switch (l) {
      case AppLanguage.fr:      return 'fr-FR';
      case AppLanguage.ar:      return 'ar-SA';
      case AppLanguage.de:      return 'de-DE';
      case AppLanguage.es:      return 'es-ES';
      case AppLanguage.amazigh: return 'fr-FR';
      case AppLanguage.ru:      return 'ru-RU';
      case AppLanguage.it:      return 'it-IT';
      case AppLanguage.zh:      return 'zh-CN';
      case AppLanguage.ko:      return 'ko-KR';
      default:                  return 'en-US';
    }
  }

  // BUG FIX 3: set _isPlaying synchronously so the button redraws immediately,
  // then await the TTS call so the handler doesn't race with our state.
  Future<void> _speak() async {
    if (_isFlipping) return;
    if (_isPlaying) {
      // ── PAUSE ──
      setState(() => _isPlaying = false); // immediate UI update
      await _tts.stop();
      return;
    }
    // ── PLAY ──
    final words = widget.story.pages[_currentPageIndex].getWords(_lang);
    final text  = words.join(' ');
    if (text.trim().isEmpty) return;
    setState(() {
      _isPlaying = true;
      _highlightedWordIndex = 0;
    });
    await _tts.setLanguage(_ttsLang(_lang));
    await _tts.setSpeechRate(_readSpeed.rate);
    await _tts.setPitch(voiceType == 'child_female' ? 1.3 : 0.9);
    await _tts.speak(text);
  }

  void _cycleSpeed() {
    setState(() => _readSpeed = ReadSpeed.values[(_readSpeed.index + 1) % 3]);
    _tts.setSpeechRate(_readSpeed.rate);
  }

  void _changeVoice() async {
    voiceType = voiceType == 'child_female' ? 'adult_male' : 'child_female';
    await _tts.setPitch(voiceType == 'child_female' ? 1.3 : 0.9);
    setState(() {});
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  Future<void> _goToPage(int index, {bool skipSave = false}) async {
    if (index < 0 || index >= widget.story.pages.length || _isFlipping) return;
    if (_isPlaying) {
      setState(() => _isPlaying = false);
      await _tts.stop();
    }
    MusicPlayer().play('assets/audios/sound_effects/transition.mp3');
    setState(() { _isFlipping = true; });
    await _flipCtrl.forward(from: 0);
    _pageController.jumpToPage(index);
    await _flipCtrl.reverse();
    setState(() {
      _currentPageIndex = index;
      _highlightedWordIndex = -1;
      _isFlipping = false;
      _showCompletion = false;
    });
    if (!skipSave) _saveProgress(index);
  }

  // ── Completion ─────────────────────────────────────────────────────────────
  void _triggerCompletion() {
    if (!mounted || _showCompletion) return;
    _confetti.play();
    setState(() { _showCompletion = true; _starRating = 0; });
    _completionCtrl.forward(from: 0);
  }

  // ── Character bubble ───────────────────────────────────────────────────────
  void _onCharacterTap() async {
    if (_showBubble) return;
    final page = widget.story.pages[_currentPageIndex];
    setState(() {
      _bubbleText = '${page.characterName}: "${page.funnyLine}"';
      _showBubble = true;
    });
    _bubbleCtrl.forward(from: 0);
    await _tts.setLanguage(_ttsLang(_lang));
    await _tts.setPitch(1.4);
    await _tts.speak(page.funnyLine);
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) {
      await _bubbleCtrl.reverse();
      setState(() => _showBubble = false);
    }
  }

  void _toggleNightMode() async {
    setState(() => isNightMode = !isNightMode);
    (await SharedPreferences.getInstance()).setBool('nightMode', isNightMode);
  }

  void _increaseTextSize() { if (_textSize < 52) setState(() => _textSize += 2); }
  void _decreaseTextSize() { if (_textSize > 18) setState(() => _textSize -= 2); }

  Future<void> _playBgMusic() async {
    _music.setVolume(0.15);
    await _music.play('assets/audios/sound_track/piano.mp3', loop: true);
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final pages = widget.story.pages;
    final isRtl = _lang == AppLanguage.ar || _lang == AppLanguage.amazigh;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            // Gradient background
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isNightMode ? _theme.nightGradient : _theme.dayGradient,
                ),
              ),
            ),
            if (isNightMode) ..._buildStars(),

            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Color(0xFFFF6B6B), Color(0xFFFFD93D), Color(0xFF6BCB77),
                  Color(0xFF4D96FF), Color(0xFFFF922B), Color(0xFFCC5DE8),
                ],
                gravity: 0.25, numberOfParticles: 40,
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  const Userstatutbar(),
                  const SizedBox(height: 4),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      widget.story.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900,
                        color: _theme.accent,
                        shadows: [Shadow(color: _theme.accent.withOpacity(0.3), blurRadius: 8)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Page view with flip
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _flipAnim,
                      builder: (_, child) => Transform(
                        alignment: Alignment.centerRight,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(_flipAnim.value * pi / 2),
                        child: Opacity(
                          opacity: (1 - _flipAnim.value).clamp(0.0, 1.0),
                          child: child,
                        ),
                      ),
                      child: PageView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        controller: _pageController,
                        itemCount: pages.length,
                        itemBuilder: (_, index) => _buildPageCard(pages, index),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  _DotProgress(total: pages.length, current: _currentPageIndex, accent: _theme.accent),
                  const SizedBox(height: 8),
                  _buildControls(pages),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            if (_showBubble) _buildSpeechBubble(),
            if (_showCompletion) _buildCompletionOverlay(),
          ],
        ),
        bottomNavigationBar: context.watch<ExperienceManager>().adsEnabled
            ? FamilyAdBanner(bannerAd: _bannerAd, isLoaded: _isBannerAdLoaded)
            : null,
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    final iconColor = isNightMode ? Colors.white70 : _theme.accent;
    return AppBar(
      backgroundColor: Colors.transparent, elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconColor),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        GestureDetector(
          onTap: _cycleSpeed,
          child: Container(
            margin: const EdgeInsets.only(right: 4, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _theme.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_readSpeed.label, style: const TextStyle(fontSize: 20)),
          ),
        ),
        IconButton(
          icon: Icon(voiceType == 'child_female' ? Icons.child_care : Icons.record_voice_over_rounded, color: iconColor),
          onPressed: _changeVoice,
        ),
        IconButton(
          icon: Icon(
            isNightMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
            color: isNightMode ? const Color(0xFFFFD93D) : _theme.accent,
          ),
          onPressed: _toggleNightMode,
        ),
        PopupMenuButton<AppLanguage>(
          icon: Icon(Icons.translate_rounded, color: iconColor),
          onSelected: (l) { setState(() => _lang = l); LanguageManager.setLanguage(l); },
          itemBuilder: (_) => const [
            PopupMenuItem(value: AppLanguage.en,      child: Text('🇬🇧 English')),
            PopupMenuItem(value: AppLanguage.fr,      child: Text('🇫🇷 Français')),
            PopupMenuItem(value: AppLanguage.ar,      child: Text('🇸🇦 العربية')),
            PopupMenuItem(value: AppLanguage.de,      child: Text('🇩🇪 Deutsch')),
            PopupMenuItem(value: AppLanguage.es,      child: Text('🇪🇸 Español')),
            PopupMenuItem(value: AppLanguage.amazigh, child: Text('🇲🇦 Amazigh')),
            PopupMenuItem(value: AppLanguage.it,      child: Text('🇮🇹 Italiano')),
            PopupMenuItem(value: AppLanguage.ko,      child: Text('🇰🇷 한국어')),
            PopupMenuItem(value: AppLanguage.ru,      child: Text('🇷🇺 Русский')),
            PopupMenuItem(value: AppLanguage.zh,      child: Text('🇨🇳 中文')),
          ],
        ),
      ],
    );
  }

  // ── Page card ──────────────────────────────────────────────────────────────
  Widget _buildPageCard(List pages, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: isNightMode ? const Color(0xFF1E1410).withOpacity(0.92) : Colors.white.withOpacity(0.94),
          boxShadow: [
            BoxShadow(color: _theme.accent.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 8)),
          ],
          border: Border.all(color: _theme.accent.withOpacity(0.25), width: 2),
        ),
        child: Column(
          children: [
            Expanded(
              child: StoryPageWidget(
                pageData: widget.story.pages[index],
                // BUG FIX 2: only pass highlightedWordIndex for the ACTIVE page
                // other pages get -1 so nothing is highlighted when not current
                highlightedWordIndex: index == _currentPageIndex ? _highlightedWordIndex : -1,
                isCurrentPage: index == _currentPageIndex,
                bounceAnimation: _bounceAnim,
                onCharacterTap: _onCharacterTap,
                textSize: _textSize,
                language: _lang,
                nightMode: isNightMode,
                accentColor: _theme.accent,
              ),
            ),
            // Text size row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SmallIconBtn(icon: Icons.text_decrease_rounded, color: _theme.accent, onTap: _decreaseTextSize),
                  const SizedBox(width: 16),
                  Text('Aa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _theme.accent.withOpacity(0.6))),
                  const SizedBox(width: 16),
                  _SmallIconBtn(icon: Icons.text_increase_rounded, color: _theme.accent, onTap: _increaseTextSize),
                ],
              ),
            ),
            // Done button on last page
            if (index == pages.length - 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _theme.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 6,
                    shadowColor: _theme.accent.withOpacity(0.4),
                  ),
                  icon: const Text('🎉', style: TextStyle(fontSize: 18)),
                  label: const Text("I'm done reading!",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: _showCompletion ? null : _triggerCompletion,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Controls ───────────────────────────────────────────────────────────────
  Widget _buildControls(List pages) {
    // BUG FIX 3: reading _isPlaying directly in build gives the correct icon
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
      decoration: BoxDecoration(
        color: isNightMode ? const Color(0xFF2C1A0A).withOpacity(0.85) : Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: _theme.accent.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavBtn(
            icon: Icons.arrow_back_ios_rounded,
            enabled: _currentPageIndex > 0,
            color: _theme.accent, nightMode: isNightMode,
            onTap: () => _goToPage(_currentPageIndex - 1),
          ),

          // Play/Pause — uses _isPlaying directly
          GestureDetector(
            onTap: _speak,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isPlaying
                    ? LinearGradient(colors: [_theme.accent, _theme.accent.withOpacity(0.75)])
                    : LinearGradient(colors: isNightMode
                    ? [const Color(0xFF3E2010), const Color(0xFF2A1500)]
                    : [Colors.grey.shade200, Colors.grey.shade100]),
                boxShadow: _isPlaying
                    ? [BoxShadow(color: _theme.accent.withOpacity(0.55), blurRadius: 16, spreadRadius: 2)]
                    : [],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  // BUG FIX 3: key forces AnimatedSwitcher to animate between icons
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey(_isPlaying),
                  color: _isPlaying ? Colors.white : (isNightMode ? Colors.white54 : Colors.grey.shade500),
                  size: 32,
                ),
              ),
            ),
          ),

          _NavBtn(
            icon: Icons.arrow_forward_ios_rounded,
            enabled: _currentPageIndex < pages.length - 1,
            color: _theme.accent, nightMode: isNightMode,
            onTap: () => _goToPage(_currentPageIndex + 1),
          ),
        ],
      ),
    );
  }

  // ── Speech bubble ──────────────────────────────────────────────────────────
  Widget _buildSpeechBubble() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.20,
      left: 20, right: 20,
      child: ScaleTransition(
        scale: _bubbleScale,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isNightMode ? const Color(0xFF2C1A0A) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24),
              bottomRight: Radius.circular(24), bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: _theme.accent, width: 2.5),
            boxShadow: [BoxShadow(color: _theme.accent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💬', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_bubbleText,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _nightText, height: 1.4)),
            ),
            GestureDetector(
              onTap: () async {
                await _bubbleCtrl.reverse();
                setState(() => _showBubble = false);
              },
              child: Icon(Icons.close_rounded, size: 18, color: _theme.accent),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Completion overlay ─────────────────────────────────────────────────────
  Widget _buildCompletionOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: Center(
          child: ScaleTransition(
            scale: _completionScale,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: isNightMode
                      ? [const Color(0xFF1A0A00), const Color(0xFF2C1200)]
                      : [const Color(0xFFFFF8F0), const Color(0xFFFFECCC)],
                ),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: _theme.accent, width: 2.5),
                boxShadow: [BoxShadow(color: _theme.accent.withOpacity(0.4), blurRadius: 30)],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🎉', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text('Story Complete!',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _theme.accent)),
                const SizedBox(height: 4),
                Text(widget.story.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: _nightText.withOpacity(0.7))),
                const SizedBox(height: 18),
                Text('Rate this story!',
                    style: TextStyle(fontSize: 14, color: _nightText.withOpacity(0.6))),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => GestureDetector(
                    onTap: () => setState(() => _starRating = i + 1),
                    child: AnimatedScale(
                      scale: _starRating > i ? 1.35 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(_starRating > i ? '⭐' : '☆', style: const TextStyle(fontSize: 36)),
                    ),
                  )),
                ),
                const SizedBox(height: 22),
                // Quiz button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 6,
                    ),
                    icon: const Text('🧠', style: TextStyle(fontSize: 20)),
                    label: const Text('Take the Quiz! +XP',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    onPressed: () {
                      setState(() => _showCompletion = false);
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => StoryQuizPage(story: widget.story, language: _lang, accentColor: _theme.accent),
                      ));
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _theme.accent,
                        side: BorderSide(color: _theme.accent, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Read Again', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () { setState(() => _showCompletion = false); _goToPage(0, skipSave: true); },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _theme.accent,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 6,
                      ),
                      icon: const Icon(Icons.library_books_rounded, color: Colors.white),
                      label: const Text('More Stories',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStars() {
    final rng = Random(42);
    final size = MediaQuery.of(context).size;
    return List.generate(24, (i) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.5;
      final s = rng.nextDouble() * 3 + 1;
      return Positioned(
        left: x, top: y,
        child: Container(
          width: s, height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(rng.nextDouble() * 0.6 + 0.2),
          ),
        ),
      );
    });
  }
}

// ── Dot progress ───────────────────────────────────────────────────────────────
class _DotProgress extends StatelessWidget {
  final int total, current;
  final Color accent;
  const _DotProgress({required this.total, required this.current, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: active ? 28 : 10, height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: active ? accent : accent.withOpacity(0.25),
            boxShadow: active ? [BoxShadow(color: accent.withOpacity(0.45), blurRadius: 8)] : [],
          ),
        );
      }),
    );
  }
}

class _SmallIconBtn extends StatelessWidget {
  final IconData icon; final Color color; final VoidCallback onTap;
  const _SmallIconBtn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon; final bool enabled, nightMode; final Color color; final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.enabled, required this.color, required this.nightMode, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.12) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 26,
            color: enabled ? color : (nightMode ? Colors.white12 : Colors.grey.shade300)),
      ),
    );
  }
}