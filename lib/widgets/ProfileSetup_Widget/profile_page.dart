import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import 'UserDataProfileEntering.dart';
import '../../XpSystem.dart'; // Your XP related stuff


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Widget _buildAvatar(String avatar) {
    const double size = 80;

    if (avatar.endsWith('.json')) {
      // Lottie animation avatar
      return Lottie.asset(avatar, repeat: true, fit: BoxFit.contain);
    } else if (avatar.startsWith('assets/')) {
      return Image.asset(avatar, width: size, height: size, fit: BoxFit.cover);
    } else {
      // Emoji avatar or text fallback
      return Center(child: Text(avatar, style: const TextStyle(fontSize: 64)));
    }
  }

  String _getAvatarFrameImage(int level) {
    // Returns avatar frame image based on level
    if (level >= 50) return 'assets/images/Banners/Islamic/Islamic7.png';
    if (level >= 35) return 'assets/images/Banners/Islamic/Islamic6.png';
    if (level >= 25) return 'assets/images/Banners/Islamic/Islamic5.png';
    if (level >= 15) return 'assets/images/Banners/Islamic/Islamic4.png';
    if (level >= 7) return 'assets/images/Banners/Islamic/Islamic3.png';
    if (level >= 5) return 'assets/images/Banners/Islamic/Islamic2.png';
    return 'assets/images/Banners/Islamic/Islamic1.png';
  }

  Future<void> _confirmResetXP() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reset Progress?"),
        content: const Text("Are you sure you want to reset your XP and stars?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Reset"),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      Provider.of<ExperienceManager>(context, listen: false).resetData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("XP and stars reset.")),
      );
    }
  }

  TextStyle _sectionTitleStyle(Color color) => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: color,
    shadows: const [Shadow(blurRadius: 3, color: Colors.black26)],
  );

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final user = xpManager.userProfile;
    final tr = AppLocalizations.of(context)!;

    final level = xpManager.level;
    final progress = xpManager.levelProgress;
    final xp = xpManager.xp;
    final stars = xpManager.stars;
    final tokens = xpManager.saveTokenCount;
    final userName = user.fullName.isNotEmpty ? user.fullName : 'UnkownUser';
    final userMood = "😊"; // You can add mood to your ExperienceManager and get it here
    final favoriteColor = Colors.deepPurple; // Replace by dynamic color if you have it

    return Scaffold(
      backgroundColor: const Color(0xfffff3e0),
      appBar: AppBar(
        title: Text(tr.myProfile, style: const TextStyle(fontFamily: 'ComicNeue', fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'edit',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => UserInfoFormPage()));
            },
          ),
        ],
        backgroundColor: favoriteColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Banner + Avatar + Name
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    xpManager.selectedBannerImage,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withOpacity(0.25),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _bounceAnimation,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipOval(
                                child: Image.asset(
                                  _getAvatarFrameImage(level),
                                  width: 115,
                                  height: 115,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              ClipOval(
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  color: Colors.white,
                                  child: _buildAvatar(xpManager.selectedAvatar),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontFamily: 'ComicNeue',
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userMood,
                          style: const TextStyle(fontSize: 20, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _infoRow(Icons.email, user.email.isNotEmpty ? user.email : 'noEmail', Colors.deepPurple),
            const SizedBox(height: 12),
            _infoRow(Icons.cake, "${user.age} ${'years Old'}", favoriteColor),
            const SizedBox(height: 12),
            _infoRow(Icons.person, user.gender.isNotEmpty ? user.gender : 'unkown', Colors.pinkAccent),
            const SizedBox(height: 12),

            _infoRow(Icons.public, user.city.isNotEmpty ? user.city : 'unkown', Colors.teal),
            _infoRow(Icons.public, user.country.isNotEmpty ? user.country : 'unkown', Colors.teal),

            const SizedBox(height: 40),

            Text("📈 xpProgress", style: _sectionTitleStyle(favoriteColor)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 800),
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  minHeight: 18,
                  backgroundColor: favoriteColor.withOpacity(0.25),
                  color: favoriteColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "level $level • $xp XP",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: favoriteColor.darken(0.2)),
            ),

            const SizedBox(height: 32),

            _infoRow(Icons.star_rounded, "$stars ${tr.stars}", Colors.amber),
            const SizedBox(height: 12),
            _infoRow(Icons.token, "$tokens Tolim", Colors.green.shade700),

            const SizedBox(height: 40),

            // Reset button
            ElevatedButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: Text('reset'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 5,
              ),
              onPressed: _confirmResetXP,
            ),
          ],
        ),
      ),
    );
  }
}

extension ColorBrightness on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
