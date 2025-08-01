import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class SpeedbombApp extends StatelessWidget {
  const SpeedbombApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SpeedBomb();
  }
}

class SpeedBomb extends StatefulWidget {
  const SpeedBomb({super.key});

  @override
  State<SpeedBomb> createState() => _speedBombState();
}

class _speedBombState extends State<SpeedBomb> {
  static const int lanes = 3;
  static const double playerSize = 60;
  static const double itemSize = 50;
  static const double laneWidth = 120;

  int playerLane = 1; // 0: left, 1: center, 2: right
  int score = 0;
  int lives = 3;
  bool gameOver = false;

  final Random random = Random();

  List<_FallingItem> fallingItems = [];

  late Timer gameTimer;
  double fallingSpeed = 4; // initial pixels per tick
  final double maxSpeed = 15;
  final double speedIncrement = 0.02; // increase per tick
  late double screenHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      screenHeight = MediaQuery.of(context).size.height;
      _startGame();
    });
  }

  @override
  void dispose() {
    gameTimer.cancel();
    super.dispose();
  }

  void _startGame() {
    score = 0;
    lives = 3;
    gameOver = false;
    playerLane = 1;
    fallingItems.clear();
    fallingSpeed = 4;

    gameTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        _moveItems();
        _maybeAddItem();
        _checkCollisions();

        // Increase speed over time but cap it
        if (fallingSpeed < maxSpeed) {
          fallingSpeed += speedIncrement;
        }
      });
    });
  }

  void _moveItems() {
    for (var item in fallingItems) {
      item.position += fallingSpeed;
    }
    fallingItems.removeWhere((item) => item.position > screenHeight + itemSize);
  }

  void _maybeAddItem() {
    if (random.nextDouble() < 0.15) {
      int lane = random.nextInt(lanes);
      _ItemType type;

      double roll = random.nextDouble();
      if (roll < 0.6) {
        type = _ItemType.star;
      } else if (roll < 0.85) {
        type = _ItemType.bomb;
      } else {
        type = _ItemType.heart;
      }

      fallingItems.add(_FallingItem(lane: lane, position: -itemSize, type: type));
    }
  }

  void _checkCollisions() {
    const playerY = null; // will calculate dynamically below
    const collisionThreshold = 40.0;

    // Calculate player Y position (fixed at bottom with some padding)
    final playerYPos = screenHeight - playerSize - 30;

    for (var item in List<_FallingItem>.from(fallingItems)) {
      if ((item.position - playerYPos).abs() < collisionThreshold &&
          item.lane == playerLane) {
        // Collision!
        if (item.type == _ItemType.star) {
          score += 10;
        } else if (item.type == _ItemType.bomb) {
          lives--;
          if (lives <= 0) {
            gameOver = true;
            gameTimer.cancel();
            _showGameOverDialog();
          }
        } else if (item.type == _ItemType.heart) {
          lives++;
        }
        fallingItems.remove(item);
      }
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Game Over 😢"),
        content: Text("Your score: $score"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _startGame();
              });
            },
            child: const Text("Restart"),
          )
        ],
      ),
    );
  }

  void _moveLeft() {
    if (playerLane > 0) {
      setState(() {
        playerLane--;
      });
    }
  }

  void _moveRight() {
    if (playerLane < lanes - 1) {
      setState(() {
        playerLane++;
      });
    }
  }

  Color _colorForType(_ItemType type) {
    switch (type) {
      case _ItemType.star:
        return Colors.yellow.shade400;
      case _ItemType.bomb:
        return Colors.red.shade700;
      case _ItemType.heart:
        return Colors.pink.shade400;
    }
  }

  IconData _iconForType(_ItemType type) {
    switch (type) {
      case _ItemType.star:
        return Icons.star;
      case _ItemType.bomb:
        return Icons.brightness_5;
      case _ItemType.heart:
        return Icons.favorite;
    }
  }

  double _laneX(int lane) {
    final screenWidth = MediaQuery.of(context).size.width;
    double center = screenWidth / 2;
    return center + (lane - 1) * laneWidth;
  }

  @override
  Widget build(BuildContext context) {
    // Set screenHeight in case of hot reloads
    screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlueAccent, Colors.blueAccent, Colors.indigo],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Player at bottom
          Positioned(
            bottom: 30,
            left: _laneX(playerLane) - playerSize / 2,
            child: Container(
              width: playerSize,
              height: playerSize,
              decoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orangeAccent.withValues(alpha: 0.7),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.airplanemode_active,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),

          // Falling items
          ...fallingItems.map(
                (item) => Positioned(
              top: item.position,
              left: _laneX(item.lane) - itemSize / 2,
              child: Container(
                width: itemSize,
                height: itemSize,
                decoration: BoxDecoration(
                  color: _colorForType(item.type),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _colorForType(item.type).withValues(alpha: 0.7),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  _iconForType(item.type),
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),

          // Score & Lives top-left
          Positioned(
            top: 40,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoChip(icon: Icons.star, label: "Score: $score", color: Colors.yellow.shade600),
                const SizedBox(height: 8),
                _infoChip(icon: Icons.favorite, label: "Lives: $lives", color: Colors.red.shade400),
              ],
            ),
          ),

          // Controls bottom center above player
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _controlButton(Icons.arrow_left, _moveLeft),
                const SizedBox(width: 40),
                _controlButton(Icons.arrow_right, _moveRight),
              ],
            ),
          ),

          if (gameOver)
            Center(
              child: Container(
                color: Colors.black54,
                child: const Text(
                  'Game Over',
                  style: TextStyle(
                    fontSize: 48,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1)]),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orangeAccent,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.8), blurRadius: 10)],
        ),
        padding: const EdgeInsets.all(14),
        child: Icon(icon, size: 40, color: Colors.white),
      ),
    );
  }
}

enum _ItemType { star, bomb, heart }

class _FallingItem {
  int lane; // 0,1,2
  double position; // vertical position (top)
  _ItemType type;

  _FallingItem({required this.lane, required this.position, required this.type});
}
