import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';


class Match3Game extends StatelessWidget {
  const Match3Game({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Candy Clash',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: SafeArea(child: Match3Board()),
      ),
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
      ),
    );
  }
}

class Match3Board extends StatefulWidget {
  const Match3Board({super.key});

  @override
  State<Match3Board> createState() => _Match3BoardState();
}

class _Match3BoardState extends State<Match3Board> with TickerProviderStateMixin {
  static const int rowCount = 6;
  static const int colCount = 6;
  static const double tileSize = 56;

  late List<List<int>> board;
  final Random random = Random();

  Point<int>? selected;

  bool isAnimating = false;

  int moves = 0;
  static const int maxTimeSeconds = 120; // 2 minutes
  late int remainingSeconds;
  Timer? gameTimer;

  final List<String> candyImageNames = [
    'candy_red',
    'candy_green',
    'candy_blue',
    'candy_yellow',
    'candy_purple',
    'candy_orange',
  ];

  // For animation: track candy positions during swap
  late List<List<Offset>> tileOffsets;

  @override
  void initState() {
    super.initState();
    remainingSeconds = maxTimeSeconds;

    _initializeBoard();
    _removeInitialMatches();
    _initializeOffsets();

    _startTimer();
  }

  void _initializeOffsets() {
    tileOffsets = List.generate(
      rowCount,
          (r) => List.generate(colCount, (c) => Offset(c * tileSize, r * tileSize)),
    );
  }

  void _startTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
        // Game over logic can be added here
      }
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

  void _removeInitialMatches() {
    bool foundMatches;
    do {
      foundMatches = false;
      final matches = _findMatches();
      if (matches.isNotEmpty) {
        foundMatches = true;
        for (var pos in matches) {
          board[pos.x][pos.y] = random.nextInt(candyImageNames.length);
        }
      }
    } while (foundMatches);
  }

  Set<Point<int>> _findMatches() {
    Set<Point<int>> matched = {};

    // Rows
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

    // Columns
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
    if (isAnimating) return;
    if (!_areAdjacent(first, second)) return;

    setState(() {
      isAnimating = true;
      moves++;
    });

    // Swap in board
    int temp = board[first.x][first.y];
    board[first.x][first.y] = board[second.x][second.y];
    board[second.x][second.y] = temp;

    // Animate the swap visually (swap offsets)
    await _animateSwap(first, second);

    final matches = _findMatches();

    if (matches.isEmpty) {
      // No match, swap back after animation
      await Future.delayed(const Duration(milliseconds: 200));
      // Swap back data
      temp = board[first.x][first.y];
      board[first.x][first.y] = board[second.x][second.y];
      board[second.x][second.y] = temp;

      // Animate swap back
      await _animateSwap(second, first);

      setState(() {
        isAnimating = false;
        selected = null;
      });
    } else {
      // Matches found, clear and collapse candies
      await _clearMatchesAndCollapse();
      setState(() {
        isAnimating = false;
        selected = null;
      });
    }
  }

  Future<void> _animateSwap(Point<int> first, Point<int> second) async {
    final Duration animationDuration = const Duration(milliseconds: 300);
    final Offset firstOffset = tileOffsets[first.x][first.y];
    final Offset secondOffset = tileOffsets[second.x][second.y];

    // Swap offsets
    setState(() {
      tileOffsets[first.x][first.y] = secondOffset;
      tileOffsets[second.x][second.y] = firstOffset;
    });

    await Future.delayed(animationDuration);

    // Swap back offsets in memory to original positions (keep visual positions swapped)
    setState(() {
      tileOffsets[first.x][first.y] = firstOffset;
      tileOffsets[second.x][second.y] = secondOffset;
    });
  }

  Future<void> _clearMatchesAndCollapse() async {
    bool foundMatches = true;

    while (foundMatches) {
      final matches = _findMatches();

      if (matches.isEmpty) {
        foundMatches = false;
        break;
      }

      setState(() {
        for (var pos in matches) {
          board[pos.x][pos.y] = -1;
        }
      });

      await Future.delayed(const Duration(milliseconds: 400));

      setState(() {
        for (int c = 0; c < colCount; c++) {
          List<int> columnCandies = [];
          for (int r = rowCount - 1; r >= 0; r--) {
            if (board[r][c] != -1) {
              columnCandies.add(board[r][c]);
            }
          }
          int rIndex = rowCount - 1;
          for (var candy in columnCandies) {
            board[rIndex][c] = candy;
            rIndex--;
          }
          while (rIndex >= 0) {
            board[rIndex][c] = random.nextInt(candyImageNames.length);
            rIndex--;
          }
        }
      });

      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final boardWidth = colCount * tileSize;
    final boardHeight = rowCount * tileSize;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2c5364),
            Color(0xFF203a43),
            Color(0xFF0f2027),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Candy Clash',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),

            // Timer & moves row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoBox('Time Left', _formatTime(remainingSeconds)),
                _buildInfoBox('Moves', moves.toString()),
              ],
            ),

            const SizedBox(height: 20),

            Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(20),
              color: Colors.black87,
              child: SizedBox(
                width: boardWidth,
                height: boardHeight,
                child: Stack(
                  children: [
                    // Draw grid background
                    for (int r = 0; r < rowCount; r++)
                      for (int c = 0; c < colCount; c++)
                        Positioned(
                          left: c * tileSize,
                          top: r * tileSize,
                          child: Container(
                            width: tileSize,
                            height: tileSize,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white24, width: 1),
                            ),
                          ),
                        ),

                    // Draw candies with animation (position based on tileOffsets)
                    for (int r = 0; r < rowCount; r++)
                      for (int c = 0; c < colCount; c++)
                        if (board[r][c] >= 0)
                          AnimatedPositioned(
                            key: ValueKey('$r-$c-${board[r][c]}'),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            left: tileOffsets[r][c].dx,
                            top: tileOffsets[r][c].dy,
                            child: GestureDetector(
                              onTap: () async {
                                if (isAnimating) return;
                                if (selected == null) {
                                  setState(() {
                                    selected = Point(r, c);
                                  });
                                } else {
                                  if (selected == Point(r, c)) {
                                    setState(() {
                                      selected = null;
                                    });
                                  } else {
                                    await _trySwap(selected!, Point(r, c));
                                  }
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                width: tileSize - 8,
                                height: tileSize - 8,
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: selected == Point(r, c)
                                      ? Border.all(color: Colors.amberAccent, width: 4)
                                      : null,
                                  boxShadow: [
                                    BoxShadow(
                                      color: selected == Point(r, c)
                                          ? Colors.amberAccent.withOpacity(0.7)
                                          : Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: selected == Point(r, c) ? 4 : 2,
                                    ),
                                  ],
                                  color: Colors.black,
                                ),
                                child: Image.asset(
                                  'assets/images/${candyImageNames[board[r][c]]}.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Tap two adjacent candies to swap',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Game over message
            if (remainingSeconds == 0)
              const Text(
                'Game Over!',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.amberAccent,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
