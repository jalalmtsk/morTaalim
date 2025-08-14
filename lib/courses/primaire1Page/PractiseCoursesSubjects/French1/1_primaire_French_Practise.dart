import 'package:flutter/material.dart';
import 'package:mortaalim/PractiseGames/ChooseTheColor/ChooseTheColor.dart';
import 'package:mortaalim/PractiseGames/MatchTheImage/MatchTheImage.dart';
import '../../../../PractiseGames/DragAndDrop/DragAndDrop.dart';
import '../../../../PractiseGames/PlayTheWord/PlayTheWord.dart';
import '../../../../PractiseGames/practiseWords.dart';

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
    // Add more words as needed
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
        title: const Text(
          "📚 French Practise",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
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
                title: "Play the Word",
                icon: Icons.volume_up_rounded,
                imagePath: 'assets/images/PractiseImage/bonjour.jpg',
                color: Colors.blueAccent,
                onTap: () => navigateTo(context, PlayTheWord(words: wordList)),
              ),
              _buildExerciseCard(
                context,
                title: "Choose the Image",
                icon: Icons.image_rounded,
                imagePath: 'assets/images/PractiseImage/cat.jpg',
                color: Colors.green,
                onTap: () => navigateTo(context, MatchWordToImage(words: wordList)),
              ),
              _buildExerciseCard(
                context,
                title: "Match the Word",
                icon: Icons.sync_alt_rounded,
                imagePath: 'assets/images/PractiseImage/dog.jpg',
                color: Colors.orange,
                onTap: () => navigateTo(context, DragDropGame(items: wordList)),
              ),
              // Add more cards here if needed
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
        String? imagePath,
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
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
          image: imagePath != null
              ? DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.35),
              BlendMode.darken,
            ),
          )
              : null,
          gradient: imagePath == null
              ? LinearGradient(
            colors: [color.withOpacity(0.85), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
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
