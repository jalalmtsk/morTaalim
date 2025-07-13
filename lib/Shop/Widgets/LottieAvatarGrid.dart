import 'package:flutter/material.dart';
import 'package:mortaalim/Shop/Widgets/LottieAvatarWidget.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';

class LottieAvatarGrid extends StatelessWidget {
  final List<Map<String, dynamic>> lottieAvatars;

  const LottieAvatarGrid({required this.lottieAvatars, super.key});

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);

    void showPurchaseDialog(String lottiePath, int cost) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirm Purchase"),
          content: Text("Do you want to unlock this avatar for $cost ⭐?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                xpManager.addXP(1000,context: context);
                xpManager.addStars(-cost);
                xpManager.unlockAvatar(lottiePath);
                xpManager.selectAvatar(lottiePath);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
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
      itemCount: lottieAvatars.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, index) {
        final item = lottieAvatars[index];
        final lottiePath = item['lottie'];
        final cost = item['cost'];
        final unlocked = xpManager.unlockedAvatars.contains(lottiePath);
        final selected = xpManager.selectedAvatar == lottiePath;

        return LottieAvatarItemWidget(
          lottiePath: lottiePath,
          cost: cost,
          unlocked: unlocked,
          selected: selected,
          userStars: xpManager.stars,
          onSelect: () => xpManager.selectAvatar(lottiePath),
          onBuy: () => showPurchaseDialog(lottiePath, cost),
        );
      },
    );
  }
}
