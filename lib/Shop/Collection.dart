import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../XpSystem.dart';

class CollectionPage extends StatelessWidget {
  final Map<String, List<String>> avatarCategories; // key: category name, value: list of paths
  final List<String> allBanners;
  final List<String> allLotties;

  const CollectionPage({
    super.key,
    required this.avatarCategories,
    required this.allBanners,
    required this.allLotties,
  });

  Widget _buildItem({
    required BuildContext context,
    required String path,
    required bool unlocked,
    required VoidCallback onTap,
    double size = 70,
  }) {
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: unlocked ? Colors.greenAccent : Colors.grey.shade600,
                  width: unlocked ? 3 : 2),
              image: DecorationImage(
                image: AssetImage(path),
                fit: BoxFit.cover,
                colorFilter: !unlocked
                    ? ColorFilter.mode(Colors.black.withOpacity(0.45), BlendMode.darken)
                    : null,
              ),
            ),
          ),
          if (!unlocked)
            const Icon(Icons.lock, color: Colors.white70, size: 28),
        ],
      ),
    );
  }

  Widget _buildCategory({
    required BuildContext context,
    required String title,
    required List<String> items,
    required List<String> unlockedItems,
    double itemSize = 70,
    void Function(String path)? onSelect,
  }) {
    final unlockedCount = items.where((item) => unlockedItems.contains(item)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('$unlockedCount / ${items.length}', style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        SizedBox(
          height: itemSize + 20,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (_, index) {
              final path = items[index];
              final unlocked = unlockedItems.contains(path);
              return _buildItem(
                context: context,
                path: path,
                unlocked: unlocked,
                onTap: () {
                  if (onSelect != null) onSelect(path);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$title selected!')),
                  );
                },
                size: itemSize,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context);

    // Global summary
    final totalAvatars = avatarCategories.values.fold<int>(0, (sum, list) => sum + list.length);
    final totalUnlockedAvatars = avatarCategories.values
        .fold<int>(0, (sum, list) => sum + list.where((a) => xpManager.unlockedAvatars.contains(a)).length);

    final totalBanners = allBanners.length;
    final totalUnlockedBanners = allBanners.where((b) => xpManager.unlockedBanners.contains(b)).length;

    final totalLotties = allLotties.length;
    final totalUnlockedLotties = allLotties.where((l) => xpManager.unlockedAvatars.contains(l)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collection'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Global summary
            Card(
              color: Colors.deepPurpleAccent.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text('Collection Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.yellowAccent.shade200)),
                    const SizedBox(height: 8),
                    Text('Avatars: $totalUnlockedAvatars / $totalAvatars', style: const TextStyle(color: Colors.white)),
                    Text('Banners: $totalUnlockedBanners / $totalBanners', style: const TextStyle(color: Colors.white)),
                    Text('Lotties: $totalUnlockedLotties / $totalLotties', style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Avatars by category
            ...avatarCategories.entries.map((entry) => _buildCategory(
              context: context,
              title: entry.key,
              items: entry.value,
              unlockedItems: xpManager.unlockedAvatars,
              itemSize: 70,
              onSelect: (path) => xpManager.selectAvatar(path),
            )),

            // Banners
            _buildCategory(
              context: context,
              title: 'Banners',
              items: allBanners,
              unlockedItems: xpManager.unlockedBanners,
              itemSize: 100,
              onSelect: (path) => xpManager.selectBannerImage(path),
            ),

            // Lotties
            _buildCategory(
              context: context,
              title: 'Lotties',
              items: allLotties,
              unlockedItems: xpManager.unlockedAvatars, // reuse avatar logic
              itemSize: 100,
              onSelect: (path) => xpManager.selectAvatar(path),
            ),
          ],
        ),
      ),
    );
  }
}
