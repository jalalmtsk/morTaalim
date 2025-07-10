import 'package:flutter/cupertino.dart';

import '../../Widgets/ImageAvatarGrid.dart';


class Babies extends StatelessWidget {
  const Babies();

  static const List<Map<String, dynamic>> _imageAvatarItems = [
    {'image': 'assets/images/AvatarImage/Avatar1.png', 'cost': 30},
    {'image': 'assets/images/AvatarImage/Avatar2.png', 'cost': 50},
    {'image': 'assets/images/AvatarImage/Avatar20.png', 'cost': 400},
    {'image': 'assets/images/AvatarImage/Avatar21.png', 'cost': 400},
    {'image': 'assets/images/AvatarImage/Avatar22.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/Avatar23.png', 'cost': 200},
    {'image': 'assets/images/AvatarImage/Avatar24.png', 'cost': 150},
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


class Babies_Funmoji extends StatelessWidget {
  const Babies_Funmoji();

  static const List<Map<String, dynamic>> _imageAvatarItems = [
    {'image': 'assets/images/AvatarImage/Avatar1.png', 'cost': 30},
    {'image': 'assets/images/AvatarImage/Avatar2.png', 'cost': 50},
    {'image': 'assets/images/AvatarImage/Avatar3.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/Avatar4.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/Avatar5.png', 'cost': 400},
    {'image': 'assets/images/AvatarImage/Avatar6.png', 'cost': 400},
    {'image': 'assets/images/AvatarImage/Avatar7.png', 'cost': 400},

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