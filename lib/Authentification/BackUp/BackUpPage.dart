import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/main.dart';

import '../../XpSystem.dart';
import 'LoadBackUp_dialog.dart';
import 'SaveBackUp_dialog.dart';
import 'TutoBackUp.dart';

class BackupPage extends StatelessWidget {
  final ExperienceManager experienceManager;

  BackupPage({required this.experienceManager, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Lottie backup animation
              Lottie.asset(
                'assets/animations/FirstTouchAnimations/progerss.json',
                width: 160,
                height: 160,
                repeat: true,
              ),

              const SizedBox(height: 24),

              Text(
                tr(context).backupYourProgressOrRestoreItUsingABackupCode,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  showSaveBackupDialog(context, experienceManager.saveBackup);
                },
                child:  Text(
                  tr(context).saveBackup,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                ),
                onPressed: () {
                  showLoadBackupDialog(context, experienceManager.loadBackup);
                },
                child:  Text(
                  tr(context).loadBackup,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) =>  BackupTutorialPage()),
                  );
                },
                child:  Text(
                  tr(context).howToBackup,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueAccent,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                tr(context).makeSureToSaveYourBackupCodeSafelyYouWillNeedItToRestoreYourProgress,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),

              const SizedBox(height: 40),

              // 🔴 Cancel Button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:  Text(
                  tr(context).cancel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
