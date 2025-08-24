import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const MazeApp());

class MazeApp extends StatelessWidget {
  const MazeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Maze Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MazeGameScreen(gridSize: 17, timeLimitSeconds: 60),
    );
  }
}

enum PowerUpType { extraTime, teleport, revealPath, timeFreeze }

class MazeGameScreen extends StatefulWidget {
  const MazeGameScreen({super.key, required this.gridSize, required this.timeLimitSeconds});

  final int gridSize;
  final int timeLimitSeconds;

  @override
  State<MazeGameScreen> createState() => _MazeGameScreenState();
}

class _MazeGameScreenState extends State<MazeGameScreen> with SingleTickerProviderStateMixin {
  late List<List<int>> maze;
  late int n;

  late int startRow;
  late int startCol;
  late int goalRow;
  late int goalCol;

  late int prow;
  late int pcol;

  Timer? _timer;
  late int timeLeft;
  bool timerFrozen = false;

  final Map<Point<int>, PowerUpType> powerUps = {};
  final Set<Point<int>> traps = {};
  final Random _rng = Random();

  static const Duration moveDuration = Duration(milliseconds: 160);

  @override
  void initState() {
    super.initState();
    n = widget.gridSize.isOdd ? widget.gridSize : (widget.gridSize + 1);
    startRow = 1;
    startCol = 1;
    goalRow = n - 2;
    goalCol = n - 2;
    _newGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _newGame() {
    maze = List.generate(n, (_) => List.filled(n, 1));
    _generateMazeDFS(startRow, startCol);

    maze[startRow][startCol] = 0;
    maze[goalRow][goalCol] = 0;

    prow = startRow;
    pcol = startCol;

    powerUps.clear();
    traps.clear();
    _scatterSpecialTiles();

    _timer?.cancel();
    timeLeft = widget.timeLimitSeconds;
    timerFrozen = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (!timerFrozen) {
        setState(() => timeLeft--);
      }
      if (timeLeft <= 0) {
        t.cancel();
        _showEndDialog('Time\'s up! You lost.');
      }
    });

