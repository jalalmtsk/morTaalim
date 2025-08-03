import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:lottie/lottie.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'ModeSelectorPage.dart';
import 'quiz_Page.dart';

class ResultPage extends StatefulWidget {
  final int player1Score;
  final int player2Score;
  final GameMode mode;
  final QuizLanguage language;
  final String? player1Name;
  final String? player2Name; // Optional for single player

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

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.deepOrange.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.deepOrange,
                  shadows: [
                    Shadow(
                      blurRadius: 5,
                      color: Colors.deepOrangeAccent,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$score ${tr(context).points}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 8,
                      color: Colors.black26,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({required VoidCallback onTap, required Widget child}) {
    return Material(
      borderRadius: BorderRadius.circular(30),
      elevation: 6,
      shadowColor: Colors.deepOrange.withOpacity(0.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        splashColor: Colors.deepOrange.shade100,
        highlightColor: Colors.deepOrange.shade50,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF7E5F), Color(0xFFFFB88C)], // smooth orange gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 1.1,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 3,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton({required VoidCallback onTap}) {
    return Material(
      borderRadius: BorderRadius.circular(30),
      color: Colors.white.withOpacity(0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        splashColor: Colors.deepOrange.shade100,
        highlightColor: Colors.deepOrange.shade50,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
              const SizedBox(width: 6),
              Text(
                tr(context).back,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 1.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Subtle pastel gradient background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade50,
              Colors.deepOrange.shade300,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 320,
                        child: AnimatedTextKit(
                          animatedTexts: [
                            ColorizeAnimatedText(
                              winner,textAlign: TextAlign.center,
                              textStyle: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.4,
                              ),
                              colors: [
                                Colors.deepOrange.shade700,
                                Colors.deepOrange.shade400,
                                Colors.orange.shade600,
                                Colors.deepOrange.shade900,
                              ],
                            ),
                          ],
                          isRepeatingAnimation: true,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Lottie.asset(
                      'assets/animations/QuizzGame_Animation/Champion.json',
                      width: 280,
                      height: 280,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 20),

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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBackButton(onTap: () => Navigator.pop(context)),

                        const SizedBox(width: 12),

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
                          ),child: Text('🔁 ${tr(context).playAgain}'),
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
