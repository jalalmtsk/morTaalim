import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';
import 'ImageAvatarWidget.dart';

class ImageAvatarGrid extends StatelessWidget {
  final List<Map<String, dynamic>> imageAvatars;

  const ImageAvatarGrid({required this.imageAvatars, super.key});

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);

    void showPurchaseDialog(BuildContext parentContext, String imagePath, int cost) {
      showDialog(
        context: parentContext,
        builder: (context) => AlertDialog(
          title: const Text("Confirm Purchase"),
          content: Text("Do you want to unlock this avatar for $cost ⭐?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // close dialog first
                xpManager.addXP(20, context: parentContext);

                await Future.delayed(const Duration(milliseconds: 1500));

                xpManager.SpendStarBanner(parentContext, -cost);
                xpManager.unlockAvatar(imagePath);
                xpManager.selectAvatar(imagePath);

                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(
                    content: Text('Avatar Unlocked! Enjoy!'),
                    backgroundColor: Colors.deepOrange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text("Buy", style: TextStyle(color: Colors.deepOrange)),
            ),
          ],
        ),
      );
    }


    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: imageAvatars.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, index) {
        final item = imageAvatars[index];
        final imagePath = item['image'];
        final cost = item['cost'];
        final unlocked = xpManager.unlockedAvatars.contains(imagePath);
        final selected = xpManager.selectedAvatar == imagePath;

        return ImageAvatarItemWidget(
          imagePath: imagePath,
          cost: cost,
          unlocked: unlocked,
          selected: selected,
          userStars: xpManager.stars,
          onSelect: () => xpManager.selectAvatar(imagePath),
          onBuy: () => showPurchaseDialog(context ,imagePath, cost),
        );
      },
    );
  }
}
