import 'dart:ui';

import 'package:flutter/material.dart';

class AvatarCarousel extends StatefulWidget {
  const AvatarCarousel({
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
  State<AvatarCarousel> createState() => _AvatarCarouselState();
}

class _AvatarCarouselState extends State<AvatarCarousel> {
  double _page = 0;

  bool _isEmoji(String s) => !s.contains('/');

  @override
  void initState() {
    super.initState();
    widget.pageController.addListener(_listener);
  }

  void _listener() {
    setState(() => _page = widget.pageController.page ?? 0);
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: PageView.builder(
        controller: widget.pageController,
        itemCount: widget.items.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final avatar = widget.items[index];
          final selected = widget.selected == avatar;
          final delta = (_page - index).abs();
          final t = (1 - (delta * 0.8)).clamp(0.0, 1.0);

          return Center(
            child: GestureDetector(
              onTap: () {
                widget.onTap(avatar);
                widget.pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                width: lerpDouble(92, 120, t)!,
                height: lerpDouble(92, 120, t)!,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.22),
                      Colors.white.withOpacity(0.08),
                    ],
                  ),
                  border: Border.all(
                    color: selected ? Colors.white : Colors.white.withOpacity(0.25),
                    width: selected ? 3 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selected
                          ? Colors.white.withOpacity(0.8)
                          : Colors.transparent, // no shadow but still valid
                      blurRadius: selected ? 4.0 : 0.9, // never exactly 0.0 to avoid lerp issues
                      spreadRadius: selected ? 1.0 : 0.1, // never negative
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isEmoji(avatar))
                      Text(
                        avatar,
                        style: TextStyle(fontSize: selected ? 52 : 44),
                      )
                    else
                      ClipOval(
                        child: Image.asset(
                          avatar,
                          width: selected ? 88 : 76,
                          height: selected ? 88 : 76,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (selected)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black87,
                          ),
                          child: const Icon(Icons.check, size: 16, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}