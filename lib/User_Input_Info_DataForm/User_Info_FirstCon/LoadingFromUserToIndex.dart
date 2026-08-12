import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/IndexPage.dart';
import 'package:mortaalim/main.dart';

class LoadingFromUserToIndex extends StatefulWidget {
  const LoadingFromUserToIndex({Key? key}) : super(key: key);

  @override
  State<LoadingFromUserToIndex> createState() => _LoadingFromUserToIndexState();
}

class _LoadingFromUserToIndexState extends State<LoadingFromUserToIndex>
    with SingleTickerProviderStateMixin {
  double progress = 0;
  late AnimationController _fadeController;

  // Cycling motivational phrases — replace with tr(context) keys as needed
  final List<String> _phrases = [
    "Préparation de votre expérience...",
    "Chargement de vos données...",
    "Presque prêt !",
    "On y est presque...",
  ];
  int _phraseIndex = 0;
  Timer? _phraseTimer;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    // Cycle through phrases every 2 seconds
    _phraseTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {
          _phraseIndex = (_phraseIndex + 1) % _phrases.length;
        });
      }
    });

    // Progress from 0 → 100 over ~9 seconds
    _progressTimer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => progress += 1);
      if (progress >= 100) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => Index(),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _phraseTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        body: FadeTransition(
          opacity: _fadeController,
          child: Stack(
            children: [
              // ── Background glow circles ─────────────────────────────
              Positioned(
                top: -80,
                left: -60,
                child: _glowCircle(200, const Color(0xFF533483).withOpacity(0.35)),
              ),
              Positioned(
                bottom: -60,
                right: -40,
                child: _glowCircle(180, const Color(0xFFFF6B35).withOpacity(0.2)),
              ),

              // ── Main content ────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // Brain animation
                      SizedBox(
                        width: size.width * 0.65,
                        height: size.width * 0.65,
                        child: Lottie.asset(
                          'assets/animations/UI_Animations/CuteBrainMediating.json',
                          fit: BoxFit.contain,
                          repeat: true,
                          animate: true,
                        ),
                      ),

                      const Spacer(flex: 1),

                      // Cycling motivational phrase
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Text(
                          _phrases[_phraseIndex],
                          key: ValueKey(_phraseIndex),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Progress bar + percentage
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Percentage
                          Text(
                            "${progress.toInt()}%",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white38,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Custom progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Stack(
                              children: [
                                // Track
                                Container(
                                  height: 6,
                                  width: double.infinity,
                                  color: Colors.white.withOpacity(0.08),
                                ),
                                // Fill
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 80),
                                  height: 6,
                                  width: (size.width - 64) * (progress / 100),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFFF6B35), Color(0xFFFFD166)],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Spacer(flex: 1),

                      // Magic loading animation
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: Lottie.asset(
                          'assets/animations/UI_Animations/MagicLoading.json',
                          repeat: true,
                          animate: true,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}