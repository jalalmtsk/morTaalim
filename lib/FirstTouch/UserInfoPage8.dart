import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../XpSystem.dart';

class UserInfoPage8 extends StatelessWidget {
  const UserInfoPage8({Key? key}) : super(key: key);

  void _finish(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Informations sauvegardées avec succès !")),
    );
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final experience = Provider.of<ExperienceManager>(context);
    final user = experience.userProfile;

    return Scaffold(
      appBar: AppBar(title: const Text("Étape 8: Confirmation")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nom: ${user.fullName}", style: const TextStyle(fontSize: 16)),
            Text("Âge: ${user.age}", style: const TextStyle(fontSize: 16)),
            Text("Ville: ${user.city}", style: const TextStyle(fontSize: 16)),
            Text("Pays: ${user.country}", style: const TextStyle(fontSize: 16)),
            Text("Email: ${user.email}", style: const TextStyle(fontSize: 16)),
            Text("Genre: ${user.gender}", style: const TextStyle(fontSize: 16)),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _finish(context),
              child: const Text("Terminer"),
            ),
          ],
        ),
      ),
    );
  }
}
