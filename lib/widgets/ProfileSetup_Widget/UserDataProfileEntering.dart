import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../XpSystem.dart'; // Your ExperienceManager provider

class UserInfoFormPage extends StatefulWidget {
  const UserInfoFormPage({Key? key}) : super(key: key);

  @override
  State<UserInfoFormPage> createState() => _UserInfoFormPageState();
}

class _UserInfoFormPageState extends State<UserInfoFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _selectedGender;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Use listen: false to safely read provider once in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final experienceManager = Provider.of<ExperienceManager>(context, listen: false);
      final user = experienceManager.userProfile;

      setState(() {
        _nameController.text = user.fullName;
        _ageController.text = user.age > 0 ? user.age.toString() : '';
        _cityController.text = user.city;
        _countryController.text = user.country;
        _emailController.text = user.email;
        _selectedGender = user.gender.isNotEmpty ? user.gender : null;
      });
    });
  }

  // If you want reactive update when @ changes, you can use didChangeDependencies:
  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   final experienceManager = Provider.of<ExperienceManager>(context);
  //   // Update controllers here if needed (careful with loops)
  // }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _selectedGender == null) {
      setState(() {
        _errorMessage = "Veuillez remplir tous les champs correctement.";
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    try {
      final experienceManager = Provider.of<ExperienceManager>(context, listen: false);

      experienceManager.setFullName(_nameController.text.trim());
      experienceManager.setAge(int.parse(_ageController.text.trim()));
      experienceManager.setCity(_cityController.text.trim());
      experienceManager.setCountry(_countryController.text.trim());
      experienceManager.setEmail(_emailController.text.trim());
      experienceManager.setGender(_selectedGender!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Informations sauvegardées avec succès!")),
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur lors de la sauvegarde: $e";
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
    _cityController.dispose();
    _countryController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Informations Utilisateur"),
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
                decoration: const InputDecoration(labelText: "Nom complet"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return "Veuillez entrer votre nom.";
                  return null;
                },
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: "Âge"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return "Veuillez entrer votre âge.";
                  final age = int.tryParse(value.trim());
                  if (age == null || age <= 0) return "Veuillez entrer un âge valide.";
                  return null;
                },
              ),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: "Ville"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return "Veuillez entrer votre ville.";
                  return null;
                },
              ),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: "Pays"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return "Veuillez entrer votre pays.";
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return "Veuillez entrer votre email.";
                  final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
                  if (!emailRegex.hasMatch(value.trim())) return "Veuillez entrer un email valide.";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text("Genre", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ListTile(
                title: const Text('Masculin'),
                leading: Radio<String>(
                  value: 'masculin',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
              ),
              ListTile(
                title: const Text('Féminin'),
                leading: Radio<String>(
                  value: 'féminin',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
              ),
              ListTile(
                title: const Text('Autre'),
                leading: Radio<String>(
                  value: 'autre',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Sauvegarder"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
