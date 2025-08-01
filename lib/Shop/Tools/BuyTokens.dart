import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../XpSystem.dart';

class BuyTokenButton extends StatelessWidget {
  final ExperienceManager xpManager;
  const BuyTokenButton({required this.xpManager});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final success = xpManager.buySaveTokens();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? '🎉 You got 1 ⭐!'
                : '❌ Not enough Tolims to buy ⭐.'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFC371), Color(0xFFFF5F6D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orangeAccent.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.swap_horiz, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Exchange 3 ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Icon(Icons.generating_tokens_rounded, color: Colors.green),
            Text(
              ' for 1⭐',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
