import 'package:flutter/material.dart';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:mortaalim/main.dart';

import 'Animal_Data.dart';

class ListenMode extends StatefulWidget {
  @override
  _AnimalFullScreenPageState createState() => _AnimalFullScreenPageState();
}

class _AnimalFullScreenPageState extends State<ListenMode>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _animationController;
  late Animation<double> _wiggleAnimation;
  int currentIndex = 0;
  Random random = Random();

  // --- Banner Ad ---
  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _wiggleAnimation =
        Tween<double>(begin: 0, end: 15).animate(_animationController);

    // Initialize Banner Ad

  }

  void playSoundAndAnimate(String soundPath) async {
    _animationController.forward().then((_) => _animationController.reverse());
    await _audioPlayer.stop();
    await _audioPlayer.setAsset(soundPath);
    _audioPlayer.play();
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
  }

  Widget buildParticles() {
    return Stack(
      children: List.generate(15, (index) {
        final double left =
            random.nextDouble() * MediaQuery.of(context).size.width;
        final double top =
            random.nextDouble() * MediaQuery.of(context).size.height;
        return Positioned(
          left: left,
          top: top,
          child: Opacity(
            opacity: 0.3 + random.nextDouble() * 0.6,
            child: Icon(
              Icons.tips_and_updates,
              size: 15 + random.nextDouble() * 20,
              color: Colors.yellow.withOpacity(0.8),
            ),
          ),
        );
      }),
    );
  }

  Widget buildAnimalPage(Map<String, dynamic> animal) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(animal['bgImage'], fit: BoxFit.cover),
        buildParticles(),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => playSoundAndAnimate(animal['sound']),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (_, child) {
                  return Transform.rotate(
                    angle: sin(_wiggleAnimation.value * pi / 180),
                    child: child,
                  );
                },
                child: Hero(
                  tag: animal['name'],
                  child: Image.asset(
                    animal['image'],
                    width: MediaQuery.of(context).size.width * 0.55,
                    height: MediaQuery.of(context).size.width * 0.55,
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.9), Colors.blue.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26, blurRadius: 10, spreadRadius: 2)
                ],
              ),
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    animal['name'],
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '🌍 Habitat: ${animal['habitat']}',
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 12),
                  Text(
                    animal['info'],
                    style: TextStyle(fontSize: 18, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '👆 ${tr(context).tapTheAnimalToHearItsSound!}',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.redAccent,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

          ],
        ),
      ],
    );
  }

  Widget buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        animals.length,
            (index) => AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4),
          width: currentIndex == index ? 14 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: currentIndex == index ? Colors.blueAccent : Colors.grey,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Fullscreen background image
          PageView.builder(
            controller: _pageController,
            itemCount: animals.length,
            onPageChanged: (index) => setState(() => currentIndex = index),
            itemBuilder: (context, index) {
              // Wrap your existing buildAnimalPage in a Container
              return Container(
                width: double.infinity,
                height: double.infinity,
                child: buildAnimalPage(animals[index]),
              );
            },
          ),

          // Page indicator
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: buildPageIndicator(),
          ),

        ],
      ),
    );
  }

}
