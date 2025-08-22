import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:mortaalim/IndexPage.dart';

class LoadingFromUserToIndex extends StatefulWidget {
  final String firstName;
  final String lastName;
  final int age;
  final String gender;
  final String banner;

  const LoadingFromUserToIndex({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.gender,
    required this.banner,
  }) : super(key: key);

  @override
  _LoadingFromUserToIndexState createState() => _LoadingFromUserToIndexState();
}

class _LoadingFromUserToIndexState extends State<LoadingFromUserToIndex>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  List<String> details = [];
  int currentStep = 0;
  double progress = 0.0;

  // Gradient Animation
  late AnimationController _gradientController;
  int currentGradientIndex = 0;

  final List<List<Color>> gradientSets = [
    [Colors.deepPurple.shade400, Colors.deepPurple.shade800],
    [Colors.orange.shade300, Colors.orange.shade700],
    [Colors.teal.shade300, Colors.teal.shade700],
  ];

  @override
  void initState() {
    super.initState();

    details = [
      "✨ Name: ${widget.firstName} ${widget.lastName}",
      "🎂 Age: ${widget.age}",
      "🚻 Gender: ${widget.gender}",
      "🏳️ Banner: ${widget.banner}",
    ];

    _controllers = List.generate(
      details.length,
          (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      ),
    );

    _animations = _controllers
        .map((controller) =>
        CurvedAnimation(parent: controller, curve: Curves.elasticOut))
        .toList();

    _startProcess();

    // Gradient animation setup
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
  }

  void _startProcess() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (currentStep < details.length) {
        Future.delayed(Duration(milliseconds: 300 * currentStep), () {
          _controllers[currentStep].forward();
        });

        setState(() {
          currentStep++;
          progress = currentStep / details.length;
        });
      } else {
        timer.cancel();
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => Index()));
        });
      }
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  Widget _buildDetailBubble(String detail, int index) {
    return AnimatedBuilder(
      animation: _animations[index],
      builder: (context, child) {
        double value = _animations[index].value.clamp(0.0, 1.0);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 80 * (1 - value)),
            child: Transform.scale(
              scale: 0.5 + 0.5 * value,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.primaries[index % Colors.primaries.length].withOpacity(0.8),
              Colors.primaries[(index + 3) % Colors.primaries.length].withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.primaries[index % Colors.primaries.length].withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.3,
              shadows: [
                Shadow(
                  blurRadius: 8,
                  color: Colors.cyanAccent,
                  offset: Offset(0, 0),
                ),
                Shadow(
                  blurRadius: 4,
                  color: Colors.black38,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextIndex = (currentGradientIndex + 1) % gradientSets.length;

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
            child: Stack(
              children: [
                // Subtle background image overlay
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.7,
                    child: Image.asset(
                      'assets/images/UI/BackGrounds/bg7.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Lottie character with progress orb
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 250,
                            height: 250,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 10,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation(Colors.cyanAccent),
                            ),
                          ),
                          Lottie.asset(
                            'assets/animations/UI_Animations/BrainTechnologyAi.json',
                            width: 300,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            Colors.pinkAccent,
                            Colors.orangeAccent,
                            Colors.yellowAccent,
                            Colors.greenAccent,
                            Colors.cyanAccent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          "Your Magical Profile is Ready!",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                blurRadius: 6,
                                color: Colors.black45,
                                offset: Offset(2, 2),
                              ),
                            ],
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 25),

                      Column(
                        children: List.generate(
                          details.length,
                              (index) => _buildDetailBubble(details[index], index),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
