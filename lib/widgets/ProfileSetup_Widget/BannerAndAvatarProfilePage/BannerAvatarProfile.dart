import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/ProfileSetup_Widget/BannerAndAvatarProfilePage/Tools/BannerAvatarStatusBar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../XpSystem.dart';
import '../../../main.dart';
import 'Tools/AvatarSelection.dart';
import 'Tools/BAckgroundColor.dart';
import 'Tools/BannerSelection.dart';
import 'Tools/FancyFields.dart';
import 'Tools/Frosted.dart';
import 'Tools/SelectionHeader.dart';

class BannerAvatarProfile extends StatefulWidget {
  const BannerAvatarProfile({super.key});

  @override
  State<BannerAvatarProfile> createState() => _BannerAvatarProfileState();
}

class _BannerAvatarProfileState extends State<BannerAvatarProfile>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  late final AnimationController _bgController;
  late final AnimationController _pulseController;

  late final PageController _bannerPage;
  late final PageController _avatarPage;

  @override
  void initState() {
    super.initState();
    _loadProfile();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);

    _bannerPage = PageController(viewportFraction: 0.84);
    _avatarPage = PageController(viewportFraction: 0.34);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pulseController.dispose();
    _bannerPage.dispose();
    _avatarPage.dispose();
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

    if (!_formKey.currentState!.validate()) {
      _showError("tr(context).pleaseCheckFields");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    await prefs.setString('username', username);
    await prefs.setString('email', email);

    xpManager.setFullName(name);
    xpManager.setLastName(username);
    xpManager.setEmail(email);

    if (mounted) {
      _showSuccess();
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playEventSound('invalid');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade600,
        content: Row(
          children: [
            ScaleTransition(
              scale: _pulseController,
              child: const Icon(Icons.check_circle, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(tr(context).profileSaved,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Animated blob gradient background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return CustomPaint(
                painter: BlobBackgroundPainter(progress: _bgController.value),
                child: const SizedBox.expand(),
              );
            },
          ),

          // Glass content with slivers
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                automaticallyImplyLeading: false, // <-- Remove back arrow
                pinned: true,
                floating: false,
                elevation: 0,
                backgroundColor: Colors.transparent,
                expandedHeight: 180,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                      padding: EdgeInsets.only(top: 20, right: 10, left: 10),
                      child: BannerAvatarStatusBar()),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 2, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: tr(context).chooseYourBanner,
                        icon: Icons.wallpaper,
                      ),
                      const SizedBox(height: 6),
                      BannerCarousel(
                        pageController: _bannerPage,
                        items: xpManager.unlockedBanners,
                        selected: xpManager.selectedBannerImage,
                        onTap: (banner) {
                          audioManager.playEventSound('clickButton2');
                          xpManager.selectBannerImage(banner);
                        },
                      ),
                      SectionHeader(
                        title: tr(context).chooseYourAvatar,
                        icon: Icons.emoji_emotions_outlined,
                      ),
                      const SizedBox(height: 4),
                      AvatarCarousel(
                        pageController: _avatarPage,
                        items: xpManager.unlockedAvatars,
                        selected: xpManager.selectedAvatar,
                        onTap: (avatar) {
                          audioManager.playEventSound('clickButton2');
                          xpManager.selectAvatar(avatar);
                        },
                      ),
                      const SizedBox(height: 12),

                      SectionHeader(
                        title: tr(context).profileInfo,
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 10),

                      Frosted(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              FancyField(
                                controller: _nameController,
                                label: "${tr(context).name} **",
                                icon: Icons.person,
                                validator: (v) {
                                  final s = (v ?? '').trim();
                                  if (s.isEmpty || s.length > 12) {
                                    return tr(context).nameRule; // "Name must be between 1 and 12 characters"
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              FancyField(
                                controller: _usernameController,
                                label: "${tr(context).lastName} **",
                                icon: Icons.nest_cam_wired_stand,
                                validator: (v) {
                                  final s = (v ?? '').trim();
                                  if (s.isEmpty || s.length > 15) {
                                    return tr(context).lastName; // "LastName must be between 1 and 15 characters"
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              FancyField(
                                controller: _emailController,
                                label: tr(context).email,
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  final s = (v ?? '').trim();
                                  if (s.isEmpty) return null; // optional
                                  final ok = RegExp(r'^.+@.+\..+\$').hasMatch(s);
                                  if (!ok) return tr(context).invalidEmail;
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 80), // space for CTA
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom sticky Save CTA
          Positioned(
            left: 16,
            right: 16,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
            child: Frosted(
              radius: 28,
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(Icons.tips_and_updates_outlined, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr(context).readyToSave,
                        maxLines: 2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ElevatedButton.icon(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellowAccent.shade700,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 8,
                        ),
                        icon: const Icon(Icons.save),
                        label: Text(
                          tr(context).save,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
