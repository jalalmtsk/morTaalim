import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';

import 'ModeSelectorPage.dart';
import 'quiz_Page.dart';
import 'package:mortaalim/games/Quiz_Game/game_mode.dart' hide GameMode;

class VsScreen extends StatefulWidget {
  final String player1Name;
  final String player1Emoji;
  final String player2Name;
  final String player2Emoji;
  final GameMode mode;
  final QuizLanguage language;

  const VsScreen({
    super.key,
    required this.player1Name,
    required this.player1Emoji,
    required this.player2Name,
    required this.player2Emoji,
    required this.mode,
    required this.language,
  });

  @override
  State<VsScreen> createState() => _VsScreenState();
}

class _VsScreenState extends State<VsScreen> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _flashController;
  late AnimationController _zigzagController;
  late AnimationController _shakeController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playSfx("assets/audios/UI_Audio/SFX_Audio/CinematicStart_SFX.mp3");
    audioManager.playSfx("assets/audios/UI_Audio/SFX_Audio/TransisitonPages_SFX.mp3");

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _zigzagController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizPage(
            mode: widget.mode,
            player1Name: widget.player1Name,
            player1Emoji: widget.player1Emoji,
            player2Name: widget.player2Name,
            player2Emoji: widget.player2Emoji,
            language: widget.language,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _flashController.dispose();
    _zigzagController.dispose();
    _shakeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowValue = (sin(_glowController.value * pi * 2) * 0.5) + 0.5;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFF9F4), // very soft off-white
              Color(0xFFFFE6B8), // light creamy orange
              Color(0xFFFFB74D), // soft orange
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Flash background with soft orange glow pulses
            FadeTransition(
              opacity: _flashController.drive(CurveTween(curve: Curves.easeOut)),
              child: Container(color: Colors.orange.withOpacity(0.15)),
            ),

            // Soft glowing circles behind players
            Positioned(
              left: 50,
              top: 150,
              child: _glowingCircle(Colors.orange.withOpacity(0.35), glowValue),
            ),
            Positioned(
              right: 50,
              top: 150,
              child: _glowingCircle(Colors.deepOrange.withOpacity(0.35), glowValue),
            ),

            Center(
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _scaleController,
                  curve: Curves.elasticOut,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPlayer(widget.player1Emoji, widget.player1Name, Colors.deepOrange, glowValue),
                    const SizedBox(width: 30),

                    SizedBox(
                      width: 300,
                      height: 300,
                      child: AnimatedBuilder(
                        animation: _shakeController,
                        builder: (context, child) {
                          final shake = (_shakeController.value - 0.5) * 10;
                          return Transform.translate(
                            offset: Offset(shake,0 ),
                            child: child,
                          );
                        },
                        child: Lottie.asset(
                          'assets/animations/QuizzGame_Animation/Versus.json',
                          repeat: false,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(width: 30),
                    _buildPlayer(widget.player2Emoji, widget.player2Name, Colors.orange, glowValue),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glowingCircle(Color color, double glowValue) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(glowValue),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(glowValue),
            blurRadius: 40 * glowValue,
            spreadRadius: 20 * glowValue,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer(String emoji, String name, Color glowColor, double glowValue) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: TextStyle(
            fontSize: 90,
            shadows: [
              Shadow(
                blurRadius: 30 * glowValue,
                color: glowColor,
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            shadows: [
              Shadow(
                blurRadius: 20 * glowValue,
                color: glowColor.withOpacity(0.8),
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
