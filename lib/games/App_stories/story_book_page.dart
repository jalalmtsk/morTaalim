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
import 'Stories.dart';
import 'story_page_widget.dart';

class StoryBookPage extends StatefulWidget {
  final Story story;

  const StoryBookPage({super.key, required this.story});

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

  // Added for text size control
  double _textSize = 35;

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
    _loadBannerAd();
    _pageController = PageController(initialPage: 0);
    _initTts();
    _loadPrefs();

    _audioPlayer = MusicPlayer();
    _confettiController = ConfettiController(duration: Duration(seconds: 3));

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _bounceAnimation = Tween(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _playBackgroundMusic();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    isNightMode = prefs.getBool('nightMode') ?? false;
    setState(() {});
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = AdHelper.getBannerAd(() {
      setState(() {});
    });
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
    } else if (type == 'adult_male') {
      await flutterTts.setPitch(0.9);
    }
    setState(() {});
  }

  void _toggleNightMode() async {
    setState(() => isNightMode = !isNightMode);
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('nightMode', isNightMode);
  }

  Future<void> _initTts() async {
    flutterTts.setStartHandler(() {
      setState(() {
        isPlaying = true;
        highlightedWordIndex = 0;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        isPlaying = false;
        highlightedWordIndex = widget.story.pages[currentPageIndex].words.length - 1;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        isPlaying = false;
      });
    });

    flutterTts.setProgressHandler((String text, int start, int end, String word) {
      final spokenText = text.substring(0, end);
      final spokenWords = spokenText.split(RegExp(r'\s+'));
      setState(() {
        highlightedWordIndex = (spokenWords.length - 1).clamp(0, widget.story.pages[currentPageIndex].words.length - 1);
      });
    });

    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.45);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speak() async {
    final text = widget.story.pages[currentPageIndex].fullText;
    if (text.isEmpty) return;

    if (isPlaying) {
      await flutterTts.stop();
      setState(() => isPlaying = false);
    } else {
      await flutterTts.speak(text);
    }
  }

  void _goToPage(int index) async {
    if (index < 0 || index >= widget.story.pages.length) return;
     _playFlipSound();

    if (isPlaying) {
      await flutterTts.stop();
    }

    if (index == widget.story.pages.length - 1) {
      _confettiController.play();
    }

    setState(() {
      currentPageIndex = index;
      highlightedWordIndex = 0;
      isPlaying = false;
    });

    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void _onCharacterTap() {
    final funnyLine = widget.story.pages[currentPageIndex].funnyLine;
    final characterName = widget.story.pages[currentPageIndex].characterName;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$characterName says: "$funnyLine"'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }

  void _increaseTextSize() {
    setState(() {
      if (_textSize < 50) _textSize += 2;
    });
  }

  void _decreaseTextSize() {
    setState(() {
      if (_textSize > 20) _textSize -= 2;
    });
  }

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

    return Scaffold(
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
            icon: Icon(
              voiceType == 'child_female'
                  ? Icons.child_care   // icon representing child voice
                  : Icons.record_voice_over_rounded, // icon for adult voice
              color: Colors.black87,
            ),
            tooltip: voiceType == 'child_female' ? 'Switch to Adult Voice' : 'Switch to Child Voice',
            onPressed: () {
              final newVoice = voiceType == 'child_female' ? 'adult_male' : 'child_female';
              _changeVoice(newVoice);
            },
          ),
          IconButton(
            icon: Icon(isNightMode ? Icons.nightlight_round : Icons.wb_sunny, color: Colors.black87),
            onPressed: _toggleNightMode,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                Image.asset(
                  isNightMode
                      ? 'assets/images/UI/BackGrounds/bg10.jpg'
                      : 'assets/images/UI/BackGrounds/bg10.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isNightMode
                          ? [Colors.black.withValues(alpha: 0.7), Colors.black.withValues(alpha: 0.3)]
                          : [Colors.white.withValues(alpha: 0.6), Colors.transparent],
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
                Text(
                  widget.story.title,
                  style: const TextStyle(
                      fontSize: 25,
                      color: Colors.deepOrange, fontWeight: FontWeight.bold),
                ),
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
                          color: isNightMode
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.95),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16,),
                        child: Column(
                          children: [
                            Expanded( flex: 1,
                              child: StoryPageWidget(
                                pageData: pages[index],
                                highlightedWordIndex: highlightedWordIndex,
                                isCurrentPage: index == currentPageIndex,
                                bounceAnimation: _bounceAnimation,
                                onCharacterTap: _onCharacterTap,
                                textSize: _textSize,
                              ),
                            ),
                            // Text size controls
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.text_decrease, color: Colors.deepOrange),
                                  onPressed: _decreaseTextSize,
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: const Icon(Icons.text_increase, color: Colors.deepOrange),
                                  onPressed: _increaseTextSize,
                                ),
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
                    color: isNightMode ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isNightMode
                        ? [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ]
                        : [
                      BoxShadow(
                        color: Colors.deepOrange.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 30),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new),
                            onPressed: currentPageIndex == 0 ? null : () => _goToPage(currentPageIndex - 1),
                            color: currentPageIndex == 0 ?
                            (isNightMode ? Colors.grey.shade700 : Colors.grey) : (isNightMode ? Colors.white : Colors.deepOrange),
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
                                    : LinearGradient(
                                  colors: isNightMode
                                      ? [Colors.grey.shade800, Colors.grey.shade700]
                                      : [Colors.grey.shade300, Colors.grey.shade200],
                                ),
                                boxShadow: isPlaying
                                    ? [
                                  BoxShadow(
                                    color: Colors.deepOrange.withValues(alpha: 0.5),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  )
                                ]
                                    : isNightMode
                                    ? [
                                  BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  )
                                ]
                                    : [],
                              ),
                              child: Icon(
                                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),

                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios),
                            onPressed: currentPageIndex == pages.length - 1 ? null : () => _goToPage(currentPageIndex + 1),
                            color: currentPageIndex == pages.length - 1  ? (isNightMode ? Colors.black : Colors.grey)
                                : (isNightMode ? Colors.white : Colors.deepOrange),
                          ),
                        ],
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
    );
  }
}
