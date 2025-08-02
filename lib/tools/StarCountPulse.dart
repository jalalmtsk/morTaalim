import 'package:flutter/material.dart';

class StarCountPulse extends StatefulWidget {
  final int oldStars;
  final int deduction;
  final VoidCallback onFinish;

  const StarCountPulse({
    super.key,
    required this.oldStars,
    required this.deduction,
    required this.onFinish,
  });

  @override
  State<StarCountPulse> createState() => _StarCountPulseState();
}

class _StarCountPulseState extends State<StarCountPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _countAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _countAnimation = IntTween(
      begin: widget.oldStars,
      end: widget.oldStars - widget.deduction,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.7), // move upward
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().whenComplete(widget.onFinish);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Icon(Icons.star, color: Colors.amber, size: 12),
            ),
            const SizedBox(width: 6),
            Stack(
              alignment: Alignment.centerLeft,
              clipBehavior: Clip.none,
              children: [
                Text(
                  '${_countAnimation.value}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      widget.deduction < 0
                          ? '+${-widget.deduction}'
                          : '-${widget.deduction}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.deduction < 0 ? Colors.green : Colors.red,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
