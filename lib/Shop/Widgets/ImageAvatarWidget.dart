import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ImageAvatarItemWidget extends StatelessWidget {
  final String imagePath;
  final int cost;
  final bool unlocked;
  final bool selected;
  final int userStars;
  final VoidCallback onSelect;
  final VoidCallback onBuy;

  const ImageAvatarItemWidget({
    super.key,
    required this.imagePath,
    required this.cost,
    required this.unlocked,
    required this.selected,
    required this.userStars,
    required this.onSelect,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final canBuy = !unlocked && (userStars >= cost);

    return GestureDetector(
      onTap: () {
        if (unlocked) {
          onSelect();
        } else if (canBuy) {
          onBuy();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not enough stars! Keep playing to earn more.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: unlocked ? Colors.white : Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Colors.green
                : unlocked
                ? Colors.orange
                : Colors.grey.shade400,
            width: selected ? 4 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: selected ? Colors.greenAccent.withValues(alpha: 0.6) : Colors.black26,
              blurRadius: selected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  imagePath,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: 8,
                right: 8,
                child: _badge('SELECTED', Colors.green),
              )
            else if (unlocked)
              Positioned(
                top: 8,
                right: 8,
                child: _badge('UNLOCKED', Colors.orange),
              ),
            if (!unlocked)
              Positioned(
                bottom: 1,
                left: 0,
                right: 0,
                child: Center(
                  child: Shimmer.fromColors(
                    baseColor: Colors.deepOrange,
                    highlightColor: Colors.yellow,
                    child: Text(
                      '$cost ⭐',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 2, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.7),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 10,
        ),
      ),
    );
  }
}
