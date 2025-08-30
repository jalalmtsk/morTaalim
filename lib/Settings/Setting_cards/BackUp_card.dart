import 'package:flutter/material.dart';
import 'package:mortaalim/main.dart';
import 'package:provider/provider.dart';
import '../../Authentification/BackUp/BackUpPage.dart';
import '../../XpSystem.dart';

class BackupCard extends StatelessWidget {
  const BackupCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              tr(context).backupAndRestore,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.backup),
              label:  Text(tr(context).manageBackup),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 45),
              ),
              onPressed: () {
                final xpManager = Provider.of<ExperienceManager>(context, listen: false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      audioManager.playEventSound("clickButton");
                      return BackupPage(experienceManager: xpManager);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
