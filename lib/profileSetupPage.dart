import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/ProfileStatusBar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'XpSystem.dart';
import '../../l10n/app_localizations.dart';
import 'main.dart';

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
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final name = _nameController.text.trim();

    audioManager.playEventSound('clickButton');

    if (name.isEmpty || name.length > 12) {
      audioManager.playEventSound('invalid');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(milliseconds: 1200),
          content: Text(
            "Name must be between 1 and 12 characters",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
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
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Status Bar
                ProfileStatusBar(
                  playerName: _nameController.text.isEmpty ? "Player" : _nameController.text,
                  onEditName: () => FocusScope.of(context).requestFocus(FocusNode()),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListView(
                        children: [
                          // Banner Selector
                          Row(
                            children: [
                              const Icon(Icons.flag, color: Colors.deepOrange),
                              const SizedBox(width: 8),
                              Text(
                                tr(context).chooseYourBanner,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepOrange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          SizedBox(
                            height: 140,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: xpManager.unlockedBanners.length,
                              itemBuilder: (context, index) {
                                final banner = xpManager.unlockedBanners[index];
                                final isSelected = xpManager.selectedBannerImage == banner;

                                return GestureDetector(
                                  onTap: () {
                                    audioManager.playEventSound('clickButton2');
                                    xpManager.selectBannerImage(banner);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
                                        width: isSelected ? 4 : 2,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                        BoxShadow(
                                          color: Colors.deepOrange.withValues(alpha: 0.5),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 4),
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

                          // Name Input
                          Row(
                            children: [
                              const Icon(Icons.person, color: Colors.deepOrange),
                              const SizedBox(width: 8),
                              Text(
                                tr(context).enterName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          TextField(
                            controller: _nameController,
                            maxLength: 12,
                            decoration: InputDecoration(
                              labelText: tr(context).name ?? "Your Name",
                              prefixIcon: const Icon(Icons.person),
                              counterText: '',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  audioManager.playEventSound('cancelButton');
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
                              audioManager.playEventSound('clickButton2');
                              setState(() {});
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
                  ),
                ),

                const SizedBox(height: 16),

                // Save Button
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
                      elevation: 5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
