import 'package:flutter/cupertino.dart';

class AdLabel extends StatelessWidget {
  const AdLabel();
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFBDBDBD), width: 0.8),
        ),
        child: const Text(
          'Ad',
          style: TextStyle(
            fontSize: 9,
            color: Color(0xFF616161),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class NeutralAdPlaceholder extends StatelessWidget {
  const NeutralAdPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: const Text(
        'Advertisement',
        style: TextStyle(
          fontSize: 11,
          color: Color(0xFF9E9E9E), // neutral grey — never themed
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

