import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'dart:math';

import '../practiseWords.dart';

class MatchWordToImage extends StatefulWidget {
  final List<PractiseWords> words;

  const MatchWordToImage({super.key, required this.words});

  @override
  State<MatchWordToImage> createState() => _MatchWordToImageState();
}

class _MatchWordToImageState extends State<MatchWordToImage> {
  final MusicPlayer _player = MusicPlayer();
  final MusicPlayer _backGround_music = MusicPlayer();
  late List<PractiseWords> currentOptions;
  late PractiseWords currentWord;
  int score = 0;

  @override
  void initState() {
    super.initState();
    _backGround_music.play("assets/audios/sound_track/SakuraGirlYay_BcG.mp3", loop: true);
    _backGround_music.setVolume(0.07);
    _player.setVolume(1);
    _generateNewRound();
  }

  Future<void> _generateNewRound() async {
    final random = Random();
    final options = widget.words.toList()..shuffle();
    currentOptions = options.take(4).toList();
    currentWord = currentOptions[random.nextInt(4)];
    await _player.play(currentWord.audioPath);
    setState(() {});
  }

  void _handleSelection(PractiseWords selected) async {
    final isCorrect = selected.word == currentWord.word;
    await _player.play(
      isCorrect
          ? 'assets/audios/QuizGame_Sounds/correct.mp3'
          : 'assets/audios/QuizGame_Sounds/incorrect.mp3',
    );

    if (isCorrect) {
      setState(() => score++);
    }

    Future.delayed(const Duration(milliseconds: 900), _generateNewRound);
  }

  @override
  void dispose() {
    _player.dispose();
    _backGround_music.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentOptions.isEmpty || currentWord.word.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("🎯 Match the Word"),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade400,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Word and Emoji Display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      currentWord.emoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentWord.word,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _player.play(currentWord.audioPath),
                      icon: const Icon(Icons.volume_up_rounded, size: 28),
                      tooltip: "Play pronunciation",
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Score Display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 26),
                const SizedBox(width: 6),
                Text(
                  'Score: $score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Grid of Options
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: currentOptions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
              ),
              itemBuilder: (context, index) {
                final option = currentOptions[index];

                return InkWell(
                  onTap: () => _handleSelection(option),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        option.imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
