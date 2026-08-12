import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import '../../XpSystem.dart';

class UserInfoBannerPage extends StatefulWidget {
  final VoidCallback? onNext;

  const UserInfoBannerPage({Key? key, this.onNext}) : super(key: key);

  @override
  _UserInfoBannerPageState createState() => _UserInfoBannerPageState();
}

class _UserInfoBannerPageState extends State<UserInfoBannerPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _countryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _gradientController;
  int currentGradientIndex = 0;

  bool _isFormValid = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Deeper, richer gradient pairs for a premium feel
  final List<List<Color>> gradientSets = [
    [const Color(0xFF1A1A2E), const Color(0xFF16213E)],   // Deep Navy
    [const Color(0xFF0F3460), const Color(0xFF533483)],   // Indigo Purple
    [const Color(0xFF1B262C), const Color(0xFF0F3460)],   // Dark Teal
  ];

  static const Color _accent = Color(0xFFFF6B35);         // Vibrant orange accent
  static const Color _accentLight = Color(0xFFFFD166);    // Warm gold highlight

  @override
  void initState() {
    super.initState();
    _loadData();
    _countryController.addListener(_validateForm);

    // ✅ Fix: defer scroll controller usage until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      KeyboardVisibilityController().onChange.listen((visible) {
        if (visible && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    });

    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
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

  void _loadData() {
    final experience = Provider.of<ExperienceManager>(context, listen: false);
    _countryController.text = experience.userProfile.country;
    _validateForm();
  }

  void _validateForm() {
    final experience = Provider.of<ExperienceManager>(context, listen: false);
    final isValid = _countryController.text.trim().isNotEmpty &&
        experience.selectedBannerImage.isNotEmpty;
    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  Future<bool> saveData() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) {
      setState(() => _errorMessage = "Veuillez entrer votre pays.");
      return false;
    }
    setState(() => _isSaving = true);
    try {
      final experience = Provider.of<ExperienceManager>(context, listen: false);
      experience.setCountry(_countryController.text.trim());
      return true;
    } catch (e) {
      setState(() => _errorMessage = "Erreur lors de la sauvegarde : $e");
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _countryController.removeListener(_validateForm);
    _countryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextIndex = (currentGradientIndex + 1) % gradientSets.length;
    final experience = Provider.of<ExperienceManager>(context);
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, _) {
          final colors = List<Color>.generate(2, (i) => Color.lerp(
            gradientSets[currentGradientIndex][i],
            gradientSets[nextIndex][i],
            _gradientController.value,
          )!);

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
                  // ── Main scrollable content ──────────────────────────
                  Form(
                    key: _formKey,
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      children: [
                        const Userstatutbar(),
                        const SizedBox(height: 28),

                        // ── Header ───────────────────────────────────────
                        _buildHeader(context),
                        const SizedBox(height: 32),

                        // ── Banner Carousel ──────────────────────────────
                        _buildBannerSection(experience, audioManager),
                        const SizedBox(height: 32),

                        // ── Mascot ───────────────────────────────────────
                        Center(
                          child: SizedBox(
                            height: 160,
                            child: Lottie.asset(
                              "assets/animations/UI_Animations/WakiBot.json",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        // ── Error message ────────────────────────────────
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          _buildErrorBanner(),
                        ],
                      ],
                    ),
                  ),

                  // ── Continue button ──────────────────────────────────
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutBack,
                    bottom: _isFormValid ? 24 : -80,
                    right: 24,
                    child: _buildContinueButton(audioManager, experience),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Eyebrow label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accent.withOpacity(0.5), width: 1),
          ),
          child: Text(
            "✦  PERSONNALISATION",
            style: TextStyle(
              color: _accentLight,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 12),

        Text(
          tr(context).chooseYourBanner,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr(context).pleaseChooseABanner,
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBannerSection(ExperienceManager experience, AudioManager audioManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected banner large preview
        if (experience.selectedBannerImage.isNotEmpty)
          _buildSelectedPreview(experience),

        const SizedBox(height: 16),

        // Horizontal carousel
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: experience.unlockedBanners.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final bannerPath = experience.unlockedBanners[index];
              final isSelected = bannerPath == experience.selectedBannerImage;

              return GestureDetector(
                onTap: () {
                  audioManager.playEventSound('clickButton2');
                  experience.selectBannerImage(bannerPath);
                  _validateForm();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? _accent : Colors.white.withOpacity(0.15),
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: _accent.withOpacity(0.4), blurRadius: 16, spreadRadius: 1)]
                        : [],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          bannerPath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.white12,
                            child: const Center(child: Icon(Icons.broken_image, color: Colors.white38)),
                          ),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: _accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedPreview(ExperienceManager experience) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: Tween(begin: 0.95, end: 1.0).animate(animation), child: child),
      ),
      child: Container(
        key: ValueKey(experience.selectedBannerImage),
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: _accent.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(experience.selectedBannerImage, fit: BoxFit.cover),
              // Subtle gradient overlay for the "selected" label
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.45)],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 13),
                      SizedBox(width: 4),
                      Text("Sélectionné", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(AudioManager audioManager, ExperienceManager experience) {
    return GestureDetector(
      onTap: _isSaving
          ? null
          : () async {
        final success = await saveData();
        if (success) {
          audioManager.playEventSound('clickButton');
          widget.onNext?.call();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_accent, Color(0xFFFF8C42)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: _isSaving
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
        )
            : const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Continuer",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}