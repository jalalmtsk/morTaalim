import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../SavingPreferencesTool_Helper/Preferences_Helper.dart';

class DuaaDialog extends StatelessWidget {
  const DuaaDialog({Key? key}) : super(key: key);

  Map<String, dynamic> _getDuaaConfig() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return {
        'duaa': "🌅 Morning Duaa:\nالحمد لله الذي أحيانا بعدما أماتنا وإليه النشور",
        'icon': Icons.wb_sunny,
        'colors': [Colors.orange.shade200, Colors.orange.shade400],
      };
    } else if (hour >= 12 && hour < 18) {
      return {
        'duaa': "☀️ Afternoon Duaa:\nاللهم أعني على ذكرك وشكرك وحسن عبادتك",
        'icon': Icons.cloud,
        'colors': [Colors.blue.shade200, Colors.blue.shade400],
      };
    } else {
      return {
        'duaa': "🌙 Night Duaa:\nاللهم بك أمسينا وبك أصبحنا وبك نحيا وبك نموت وإليك المصير",
        'icon': Icons.nightlight_round,
        'colors': [Colors.indigo.shade200, Colors.indigo.shade400],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getDuaaConfig();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: config['colors'],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config['icon'], size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              config['duaa'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // Checkbox toggle row
            Consumer<CardVisibilityManager>(
              builder: (context, manager, _) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: !manager.showDuaaDialog,
                    onChanged: (value) {
                      manager.toggleDuaaDialog(!(value ?? false));
                    },
                    activeColor: Colors.white,
                    checkColor: Colors.black87,
                  ),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      "Don't show again",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Close",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
