import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'XpSystem.dart';
import '../../l10n/app_localizations.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('name') ?? "";
    });
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);

    Navigator.pop(context); // Return to previous screen
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final unlockedAvatars = xpManager.unlockedAvatars;
    final selectedAvatar = xpManager.selectedAvatar;
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Setup Profile"),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              "Choose your emoji avatar:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: emojiList.map((emoji) {
                final isUnlocked = unlockedAvatars.contains(emoji);
                final isSelected = selectedAvatar == emoji;

                return GestureDetector(
                  onTap: () {
                    if (isUnlocked) {
                      setState(() => xpManager.selectAvatar(emoji));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 1),
                          content: Wrap(
                            children: [
                              Text(tr.this_avatar_is_locked_unlock_it_in_the),
                              InkWell(
                                onTap: () {
                                  Navigator.of(context).pushNamed("Shop");
                                },
                                child: Text(
                                  " ${tr.shop}",
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected && isUnlocked
                              ? Colors.deepOrange.withOpacity(0.2)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected && isUnlocked
                                ? Colors.deepOrange
                                : Colors.grey.shade300,
                            width: 3,
                          ),
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                      if (!isUnlocked)
                        const Positioned(
                          right: 0,
                          top: 0,
                          child: Icon(Icons.lock, size: 20, color: Colors.deepOrange),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Your Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              child: const Text(
                "Save Profile",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> emojiList = [
  "🐶", "🐱", "🐻", "🐸", "🦄", "🐵",
  "🐼", "🦊", "🐯", "🐷", "🐨", "🐥",
  '🧙‍♂️','👽',"🤖", "🐼"
];
