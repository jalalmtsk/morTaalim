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
    PractiseWords(
      word: 'École',
      emoji: '🏫',
      imagePath: 'assets/images/PractiseImage/ecole.jpg',
      audioPath: 'assets/audio/ecole.mp3',
    ),
    PractiseWords(
      word: 'Livre',
      emoji: '📖',
      imagePath: 'assets/images/PractiseImage/livre.jpg',
      audioPath: 'assets/audio/livre.mp3',
    ),
    PractiseWords(
      word: 'Soleil',
      emoji: '☀️',
      imagePath: 'assets/images/PractiseImage/soleil.jpg',
      audioPath: 'assets/audio/soleil.mp3',
    ),
    PractiseWords(
      word: 'Lune',
      emoji: '🌙',
      imagePath: 'assets/images/PractiseImage/lune.jpg',
      audioPath: 'assets/audio/lune.mp3',
    ),
    PractiseWords(
      word: 'Fleur',
      emoji: '🌸',
      imagePath: 'assets/images/PractiseImage/fleur.jpg',
      audioPath: 'assets/audio/fleur.mp3',
    ),
    PractiseWords(
      word: 'Arbre',
      emoji: '🌳',
      imagePath: 'assets/images/PractiseImage/arbre.jpg',
      audioPath: 'assets/audio/arbre.mp3',
    ),
    PractiseWords(
      word: 'Oiseau',
      emoji: '🐦',
      imagePath: 'assets/images/PractiseImage/oiseau.jpg',
      audioPath: 'assets/audio/oiseau.mp3',
    ),
    PractiseWords(
      word: 'Poisson',
      emoji: '🐟',
      imagePath: 'assets/images/PractiseImage/poisson.jpg',
      audioPath: 'assets/audio/poisson.mp3',
    ),
    PractiseWords(
      word: 'Papillon',
      emoji: '🦋',
      imagePath: 'assets/images/PractiseImage/papillon.jpg',
      audioPath: 'assets/audio/papillon.mp3',
    ),
    PractiseWords(
      word: 'Bateau',
      emoji: '⛵',
      imagePath: 'assets/images/PractiseImage/bateau.jpg',
      audioPath: 'assets/audio/bateau.mp3',
    ),
    PractiseWords(
      word: 'Avion',
      emoji: '✈️',
      imagePath: 'assets/images/PractiseImage/avion.jpg',
      audioPath: 'assets/audio/avion.mp3',
    ),
    PractiseWords(
      word: 'Banane',
      emoji: '🍌',
      imagePath: 'assets/images/PractiseImage/banane.jpg',
      audioPath: 'assets/audio/banane.mp3',
    ),
    PractiseWords(
      word: 'Robe',
      emoji: '👗',
      imagePath: 'assets/images/PractiseImage/robe.jpg',
      audioPath: 'assets/audio/robe.mp3',
    ),
    PractiseWords(
      word: 'Chaussure',
      emoji: '👟',
      imagePath: 'assets/images/PractiseImage/chaussure.jpg',
      audioPath: 'assets/audio/chaussure.mp3',
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
                color: Colors.blueAccent,
                onTap: () => navigateTo(context, PlayTheWord(words: wordList)),
              ),
              _buildExerciseCard(
                context,
                title: "Choose the Image",
                icon: Icons.image_rounded,
                color: Colors.green,
                onTap: () => navigateTo(context, MatchWordToImage(words: wordList)),
              ),
              _buildExerciseCard(
                context,
                title: "Match the Word",
                icon: Icons.sync_alt_rounded,
                color: Colors.orange,
                onTap: () => navigateTo(context, DragDropGame(items: wordList)),
              ),

              // Add more games here later if needed
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
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.85), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
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
