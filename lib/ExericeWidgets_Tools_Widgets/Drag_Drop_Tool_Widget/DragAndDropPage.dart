import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'DragAndDrop.dart';

class ExercisePage extends StatelessWidget {
  const ExercisePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تمرين الترتيب'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DragAndDropSorter(
          items: ['morning', 'noon', 'evening'],
          correctOrder: ['morning', 'noon', 'evening'],
          labels: {
            'morning': 'الصباح',
            'noon': 'الظهر',
            'evening': 'المساء',
          },
          imagePaths: {
            'morning': 'assets/images/morning.png',
            'noon': 'assets/images/noon.png',
            'evening': 'assets/images/evening.png',
          },
        ),
      ),
    );
  }
}
