import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/Inside_Course_Logic/HomeCourse_Tools/Widgets/MascotBubble.dart';
import 'package:mortaalim/Inside_Course_Logic/HomeCourse_Tools/Widgets/ProgressCard.dart';
import 'package:mortaalim/widgets/ProfileSetup_Widget/MainProfile_Page/Tools/InfoSchool_card.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../XpSystem.dart';
import 'Widgets/UserDataProfileEntering.dart';
import 'Tools/InfoProfile_card.dart';


// -------------------- Main Profile Page --------------------
class MainProfilePage extends StatefulWidget {
  const MainProfilePage({super.key});

  @override
  State<MainProfilePage> createState() => _MainProfilePageState();
}

class _MainProfilePageState extends State<MainProfilePage> with SingleTickerProviderStateMixin {
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
    const double size = 100;
    if (avatar.endsWith('.json')) return Lottie.asset(avatar, repeat: true, fit: BoxFit.contain);
    if (avatar.startsWith('assets/')) return ClipOval(child: Image.asset(avatar, width: size, height: size, fit: BoxFit.cover));
    return Center(child: Text(avatar, style: const TextStyle(fontSize: 64)));
  }

  String _getAvatarFrameImage(int level) {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("XP and stars reset.")));
    }
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
    final userName = user.fullName.isNotEmpty ? user.fullName : 'Unknown';
    final favoriteColor = Colors.deepPurple;

    return Scaffold(
      backgroundColor: const Color(0xfffff3e0),
      appBar: AppBar(
        title: Text(tr.myProfile, style: const TextStyle(fontFamily: 'ComicNeue', fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserAndSchoolInfoPage ())),
          ),
        ],
        backgroundColor: favoriteColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Banner + Avatar
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    xpManager.selectedBannerImage,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  height: 220,
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
                                child: Image.asset(_getAvatarFrameImage(level), width: 120, height: 120, fit: BoxFit.cover),
                              ),
                              ClipOval(
                                child: Container(width: 110, height: 110, color: Colors.white, child: _buildAvatar(xpManager.selectedAvatar)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(userName,
                            style: const TextStyle(fontFamily: 'ComicNeue', fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, shadows: [
                              Shadow(blurRadius: 3, color: Colors.black),
                            ])),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),




            // -------- User Info Row ----------
            Row(
              children: [
                Expanded(flex : 3,child: ProgressCard(progressPct: 23, progress: 2, xp: xp, badges: 34)),
                const SizedBox(width: 10,),
                Expanded(child: MascotBubble())
              ],
            ),
            const SizedBox(height: 30,),

            Row(
              children: [

                Expanded(flex: 3,
                  child: SwipableSchoolCard (
                    schoolName: user.schoolName.isNotEmpty ? user.schoolName : 'Unknown School',
                    schoolType: user.schoolType.isNotEmpty ? user.schoolType : 'Type Unknown',
                    schoolGrade: user.schoolGrade.isNotEmpty ? user.schoolGrade : 'Grade Unknown',
                    lyceeTrack: user.lyceeTrack.isNotEmpty ? user.lyceeTrack : '',
                  ),
                ),

                Expanded(flex: 2,
                  child: SwipableSchoolCard (
                    schoolName: user.schoolName.isNotEmpty ? user.schoolName : 'Unknown School',
                    schoolType: user.schoolType.isNotEmpty ? user.schoolType : 'Type Unknown',
                    schoolGrade: user.schoolGrade.isNotEmpty ? user.schoolGrade : 'Grade Unknown',
                    lyceeTrack: user.lyceeTrack.isNotEmpty ? user.lyceeTrack : '',
                  ),
                ),
              ],
            ),


            InfoProfileCard(icon: Icons.email, title: user.email.isNotEmpty ? user.email : 'No Email', iconColor: Colors.deepPurple),
            Row(
              children: [
                Expanded(flex :5,child: InfoProfileCard(icon: Icons.person, title: user.gender.isNotEmpty ? user.gender : 'Unknown', iconColor: Colors.pinkAccent)),
                const SizedBox(width: 12),
                Expanded(flex: 4,child: InfoProfileCard(icon: Icons.cake, title: "${user.age} years", iconColor: Colors.orangeAccent)),
              ],
            ),
            Row(
              children: [
                Expanded(flex: 5, child: InfoProfileCard(icon: Icons.public, title: user.country.isNotEmpty ? user.country : 'Unknown', iconColor: Colors.greenAccent)),
                const SizedBox(width: 12),
                Expanded(flex : 4,child: InfoProfileCard(icon: Icons.location_city, title: user.city.isNotEmpty ? user.city : 'Unknown', iconColor: Colors.teal)),
              ],
            ),

            const SizedBox(height: 30),

            // XP Progress
            InfoProfileCard(
              icon: Icons.bar_chart,
              title: "Level $level • $xp XP",
              subtitle: "Progress ${(progress * 100).toStringAsFixed(1)}%",
              iconColor: favoriteColor,
              gradient: LinearGradient(colors: [favoriteColor.withOpacity(0.3), favoriteColor.withOpacity(0.7)]),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 16,
                backgroundColor: favoriteColor.withOpacity(0.25),
                color: favoriteColor,
              ),
            ),

            const SizedBox(height: 20),

            // Stars & Tokens Row
            Row(
              children: [
                Expanded(
                  child: InfoProfileCard(
                    icon: Icons.star_rounded,
                    title: "$stars Stars",
                    iconColor: Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InfoProfileCard(
                    icon: Icons.token,
                    title: "$tokens Tokens",
                    iconColor: Colors.green.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Reset XP Button
            ElevatedButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset XP'),
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
