import 'package:flutter/material.dart';
import 'package:mortaalim/games/paitingGame/paintOnSketch/paintonSketchPage.dart';

class SketchSelectorPage extends StatelessWidget {
  final List<String> sketchPaths = [
    'assets/images/Sketches/CuteBear_Sketch.jpg',
    'assets/images/Sketches/CuteDog_Sketch.jpg',
    'assets/images/Sketches/CuteGirl_Sketch.jpg',
    'assets/images/Sketches/doll.jpg',
    'assets/images/Sketches/Girl.jpg',
    'assets/images/Sketches/Labubu.jpg',
    'assets/images/Sketches/Parrot_sketch.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: const Text('Choose a Sketch'),
        backgroundColor: Colors.pinkAccent,
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sketchPaths.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final path = sketchPaths[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DrawingOnBackgroundPage(imageAssetPath: path),
              ),
            ),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              clipBehavior: Clip.antiAlias,
              child: Image.asset(path, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}