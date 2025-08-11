import 'package:flutter/material.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../XpSystem.dart';

class UserInfoAvatarAndGender extends StatefulWidget {
  final VoidCallback? onNext;

  const UserInfoAvatarAndGender({Key? key, this.onNext}) : super(key: key);

  @override
  _UserInfoAvatarAndGenderState createState() => _UserInfoAvatarAndGenderState();
}

class _UserInfoAvatarAndGenderState extends State<UserInfoAvatarAndGender>
    with SingleTickerProviderStateMixin {
  late AnimationController _gradientController;
  int currentGradientIndex = 0;
  int _currentAvatarIndex = 0;

  bool _isSaving = false;
  String? _errorMessage;

  final PageController _avatarPageController = PageController(viewportFraction: 0.6);

  final List<List<Color>> gradientSets = [
    [const Color(0xFF6DD5FA), const Color(0xFF2980B9)],
    [const Color(0xFFFFD194), const Color(0xFFD1913C)],
    [const Color(0xFFB2FEFA), const Color(0xFF0ED2F7)],
  ];

  @override
  void initState() {
    super.initState();
    _loadGender();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => currentGradientIndex = (currentGradientIndex + 1) % gradientSets.length);
        _gradientController.forward(from: 0);
      }
    });
    _gradientController.forward();
  }

  Future<void> _loadGender() async {
    final prefs = await SharedPreferences.getInstance();
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    final savedGender = prefs.getString('gender');
    if (savedGender != null) xpManager.setGender(savedGender);
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _avatarPageController.dispose();
    super.dispose();
  }

  Future<bool> saveSelection(ExperienceManager xpManager) async {
    setState(() {
      _errorMessage = null;
      _isSaving = true;
    });

    if (xpManager.selectedAvatar.isEmpty) {
      setState(() {
        _errorMessage = "Veuillez sélectionner un avatar.";
        _isSaving = false;
      });
      return false;
    }

    if (xpManager.userProfile.gender.isEmpty) {
      setState(() {
        _errorMessage = "Veuillez sélectionner votre genre.";
        _isSaving = false;
      });
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gender', xpManager.userProfile.gender);
    return true;
  }

  bool _isEmoji(String avatar) => !avatar.contains('/');

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final nextIndex = (currentGradientIndex + 1) % gradientSets.length;
    bool isSelectionValid = xpManager.selectedAvatar.isNotEmpty && xpManager.userProfile.gender.isNotEmpty;

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
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Userstatutbar(),
                        const SizedBox(height: 20),

                        _buildAvatarPreview(xpManager),
                        const SizedBox(height: 16),

                        _buildAvatarCarousel(xpManager),
                        const SizedBox(height: 20),

                        _buildGenderToggle(xpManager),
                      ],
                    ),
                  ),

                  if (isSelectionValid)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: FloatingActionButton(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepOrange,
                        elevation: 6,
                        onPressed: _isSaving
                            ? null
                            : () async {
                          final success = await saveSelection(xpManager);
                          if (success) widget.onNext?.call();
                        },
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.deepOrange)
                            : const Icon(Icons.arrow_forward, size: 28),
                      ),
                    ),

                  if (_errorMessage != null)
                    Positioned(
                      bottom: 80,
                      left: 24,
                      right: 24,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
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

  Widget _buildAvatarPreview(ExperienceManager xpManager) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white,
          child: xpManager.selectedAvatar.isNotEmpty
              ? (_isEmoji(xpManager.selectedAvatar)
              ? Text(xpManager.selectedAvatar, style: const TextStyle(fontSize: 50))
              : ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.asset(xpManager.selectedAvatar, fit: BoxFit.cover),
          ))
              : const Icon(Icons.person, size: 50, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        Text(
          xpManager.userProfile.gender.isEmpty
              ? "Sélectionnez votre genre"
              : xpManager.userProfile.gender == "male"
              ? "Homme"
              : "Femme",
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildAvatarCarousel(ExperienceManager xpManager) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _avatarPageController,
        itemCount: xpManager.unlockedAvatars.length,
        onPageChanged: (index) {
          setState(() {
            _currentAvatarIndex = index;
            xpManager.selectAvatar(xpManager.unlockedAvatars[index]);
          });
        },
        itemBuilder: (context, index) {
          final avatar = xpManager.unlockedAvatars[index];
          final scale = index == _currentAvatarIndex ? 1.0 : 0.8;

          return TweenAnimationBuilder(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: scale, end: scale),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: index == _currentAvatarIndex ? Colors.deepOrange : Colors.transparent,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: index == _currentAvatarIndex
                            ? Colors.deepOrange.withValues(alpha: 0.5)
                            : Colors.black26,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isEmoji(avatar)
                      ? Center(child: Text(avatar, style: const TextStyle(fontSize: 100)))
                      : ClipOval(child: Image.asset(avatar, fit: BoxFit.cover)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGenderToggle(ExperienceManager xpManager) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildGenderButton("male", Icons.male, xpManager),
          _buildGenderButton("female", Icons.female, xpManager),
        ],
      ),
    );
  }

  Widget _buildGenderButton(String gender, IconData icon, ExperienceManager xpManager) {
    final isSelected = xpManager.userProfile.gender == gender;
    return GestureDetector(
      onTap: () => xpManager.setGender(gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.deepOrange.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.deepOrange),
            const SizedBox(width: 6),
            Text(
              gender == "male" ? "Homme" : "Femme",
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.deepOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
