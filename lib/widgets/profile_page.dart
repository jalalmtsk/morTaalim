import 'package:flutter/material.dart';
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

  final List<Map<String, dynamic>> badges = [
    {"icon": Icons.emoji_events, "label": "Champion", "color": Colors.orange},
    {"icon": Icons.flash_on, "label": "Quick Learner", "color": Colors.purple},
    {"icon": Icons.star, "label": "Top Scorer", "color": Colors.amber},
    {"icon": Icons.cake, "label": "Anniversary", "color": Colors.pink},
  ];

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
            // Avatar
            ScaleTransition(
              scale: _bounceAnimation,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: favoriteColor.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.white,
                  child: avatar.contains("assets/")
                      ? ClipOval(
                    child: Image.asset(
                      avatar,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Text(
                    avatar,
                    style: const TextStyle(fontSize: 72),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              name,
              style: TextStyle(
                fontFamily: 'ComicNeue',
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: favoriteColor.darken(0.2),
              ),
            ),

            const SizedBox(height: 12),
            Text(
              mood,
              style: const TextStyle(fontSize: 40),
            ),

            const SizedBox(height: 32),

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

            // 🔰 Badge Section
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
        ),
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
        'unlockXp': 0,
      },
      {
        'image': 'assets/images/badges/Badge2.png',
        'label': 'Intermediate',
        'unlockXp': 100,
      },
      {
        'image': 'assets/images/badges/Badge3.png',
        'label': 'Advanced',
        'unlockXp': 250,
      },
      {
        'image': 'assets/images/badges/Badge4.png',
        'label': 'Master',
        'unlockXp': 500,
      },

      {
        'image': 'assets/images/badges/Badge5.png',
        'label': 'Top of the Class',
        'unlockXp': 600,
      },

      {
        'image': 'assets/images/badges/Badge6.png',
        'label': 'Top of the Class',
        'unlockXp': 600,
      },

      {
        'image': 'assets/images/badges/Badge7.png',
        'label': 'Top of the Class',
        'unlockXp': 600,
      },

      {
        'image': 'assets/images/badges/Badge.png',
        'label': 'Never Give Up',
        'unlockXp': 700,
      },
      {
        'image': 'assets/images/badges/Badge3.png',
        'label': 'XP Hero',
        'unlockXp': 800,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("🏅 Badges", style: _sectionTitleStyle(favoriteColor)),
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
