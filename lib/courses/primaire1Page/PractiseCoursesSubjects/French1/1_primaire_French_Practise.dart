import 'package:flutter/material.dart';
import 'package:mortaalim/PractiseGames/ChooseTheColor/ChooseTheColor.dart';
import 'package:mortaalim/PractiseGames/MatchTheImage/MatchTheImage.dart';
import '../../../../PractiseGames/DragAndDrop/DragAndDrop.dart';
import '../../../../PractiseGames/PlayTheWord/PlayTheWord.dart';
import '../../../../PractiseGames/practiseWords.dart';
import '../../../../main.dart';

class IndexFrench1Practise extends StatelessWidget {
  final List<PractiseWords> wordList = [
    PractiseWords(
      word: 'Bonjour',
      emoji: '👋',
      imagePath: 'assets/images/PractiseImage/bonjour.jpg',
      audioPath: 'assets/audios/tts_female/bonjour_female.mp3',
    ),
    PractiseWords(
      word: 'Chat',
      emoji: '🐱',
      imagePath: 'assets/images/PractiseImage/cat.jpg',
      audioPath: 'assets/audios/tts_female/chat_female.mp3',
    ),
    PractiseWords(
      word: 'Chien',
      emoji: '🐶',
      imagePath: 'assets/images/PractiseImage/dog.jpg',
      audioPath: 'assets/audios/tts_female/chien_female.mp3',
    ),
    PractiseWords(
      word: 'Maison',
      emoji: '🏠',
      imagePath: 'assets/images/PractiseImage/house.jpg',
      audioPath: 'assets/audios/tts_female/maison_female.mp3',
    ),
    PractiseWords(
      word: 'Pomme',
      emoji: '🍎',
      imagePath: 'assets/images/PractiseImage/pomme.jpg',
      audioPath: 'assets/audios/tts_female/pomme_female.mp3',
    ),
    PractiseWords(
      word: 'Voiture',
      emoji: '🚗',
      imagePath: 'assets/images/PractiseImage/voiture.jpg',
      audioPath: 'assets/audios/tts_female/voiture_female.mp3',
    ),
  ];

  void navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.indigo,
        title: Text(
          tr(context).frenchPractise,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F4F6), Color(0xFFE3F2FD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
            children: [
              _buildExerciseCard(
                context,
                title: tr(context).playTheWord,
                imagePath: 'assets/images/UI/BackGrounds/GamePractise_BG/Frennch_bg/playTheWordFrench.jpg',
                icon: Icons.volume_up_rounded,
                onTap: () => navigateTo(context, PlayTheWord(words: wordList)),
              ),
              _buildExerciseCard(
                context,
                title: tr(context).chooseTheImage,
                imagePath: 'assets/images/UI/BackGrounds/GamePractise_BG/Frennch_bg/chooseTheImageFrench.jpg',
                icon: Icons.image_rounded,
                onTap: () => navigateTo(context, MatchWordToImage(words: wordList)),
              ),
              _buildExerciseCard(
                context,
                title: tr(context).matchTheWord,
                imagePath: 'assets/images/UI/BackGrounds/GamePractise_BG/Frennch_bg/matchTheWordFrench.jpg',
                icon: Icons.sync_alt_rounded,
                onTap: () => navigateTo(context, DragDropGame(items: wordList)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
      BuildContext context, {
        required String title,
        required String imagePath,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 6),
            ),
          ],
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.35),
              BlendMode.darken,
            ),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 52, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 3,
                        color: Colors.black45,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
