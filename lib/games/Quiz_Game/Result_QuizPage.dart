import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'ModeSelectorPage.dart';
import 'quiz_Page.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';

class ResultPage extends StatefulWidget {
  final int player1Score;
  final int player2Score;
  final GameMode mode;
  final QuizLanguage language;
  final String? player1Name;
  final String? player2Name;

  const ResultPage({
    super.key,
    required this.player1Score,
    required this.player2Score,
    required this.mode,
    required this.language,
    this.player1Name,
    this.player2Name,
  });

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeInAnimation;

  String get winner {
    if (widget.mode == GameMode.single) {
      return "🎉 ${tr(context).greatJob}";
    } else {
      if (widget.player1Score > widget.player2Score) {
        return "🏆 ${tr(context).player1Wins}: ${widget.player1Name}";
      } else if (widget.player2Score > widget.player1Score) {
        return "🏆 ${tr(context).player2Wins}: ${widget.player2Name}";
      } else {
        return "🤝 ${tr(context).itsATie}";
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeInAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _playVictorySound();
  }

  Future<void> _playVictorySound() async {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    try {
      audioManager.playSfx("assets/audios/QuizGame_Sounds/crowd-cheering-6229.mp3");
      audioManager.playSfx("assets/audios/QuizGame_Sounds/skaWhistleukulele30Sec.mp3");
      audioManager.playSfx('assets/audios/UI_Audio/SFX_Audio/VictoryOrchestral_SFX.mp3');
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildScoreCard(String player, int score) {
    return Transform.scale(
      scale: 1.05,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: 160,
            padding: const EdgeInsets.symmetric(vertical: 26),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade200.withOpacity(0.5), Colors.deepOrange.shade400.withOpacity(0.5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepOrange.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.orangeAccent,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$score ${tr(context).points}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellowAccent,
                    shadows: [
                      Shadow(
                        blurRadius: 12,
                        color: Colors.black26,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({required VoidCallback onTap, required Widget child}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      splashColor: Colors.orange.shade200,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFA726), Color(0xFFFF5722)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.orangeAccent.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: Colors.black38,
                offset: Offset(0, 2),
                blurRadius: 3,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildBackButton({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(36),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 22),
            const SizedBox(width: 6),
            Text(
              tr(context).back,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.deepOrange.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Winner Text with Neon Glow
                    SizedBox(
                      width: 300,
                      child: AnimatedTextKit(
                        animatedTexts: [
                          ColorizeAnimatedText(
                            winner,
                            textAlign: TextAlign.center,
                            textStyle: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                            colors: [
                              Colors.orange.shade700,
                              Colors.yellow.shade400,
                              Colors.deepOrange.shade900,
                            ],
                          ),
                        ],
                        isRepeatingAnimation: true,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Victory Animation
                    Lottie.asset(
                      'assets/animations/QuizzGame_Animation/Champion.json',
                      width: 320,
                      height: 320,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 24),

                    // Score Cards
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 24,
                      runSpacing: 20,
                      children: [
                        _buildScoreCard(widget.player1Name ?? tr(context).player1, widget.player1Score),
                        if (widget.mode == GameMode.multiplayer)
                          _buildScoreCard(widget.player2Name ?? tr(context).player2, widget.player2Score),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBackButton(onTap: () => Navigator.pop(context)),
                        const SizedBox(width: 16),
                        _buildGradientButton(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizPage(
                                mode: widget.mode,
                                language: widget.language,
                                player1Name: widget.player1Name,
                                player2Name: widget.player2Name,
                              ),
                            ),
                          ),
                          child: Text('🔁 ${tr(context).playAgain}'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
