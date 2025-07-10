import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';


MusicPlayerOne rightLeft_sound = MusicPlayerOne();
MusicPlayerOne backGround_sound = MusicPlayerOne();
MusicPlayerOne score_sound = MusicPlayerOne();
MusicPlayerOne explosion_sound = MusicPlayerOne();

class JumpingJellyApp extends StatelessWidget {
  const JumpingJellyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const JumpingJellyGame();
  }
}

class JumpingJellyGame extends StatefulWidget {
  const JumpingJellyGame({super.key});

  @override
  State<JumpingJellyGame> createState() => _JumpingJellyGameState();
}

enum TileType {
  empty,
  safe,
  trap,
  star,
  doublePoints, // Purple tile
  extraLife,    // Pink tile
  magnet        // Cyan tile
}

class _JumpingJellyGameState extends State<JumpingJellyGame> {
  static const int rows = 12;
  static const int cols = 3;

  late List<List<TileType>> grid;
  int playerCol = 1;
  int score = 0;
  int _lastTokenScoreAwarded = 0;
  int lives = 3;
  bool isGameOver = false;
  bool isPaused = false;

  final Random random = Random();
  Timer? gameLoop;
  int gameSpeedMs = 600;

  int consecutiveStars = 0;
  int scoreMultiplier = 1;

  // Bonus state
  bool doublePointsActive = false;
  Timer? doublePointsTimer;
  int doublePointsSecondsLeft = 0;
  Timer? doublePointsCountdownTimer;

  bool magnetActive = false;
  Timer? magnetTimer;
  int magnetSecondsLeft = 0;
  Timer? magnetCountdownTimer;

  // Your ExperienceManager instance - assign properly!
  // You can use Provider, or pass via constructor, etc.
  // For this example, it's null and needs to be assigned
  dynamic experienceManager;

  @override
  void initState() {
    super.initState();

    rightLeft_sound.preload("assets/audios/sound_effects/retro-rightLeft.mp3");
    score_sound.preload("assets/audios/sound_effects/retro-coin.mp3");
    explosion_sound.preload("assets/audios/sound_effects/retro-explode.mp3");
    backGround_sound.play("assets/audios/sound_track/arcade-beat.mp3", loop: true);

    _initGrid();
    _spawnPlatforms();
    _startGameLoop();
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (experienceManager == null) {
      experienceManager = Provider.of<ExperienceManager>(context, listen: false);
    }

    // Ensure background music is playing
    backGround_sound.play("assets/audios/sound_track/arcade-beat.mp3", loop: true);
  }


  void _initGrid() {
    grid = List.generate(rows, (_) => List.generate(cols, (_) => TileType.empty));
  }

  void _startGameLoop() {
    gameLoop?.cancel();
    gameLoop = Timer.periodic(Duration(milliseconds: gameSpeedMs), (timer) {
      if (!isPaused && !isGameOver) {
        setState(() {
          _moveGridUp();
          _spawnPlatforms();
          _checkCollision();
          _checkMagnetCollect();
          _adjustSpeed();
        });
      }
    });
  }

  void _adjustSpeed() {
    int newSpeed = 600 - (score ~/ 10) * 50;
    if (newSpeed < 200) newSpeed = 200;
    if (newSpeed != gameSpeedMs) {
      gameSpeedMs = newSpeed;
      _startGameLoop();
    }
  }

  void _moveGridUp() {
    grid.removeAt(0);
    grid.add(List.generate(cols, (_) => TileType.empty));
  }

  Set<int> previousSafeCols = {1};        // Safe tiles in last spawned row
  Set<int> prePreviousSafeCols = {1};     // Safe tiles row before last

