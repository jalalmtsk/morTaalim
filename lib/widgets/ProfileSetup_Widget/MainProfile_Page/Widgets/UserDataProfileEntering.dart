import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../../../XpSystem.dart';

class UserAndSchoolInfoPage extends StatefulWidget {
  const UserAndSchoolInfoPage({Key? key}) : super(key: key);

  @override
  State<UserAndSchoolInfoPage> createState() => _UserAndSchoolInfoPageState();
}

class _UserAndSchoolInfoPageState extends State<UserAndSchoolInfoPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // --- User Info Controllers ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _selectedGender;

  // --- School Info Controllers ---
  final TextEditingController _schoolNameController = TextEditingController();
  String? _selectedSchoolType;
  String? _selectedSchoolLevel;
  String? _selectedGrade;
  String? _selectedLyceeTrack;

  // --- Animation / State ---
  late AnimationController _gradientController;
  int currentGradientIndex = 0;

  final List<List<Color>> gradientSets = [
    [Colors.deepPurple.shade400, Colors.deepPurple.shade800],
    [Colors.blue.shade400, Colors.blue.shade800],
    [Colors.pink.shade400, Colors.pink.shade800],
  ];

  bool _isFormValid = false;
  bool _isSaving = false;
  String? _errorMessage;

  // --- School Data ---
  final List<String> schoolTypes = ['Privé', 'Publique', 'Autre'];
  final List<String> schoolLevels = ['Primaire', 'Collège', 'Lycée'];
  final Map<String, List<String>> gradesByLevel = {
    'Primaire': ['1ère année primaire (CP)', '2ème année primaire (CE1)', '3ème année primaire (CE2)', '4ème année primaire (CM1)', '5ème année primaire (CM2)', '6ème année primaire (CM3)'],
    'Collège': ['7ème année (1ère année collège)', '8ème année (2ème année collège)', '9ème année (3ème année collège)'],
    'Lycée': ['Tronc Commun (TC)', '1ère année bac', 'Baccalauréat'],
  };
  final List<String> lyceeTracks = ['Science', 'Lettre'];

  @override
  void initState() {
    super.initState();
    _loadProfile();

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          currentGradientIndex = (currentGradientIndex + 1) % gradientSets.length;
        });
        _gradientController.forward(from: 0);
      }
    });

    _gradientController.forward();
  }

  void _loadProfile() {
    final experienceManager = Provider.of<ExperienceManager>(context, listen: false);
    final user = experienceManager.userProfile;

    setState(() {
      // --- User ---
      _nameController.text = user.fullName;
      _ageController.text = user.age > 0 ? user.age.toString() : '';
      _cityController.text = user.city;
      _countryController.text = user.country;
      _emailController.text = user.email;
      _selectedGender = user.gender.isNotEmpty ? user.gender : null;

      // --- School ---
      _schoolNameController.text = user.schoolName;
      _selectedSchoolType = user.schoolType.isNotEmpty ? user.schoolType : null;
      _selectedSchoolLevel = user.schoolLevel.isNotEmpty ? user.schoolLevel : null;
      _selectedGrade = user.schoolGrade.isNotEmpty ? user.schoolGrade : null;
      _selectedLyceeTrack = user.lyceeTrack.isNotEmpty ? user.lyceeTrack : null;
    });

    _validateForm();
  }

  void _validateForm() {
    final userValid = _nameController.text.trim().isNotEmpty &&
        _ageController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty &&
        _countryController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _selectedGender != null;

    final schoolValid = _schoolNameController.text.trim().isNotEmpty &&
        _selectedSchoolType != null &&
        _selectedSchoolLevel != null &&
        _selectedGrade != null &&
        (_selectedSchoolLevel != 'Lycée' || _selectedLyceeTrack != null);

    setState(() => _isFormValid = userValid && schoolValid);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _errorMessage = "Veuillez remplir tous les champs correctement.");
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    try {
      final experienceManager = Provider.of<ExperienceManager>(context, listen: false);

      // --- User Info ---
      experienceManager.setFullName(_nameController.text.trim());
      experienceManager.setAge(int.parse(_ageController.text.trim()));
      experienceManager.setCity(_cityController.text.trim());
      experienceManager.setCountry(_countryController.text.trim());
      experienceManager.setEmail(_emailController.text.trim());
      experienceManager.setGender(_selectedGender!);

      // --- School Info ---
      experienceManager.setSchoolName(_schoolNameController.text.trim());
      experienceManager.setSchoolType(_selectedSchoolType!);
      experienceManager.setSchoolLevel(_selectedSchoolLevel!);
      experienceManager.setSchoolGrade(_selectedGrade!);
      if (_selectedSchoolLevel == 'Lycée') {
        experienceManager.setLyceeTrack(_selectedLyceeTrack!);
      } else {
        experienceManager.setLyceeTrack('');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Toutes les informations ont été sauvegardées avec succès!")),
      );
    } catch (e) {
      setState(() => _errorMessage = "Erreur lors de la sauvegarde: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _emailController.dispose();
    _schoolNameController.dispose();
    super.dispose();
  }

  Widget _buildInputCard({required Widget child}) {
    return Card(
      color: Colors.white.withOpacity(0.15),
      elevation: 8,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        child: child,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String validatorMessage,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return validatorMessage;
        if (keyboardType == TextInputType.emailAddress) {
          final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
          if (!emailRegex.hasMatch(value.trim())) return "Veuillez entrer un email valide.";
        }
        return null;
      },
      onChanged: (_) => _validateForm(),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 16),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white70.withOpacity(0.6), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required String validatorMessage,
    required void Function(String?) onChanged,
    IconData? icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: Colors.deepOrange.shade400,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 16),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white70.withOpacity(0.6), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
      onChanged: (val) {
        onChanged(val);
        _validateForm();
      },
      validator: (val) {
        if (val == null || val.isEmpty) return validatorMessage;
        return null;
      },
    );
  }

  Widget _buildGenderSelector(String title, String value, Color color) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedGender = value);
          _validateForm();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? color : Colors.white70, width: 2),
          ),
          child: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 16), textAlign: TextAlign.center),
        ),
      ),
    );
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
                    padding: const EdgeInsets.all(12),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 180,
                            child: Center(
                              child: Lottie.asset('assets/animations/FirstTouchAnimations/User.json', fit: BoxFit.contain),
                            ),
                          ),
                          const Text("Informations Utilisateur", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          _buildInputCard(child: _buildInputField(controller: _nameController, label: "Nom complet", validatorMessage: "Veuillez entrer votre nom")),
                          _buildInputCard(child: _buildInputField(controller: _ageController, label: "Âge", validatorMessage: "Veuillez entrer votre âge", keyboardType: TextInputType.number)),
                          _buildInputCard(child: _buildInputField(controller: _cityController, label: "Ville", validatorMessage: "Veuillez entrer votre ville")),
                          _buildInputCard(child: _buildInputField(controller: _countryController, label: "Pays", validatorMessage: "Veuillez entrer votre pays")),
                          _buildInputCard(child: _buildInputField(controller: _emailController, label: "Email", validatorMessage: "Veuillez entrer votre email", keyboardType: TextInputType.emailAddress)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildGenderSelector("Masculin", "masculin", Colors.blue),
                              const SizedBox(width: 12),
                              _buildGenderSelector("Féminin", "feminin", Colors.pinkAccent),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text("Informations Scolaires", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          _buildInputCard(child: _buildInputField(controller: _schoolNameController, label: "Nom de l'école", validatorMessage: "Veuillez entrer le nom de l'école", icon: Icons.school_outlined)),
                          _buildInputCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildDropdownField(label: "Type d'école", value: _selectedSchoolType, items: schoolTypes, validatorMessage: "Sélectionnez le type d'école", onChanged: (val) => setState(() => _selectedSchoolType = val), icon: Icons.apartment_outlined),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _buildDropdownField(
                                      label: "Niveau scolaire",
                                      value: _selectedSchoolLevel,
                                      items: schoolLevels,
                                      validatorMessage: "Sélectionnez le niveau",
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedSchoolLevel = val;
                                          _selectedGrade = null;
                                          _selectedLyceeTrack = null;
                                        });
                                        _validateForm();
                                      },
                                      icon: Icons.account_tree_outlined),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedSchoolLevel != null)
                            _buildInputCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _buildDropdownField(
                                      label: "Classe",
                                      value: _selectedGrade,
                                      items: gradesByLevel[_selectedSchoolLevel!] ?? [],
                                      validatorMessage: "Sélectionnez la classe",
                                      onChanged: (val) => setState(() => _selectedGrade = val),
                                    ),
                                  ),
                                  if (_selectedSchoolLevel == 'Lycée') ...[
                                    const SizedBox(width: 6),
                                    Expanded(
                                      flex: 2,
                                      child: _buildDropdownField(
                                        label: "Filière",
                                        value: _selectedLyceeTrack,
                                        items: lyceeTracks,
                                        validatorMessage: "Sélectionnez la filière",
                                        onChanged: (val) => setState(() => _selectedLyceeTrack = val),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                            ),
                          const SizedBox(height: 100),
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
                        foregroundColor: Colors.deepPurple,
                        elevation: 12,
                        onPressed: _isSaving ? null : _submit,
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.deepPurple)
                            : const Icon(Icons.arrow_forward, size: 32),
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
}
