import 'package:flutter/material.dart';
import 'package:mortaalim/PractiseGames/MatchTheImage/MatchTheImage.dart';
import '../../../../PractiseGames/DragAndDrop/DragAndDrop.dart';
import '../../../../PractiseGames/IslamExercice/PillarOfIslam.dart';
import '../../../../PractiseGames/IslamExercice/WuduGame.dart';
import '../../../../PractiseGames/PlayTheWord/PlayTheWord.dart';
import '../../../../PractiseGames/practiseWords.dart';
import '../../../../main.dart';

class IndexIslamicEducation1Practise extends StatelessWidget {
  final List<PractiseWords> wuduStepsList = [
    PractiseWords(
      word: 'النية',
      emoji: '🧠',
      imagePath: 'assets/images/PractiseImage/WuduImages/intention_wudu.png',
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
      imagePath: 'assets/images/PractiseImage/WuduImages/head_wudu.png',
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
        title: Text(
          tr(context).islamicPractise,
          style: const TextStyle(
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
                title: tr(context).wudu,
                imagePath: "assets/images/UI/BackGrounds/GamePractise_BG/IslamicEducation_bg/wudueExercice.jpg",
                onTap: () => navigateTo(context, WuduGame()),
              ),
              _buildExerciseCard(
                context,
                title: tr(context).playTheWord,
                imagePath: "assets/images/UI/BackGrounds/GamePractise_BG/IslamicEducation_bg/ChooseTheImageIslamic.jpg",
                onTap: () => navigateTo(context, PlayTheWord(words: wuduStepsList)),
              ),
              _buildExerciseCard(
                context,
                title: tr(context).chooseTheImage,
                imagePath: "assets/images/UI/BackGrounds/GamePractise_BG/IslamicEducation_bg/ChooseTheImageIslamic.jpg",
                onTap: () => navigateTo(context, MatchWordToImage(words: wuduStepsList)),
              ),
              _buildExerciseCard(
                context,
                title: tr(context).pillarOfIslam,
                imagePath: "assets/images/UI/BackGrounds/GamePractise_BG/IslamicEducation_bg/PillarOfIslam.jpg",
                onTap: () => navigateTo(context, PillarsGame()),
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
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
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
                Expanded(
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
