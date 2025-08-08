import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showSaveBackupDialog(BuildContext context, Future<String> Function() saveBackupFunc) async {
  // Show loading spinner while saving
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(child: CircularProgressIndicator()),
  );

  try {
    final backupCode = await saveBackupFunc();

    Navigator.pop(context); // close loading dialog

    // Show success dialog with backup code
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Backup Saved"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Your backup code is:"),
            SizedBox(height: 12),
            SelectableText(
              backupCode,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: backupCode));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Backup code copied to clipboard!")),
              );
            },
            child: Text("Copy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  } catch (e) {
    Navigator.pop(context); // close loading dialog if error

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to save backup: $e")),
    );
  }
}
