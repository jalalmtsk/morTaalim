import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final String lottieAssetPath;
  final String buttonText;

  const InfoDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.lottieAssetPath,
    required this.buttonText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            lottieAssetPath,
            width: 150,
            height: 150,
            repeat: true,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
