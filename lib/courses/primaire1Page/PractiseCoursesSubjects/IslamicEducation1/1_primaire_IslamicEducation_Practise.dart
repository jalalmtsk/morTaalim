import 'package:flutter/material.dart';
import 'package:mortaalim/PractiseGames/MatchTheImage/MatchTheImage.dart';
import 'package:mortaalim/PractiseGames/WuduGame/WuduGame.dart';
import '../../../../PractiseGames/DragAndDrop/DragAndDrop.dart';
import '../../../../PractiseGames/PlayTheWord/PlayTheWord.dart';
import '../../../../PractiseGames/practiseWords.dart';

class IndexIslamicEducation1Practise extends StatelessWidget {
  final List<PractiseWords> wuduStepsList = [
    PractiseWords(
      word: 'النية',
      emoji: '🧠',
      imagePath: 'assets/images/PractiseImage/WuduImages/intention.png',
      audioPath: 'assets/audios/tts_female/Wudu/intention_female.mp3',
    ),
    PractiseWords(
      word: 'غسل اليدين',
      emoji: '👐',
      imagePath: 'assets/images/PractiseImage/WuduImages/hands_wudu.png',
      audioPath: 'assets/audios/tts_female/Wudu/hands_female.mp3',
    ),
    PractiseWords(
      word: 'المضمضة',
      emoji: '👄',
      imagePath: 'assets/images/PractiseImage/WuduImages/mouth_wudu.png',
      audioPath: 'assets/audios/tts_female/Wudu/mouth_female.mp3',
    ),
    PractiseWords(
      word: 'الاستنشاق',
      emoji: '👃',
      imagePath: 'assets/images/PractiseImage/WuduImages/nose_wudu.png',
      audioPath: 'assets/audios/tts_female/Wudu/nose_female.mp3',
    ),
    PractiseWords(
      word: 'غسل الوجه',
      emoji: '🧼',
      imagePath: 'assets/images/PractiseImage/WuduImages/face_wudu.png',
      audioPath: 'assets/audios/tts_female/Wudu/face_female.mp3',
    ),
    PractiseWords(
      word: 'غسل الذراعين',
      emoji: '💪',
      imagePath: 'assets/images/PractiseImage/WuduImages/arm_wudu.png',
      audioPath: 'assets/audios/tts_female/Wudu/arms_female.mp3',
    ),
    PractiseWords(
      word: 'مسح الرأس',
      emoji: '🧴',
      imagePath: 'assets/images/PractiseImage/WuduImages/hear_wudu.png',
      audioPath: 'assets/audios/tts_female/Wudu/head_female.mp3',
    ),
    PractiseWords(
      word: 'مسح الأذنين',
      emoji: '👂',
      imagePath: 'assets/images/PractiseImage/WuduImages/ear_wudu.png',
      audioPath: 'assets/audios/tts_female/Wudu/ears_female.mp3',
    ),
    PractiseWords(
      word: 'غسل الرجلين',
      emoji: '🦶',
      imagePath: 'assets/images/PractiseImage/WuduImages/feet_wudu.png',
      audioPath: 'assets/audios/tts_female/Wudu/feet_female.mp3',
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
                title: "Wudue",
                icon: Icons.clean_hands_outlined,
                color: Colors.blueAccent,
                onTap: () => navigateTo(context, WuduGame()),
              ),

              _buildExerciseCard(
                context,
                title: "Play the Word",
                icon: Icons.volume_up_rounded,
                color: Colors.blueAccent,
                onTap: () => navigateTo(context, PlayTheWord(words: wuduStepsList)),
              ),
              _buildExerciseCard(
                context,
                title: "Choose the Image",
                icon: Icons.image_rounded,
                color: Colors.green,
                onTap: () => navigateTo(context, MatchWordToImage(words: wuduStepsList)),
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
