import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/ProfileStatusBar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'XpSystem.dart';
import 'main.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);

    _nameController.text = prefs.getString('name') ?? xpManager.fullName;
    _ageController.text = (xpManager.age > 0) ? xpManager.age.toString() : "";
    _cityController.text = xpManager.city;
    _countryController.text = xpManager.country;
    _emailController.text = xpManager.email;
    _selectedGender = xpManager.gender.isNotEmpty ? xpManager.gender : null;

    setState(() {});
  }

  Future<void> _saveProfile() async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);

    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final city = _cityController.text.trim();
    final country = _countryController.text.trim();
    final email = _emailController.text.trim();
    final gender = _selectedGender;

    audioManager.playEventSound('clickButton');

    if (name.isEmpty || name.length > 12) {
      _showError("Name must be between 1 and 12 characters");
      return;
    }
    if (age <= 0) {
      _showError("Please enter a valid age");
      return;
    }
    if (city.isEmpty) {
      _showError("Please enter your city");
      return;
    }
    if (country.isEmpty) {
      _showError("Please enter your country");
      return;
    }
    if (email.isEmpty || !RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email)) {
      _showError("Please enter a valid email");
      return;
    }
    if (gender == null) {
      _showError("Please select your gender");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);

    xpManager.setFullName(name);
    xpManager.setAge(age);
    xpManager.setCity(city);
    xpManager.setCountry(country);
    xpManager.setEmail(email);
    xpManager.setGender(gender);

    Navigator.pop(context);
  }

  void _showError(String message) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playEventSound('invalid');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1200),
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
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
                const ProfileStatusBar(),
                const SizedBox(height: 20),
                Expanded(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListView(
                        children: [
                          _buildSectionTitle(Icons.flag, tr(context).chooseYourBanner),
                          const SizedBox(height: 12),
                          _buildBannerSelector(xpManager, audioManager),
                          const SizedBox(height: 30),
                          _buildSectionTitle(Icons.face, "Choose Your Avatar"),
                          const SizedBox(height: 12),
                          _buildAvatarSelector(xpManager, audioManager),
                          const SizedBox(height: 30),
                          _buildSectionTitle(Icons.person, 'Personal' ?? "Personal Information"),
                          const SizedBox(height: 12),
                          _buildNameField(audioManager),
                          _buildField(_ageController, "Age", Icons.cake, TextInputType.number),
                          _buildField(_cityController, "City", Icons.location_city),
                          _buildField(_countryController, "Country", Icons.public),
                          _buildField(_emailController, "Email", Icons.email, TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          _buildGenderSelection(),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepOrange),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
      ],
    );
  }



  Widget _buildBannerSelector(ExperienceManager xpManager, AudioManager audioManager) {
    return SizedBox(
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
    );
  }

  Widget _buildAvatarSelector(ExperienceManager xpManager, AudioManager audioManager) {
    bool _isEmoji(String avatar) => !avatar.contains('/');

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: xpManager.unlockedAvatars.length,
        itemBuilder: (context, index) {
          final avatar = xpManager.unlockedAvatars[index];
          final isSelected = xpManager.selectedAvatar == avatar;

          return GestureDetector(
            onTap: () {
              audioManager.playEventSound('clickButton2');
              xpManager.selectAvatar(avatar);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
                  width: isSelected ? 4 : 2,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: Colors.deepOrange.withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  )
                ]
                    : [],
              ),
              child: _isEmoji(avatar)
                  ? Text(
                avatar,
                style: const TextStyle(fontSize: 48),
              )
                  : ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  avatar,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildNameField(AudioManager audioManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          maxLength: 12,
          decoration: InputDecoration(
            labelText: "Name",
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
          onChanged: (_) => setState(() {}),
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
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon,
      [TextInputType keyboardType = TextInputType.text]) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.orange.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          "Gender",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        RadioListTile<String>(
          title: const Text("Male"),
          value: "male",
          groupValue: _selectedGender,
          onChanged: (value) => setState(() => _selectedGender = value),
        ),
        RadioListTile<String>(
          title: const Text("Female"),
          value: "female",
          groupValue: _selectedGender,
          onChanged: (value) => setState(() => _selectedGender = value),
        ),
        RadioListTile<String>(
          title: const Text("Other"),
          value: "other",
          groupValue: _selectedGender,
          onChanged: (value) => setState(() => _selectedGender = value),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
      ),
    );
  }
}
