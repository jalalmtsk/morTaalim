import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class AnimatedGridItem extends StatefulWidget {
  final int index;
  final Widget child;
  final int columnCount;
  final VoidCallback? onTap;

  const AnimatedGridItem({
    super.key,
    required this.index,
    required this.child,
    this.columnCount = 2,
    this.onTap,
  });

  @override
  State<AnimatedGridItem> createState() => _AnimatedGridItemState();
}

class _AnimatedGridItemState extends State<AnimatedGridItem> {
  double _tiltX = 0;
  double _tiltY = 0;
  bool _isPressed = false;

  void _onPointerMove(PointerEvent event, Size size) {
    final dx = (event.localPosition.dx - size.width / 2) / (size.width / 2);
    final dy = (event.localPosition.dy - size.height / 2) / (size.height / 2);

    setState(() {
      _tiltX = dy * 0.08;
      _tiltY = -dx * 0.08;
    });
  }

  void _resetTilt() {
    setState(() {
      _tiltX = 0;
      _tiltY = 0;
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredGrid(
      position: widget.index,
      duration: const Duration(milliseconds: 450),
      columnCount: widget.columnCount,
      child: ScaleAnimation(
        scale: 0.85,
        curve: Curves.easeOutBack,
        child: FadeInAnimation(
          child: Listener(
            onPointerMove: (event) {
              final size = context.size ?? const Size(150, 150);
              _onPointerMove(event, size);
            },
            onPointerUp: (_) => _resetTilt(),
            onPointerCancel: (_) => _resetTilt(),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => _resetTilt(),
              onTapCancel: _resetTilt,
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                transform: Matrix4.identity()
                  ..rotateX(_tiltX)
                  ..rotateY(_tiltY)
                  ..scale(_isPressed ? 0.97 : 1.0),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
