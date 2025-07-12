import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../XpSystem.dart';

class ProfilePage extends StatefulWidget {
  final String initialName;
  final String initialAvatar;
  final int initialAge;
  final Color initialColor;
  final String initialMood;

  const ProfilePage({
    super.key,
    required this.initialName,
    required this.initialAvatar,
    required this.initialAge,
    required this.initialColor,
    required this.initialMood,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late String name;
  late String avatar;
  late int age;
  late Color favoriteColor;
  late String mood;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;


  @override
  void initState() {
    super.initState();
    name = widget.initialName;
    avatar = widget.initialAvatar;
    age = widget.initialAge;
    favoriteColor = widget.initialColor;
    mood = widget.initialMood;

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  Widget _buildAvatar(String avatarPath) {
    const double size = 80;

    Widget avatarContent;

    if (avatarPath.endsWith('.json')) {
      avatarContent = Lottie.asset(
        avatarPath,
        repeat: true,
        fit: BoxFit.contain,
      );
    } else if (avatarPath.contains('assets/')) {
      avatarContent = Image.asset(
        avatarPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else {
      avatarContent = Center(
        child: Text(
          avatarPath,
          style: const TextStyle(fontSize: 64),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.pink.shade100,
            Colors.white,
          ],
          center: Alignment.topLeft,
          radius: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withOpacity(0.3),
            blurRadius: 18,
            spreadRadius: 4,
          ),
        ],
        border: Border.all(
          color: Colors.pink.shade200,
          width: 3,
        ),
      ),
      child: ClipOval(
        child: Container(
          width: size,
          height: size,
          child: avatarContent,
        ),
      ),
    );
  }

  BoxDecoration avatarBorderDecorationByLevel(int level) {
    Color borderColor;

    if (level >= 30) {
      borderColor = Colors.deepPurpleAccent;
    } else if (level >= 20) {
      borderColor = Colors.teal;
    } else if (level >= 10) {
      borderColor = Colors.indigoAccent;
    } else if (level >= 5) {
      borderColor = Colors.orangeAccent;
    } else {
      borderColor = Colors.grey;
    }
    return BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: borderColor, width: 4),
      boxShadow: [
        BoxShadow(
          color: borderColor.withOpacity(0.5),
          blurRadius: 10,
          spreadRadius: 2,
        ),
      ],
    );
  }

  /// RING FRAME IMAGE
  String _getAvatarFrameImage(int level) {
    if (level >= 50) return 'assets/images/Banners/Islamic/Islamic7.png';
    if (level >= 35) return 'assets/images/Banners/Islamic/Islamic6.png';
    if (level >= 25) return 'assets/images/Banners/Islamic/Islamic5.png';
    if (level >= 15) return 'assets/images/Banners/Islamic/Islamic4.png';
    if (level >= 7) return 'assets/images/Banners/Islamic/Islamic3.png';
    if (level >= 5) return 'assets/images/Banners/Islamic/Islamic2.png';
    return 'assets/images/Banners/Islamic/Islamic1.png';
  }




  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _changeAge(int delta) {
    setState(() {
      age = (age + delta).clamp(1, 120);
    });
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

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final tr = AppLocalizations.of(context)!;
    final level = xpManager.level;
    final progress = xpManager.levelProgress;
    final xp = xpManager.xp;
    final stars = xpManager.stars;
    final saveTokens = xpManager.saveTokenCount;

    return Scaffold(
      backgroundColor: const Color(0xfffff3e0),
      appBar: AppBar(
        title: Text(
          tr.myProfile,
          style: const TextStyle(fontFamily: 'ComicNeue', fontWeight: FontWeight.bold),
        ),
        backgroundColor: favoriteColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🏞️ Banner Header with Avatar, Name, Mood
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
                    color: Colors.black.withOpacity(0.2),
                  ),
                ),
                Positioned.fill(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _bounceAnimation,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipOval(
                                child: Container(
                                  child: Image.asset(
                                    _getAvatarFrameImage(level), // ⬅️ Your level-based frame
                                    width: 115,
                                    height: 115,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              ClipOval(
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  child: _buildAvatar(avatar),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'ComicNeue',
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Age
            Text("🎂 ${tr.age}", style: _sectionTitleStyle(favoriteColor)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 36,
                  icon: Icon(Icons.remove_circle, color: favoriteColor),
                  onPressed: () => _changeAge(-1),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: favoriteColor.withOpacity(0.1),
                  ),
                  child: Text(
                    "$age",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: favoriteColor,
                    ),
                  ),
                ),
                IconButton(
                  iconSize: 36,
                  icon: Icon(Icons.add_circle, color: favoriteColor),
                  onPressed: () => _changeAge(1),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // XP Progress
            Text("📈 XP Progress", style: _sectionTitleStyle(favoriteColor)),
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
              "Level $level • $xp XP",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: favoriteColor.darken(0.2)),
            ),

            const SizedBox(height: 32),

            // Stats
            _infoRow(Icons.star_rounded, "$stars Stars", Colors.amber),
            const SizedBox(height: 12),
            _infoRow(Icons.generating_tokens, "$saveTokens Tolim", Colors.green.shade700),

            const SizedBox(height: 40),

            _buildBadgesSection(),

            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: _confirmResetXP,
              icon: const Icon(Icons.restart_alt),
              label: const Text("Reset XP & Stars"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 5,
              ),
            ),
          ],
        )

      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 36),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildBadgesSection() {
    final xp = Provider.of<ExperienceManager>(context).xp;

    final List<Map<String, dynamic>> badgeData = [
      {
        'image': 'assets/images/badges/Badge1.png',
        'label': 'First Steps',
        'unlockXp': 100,
      },
      {
        'image': 'assets/images/badges/Badge2.png',
        'label': 'Intermediate',
        'unlockXp': 200,
      },
      {
        'image': 'assets/images/badges/Badge3.png',
        'label': 'Advanced',
        'unlockXp': 350,
      },
      {
        'image': 'assets/images/badges/Badge4.png',
        'label': 'Master',
        'unlockXp': 500,
      },

      {
        'image': 'assets/images/badges/Badge5.png',
        'label': 'Top of the Class',
        'unlockXp': 750,
      },

      {
        'image': 'assets/images/badges/Badge6.png',
        'label': 'Top of the Class',
        'unlockXp': 1050,
      },

      {
        'image': 'assets/images/badges/Badge7.png',
        'label': 'Top of the Class',
        'unlockXp': 1800,
      },

      {
        'image': 'assets/images/badges/Badge9.png',
        'label': 'Never Give Up',
        'unlockXp': 2900,
      },
      {
        'image': 'assets/images/badges/Badge10.png',
        'label': 'XP Hero',
        'unlockXp': 4000,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("🏅Badges", style: _sectionTitleStyle(favoriteColor)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 20,
          children: badgeData.map((badge) {
            final bool isUnlocked = xp >= badge['unlockXp'];
            final int unlockLevel = (badge['unlockXp'] / 100).ceil(); // adjust XP-to-level ratio if needed

            return SizedBox(
              width: 80,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: isUnlocked ? favoriteColor.withOpacity(0.3) : Colors.grey.shade300,
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: ClipOval(
                          child: Image.asset(
                            badge['image'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            color: isUnlocked ? null : Colors.grey.shade400,
                            colorBlendMode: isUnlocked ? null : BlendMode.saturation,
                          ),
                        ),
                      ),
                      if (!isUnlocked)
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          child: Icon(Icons.lock, size: 16, color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    badge['label'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isUnlocked ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  if (!isUnlocked)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Unlock at LvL$unlockLevel",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  TextStyle _sectionTitleStyle(Color baseColor) {
    return TextStyle(
      fontSize: 24,
      fontFamily: 'ComicNeue',
      fontWeight: FontWeight.bold,
      color: baseColor.darken(0.15),
    );
  }
}

extension ColorUtils on Color {
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
