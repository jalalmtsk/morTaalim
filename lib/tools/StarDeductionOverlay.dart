import 'dart:math';
import 'package:flutter/material.dart';

class StarDeductionOverlay {
  static void showStarAnimation(
      BuildContext context, {
        required Offset from,
        required Offset to,
        int starCount = 5,
        Duration duration = const Duration(milliseconds: 800),
        VoidCallback? onComplete,
      }) {
    final overlay = Overlay.of(context);

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _StarDeductionAnimation(
        from: from,
        to: to,
        starCount: starCount,
        duration: duration,
        onComplete: () {
          overlayEntry.remove();
          if (onComplete != null) onComplete();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _StarDeductionAnimation extends StatefulWidget {
  final Offset from;
  final Offset to;
  final int starCount;
  final Duration duration;
  final VoidCallback onComplete;

  const _StarDeductionAnimation({
    required this.from,
    required this.to,
    required this.starCount,
    required this.duration,
    required this.onComplete,
  });

  @override
  State<_StarDeductionAnimation> createState() => _StarDeductionAnimationState();
}

class _StarDeductionAnimationState extends State<_StarDeductionAnimation>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;
  late final List<Offset> _controlPoints;

  @override
  @override
  void initState() {
    super.initState();

    _controllers = List.generate(widget.starCount, (i) {
      final controller = AnimationController(
        vsync: this,
        duration: widget.duration,
      );

      Future.delayed(Duration(milliseconds: i * 80), () {
        if (!mounted) return;
        controller.forward();
      });
      return controller;
    });

    _animations = _controllers
        .map((controller) => CurvedAnimation(parent: controller, curve: Curves.easeInOut))
        .toList();

    _controlPoints = List.generate(widget.starCount, (i) {
      final midX = (widget.from.dx + widget.to.dx) / 2;
      final midY = min(widget.from.dy, widget.to.dy) - 80 - Random().nextInt(50);
      return Offset(midX + Random().nextInt(40) - 20, midY);
    });

    Future.delayed(widget.duration + const Duration(milliseconds: 400), () {
      if (!mounted) return;
      widget.onComplete();
    });
  }


  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Offset _calculateBezier(double t, Offset start, Offset control, Offset end) {
    final x = pow(1 - t, 2) * start.dx +
        2 * (1 - t) * t * control.dx +
        pow(t, 2) * end.dx;
    final y = pow(1 - t, 2) * start.dy +
        2 * (1 - t) * t * control.dy +
        pow(t, 2) * end.dy;
    return Offset(x.toDouble(), y.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: List.generate(widget.starCount, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (context, child) {
              final t = _animations[i].value;
              final pos = _calculateBezier(t, widget.from, _controlPoints[i], widget.to);
              final scale = 1.0 - (t * 0.4);
              final opacity = 1.0 - (t * 0.8);

              return Positioned(
                left: pos.dx,
                top: pos.dy,
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: const Icon(Icons.star, color: Colors.amber, size: 24),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
