import 'package:flutter/material.dart';
import 'dart:math';
import 'package:just_audio/just_audio.dart';

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

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _wiggleAnimation =
        Tween<double>(begin: 0, end: 15).animate(_animationController);
  }

  void playSoundAndAnimate(String soundPath) async {
    _animationController.forward().then((_) => _animationController.reverse());
    await _audioPlayer.setAsset(soundPath);
    _audioPlayer.play();
  }

  Widget buildParticles() {
    // Floating circles for fun effect
    return Stack(
      children: List.generate(20, (index) {
        final double left = random.nextDouble() * MediaQuery.of(context).size.width;
        final double top = random.nextDouble() * MediaQuery.of(context).size.height;
        final double size = 10 + random.nextDouble() * 20;
        return Positioned(
          left: left,
          top: top,
          child: Opacity(
            opacity: 0.2 + random.nextDouble() * 0.5,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
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
        // Full screen background image
        Image.asset(
          animal['bgImage'],
          fit: BoxFit.cover,
        ),
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
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(15),
              child: Column(
                children: [
                  Text(
                    animal['name'],
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Habitat: ${animal['habitat']}',
                    style: TextStyle(fontSize: 20, color: Colors.white70),
                  ),
                  SizedBox(height: 10),
                  Text(
                    animal['info'],
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text('Tap the animal to hear its sound!',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ],
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
      body: PageView.builder(
        controller: _pageController,
        itemCount: animals.length,
        onPageChanged: (index) => setState(() => currentIndex = index),
        itemBuilder: (context, index) {
          return buildAnimalPage(animals[index]);
        },
      ),
    );
  }
}
