import 'package:flutter/material.dart';


class BreakingWalls extends StatelessWidget {
  const BreakingWalls({super.key});

  @override
  Widget build(BuildContext context) {
    return QuoridorBoard();
  }
}

enum WallType { horizontal, vertical }

class QuoridorBoard extends StatefulWidget {
  const QuoridorBoard({super.key});

  @override
  _QuoridorBoardState createState() => _QuoridorBoardState();
}

class _QuoridorBoardState extends State<QuoridorBoard> {
  static const int boardSize = 8;
  final double cellSize = 48;
  final double wallThickness = 12;

  Offset player1 = const Offset(4, 0);
  Offset player2 = const Offset(4, 7);
  int playerTurn = 1;

  int player1Walls = 5;
  int player2Walls = 5;

  WallType? selectedWallType; // Nullable: no selection by default
  final Set<String> placedWalls = {};
  Set<Offset> possibleMoves = {};

  @override
  void initState() {
    super.initState();
    possibleMoves = getPossibleMoves();
  }

  bool canPlaceWall(String key) {
    if (placedWalls.contains(key)) return false;

    final parts = key.split('_');
    if (parts.length != 3) return false;

    String type = parts[0];
    int r = int.tryParse(parts[1]) ?? -1;
    int c = int.tryParse(parts[2]) ?? -1;

    if (r < 0 || r >= boardSize - 1 || c < 0 || c >= boardSize - 1) return false;

    if (type == 'H') {
      if (placedWalls.contains(key)) return false;
      if (placedWalls.contains('V_${r}_${c}') || placedWalls.contains('V_${r}_${c + 1}')) return false;
    } else if (type == 'V') {
      if (placedWalls.contains(key)) return false;
      if (placedWalls.contains('H_${r}_${c}') || placedWalls.contains('H_${r + 1}_${c}')) return false;
    } else {
      return false;
    }

    return true;
  }

  void placeWall(WallType type, Offset pos) {
    if ((playerTurn == 1 && player1Walls == 0) || (playerTurn == 2 && player2Walls == 0)) {
      showWarning('No walls left');
      return;
    }

    final key = '${type == WallType.horizontal ? 'H' : 'V'}_${pos.dy.toInt()}_${pos.dx.toInt()}';

    if (!canPlaceWall(key)) {
      showWarning('Illegal wall placement!');
      return;
    }

    setState(() {
      placedWalls.add(key);
      if (playerTurn == 1) {
        player1Walls--;
        playerTurn = 2;
      } else {
        player2Walls--;
        playerTurn = 1;
      }
      possibleMoves = getPossibleMoves();
      selectedWallType = null; // Deselect after placing
    });
  }

  bool canMove(Offset from, Offset to) {
    if (to.dx < 0 || to.dx >= boardSize || to.dy < 0 || to.dy >= boardSize) return false;
    if (to == player1 || to == player2) return false;

    final dx = (from.dx - to.dx).abs();
    final dy = (from.dy - to.dy).abs();
    if (dx + dy != 1) return false;

    if (dy == 0) {
      int row = from.dy.toInt();
      int col = dx == 1 && from.dx < to.dx ? from.dx.toInt() : to.dx.toInt();
      if (placedWalls.contains('V_${row}_${col}')) return false;
    } else if (dx == 0) {
      int col = from.dx.toInt();
      int row = dy == 1 && from.dy < to.dy ? from.dy.toInt() : to.dy.toInt();
      if (placedWalls.contains('H_${row}_${col}')) return false;
    } else {
      return false;
    }
    return true;
  }

  Set<Offset> getPossibleMoves() {
    final currentPlayer = playerTurn == 1 ? player1 : player2;
    final candidates = <Offset>[
      Offset(currentPlayer.dx, currentPlayer.dy - 1),
      Offset(currentPlayer.dx, currentPlayer.dy + 1),
      Offset(currentPlayer.dx - 1, currentPlayer.dy),
      Offset(currentPlayer.dx + 1, currentPlayer.dy),
    ];
    return candidates.where((pos) => canMove(currentPlayer, pos)).toSet();
  }

  void movePlayer(Offset to) {
    if (!possibleMoves.contains(to)) {
      showWarning('Invalid move');
      return;
    }
    setState(() {
      if (playerTurn == 1) {
        player1 = to;
        if (player1.dy == boardSize - 1) {
          showWinDialog(1);
          return;
        }
        playerTurn = 2;
      } else {
        player2 = to;
        if (player2.dy == 0) {
          showWinDialog(2);
          return;
        }
        playerTurn = 1;
      }
      possibleMoves = getPossibleMoves();
      selectedWallType = null;
    });
  }

