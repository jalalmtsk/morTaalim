import 'package:flutter/material.dart';

class PromptCard extends StatelessWidget {
  const PromptCard({
    required this.pulseController,
    required this.onPlay,
    required this.text,
  });

  final AnimationController pulseController;
  final VoidCallback onPlay;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.05)
                .chain(CurveTween(curve: Curves.easeInOut))
                .animate(pulseController),
            child: ElevatedButton.icon(
              onPressed: onPlay,
              icon: const Icon(Icons.volume_up),
              label: const Text('Play'),
              style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
            ),
          )
        ],
      ),
    );
  }
}