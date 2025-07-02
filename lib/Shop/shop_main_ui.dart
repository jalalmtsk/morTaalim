import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../XpSystem.dart';

class RewardShopPage extends StatelessWidget {
  const RewardShopPage({super.key});

  final List<Map<String, dynamic>> _avatarItems = const [
    {'emoji': '🐱', 'cost': 0},
    {'emoji': '🐻', 'cost': 4},
    {'emoji': '🐶', 'cost': 0},
    {'emoji': '🐵', 'cost': 0},
    {'emoji': '🐸', 'cost': 0},
    {'emoji': '🦄', 'cost': 0},
    {'emoji': '🧙‍♂️', 'cost': 0},
    {'emoji': '🐥', 'cost': 30},
    {'emoji': '👽', 'cost': 30},
    {'emoji': '🦊', 'cost': 30},
    {'emoji': '🤖', 'cost': 35},
    {'emoji': '🐨', 'cost': 35},
    {'emoji': '🐷', 'cost': 35},
    {'emoji': '🐼', 'cost': 35},
    {'emoji': '🐯', 'cost': 300},
  ];

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back)),
        title: const Text("🎁 Avatar Reward Shop"),
        backgroundColor: Colors.deepOrangeAccent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFff9966),
              Color(0xFFff5e62),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              _StarCounter(stars: xpManager.stars),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _avatarItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (_, index) {
                    final item = _avatarItems[index];
                    final emoji = item['emoji'];
                    final cost = item['cost'];
                    final unlocked = xpManager.unlockedAvatars.contains(emoji);
                    final selected = xpManager.selectedAvatar == emoji;

                    final canBuy = !unlocked && (xpManager.stars >= cost);
                    final isExpensive = cost >= 30;

                    Widget avatarCard = GestureDetector(
                      onTap: () {
                        if (unlocked) {
                          xpManager.selectAvatar(emoji);
                        } else if (canBuy) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Confirm Purchase"),
                              content: Text("Do you want to unlock $emoji for $cost ⭐?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context), // Cancel
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    xpManager.addStars(-cost);
                                    xpManager.unlockAvatar(emoji);
                                    xpManager.selectAvatar(emoji);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$emoji Unlocked! Enjoy!'),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Colors.deepOrangeAccent,
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    "Buy",
                                    style: TextStyle(color: Colors.deepOrange),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else if (!unlocked) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Not enough stars! Keep playing to earn more.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        decoration: BoxDecoration(
                          color: unlocked ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: selected ? Colors.greenAccent.withOpacity(0.7) : Colors.black26,
                              blurRadius: selected ? 15 : 7,
                              spreadRadius: selected ? 3 : 1,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: selected
                                ? Colors.greenAccent
                                : unlocked
                                ? Colors.orange
                                : Colors.grey.shade400,
                            width: selected ? 4 : 2,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                emoji,
                                style: TextStyle(
                                  fontSize: 52,
                                  shadows: selected
                                      ? [
                                    Shadow(
                                      color: Colors.greenAccent.withOpacity(0.7),
                                      blurRadius: 15,
                                      offset: const Offset(0, 0),
                                    )
                                  ]
                                      : null,
                                ),
                              ),
                            ),

                            // Badge ribbons
                            if (selected)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: _RibbonBadge(
                                  text: 'SELECTED',
                                  color: Colors.greenAccent.shade700,
                                ),
                              )
                            else if (unlocked)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: _RibbonBadge(
                                  text: 'UNLOCKED',
                                  color: Colors.orange.shade700,
                                ),
                              ),

                            if (!unlocked)
                              Positioned(
                                bottom: 10,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: isExpensive
                                      ? Shimmer.fromColors(
                                    baseColor: Colors.deepOrange.shade700,
                                    highlightColor: Colors.yellow.shade400,
                                    child: Text(
                                      '$cost ⭐',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 4,
                                            color: Colors.black54,
                                            offset: Offset(0, 0),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                      : Text(
                                    '$cost ⭐',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );

                    return avatarCard;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RibbonBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _RibbonBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.7),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _StarCounter extends StatefulWidget {
  final int stars;

  const _StarCounter({required this.stars});

  @override
  State<_StarCounter> createState() => _StarCounterState();
}

class _StarCounterState extends State<_StarCounter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant _StarCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stars != widget.stars) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _bounceAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.amber.shade700,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.shade400,
              blurRadius: 10,
              spreadRadius: 3,
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 32, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              '${widget.stars}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
