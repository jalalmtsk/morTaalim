import 'package:flutter/material.dart';
import 'package:mortaalim/Shop/MainShopPageIndex.dart';

import '../../../main.dart';
import 'ItemTiles.dart';
import 'SmallStatPill.dart';


class CategorySection extends StatefulWidget {
  final String category;
  final List<String> items;
  final List<String> unlockedItems;
  final String selectedItem;

  const CategorySection({
    Key? key,
    required this.category,
    required this.items,
    required this.unlockedItems,
    required this.selectedItem, required void Function(String p1) onSelect,
  }) : super(key: key);

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
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
                    SmallStatPill(
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
                      return  ItemTile(
                        asset: asset,
                        isUnlocked: isUnlocked,
                        isSelected: isSelected,
                        onTap: () {
                          if (isUnlocked) {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                opaque: false,
                                pageBuilder: (_, __, ___) => Scaffold(
                                  backgroundColor: Colors.black.withOpacity(0.6),
                                  body: Center(
                                    child: Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(20),
                                          child: Image.asset(
                                            asset,
                                            fit: BoxFit.cover,
                                            width: 300,
                                            height: 400,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white),
                                          onPressed: () => Navigator.pop(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          else {
                            // Show snackbar prompting purchase
                            ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                content: Wrap(
                                  children: [
                                    Text(tr(context).this_avatar_is_locked_unlock_it_in_the),
                                    TextButton(onPressed: (){Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> MainShopPageIndex()));}, child: Text(tr(context).shop, style: TextStyle(color: Colors.deepOrange),))
                                  ],
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
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
