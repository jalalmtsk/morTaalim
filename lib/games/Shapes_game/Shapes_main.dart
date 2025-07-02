import 'package:flutter/material.dart';
import 'package:mortaalim/games/Shapes_game/widget_difficulty.dart';


class ShapeSorterApp extends StatelessWidget {
  const ShapeSorterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const DifficultySelectionPage();
  }
}

class DifficultySelectionPage extends StatelessWidget {
  const DifficultySelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: (){
          Navigator.of(context).pop();
        }, icon: Icon(Icons.arrow_back)),
        title: const Text('Select Difficulty'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            DifficultyButton(levelName: 'Easy', shapeCount: 3),
            DifficultyButton(levelName: 'Medium', shapeCount: 4),
            DifficultyButton(levelName: 'Hard', shapeCount: 7),
          ],
        ),
      ),
    );
  }
}
