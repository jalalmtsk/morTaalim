/*

 import 'package:flutter/material.dart';

import 'CardConcept.dart';

class EndGameScreen extends StatelessWidget {
  final List<List<PlayingCard>> hands;
  final int winnerIndex;

  const EndGameScreen({
    super.key,
    required this.hands,
    required this.winnerIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[900],
      appBar: AppBar(
        title: const Text('Game Results'),
        backgroundColor: Colors.green[800],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              winnerIndex == 0
                  ? '🎉 You Win! 🎉'
                  : 'Bot $winnerIndex Wins!',
              style: const TextStyle(fontSize: 32, color: Colors.white),
            ),
            const SizedBox(height: 20),
            ...List.generate(
              hands.length,
                  (i) => Text(
                '${i == 0 ? "You" : "Bot $i"}: ${hands[i].length} cards',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back to game screen
              },
              child: const Text('Play Again'),
            ),
          ],
        ),
      ),
    );
  }
}
*/
