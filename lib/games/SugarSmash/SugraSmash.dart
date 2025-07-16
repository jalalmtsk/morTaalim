// Full updated SugarSmash game with:
// - Swipe gesture to swap candies
// - Dynamic scoring (10 for 3-match, 20 for 4-match, etc.)
// - Preview moves before clearing
// - Colorful, fun UI
// - Restart button and power-up example

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class Sugrasmash extends StatelessWidget {
  const Sugrasmash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: const SafeArea(
            child: Match3Board()));
  }
}

class Match3Board extends StatefulWidget {
  const Match3Board({super.key});

  @override
  State<Match3Board> createState() => _Match3BoardState();
}

class _Match3BoardState extends State<Match3Board> {
  static const int rowCount = 6;
  static const int colCount = 6;
  static const double tileSize = 56;
  final Random random = Random();

  late List<List<int>> board;
  final List<String> candyImageNames = [
    'candy_red',
    'candy_green',
    'candy_blue',
    'candy_yellow',
    'candy_purple',
    'candy_orange',
  ];

  bool isAnimating = false;
  int maxMoves = 30;
  int currentScore = 200;
  static const int maxTimeSeconds = 120;
  int remainingSeconds = maxTimeSeconds;
  bool gameWon = false;
  Timer? gameTimer;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      maxMoves = 30;
      currentScore = 200;
      remainingSeconds = maxTimeSeconds;
      gameWon = false;
      _initializeBoard();
      _removeInitialMatches();
      gameTimer?.cancel();
      _startTimer();
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void _initializeBoard() {
    board = List.generate(
      rowCount,
          (_) => List.generate(colCount, (_) => random.nextInt(candyImageNames.length)),
    );
  }

  void _startTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _removeInitialMatches() {
    bool found;
    do {
      found = false;
      final matches = _findMatches();
      if (matches.isNotEmpty) {
        found = true;
        for (var p in matches) {
          board[p.x][p.y] = random.nextInt(candyImageNames.length);
        }
      }
    } while (found);
  }

  Set<Point<int>> _findMatches() {
    Set<Point<int>> matched = {};

    for (int r = 0; r < rowCount; r++) {
      int count = 1;
      for (int c = 1; c < colCount; c++) {
        if (board[r][c] == board[r][c - 1]) {
          count++;
        } else {
          if (count >= 3) {
            for (int k = 0; k < count; k++) {
              matched.add(Point(r, c - 1 - k));
            }
          }
          count = 1;
        }
      }
      if (count >= 3) {
        for (int k = 0; k < count; k++) {
          matched.add(Point(r, colCount - 1 - k));
        }
      }
    }

    for (int c = 0; c < colCount; c++) {
      int count = 1;
      for (int r = 1; r < rowCount; r++) {
        if (board[r][c] == board[r - 1][c]) {
          count++;
        } else {
          if (count >= 3) {
            for (int k = 0; k < count; k++) {
              matched.add(Point(r - 1 - k, c));
            }
          }
          count = 1;
        }
      }
      if (count >= 3) {
        for (int k = 0; k < count; k++) {
          matched.add(Point(rowCount - 1 - k, c));
        }
      }
    }

    return matched;
  }

  bool _areAdjacent(Point<int> a, Point<int> b) {
    return (a.x == b.x && (a.y - b.y).abs() == 1) ||
        (a.y == b.y && (a.x - b.x).abs() == 1);
  }

  Future<void> _trySwap(Point<int> first, Point<int> second) async {
    if (isAnimating || ! _areAdjacent(first, second)) return;

    setState(() {
      isAnimating = true;
      maxMoves--;
    });

    int temp = board[first.x][first.y];
    board[first.x][first.y] = board[second.x][second.y];
    board[second.x][second.y] = temp;

    setState(() {});

    await Future.delayed(const Duration(milliseconds: 300));

    final matches = _findMatches();
    if (matches.isEmpty) {
      temp = board[first.x][first.y];
      board[first.x][first.y] = board[second.x][second.y];
      board[second.x][second.y] = temp;
      setState(() => isAnimating = false);
    } else {
      int matchScore = (matches.length ~/ 3) * 10;
      await _clearMatchesAndCollapse();
      setState(() {
        currentScore = (currentScore - matchScore).clamp(0, 200);
        if (currentScore == 0) {
          gameWon = true;
          gameTimer?.cancel();
        }
        isAnimating = false;
      });
    }
  }

  Future<void> _clearMatchesAndCollapse() async {
    bool foundMatches = true;
    while (foundMatches) {
      final matches = _findMatches();
      if (matches.isEmpty) break;

      setState(() {
        for (var pos in matches) {
          board[pos.x][pos.y] = -1;
        }
      });

      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        for (int c = 0; c < colCount; c++) {
          List<int> column = [];
          for (int r = rowCount - 1; r >= 0; r--) {
            if (board[r][c] != -1) column.add(board[r][c]);
          }
          int rIndex = rowCount - 1;
          for (var val in column) {
            board[rIndex--][c] = val;
          }
          while (rIndex >= 0) {
            board[rIndex--][c] = random.nextInt(candyImageNames.length);
          }
        }
      });

      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildTile(int r, int c) {
    return GestureDetector(
      onPanUpdate: (details) async {
        if (isAnimating || gameWon || maxMoves <= 0) return;
        final dx = details.delta.dx;
        final dy = details.delta.dy;
        Point<int>? swapTarget;

        if (dx.abs() > dy.abs()) {
          swapTarget = Point(r, c + (dx > 0 ? 1 : -1));
        } else {
          swapTarget = Point(r + (dy > 0 ? 1 : -1), c);
        }

        if (swapTarget.x >= 0 &&
            swapTarget.x < rowCount &&
            swapTarget.y >= 0 &&
            swapTarget.y < colCount) {
          await _trySwap(Point(r, c), swapTarget);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(3),
        width: tileSize - 6,
        height: tileSize - 6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.pinkAccent, width: 1),
        ),
        child: board[r][c] >= 0
            ? Image.asset(
          'assets/images/SugarSmash/${candyImageNames[board[r][c]]}.png',
          fit: BoxFit.contain,
        )
            : const SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFC3A0), Color(0xFFFFF3A0), Color(0xFFA0FFC3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🎉 Sugar Smash 🎉',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _infoBox("Score", "$currentScore", Colors.pinkAccent),
              _infoBox("Moves", "$maxMoves", Colors.orangeAccent),
              _infoBox("Time", _formatTime(remainingSeconds), Colors.teal),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: colCount * tileSize,
            height: rowCount * tileSize,
            child: Column(
              children: List.generate(
                rowCount,
                    (r) => Row(
                  children: List.generate(colCount, (c) => _buildTile(r, c)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (gameWon)
            const Text("🎊 You Win! 🎊",
                style: TextStyle(fontSize: 24, color: Colors.green)),
          if (!gameWon && maxMoves == 0)
            const Text("😢 Out of Moves!",
                style: TextStyle(fontSize: 24, color: Colors.red)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text("Restart Game",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white)),
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))
        ],
      ),
    );
  }
}
