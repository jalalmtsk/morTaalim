import 'dart:async';
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

class StoryBookPage extends StatefulWidget {
  final Story story;
  final AppLanguage language;

  const StoryBookPage({super.key, required this.story, this.language = AppLanguage.en});

  @override
  State<StoryBookPage> createState() => _StoryBookPageState();
}

class _StoryBookPageState extends State<StoryBookPage> with TickerProviderStateMixin {
  BannerAd? _bannerAd;
  late final PageController _pageController;
  final FlutterTts flutterTts = FlutterTts();

  int currentPageIndex = 0;
  int highlightedWordIndex = 0;
  bool isPlaying = false;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late MusicPlayer _audioPlayer;
  late ConfettiController _confettiController;

  bool isNightMode = false;
  String voiceType = 'child_female';
  double _textSize = 35;
  AppLanguage currentLanguage = AppLanguage.en;

  final List<Color> confettiColors = [
    Color(0xFF8ADA15),
    Color(0xFFFE418B),
    Color(0xFF6D6F22),
    Color(0xFF78D41C),
    Color(0xFF67DA85),
    Color(0xFF534CAA),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    currentLanguage = widget.language;

    _initTts();
    _loadPrefs();
    _loadLanguage();
    _loadBannerAd();

    _audioPlayer = MusicPlayer();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _bounceAnimation = Tween(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _playBackgroundMusic();
  }

  Future<void> _loadLanguage() async {
    final savedLang = await LanguageManager.getLanguage();
    setState(() => currentLanguage = savedLang);
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    isNightMode = prefs.getBool('nightMode') ?? false;
    setState(() {});
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = AdHelper.getBannerAd(() => setState(() {}));
  }

  Future<void> _playBackgroundMusic() async {
    _audioPlayer.setVolume(0.2);
    await _audioPlayer.play('assets/audios/sound_track/piano.mp3', loop: true);
  }

  Future<void> _playFlipSound() async {
    final MusicPlayer tempPlayer = MusicPlayer();
    await tempPlayer.play('assets/audios/sound_effects/transition.mp3');
  }

  Future<void> _changeVoice(String type) async {
    voiceType = type;
    if (type == 'child_female') {
      await flutterTts.setVoice({"name": "en-US-language", "locale": "en-US"});
      await flutterTts.setPitch(1.3);
    } else {
      await flutterTts.setPitch(0.9);
    }
    setState(() {});
  }

  void _toggleNightMode() async {
    setState(() => isNightMode = !isNightMode);
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('nightMode', isNightMode);
  }

  Future<void> speak(String text, AppLanguage lang) async {
    switch (lang) {
      case AppLanguage.en:
        await flutterTts.setLanguage("en-US");
        break;
      case AppLanguage.fr:
        await flutterTts.setLanguage("fr-FR");
        break;
      case AppLanguage.ar:
        await flutterTts.setLanguage("ar-SA");
        break;
      case AppLanguage.de:
        await flutterTts.setLanguage("de-DE");
        break;
      case AppLanguage.es:
        await flutterTts.setLanguage("es-ES");
        break;
      case AppLanguage.amazigh:
        await flutterTts.setLanguage("fr-FR"); // No native TTS, fallback
        break;
      case AppLanguage.ru:
        await flutterTts.setLanguage("ru-RU");
        break;
      case AppLanguage.it:
        await flutterTts.setLanguage("it-IT");
        break;
      case AppLanguage.zh:
        await flutterTts.setLanguage("zh-CN"); // or zh-TW for Traditional
        break;
      case AppLanguage.ko:
        await flutterTts.setLanguage("ko-KR");
        break;
    }
    await flutterTts.speak(text);
  }


  void _initTts() {
    flutterTts.setStartHandler(() {
      setState(() {
        isPlaying = true;
        highlightedWordIndex = 0;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        isPlaying = false;
        final words = widget.story.pages[currentPageIndex].getWords(currentLanguage);
        highlightedWordIndex = words.length - 1;
      });
    });

    flutterTts.setCancelHandler(() => setState(() => isPlaying = false));

    flutterTts.setProgressHandler((text, start, end, word) {
      final spokenWords = text.substring(0, end).split(RegExp(r'\s+'));
      final words = widget.story.pages[currentPageIndex].getWords(currentLanguage);
      setState(() => highlightedWordIndex = (spokenWords.length - 1).clamp(0, words.length - 1));
    });

    flutterTts.setLanguage('en-US');
    flutterTts.setSpeechRate(0.45);
    flutterTts.setPitch(1.0);
  }

  Future<void> _speak() async {
    final words = widget.story.pages[currentPageIndex].getWords(currentLanguage);
    final text = words.join(' ');
    if (text.isEmpty) return;
    if (isPlaying) {
      await flutterTts.stop();
      setState(() => isPlaying = false);
    } else {
      await speak(text, currentLanguage);
    }
  }

  void _goToPage(int index) async {
    if (index < 0 || index >= widget.story.pages.length) return;
    _playFlipSound();
    if (isPlaying) await flutterTts.stop();

    if (index == widget.story.pages.length - 1) _confettiController.play();

    setState(() {
      currentPageIndex = index;
      highlightedWordIndex = 0;
      isPlaying = false;
    });

    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void _onCharacterTap() {
    final page = widget.story.pages[currentPageIndex];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${page.characterName} says: "${page.funnyLine}"'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }

  void _increaseTextSize() { if (_textSize < 50) setState(() => _textSize += 2); }
  void _decreaseTextSize() { if (_textSize > 20) setState(() => _textSize -= 2); }

  @override
  void dispose() {
    _bounceController.dispose();
    _bannerAd?.dispose();
    flutterTts.stop();
    _pageController.dispose();
    _audioPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.story.pages;
    final isRtl = currentLanguage == AppLanguage.ar || currentLanguage == AppLanguage.amazigh;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isNightMode ? const Color(0xFF121212) : const Color(0xFFFFF3E0),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(voiceType == 'child_female' ? Icons.child_care : Icons.record_voice_over_rounded),
              tooltip: voiceType == 'child_female' ? 'Switch to Adult Voice' : 'Switch to Child Voice',
              onPressed: () {
                _changeVoice(voiceType == 'child_female' ? 'adult_male' : 'child_female');
              },
            ),
            IconButton(
              icon: Icon(isNightMode ? Icons.nightlight_round : Icons.wb_sunny, color: Colors.black87),
              onPressed: _toggleNightMode,
            ),
            PopupMenuButton<AppLanguage>(
              icon: const Icon(Icons.language, color: Colors.black87),
              onSelected: (lang) {
                setState(() {
                  currentLanguage = lang;
                  LanguageManager.setLanguage(lang);
                });
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: AppLanguage.en, child: Text("English")),
                PopupMenuItem(value: AppLanguage.fr, child: Text("Français")),
                PopupMenuItem(value: AppLanguage.ar, child: Text("العربية")),
                PopupMenuItem(value: AppLanguage.de, child: Text("Deutch")),
                PopupMenuItem(value: AppLanguage.es, child: Text("Spanish")),
                PopupMenuItem(value: AppLanguage.amazigh, child: Text("Amazigh")),
                PopupMenuItem(value: AppLanguage.it, child: Text("Italian")),
                PopupMenuItem(value: AppLanguage.ko, child: Text("Korean")),
                PopupMenuItem(value: AppLanguage.ru, child: Text("Russian")),
                PopupMenuItem(value: AppLanguage.zh, child: Text("Chinese")),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Stack(
                children: [
                  Image.asset(
                    'assets/images/UI/BackGrounds/bg10.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isNightMode
                            ? [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.3)]
                            : [Colors.white.withOpacity(0.6), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: confettiColors,
                gravity: 0.3,
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Userstatutbar(),
                  Text(widget.story.title,
                      style: const TextStyle(fontSize: 25, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: PageView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      controller: _pageController,
                      itemCount: pages.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: isNightMode ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.95),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 15, offset: const Offset(0, 6))
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              Expanded(
                                child: StoryPageWidget(
                                  pageData: pages[index],
                                  highlightedWordIndex: highlightedWordIndex,
                                  isCurrentPage: index == currentPageIndex,
                                  bounceAnimation: _bounceAnimation,
                                  onCharacterTap: _onCharacterTap,
                                  textSize: _textSize,
                                  language: currentLanguage,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(icon: const Icon(Icons.text_decrease, color: Colors.deepOrange), onPressed: _decreaseTextSize),
                                  const SizedBox(width: 16),
                                  IconButton(icon: const Icon(Icons.text_increase, color: Colors.deepOrange), onPressed: _increaseTextSize),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: LinearProgressIndicator(
                      value: (currentPageIndex + 1) / pages.length,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepOrangeAccent),
                      minHeight: 6,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isNightMode ? Colors.white.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isNightMode
                          ? [const BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 6))]
                          : [BoxShadow(color: Colors.deepOrange.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new),
                          onPressed: currentPageIndex == 0 ? null : () => _goToPage(currentPageIndex - 1),
                          color: currentPageIndex == 0 ? (isNightMode ? Colors.grey.shade700 : Colors.grey) : (isNightMode ? Colors.white : Colors.deepOrange),
                        ),
                        GestureDetector(
                          onTap: _speak,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isPlaying
                                  ? const LinearGradient(colors: [Colors.deepOrange, Colors.orangeAccent])
                                  : LinearGradient(colors: isNightMode ? [Colors.grey.shade800, Colors.grey.shade700] : [Colors.grey.shade300, Colors.grey.shade200]),
                              boxShadow: isPlaying
                                  ? [BoxShadow(color: Colors.deepOrange.withOpacity(0.5), blurRadius: 12, spreadRadius: 2)]
                                  : isNightMode
                                  ? const [BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3))]
                                  : [],
                            ),
                            child: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white, size: 28),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          onPressed: currentPageIndex == pages.length - 1 ? null : () => _goToPage(currentPageIndex + 1),
                          color: currentPageIndex == pages.length - 1 ? (isNightMode ? Colors.black : Colors.grey) : (isNightMode ? Colors.white : Colors.deepOrange),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: context.watch<ExperienceManager>().adsEnabled && _bannerAd != null
            ? SafeArea(
          child: Container(
            padding: const EdgeInsets.only(bottom: 4),
            color: Colors.transparent,
            height: _bannerAd!.size.height.toDouble(),
            width: _bannerAd!.size.width.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        )
            : null,
      ),
    );
  }
}
