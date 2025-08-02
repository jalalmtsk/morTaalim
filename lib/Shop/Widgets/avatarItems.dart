import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

class AvatarItemWidget extends StatefulWidget {
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
  State<AvatarItemWidget> createState() => _AvatarItemWidgetState();
}

class _AvatarItemWidgetState extends State<AvatarItemWidget>
    with TickerProviderStateMixin {
  double _scale = 1.0;
  late AnimationController _glowController;
  late AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _onTapDown(_) => setState(() => _scale = 0.93);
  void _onTapUp(_) => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    final canBuy = !widget.unlocked && (widget.userStars >= widget.cost);
    final isExpensive = widget.cost >= 30;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: (details) {
        HapticFeedback.lightImpact();
        setState(() => _scale = 1.0);
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () {
        if (widget.unlocked) {
          widget.onSelect();
        } else if (canBuy) {
          widget.onBuy();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not enough stars! Earn more to unlock this avatar.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            final glow = (0.5 + 0.5 * sin(_glowController.value * 2 * pi)) * 15;
            return Container(
              decoration: BoxDecoration(
                color: widget.unlocked
                    ? Colors.white.withOpacity(0.95)
                    : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.selected
                      ? Colors.greenAccent
                      : widget.unlocked
                      ? Colors.orange
                      : Colors.grey.shade500,
                  width: widget.selected ? 3 : 2,
                ),
                boxShadow: [
                  if (widget.selected)
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.7),
                      blurRadius: glow,
                      spreadRadius: 2,
                    )
                  else
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Stack(
                children: [
                  // Glass effect for locked avatars
                  if (!widget.unlocked)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(color: Colors.transparent),
                      ),
                    ),

                  // Sparkle animation for selected avatars
                  if (widget.selected)
                    ...List.generate(6, (index) {
                      final angle = (index / 6) * 2 * pi;
                      final offset = Offset(
                        30 * cos(angle + _sparkleController.value * 2 * pi),
                        30 * sin(angle + _sparkleController.value * 2 * pi),
                      );
                      return Positioned(
                        top: 45 + offset.dy,
                        left: 45 + offset.dx,
                        child: Opacity(
                          opacity: 0.8,
                          child: Icon(Icons.star,
                              size: 12, color: Colors.yellow.shade600),
                        ),
                      );
                    }),

                  // Avatar Emoji
                  Center(
                    child: Text(
                      widget.emoji,
                      style: TextStyle(
                        fontSize: 65,
                        shadows: widget.selected
                            ? [
                          Shadow(
                            color: Colors.greenAccent.withOpacity(0.9),
                            blurRadius: 20,
                          )
                        ]
                            : [],
                      ),
                    ),
                  ),

                  // Badges
                  if (widget.selected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _GradientBadge(
                        text: 'SELECTED',
                        colors: [Colors.greenAccent, Colors.green],
                      ),
                    )
                  else if (widget.unlocked)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _GradientBadge(
                        text: 'UNLOCKED',
                        colors: [Colors.orangeAccent, Colors.deepOrange],
                      ),
                    ),

                  // Cost for locked avatars
                  if (!widget.unlocked)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isExpensive)
                              Shimmer.fromColors(
                                baseColor: Colors.deepOrange,
                                highlightColor: Colors.yellow,
                                child: const Icon(Icons.star,
                                    color: Colors.amber, size: 24),
                              )
                            else
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 22),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.cost}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isExpensive
                                    ? Colors.deepOrange
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GradientBadge extends StatelessWidget {
  final String text;
  final List<Color> colors;

  const _GradientBadge({required this.text, required this.colors, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.6),
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
          fontSize: 11,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
