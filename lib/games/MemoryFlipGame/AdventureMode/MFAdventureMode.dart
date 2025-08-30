import 'dart:async';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mortaalim/games/MemoryFlipGame/AdventureMode/Tools/LevelUpDialogFlipMemory.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../XpSystem.dart';
import 'CategoryOfImages_Data.dart';



/// ---------------- GAME MODE ----------------
class MFAdventureMode extends StatefulWidget {
  final int startLevel;
  final String category;

  const MFAdventureMode({
    super.key,
    required this.startLevel,
    required this.category,
  });

  @override
  State<MFAdventureMode> createState() => _MFAdventureModeState();
}

class _MFAdventureModeState extends State<MFAdventureMode>
    with SingleTickerProviderStateMixin {
  late List<String> allImages;
  late int currentLevel;
  late List<_CardData> _cards;
  bool _waiting = true;
  List<int> _selectedIndices = [];
  bool _canTap = true;
  int _movesLeft = 30;
  late Stopwatch _stopwatch;
  Timer? _timer;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  Set<int> _completedLevels = {};

  @override
  void initState() {
    super.initState();
    currentLevel = widget.startLevel;

    // Load images for chosen category
    allImages = categoryImages[widget.category] ?? [];

    _stopwatch = Stopwatch();
    _loadCompletedLevels();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _scaleAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _animationController.value = 1.0;

    _startLevel();
  }

  Future<void> _loadCompletedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final completed =
        prefs.getStringList('completedLevels_${widget.category}') ?? [];
    setState(() {
      _completedLevels = completed.map(int.parse).toSet();
    });
  }

  Future<void> _saveCompletedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
      'completedLevels_${widget.category}',
      _completedLevels.map((e) => e.toString()).toList(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    _animationController.dispose();
    super.dispose();
  }

  void _startLevel() {
    int pairsCount = (3 + (currentLevel ~/ 2)).clamp(3, 12);

    final random = Random();
    final selectedImages = List<String>.from(allImages)..shuffle(random);
    final levelImages = selectedImages.take(pairsCount).toList();

    _cards = [];
    for (var img in levelImages) {
      _cards.add(_CardData(img));
      _cards.add(_CardData(img));
    }
    _cards.shuffle(random);

    _movesLeft = 30;
    _selectedIndices.clear();
    _waiting = true;
    _canTap = false;
    _stopwatch.reset();

    int previewSeconds = (4 - (currentLevel ~/ 2)).clamp(1, 4);
    Timer(Duration(seconds: previewSeconds), () {
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
        _showOutOfMovesDialog();
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

          if (_cards.every((c) => c.isMatched)) {
            _stopwatch.stop();
            _timer?.cancel();
            _finishLevel();
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

  void _showOutOfMovesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:  Text(tr(context).noMovesLeft,
            style: TextStyle(color: Colors.deepPurple)),
        content:  Text("${tr(context).youRanOutOfMoves}. ${tr(context).restartingLevel}",
            style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startLevel();
            },
            child: Text(tr(context).restart,
                style: TextStyle(color: Colors.deepPurple.shade700)),
          ),
        ],
      ),
    );
  }

  void _finishLevel() async {
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);

    // Give XP for completing the level
    xpManager.addXP(2, context: context);

    // Small delay for animations
    await Future.delayed(const Duration(seconds: 1));

    // Mark level as completed and give token
    if (!_completedLevels.contains(currentLevel)) {
      _completedLevels.add(currentLevel);
      xpManager.addTokenBanner(context, 1); // Give 1 Tolim
      await _saveCompletedLevels();
    }

    // Calculate next level, cap at 50
    final int nextLevel = (currentLevel + 1).clamp(0, 50);

    // Show the LevelUpDialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LevelUpDialogFlipMemory(
        nextLevel: nextLevel,
        onContinue: () {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(nextLevel); // Return next level
        },
      ),
    );
  }



  Widget _glassmorphicCard(
      {required Widget child, required VoidCallback? onTap}) {
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
        centerTitle: true,
        title: Text(
          '${widget.category} - ${tr(context).level} ${currentLevel + 1}',
          style: TextStyle(
            color: Colors.deepPurple.shade700,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: 1.1,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.deepPurple.shade700),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Userstatutbar(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusTile(icon: Icons.timer, label: '$minutes:$seconds'),
                _StatusTile(icon: Icons.swap_calls, label: '${tr(context).moves}: $_movesLeft'),
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
                  final showFace =
                      _waiting || card.isMatched || _selectedIndices.contains(index);

                  return _glassmorphicCard(
                    onTap: () {
                      audioManager.playEventSound('PopButton');
                      _onCardTap(index);
                    },
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

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatusTile({required this.icon, required this.label});

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

class _CardData {
  final String imagePath;
  bool isMatched;
  _CardData(this.imagePath, {this.isMatched = false});
}

