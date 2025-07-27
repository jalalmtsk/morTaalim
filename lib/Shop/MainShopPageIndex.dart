import 'package:flutter/material.dart';
import 'package:mortaalim/Shop/BannerTab/IndexBanner.dart';
import 'package:mortaalim/Shop/StarsTab/IndexStars.dart';
import 'package:mortaalim/Shop/Tools/watchAdButton.dart';
import 'package:mortaalim/widgets/SpinWheel/SpinTheWheel.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';

import '../XpSystem.dart';
import '../tools/Ads_Manager.dart';
import '../widgets/RewardChest.dart';
import 'FunMojiTab/IndexFunMoji.dart';
import 'Tools/_StarCounter.dart';
import 'Tools/_TokenAndSection.dart';


class MainShopPageIndex extends StatelessWidget {
  const MainShopPageIndex({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // 5 tabs
      child: Scaffold(
        backgroundColor: const Color(0xFFff9966),
        body: SafeArea(
          child: Column(
            children: [
              const Userstatutbar(),
              const SizedBox(height: 6),

              // Top Row: Back + Spacer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(14),
                        minimumSize: const Size(50, 50),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),

                    Row(children: [
                      RewardChest(
                        cooldown: Duration(seconds: 5),
                        chestClosedAsset: 'assets/images/UI/utilities/Box.png',
                        chestOpenAnimationAsset: 'assets/animations/LvlUnlocked/BoxQuest.json',
                        rareChestClosedAsset: 'assets/images/UI/utilities/Box.png',
                        rareChestOpenAnimationAsset: 'assets/animations/LvlUnlocked/BoxQuest.json',
                        onRewardCollected: ({required bool isRare}) {
                          if (isRare) {
                            // Give bigger reward
                            Provider.of<ExperienceManager>(context, listen: false).addTokenBanner(context, 1);
                          } else {
                            // Normal reward
                            Provider.of<ExperienceManager>(context, listen: false).addXP(2, context: context);
                          }
                        },
                      ),
                      RewardChest(
                        cooldown: Duration(hours: 24),
                        chestClosedAsset: 'assets/images/UI/utilities/Box.png',
                        chestOpenAnimationAsset: 'assets/animations/LvlUnlocked/BoxQuest.json',
                        rareChestClosedAsset: 'assets/images/UI/utilities/Box.png',
                        rareChestOpenAnimationAsset: 'assets/animations/LvlUnlocked/BoxQuest.json',
                        onRewardCollected: ({required bool isRare}) {
                          if (isRare) {
                            // Give bigger reward
                            Provider.of<ExperienceManager>(context, listen: false).addStarBanner(context, 2);
                          } else {
                            // Normal reward
                            Provider.of<ExperienceManager>(context, listen: false).addXP(10, context: context);
                          }
                        },
                      ),

                      const SizedBox(width: 20,),

                    ],)

                  ],
                ),
              ),

              const SizedBox(height: 5),

              // Tabs bar container
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFff9966), Color(0xFFff5e62)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: TabBar(
                  isScrollable: true,
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(icon: Icon(Icons.face_2_sharp), text: "FunMoji"),
                    Tab(icon: Icon(Icons.filter_b_and_w_outlined), text: "Banner"),
                    Tab(icon: Icon(Icons.token), text: "Stars/Tolims"),
                    Tab(icon: Icon(Icons.card_giftcard), text: "Specials"),
                    Tab(icon: Icon(Icons.info_outline), text: "Info"),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  children: [
                    IndexFunMojiPage(),
                    IndexBanner(),
                    IndexStars(),
                    SingleChildScrollView(child: SpinWheelPopup()),
                    const Center(child: Text("ℹ️ Information", style: TextStyle(fontSize: 18))),
                  ],
                ),
              ),

              // Rewarded Ad Button fixed at bottom with emphasis
              Container(
                color: Color(0xFFff9966),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                child: GestureDetector(
                  onTap: () => AdHelper.showRewardedAdWithLoading(context, (){
                    Provider.of<ExperienceManager>(context, listen: false).addStarBanner(context,1);
                  }),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated icon or badge
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 1.2),
                        duration: const Duration(seconds: 1),
                        curve: Curves.easeInOut,
                        builder: (context, scale, child) => Transform.scale(
                          scale: scale,
                          child: child,
                        ),
                        onEnd: () => null,
                        child: const Icon(Icons.ads_click_outlined, color: Colors.white, size: 32),
                      ),

                      const SizedBox(width: 10),

                      const Text(
                        'Watch Ad → Earn 🌟!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(1, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
