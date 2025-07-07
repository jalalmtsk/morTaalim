import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import 'XpSystem.dart';

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
    final saveTokens = xpManager.saveTokens;

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: Text(
          tr.myProfile,
          style: TextStyle(
            fontFamily: 'ComicNeue',
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: favoriteColor,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Bouncing avatar with glow
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
                  child: Text(
                    avatar,
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Name text big and bold
            Text(
              name,
              style: TextStyle(
                fontFamily: 'ComicNeue',
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: favoriteColor,
              ),
            ),

            const SizedBox(height: 12),

            // Mood display (non-editable)
            Text(
              mood,
              style: const TextStyle(fontSize: 48),
            ),

            const SizedBox(height: 28),

            // Age selector with simple buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tr.age,
                  style: TextStyle(
                    fontFamily: 'ComicNeue',
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: favoriteColor,
                  ),
                ),
                const SizedBox(width: 20),
                IconButton(
                  iconSize: 36,
                  onPressed: () => _changeAge(-1),
                  icon: Icon(Icons.remove_circle, color: favoriteColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: favoriteColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$age",
                    style: TextStyle(
                      fontFamily: 'ComicNeue',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: favoriteColor.darken(0.3),
                    ),
                  ),
                ),
                IconButton(
                  iconSize: 36,
                  onPressed: () => _changeAge(1),
                  icon: Icon(Icons.add_circle, color: favoriteColor),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // XP Progress bar with animation
            Text(
              "🎮 XP Progress",
              style: TextStyle(
                fontFamily: 'ComicNeue',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: favoriteColor,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) => LinearProgressIndicator(
                  value: value,
                  minHeight: 20,
                  backgroundColor: favoriteColor.withOpacity(0.25),
                  color: favoriteColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Level $level • $xp XP",
              style: TextStyle(
                fontFamily: 'ComicNeue',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: favoriteColor.darken(0.1),
              ),
            ),

            const SizedBox(height: 28),

            // Stars count with icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 36),
                const SizedBox(width: 16),
                Text(
                  "$stars Stars",
                  style: TextStyle(
                    fontFamily: 'ComicNeue',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Save tokens count with icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.generating_tokens_sharp, color: Colors.green.shade700, size: 36),
                const SizedBox(width: 16),
                Text(
                  "$saveTokens Tolim",
                  style: TextStyle(
                    fontFamily: 'ComicNeue',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            ElevatedButton.icon(
              onPressed: _confirmResetXP,
              icon: const Icon(Icons.restart_alt),
              label: Text(
                "Reset XP & Stars",
                style: TextStyle(
                  fontFamily: 'ComicNeue',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
}

extension ColorUtils on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
