import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BannedChecker {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> checkIfBanned(String uid, BuildContext context) async {
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists && (doc.get('isLocked') ?? false)) {
        _showBannedDialog(context);
      }
    } catch (e) {
      debugPrint("❌ Banned check failed: $e");
    }
  }

  void _showBannedDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.9),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, color: Colors.white, size: 60),
                const SizedBox(height: 20),
                const Text(
                  "🚫 Your account is banned!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Please contact support if you think this is a mistake.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: const Text("OK"),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) => Transform.scale(
        scale: Curves.easeOutBack.transform(anim.value),
        child: Opacity(opacity: anim.value, child: child),
      ),
    );
  }
}
