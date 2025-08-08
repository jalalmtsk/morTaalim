import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

Future<void> showLoadBackupDialog(
    BuildContext context,
    Future<void> Function(String) loadBackupFunc,
    ) async {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();

  // Show dialog to enter backup code
  final String? codeEntered = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Load Backup",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: codeController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: "Enter backup code",
                  hintText: "ABC123",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter a backup code";
                  }
                  if (value.trim().length < 3) {
                    return "Code is too short";
                  }
                  return null;
                },
                onFieldSubmitted: (_) {
                  if (_formKey.currentState?.validate() ?? false) {
                    Navigator.pop(context, codeController.text.trim());
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        Navigator.pop(context, codeController.text.trim());
                      }
                    },
                    child: const Text("Load"),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  if (codeEntered == null) return;

  // Show loading dialog with Lottie animation
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Center(
      child: Container(
        width: 120,
        height: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/lottie/loading_spinner.json', // Add your spinner JSON here
              width: 60,
              height: 60,
              repeat: true,
            ),
            const SizedBox(height: 12),
            const Text(
              "Loading backup...",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );

  try {
    await loadBackupFunc(codeEntered);
    Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Backup loaded successfully!")),
    );
  } catch (e) {
    Navigator.pop(context); // Close loading dialog

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Load Failed"),
        content: Text(
          "Backup not found or an error occurred.\n\nDetails:\n$e",
          style: const TextStyle(color: Colors.redAccent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
