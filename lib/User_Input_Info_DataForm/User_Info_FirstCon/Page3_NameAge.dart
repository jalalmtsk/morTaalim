import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../XpSystem.dart';
import '../../tools/audio_tool/Audio_Manager.dart';

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

  bool isMinor = false;

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
      if (!mounted) return;   // ✅ Prevent crash after dispose()
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

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final experienceManager = Provider.of<ExperienceManager>(context, listen: false);

    int savedAge = prefs.getInt('age') ?? experienceManager.userProfile.age;

    isMinor = savedAge < 18;

    _ageController.text = savedAge > 0 ? savedAge.toString() : "";

    _nameController.text =
        prefs.getString('name') ?? experienceManager.userProfile.fullName;

    if (!isMinor) {
      _lastNameController.text =
          prefs.getString('lastName') ?? experienceManager.userProfile.lastName;
    }

    _validateForm();
  }

  void _validateForm() {
    final nameValid = _nameController.text.trim().isNotEmpty;
    final ageValid = _ageController.text.trim().isNotEmpty;

    bool lastNameValid = true;
    if (!isMinor) {
      lastNameValid = _lastNameController.text.trim().isNotEmpty;
    }

    _isFormValid = nameValid && ageValid && lastNameValid;
    setState(() {});
  }

  Future<bool> saveData() async {
    if (!_formKey.currentState!.validate()) return false;

    final prefs = await SharedPreferences.getInstance();
    final experienceManager = Provider.of<ExperienceManager>(context, listen: false);

    final name = _nameController.text.trim();
    final age = int.parse(_ageController.text.trim());

    final lastName = isMinor ? "" : _lastNameController.text.trim();

    await prefs.setString('name', name);
    await prefs.setInt('age', age);
    await prefs.setString('lastName', lastName);

    experienceManager.setFullName(name);
    experienceManager.setAge(age);
    experienceManager.setLastName(lastName);

    return true;
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
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
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          SizedBox(
                            height: 250,
                            child: Center(
                              child: Lottie.asset(
                                'assets/animations/FirstTouchAnimations/Learning.json',
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            tr(context).letsGetToKnowEachOther,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 35),

                          _buildInputField(
                            controller: _nameController,
                            label:isMinor ? tr(context).username : tr(context).firstName,
                            onTap: () => audioManager.playEventSound('PopButton'),
                            validator: (v) =>
                            v == null || v.trim().isEmpty
                                ? tr(context).pleaseEnterName
                                : null,
                          ),

                          const SizedBox(height: 16),

                          if (!isMinor) ...[
                            _buildInputField(
                              controller: _lastNameController,
                              label: tr(context).lastName,
                              onTap: () => audioManager.playEventSound('PopButton'),
                              validator: (v) {
                                if (isMinor) return null;
                                if (v == null || v.trim().isEmpty) {
                                  return tr(context).pleaseEnterYourLastName;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

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
                          audioManager.playEventSound('clickButton');
                          if (await saveData()) {
                            widget.onNext?.call();
                          }
                        },
                        child: const Icon(Icons.arrow_forward, size: 28),
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
    Function()? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onTap: onTap,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.7)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
      validator: validator,
    );
  }
}
