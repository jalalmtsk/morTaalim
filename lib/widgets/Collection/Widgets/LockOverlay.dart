import 'package:flutter/material.dart';


class LockOverlay extends StatelessWidget {
  const LockOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white70, width: 1),
          ),
          child: const Icon(
            Icons.lock_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}