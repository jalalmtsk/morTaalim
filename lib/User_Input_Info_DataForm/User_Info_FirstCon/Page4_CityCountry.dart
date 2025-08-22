import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/main.dart';
import 'package:provider/provider.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../../XpSystem.dart';
import '../../IndexPage.dart';
import '../../tools/audio_tool/Audio_Manager.dart'; // Adjust as needed

class CityCountryPage extends StatefulWidget {
  final VoidCallback? onNext;

  const CityCountryPage({Key? key, this.onNext}) : super(key: key);

  @override
  State<CityCountryPage> createState() => _CityCountryPageState();
}

class _CityCountryPageState extends State<CityCountryPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  final FocusNode _cityFocus = FocusNode();
  final FocusNode _countryFocus = FocusNode();

  late AnimationController _gradientController;
  int currentGradientIndex = 0;

  bool _isFormValid = false;
  String? _errorMessage;
  bool _isSaving = false;

  final List<List<Color>> gradientSets = [
    [const Color(0xFF6DD5FA), const Color(0xFF2980B9)], // Bleu doux
    [const Color(0xFFFFD194), const Color(0xFFD1913C)], // Or chaud
    [const Color(0xFFB2FEFA), const Color(0xFF0ED2F7)], // Turquoise clair
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();

    _cityController.addListener(_validateForm);
    _countryController.addListener(_validateForm);

    // Scroll to active field when focused
    _cityFocus.addListener(() {
      if (_cityFocus.hasFocus) _scrollToField(0);
    });
    _countryFocus.addListener(() {
      if (_countryFocus.hasFocus) _scrollToField(1);
    });

    // Keyboard visibility listener
    KeyboardVisibilityController().onChange.listen((visible) {
      if (visible) {
        if (_cityFocus.hasFocus) _scrollToField(0);
        if (_countryFocus.hasFocus) _scrollToField(1);
      }
    });

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

  void _scrollToField(int index) {
    // Adjust these offsets depending on layout
    double offset = index == 0 ? 200 : 300;
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _validateForm() {
    final cityValid = _cityController.text.trim().isNotEmpty;
    final countryValid = _countryController.text.trim().isNotEmpty;

    final isValid = cityValid && countryValid;

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<void> _loadProfile() async {
    final experienceManager =
    Provider.of<ExperienceManager>(context, listen: false);
    final user = experienceManager.userProfile;

    setState(() {
      _cityController.text = user.city;
      _countryController.text = user.country;
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

    setState(() {
      _isSaving = true;
    });

    try {
      final experienceManager =
      Provider.of<ExperienceManager>(context, listen: false);

      experienceManager.setCity(_cityController.text.trim());
      experienceManager.setCountry(_countryController.text.trim());

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
    _cityController.removeListener(_validateForm);
    _countryController.removeListener(_validateForm);
    _cityController.dispose();
    _countryController.dispose();
    _cityFocus.dispose();
    _countryFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String validatorMessage,
    IconData? icon,
    FocusNode? focusNode,
    Function() ? onTap,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      onTap: onTap,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.white) : null,
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
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return validatorMessage;
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextIndex = (currentGradientIndex + 1) % gradientSets.length;
    final audioManager = Provider.of<AudioManager>(context, listen: false);

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
                        controller: _scrollController,
                        children: [
                          SizedBox(
                            height: 300,
                            child: Center(
                              child: Lottie.asset(
                                'assets/animations/FirstTouchAnimations/BusTransport.json',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                           Text(
                            tr(context).yourLocation,
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

                          const SizedBox(height: 10),

                          Text(
                            tr(context).pleaseEnterYourCityAndCountryToContinue,
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
                            controller: _cityController,
                            focusNode: _cityFocus,
                            label: tr(context).city,
                            validatorMessage: tr(context).pleaseEnterYourCity,
                            icon: Icons.location_city,
                              onTap : ()
                              {
                                audioManager.playEventSound('PopButton');
                              }
                          ),

                          const SizedBox(height: 16),

                          _buildInputField(
                            controller: _countryController,
                            focusNode: _countryFocus,
                            label: tr(context).country,
                            validatorMessage: tr(context).pleaseEnterYourCountry,
                            icon: Icons.flag,
                            onTap : ()
                            {
                              audioManager.playEventSound('PopButton');

                            }
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
                        onPressed: _isSaving
                            ? null
                            : () async {
                          final success = await saveData();
                          if (success) {
                            audioManager.playEventSound("clickButton");
                            widget.onNext?.call();
                          }
                        },
                        elevation: 6,
                        child: _isSaving
                            ? const CircularProgressIndicator(
                          color: Colors.deepOrange,
                        )
                            : const Icon(Icons.arrow_forward, size: 28),
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
