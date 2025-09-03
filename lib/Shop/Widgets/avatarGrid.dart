import 'package:flutter/material.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import '../../XpSystem.dart';
import '../../main.dart';
import '../Tools/UnlockedAnimations/EmojiesUnlockedAnimations.dart';
import 'avatarItems.dart';

class AvatarGrid extends StatelessWidget {
  final List<Map<String, dynamic>> avatarItems;
  const AvatarGrid({required this.avatarItems, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final audioManager = Provider.of<AudioManager>(context,listen: false);
    void showPurchaseDialog(BuildContext parentContext, String emoji, int cost) {
      showDialog(
        context: parentContext,
        builder: (context) => AlertDialog(
          title:  Text(tr(context).confirmPurchase),
          content: Text("${tr(context).doYouWantToUnlockThis} $emoji for $cost ⭐?"),
          actions: [
            TextButton(
              onPressed: () {
                audioManager.playEventSound("cancelButton");
                Navigator.pop(context);
              },
              child:  Text(tr(context).cancel),
            ),
            TextButton(
              onPressed: () async {
                audioManager.playEventSound("clickButton");
                Navigator.pop(context); // Close the purchase dialog
                await Future.delayed(const Duration(milliseconds: 300));

                // Deduct stars & unlock avatar
                xpManager.SpendStarBanner(parentContext, cost);


                // Show the fancy unlocked dialog with Lottie, confetti, sounds
               await   showDialog(
                  context: parentContext,
                  barrierDismissible: false,
                  builder: (_) => EmojiUnlockedDialog(
                    xpReward: 20,
                    emoji: emoji,
                  ),
                );
                xpManager.unlockAvatar(emoji);
                xpManager.selectAvatar(emoji);
              },
              child:  Text(tr(context).pay, style: TextStyle(color: Colors.deepOrange)),
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
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
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
          onBuy: () => showPurchaseDialog(context, emoji, cost),
        );
      },
    );
  }
}
