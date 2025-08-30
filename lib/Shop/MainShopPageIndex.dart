import 'package:flutter/material.dart';
import 'package:mortaalim/Shop/BannerTab/IndexBanner.dart';
import 'package:mortaalim/Shop/StarsTab/IndexStars.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/SpinWheel/SpinTheWheel.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import '../XpSystem.dart';
import '../main.dart';
import '../tools/Ads_Manager.dart';
import '../widgets/RewardChest.dart';
import 'FunMojiTab/IndexFunMoji.dart';

class MainShopPageIndex extends StatefulWidget {
  const MainShopPageIndex({super.key});

  @override
  State<MainShopPageIndex> createState() => _MainShopPageIndexState();
}

class _MainShopPageIndexState extends State<MainShopPageIndex>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _playClickSound();
      }
    });
  }

  Future<void> _playClickSound() async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    await audioManager.playEventSound("clickButton");
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    final theme = Theme.of(context);

    final ColorScheme colorScheme = theme.colorScheme.copyWith(
      primary: const Color(0xFFFF6F3C),
      primaryContainer: const Color(0xFFFFA65C),
      secondary: const Color(0xFF4A90E2),
      surface: Colors.white,
      onSurface: Colors.black87,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  _circularButton(
                    icon: Icons.arrow_back,
                    onTap: () {
                     audioManager.playEventSound("cancelButton");
                      Navigator.pop(context);
                    },
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: Userstatutbar()),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // TabBar container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.primaryContainer],
                    ),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: colorScheme.primary.withOpacity(0.7),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  tabs: [
                    Tab(icon: Icon(Icons.card_giftcard), text: tr(context).spinningWheel),
                    Tab(icon: Icon(Icons.face_2_sharp), text: tr(context).funMoji),
                    Tab(icon: Icon(Icons.filter_b_and_w_outlined), text: tr(context).banners),
                    Tab(icon: Icon(Icons.token), text: tr(context).stars),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _animatedTab(SingleChildScrollView(child: SpinWheelPopup())),
                        _animatedTab(IndexFunMojiPage()),
                        _animatedTab(IndexBanner()),
                        _animatedTab(IndexStars()),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Reward chests row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _rewardCard(context, 15, 2, 1, tr(context).quick, colorScheme),
                  _rewardCard(context, 30, 5, 2, tr(context).medium, colorScheme),
                  _rewardCard(context, 60, 15, 3, tr(context).rare, colorScheme),
                ],
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // Animated tab wrapper
  Widget _animatedTab(Widget child) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.95, end: 1),
      curve: Curves.easeOut,
      builder: (context, scale, _) => Transform.scale(scale: scale, child: child),
    );
  }

  // Reward chest card
  Widget _rewardCard(BuildContext context, int cooldownSec, int xpReward,
      int starReward, String label, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {}, // Optional chest tap interaction
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.5),
                  colorScheme.primary.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: RewardChest(
              cooldown: Duration(minutes: cooldownSec),
              chestClosedAsset: 'assets/images/UI/utilities/Box.png',
              chestOpenAnimationAsset: 'assets/animations/LvlUnlocked/BoxQuest.json',
              rareChestClosedAsset: 'assets/images/UI/utilities/Box.png',
              rareChestOpenAnimationAsset: 'assets/animations/LvlUnlocked/BoxQuest.json',
              onRewardCollected: ({required bool isRare}) {
                if (isRare) {
                  Provider.of<ExperienceManager>(context, listen: false)
                      .addStarBanner(context, starReward);
                } else {
                  Provider.of<ExperienceManager>(context, listen: false)
                      .addXP(xpReward, context: context);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // Circular button helper
  Widget _circularButton({required IconData icon, required VoidCallback onTap, required Color color}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 24, color: color),
        ),
      ),
    );
  }
}
