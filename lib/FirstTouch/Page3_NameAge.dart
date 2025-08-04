import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../XpSystem.dart';

class NameAgePage extends StatefulWidget {
  const NameAgePage({Key? key}) : super(key: key);

  @override
  State<NameAgePage> createState() => _NameAgePageState();
}

class _NameAgePageState extends State<NameAgePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  final List<String> _languages = ['English', 'Français', 'العربية', 'Español'];
  int? _selectedLanguageIndex;

  bool _isSaving = false;
  String? _errorMessage;

  final Color _primaryColor = Colors.deepOrange.shade700;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final experienceManager = Provider.of<ExperienceManager>(context, listen: false);

    final savedName = prefs.getString('name') ?? experienceManager.fullName;
    final savedAge = prefs.getInt('age') ?? experienceManager.age;
    final savedLanguage = prefs.getInt('languageIndex');

    // Update provider and UI
    experienceManager.setFullName(savedName);
    experienceManager.setAge(savedAge);

    setState(() {
      _nameController.text = savedName;
      _ageController.text = (savedAge > 0) ? savedAge.toString() : '';
      _selectedLanguageIndex = savedLanguage;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = "Please fill all fields correctly.";
      });
      return;
    }
    if (_selectedLanguageIndex == null) {
      setState(() {
        _errorMessage = "Please select a language.";
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    try {
      final experienceManager = Provider.of<ExperienceManager>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();

      final name = _nameController.text.trim();
      final age = int.parse(_ageController.text.trim());

      // Save to SharedPreferences
      await prefs.setString('name', name);
      await prefs.setInt('age', age);
      await prefs.setInt('languageIndex', _selectedLanguageIndex!);

      // Update provider
      experienceManager.setFullName(name);
      experienceManager.setAge(age);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Information saved successfully!")),
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Error saving data: $e";
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Information"),
        backgroundColor: _primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter your name.";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: "Age"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter your age.";
                  }
                  final age = int.tryParse(value.trim());
                  if (age == null || age <= 0) {
                    return "Please enter a valid age.";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              Text(
                "Select Language",
                style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor, fontSize: 16),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 12,
                children: List.generate(_languages.length, (index) {
                  final selected = _selectedLanguageIndex == index;
                  return ChoiceChip(
                    label: Text(
                      _languages[index],
                      style: TextStyle(
                        color: selected ? Colors.white : _primaryColor,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: selected,
                    selectedColor: _primaryColor,
                    backgroundColor: _primaryColor.withOpacity(0.1),
                    onSelected: (_) {
                      setState(() {
                        _selectedLanguageIndex = index;
                      });
                    },
                  );
                }),
              ),

              const SizedBox(height: 36),

              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Save & Continue",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
