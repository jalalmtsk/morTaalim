import 'package:flutter/material.dart';

import 'package:mortaalim/TestingBeforeProdcution/Hezz2FinalGame/Models/GameCardEnums.dart';
import 'package:mortaalim/TestingBeforeProdcution/Hezz2FinalGame/Models/Cards.dart';



class EndGameScreen extends StatelessWidget {
  final List<List<PlayingCard>> hands;
  final int winnerIndex;
  final GameModeType gameModeType;
  final int currentRound;

  const EndGameScreen({
    required this.hands,
    required this.winnerIndex,
    required this.gameModeType,
    required this.currentRound,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Over')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${winnerIndex == 0 ? 'You' : 'Bot $winnerIndex'} Win!',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'Game Mode: ${gameModeType == GameModeType.playToWin ? 'Play To Win' : 'Elimination'}',
              style: const TextStyle(fontSize: 18),
            ),
            if (gameModeType == GameModeType.elimination)
              Text(
                'Rounds Played: $currentRound',
                style: const TextStyle(fontSize: 18),
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to Main Menu'),
            ),
          ],
        ),
      ),
    );
  }
}