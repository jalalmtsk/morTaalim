import 'package:flutter/material.dart';

class AnimatedGridBackground extends StatefulWidget {
  final int rows;
  final int columns;

  const AnimatedGridBackground({super.key, this.rows = 10, this.columns = 6});

  @override
  State<AnimatedGridBackground> createState() => _AnimatedGridBackgroundState();
}

class _AnimatedGridBackgroundState extends State<AnimatedGridBackground>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(widget.rows * widget.columns, (index) {
      final controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1500 + (index * 50)),
      )..repeat(reverse: true);
      return controller;
    });

    _animations = _controllers.map((controller) {
      final randomStart = 0.8 + (0.4 * (controller.hashCode % 100) / 100);
      return Tween<double>(begin: randomStart, end: randomStart + 0.1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final cellWidth = constraints.maxWidth / widget.columns;
        final cellHeight = constraints.maxHeight / widget.rows;

        return Stack(
          children: List.generate(widget.rows * widget.columns, (index) {
            final row = index ~/ widget.columns;
            final col = index % widget.columns;
            return Positioned(
              left: col * cellWidth,
              top: row * cellHeight,
              width: cellWidth,
              height: cellHeight,
              child: ScaleTransition(
                scale: _animations[index],
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.05), width: 0.5),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
