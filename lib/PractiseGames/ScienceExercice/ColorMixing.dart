import 'package:flutter/material.dart';
import 'dart:math';


class ColorMixingExercise extends StatefulWidget {
  const ColorMixingExercise({super.key});

  @override
  State<ColorMixingExercise> createState() => _ColorMixPageState();
}

class _ColorMixPageState extends State<ColorMixingExercise> {
  Color mixedColor = Colors.white;
  String colorName = "White";

  // More base colors for accuracy
  final Map<String, Color> baseColors = {
    'Red': Colors.red,
    'Yellow': Colors.yellow,
    'Blue': Colors.blue,
    'Cyan': Colors.cyan,
    'Magenta': Colors.purple,
    'Green': Colors.green,
    'Orange': Colors.orange,
    'Purple': Colors.deepPurple,
    'Brown': Colors.brown,
    'White': Colors.white,
    'Black': Colors.black,
  };

  final List<Color> selectedColors = [];

  // List of color names with approximate RGB
  final Map<String, Color> namedColors = {
    'Red': Colors.red,
    'Yellow': Colors.yellow,
    'Blue': Colors.blue,
    'Cyan': Colors.cyan,
    'Magenta': Colors.purple,
    'Green': Colors.green,
    'Orange': Colors.orange,
    'Purple': Colors.deepPurple,
    'Brown': Colors.brown,
    'Pink': Colors.pink,
    'White': Colors.white,
    'Black': Colors.black,
    'Gray': Colors.grey,
    'Lime': Colors.lime,
    'Indigo': Colors.indigo,
    'Teal': Colors.teal,
  };

  void _mixColors() {
    if (selectedColors.isEmpty) {
      setState(() {
        mixedColor = Colors.white;
        colorName = "White";
      });
      return;
    }

    double r = 0, g = 0, b = 0;

    for (var color in selectedColors) {
      r += color.red;
      g += color.green;
      b += color.blue;
    }

    int n = selectedColors.length;
    Color mix = Color.fromARGB(255, (r / n).round(), (g / n).round(), (b / n).round());

    setState(() {
      mixedColor = mix;
      colorName = _getClosestColorName(mix);
    });
  }

  // Find the closest color name
  String _getClosestColorName(Color color) {
    String closestName = "Unknown";
    double minDistance = double.infinity;

    for (var entry in namedColors.entries) {
      double distance = _colorDistance(color, entry.value);
      if (distance < minDistance) {
        minDistance = distance;
        closestName = entry.key;
      }
    }

    return closestName;
  }

  double _colorDistance(Color a, Color b) {
    return sqrt(pow(a.red - b.red, 2) + pow(a.green - b.green, 2) + pow(a.blue - b.blue, 2));
  }

  void _addColor(Color color) {
    selectedColors.add(color);
    _mixColors();
  }

  void _clearColors() {
    selectedColors.clear();
    _mixColors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Color Mixing'),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearColors,
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mixed Color Display
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: mixedColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(width: 2, color: Colors.black),
            ),
            child: Center(
              child: Text(
                colorName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                  shadows: [Shadow(blurRadius: 2, color: Colors.white)],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Base Colors
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: baseColors.entries.map((entry) {
              return GestureDetector(
                onTap: () => _addColor(entry.value),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: entry.value,
                    shape: BoxShape.circle,
                    border: Border.all(width: 2, color: Colors.black),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Selected Colors: ${selectedColors.length}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
