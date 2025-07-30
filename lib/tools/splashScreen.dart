import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/IndexPage.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatefulWidget {
  final void Function(Locale) onChangeLocale;
  const SplashPage({super.key, required this.onChangeLocale});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  bool _showLogo = false;
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    // Fade-in controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Scale (zoom + bounce)
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 2.4,
      upperBound: 3.0,
    );

    // Navigate to next page after 4 seconds
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Index(onChangeLocale: widget.onChangeLocale)),
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      final audioManager = Provider.of<AudioManager>(context, listen: false);
      audioManager.playAlert("assets/audios/SplashScreen_Audio/modern_logo.mp3");

      // Trigger logo animations after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showLogo = true);
          _fadeController.forward();
          audioManager.playAlert("assets/audios/SplashScreen_Audio/openingZoom.mp3");
          _scaleController.forward().then((_) => _scaleController.reverse());
        }
      });

      _initialized = true;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Logo appearing with fade + scale
          if (_showLogo)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: FadeTransition(
                  opacity: _fadeController,
                  child: ScaleTransition(
                    scale: _scaleController,
                    child: Image.asset(
                      'assets/images/fesKia.png',
                      width: 160,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
