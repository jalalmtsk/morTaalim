import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'LockOverlay.dart';

class ItemTile extends StatefulWidget {
  final String asset;
  final bool isUnlocked;
  final bool isSelected;
  final VoidCallback? onTap;

  const ItemTile({
    Key? key,
    required this.asset,
    required this.isUnlocked,
    required this.isSelected,
    this.onTap,
  }) : super(key: key);

  @override
  State<ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<ItemTile> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_controller);

    _glowAnimation = Tween<double>(begin: 0.0, end: 15.0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_controller);
  }

  void _handleTap() {
    if (widget.isUnlocked) {
      _controller.forward(from: 0).then((_) => _controller.reverse());
      widget.onTap?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.lock, color: Colors.white),
              SizedBox(width: 8),
              Text("This item is locked! Unlock it in the shop."),
            ],
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: widget.isSelected
                    ? const LinearGradient(
                  colors: [Colors.greenAccent, Colors.lightGreen],
                )
                    : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isUnlocked
                      ? Colors.deepPurpleAccent
                      : Colors.grey.shade400,
                  width: widget.isSelected ? 3 : 2,
                ),
                boxShadow: [
                  if (widget.isSelected)
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.6),
                      blurRadius: _glowAnimation.value,
                      spreadRadius: _glowAnimation.value / 2,
                    ),
                  BoxShadow(
                    color: Colors.deepPurpleAccent.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildContent(widget.asset, widget.isUnlocked),
                    if (!widget.isUnlocked) const LockOverlay(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(String asset, bool isUnlocked) {
    if (asset.endsWith('.png') ||
        asset.endsWith('.jpg') ||
        asset.endsWith('.webp')) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        color: isUnlocked ? null : Colors.black.withOpacity(0.55),
        colorBlendMode: isUnlocked ? null : BlendMode.darken,
      );
    } else if (asset.endsWith('.json')) {
      return Container(
        color: isUnlocked ? null : Colors.black.withOpacity(0.65),
        child: Lottie.asset(asset, fit: BoxFit.cover),
      );
    } else {
      // Emoji or text
      return Container(
        alignment: Alignment.center,
        color: isUnlocked ? null : Colors.black.withOpacity(0.7),
        child: Text(
          asset,
          style: TextStyle(
            fontSize: 70,
            shadows: [
              Shadow(
                blurRadius: 10,
                color: widget.isUnlocked ? Colors.purpleAccent : Colors.black38,
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
      );
    }
  }
}
