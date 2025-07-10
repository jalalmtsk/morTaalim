import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';
import 'avatarItems.dart';

class AvatarGrid extends StatelessWidget {
  final List<Map<String, dynamic>> avatarItems;

  const AvatarGrid({required this.avatarItems, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);

    void showPurchaseDialog(String emoji, int cost) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirm Purchase"),
          content: Text("Do you want to unlock $emoji for $cost ⭐?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                xpManager.addStars(-cost);
                xpManager.unlockAvatar(emoji);
                xpManager.selectAvatar(emoji);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$emoji Unlocked! Enjoy!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.deepOrangeAccent,
                  ),
                );
              },
              child: const Text(
                "Buy",
                style: TextStyle(color: Colors.deepOrange),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: avatarItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, index) {
        final item = avatarItems[index];
        final emoji = item['emoji'];
        final cost = item['cost'];
        final unlocked = xpManager.unlockedAvatars.contains(emoji);
        final selected = xpManager.selectedAvatar == emoji;

        return AvatarItemWidget(
          emoji: emoji,
          cost: cost,
          unlocked: unlocked,
          selected: selected,
          userStars: xpManager.stars,
          onSelect: () => xpManager.selectAvatar(emoji),
          onBuy: () => showPurchaseDialog(emoji, cost),
        );
      },
    );
  }
}
