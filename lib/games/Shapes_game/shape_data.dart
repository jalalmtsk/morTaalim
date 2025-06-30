import 'package:flutter/material.dart';

class ShapeData {
  final String name;
  final Color color;
  final IconData icon;

  ShapeData(this.name, this.color, this.icon);
}

final List<ShapeData> allShapes = [
  ShapeData('Circle', Colors.red, Icons.circle),
  ShapeData('Square', Colors.blue, Icons.square),
  ShapeData('Triangle', Colors.green, Icons.change_history),
  ShapeData('Star', Colors.orange, Icons.star),
  ShapeData('Heart', Colors.pink, Icons.favorite),
  ShapeData('Hexagon', Colors.purple, Icons.hexagon),
  ShapeData('Pentagon', Colors.purple, Icons.pentagon),
  ShapeData('Pentagon', Colors.purple, Icons.currency_bitcoin_sharp),
];
