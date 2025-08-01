import 'package:flutter/material.dart';

class GlowingLogo extends StatefulWidget {
  final String imagePath;
  final double size;

  const GlowingLogo({super.key, required this.imagePath, this.size = 150});

  @override
  State<GlowingLogo> createState() => _GlowingLogoState();
}

class _GlowingLogoState extends State<GlowingLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseSize = widget.size;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowOpacity = _glowAnimation.value;
        final scale = _scaleAnimation.value;

        return Transform.scale(
          scale: scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Soft outer glow (modern aura effect)
              Container(
                width: baseSize * 1.8,
                height: baseSize * 1.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withOpacity(glowOpacity * 0.4),
                      blurRadius: 60,
                      spreadRadius: 20,
                    ),
                    BoxShadow(
                      color: Colors.deepOrange.withOpacity(glowOpacity * 0.2),
                      blurRadius: 90,
                      spreadRadius: 35,
                    ),
                  ],
                ),
              ),

              // Logo image with subtle shadow (no ugly circles)
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    widget.imagePath,
                    width: baseSize,
                    height: baseSize,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


/// --- Elegant Progress Bar with shimmer & animated dots ---

class ElegantProgressBar extends StatefulWidget {
  final double progress;

  const ElegantProgressBar({super.key, required this.progress});

  @override
  State<ElegantProgressBar> createState() => _ElegantProgressBarState();
}

class _ElegantProgressBarState extends State<ElegantProgressBar>
    with TickerProviderStateMixin {
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouncing dots loader
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return AnimatedBuilder(
              animation: _dotsController,
              builder: (context, child) {
                double t = (_dotsController.value * 3 - index).clamp(0.0, 1.0);

                // Bounce effect
                double scale =
                    0.7 + (0.4 * (1 - (t - 0.5).abs() * 2).clamp(0, 1));

                // Fade effect
                double opacity = (1 - (t - 0.5).abs() * 2).clamp(0, 1);

                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),

        const SizedBox(height: 10),

        // Clean progress bar
        LayoutBuilder(
          builder: (context, constraints) {
            final progressWidth = constraints.maxWidth * widget.progress;

            return Stack(
              children: [
                // Background track
                Container(
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade200.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.shade900.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                ),

                // Progress fill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: progressWidth,
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFA726),
                        Color(0xFFF57C00),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orangeAccent.withValues(alpha: 0.6),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
