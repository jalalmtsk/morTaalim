import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../XpSystem.dart';

class NameAgePage extends StatefulWidget {
  final VoidCallback? onNext;

  const NameAgePage({Key? key, this.onNext}) : super(key: key);

  @override
  State<NameAgePage> createState() => _NameAgePageState();
}

class _NameAgePageState extends State<NameAgePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String? _errorMessage;
  bool _isFormValid = false;

  late AnimationController _gradientController;
  int currentGradientIndex = 0;

  final List<List<Color>> gradientSets = [
    [const Color(0xFF6DD5FA), const Color(0xFF2980B9)],
    [const Color(0xFFFFD194), const Color(0xFFD1913C)],
    [const Color(0xFFB2FEFA), const Color(0xFF0ED2F7)],
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();

    _nameController.addListener(_validateForm);
    _lastNameController.addListener(_validateForm);
    _ageController.addListener(_validateForm);

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          currentGradientIndex =
              (currentGradientIndex + 1) % gradientSets.length;
        });
        _gradientController.forward(from: 0);
      }
    });

    _gradientController.forward();
  }

  void _validateForm() {
    final nameValid = _nameController.text.trim().isNotEmpty;
    final lastNameValid = _lastNameController.text.trim().isNotEmpty;
    final ageText = _ageController.text.trim();
    final ageValid = ageText.isNotEmpty &&
        int.tryParse(ageText) != null &&
        int.parse(ageText) > 0;

    final isValid = nameValid && lastNameValid && ageValid;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final experienceManager =
    Provider.of<ExperienceManager>(context, listen: false);
    final user = experienceManager.userProfile;

    final savedName = prefs.getString('name') ?? user.fullName;
    final savedLastName = prefs.getString('lastName') ?? user.lastName;
    final savedAge = prefs.getInt('age') ?? user.age;

    experienceManager.setFullName(savedName);
    experienceManager.setLastName(savedLastName);
    experienceManager.setAge(savedAge);

    setState(() {
      _nameController.text = savedName;
      _lastNameController.text = savedLastName;
      _ageController.text = (savedAge > 0) ? savedAge.toString() : '';
    });

    _validateForm();
  }

  Future<bool> saveData() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = "Veuillez remplir correctement tous les champs.";
      });
      return false;
    }

    try {
      final experienceManager =
      Provider.of<ExperienceManager>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();

      final name = _nameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final age = int.parse(_ageController.text.trim());

      await prefs.setString('name', name);
      await prefs.setString('lastName', lastName);
      await prefs.setInt('age', age);

      experienceManager.setFullName(name);
      experienceManager.setLastName(lastName);
      experienceManager.setAge(age);

      return true;
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur lors de la sauvegarde des données : $e";
      });
      return false;
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _nameController.removeListener(_validateForm);
    _lastNameController.removeListener(_validateForm);
    _ageController.removeListener(_validateForm);
    _nameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextIndex = (currentGradientIndex + 1) % gradientSets.length;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, _) {
          final colors = List<Color>.generate(
            2,
                (i) => Color.lerp(
              gradientSets[currentGradientIndex][i],
              gradientSets[nextIndex][i],
              _gradientController.value,
            )!,
          );

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          SizedBox(
                            height: 250,
                            child: Center(
                              child: Lottie.asset(
                                'assets/animations/FirstTouchAnimations/Learning.json',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            "Faisons connaissance",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 8,
                                  color: Colors.black38,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 4),

                          Text(
                            "Remplissez vos informations pour personnaliser votre expérience.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),

                          const SizedBox(height: 40),

                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          _buildInputField(
                            controller: _nameController,
                            label: "Prénom",
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Veuillez saisir votre Prénom.";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          _buildInputField(
                            controller: _lastNameController,
                            label: "Nom",
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Veuillez saisir votre Nom.";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          _buildInputField(
                            controller: _ageController,
                            label: "Âge",
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Veuillez saisir votre âge.";
                              }
                              final age = int.tryParse(value.trim());
                              if (age == null || age <= 0) {
                                return "Veuillez saisir un âge valide.";
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_isFormValid)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: FloatingActionButton(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepOrange,
                        onPressed: () async {
                          final success = await saveData();
                          if (success) {
                            widget.onNext?.call();
                          }
                        },
                        child: const Icon(Icons.arrow_forward, size: 28),
                        elevation: 6,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: validator,
    );
  }
}
