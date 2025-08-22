import 'package:flutter/material.dart';

import 'Frosted.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    required this.pageController,
    required this.items,
    required this.selected,
    required this.onTap,
  });

  final PageController pageController;
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onTap;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel>
    with SingleTickerProviderStateMixin {
  double _page = 0;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    widget.pageController.addListener(_listener);

    // Animation for pulsing glow
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  void _listener() {
    setState(() => _page = widget.pageController.page ?? 0);
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_listener);
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: PageView.builder(
        controller: widget.pageController,
        itemCount: widget.items.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final banner = widget.items[index];
          final selected = widget.selected == banner;
          final delta = (_page - index).abs();
          final scale = 1 - (delta * 0.08).clamp(0.0, 0.08);

          return Transform.scale(
            scale: scale,
            child: GestureDetector(
              onTap: () => widget.onTap(banner),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing white neon glow behind selected banner
                  if (selected)
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        final value = 0.8 + 0.2 * _glowController.value;
                        return Container(
                          width: MediaQuery.of(context).size.width * 0.8 * value,
                          height: 150 * value,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.8),
                                blurRadius: 8 * value,
                                spreadRadius: 4 * value,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  // Frosted banner card
                  Frosted(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        banner,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),

                  // Selected badge
                  if (selected)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.shade700,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children:  [
                            const Icon(Icons.check, size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              "tr(context).selected",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}