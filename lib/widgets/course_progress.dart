import 'package:flutter/material.dart';

class CourseProgress extends StatelessWidget {
  final double progress;
  final String progressPercent;

  const CourseProgress({
    super.key,
    required this.progress,
    required this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progression: $progressPercent%',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: Colors.deepPurpleAccent,
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}
