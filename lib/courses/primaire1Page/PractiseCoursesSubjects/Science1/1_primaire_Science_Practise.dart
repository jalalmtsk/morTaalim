import 'package:flutter/material.dart';
import 'package:mortaalim/PractiseGames/ArabicExercice/ArabicLetters.dart';
import 'package:mortaalim/PractiseGames/ChooseTheColor/ChooseTheColor.dart';
import 'package:mortaalim/PractiseGames/HeavyLight/HeavyLight.dart';
import 'package:mortaalim/PractiseGames/ScienceExercice/ColorMixing.dart';
import 'package:mortaalim/PractiseGames/ScienceExercice/ScienceQuizz.dart';

import '../../../../main.dart'; // assuming you have this

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
        backgroundColor: Colors.deepPurple,
        title: Text(
          tr(context).sciencePractise,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDF6F0), Color(0xFFE1F5FE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1,
            children: [
              _buildExerciseCard(
                context,
                title: tr(context).heavyLight,
                imagePath: "assets/images/UI/BackGrounds/GamePractise_BG/Science_bg/heavyandLight.jpg",
                onTap: () => navigateTo(context, HeavyLightGame()),
              ),
              _buildExerciseCard(
                context,
                title: tr(context).findColor,
                imagePath: "assets/images/UI/BackGrounds/GamePractise_BG/Science_bg/findTheColor.jpg",
                onTap: () => navigateTo(context, ColorMatchingGame()),
              ),
              _buildExerciseCard(
                context,
                title: tr(context).scienceQuizz,
                imagePath: "assets/images/UI/BackGrounds/GamePractise_BG/Science_bg/SciecneQuizz.jpg",
                onTap: () => navigateTo(context, ScienceQuizExercise()),
              ),
              _buildExerciseCard(
                context,
                title: tr(context).colorMixing,
                imagePath: "assets/images/UI/BackGrounds/GamePractise_BG/Science_bg/colorMixing.jpg",
                onTap: () => navigateTo(context, ColorMixingExercise()),
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
