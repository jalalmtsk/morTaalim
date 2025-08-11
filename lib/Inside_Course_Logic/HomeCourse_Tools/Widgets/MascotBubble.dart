import 'package:flutter/material.dart';

class MascotBubble extends StatefulWidget {
  final VoidCallback? onTap;
  final String emoji;
  final String label;
  final Color bubbleColor;
  final Color backgroundColor;
  final double size;

  const MascotBubble({
    Key? key,
    this.onTap,
    this.emoji = '🦊',
    this.label = 'Mascot',
    this.bubbleColor = const Color(0xFFFFE0B2), // Light orange
    this.backgroundColor = Colors.white,
    this.size = 56,
  }) : super(key: key);

  @override
  State<MascotBubble> createState() => _MascotBubbleState();
}

class _MascotBubbleState extends State<MascotBubble> with SingleTickerProviderStateMixin {
  late AnimationController _wiggle;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _wiggle = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scaleAnimation = Tween(begin: 0.98, end: 1.04).animate(
      CurvedAnimation(parent: _wiggle, curve: Curves.easeInOut),
    );
    _wiggle.repeat(reverse: true);
  }

  @override
  void dispose() {
    _wiggle.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 8),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: widget.size,
                height: widget.size,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.bubbleColor,
                ),
                child: Text(
                  widget.emoji,
                  style: TextStyle(fontSize: widget.size * 0.5),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
