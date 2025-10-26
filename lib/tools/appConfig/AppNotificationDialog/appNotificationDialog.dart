import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/main.dart';

class NotificationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? lottieAsset;
  final bool showDontShowAgain;
  final VoidCallback onClose;
  final VoidCallback? onDontShowAgain;

  const NotificationDialog({
    super.key,
    required this.title,
    required this.message,
    this.lottieAsset,
    required this.onClose,
    this.onDontShowAgain,
    this.showDontShowAgain = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lottieAsset != null)
              SizedBox(
                height: 120,
                child: Lottie.asset(lottieAsset!, repeat: true),
              ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onClose,
              child:  Text(tr(context).close, style: TextStyle(color: Colors.white)),
            ),
            if (showDontShowAgain) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onDontShowAgain,
                child:  Text(
                  tr(context).dontShowAgain,
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
