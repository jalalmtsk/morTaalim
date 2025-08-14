import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../tools/audio_tool/Audio_Manager.dart';
import 'GlowingAppLogoUI.dart';

class LoadingScreen extends StatefulWidget {
  final double progress;
  final bool loadingComplete;

  const LoadingScreen({
    super.key,
    required this.progress,
    required this.loadingComplete,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  late String _backgroundImage;
  bool _showAppLogo = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _images = [
    'assets/images/UI/BackGrounds/bg4.jpg',
    'assets/images/UI/BackGrounds/bg5.jpg',
    'assets/images/UI/BackGrounds/bg7.jpg',
    'assets/images/UI/BackGrounds/bg8.jpg',
    'assets/images/UI/BackGrounds/bg9.jpg',
    'assets/images/UI/BackGrounds/bg10.jpg',
  ];

  @override
  void initState() {
    super.initState();

    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playSfx("assets/audios/AppLogoSound.mp3");

    final random = Random();
    _backgroundImage = _images[random.nextInt(_images.length)];

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Show app logo after 800 ms, fade it in
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showAppLogo = true);
        _fadeController.forward(from: 0);
      }
    });

  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background
        Positioned.fill(
          child: Image.asset(
            _backgroundImage,
            fit: BoxFit.cover,
          ),
        ),
        Container(color: Colors.black.withOpacity(0.5)),

        // Show App logo fading in after 800ms
        Center(
          child: _showAppLogo
              ? FadeTransition(
            opacity: _fadeAnimation,
            child: GlowingLogo(
              imagePath: 'assets/icons/logo3.png',
              size: 160,
            ),
          )
              : const SizedBox.shrink(),  // Nothing shown before 800ms
        ),

        // Bottom progress bar & text
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElegantProgressBar(progress: widget.progress),
                const SizedBox(height: 16),
                Text(
                  widget.loadingComplete ? "Ready!" : "Loading...",
                  style: TextStyle(
                    color: Colors.orange.shade50,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        blurRadius: 6,
                        color: Colors.orange.shade900.withOpacity(0.7),
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${(widget.progress * 100).toInt()}%",
                  style: TextStyle(
                    color: Colors.orange.shade200.withOpacity(0.95),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.orange.shade900.withOpacity(0.6),
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
