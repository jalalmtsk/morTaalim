import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';

class ImageBannerGrid extends StatelessWidget {
  final List<Map<String, dynamic>> banners;

  const ImageBannerGrid({super.key, required this.banners});

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);

    void showPurchaseDialog(String path, int cost) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Unlock Banner"),
          content: Text("Unlock this banner for $cost ⭐?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async{
                Navigator.pop(context);
                xpManager.addXP(25,context: context);
                await Future.delayed(Duration(seconds: 1));
                xpManager.SpendStarBanner(context, -cost);
                xpManager.unlockBanner(path);
                xpManager.selectBannerImage(path);
              },
              child: const Text("Unlock"),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: banners.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (_, index) {
        final banner = banners[index];
        final path = banner['image'];
        final cost = banner['cost'];
        final unlocked = xpManager.unlockedBanners.contains(path);
        final selected = xpManager.selectedBannerImage == path;

        return GestureDetector(
          onTap: () {
            if (unlocked) {
              xpManager.selectBannerImage(path);
            } else if (xpManager.stars >= cost) {
              showPurchaseDialog(path, cost);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Not enough stars!"),
              ));
            }
          },
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(path),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? Colors.green : Colors.grey,
                    width: selected ? 6 : 2,
                  ),
                ),
              ),
              if (!unlocked)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      "$cost ⭐",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              if (unlocked && !selected)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.check_circle, color: Colors.orange, size: 28),
                ),
              if (selected)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.check_circle, color: Colors.green, size: 28),
                ),
            ],
          ),
        );
      },
    );
  }
}