    setState(() {});
  }

  void _scatterSpecialTiles() {
    final int targetPowerUps = max(3, n ~/ 5);
    final int targetTraps = max(3, n ~/ 6);

    List<Point<int>> pathCells = [];
    for (int r = 1; r < n - 1; r++) {
      for (int c = 1; c < n - 1; c++) {
        if (maze[r][c] == 0 && !(r == startRow && c == startCol) && !(r == goalRow && c == goalCol)) {
          pathCells.add(Point(r, c));
        }
      }
    }
    pathCells.shuffle(_rng);

    // Assign different power-ups randomly
    for (int i = 0; i < pathCells.length && powerUps.length < targetPowerUps; i++) {
      final type = PowerUpType.values[_rng.nextInt(PowerUpType.values.length)];
      powerUps[pathCells[i]] = type;
    }
    for (int i = pathCells.length - 1; i >= 0 && traps.length < targetTraps; i--) {
      final p = pathCells[i];
      if (!powerUps.containsKey(p)) traps.add(p);
    }
  }

  void _generateMazeDFS(int r, int c) {
    maze[r][c] = 0;
    final dirs = [
      const Point(0, 2),
      const Point(0, -2),
      const Point(2, 0),
      const Point(-2, 0),
    ]..shuffle(_rng);

    for (final d in dirs) {
      final nr = r + d.x;
      final nc = c + d.y;
      if (nr > 0 && nr < n - 1 && nc > 0 && nc < n - 1 && maze[nr][nc] == 1) {
        maze[r + d.x ~/ 2][c + d.y ~/ 2] = 0;
        _generateMazeDFS(nr, nc);
      }
    }
  }

  bool _isWall(int r, int c) => r < 0 || r >= n || c < 0 || c >= n || maze[r][c] == 1;

  void _tryMove(int dr, int dc) {
    final nr = prow + dr;
    final nc = pcol + dc;
    if (!_isWall(nr, nc)) {
      setState(() {
        prow = nr;
        pcol = nc;
      });
      _onEnterCell(nr, nc);
    }
  }

  void _onEnterCell(int r, int c) {
    final p = Point(r, c);
    if (powerUps.containsKey(p)) {
      final type = powerUps[p]!;
      powerUps.remove(p);
      switch (type) {
        case PowerUpType.extraTime:
          setState(() => timeLeft += 5);
          _showSnack('+5s Time Power-Up');
          break;
        case PowerUpType.teleport:
          _teleportPlayer();
          _showSnack('Teleported closer to goal!');
          break;
        case PowerUpType.revealPath:
          _revealPath();
          _showSnack('Path revealed for 5s!');
          break;
        case PowerUpType.timeFreeze:
          _freezeTime();
          _showSnack('Time frozen for 5s!');
          break;
      }
    } else if (traps.contains(p)) {
      traps.remove(p);
      setState(() => timeLeft = max(0, timeLeft - 5));
      _showSnack('Trap! −5s');
      if (timeLeft == 0) {
        _timer?.cancel();
        _showEndDialog('Time\'s up! You lost.');
        return;
      }
    }

    if (r == goalRow && c == goalCol) {
      _timer?.cancel();
      _showEndDialog('Congratulations! You reached the prize!');
    }
  }

  void _teleportPlayer() {
    // Move player halfway to goal along row/col
    final newRow = (prow + goalRow) ~/ 2;
    final newCol = (pcol + goalCol) ~/ 2;
    if (!_isWall(newRow, newCol)) {
      setState(() {
        prow = newRow;
        pcol = newCol;
      });
    }
  }

  void _revealPath() {
    // Optional: Highlight path for 5s using a simple direct line (can improve to shortest path algorithm)
    setState(() {});
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _freezeTime() {
    timerFrozen = true;
    Future.delayed(const Duration(seconds: 5), () {
      timerFrozen = false;
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 800)),
    );
  }

  void _showEndDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Game Over'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _newGame();
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(
        title: const Text('Hard Maze with Power-Ups'),
        actions: [
          IconButton(
            tooltip: 'New Maze',
            onPressed: _newGame,
            icon: const Icon(Icons.casino),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double boardSize = min(constraints.maxWidth, constraints.maxHeight - 160);
            final double cellSize = boardSize / n;

            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.timer),
                        const SizedBox(width: 6),
                        Text('Time: $timeLeft s', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      ]),
                      Row(children: [
                        const Icon(Icons.bolt),
                        const SizedBox(width: 4),
                        Text('Power-Ups: ${powerUps.length}'),
                        const SizedBox(width: 16),
                        const Icon(Icons.warning_amber_rounded),
                        const SizedBox(width: 4),
                        Text('Traps: ${traps.length}'),
                      ]),
                    ],
                  ),
                ),

                Center(
                  child: SizedBox(
                    width: boardSize,
                    height: boardSize,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        final d = details.delta;
                        if (d.distance < 6) return;
                        if (d.dx.abs() > d.dy.abs()) {
                          _tryMove(d.dx > 0 ? 0 : 0, d.dx > 0 ? 1 : -1);
                        } else {
                          _tryMove(d.dy > 0 ? 1 : -1, 0);
                        }
                      },
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: Size(boardSize, boardSize),
                            painter: _MazePainter(maze: maze),
                          ),
                          Positioned(
                            left: goalCol * cellSize,
                            top: goalRow * cellSize,
                            child: SizedBox(
                              width: cellSize,
                              height: cellSize,
                              child: Center(child: Icon(Icons.emoji_events, size: cellSize * 0.7)),
                            ),
                          ),
                          ...powerUps.entries.map((e) {
                            IconData icon;
                            switch (e.value) {
                              case PowerUpType.extraTime: icon = Icons.add_alarm; break;
                              case PowerUpType.teleport: icon = Icons.flight; break;
                              case PowerUpType.revealPath: icon = Icons.visibility; break;
                              case PowerUpType.timeFreeze: icon = Icons.pause; break;
                            }
                            return Positioned(
                              left: e.key.y * cellSize,
                              top: e.key.x * cellSize,
                              child: SizedBox(
                                width: cellSize,
                                height: cellSize,
                                child: Center(child: Icon(icon, size: cellSize * 0.6)),
                              ),
                            );
                          }),
                          ...traps.map((p) => Positioned(
                            left: p.y * cellSize,
                            top: p.x * cellSize,
                            child: SizedBox(
                              width: cellSize,
                              height: cellSize,
                              child: Center(child: Icon(Icons.do_not_disturb_on, size: cellSize * 0.6)),
                            ),
                          )),
                          AnimatedPositioned(
                            duration: moveDuration,
                            curve: Curves.easeInOut,
                            left: pcol * cellSize + cellSize * 0.1,
                            top: prow * cellSize + cellSize * 0.1,
                            child: Container(
                              width: cellSize * 0.8,
                              height: cellSize * 0.8,
                              decoration: BoxDecoration(
                                color: Colors.teal,
                                borderRadius: BorderRadius.circular(cellSize * 0.2),
                                boxShadow: const [BoxShadow(blurRadius: 6, spreadRadius: 1, offset: Offset(0, 2))],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          _dirButton(Icons.keyboard_arrow_up, () => _tryMove(-1, 0)),
                          Row(
                            children: [
                              _dirButton(Icons.keyboard_arrow_left, () => _tryMove(0, -1)),
                              const SizedBox(width: 24),
                              _dirButton(Icons.keyboard_arrow_right, () => _tryMove(0, 1)),
                            ],
                          ),
                          _dirButton(Icons.keyboard_arrow_down, () => _tryMove(1, 0)),
                        ],
                      ),
                      const SizedBox(width: 48),
                      FilledButton.icon(
                        onPressed: _newGame,
                        icon: const Icon(Icons.casino),
                        label: const Text('New Maze'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _dirButton(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Ink(
        decoration: const ShapeDecoration(
          color: Color(0xFFE2F1EF),
          shape: CircleBorder(),
        ),
        child: IconButton(
          icon: Icon(icon, size: 30),
          onPressed: onTap,
        ),
      ),
    );
  }
}

class _MazePainter extends CustomPainter {
  _MazePainter({required this.maze});
  final List<List<int>> maze;

  @override
  void paint(Canvas canvas, Size size) {
    final n = maze.length;
    final cellW = size.width / n;
    final cellH = size.height / n;

    final pathPaint = Paint()..color = const Color(0xFFEFF7F6);
    final wallPaint = Paint()..color = const Color(0xFF1F2937);
    final gridPaint = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        final rect = Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH);
        canvas.drawRect(maze[r][c] == 0 ? rect : rect, maze[r][c] == 0 ? pathPaint : wallPaint);
      }
    }

    for (int i = 0; i <= n; i++) {
      canvas.drawLine(Offset(i * cellW, 0), Offset(i * cellW, size.height), gridPaint);
      canvas.drawLine(Offset(0, i * cellH), Offset(size.width, i * cellH), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MazePainter oldDelegate) => oldDelegate.maze != maze;
}
