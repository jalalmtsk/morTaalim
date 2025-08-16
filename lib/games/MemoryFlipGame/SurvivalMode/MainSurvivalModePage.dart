import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mortaalim/XpSystem.dart';

import 'SurvivalHighlight.dart'; // Your XP/Tolim manager

class SurvivalMemoryGame extends StatefulWidget {
  final int startingMoves;

  const SurvivalMemoryGame({super.key, this.startingMoves = 100});

  @override
  State<SurvivalMemoryGame> createState() => _SurvivalMemoryGameState();
}

class _SurvivalMemoryGameState extends State<SurvivalMemoryGame>
    with SingleTickerProviderStateMixin {
  final List<String> allImages = List.generate(
    36,
        (index) => 'assets/images/UI/utilities/MemoryFlip_images/${index + 1}.png',
  );

  late List<CardData> _cards;
  bool _waiting = true;
  List<int> _selectedIndices = [];
  bool _canTap = true;
  late int _movesLeft;
  int _matchesMade = 0; // count matches
  late Stopwatch _stopwatch;
  Timer? _timer;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  int bestMatches = 0;
  int bestTimeSeconds = 0;

  @override
  void initState() {
    super.initState();
    _movesLeft = widget.startingMoves;
    _stopwatch = Stopwatch();

    _loadBestScore();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.value = 1.0;

    _startRound();
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bestMatches = prefs.getInt('bestMatches') ?? 0;
      bestTimeSeconds = prefs.getInt('bestTimeSeconds') ?? 0;
    });
  }

  Future<void> _saveBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('bestMatches', bestMatches);
    prefs.setInt('bestTimeSeconds', bestTimeSeconds);
  }

  void _startRound() {
    int pairsCount = 6 + Random().nextInt(7); // 6 to 12 pairs

    final selectedImages = List<String>.from(allImages)..shuffle();
    final levelImages = selectedImages.take(pairsCount).toList();

    _cards = [];
    for (var img in levelImages) {
      _cards.add(CardData(img));
      _cards.add(CardData(img));
    }
    _cards.shuffle();

    _selectedIndices.clear();
    _waiting = true;
    _canTap = false;

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _waiting = false;
        _canTap = true;
      });
      _stopwatch.start();
      _startTimer();
    });

    setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _onCardTap(int index) {
    if (_waiting || !_canTap) return;
    if (_cards[index].isMatched || _selectedIndices.contains(index)) return;

    setState(() {
      _movesLeft--;
      if (_movesLeft <= 0) {
        _stopwatch.stop();
        _timer?.cancel();
        _showGameOverDialog();
        return;
      }

      _selectedIndices.add(index);

      if (_selectedIndices.length == 2) {
        _canTap = false;
        final first = _selectedIndices[0];
        final second = _selectedIndices[1];

        if (_cards[first].imagePath == _cards[second].imagePath) {
          _cards[first].isMatched = true;
          _cards[second].isMatched = true;
          _selectedIndices.clear();
          _canTap = true;

          _matchesMade++;

          // Every 20 matches -> give Tolim + XP
          if (_matchesMade % 20 == 0) {
            final xpManager =
            Provider.of<ExperienceManager>(context, listen: false);
            xpManager.addXP(context: context, 5);
            xpManager.addTokenBanner(context, 1);
          }

          if (_cards.every((c) => c.isMatched)) {
            _startRound(); // start new set of cards
          }
        } else {
          Timer(const Duration(milliseconds: 700), () {
            if (!mounted) return;
            setState(() {
              _selectedIndices.clear();
              _canTap = true;
            });
          });
        }
      }
    });
  }

  void _showGameOverDialog() {
    int elapsedSeconds = _stopwatch.elapsed.inSeconds;

    // Save best score if beaten
    if (_matchesMade > bestMatches ||
        (_matchesMade == bestMatches && elapsedSeconds < bestTimeSeconds)) {
      bestMatches = _matchesMade;
      bestTimeSeconds = elapsedSeconds;
      _saveBestScore();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Game Over', style: TextStyle(color: Colors.deepPurple)),
        content: Text(
            'You survived for ${elapsedSeconds}s and made $_matchesMade matches.\n\nBest: $bestMatches matches in $bestTimeSeconds seconds.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _movesLeft = widget.startingMoves;
                _matchesMade = 0;
                _stopwatch.reset();
                _startRound();
              });
            },
            child: Text('Restart', style: TextStyle(color: Colors.deepPurple.shade700)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SurvivalHighlightsPage(
                    bestMatches: bestMatches,
                    bestTimeSeconds: bestTimeSeconds,
                  ),
                ),
              );
            },
            child: Text('Highlights', style: TextStyle(color: Colors.deepPurple.shade700)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    _animationController.dispose();
    super.dispose();
  }

  Widget _glassmorphicCard({required Widget child, required VoidCallback? onTap}) {
    return GestureDetector(
      onTapDown: (_) => _animationController.reverse(),
      onTapUp: (_) => _animationController.forward(),
      onTapCancel: () => _animationController.forward(),
      onTap: onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.07),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.1),
                    offset: const Offset(0, 6),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int columns = _cards.length <= 12 ? 3 : 4;
    final elapsed = _stopwatch.elapsed;
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (_) => SurvivalHighlightsPage(bestMatches: bestMatches, bestTimeSeconds: bestTimeSeconds)));
          }, icon: Icon(Icons.score))
        ],
        centerTitle: true,
        title: Text(
          'Survival Mode',
          style: TextStyle(
            color: Colors.deepPurple.shade700,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: 1.1,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.deepPurple.shade700),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusTile(icon: Icons.timer, label: '$minutes:$seconds'),
                StatusTile(icon: Icons.swap_calls, label: 'Moves: $_movesLeft'),
                StatusTile(icon: Icons.star, label: 'Matches: $_matchesMade'),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: _cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  final showFace = _waiting || card.isMatched || _selectedIndices.contains(index);

                  return _glassmorphicCard(
                    onTap: () => _onCardTap(index),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: showFace
                          ? Image.asset(
                        card.imagePath,
                        key: ValueKey(card.imagePath),
                        fit: BoxFit.contain,
                      )
                          : Container(
                        key: const ValueKey('back'),
                        color: Colors.deepPurple.withOpacity(0.1),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- Helper Widgets --------------------

class StatusTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const StatusTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.deepPurple.shade400),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.deepPurple.shade700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class CardData {
  final String imagePath;
  bool isMatched;
  CardData(this.imagePath, {this.isMatched = false});
}
