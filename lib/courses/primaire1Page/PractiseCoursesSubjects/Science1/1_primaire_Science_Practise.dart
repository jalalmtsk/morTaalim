import 'package:flutter/material.dart';
import 'package:mortaalim/PractiseGames/ArabicExercice/ArabicLetters.dart';
import 'package:mortaalim/PractiseGames/ChooseTheColor/ChooseTheColor.dart';
import 'package:mortaalim/PractiseGames/HeavyLight/HeavyLight.dart';
import 'package:mortaalim/PractiseGames/ScienceExercice/AnimalSounds.dart';
import 'package:mortaalim/PractiseGames/ScienceExercice/ColorMixing.dart';
import 'package:mortaalim/PractiseGames/ScienceExercice/ScienceQuizz.dart';

class IndexScience1Practise extends StatelessWidget {

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
          "📚 Science Practise",
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
                title: "Heavy Or Light",
                icon: Icons.color_lens,
                color: Colors.teal,
                onTap: () => navigateTo(context, HeavyLightGame()),
              ),

              _buildExerciseCard(
                context,
                title: "Find The Color",
                icon: Icons.color_lens,
                color: Colors.redAccent,
                onTap: () => navigateTo(context, ColorMatchingGame()),
              ),
              _buildExerciseCard(
                context,
                title: "Science Quizz",
                icon: Icons.science,
                color: Colors.orangeAccent,
                onTap: () => navigateTo(context, ScienceQuizExercise()),
              ),

              _buildExerciseCard(
                context,
                title: "Color Mixing",
                icon: Icons.science,
                color: Colors.green,
                onTap: () => navigateTo(context, ColorMixingExercise()),
              ),

              _buildExerciseCard(
                context,
                title: "Animal Sounds",
                icon: Icons.surround_sound,
                color: Colors.green,
                onTap: () => navigateTo(context, ArabicLettersExercise()),
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
              color: color.withValues(alpha: 0.4),
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
