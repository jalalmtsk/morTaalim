import 'package:flutter/material.dart';
import 'package:mortaalim/PractiseGames/MathExercice/CountObject.dart';
import 'package:mortaalim/PractiseGames/MathExercice/FindLargestNumber.dart';
import 'package:mortaalim/PractiseGames/MathExercice/MathAddition.dart';
import 'package:mortaalim/PractiseGames/MathExercice/MathSubstraction.dart';
import 'package:mortaalim/PractiseGames/MathExercice/MissingNumber.dart';
import 'package:mortaalim/PractiseGames/MathExercice/NumberComparison.dart';
import 'package:mortaalim/PractiseGames/MathExercice/OddNumbers.dart';
import 'package:mortaalim/PractiseGames/MathExercice/TargetNumber.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';

class IndexArabic1Practise extends StatelessWidget {
  const IndexArabic1Practise({super.key});

  void navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final exercises = [
      {
        'title': '🔢 Missing Number',
        'icon': Icons.question_mark,
        'color': Colors.pinkAccent,
        'page':  MissingNumberExercise()
      },
      {
        'title': '🏆 Find Largest',
        'icon': Icons.trending_up,
        'color': Colors.orangeAccent,
        'page':  FindLargestNumberExercise()
      },
      {
        'title': '➕ Addition',
        'icon': Icons.add_circle,
        'color': Colors.blueAccent,
        'page':  MathAdditionExercise()
      },
      {
        'title': '➖ Subtraction',
        'icon': Icons.remove_circle,
        'color': Colors.green,
        'page':  MathSubtractionExercise()
      },
      {
        'title': '🍎 Count Objects',
        'icon': Icons.countertops,
        'color': Colors.amber,
        'page':  CountObject()
      },
      {
        'title': '⚖ Compare Numbers',
        'icon': Icons.compare_arrows,
        'color': Colors.purple,
        'page':  NumberComparisonGame()
      },
      {
        'title': '🔍 Odd Numbers',
        'icon': Icons.filter_9_plus,
        'color': Colors.teal,
        'page':  EvenOddExercise()
      },
      {
        'title': '🎯 Target Number',
        'icon': Icons.my_location,
        'color': Colors.deepPurpleAccent,
        'page':  TargetNumberExercise()
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Fun header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A5AE0), Color(0xFF8D58E8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: const [
                  Text(
                    '📚 Let’s Practise Math!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                            blurRadius: 4,
                            color: Colors.black26,
                            offset: Offset(2, 2))
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Fun games to make you a math star 🌟',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Userstatutbar(),
            const SizedBox(height: 8),

            // Grid of exercises
            Expanded(
              child: GridView.builder(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: exercises.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final ex = exercises[index];
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.95, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: InkWell(
                      onTap: () => navigateTo(context, ex['page'] as Widget),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (ex['color'] as Color).withOpacity(0.8),
                              ex['color'] as Color
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: (ex['color'] as Color)
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(ex['icon'] as IconData,
                                size: 60, color: Colors.white),
                            const SizedBox(height: 10),
                            Text(
                              ex['title'] as String,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 3,
                                    color: Colors.black26,
                                    offset: Offset(1, 1),
                                  )
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
