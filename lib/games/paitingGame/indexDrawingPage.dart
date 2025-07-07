import 'package:flutter/material.dart';
import 'package:mortaalim/games/paitingGame/paintOnSketch/paintonSketchPage.dart';
import 'package:mortaalim/games/paitingGame/paint_main.dart';

import 'CoursePaiting.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drawing App',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: DrawingIndex(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DrawingIndex extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to Drawing App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.brush, size: 40),
              label: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Free Drawing', style: TextStyle(fontSize: 24)),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 100),
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Coursepaiting(),
                  ),
                );
              },
            ),
            SizedBox(height: 40),
            ElevatedButton.icon(
              icon: Icon(Icons.school, size: 40),
              label: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Learning Program', style: TextStyle(fontSize: 24)),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 100),
                backgroundColor: Colors.deepPurple.shade300,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LearningProgramPage(),
                  ),
                );
              },
            ),
            SizedBox(height: 40),
            ElevatedButton.icon(
              icon: Icon(Icons.image, size: 40),
              label: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Paint on Sketches', style: TextStyle(fontSize: 24)),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 100),
                backgroundColor: Colors.deepPurple.shade200,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Coursepaiting(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}