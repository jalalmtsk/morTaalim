import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mortaalim/userStatutBar.dart';
import 'package:provider/provider.dart';

import '../XpSystem.dart';
import 'avatarGrid.dart';
import 'package:mortaalim/Ads_Manager.dart';
class RewardShopPage extends StatelessWidget {
  const RewardShopPage({super.key});

  static const List<Map<String, dynamic>> _avatarItems = [
    {'emoji': '🐱', 'cost': 0},
    {'emoji': '🐻', 'cost': 20},
    {'emoji': '🐶', 'cost': 45},
    {'emoji': '🐥', 'cost': 600},
    {'emoji': '🐵', 'cost': 120},
    {'emoji': '🐸', 'cost': 160},
    {'emoji': '👽', 'cost': 200},
    {'emoji': '🦊', 'cost': 250},
    {'emoji': '🤖', 'cost': 350},
    {'emoji': '🐨', 'cost': 400},
    {'emoji': '🐷', 'cost': 460},
    {'emoji': '🐼', 'cost': 495},
    {'emoji': '🧙‍♂️', 'cost': 640},
    {'emoji': '🦄', 'cost': 800},
    {'emoji': '🐯', 'cost': 1000},
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Userstatutbar(),
              ),
              const SizedBox(height: 12),
              Consumer<ExperienceManager>(
                builder: (context, xpManager, _) =>
                    _StarCounter(stars: xpManager.stars),
              ),
              const SizedBox(height: 12),

              // ⭐ Token Purchase Row
              Consumer<ExperienceManager>(
                builder: (context, xpManager, _) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () {
                          final success = xpManager.buySaveTokens();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? '🎉 You got 1 ⭐!'
                                  : '❌ Not enough Tolims to buy ⭐.'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFC371), Color(0xFFFF5F6D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orangeAccent.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.swap_horiz, color: Colors.white),
                              SizedBox(width: 12),
                              Row(
                                children: [
                                  Text(
                                    'Exchange 3',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Icon(
                                    Icons.generating_tokens_rounded,
                                    color: Colors.green,
                                  ),
                                  Text(
                                    'for 1⭐',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Watch Ad Button
                      InkWell(
                        onTap: () {
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.green, Colors.lightGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: GestureDetector(
                            onTap:() {
                              AdHelper.showRewardedAdWithLoading(context, 1);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.video_library, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  'Watch Ad for 1⭐ & 1 Token',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Expanded(
                child: AvatarGrid(avatarItems: _avatarItems),
              ),
            ],
          ),
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

class _StarCounterState extends State<_StarCounter>
    with SingleTickerProviderStateMixin {
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
                shadows: [
                  Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
