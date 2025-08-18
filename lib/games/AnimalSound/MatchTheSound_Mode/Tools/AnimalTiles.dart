
import 'package:flutter/material.dart';
class AnimalTile extends StatelessWidget {
  const AnimalTile({
    required this.image,
    this.dragging = false,
    this.faded = false,
  });

  final String image;
  final bool dragging;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(2, 4))],
      ),
      child: Image.asset(image, fit: BoxFit.contain),
    );

    if (dragging) return Material(color: Colors.transparent, child: Transform.scale(scale: 1.05, child: child));
    if (faded) return Opacity(opacity: 0.35, child: child);
    return child;
  }
}
