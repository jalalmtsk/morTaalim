
import 'package:flutter/material.dart';

class BadgeChip extends StatelessWidget {
  final String title;
  final bool unlocked;
  const BadgeChip({Key? key, required this.title, required this.unlocked}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: unlocked ? Colors.amber.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: unlocked ? Colors.amber : Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(children: [
        Icon(unlocked ? Icons.emoji_events : Icons.lock_outline, color: unlocked ? Colors.amber.shade700 : Colors.grey),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: unlocked ? Colors.brown : Colors.grey.shade700)),
      ]),
    );
  }
}