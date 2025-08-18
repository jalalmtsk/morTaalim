
import 'package:flutter/material.dart';
class DropTarget extends StatelessWidget {
  const DropTarget({
    required this.onWillAccept,
    required this.onAccept,
    this.highlight = false,
  });

  final bool Function(Map<String, dynamic>?) onWillAccept;
  final void Function(Map<String, dynamic>) onAccept;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Map<String, dynamic>>(
      onWillAccept: onWillAccept,
      onAccept: onAccept,
      builder: (context, candidate, rejected) {
        final isHover = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: isHover
                  ? [Colors.yellow.shade200, Colors.amber.shade100]
                  : [Colors.blue.shade100, Colors.lightBlue.shade50],
            ),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(2, 6))],
          ),
          child: Center(
            child: Icon(
              Icons.surround_sound,
              size: 60,
              color: isHover ? Colors.orange.shade700 : Colors.blueGrey,
            ),
          ),
        );
      },
    );
  }
}