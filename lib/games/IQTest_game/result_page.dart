import 'package:flutter/material.dart';

import 'Section_Selector.dart';
import 'iqGame_data.dart';

class ResultPage extends StatelessWidget {
  final int score;
  final Section section;
  const ResultPage({super.key, required this.score, required this.section});

  String getDescription(int score) {
    if (score >= 40) return 'Excellent! You\'re a logic master! 🧠';
    if (score >= 30) return 'Great job! Above average IQ 👍';
    if (score >= 20) return 'Not bad! Average performance 😊';
    return 'Keep practicing to improve! 💪';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(section.icon, size: 60, color: Colors.deepPurple),
              const SizedBox(height: 20),
              Text('Your Score: $score',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text(getDescription(score),
                  style: const TextStyle(fontSize: 20), textAlign: TextAlign.center),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SectionSelector()),
                ),
                child: const Text('Back to Menu'),
              )
            ],
          ),
        ),
      ),
    );
  }
}