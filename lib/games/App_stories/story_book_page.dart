import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mortaalim/games/App_stories/story_page_data.dart';
import 'package:mortaalim/games/App_stories/story_page_widget.dart';



class StoryBookPage extends StatefulWidget {
  const StoryBookPage({super.key});

  @override
  State<StoryBookPage> createState() => _StoryBookPageState();
}

class _StoryBookPageState extends State<StoryBookPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final FlutterTts flutterTts = FlutterTts();

  final List<StoryPageData> pages = [
    StoryPageData(
      words: [
        'Once', 'upon', 'a', 'time,', 'there', 'was', 'a', 'silly', 'fox',
        'named', 'Flick,', 'who', 'loved', 'to', 'dance', 'in', 'the', 'rain.'
      ],
      imageUrl: 'https://i.imgur.com/xO4rLyD.png',
      characterName: 'Flick',
      funnyLine: 'Oops! He slipped and did a funny twirl!',
    ),
    StoryPageData(
      words: [
        'Flick', 'decided', 'to', 'invite', 'his', 'best', 'friend,', 'Benny', 'the', 'bunny,',
        'to', 'join', 'the', 'rain', 'dance', 'party.'
      ],
      imageUrl: 'https://i.imgur.com/MT2Hg6P.png',
      characterName: 'Benny',
      funnyLine: 'Benny tried to hop but ended up splashing mud everywhere!',
    ),
    StoryPageData(
      words: [
        'Together,', 'they', 'danced', 'and', 'laughed,', 'making', 'the', 'forest', 'a', 'happier', 'place.',
        'Suddenly,', 'a', 'rainbow', 'appeared,', 'and', 'Flick', 'wished', 'for', 'more', 'adventures.'
      ],
      imageUrl: 'https://i.imgur.com/PMjRJ9N.png',
      characterName: 'Flick & Benny',
      funnyLine: 'Rainbow magic made Benny\'s ears glow bright pink!',
    ),
  ];

  int currentPageIndex = 0;
  int highlightedWordIndex = 0;
  bool isPlaying = false;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _initTts();
    _bounceController =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _bounceAnimation = Tween(begin: 0.0, end: -20.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
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
        highlightedWordIndex = pages[currentPageIndex].words.length - 1;
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
        highlightedWordIndex = (spokenWords.length - 1)
            .clamp(0, pages[currentPageIndex].words.length - 1);
      });
    });

    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(0.45);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speak() async {
    final text = pages[currentPageIndex].fullText;
    if (text.isEmpty) return;

    if (isPlaying) {
      await flutterTts.stop();
      setState(() => isPlaying = false);
    } else {
      await flutterTts.speak(text);
    }
  }

  void _goToPage(int index) async {
    if (index < 0 || index >= pages.length) return;

    if (isPlaying) {
      await flutterTts.stop();
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
    final funnyLine = pages[currentPageIndex].funnyLine;
    final characterName = pages[currentPageIndex].characterName;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$characterName says: "$funnyLine"'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    flutterTts.stop();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        leading: IconButton(onPressed: (){
          Navigator.of(context).pushReplacementNamed("Index");
        }, icon: Icon(Icons.arrow_back)),
        title: const Text('Story Book with TTS'),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              itemCount: pages.length,
              itemBuilder: (context, index) => StoryPageWidget(
                pageData: pages[index],
                highlightedWordIndex: highlightedWordIndex,
                isCurrentPage: index == currentPageIndex,
                bounceAnimation: _bounceAnimation,
                onCharacterTap: _onCharacterTap,
              ),
            ),
          ),
          Container(
            color: Colors.deepOrange.shade100,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed:
                  currentPageIndex == 0 ? null : () => _goToPage(currentPageIndex - 1),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    disabledBackgroundColor: Colors.deepOrange.shade200,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle : Icons.play_circle,
                    size: 36,
                    color: Colors.deepOrange,
                  ),
                  onPressed: _speak,
                ),
                Text(
                  'Page ${currentPageIndex + 1} of ${pages.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton.icon(
                  onPressed: currentPageIndex == pages.length - 1
                      ? null
                      : () => _goToPage(currentPageIndex + 1),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    disabledBackgroundColor: Colors.deepOrange.shade200,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
