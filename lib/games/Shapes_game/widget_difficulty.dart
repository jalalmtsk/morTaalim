import 'package:flutter/material.dart';
import 'package:mortaalim/games/Shapes_game/shape_sorter_page.dart';

class DifficultyButton extends StatelessWidget {
  final String levelName;
  final int shapeCount;

  const DifficultyButton({
    required this.levelName,
    required this.shapeCount,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShapeSorterPage(shapeCount: shapeCount),
            ),
          );
        },
        child: Text(
          levelName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