  void showWinDialog(int winner) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Player $winner Wins!',
          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              resetGame();
            },
            child: const Text('Play Again', style: TextStyle(color: Colors.greenAccent)),
          )
        ],
      ),
    );
  }

  void showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.redAccent),
    );
  }

  void resetGame() {
    setState(() {
      player1 = const Offset(4, 0);
      player2 = const Offset(4, 7);
      player1Walls = 5;
      player2Walls = 5;
      placedWalls.clear();
      playerTurn = 1;
      possibleMoves = getPossibleMoves();
      selectedWallType = null;
    });
  }

  List<Widget> buildWallPlacementSlots() {
    List<Widget> slots = [];

    for (int r = 0; r < boardSize - 1; r++) {
      for (int c = 0; c < boardSize - 1; c++) {
        String hKey = 'H_${r}_$c';
        bool hOccupied = placedWalls.contains(hKey);
        slots.add(Positioned(
          left: c * cellSize,
          top: (r + 1) * cellSize - wallThickness / 2,
          width: cellSize,
          height: wallThickness,
          child: GestureDetector(
            onTap: () {
              if (selectedWallType == WallType.horizontal && !hOccupied) {
                placeWall(WallType.horizontal, Offset(c.toDouble(), r.toDouble()));
              }
            },
            behavior: HitTestBehavior.translucent,
            child: Container(
              color: selectedWallType == WallType.horizontal && !hOccupied
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
        ));

        String vKey = 'V_${r}_$c';
        bool vOccupied = placedWalls.contains(vKey);
        slots.add(Positioned(
          left: (c + 1) * cellSize - wallThickness / 2,
          top: r * cellSize,
          width: wallThickness,
          height: cellSize,
          child: GestureDetector(
            onTap: () {
              if (selectedWallType == WallType.vertical && !vOccupied) {
                placeWall(WallType.vertical, Offset(c.toDouble(), r.toDouble()));
              }
            },
            behavior: HitTestBehavior.translucent,
            child: Container(
              color: selectedWallType == WallType.vertical && !vOccupied
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.transparent,
            ),
          ),
        ));
      }
    }

    return slots;
  }

  @override
  Widget build(BuildContext context) {
    double boardPixelSize = cellSize * boardSize;

    final playerColor = playerTurn == 1 ? Colors.blueAccent : Colors.redAccent;
    final possibleMoveColor = playerColor.withOpacity(0.5);
    final wallColor = Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quoridor Game'),
        centerTitle: true,
        actions: [IconButton(onPressed: resetGame, icon: const Icon(Icons.refresh))],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Turn info and walls left
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  WallCounter(player: 1, wallsLeft: player1Walls, color: Colors.blueAccent),
                  Text(
                    'Player $playerTurn\'s Turn',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: playerColor,
                      shadows: [
                        Shadow(
                          color: playerColor.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  WallCounter(player: 2, wallsLeft: player2Walls, color: Colors.redAccent),
                ],
              ),
            ),

            // Board with border and shadow
            Expanded(
              child: Center(
                child: Container(
                  width: boardPixelSize + 4,
                  height: boardPixelSize + 4,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        offset: const Offset(3, 3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTapUp: (details) {
                          final localPos = details.localPosition;
                          int col = (localPos.dx ~/ cellSize).clamp(0, boardSize - 1);
                          int row = (localPos.dy ~/ cellSize).clamp(0, boardSize - 1);
                          final tappedPos = Offset(col.toDouble(), row.toDouble());

                          if (selectedWallType == null && possibleMoves.contains(tappedPos)) {
                            movePlayer(tappedPos);
                          }
                        },
                        child: CustomPaint(
                          size: Size(boardPixelSize, boardPixelSize),
                          painter: QuoridorPainter(
                            player1: player1,
                            player2: player2,
                            walls: placedWalls,
                            boardSize: boardSize,
                            cellSize: cellSize,
                            possibleMoves: possibleMoves,
                            possibleMoveColor: possibleMoveColor,
                            playerPawnColor: playerColor,
                            wallColor: wallColor,
                            wallThickness: wallThickness,
                          ),
                        ),
                      ),
                      ...buildWallPlacementSlots(),
                    ],
                  ),
                ),
              ),
            ),

            // Wall type selector panel with padding, margin, and shadow
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orangeAccent.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedWallType == WallType.horizontal
                          ? playerTurn == 1  ? Colors.blue : Colors.red
                          : playerTurn == 1 ? Colors.blueAccent.shade200 : Colors.redAccent.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      setState(() {
                        if (selectedWallType == WallType.horizontal) {
                          selectedWallType = null; // toggle off
                        } else {
                          selectedWallType = WallType.horizontal;
                        }
                      });
                    },
                    child: const Text('Horizontal Wall',style: TextStyle(color: Colors.white),),
                  ),
                  const SizedBox(width: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedWallType == WallType.horizontal
                          ? playerTurn == 1  ? Colors.blue : Colors.red
                          : playerTurn == 1 ? Colors.blueAccent.shade200 : Colors.redAccent.shade200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      setState(() {
                        if (selectedWallType == WallType.vertical) {
                          selectedWallType = null; // toggle off
                        } else {
                          selectedWallType = WallType.vertical;
                        }
                      });
                    },
                    child: const Text('Vertical Wall', style: TextStyle(color: Colors.white),),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuoridorPainter extends CustomPainter {
  final Offset player1;
  final Offset player2;
  final Set<String> walls;
  final int boardSize;
  final double cellSize;
  final Set<Offset> possibleMoves;
  final Color possibleMoveColor;
  final Color playerPawnColor;
  final Color wallColor;
  final double wallThickness;

  QuoridorPainter({
    required this.player1,
    required this.player2,
    required this.walls,
    required this.boardSize,
    required this.cellSize,
    required this.possibleMoves,
    required this.possibleMoveColor,
    required this.playerPawnColor,
    required this.wallColor,
    required this.wallThickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellPaint = Paint()..color = Colors.grey.shade600;
    final linePaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 2;

    // Draw grid cells
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        final rect = Rect.fromLTWH(c * cellSize, r * cellSize, cellSize, cellSize);
        canvas.drawRect(rect, cellPaint);
      }
    }

    // Draw grid lines
    for (int i = 0; i <= boardSize; i++) {
      canvas.drawLine(Offset(i * cellSize, 0), Offset(i * cellSize, boardSize * cellSize), linePaint);
      canvas.drawLine(Offset(0, i * cellSize), Offset(boardSize * cellSize, i * cellSize), linePaint);
    }

    // Draw possible moves highlight
    final movePaint = Paint()..color = possibleMoveColor;
    for (final pos in possibleMoves) {
      canvas.drawRect(
        Rect.fromLTWH(pos.dx * cellSize + 6, pos.dy * cellSize + 6, cellSize - 12, cellSize - 12),
        movePaint,
      );
    }

    // Draw players
    final p1Paint = Paint()..color = Colors.blueAccent;
    final p2Paint = Paint()..color = Colors.redAccent;

    canvas.drawCircle(
      Offset(player1.dx * cellSize + cellSize / 2, player1.dy * cellSize + cellSize / 2),
      cellSize / 2.5,
      p1Paint,
    );
    canvas.drawCircle(
      Offset(player2.dx * cellSize + cellSize / 2, player2.dy * cellSize + cellSize / 2),
      cellSize / 2.5,
      p2Paint,
    );

    // Draw walls (one cell long)
    final wallPaint = Paint()
      ..color = wallColor
      ..style = PaintingStyle.fill;

    for (final key in walls) {
      final parts = key.split('_');
      if (parts.length != 3) continue;
      final type = parts[0];
      final r = int.tryParse(parts[1]) ?? 0;
      final c = int.tryParse(parts[2]) ?? 0;

      if (type == 'H') {
        final rect = Rect.fromLTWH(
          c * cellSize,
          (r + 1) * cellSize - wallThickness / 2,
          cellSize,
          wallThickness,
        );
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), wallPaint);
      } else if (type == 'V') {
        final rect = Rect.fromLTWH(
          (c + 1) * cellSize - wallThickness / 2,
          r * cellSize,
          wallThickness,
          cellSize,
        );
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), wallPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WallCounter extends StatelessWidget {
  final int player;
  final int wallsLeft;
  final Color color;

  const WallCounter({
    super.key,
    required this.player,
    required this.wallsLeft,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.wallpaper, color: color),
        const SizedBox(width: 6),
        Text(
          'P$player Walls: $wallsLeft',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