  void _spawnPlatforms() {
    List<TileType> newRow = List.generate(cols, (_) => TileType.empty);

    // Allowed safe columns adjacent to previousSafeCols
    Set<int> allowedColsPrev = {};
    for (int col in previousSafeCols) {
      allowedColsPrev.add(col);
      if (col > 0) allowedColsPrev.add(col - 1);
      if (col < cols - 1) allowedColsPrev.add(col + 1);
    }

    // Allowed safe columns adjacent to prePreviousSafeCols
    Set<int> allowedColsPrePrev = {};
    for (int col in prePreviousSafeCols) {
      allowedColsPrePrev.add(col);
      if (col > 0) allowedColsPrePrev.add(col - 1);
      if (col < cols - 1) allowedColsPrePrev.add(col + 1);
    }

    // Intersection to ensure path
    Set<int> allowedSafeCols = allowedColsPrev.intersection(allowedColsPrePrev);

    // Fallback if empty
    if (allowedSafeCols.isEmpty) {
      allowedSafeCols = allowedColsPrev.isNotEmpty ? allowedColsPrev : {0, 1, 2};
    }

    int safeCount = random.nextBool() ? 1 : 2;
    safeCount = safeCount.clamp(1, allowedSafeCols.length);

    Set<int> safeCols = {};
    List<int> allowedSafeList = allowedSafeCols.toList();

    while (safeCols.length < safeCount) {
      safeCols.add(allowedSafeList[random.nextInt(allowedSafeList.length)]);
    }

    // Place safe/bonus tiles
    for (int col in safeCols) {
      double r = random.nextDouble();
      if (r < 0.10) {
        newRow[col] = TileType.doublePoints;
      } else if (r < 0.13) {
        newRow[col] = TileType.extraLife;
      } else if (r < 0.14) {
        newRow[col] = TileType.magnet;
      } else if (r < 0.44) {
        newRow[col] = TileType.star;
      } else {
        newRow[col] = TileType.safe;
      }
    }

    // Fill others with traps 50% chance
    for (int c = 0; c < cols; c++) {
      if (!safeCols.contains(c) && random.nextDouble() < 0.5) {
        newRow[c] = TileType.trap;
      }
    }

    grid[rows - 1] = newRow;

    prePreviousSafeCols = previousSafeCols;
    previousSafeCols = safeCols;
  }

  void _movePlayer(int direction) {
    if (isGameOver || isPaused) return;
    rightLeft_sound.play("assets/audios/sound_effects/retro-rightLeft.mp3");
    setState(() {
      playerCol = (playerCol + direction).clamp(0, cols - 1);
      _checkCollision();
    });
  }

  void _checkCollision() {
    TileType tile = grid[0][playerCol];
    if (tile == TileType.trap) {
      if (!magnetActive) {
        explosion_sound.play("assets/audios/sound_effects/retro-explode.mp3");
        lives--;
        consecutiveStars = 0;
        scoreMultiplier = 1;
        if (lives <= 0) {
          isGameOver = true;
          gameLoop?.cancel();
          _showGameOverDialog();

          _awardTolimTokens();
        }
      }
    } else if (tile == TileType.star) {
      score_sound.play("assets/audios/sound_effects/retro-coin.mp3");
      int pointsToAdd = doublePointsActive ? scoreMultiplier * 2 : scoreMultiplier;
      score += pointsToAdd;
      consecutiveStars++;
      grid[0][playerCol] = TileType.safe;

      _awardTolimTokens();

      if (consecutiveStars % 5 == 0) {
        scoreMultiplier++;
      }
    } else if (tile == TileType.doublePoints) {
      _activateDoublePoints();
      grid[0][playerCol] = TileType.safe;
    } else if (tile == TileType.extraLife) {
      if (lives < 5) {
        lives++;
      }
      grid[0][playerCol] = TileType.safe;
    } else if (tile == TileType.magnet) {
      _activateMagnet();
      grid[0][playerCol] = TileType.safe;
    } else {
      consecutiveStars = 0;
      scoreMultiplier = 1;
    }
  }

  void _awardTolimTokens() {
    if (experienceManager != null) {
      int tokensToAward = (score ~/ 10) - (_lastTokenScoreAwarded ~/ 10);
      if (tokensToAward > 0) {
        print('✅ Awarding $tokensToAward token(s) for score: $score');
        experienceManager.addTokens(tokensToAward);
        _lastTokenScoreAwarded = (score ~/ 10) * 10;
      }
    } else {
      print('⚠ experienceManager is null');
    }
  }



  void _activateDoublePoints() {
    doublePointsTimer?.cancel();
    doublePointsCountdownTimer?.cancel();

    doublePointsActive = true;
    doublePointsSecondsLeft = 5;
    _startDoublePointsCountdown();

    setState(() {});

    doublePointsTimer = Timer(Duration(seconds: 5), () {
      setState(() {
        doublePointsActive = false;
        doublePointsSecondsLeft = 0;
      });
    });
  }

