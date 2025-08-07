import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import '../XpSystem.dart';
import 'UserInfoPage6.dart';

class UserInfoPage5 extends StatefulWidget {
  final VoidCallback? onNext;

  const UserInfoPage5({Key? key, this.onNext}) : super(key: key);

  @override
  _UserInfoPage5State createState() => _UserInfoPage5State();
}

class _UserInfoPage5State extends State<UserInfoPage5>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _countryController = TextEditingController();

  late AnimationController _gradientController;
  int currentGradientIndex = 0;

  bool _isFormValid = false;
  bool _isSaving = false;
  String? _errorMessage;

  final List<List<Color>> gradientSets = [
    [const Color(0xFF6DD5FA), const Color(0xFF2980B9)], // Soft Blue
    [const Color(0xFFFFD194), const Color(0xFFD1913C)], // Warm Gold
    [const Color(0xFFB2FEFA), const Color(0xFF0ED2F7)], // Light Turquoise
  ];

  @override
  void initState() {
    super.initState();
    _loadData();

    _countryController.addListener(_validateForm);

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

  void _loadData() {
    final experience = Provider.of<ExperienceManager>(context, listen: false);
    _countryController.text = experience.country;
    _validateForm();
  }

  void _validateForm() {
    final experience = Provider.of<ExperienceManager>(context, listen: false);
    final isValid = _countryController.text.trim().isNotEmpty &&
        experience.selectedBannerImage.isNotEmpty;
    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<bool> saveData() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = "Veuillez entrer votre pays.";
      });
      return false;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final experience = Provider.of<ExperienceManager>(context, listen: false);
      experience.setCountry(_countryController.text.trim());
      // Banner is already selected live, so no need to set here.
      return true;
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur lors de la sauvegarde : $e";
      });
      return false;
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _countryController.removeListener(_validateForm);
    _countryController.dispose();
    super.dispose();
  }

  Widget _buildInputField() {
    return TextFormField(
      controller: _countryController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: "Pays",
        prefixIcon: const Icon(Icons.flag, color: Colors.white),
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
          return "Veuillez entrer votre pays.";
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextIndex = (currentGradientIndex + 1) % gradientSets.length;
    final experience = Provider.of<ExperienceManager>(context);

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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: ListView(
                      children: [
                        const Userstatutbar(),
                        const SizedBox(height: 16),

                        const Text(
                          "Veuillez choisir une bannière.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),

                        const SizedBox(height: 30),

                        const Text(
                          'Choisissez votre bannière',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.left,
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: experience.unlockedBanners.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final bannerPath = experience.unlockedBanners[index];
                              final isSelected = bannerPath == experience.selectedBannerImage;

                              return GestureDetector(
                                onTap: () {
                                  experience.selectBannerImage(bannerPath);
                                  _validateForm();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 350),
                                  width: 220,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSelected
                                        ? Border.all(color: Colors.white, width: 4)
                                        : Border.all(color: Colors.transparent),
                                    boxShadow: isSelected
                                        ? [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.45),
                                        blurRadius: 14,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                        : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      )
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.asset(
                                      bannerPath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                            color: Colors.grey[300],
                                            child: const Center(child: Icon(Icons.broken_image)),
                                          ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 40),

                      ],
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
