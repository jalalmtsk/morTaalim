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
    if (name.isEmpty || name.length > 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name must be between 1 and 12 characters")),
      );
      return;
    }

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
            ProfileStatusBar(
              playerName: _nameController.text.isEmpty ? "Player" : _nameController.text,
              onEditName: () {
                FocusScope.of(context).requestFocus(FocusNode());
              },
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: [
                  const Text(
                    "Choose Your Banner",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: xpManager.unlockedBanners.length,
                      itemBuilder: (context, index) {
                        final banner = xpManager.unlockedBanners[index];
                        final isSelected = xpManager.selectedBannerImage == banner;

                        return GestureDetector(
                          onTap: () => xpManager.selectBannerImage(banner),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.deepOrange : Colors.grey.shade400,
                                width: isSelected ? 4 : 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: Colors.deepOrange.withOpacity(0.4),
                                  blurRadius: 8,
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
                                width: 230,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "Enter Your Name",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _nameController,
                    maxLength: 12,
                    decoration: InputDecoration(
                      labelText: tr.name ?? "Your Name",
                      prefixIcon: const Icon(Icons.person),
                      counterText: '', // hide default counter
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _nameController.clear();
                          setState(() {});
                        },
                      ),
                      filled: true,
                      fillColor: Colors.orange.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {}); // live update ProfileStatusBar
                    },
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        "${_nameController.text.length}/12",
                        style: TextStyle(
                          fontSize: 12,
                          color: _nameController.text.length > 12 ? Colors.red : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save),
                label: const Text("Save Profile"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
