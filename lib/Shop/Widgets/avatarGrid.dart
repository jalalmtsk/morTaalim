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

    void showPurchaseDialog(BuildContext parentContext, String emoji, int cost) {
      showDialog(
        context: parentContext,
        builder: (context) => AlertDialog(
          title: const Text("Confirm Purchase"),
          content: Text("Do you want to unlock $emoji for $cost ⭐?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async{
                Navigator.pop(context);
                await Future.delayed(Duration(milliseconds: 300));
                xpManager.addXP(20, context: parentContext);
                await Future.delayed(Duration(milliseconds: 1800));
                xpManager.SpendStarBanner(parentContext, cost);
                xpManager.unlockAvatar(emoji);
                xpManager.selectAvatar(emoji);
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text('$emoji Unlocked! Enjoy!')),
                );
              },
              child: const Text("Buy", style: TextStyle(color: Colors.deepOrange)),
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
          onBuy: () => showPurchaseDialog(context, emoji, cost), // Pass parent context
        );
      },
    );
  }
}
