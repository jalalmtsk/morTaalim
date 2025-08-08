import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageAsset;
  final bool completed;
  final int stars;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final AnimationController bounceController;

  const SectionCard({
    Key? key,
    required this.title,
    required this.subtitle,
    this.imageAsset,
    required this.completed,
    required this.stars,
    required this.color,
    required this.onTap,
    required this.onToggleComplete,
    required this.bounceController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scaleAnim = Tween(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: bounceController, curve: Curves.easeInOut));
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.95), color.withOpacity(0.75)]), borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ScaleTransition(
                      scale: scaleAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 6),
                          Text(subtitle, style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: onToggleComplete,
                        icon: Icon(completed ? Icons.favorite : Icons.favorite_border, color: completed ? Colors.redAccent : Colors.white),
                      ),
                      Row(
                        children: List.generate(3, (i) {
                          final lit = i < stars;
                          return Icon(lit ? Icons.star : Icons.star_border, color: lit ? Colors.amber : Colors.white70, size: 18);
                        }),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              if (imageAsset != null)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Opacity(
                    opacity: 0.9,
                    child: Image.asset(imageAsset!, width: 86, height: 86, fit: BoxFit.contain),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
