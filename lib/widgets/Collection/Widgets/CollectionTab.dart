import 'package:flutter/material.dart';

import 'CategorySelection.dart';
import 'ProgressionHeader.dart';

class CollectionTab extends StatelessWidget {
  final String title;
  final List<String> allItems;
  final List<String> unlockedItems;
  final String selectedItem;
  final void Function(String) onSelect;
  final String Function(String path) categoryOf;

  const CollectionTab({
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
          child: ProgressHeader(
            title: title,
            unlockedCount: unlockedCount,
            totalCount: totalCount,
            progress: progress,
          ),
        ),
        for (final entry in grouped.entries)
          SliverToBoxAdapter(
            child: CategorySection(
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