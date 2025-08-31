import 'package:flutter/material.dart';


class SmallStatPill extends StatelessWidget {
  final int unlocked;
  final int total;

  const SmallStatPill({Key? key, required this.unlocked, required this.total})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : unlocked / total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: Colors.deepPurple),
          const SizedBox(width: 6),
          Text(
            '$unlocked/$total',
            style: const TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                backgroundColor: Colors.deepPurple.withOpacity(0.15),
                color: Colors.deepPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
