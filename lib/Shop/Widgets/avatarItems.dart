import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AvatarItemWidget extends StatelessWidget {
  final String emoji;
  final int cost;
  final bool unlocked;
  final bool selected;
  final int userStars;
  final VoidCallback onSelect;
  final VoidCallback onBuy;

  const AvatarItemWidget({
    required this.emoji,
    required this.cost,
    required this.unlocked,
    required this.selected,
    required this.userStars,
    required this.onSelect,
    required this.onBuy,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final canBuy = !unlocked && (userStars >= cost);
    final isExpensive = cost >= 30;

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
        duration: const Duration(milliseconds: 350),
        decoration: BoxDecoration(
          color: unlocked ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: selected ? Colors.greenAccent.withOpacity(0.7) : Colors.black26,
              blurRadius: selected ? 15 : 7,
              spreadRadius: selected ? 3 : 1,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: selected
                ? Colors.greenAccent
                : unlocked
                ? Colors.orange
                : Colors.grey.shade400,
            width: selected ? 4 : 2,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                emoji,
                style: TextStyle(
                  fontSize: 52,
                  shadows: selected
                      ? [
                    Shadow(
                      color: Colors.greenAccent.withOpacity(0.7),
                      blurRadius: 15,
                      offset: const Offset(0, 0),
                    )
                  ]
                      : null,
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: 10,
                right: 10,
                child: _RibbonBadge(
                  text: 'SELECTED',
                  color: Colors.greenAccent.shade700,
                ),
              )
            else if (unlocked)
              Positioned(
                top: 10,
                right: 10,
                child: _RibbonBadge(
                  text: 'UNLOCKED',
                  color: Colors.orange.shade700,
                ),
              ),
            if (!unlocked)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: isExpensive
                      ? Shimmer.fromColors(
                    baseColor: Colors.deepOrange.shade700,
                    highlightColor: Colors.yellow.shade400,
                    child: Text(
                      '$cost ⭐',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black54,
                            offset: Offset(0, 0),
                          )
                        ],
                      ),
                    ),
                  )
                      : Text(
                    '$cost ⭐',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RibbonBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _RibbonBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.7),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
