import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageAsset;
  final bool completed;
  final int points; // CoursePoints earned (0..3)
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onToggleComplete;
  final AnimationController bounceController;

  const SectionCard({
    Key? key,
    required this.title,
    required this.subtitle,
    this.imageAsset,
    required this.completed,
    required this.color,
    required this.onTap,
    this.onToggleComplete,  // now nullable
    required this.points,
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.75)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(22),
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
                          const SizedBox(height: 2),
                          Text(subtitle, style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: onToggleComplete, // safely allows null
                        icon: Icon(
                          completed ? Icons.favorite : Icons.favorite_border,
                          color: completed ? Colors.red : Colors.white,
                          size: 25,
                        ),
                      ),
                      Row(
                        children: List.generate(2, (i) {
                          final lit = i < points;
                          return Icon(
                            lit ? Icons.emoji_events : Icons.emoji_events_outlined,
                            color: lit ? Colors.amber : Colors.white70,
                            size: 22,
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              if (imageAsset != null)
    Padding(
      padding: const EdgeInsets.only(bottom: 20.0, top: 10),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Opacity(
          opacity: completed ? 0.9 : 0.4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Align(
              alignment: Alignment.topCenter, // Change this to crop different areas
              widthFactor: 1, // Show 50% of the width
              heightFactor: 0.5, // Show 50% of the height
              child: Image.asset(
                imageAsset!,
                width: 280,
                height: 130,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    )
    ],
          ),
        ),
      ),
    );
  }
}
