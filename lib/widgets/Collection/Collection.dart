import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

// Your own imports
import '../../XpSystem.dart'; // contains ExperienceManager
import 'AllAssets.dart';
import 'Widgets/CategorySelection.dart';
import 'Widgets/CollectionTab.dart';
import 'Widgets/ItemTiles.dart';
import 'Widgets/SmallStatPill.dart';

class CollectionPagePremium extends StatefulWidget {
  const CollectionPagePremium({Key? key}) : super(key: key);

  @override
  State<CollectionPagePremium> createState() => _CollectionPagePremiumState();
}

class _CollectionPagePremiumState extends State<CollectionPagePremium>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExperienceManager>(
      builder: (context, manager, _) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF0F0F5), Color(0xFFE8E8F5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  _buildSearchBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        CollectionTab(
                          title: 'Avatars',
                          allItems: AllAssets.allAvatars
                              .where((p) =>
                              p.toLowerCase().contains(searchQuery.toLowerCase()))
                              .toList(),
                          unlockedItems: manager.unlockedAvatars,
                          selectedItem: manager.selectedAvatar,
                          onSelect: manager.selectAvatar,
                          categoryOf: (p) => _extractAfterDir(p, 'AvatarImage'),
                        ),
                        CollectionTab(
                          title: 'Banners',
                          allItems: AllAssets.allBanners
                              .where((p) =>
                              p.toLowerCase().contains(searchQuery.toLowerCase()))
                              .toList(),
                          unlockedItems: manager.unlockedBanners,
                          selectedItem: manager.selectedBannerImage,
                          onSelect: manager.selectBannerImage,
                          categoryOf: (p) => _extractAfterDir(p, 'Banners'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.purpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.collections, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'My Collection',
                style: TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabs,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white,
            ),
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.white,
            tabs: const [
              Tab(text: 'Avatars'),
              Tab(text: 'Banners'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => setState(() => searchQuery = value),
      ),
    );
  }

  static String _extractAfterDir(String path, String rootDir) {
    final parts = path.split('/');
    final idx = parts.indexOf(rootDir);
    if (idx != -1 && idx + 1 < parts.length) {
      return parts[idx + 1];
    }
    return 'Others';
  }
}


