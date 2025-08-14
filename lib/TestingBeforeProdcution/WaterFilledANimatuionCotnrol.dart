import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FillBottleExample extends StatefulWidget {
  @override
  _FillBottleExampleState createState() => _FillBottleExampleState();
}

class _FillBottleExampleState extends State<FillBottleExample>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _currentProgress = 0.0;
  double _targetProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  void _fillMore() {
    setState(() {
      _currentProgress = _targetProgress; // store old progress
      _targetProgress += 0.2;
      if (_targetProgress > 1.0) {
        _targetProgress = 0.0; // reset to empty
        _currentProgress = 0.0;
      }
    });

    // First: stop any idle loop
    _controller.stop();

    // Second: animate smoothly to new level
    _controller.animateTo(
      _targetProgress,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    ).then((_) {
      // Third: start a subtle idle movement (ping-pong)
      _controller.repeat(
        min: _targetProgress - 0.02 < 0 ? 0 : _targetProgress - 0.02,
        max: _targetProgress + 0.02 > 1 ? 1 : _targetProgress + 0.02,
        reverse: true,
        period: const Duration(milliseconds: 400),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset(
          'assets/animations/PetAnimations/WaterBubble.json',
          controller: _controller,
          onLoaded: (composition) {
            _controller.duration = composition.duration;
            // Start initial idle effect
            _controller.repeat(
              min: _targetProgress,
              max: _targetProgress + 0.01,
              reverse: true,
              period: const Duration(milliseconds: 700),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fillMore,
        child: const Icon(Icons.local_drink),
      ),
    );
  }
}
