import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../XpSystem.dart';
import 'avatarGrid.dart';

class RewardShopPage extends StatelessWidget {
  const RewardShopPage({super.key});

  static const List<Map<String, dynamic>> _avatarItems = [
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
              const SizedBox(height: 12),
              Consumer<ExperienceManager>(
                builder: (context, xpManager, _) =>
                    _StarCounter(stars: xpManager.stars),
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

