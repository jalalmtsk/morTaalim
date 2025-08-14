import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'MemoryFlip.dart';

class MemoryFlipLevelSelector extends StatefulWidget {
  final int totalLevels;
  final int unlockedLevel;

  const MemoryFlipLevelSelector({
    super.key,
    required this.totalLevels,
    required this.unlockedLevel,
  });

  @override
  State<MemoryFlipLevelSelector> createState() => _MemoryFlipLevelSelectorState();
}

class _MemoryFlipLevelSelectorState extends State<MemoryFlipLevelSelector> with SingleTickerProviderStateMixin {
  int? _currentUnlocked;
  static const String _prefsKey = 'unlocked_level';

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadUnlockedLevel();

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLevel = prefs.getInt(_prefsKey);
    setState(() {
      _currentUnlocked = savedLevel ?? widget.unlockedLevel;
    });
  }

  Future<void> _saveUnlockedLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, level);
  }

  Future<void> _startLevel(int index) async {
    int? result = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => MemoryGame(startLevel: index),
      ),
    );

    if (result != null && (_currentUnlocked == null || result > _currentUnlocked!)) {
      setState(() {
        _currentUnlocked = result;
      });
      await _saveUnlockedLevel(result);

      if (result < widget.totalLevels) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _startLevel(result);
        });
      }
    }
  }

  Widget _glassmorphicCard({
    required Widget child,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTapDown: (_) => _animationController.reverse(),
      onTapUp: (_) => _animationController.forward(),
      onTapCancel: () => _animationController.forward(),
      onTap: onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.1),
                    offset: const Offset(0, 8),
                    blurRadius: 24,
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
    if (_currentUnlocked == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFE0F7FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    const columns = 3;

    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: const Text("Select Level"),
        actions: [
          // Unlock All Levels
          IconButton(
            icon: const Icon(Icons.lock_open),
            tooltip: "Unlock All",
            onPressed: () async {
              setState(() {
                _currentUnlocked = widget.totalLevels - 1;
              });
              await _saveUnlockedLevel(widget.totalLevels - 1);
            },
          ),
          // Reset Progress
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: "Reset Progress",
            onPressed: () async {
              setState(() {
                _currentUnlocked = 0;
              });
              await _saveUnlockedLevel(0);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -100,
              left: -50,
              child: _buildBlob(180, Colors.pinkAccent.withOpacity(0.15)),
            ),
            Positioned(
              bottom: -120,
              right: -40,
              child: _buildBlob(220, Colors.lightBlueAccent.withOpacity(0.15)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  Text(
                    'Select Level',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.deepPurple.shade700,
                      shadows: [
                        Shadow(
                          color: Colors.deepPurple.shade200.withOpacity(0.5),
                          offset: const Offset(0, 3),
                          blurRadius: 8,
                        )
                      ],
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: widget.totalLevels,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 24,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final unlocked = index <= _currentUnlocked!;

                        return _glassmorphicCard(
                          onTap: unlocked ? () => _startLevel(index) : null,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: unlocked
                                      ? Icon(
                                    Icons.star_rounded,
                                    key: const ValueKey('star'),
                                    size: 35,
                                    color: Colors.amberAccent.shade700,
                                    shadows: const [
                                      Shadow(
                                        blurRadius: 8,
                                        color: Colors.orangeAccent,
                                      )
                                    ],
                                  )
                                      : Icon(
                                    Icons.lock_rounded,
                                    key: const ValueKey('lock'),
                                    size: 35,
                                    color: Colors.deepPurple.shade300,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Level ${index + 1}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: unlocked
                                        ? Colors.deepPurple.shade700
                                        : Colors.deepPurple.shade300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 40,
            spreadRadius: 10,
          )
        ],
      ),
    );
  }
}
