import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const SnakeAndLadderTest());
}

class SnakeAndLadderTest extends StatelessWidget {
  const SnakeAndLadderTest({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Snake & Ladder 8x8',
      home: const GameBoard(),
    );
  }
}

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> with TickerProviderStateMixin {
  int player1Pos = 1;
  int player2Pos = 1;
  int diceNumber = 1;
  bool isPlayer1Turn = true;

  final Random random = Random();

  // Snakes and ladders for 8x8 board (positions 1-64)
  final Map<int, int> snakes = {16: 6, 48: 30, 56: 25, 62: 45, 50:20};
  final Map<int, int> ladders = {3: 22, 9: 38, 17: 33, 28: 44};

  final double boardSize = 400;
  final double avatarRadius = 12;
  final int gridSize = 8;

  void rollDice() async {
    for (int i = 0; i < 10; i++) {
      setState(() {
        diceNumber = random.nextInt(6) + 1;
      });
      await Future.delayed(const Duration(milliseconds: 100));
    }

    int rolls = diceNumber;
    movePlayer(rolls);
  }

  Offset getPlayerOffset(int position, {bool secondPlayer = false}) {
    int index = position - 1;
    int row = index ~/ gridSize;
    int col = index % gridSize;

    bool reverse = row % 2 == 1; // zigzag pattern
    int x = reverse ? gridSize - 1 - col : col;
    int y = gridSize - 1 - row;

    double tileSize = boardSize / gridSize;

    // Blue: center, Orange: slightly right
    double offsetX = secondPlayer ? avatarRadius * 0.4 : 0;

    return Offset(
      x * tileSize + tileSize / 2 - avatarRadius + offsetX,
      y * tileSize + tileSize / 2 - avatarRadius,
    );
  }


  void movePlayer(int steps) async {
    int currentPos = isPlayer1Turn ? player1Pos : player2Pos;

    for (int i = 0; i < steps; i++) {
      currentPos++;
      if (currentPos > gridSize * gridSize) {
        currentPos = gridSize * gridSize - (currentPos - gridSize * gridSize);
      }
      await animateStep(currentPos);
    }

    // Animate snakes or ladders along path
    if (snakes.containsKey(currentPos)) {
      await animatePathMovement(currentPos, snakes[currentPos]!);
      currentPos = snakes[currentPos]!;
    } else if (ladders.containsKey(currentPos)) {
      await animatePathMovement(currentPos, ladders[currentPos]!);
      currentPos = ladders[currentPos]!;
    }

    setState(() {
      if (isPlayer1Turn) player1Pos = currentPos;
      else player2Pos = currentPos;
    });

    if (currentPos == gridSize * gridSize) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Game Over!"),
          content: Text("${isPlayer1Turn ? 'Player 1' : 'Player 2'} Wins!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                resetGame();
              },
              child: const Text("Restart"),
            ),
          ],
        ),
      );
    } else {
      isPlayer1Turn = !isPlayer1Turn;
    }
  }

  Future<void> animateStep(int pos) async {
    setState(() {
      if (isPlayer1Turn)
        player1Pos = pos;
      else
        player2Pos = pos;
    });
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> animatePathMovement(int start, int end) async {
    Offset from = getPlayerOffset(start);
    Offset to = getPlayerOffset(end);
    int frames = 20;

    for (int i = 1; i <= frames; i++) {
      double t = i / frames;
      Offset pos = Offset(
        from.dx + (to.dx - from.dx) * t,
        from.dy + (to.dy - from.dy) * t - 15 * sin(pi * t), // bounce effect
      );
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 30));
    }
  }

  void resetGame() {
    setState(() {
      player1Pos = 1;
      player2Pos = 1;
      diceNumber = 1;
      isPlayer1Turn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    double tileSize = boardSize / gridSize;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Snake & Ladder 8x8'),
        actions: [IconButton(onPressed: resetGame, icon: const Icon(Icons.refresh))],
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              children: [
                // Background image with soft opacity
                Container(
                  width: boardSize,
                  height: boardSize,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/snake.png'),
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(color: Colors.black),
                  ),
                ),
                // Players
                Positioned(
                  left: getPlayerOffset(player1Pos).dx,
                  top: getPlayerOffset(player1Pos).dy,
                  child: const CircleAvatar(radius: 12, backgroundColor: Colors.blue),
                ),
                Positioned(
                  left: getPlayerOffset(player2Pos, secondPlayer: true).dx,
                  top: getPlayerOffset(player2Pos, secondPlayer: true).dy,
                  child: const CircleAvatar(radius: 12, backgroundColor: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Image.asset('assets/dice$diceNumber.png', width: 60, height: 60),
            const SizedBox(height: 10),
            Text("${isPlayer1Turn ? 'Player 1' : 'Player 2'} Turn",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: rollDice, child: const Text("Roll Dice")),
          ],
        ),
      ),
    );
  }
}
