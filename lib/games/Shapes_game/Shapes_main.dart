import 'package:flutter/material.dart';
import 'package:mortaalim/games/Shapes_game/widget_difficulty.dart';
import 'package:mortaalim/tools/audio_tool/audio_tool.dart';


class ShapeSorterApp extends StatelessWidget {
  const ShapeSorterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  DifficultySelectionPage();
  }
}

class DifficultySelectionPage extends StatelessWidget {
   DifficultySelectionPage({super.key});

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
