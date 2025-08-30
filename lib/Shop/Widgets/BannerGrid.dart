import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../ManagerTools/StarDeductionOverlay.dart';
import '../../XpSystem.dart';
import '../../ManagerTools/StarCountPulse.dart';
import '../../widgets/userStatutBar.dart';
import '../Tools/UnlockedAnimations/BannerUnlockedAnimation.dart';

class ImageBannerGrid extends StatefulWidget {
  final List<Map<String, dynamic>> banners;

  const ImageBannerGrid({super.key, required this.banners});

  @override
  State<ImageBannerGrid> createState() => _ImageBannerGridState();
}


class _ImageBannerGridState extends State<ImageBannerGrid>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  final GlobalKey starIconKey = GlobalKey();

  int? selectedIndex;
  int? recentlyUnlockedIndex;
  bool showSparkle = false;

  // Flip animation state
  int? flippingIndex;
  late AnimationController _flipController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _flipController.dispose();
    super.dispose();
  }


  void showPurchaseDialog(BuildContext context, String path, int cost,
      ExperienceManager xpManager, int index) {
    final audiManager = Provider.of<AudioManager>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:  Text(tr(context).unlockBanner),
        content: Text("${tr(context).unlockThis} ${tr(context).banner} ${tr(context).forb} $cost ⭐?"),
        actions: [
          TextButton(
            onPressed: () {
              audiManager.playEventSound("cancelButton");
              Navigator.pop(context);
            },
            child:  Text(tr(context).cancel),
          ),
          TextButton(
            onPressed: () async {
              audiManager.playEventSound("clickButton");
              Navigator.pop(context);

              // Deduct stars
              xpManager.SpendStarBanner(context, cost);

              // Unlock & select the banner
              xpManager.unlockBanner(path);
              xpManager.selectBannerImage(path);

              // Sync or save state if needed
              await xpManager.syncWithFirebaseIfOnline();

              // Show the unlock dialog with animation
              if (!mounted) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => BannerUnlockedDialog(
                  bannerImage: path,
                  xpReward: 25,
                ),
              );

              // Update the grid state for glow/scale effect
              setState(() {
                selectedIndex = index;
                recentlyUnlockedIndex = index;
                showSparkle = true;
              });

              Future.delayed(const Duration(milliseconds: 1200), () {
                if (mounted) setState(() => showSparkle = false);
              });

              Future.delayed(const Duration(milliseconds: 700), () {
                if (mounted) setState(() => recentlyUnlockedIndex = null);
              });
            },
            child:  Text(tr(context).unlock),
          ),
        ],
      ),
    );
  }


  Widget _rarityBox(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor,
          fontSize: 11,
          letterSpacing: 0.6,
          shadows: const [
            Shadow(
              color: Colors.black26,
              offset: Offset(0.5, 0.5),
              blurRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRarityLabel(String rarity) {
    switch (rarity.toUpperCase()) {
      case "RARE":
        return _rarityBox(rarity.toUpperCase(), Colors.blue.shade600, Colors.white);
      case "LEGENDARY":
        return Shimmer.fromColors(
          baseColor: Colors.amber.shade600,
          highlightColor: Colors.yellow.shade400,
          child: _rarityBox(rarity.toUpperCase(), Colors.black.withOpacity(0.7), Colors.amberAccent),
        );
      case "COMMON":
      default:
        return _rarityBox(rarity.toUpperCase(), Colors.grey.shade700, Colors.white70);
    }
  }

  Widget _buildBannerContainer(String path, bool selected, bool unlocked, String rarity) {
    final borderColor = selected
        ? Colors.greenAccent.shade400
        : unlocked
        ? Colors.deepOrange.shade400
        : Colors.grey.shade400;

    final glowColor = selected ? Colors.greenAccent.withOpacity(0.7) : Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: selected ? 5 : 3),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: glowColor,
              blurRadius: 12,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 3),
            blurRadius: 6,
          ),
        ],
        image: DecorationImage(
          image: AssetImage(path),
          fit: BoxFit.cover,
          colorFilter: !unlocked
              ? ColorFilter.mode(Colors.black.withOpacity(0.15), BlendMode.darken)
              : null,
        ),
      ),
      foregroundDecoration: !unlocked
          ? BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      )
          : null,
    );
  }

  Widget _buildStarCostBadge(int cost) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            offset: const Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.white, size: 18, shadows: [
            Shadow(color: Colors.black38, offset: Offset(1, 1), blurRadius: 1)
          ]),
          const SizedBox(width: 6),
          Text(
            "$cost",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.black38, offset: Offset(1, 1), blurRadius: 1)
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.banners.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (_, index) {
        final banner = widget.banners[index];
        final path = banner['image'];
        final cost = banner['cost'];
        final rarity = banner['rarity'] ?? "COMMON";
        final unlocked = xpManager.unlockedBanners.contains(path);
        final selected = xpManager.selectedBannerImage == path;

        // If this banner is flipping, show the flip animation
        if (flippingIndex == index) {
          return AnimatedBuilder(
            animation: _flipController,
            builder: (context, child) {
              final angle = _flipController.value * pi; // 0 -> pi

              bool isFront = angle <= pi / 2;

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: isFront
                    ? _buildBannerContainer(path, selected, false, rarity) // locked front
                    : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: _buildBannerContainer(path, selected, true, rarity), // unlocked back
                ),
              );
            },
          );
        }

        return GestureDetector(
          onTap: () {
            if (unlocked) {
              audioManager.playEventSound("clickButton2");
              xpManager.selectBannerImage(path);
              setState(() => selectedIndex = index);
            } else if (xpManager.stars >= cost) {
              audioManager.playEventSound("PopButton");
              showPurchaseDialog(context, path, cost, xpManager, index);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Not enough stars!")),
              );
              audioManager.playEventSound("invalid");
            }
          },
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 1.0,
              end: recentlyUnlockedIndex == index ? 1.07 : 1.0,
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Stack(
                  children: [
                    _buildBannerContainer(path, selected, unlocked, rarity),

                    if (!unlocked)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: _buildStarCostBadge(cost),
                      ),

                    Positioned(
                      top: 10,
                      left: 10,
                      child: _buildRarityLabel(rarity),
                    ),

                    if (unlocked)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Icon(
                          Icons.check_circle,
                          color: selected
                              ? Colors.greenAccent.shade400
                              : Colors.deepOrangeAccent,
                          size: 28,
                          shadows: const [
                            Shadow(
                              color: Colors.black45,
                              offset: Offset(1, 1),
                              blurRadius: 3,
                            )
                          ],
                        ),
                      ),

                    if (recentlyUnlockedIndex == index && showSparkle)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: Lottie.asset(
                              'assets/animations/LvlUnlocked/StarSpark.json',
                              repeat: false,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
