import 'package:flutter/cupertino.dart';
import 'package:mortaalim/Shop/Widgets/LottieAvatarGrid.dart';

import '../../Widgets/ImageAvatarGrid.dart';


class AnimatedAvatars extends StatelessWidget {
  const AnimatedAvatars();

  static const List<Map<String, dynamic>> _lottieAvatarItems = [
    {'lottie': 'assets/animations/AnimatedAvatars/Cat Crying emojiSticker animation.json', 'cost': 30},
    {'lottie': 'assets/animations/AnimatedAvatars/Cat feeling love emotionsexpression. Emojisticker animation.json', 'cost': 30},
    {'lottie': 'assets/animations/AnimatedAvatars/Cute bear dancing.json', 'cost': 30},
    {'lottie': 'assets/animations/AnimatedAvatars/Cute dog eat.json', 'cost': 30},
    {'lottie': 'assets/animations/AnimatedAvatars/Nice rabbit with balloon.json', 'cost': 30},
    {'lottie': 'assets/animations/AnimatedAvatars/Smoothymon - typing.json', 'cost': 30},
  ];
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFff9966), Color(0xFFff5e62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: LottieAvatarGrid(lottieAvatars: _lottieAvatarItems),
      ),
    );
  }
}


