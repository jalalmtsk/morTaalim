import 'package:flutter/material.dart';

class PetStatMiniCardProgress extends StatelessWidget {
  final int requiredStat;
  final int feedProgress;
  final int waterProgress;
  final int playProgress;
  final int maxPerLevel;

  const PetStatMiniCardProgress({
    Key? key,
    required this.requiredStat,
    required this.feedProgress,
    required this.waterProgress,
    required this.playProgress,
    required this.maxPerLevel,
  }) : super(key: key);

  double _getProgress(int value) =>
      maxPerLevel == 0 ? 0 : (value / maxPerLevel).clamp(0.0, 1.0);

  Widget _buildStatRow(String emoji, int progress, Color color) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Expanded(
          child: LinearProgressIndicator(
            value: _getProgress(progress),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(width: 6),
        Text("$progress/$maxPerLevel",
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.deepPurple[50],
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildStatRow("🍎", feedProgress, Colors.redAccent),
            const SizedBox(height: 6),
            _buildStatRow("💧", waterProgress, Colors.blueAccent),
            const SizedBox(height: 6),
            _buildStatRow("🎾", playProgress, Colors.green),
          ],
        ),
      ),
    );
  }
}
