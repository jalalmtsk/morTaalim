import 'package:flutter/material.dart';
import 'package:mortaalim/games/paitingGame/paint_main.dart';

class Coursepaiting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DrawingApp(); // Your free drawing logic goes here
  }
}

/// Placeholder page for drawing lessons/tutorials
class LearningProgramPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Learning Program'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Here you can add step-by-step drawing lessons or tutorials.\n\n'
                'Coming soon!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
