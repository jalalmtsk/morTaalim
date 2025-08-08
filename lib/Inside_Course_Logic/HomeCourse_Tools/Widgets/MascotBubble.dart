import 'package:flutter/material.dart';

class MascotBubble extends StatefulWidget {
  final VoidCallback? onTap;
  const MascotBubble({Key? key, this.onTap}) : super(key: key);
  @override
  State<MascotBubble> createState() => _MascotBubbleState();
}

class _MascotBubbleState extends State<MascotBubble> with SingleTickerProviderStateMixin {
  late AnimationController _wiggle;

  @override
  void initState() {
    super.initState();
    _wiggle = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _wiggle.repeat(reverse: true);
  }

  @override
  void dispose() {
    _wiggle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.98, end: 1.04).animate(CurvedAnimation(parent: _wiggle, curve: Curves.easeInOut)),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.orange.shade100),
                child: const Text('🦊', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(height: 4),
              const Text('Mimi', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
