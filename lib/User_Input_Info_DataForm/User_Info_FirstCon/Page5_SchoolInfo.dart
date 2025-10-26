import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
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

  String? _selectedSchoolType;
  String? _selectedSchoolLevel;
  String? _selectedGrade;
  String? _selectedLyceeTrack;

  bool? _isStudent; // true = Student, false = Not Student

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

  final List<String> schoolTypes = ['Private', 'Public', 'Other'];
  final List<String> schoolLevels = ['Primary', 'Middle School', 'High School'];

  final Map<String, List<String>> gradesByLevel = {
    'Primary': ['Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6'],
    'Middle School': ['Grade 7', 'Grade 8', 'Grade 9'],
    'High School': ['Common Track', '1st Year Bac', 'Baccalaureate'],
  };

  final List<String> lyceeTracks = ['Science', 'Arts'];

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
    final lyceeTrackValid = _selectedSchoolLevel == 'High School'
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
    setState(() { _errorMessage = null; });

    if (_selectedSchoolType == null ||
        _selectedSchoolLevel == null ||
        _selectedGrade == null ||
        (_selectedSchoolLevel == 'High School' && _selectedLyceeTrack == null) ||
        _schoolNameController.text.trim().isEmpty) {
      setState(() { _errorMessage = "Please complete all fields"; });
      return false;
    }

    setState(() { _isSaving = true; });
    try {
      final experienceManager = Provider.of<ExperienceManager>(context, listen: false);
      experienceManager.setSchoolName(_schoolNameController.text.trim());
      experienceManager.setSchoolType(_selectedSchoolType!);
      experienceManager.setSchoolLevel(_selectedSchoolLevel!);
      experienceManager.setSchoolGrade(_selectedGrade!);
      experienceManager.setLyceeTrack(_selectedSchoolLevel == 'High School'
          ? _selectedLyceeTrack!
          : '');
      return true;
    } catch (e) {
      setState(() { _errorMessage = "Error saving data: $e"; });
      return false;
    } finally {
      if (mounted) setState(() { _isSaving = false; });
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 7),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
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
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    return TextFormField(
      controller: controller,
      onTap: () {
        audioManager.playEventSound('PopButton');
      },
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
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : null,
        dropdownColor: Colors.deepOrange.shade400.withOpacity(0.5),
        onTap: () {
          audioManager.playEventSound('toggleButton');
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 16),
          prefixIcon: icon != null ? Icon(icon, color: Colors.white70, size: 24) : null,
          enabledBorder: OutlineInputBorder(
            gapPadding: 1,
            borderRadius: BorderRadius.circular(25),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextIndex = (currentGradientIndex + 1) % gradientSets.length;
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    final colors = List<Color>.generate(
      2,
          (i) => Color.lerp(
        gradientSets[currentGradientIndex][i],
        gradientSets[nextIndex][i],
        _gradientController.value,
      )!,
    );

    return Scaffold(
      body: Container(
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
              if (_isStudent == null)
                _buildStudentSelection(audioManager)
              else
                _buildFormContent(audioManager),
            ],
          ),
        ),
      ),
    );
  }

  // Student / Not Student Selection
  Widget _buildStudentSelection(AudioManager audioManager) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 220,
            child: Lottie.asset(
              'assets/animations/FirstTouchAnimations/School.json',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Are you a student?",
            style: TextStyle(
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(0, 3))]),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  audioManager.playEventSound('clickButton');
                  setState(() {
                    _isStudent = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20))),
                child: const Text("Yes", style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () {
                  audioManager.playEventSound('clickButton');
                  setState(() {
                    _isStudent = false;
                  });
                  widget.onNext?.call(); // Skip form
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20))),
                child: const Text("No", style: TextStyle(fontSize: 18)),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Form Content for Students
  Widget _buildFormContent(AudioManager audioManager) {
    return Stack(
      children: [
        Stack(
          fit: StackFit.expand,
          children: [
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                  "School Information",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(0, 3))]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                _buildInputCard(
                  child: _buildInputField(
                      controller: _schoolNameController,
                      label: "School Name",
                      validatorMessage: "Please enter the school name.",
                      icon: Icons.school_outlined),
                ),
                _buildInputCard(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildDropdownField(
                          label: "School Type",
                          value: _selectedSchoolType,
                          items: schoolTypes,
                          validatorMessage: "Select school type.",
                          onChanged: (val) => setState(() => _selectedSchoolType = val),
                          icon: Icons.apartment_outlined,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 4,
                        child: _buildDropdownField(
                          label: "School Level",
                          value: _selectedSchoolLevel,
                          items: schoolLevels,
                          validatorMessage: "Select school level.",
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
                            label: "Grade",
                            value: _selectedGrade,
                            items: gradesByLevel[_selectedSchoolLevel!] ?? [],
                            validatorMessage: "Select grade.",
                            onChanged: (val) {
                              setState(() {
                                _selectedGrade = val;
                              });
                              _validateForm();
                            },
                            icon: Icons.grade_outlined,
                          ),
                        ),
                        if (_selectedSchoolLevel == 'High School') ...[
                          const SizedBox(width: 6),
                          Expanded(
                            flex: 3,
                            child: _buildDropdownField(
                              label: "High School Track",
                              value: _selectedLyceeTrack,
                              items: lyceeTracks,
                              validatorMessage: "Select high school track.",
                              onChanged: (val) {
                                setState(() {
                                  _selectedLyceeTrack = val;
                                });
                                _validateForm();
                              },
                            ),
                          ),
                        ]
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
                const SizedBox(height: 80), // space for FAB
              ],
            ),
          ],
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
                  audioManager.playEventSound('clickButton');
                  widget.onNext?.call();
                }
              },
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.deepOrange)
                  : const Icon(Icons.arrow_forward, size: 32),
            ),
          ),
      ],
    );
  }
}
