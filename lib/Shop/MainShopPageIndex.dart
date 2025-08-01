import 'package:flutter/material.dart';
import 'package:mortaalim/Shop/BannerTab/IndexBanner.dart';
import 'package:mortaalim/Shop/StarsTab/IndexStars.dart';
import 'package:mortaalim/widgets/SpinWheel/SpinTheWheel.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';

import '../XpSystem.dart';
import '../main.dart';
import '../tools/Ads_Manager.dart';
import '../widgets/RewardChest.dart';
import 'FunMojiTab/IndexFunMoji.dart';

class MainShopPageIndex extends StatelessWidget {
  const MainShopPageIndex({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme(
      primary: const Color(0xFFFF6F3C),
      primaryContainer: const Color(0xFFFFA65C),
      secondary: const Color(0xFF4A90E2),
      surface: Colors.white,
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onError: Colors.white,
      brightness: Brightness.light,
    );

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              // Top bar: back button + user status
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    // Back button with subtle elevation & splash radius
                    Material(
                      shape: const CircleBorder(),
                      elevation: 5,
                      shadowColor: colorScheme.primaryContainer.withValues(alpha: 0.25),
                      color: colorScheme.surface,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: colorScheme.primary, size: 28),
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 26,
                      ),
                    ),

                    const SizedBox(width: 4),

                    const Expanded(child: Userstatutbar()),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // TabBar with smooth rounded indicator & gradient background
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: TabBar(
                    isScrollable: true,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.primaryContainer],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab, // full tab width indicator
                    labelColor: colorScheme.onPrimary,
                    unselectedLabelColor: colorScheme.primary.withValues(alpha: 0.7),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    tabs: [
                      Tab(icon: Icon(Icons.face_2_sharp, size: 22), text: tr(context).funMoji),
                      Tab(icon: Icon(Icons.filter_b_and_w_outlined, size: 22), text: tr(context).banners),
                      Tab(icon: Icon(Icons.token, size: 22), text: tr(context).stars),
                      Tab(icon: Icon(Icons.card_giftcard, size: 22), text: tr(context).spinningWheel),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Main tab content container
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TabBarView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        IndexFunMojiPage(),
                        IndexBanner(),
                        IndexStars(),
                        SingleChildScrollView(child: SpinWheelPopup()),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Reward chests with spacing and shadowed circular backgrounds
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildRewardChest(context, 15, 2, 1, "Quick", colorScheme),
                    _buildRewardChest(context, 30, 5, 2, tr(context).medium, colorScheme),
                    _buildRewardChest(context, 60, 15, 3, "Rare", colorScheme),
                  ],
                ),
              ),

              const SizedBox(height: 2), // Leave space for floating button
            ],
          ),
        ),
    )
    );
  }

  Widget _buildRewardChest(BuildContext context, int cooldownSec, int xpReward,
      int starReward, String label, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [colorScheme.primaryContainer.withValues(alpha: 0.4), colorScheme.primary.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
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
                Provider.of<ExperienceManager>(context, listen: false).addStarBanner(context, starReward);
              } else {
                Provider.of<ExperienceManager>(context, listen: false).addXP(xpReward, context: context);
              }
            },
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.4,
          ),
        ),

      ],
    );
  }
}

// Extension method to add gradient background to ElevatedButton
extension GradientButton on Widget {
  Widget withGradient(Color startColor, Color endColor) {
    return Ink(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: startColor.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: this,
    );
  }
}
