import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/IndexPage.dart';
import 'package:mortaalim/tools/audio_tool/audio_tool.dart';

final MusicPlayer _musicPlayer = MusicPlayer();
final MusicPlayer _musicPlayer_wave = MusicPlayer();

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

  @override
  void initState() {
    super.initState();

    _musicPlayer.play("assets/audios/modern_logo.mp3");

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
      upperBound: 3.2,
    );

    // Trigger logo animations after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showLogo = true);
        _fadeController.forward();
        _musicPlayer_wave.play("assets/audios/openingZoom.mp3");
        _scaleController.forward().then((_) {
          _scaleController.reverse(); // bounce
        });
      }
    });

    // Move to next page after 4 seconds
    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Index(onChangeLocale: widget.onChangeLocale)),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _musicPlayer.dispose();
    _musicPlayer_wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background wave animation
      /* Lottie.asset(
              'assets/animations/anim.json',
              fit: BoxFit.cover,
            ),
*/

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
                      'assets/images/logo_black.png',
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
