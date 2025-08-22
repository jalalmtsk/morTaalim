import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../XpSystem.dart';

class SchoolInfoPage extends StatefulWidget {
  final VoidCallback? onNext;

  const SchoolInfoPage({Key? key, this.onNext}) : super(key: key);

  @override
  State<SchoolInfoPage> createState() => _SchoolInfoPageState();
}

class _SchoolInfoPageState extends State<SchoolInfoPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _schoolNameController = TextEditingController();

  String? _selectedSchoolType; // privé, publique, autre
  String? _selectedSchoolLevel; // Primaire, Collège, Lycée
  String? _selectedGrade;
  String? _selectedLyceeTrack;

  late AnimationController _gradientController;
  int currentGradientIndex = 0;

  bool _isFormValid = false;
  String? _errorMessage;
  bool _isSaving = false;

  final List<List<Color>> gradientSets = [
    [Colors.deepPurple.shade400, Colors.deepPurple.shade800],
    [Colors.orange.shade300, Colors.orange.shade700],
    [Colors.teal.shade300, Colors.teal.shade700],
  ];

  final List<String> schoolTypes = ['Privé', 'Publique', 'Autre'];
  final List<String> schoolLevels = ['Primaire', 'Collège', 'Lycée'];

  final Map<String, List<String>> gradesByLevel = {
    'Primaire': [
      '1ère année primaire (CP)',
      '2ème année primaire (CE1)',
      '3ème année primaire (CE2)',
      '4ème année primaire (CM1)',
      '5ème année primaire (CM2)',
      '6ème année primaire (CM3)',
    ],
    'Collège': [
      '7ème année (1ère année collège)',
      '8ème année (2ème année collège)',
      '9ème année (3ème année collège)',
    ],
    'Lycée': [
      '(Tronc Commun / TC)',
      '1ère année bac (Régional)',
      'Baccalauréat (National)',
    ],
  };

  final List<String> lyceeTracks = [
    'Science',
    'Lettre',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();

    _schoolNameController.addListener(_validateForm);

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

  void _validateForm() {
    final schoolNameValid = _schoolNameController.text.trim().isNotEmpty;
    final schoolTypeValid = _selectedSchoolType != null && _selectedSchoolType!.isNotEmpty;
    final schoolLevelValid = _selectedSchoolLevel != null && _selectedSchoolLevel!.isNotEmpty;
    final gradeValid = _selectedGrade != null && _selectedGrade!.isNotEmpty;

    final lyceeTrackValid = _selectedSchoolLevel == 'Lycée'
        ? _selectedLyceeTrack != null && _selectedLyceeTrack!.isNotEmpty
        : true;

    final isValid = schoolNameValid && schoolTypeValid && schoolLevelValid && gradeValid && lyceeTrackValid;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<void> _loadProfile() async {
    final experienceManager = Provider.of<ExperienceManager>(context, listen: false);
    final user = experienceManager.userProfile;

    setState(() {
      _schoolNameController.text = user.schoolName;
      _selectedSchoolType = user.schoolType.isNotEmpty ? user.schoolType : null;
      _selectedSchoolLevel = user.schoolLevel.isNotEmpty ? user.schoolLevel : null;
      _selectedGrade = user.schoolGrade.isNotEmpty ? user.schoolGrade : null;
      _selectedLyceeTrack = user.lyceeTrack.isNotEmpty ? user.lyceeTrack : null;
    });

    _validateForm();
  }

  Future<bool> saveData() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate() ||
        _selectedSchoolType == null ||
        _selectedSchoolLevel == null ||
        _selectedGrade == null ||
        (_selectedSchoolLevel == 'Lycée' && _selectedLyceeTrack == null)) {
      setState(() {
        _errorMessage = "Veuillez remplir correctement tous les champs.";
      });
      return false;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final experienceManager = Provider.of<ExperienceManager>(context, listen: false);

      experienceManager.setSchoolName(_schoolNameController.text.trim());
      experienceManager.setSchoolType(_selectedSchoolType!);
      experienceManager.setSchoolLevel(_selectedSchoolLevel!);
      experienceManager.setSchoolGrade(_selectedGrade!);
      if (_selectedSchoolLevel == 'Lycée') {
        experienceManager.setLyceeTrack(_selectedLyceeTrack!);
      } else {
        experienceManager.setLyceeTrack('');
      }

      return true;
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur lors de la sauvegarde des données : $e";
      });
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _schoolNameController.removeListener(_validateForm);
    _schoolNameController.dispose();
    super.dispose();
  }

  Widget _buildInputCard({required Widget child}) {
    return Card(
      color: Colors.white.withOpacity(0.15),
      elevation: 8,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: child,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String validatorMessage,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 16),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white70, size: 24) : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white70.withOpacity(0.6), width: 1.8),
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
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return validatorMessage;
        }
        return null;
      },
      cursorColor: Colors.white,
    );
  }

  Widget _buildDropdownField({
    required String label,
    String? value,
    required List<String> items,
    required String validatorMessage,
    required void Function(String?) onChanged,
    IconData? icon,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null, // <-- Prevent invalid value
      dropdownColor: Colors.deepOrange.shade400,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 16),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white70, size: 24) : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white70.withOpacity(0.6), width: 1.8),
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
      items: items
          .map((e) => DropdownMenuItem<String>(
        value: e,
        child: Text(e, style: const TextStyle(color: Colors.white)),
      ))
          .toList(),
      onChanged: (val) {
        onChanged(val);
        _validateForm();
      },
      validator: (val) {
        if (val == null || val.isEmpty) {
          return validatorMessage;
        }
        return null;
      },
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
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 220,
                            child: Center(
                              child: Lottie.asset(
                                'assets/animations/FirstTouchAnimations/School.json',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          const Text(
                            "Informations scolaires",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 8,
                                  color: Colors.black54,
                                  offset: Offset(0, 3),
                                )
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 2),

                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "Veuillez entrer le nom de l'école, le type, le niveau, et la classe.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          _buildInputCard(
                            child: _buildInputField(
                              controller: _schoolNameController,
                              label: "Nom de l'école",
                              validatorMessage: "Veuillez saisir le nom de l'école.",
                              icon: Icons.school_outlined,
                            ),
                          ),

                          _buildInputCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildDropdownField(
                                    label: "Type d'école",
                                    value: _selectedSchoolType,
                                    items: schoolTypes,
                                    validatorMessage: "Sélectionnez le type d'école.",
                                    onChanged: (val) => setState(() => _selectedSchoolType = val),
                                    icon: Icons.apartment_outlined,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _buildDropdownField(
                                    label: "Niveau scolaire",
                                    value: _selectedSchoolLevel,
                                    items: schoolLevels,
                                    validatorMessage: "Sélectionnez le niveau scolaire.",
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedSchoolLevel = val;
                                        _selectedGrade = null;
                                        _selectedLyceeTrack = null;
                                      });
                                      _validateForm();
                                    },
                                    icon: Icons.account_tree_outlined,
                                  ),
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
                                      validatorMessage: "Sélectionnez la classe.",
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedGrade = val;
                                        });
                                        _validateForm();
                                      },
                                      icon: Icons.grade_outlined,
                                    ),
                                  ),

                                  if (_selectedSchoolLevel == 'Lycée') ...[
                                    const SizedBox(width: 6),
                                    Expanded(
                                      flex: 2,
                                      child: _buildDropdownField(
                                        label: "Filière Lycée",
                                        value: _selectedLyceeTrack,
                                        items: lyceeTracks,
                                        validatorMessage: "Sélectionnez la filière du lycée.",
                                        onChanged: (val) {
                                          setState(() {
                                            _selectedLyceeTrack = val;
                                          });
                                          _validateForm();
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700),
                                textAlign: TextAlign.center,
                              ),
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
                        elevation: 12,
                        onPressed: _isSaving
                            ? null
                            : () async {
                          final success = await saveData();
                          if (success) {
                            widget.onNext?.call();
                          }
                        },
                        child: _isSaving
                            ? const CircularProgressIndicator(
                          color: Colors.deepOrange,
                        )
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