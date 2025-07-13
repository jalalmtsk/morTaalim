import 'package:flutter/cupertino.dart';

import '../../Widgets/ImageAvatarGrid.dart';


class Aliens extends StatelessWidget {
  const Aliens();

  static const List<Map<String, dynamic>> _imageAvatarItems = [
    {'image': 'assets/images/AvatarImage/Aliens/Alien1.png', 'cost': 45},
    {'image': 'assets/images/AvatarImage/Aliens/Alien2.png', 'cost': 50},
    {'image': 'assets/images/AvatarImage/Aliens/Alien3.png', 'cost': 50},
    {'image': 'assets/images/AvatarImage/Aliens/Alien4.png', 'cost': 50},
    {'image': 'assets/images/AvatarImage/Aliens/Alien5.png', 'cost': 80},
    {'image': 'assets/images/AvatarImage/Aliens/Alien6.png', 'cost': 80},
    {'image': 'assets/images/AvatarImage/Aliens/Alien7.png', 'cost': 80},
    {'image': 'assets/images/AvatarImage/Aliens/Alien8.png', 'cost': 80},
    {'image': 'assets/images/AvatarImage/Aliens/Alien9.png', 'cost': 80},
    {'image': 'assets/images/AvatarImage/Aliens/Alien10.png', 'cost': 80},
    {'image': 'assets/images/AvatarImage/Aliens/Alien11.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/Aliens/Alien12.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/Aliens/Alien13.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/Aliens/Alien14.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/Aliens/Alien15.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/Aliens/Alien16.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/Aliens/Alien17.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/Aliens/Alien18.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/Aliens/Alien19.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/Aliens/Alien20.png', 'cost': 250},
    {'image': 'assets/images/AvatarImage/Aliens/Alien21.png', 'cost': 250},
    {'image': 'assets/images/AvatarImage/Aliens/Alien22.png', 'cost': 250},
    {'image': 'assets/images/AvatarImage/Aliens/Alien23.png', 'cost': 250},
    {'image': 'assets/images/AvatarImage/Aliens/Alien24.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/Aliens/Alien25.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/Aliens/Alien26.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/Aliens/Alien27.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/Aliens/Alien28.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/Aliens/Alien29.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/Aliens/Alien29.png', 'cost': 350},
    {'image': 'assets/images/AvatarImage/Aliens/Alien30.png', 'cost': 350},
    {'image': 'assets/images/AvatarImage/Aliens/Alien31.png', 'cost': 350},
    {'image': 'assets/images/AvatarImage/Aliens/Alien32.png', 'cost': 350},
    {'image': 'assets/images/AvatarImage/Aliens/Alien33.png', 'cost': 500},
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
        child: ImageAvatarGrid(imageAvatars: _imageAvatarItems),
      ),
    );
  }
}
