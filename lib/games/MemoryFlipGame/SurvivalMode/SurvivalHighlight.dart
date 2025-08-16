
import 'package:flutter/material.dart';

class SurvivalHighlightsPage extends StatelessWidget {
  final int bestMatches;
  final int bestTimeSeconds;

  const SurvivalHighlightsPage(
      {super.key, required this.bestMatches, required this.bestTimeSeconds});

  @override
  Widget build(BuildContext context) {
    int minutes = bestTimeSeconds ~/ 60;
    int seconds = bestTimeSeconds % 60;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Survival Highlights'),
        backgroundColor: Colors.deepPurple.shade700,
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Best Survival Score',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700)),
                const SizedBox(height: 16),
                Text('Matches: $bestMatches',
                    style: TextStyle(fontSize: 20, color: Colors.black87)),
                Text('Time: ${minutes}m ${seconds}s',
                    style: TextStyle(fontSize: 20, color: Colors.black87)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}