  void _startDoublePointsCountdown() {
    doublePointsCountdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (doublePointsSecondsLeft > 0) {
          doublePointsSecondsLeft--;
        } else {
          doublePointsCountdownTimer?.cancel();
        }
      });
    });
  }

  void _activateMagnet() {
    magnetTimer?.cancel();
    magnetCountdownTimer?.cancel();

    magnetActive = true;
    magnetSecondsLeft = 7;
    _startMagnetCountdown();

    setState(() {});

    magnetTimer = Timer(Duration(seconds: 7), () {
      setState(() {
        magnetActive = false;
        magnetSecondsLeft = 0;
      });
    });
  }

  void _startMagnetCountdown() {
    magnetCountdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (magnetSecondsLeft > 0) {
          magnetSecondsLeft--;
        } else {
          magnetCountdownTimer?.cancel();
        }
      });
    });
  }

  void _checkMagnetCollect() {
    if (!magnetActive) return;

    bool collectedAny = false;

    // Collect stars automatically in bottom 3 rows
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c] == TileType.star) {
          score_sound.play("assets/audios/sound_effects/retro-coin.mp3");
          int pointsToAdd = doublePointsActive ? scoreMultiplier * 2 : scoreMultiplier;
          score += pointsToAdd;
          grid[r][c] = TileType.safe;
          collectedAny = true;
        }
      }
    }

    if (collectedAny) {
      _awardTolimTokens();
      setState(() {});
    }
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Game Over 💥'),
        content: Text('Your score: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _lastTokenScoreAwarded = 0;
      score = 0;
      lives = 3;
      playerCol = 1;
      isGameOver = false;
      consecutiveStars = 0;
      scoreMultiplier = 1;
      isPaused = false;
      doublePointsActive = false;
      magnetActive = false;
      doublePointsTimer?.cancel();
      magnetTimer?.cancel();
      doublePointsCountdownTimer?.cancel();
      magnetCountdownTimer?.cancel();
      doublePointsSecondsLeft = 0;
      magnetSecondsLeft = 0;
      _initGrid();
    });
    _spawnPlatforms();
    _startGameLoop();
  }

  void _togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
  }

  void _onHorizontalDrag(DragUpdateDetails details) {
    if (details.delta.dx > 5) {
      _movePlayer(1);
    } else if (details.delta.dx < -5) {
      _movePlayer(-1);
    }
  }

  @override
  void dispose() {
    super.dispose();
    score_sound.dispose();
    explosion_sound.dispose();
    backGround_sound.dispose();
    rightLeft_sound.dispose();
    doublePointsTimer?.cancel();
    magnetTimer?.cancel();
    doublePointsCountdownTimer?.cancel();
    magnetCountdownTimer?.cancel();
  }

  Widget _buildTile(TileType type, bool isPlayerHere) {
    Color color;
    IconData? icon;

    switch (type) {
      case TileType.empty:
        color = Colors.transparent;
        break;
      case TileType.safe:
        color = Colors.green.shade400;
        break;
      case TileType.trap:
        color = Colors.red.shade800;
        icon = Icons.close;
        break;
      case TileType.star:
        color = Colors.amber.shade400;
        icon = Icons.star;
        break;
      case TileType.doublePoints:
        color = Colors.purple.shade600;
        icon = Icons.flash_on;
        break;
      case TileType.extraLife:
        color = Colors.pink.shade400;
        icon = Icons.favorite;
        break;
      case TileType.magnet:
        color = Colors.cyan.shade400;
        icon = Icons.toll_sharp;
        break;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isPlayerHere ? Colors.yellow.shade700 : color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Center(
        child: isPlayerHere
            ? const Icon(Icons.emoji_emotions, size: 36, color: Colors.black)
            : icon != null
            ? Icon(icon, size: 24, color: Colors.white)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDrag,
      child: Scaffold(
        backgroundColor: Colors.blueGrey.shade900,
        appBar: AppBar(
          title: const Text('🍬 Jumping Jelly'),
          backgroundColor: Colors.deepPurpleAccent,
          actions: [
            if (doublePointsActive)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Icon(Icons.flash_on, color: Colors.purple.shade200),
                    const SizedBox(width: 4),
                    Text('$doublePointsSecondsLeft s',
                        style: TextStyle(color: Colors.purple.shade200, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            if (magnetActive)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Icon(Icons.toll_sharp, color: Colors.cyan.shade200),
                    const SizedBox(width: 4),
                    Text('$magnetSecondsLeft s',
                        style: TextStyle(color: Colors.cyan.shade200, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            IconButton(
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
              onPressed: _togglePause,
              tooltip: isPaused ? 'Resume' : 'Pause',
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Userstatutbar(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('⭐ Score: $score', style: const TextStyle(fontSize: 20)),
                  Text('❤ Lives: $lives', style: const TextStyle(fontSize: 20)),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _resetGame,
                    tooltip: 'Restart Game',
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                ),
                itemCount: rows * cols,
                itemBuilder: (context, index) {
                  int row = index ~/ cols;
                  int col = index % cols;
                  bool isPlayer = row == 0 && col == playerCol;
                  return _buildTile(grid[row][col], isPlayer);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    onPressed: () => _movePlayer(-1),
                    child: const Icon(Icons.arrow_left, size: 32),
                  ),
                  ElevatedButton(
                    onPressed: () => _movePlayer(1),
                    child: const Icon(Icons.arrow_right, size: 32),
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
