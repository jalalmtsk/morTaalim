import 'package:flutter/material.dart';
import 'package:mortaalim/widgets/ProfileStatusBar.dart';
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

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Setup Profile"),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // Add the status bar here
            ProfileStatusBar(
              playerName: _nameController.text.isEmpty
                  ? "Player"
                  : _nameController.text,
              onEditName: () {
                // Scroll to textfield or open dialog to edit name (optional)
                FocusScope.of(context).requestFocus(
                    FocusNode()); // Remove keyboard focus
                // Or just focus the TextField below:
                // _nameFocusNode.requestFocus(); // if you add a FocusNode to TextField
              },
            ),

            const SizedBox(height: 30),

            Expanded(
              child: ListView(
                children: [
                  Text(
                    "Choose your banner:",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: xpManager.unlockedBanners.length,
                      itemBuilder: (context, index) {
                        final banner = xpManager.unlockedBanners[index];
                        final isSelected = xpManager.selectedBannerImage ==
                            banner;

                        return GestureDetector(
                          onTap: () {
                            xpManager.selectBannerImage(banner);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.deepOrange
                                    : Colors.grey.shade300,
                                width: isSelected ? 4 : 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: Colors.deepOrange.withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 5),
                                )
                              ]
                                  : [],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                banner,
                                width: 240,
                                height: 140,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: tr.name ?? "Your Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    onChanged: (val) {
                      // Update status bar instantly
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Save Profile" ?? "Save Profile",
                  style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}