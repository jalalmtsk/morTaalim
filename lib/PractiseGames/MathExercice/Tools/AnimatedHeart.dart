
// ❤️ Animated Heart Widget

import 'package:flutter/material.dart';
class AnimatedHeart extends StatefulWidget {
  final bool lost;

  const AnimatedHeart({Key? key, required this.lost}) : super(key: key);

  @override
  _AnimatedHeartState createState() => _AnimatedHeartState();
}

class _AnimatedHeartState extends State<AnimatedHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    _scale = Tween<double>(begin: 1.0, end: 1.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    if (widget.lost) {
      _controller.forward(); // play pop animation when heart is lost
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedHeart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.lost && widget.lost) {
      _controller.forward(from: 0); // replay animation when losing a heart
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(
        Icons.favorite,
        color: widget.lost ? Colors.grey : Colors.red,
        size: 30,
      ),
    );
  }
}
