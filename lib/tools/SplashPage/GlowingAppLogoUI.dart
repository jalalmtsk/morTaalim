import 'package:flutter/material.dart';
import 'dart:math';

class GlowingLogo extends StatefulWidget {
  final String imagePath;
  final double size;

  const GlowingLogo({super.key, required this.imagePath, this.size = 150});

  @override
  State<GlowingLogo> createState() => _GlowingLogoState();
}

class _GlowingLogoState extends State<GlowingLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final glowIntensity = 0.5 + 0.5 * _controller.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Smooth pulsing glow
            Container(
              width: size * 2,
              height: size * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.orange.withOpacity(glowIntensity * 0.3),
                    Colors.deepOrange.withOpacity(0.0),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),

            // Subtle rotating particles (elegant effect)
            ...List.generate(4, (i) {
              final angle = (2 * pi / 4) * i + _controller.value * pi;
              return Positioned(
                left: size + cos(angle) * size * 0.9,
                top: size + sin(angle) * size * 0.9,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),

            // Logo image
            ClipOval(
              child: Image.asset(
                widget.imagePath,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
          ],
        );
      },
    );
  }
}

class ElegantProgressBar extends StatelessWidget {
  final double progress;
  final String label;

  const ElegantProgressBar({
    super.key,
    required this.progress,
    this.label = "Loading...",
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Title Label
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 10),

        // Progress Bar
        Stack(
          children: [
            Container(
              height: 22,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth * progress;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: width,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

