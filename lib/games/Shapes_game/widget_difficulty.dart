// widget_difficulty.dart
// Kept for backwards compatibility — DifficultyButton is no longer used
// directly but may be imported elsewhere. It now just delegates to
// DifficultySelectionPage from Shapes_main.dart.
import 'package:flutter/material.dart';
import 'shape_data.dart';
import 'shape_sorter_page.dart';

/// Legacy entry-point widget — wraps a single level launch.
class DifficultyButton extends StatelessWidget {
  final String levelName;
  final int    shapeCount;
  const DifficultyButton({required this.levelName,
    required this.shapeCount, super.key});

  @override
  Widget build(BuildContext context) {
    // Map old shapeCount to nearest new ShapeLevel
    final lvl = kLevels.firstWhere(
          (l) => l.shapeCount >= shapeCount,
      orElse: () => kLevels.last,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: lvl.color,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28)),
          elevation: 6,
        ),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ShapeSorterPage(level: lvl))),
        child: Text(levelName,
            style: const TextStyle(fontFamily: 'Fredoka One',
                fontSize: 20, color: Colors.white)),
      ),
    );
  }
}