import 'package:flutter/material.dart';

import 'Piano_Free_play.dart';
import 'Piano_lessons_play.dart';

class PianoModeSelector extends StatelessWidget {
  const PianoModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎵 Piano Mode Selector'), backgroundColor: Colors.deepPurple),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FullPianoPage()),
              ),
              child: const Text('🎹 Free Play', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PianoLessonsPage()),
              ),
              child: const Text('📘 Piano Lessons', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}