import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';



// --- CONSTANTS ---
class Constants {
  static double screenWidth = 0;
  static double screenHeight = 0;
  static final random = Random();
}

// --- BLOCK ---
class Block {
  double x, y, width, height;
  Color color;
  bool movingRight;
  double speed;
  Block({required this.x, required this.y, required this.width, required this.height, required this.speed})
      : color = Colors.primaries[Constants.random.nextInt(Colors.primaries.length)],
        movingRight = Constants.random.nextBool();

  void update() {
    if (movingRight) {
      x += speed;
      if (x + width > Constants.screenWidth) movingRight = false;
    } else {
      x -= speed;
      if (x < 0) movingRight = true;
    }
  }

  Rect get hitBox => Rect.fromLTWH(x, y, width, height);

  void draw(Canvas canvas) {
    Paint paint = Paint()..color = color;
    canvas.drawRect(hitBox, paint);
  }
}

// --- GAME SCREEN ---
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Timer _timer;
  List<Block> blocks = [];
  double blockHeight = 40;
  double speed = 3.0;
  int score = 0;
  int multiplier = 1;
  bool isGameOver = false;

  @override
  void initState() {
    super.initState();
    resetGame();
  }

  void resetGame() {
    setState(() {
      blocks = [
        Block(
            x: 50,
            y: 500,
            width: 200,
            height: blockHeight,
            speed: speed)
      ];
      score = 0;
      multiplier = 1;
      speed = 3.0;
      isGameOver = false;
      startGame();
    });
  }

  void startGame() {
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!isGameOver) {
        setState(() {
          blocks.last.update();
        });
      }
    });
  }

  void dropBlock() {
    if (isGameOver) return;

    if (blocks.length > 1) {
      Block prev = blocks[blocks.length - 2];
      Block current = blocks.last;
      double overlap = min(prev.x + prev.width, current.x + current.width) -
          max(prev.x, current.x);
      if (overlap <= 0) {
        gameOver();
        return;
      } else {
        // Adjust block size for next round
        double newWidth = overlap;
        current.width = newWidth;
        current.x = max(prev.x, current.x);
        score += 10 * multiplier;
        multiplier++;
        speed += 0.1;
      }
    }
    // Add next moving block above
    blocks.add(Block(
        x: 0,
        y: blocks.last.y - blockHeight,
        width: blocks.last.width,
        height: blockHeight,
        speed: speed));
  }

  void gameOver() {
    isGameOver = true;
    _timer.cancel();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Game Over!'),
          content: Text('Score: $score'),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  resetGame();
                },
                child: const Text('Restart'))
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    Constants.screenWidth = MediaQuery.of(context).size.width;
    Constants.screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: dropBlock,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                  painter: GamePainter(blocks: blocks)),
            ),
            Positioned(
                top: 50,
                left: 20,
                child: Text('Score: $score x$multiplier',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white))),
          ],
        ),
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  List<Block> blocks;
  GamePainter({required this.blocks});
  @override
  void paint(Canvas canvas, Size size) {
    for (var b in blocks) b.draw(canvas);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
