import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Your own imports
import '../../XpSystem.dart'; // contains ExperienceManager
import 'AllAssets.dart';

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
                        _CollectionTab(
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
                        _CollectionTab(
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

class _CollectionTab extends StatelessWidget {
  final String title;
  final List<String> allItems;
  final List<String> unlockedItems;
  final String selectedItem;
  final void Function(String) onSelect;
  final String Function(String path) categoryOf;

  const _CollectionTab({
    Key? key,
    required this.title,
    required this.allItems,
    required this.unlockedItems,
    required this.selectedItem,
    required this.onSelect,
    required this.categoryOf,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByCategory(allItems, categoryOf);
    final unlockedCount = unlockedItems.length;
    final totalCount = allItems.length;
    final progress = totalCount == 0 ? 0.0 : unlockedCount / totalCount;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _ProgressHeader(
            title: title,
            unlockedCount: unlockedCount,
            totalCount: totalCount,
            progress: progress,
          ),
        ),
        for (final entry in grouped.entries)
          SliverToBoxAdapter(
            child: _CategorySection(
              category: _prettify(entry.key),
              items: entry.value,
              unlockedItems: unlockedItems,
              selectedItem: selectedItem,
              onSelect: onSelect,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  static Map<String, List<String>> _groupByCategory(
      List<String> items, String Function(String) categoryOf) {
    final map = <String, List<String>>{};
    for (final p in items) {
      final key = categoryOf(p);
      (map[key] ??= []).add(p);
    }
    for (final key in map.keys) {
      map[key]!.sort();
    }
    final sortedKeys = map.keys.toList()..sort();
    return {for (final k in sortedKeys) k: map[k]!};
  }

  static String _prettify(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _ProgressHeader extends StatelessWidget {
  final String title;
  final int unlockedCount;
  final int totalCount;
  final double progress;

  const _ProgressHeader({
    Key? key,
    required this.title,
    required this.unlockedCount,
    required this.totalCount,
    required this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Icon(
              title == 'Avatars' ? Icons.face_rounded : Icons.image_rounded,
              size: 32,
              color: Colors.deepPurple,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title  •  $unlockedCount / $totalCount unlocked',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatefulWidget {
  final String category;
  final List<String> items;
  final List<String> unlockedItems;
  final String selectedItem;
  final void Function(String) onSelect;

  const _CategorySection({
    Key? key,
    required this.category,
    required this.items,
    required this.unlockedItems,
    required this.selectedItem,
    required this.onSelect,
  }) : super(key: key);

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final columns = (w / 120).floor().clamp(2, 6);
        final previewCount = (_expanded ? widget.items.length : (columns * 2).clamp(0, widget.items.length));

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.category,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _SmallStatPill(
                      unlocked: widget.items.where(widget.unlockedItems.contains).length,
                      total: widget.items.length,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _expanded = !_expanded),
                      icon: AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: _expanded ? 0.5 : 0.0,
                        child: const Icon(Icons.expand_more_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: previewCount,
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 120,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, i) {
                      final asset = widget.items[i];
                      final isUnlocked = widget.unlockedItems.contains(asset);
                      final isSelected = widget.selectedItem == asset;
                      return _ItemTile(
                        asset: asset,
                        isUnlocked: isUnlocked,
                        isSelected: isSelected,
                        onTap: isUnlocked ? () => widget.onSelect(asset) : null,
                      );
                    },
                  ),
                ),
                if (previewCount < widget.items.length) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => setState(() => _expanded = true),
                    icon: const Icon(Icons.unfold_more_rounded),
                    label: Text('Show all ${widget.items.length}'),
                  ),
                ] else if (widget.items.length > (columns * 2)) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => setState(() => _expanded = false),
                    icon: const Icon(Icons.unfold_less_rounded),
                    label: const Text('Show less'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ItemTile extends StatelessWidget {
  final String asset;
  final bool isUnlocked;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ItemTile({
    Key? key,
    required this.asset,
    required this.isUnlocked,
    required this.isSelected,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      tween: Tween(begin: isUnlocked ? 0.95 : 1.0, end: isUnlocked ? 1.0 : 1.0),
      builder: (_, scale, child) {
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(colors: [Colors.greenAccent, Colors.lightGreen])
                  : null,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isUnlocked ? Colors.deepPurpleAccent : Colors.grey.shade400,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Transform.scale(
                    scale: scale,
                    child: Image.asset(
                      asset,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      color: isUnlocked ? null : Colors.black.withOpacity(0.55),
                      colorBlendMode: isUnlocked ? null : BlendMode.darken,
                    ),
                  ),
                  if (!isUnlocked) const _LockOverlay(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LockOverlay extends StatelessWidget {
  const _LockOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white70, width: 1),
          ),
          child: const Icon(
            Icons.lock_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _SmallStatPill extends StatelessWidget {
  final int unlocked;
  final int total;

  const _SmallStatPill({Key? key, required this.unlocked, required this.total})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : unlocked / total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: Colors.deepPurple),
          const SizedBox(width: 6),
          Text(
            '$unlocked/$total',
            style: const TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                backgroundColor: Colors.deepPurple.withOpacity(0.15),
                color: Colors.deepPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
