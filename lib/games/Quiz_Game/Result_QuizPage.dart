import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'general_culture_game.dart';

class ResultPage extends StatelessWidget {
  final int player1Score;
  final int player2Score;
  final GameMode mode;

  const ResultPage({
    super.key,
    required this.player1Score,
    required this.player2Score,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    String winner;
    if (mode == GameMode.single) {
      winner = "🎉 Great Job!";
    } else {
      if (player1Score > player2Score) {
        winner = "🏆 Player 1 Wins!";
      } else if (player2Score > player1Score) {
        winner = "🏆 Player 2 Wins!";
      } else {
        winner = "🤝 It's a Tie!";
      }
    }


    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text('🎮 Game Over!'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(winner, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text('Player 1: $player1Score', style: const TextStyle(fontSize: 22)),
            if (mode == GameMode.multiplayer)
              Text('Player 2: $player2Score', style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => QuizPage(mode: mode)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),

              child: const Text('🔁 Play Again', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
