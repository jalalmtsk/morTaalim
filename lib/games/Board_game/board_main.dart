import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:provider/provider.dart';
import 'package:mortaalim/l10n/app_localizations.dart';
import '../../XpSystem.dart';



class BoardGameApp extends StatelessWidget {
  const BoardGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const BoardGamePage();
  }
}

class BoardGamePage extends StatefulWidget {
  const BoardGamePage({super.key});

  @override
  State<BoardGamePage> createState() => _BoardGamePageState();
}

final MusicPlayer _musicPlayer = MusicPlayer();
class _BoardGamePageState extends State<BoardGamePage>
    with SingleTickerProviderStateMixin {
  static const int boardLength = 15;
  static const int maxLives = 3;
  final Random _random = Random();
  final Duration scrollSpeed = const Duration(milliseconds: 1200);

  late List<bool> board;
  int playerPosition = 0;
  int score = 0;
  int lives = maxLives;
  int lastXpAwardedScore = 0;

  Timer? timer;
  bool gameRunning = false;
  bool waitingAfterLifeLost = false;

  late AnimationController _playerAnimController;
  late Animation<double> _playerBounceAnim;

  @override
  void initState() {
    super.initState();
    _generateBoard();

    _playerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _playerBounceAnim = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _playerAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _playerAnimController.dispose();
    _musicPlayer.dispose();
    super.dispose();
  }

  void _generateBoard() {
    board = List.generate(boardLength, (index) => true);
    for (int i = 1; i < boardLength; i++) {
      board[i] = _random.nextInt(5) != 0;
    }
    playerPosition = 0;
    score = 0;
    lives = maxLives;
    gameRunning = false;
    waitingAfterLifeLost = false;
    timer?.cancel();
  }

  void _startBoardScroll() {
    _musicPlayer.play("assets/audios/sound_track/happy.mp3");
    if (gameRunning) return;
    timer?.cancel();
    gameRunning = true;

    final xpManager = Provider.of<ExperienceManager>(context, listen: false);

    timer = Timer.periodic(scrollSpeed, (timer) {
      setState(() {
        board.removeAt(0);
        board.add(_random.nextInt(5) != 0);

        if (playerPosition > 0) playerPosition--;

        score++;

        // Award XP every 10 points
        if (score - lastXpAwardedScore >= 20) {
          lastXpAwardedScore = score;
          xpManager.addXP(2);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: Duration(seconds: 1),
                content: Text('You earned 10 XP! Total XP: ${xpManager.xp}')),
          );
        }

        if (!board[playerPosition]) {
          lives--;
          timer.cancel();
          gameRunning = false;

          if (lives == 0) {
            int starsEarned = (score / 20).floor();
            if (starsEarned > 0) {
              xpManager.addStarBanner(context, starsEarned);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                    Text('You earned $starsEarned star(s)! Total Stars: ${xpManager.stars}')),
              );
            }
            _showGameOverDialog(xpManager);
          } else {
            waitingAfterLifeLost = true;
            _showLifeLostDialog();
          }
        }
      });
    });
  }

  Future<void> _showGameOverDialog(ExperienceManager xpManager) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Game Over🎮"),
        content: Text('Final score: $score\nXP: ${xpManager.xp}\nStars: ${xpManager.stars}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _generateBoard();
                lastXpAwardedScore = 0;
              });
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void _showLifeLostDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Oops! You fell!'),
        content: Text('You lost a life. Lives left: $lives'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                playerPosition = 0;
              });
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    ).then((_) {
      setState(() {
        waitingAfterLifeLost = false;
        _startBoardScroll();
      });
    });
  }

  void _jump() {
    if (!gameRunning) return;
    if (playerPosition < boardLength - 3) {
      setState(() {
        playerPosition += 2;
        if (!board[playerPosition]) _handleFall();
      });
    }
  }

  void _step() {
    if (!gameRunning) return;
    if (playerPosition < boardLength - 1) {
      setState(() {
        playerPosition += 1;
        if (!board[playerPosition]) _handleFall();
      });
    }
  }

  void _handleFall() {
    lives--;
    timer?.cancel();
    gameRunning = false;
    if (lives == 0) {
      final xpManager = Provider.of<ExperienceManager>(context, listen: false);
      _showGameOverDialog(xpManager);
    } else {
      waitingAfterLifeLost = true;
      _showLifeLostDialog();
    }
  }

  Widget _buildBoard() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: board.length,
        itemBuilder: (context, index) {
          final isPlayerHere = index == playerPosition;
          return Container(
            width: 60,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: board[index] ? Colors.green.shade400 : Colors.brown.shade700,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (board[index])
                  BoxShadow(
                    color: Colors.greenAccent.shade100.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
              ],
              border: isPlayerHere
                  ? Border.all(color: Colors.yellowAccent, width: 5)
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isPlayerHere)
                  AnimatedBuilder(
                    animation: _playerBounceAnim,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _playerBounceAnim.value),
                        child: child,
                      );
                    },
                    child: const Icon(
                      Icons.person_3,
                      color: Colors.yellow,
                      size: 36,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final tr = AppLocalizations.of(context)!;
    final textStyleHeader = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.deepOrange.shade700,
      shadows: const [Shadow(blurRadius: 3, color: Colors.black26, offset: Offset(1, 1))],
    );

    final textStyleBody = TextStyle(fontSize: 18, color: Colors.grey.shade800);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: "Back",
        ),
        title:  Text(tr.funBoardGame),
        backgroundColor: Colors.deepOrange,
        elevation: 8,
        shadowColor: Colors.deepOrangeAccent.withOpacity(0.8),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade100, Colors.deepOrange.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Lives & Score row with icons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _IconWithText(
                  icon: Icons.favorite,
                  iconColor: Colors.redAccent.shade400,
                  text: '$lives',
                  textStyle: textStyleHeader,
                ),
                const SizedBox(width: 40),
                _IconWithText(
                  icon: Icons.polymer,
                  iconColor: Colors.amber.shade600,
                  text: '$score',
                  textStyle: textStyleHeader,
                ),
              ],
            ),

            ElevatedButton(onPressed: (){
                xpManager.addStarBanner(context,20);
            }, child: Text("LOL")),
            const SizedBox(height: 30),
            Text(
              "${tr.tapStepOrJumpToMoveForward} ${tr.avoidTheHolesBoardScrollsOnlyWhenYouStart}",
              textAlign: TextAlign.center,
              style: textStyleBody,
            ),
            const SizedBox(height: 30),
            _buildBoard(),
            const Spacer(),
            if (!gameRunning && !waitingAfterLifeLost)
              ElevatedButton(
                onPressed: _startBoardScroll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 6,
                  shadowColor: Colors.deepOrangeAccent.withOpacity(0.9),
                ),
                child:  Text(
                  tr.startGame,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              )
            else
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _GameActionButton(
                      label: tr.step,
                      onPressed: _step,
                      enabled: gameRunning,
                    ),
                    _GameActionButton(
                      label: tr.jump,
                      onPressed: _jump,
                      enabled: gameRunning,
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

class _IconWithText extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final TextStyle textStyle;

  const _IconWithText({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 36),
        const SizedBox(width: 8),
        Text(text, style: textStyle),
      ],
    );
  }
}

class _GameActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  const _GameActionButton({
    required this.label,
    required this.onPressed,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = enabled ? Colors.deepOrange : Colors.grey.shade400;
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: enabled ? 5 : 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}
