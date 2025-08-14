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
            // Pulsing glow with blur
            Container(
              width: size * 2.2,
              height: size * 2.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.orange.withOpacity(glowIntensity * 0.4),
                    Colors.deepOrange.withOpacity(0.0),
                  ],
                  stops: const [0.4, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(glowIntensity * 0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),

            // Rotating particles
            ...List.generate(8, (i) {
              final angle = (2 * pi / 8) * i + _controller.value * 2 * pi;
              final particleSize = 4 + 4 * sin(_controller.value * pi + i);
              return Positioned(
                left: size + cos(angle) * size * 0.95,
                top: size + sin(angle) * size * 0.95,
                child: Container(
                  width: particleSize,
                  height: particleSize,
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.6 + 0.4 * glowIntensity),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orangeAccent.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
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
            color: Colors.deepOrange,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: Colors.orangeAccent,
                offset: Offset(0, 1),
              )
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Animated Progress Bar with gradient and shadow
        Stack(
          children: [
            Container(
              height: 22,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth * progress;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: width,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orangeAccent.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
