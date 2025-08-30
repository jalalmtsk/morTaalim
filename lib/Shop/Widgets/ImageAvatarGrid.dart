import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../XpSystem.dart';
import '../../main.dart';
import '../../tools/audio_tool/Audio_Manager.dart';
import '../Tools/UnlockedAnimations/AvatarImageUnlockedAnimationBanner.dart';
import 'ImageAvatarWidget.dart';

class ImageAvatarGrid extends StatelessWidget {
  final List<Map<String, dynamic>> imageAvatars;

  const ImageAvatarGrid({required this.imageAvatars, super.key});

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    void showPurchaseDialog(BuildContext parentContext, String imagePath, int cost) {
      showDialog(
        context: parentContext,
        builder: (context) => AlertDialog(
          title:  Text(tr(context).confirmPurchase),
          content: Text("${tr(context).doYouWantToUnlockThis} ${tr(context).avatar} ${tr(context).forb} $cost ⭐?"),
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
                Navigator.pop(context); // close dialog first

                // Spend stars
                xpManager.SpendStarBanner(parentContext, cost);

                // Play sound effects
                audioManager.playSfx("assets/audios/UI_Audio/SFX_Audio/MarimbaWin_SFX.mp3");
                audioManager.playSfx("assets/audios/UI_Audio/SFX_Audio/victory1_SFX.mp3");

                await Future.delayed(const Duration(milliseconds: 500));

                // Unlock and select avatar
                // Show animated Avatar Unlocked dialog
               await  showDialog(
                  context: parentContext,
                  barrierDismissible: true,
                  builder: (_) => AvatarUnlockedDialog(
                    avatarImage: imagePath,
                    xpReward: 20,
                  ),
                );
                xpManager.unlockAvatar(imagePath);
                xpManager.selectAvatar(imagePath);

              },
              child:  Text(tr(context).pay, style: TextStyle(color: Colors.deepOrange)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
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
          onBuy: () => showPurchaseDialog(context, imagePath, cost),
        );
      },
    );
  }
}
