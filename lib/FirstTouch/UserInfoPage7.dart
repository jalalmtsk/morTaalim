import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../XpSystem.dart';
import 'UserInfoPage8.dart';

class UserInfoPage7 extends StatefulWidget {
  const UserInfoPage7({Key? key}) : super(key: key);

  @override
  _UserInfoPage7State createState() => _UserInfoPage7State();
}

class _UserInfoPage7State extends State<UserInfoPage7> {
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    final experience = Provider.of<ExperienceManager>(context, listen: false);
    final user = experience.userProfile;
    _selectedGender = user.gender.isNotEmpty ? user.gender : null;
  }

  void _next() {
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sélectionnez un genre")),
      );
      return;
    }
    Provider.of<ExperienceManager>(context, listen: false)
        .setGender(_selectedGender!);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const UserInfoPage8()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Étape 7: Genre")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: const Text("Masculin"),
              leading: Radio<String>(
                value: "masculin",
                groupValue: _selectedGender,
                onChanged: (v) => setState(() => _selectedGender = v),
              ),
            ),
            ListTile(
              title: const Text("Féminin"),
              leading: Radio<String>(
                value: "féminin",
                groupValue: _selectedGender,
                onChanged: (v) => setState(() => _selectedGender = v),
              ),
            ),
            ListTile(
              title: const Text("Autre"),
              leading: Radio<String>(
                value: "autre",
                groupValue: _selectedGender,
                onChanged: (v) => setState(() => _selectedGender = v),
              ),
            ),
            const Spacer(),
            ElevatedButton(onPressed: _next, child: const Text("Suivant")),
          ],
        ),
      ),
    );
  }
}
