import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/ProfileSetup_Widget/BannerAndAvatarProfilePage/Tools/BannerAvatarStatusBar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../XpSystem.dart';
import '../../../main.dart';

class BannerAvatarProfile extends StatefulWidget {
  const BannerAvatarProfile({super.key});

  @override
  State<BannerAvatarProfile> createState() => _BannerAvatarProfileState();
}

class _BannerAvatarProfileState extends State<BannerAvatarProfile>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  late AnimationController _bgAnimationController;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    final user = xpManager.userProfile;

    _nameController.text = user.fullName;
    _usernameController.text = user.lastName ?? "";
    _emailController.text = user.email;

    setState(() {});
  }

  Future<void> _saveProfile() async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);

    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();

    audioManager.playEventSound('clickButton');

    if (name.isEmpty || name.length > 12) {
      _showError("Name must be between 1 and 12 characters");
      return;
    }
    if (username.isEmpty || username.length > 15) {
      _showError("Username must be between 1 and 15 characters");
      return;
    }
    if (email.isEmpty ||
        !RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email)) {
      _showError("Please enter a valid email");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    await prefs.setString('username', username);
    await prefs.setString('email', email);

    xpManager.setFullName(name);
    xpManager.setLastName(username);
    xpManager.setEmail(email);

    Navigator.pop(context);
  }

  void _showError(String message) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playEventSound('invalid');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1200),
        backgroundColor: Colors.redAccent,
        content: Text(
          message,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    return Scaffold(
      body: Stack(
        children: [
          // Animated playful background
          AnimatedBuilder(
            animation: _bgAnimationController,
            builder: (context, child) {
              return CustomPaint(
                painter: _BackgroundPainter(_bgAnimationController.value),
                child: Container(),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const BannerAvatarStatusBar(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildFunSectionTitle("Choose Your Banner"),
                          const SizedBox(height: 12),
                          _buildBannerSelector(xpManager, audioManager),
                          const SizedBox(height: 20),
                          _buildFunSectionTitle("Choose Your Avatar"),
                          const SizedBox(height: 12),
                          _buildAvatarSelector(xpManager, audioManager),
                          const SizedBox(height: 20),
                          _buildFunSectionTitle("Profile Info"),
                          const SizedBox(height: 12),
                          _buildField(_nameController, "Name", Icons.person),
                          _buildField(_usernameController, "Username",
                              Icons.alternate_email),
                          _buildField(_emailController, "Email", Icons.email,
                              TextInputType.emailAddress),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.orangeAccent, Colors.pinkAccent],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(1, 2),
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerSelector(
      ExperienceManager xpManager, AudioManager audioManager) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: xpManager.unlockedBanners.length,
        itemBuilder: (context, index) {
          final banner = xpManager.unlockedBanners[index];
          final isSelected = xpManager.selectedBannerImage == banner;

          return GestureDetector(
            onTap: () {
              audioManager.playEventSound('clickButton2');
              xpManager.selectBannerImage(banner);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected ? Colors.yellowAccent : Colors.transparent,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? Colors.yellowAccent.withOpacity(0.5)
                        : Colors.black12,
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  banner,
                  width: 260,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarSelector(
      ExperienceManager xpManager, AudioManager audioManager) {
    bool _isEmoji(String avatar) => !avatar.contains('/');

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: xpManager.unlockedAvatars.length,
        itemBuilder: (context, index) {
          final avatar = xpManager.unlockedAvatars[index];
          final isSelected = xpManager.selectedAvatar == avatar;

          return GestureDetector(
            onTap: () {
              audioManager.playEventSound('clickButton2');
              xpManager.selectAvatar(avatar);
            },
            child: Container(
              width: 110,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow behind selected avatar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: isSelected ? 120 : 100,
                    height: isSelected ? 120 : 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected
                          ? RadialGradient(
                        colors: [
                          Colors.yellowAccent.withOpacity(0.7),
                          Colors.orangeAccent.withOpacity(0.3),
                        ],
                      )
                          : null,
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: Colors.yellowAccent.withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 3,
                          )
                      ],
                    ),
                  ),
                  // Avatar or emoji
                  _isEmoji(avatar)
                      ? TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 8),
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, -value),
                        child: Text(
                          avatar,
                          style: TextStyle(
                            fontSize: isSelected ? 60 : 50,
                          ),
                        ),
                      );
                    },
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.asset(
                      avatar,
                      width: isSelected ? 90 : 80,
                      height: isSelected ? 90 : 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Optional: tiny sparkles around avatar
                  if (isSelected)
                    ...List.generate(3, (i) {
                      final angle = (i * 120).toDouble();
                      final radius = 55.0;
                      final x = radius * (i % 2 == 0 ? 1 : -1) * 0.5;
                      final y = radius * 0.3 * (i + 1) / 3;
                      return Positioned(
                        left: 50 + x,
                        top: 50 - y,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.yellowAccent.withOpacity(0.8),
                                blurRadius: 4,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildField(TextEditingController controller, String label, IconData icon,
      [TextInputType keyboardType = TextInputType.text]) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.orangeAccent),
          filled: true,
          fillColor: Colors.orange.shade100.withOpacity(0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _saveProfile,
        icon: const Icon(Icons.save, size: 28),
        label: const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Text(
            "Save Profile",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellowAccent.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
          shadowColor: Colors.orangeAccent,
        ),
      ),
    );
  }
}

// Custom background painter for floating stars, clouds, and playful shapes
class _BackgroundPainter extends CustomPainter {
  final double progress;

  _BackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw floating clouds
    paint.color = Colors.white.withOpacity(0.6);
    canvas.drawCircle(Offset(100 + progress * 50, 80), 30, paint);
    canvas.drawCircle(Offset(200 + progress * 40, 120), 40, paint);
    canvas.drawCircle(Offset(300 - progress * 60, 60), 25, paint);

    // Draw floating stars
    paint.color = Colors.yellowAccent.withOpacity(0.8);
    canvas.drawCircle(Offset(50 + progress * 70, 200), 8, paint);
    canvas.drawCircle(Offset(150 - progress * 60, 250), 6, paint);
    canvas.drawCircle(Offset(250 + progress * 50, 180), 10, paint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) => true;
}
