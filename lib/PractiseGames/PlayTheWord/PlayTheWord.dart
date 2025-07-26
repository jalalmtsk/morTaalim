import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';

import '../../XpSystem.dart';
import '../../courses/primaire1Page/index_1PrimairePage.dart';
import '../../tools/Ads_Manager.dart';
import '../practiseWords.dart';

class PlayTheWord extends StatefulWidget {
  final List<PractiseWords> words;

  const PlayTheWord({super.key, required this.words});

  @override
  State<PlayTheWord> createState() => _PlayTheWordState();
}

class _PlayTheWordState extends State<PlayTheWord> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  final Set<String> learnedWords = {};
  PractiseWords? selectedWord;
  bool showImage = false;
  bool flashcardMode = false;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    initPrefs();
  }

  void _loadBannerAd() {
    _bannerAd?.dispose();
    _isBannerAdLoaded = false;
    _bannerAd = AdHelper.getBannerAd(() {
      setState(() => _isBannerAdLoaded = true);
    });
  }

  Future<void> initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    final savedWords = prefs.getStringList('learnedWords') ?? [];
    setState(() => learnedWords.addAll(savedWords));
  }

  Future<void> saveProgress() async {
    await prefs.setStringList('learnedWords', learnedWords.toList());
  }

  void playWord(PractiseWords word) async {
    await backGroundIndexMusic.play(word.audioPath);
    setState(() {
      selectedWord = word;
      learnedWords.add(word.word);
      showImage = !flashcardMode;
    });
    saveProgress();

  }

  void resetProgress() async {
    setState(() {
      learnedWords.clear();
      selectedWord = null;
      showImage = false;
    });
    await prefs.remove('learnedWords');
  }

  void toggleImage() {
    setState(() => showImage = !showImage);
  }

  @override
  void dispose() {
    backGroundIndexMusic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.words;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Play the Word'),
        actions: [
          IconButton(
            icon: Icon(flashcardMode ? Icons.grid_view : Icons.view_carousel),
            tooltip: flashcardMode ? 'Switch to Grid' : 'Switch to Flashcards',
            onPressed: () {
              setState(() {
                flashcardMode = !flashcardMode;
                showImage = false;
                selectedWord = null;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Userstatutbar(),
            buildProgressBar(words),
            const SizedBox(height: 8),
            Expanded(
              child: flashcardMode ? buildFlashcardMode(words) : buildGridMode(words),
            ),
            if (!flashcardMode && selectedWord != null && showImage)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Image.asset(
                      selectedWord!.imagePath,
                      key: ValueKey(selectedWord!.imagePath),
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: context.watch<ExperienceManager>().adsEnabled && _bannerAd != null && _isBannerAdLoaded
          ? SafeArea(
        child: SizedBox(
          height: _bannerAd!.size.height.toDouble(),
          width: _bannerAd!.size.width.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      )
          : null,
    );
  }

  Widget buildProgressBar(List<PractiseWords> words) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress: ${learnedWords.length} / ${words.length}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  IconButton(onPressed: resetProgress, icon: const Icon(Icons.refresh)),
                  if (!flashcardMode)
                    IconButton(
                      onPressed: toggleImage,
                      icon: Icon(showImage ? Icons.image : Icons.hide_image),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: words.isEmpty ? 0 : learnedWords.length / words.length,
            backgroundColor: Colors.grey.shade300,
            color: Colors.indigo,
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget buildGridMode(List<PractiseWords> words) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        final isLearned = learnedWords.contains(word.word);

        return InkWell(
          onTap: () => playWord(word),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLearned
                    ? [Colors.green.shade300, Colors.green.shade600]
                    : [Colors.blue.shade200, Colors.indigo.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: GridTile(
              footer: Center(
                child: Text(
                  word.word,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  word.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildFlashcardMode(List<PractiseWords> words) {
    return PageView.builder(
      itemCount: words.length,
      controller: PageController(viewportFraction: 0.85),
      itemBuilder: (context, index) {
        final word = words[index];
        final isLearned = learnedWords.contains(word.word);

        return GestureDetector(
          onTap: () => playWord(word),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.indigo.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(4, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    word.imagePath,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(word.emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text(
                  word.word,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                if (isLearned)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Icon(Icons.check_circle, color: Colors.green, size: 30),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}