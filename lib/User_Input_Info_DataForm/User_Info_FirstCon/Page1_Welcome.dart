import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';

class WelcomePage extends StatefulWidget {
  final VoidCallback onGetStarted;

  const WelcomePage({Key? key, required this.onGetStarted}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;

  int currentGradientIndex = 0;
  int currentTextIndex = 0;

  final List<List<Color>> gradientSets = [
    [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
    [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
    [const Color(0xFFFF6FD8), const Color(0xFFFF9068)],
  ];

  final List<String> buttonTexts = ['Commencer', 'Start', 'ابدأ', 'ⴰⵙⵙⵓⵎ', 'Beginnen'];
  final List<String> subtitles = [
    'Découvrez, apprenez et progressez avec nous.\nEnsemble, rendons la connaissance amusante et accessible !',
    'Discover, learn and progress with us.\nLet\'s make knowledge fun and accessible!',
    'اكتشف وتعلم وتقدم معنا.\nلنجعل المعرفة ممتعة ومتاحة للجميع!!',
    'ⵉⵎⵙⵙⴰⴼ, ⵜⴰⵙⵉⴷⵉⵏ ⴷ ⵜⴰⵙⵓⵎⵓⵏ.\nⵙⵉⵏⵏⴰ ⵉⵎⵙⵙⴰⴼ ⵏ ⵉⴳⴻⵔⴻⵏ!',
    'Entdecken, lernen und Fortschritte mit uns.\nLassen Sie uns Wissen spaßig und zugänglich machen!'
  ];
  final List<String> titles = [
    'Bienvenue dans votre nouvelle aventure',
    'Welcome to your new adventure',
    'مرحبا بك في مغامرتك الجديدة',
    'ⴰⵎⴰⵣⵉⵖ ⴷ ⵉⴳⴻⵔⴻⵏ ⴰⵎⴰⴷⴰⵔⵜ',
    'Willkommen zu deinem neuen Abenteuer'
  ];


  @override
  void initState() {
    super.initState();

    final audioManager = Provider.of<AudioManager>(context, listen: false);
    audioManager.playAlert("assets/audios/logo_introsecond.mp3");
    audioManager.playBackgroundMusic("assets/audios/BackGround_Audio/FunnyDogUserInfo_bg.mp3");

    // Gradient controller
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          currentGradientIndex = (currentGradientIndex + 1) % gradientSets.length;
        });
        _gradientController.forward(from: 0);
      }
    });
    _gradientController.forward();

    // Fade controller
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1750),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _startTextLoop();
  }


  void _startTextLoop() async {
    while (mounted) {
      // Fade out
      await _fadeController.reverse(from: 1.0);

      // Change text
      setState(() {
        currentTextIndex = (currentTextIndex + 1) % titles.length;
      });

      // Fade in
      await _fadeController.forward(from: 0.0);

      // Wait before next change
      await Future.delayed(const Duration(milliseconds: 5000));
    }
  }


  @override
  void dispose() {
    _fadeController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextIndex = (currentGradientIndex + 1) % gradientSets.length;
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, _) {
          final colors = List<Color>.generate(
            2,
                (i) => Color.lerp(
              gradientSets[currentGradientIndex][i],
              gradientSets[nextIndex][i],
              _gradientController.value,
            )!,
          );

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Lottie.asset(
                        'assets/animations/FirstTouchAnimations/Welcome.json',
                        width: 260,
                        height: 260,
                        repeat: true,
                      ),
                    ),
                    // Fade + Slide Animated Texts with fixed height
                    FadeTransition(
                      opacity: _fadeController,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SizedBox(
                          height: 180, // FIXED HEIGHT prevents jumping
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                titles[currentTextIndex],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 8,
                                      color: Colors.black26,
                                      offset: Offset(0, 3),
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                subtitles[currentTextIndex],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.95),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        audioManager.playEventSound("clickButton");
                        widget.onGetStarted();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: const Color(0xFF43E97B),
                      ),
                      child: SizedBox(
                        width: 100,
                        child: Center(
                          child: Text(
                            buttonTexts[currentTextIndex],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
