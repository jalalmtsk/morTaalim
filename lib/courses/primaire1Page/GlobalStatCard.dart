import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../main.dart';

class GlobalStatsCard extends StatelessWidget {
  final double progress; // 0.0 .. 1.0
  final int badges;
  final int courseXp;
  final int completedCourses;
  final int totalCourses;

  const GlobalStatsCard({
    Key? key,
    required this.progress,
    required this.badges,
    required this.courseXp,
    required this.completedCourses,
    required this.totalCourses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentText = (progress * 100).toStringAsFixed(0);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 36.0,
            lineWidth: 8.0,
            percent: progress.clamp(0.0, 1.0),
            center: Text(
              "$percentText%",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
              ),
            ),
            progressColor: Colors.orangeAccent,
            backgroundColor: Colors.orangeAccent.withOpacity(0.2),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                  tr(context).global,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _statItem(Icons.wine_bar, "$badges ${tr(context).badges}"),
                    const SizedBox(width: 16),
                    _statItem(Icons.flash_on, "$courseXp ${tr(context).learningPower}"),
                  ],
                ),
                const SizedBox(height: 6),
                _statItem(
                  Icons.check_circle,
                  "$completedCourses / $totalCourses ${tr(context).coursesCompleted}",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.orangeAccent, size: 18),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
