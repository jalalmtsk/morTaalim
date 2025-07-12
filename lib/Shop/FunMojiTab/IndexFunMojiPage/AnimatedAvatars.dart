import 'package:flutter/cupertino.dart';
import 'package:mortaalim/Shop/Widgets/LottieAvatarGrid.dart';

import '../../Widgets/ImageAvatarGrid.dart';


class AnimatedAvatars extends StatelessWidget {
  const AnimatedAvatars();

  static const List<Map<String, dynamic>> _lottieAvatarItems = [
    {'lottie': 'assets/animations/AnimatedAvatars/CatCrying.json', 'cost': 800},
    {'lottie': 'assets/animations/AnimatedAvatars/CatLove.json', 'cost': 1000},
    {'lottie': 'assets/animations/AnimatedAvatars/CuteDogEat.json', 'cost': 1200},
    {'lottie': 'assets/animations/AnimatedAvatars/RabbitWithBall.json', 'cost': 1200},
    {'lottie': 'assets/animations/AnimatedAvatars/Smoothymon_typing.json', 'cost': 1300},
    {'lottie': 'assets/animations/AnimatedAvatars/CuteBearDancing.json', 'cost': 1500},
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


