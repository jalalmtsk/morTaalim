import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'appNotificationDialog.dart';

class NotificationManager {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String collectionName;
  final String documentName;

  NotificationManager({
    this.collectionName = 'app_settings',
    this.documentName = 'notification',
  });

  /// Show dynamic notification dialog if Firestore or local settings allow it
  Future<void> showNotificationIfAllowed(BuildContext context, String locale) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final doc = await firestore.collection(collectionName).doc(documentName).get();
      if (!doc.exists) return;

      final data = doc.data() ?? {};
      final enabled = data['enabled'] ?? false;
      if (!enabled) return;

      // Get notification ID (unique per message)
      final notificationId = data['notification_id'] ?? "default";

      // Check if this notification has already been dismissed
      final lastDismissedId = prefs.getString('dismissedNotificationId');
      if (lastDismissedId == notificationId) {
        // Same notification — don't show it again
        return;
      }

      // Localization logic
      String title = data['title_en'] ?? "Notification";
      String message = data['message_en'] ?? "Welcome!";
      String? lottieAsset = data['lottie_asset'];

      if (locale.startsWith('fr')) {
        title = data['title_fr'] ?? title;
        message = data['message_fr'] ?? message;
      } else if (locale.startsWith('ar')) {
        title = data['title_ar'] ?? title;
        message = data['message_ar'] ?? message;
      }

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => NotificationDialog(
            title: title,
            message: message,
            lottieAsset: lottieAsset,
            onClose: () {
              Navigator.pop(context);
            },
            onDontShowAgain: () async {
              await prefs.setString('dismissedNotificationId', notificationId);
              Navigator.pop(context);
            },
          ),
        );
      }
    } catch (e) {
      debugPrint("⚠️ NotificationManager error: $e");
    }
  }
}
