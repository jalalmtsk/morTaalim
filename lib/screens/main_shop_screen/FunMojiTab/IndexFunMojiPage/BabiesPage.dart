import 'package:flutter/cupertino.dart';

import '../../Widgets/ImageAvatarGrid.dart';


class Babies extends StatelessWidget {
  const Babies();

  static const List<Map<String, dynamic>> _imageAvatarItems = [
    {'image': 'assets/images/AvatarImage/Babies/baby1.png', 'cost': 50},
    {'image': 'assets/images/AvatarImage/Babies/baby2.png', 'cost': 50},
    {'image': 'assets/images/AvatarImage/Babies/baby3.png', 'cost': 50},
    {'image': 'assets/images/AvatarImage/Babies/baby4.png', 'cost': 50},
    {'image': 'assets/images/AvatarImage/Babies/baby5.png', 'cost': 50},
    {'image': 'assets/images/AvatarImage/Babies/baby6.png', 'cost': 50},
    {'image': 'assets/images/AvatarImage/Babies/baby7.png', 'cost': 50},
    {'image': 'assets/images/AvatarImage/Babies/baby8.png', 'cost': 80},
    {'image': 'assets/images/AvatarImage/Babies/baby9.png', 'cost': 80},
    {'image': 'assets/images/AvatarImage/Babies/baby10.png', 'cost': 80},
    {'image': 'assets/images/AvatarImage/Babies/baby11.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/Babies/baby12.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/Babies/baby13.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/Babies/baby14.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/Babies/baby15.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/Babies/baby16.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/Babies/baby17.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/Babies/baby18.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/Babies/baby19.png', 'cost': 150},
    {'image': 'assets/images/AvatarImage/Babies/baby20.png', 'cost': 150},
    {'image': 'assets/images/AvatarImage/Babies/baby21.png', 'cost': 200},
    {'image': 'assets/images/AvatarImage/Babies/baby22.png', 'cost': 200},
    {'image': 'assets/images/AvatarImage/Babies/baby23.png', 'cost': 200},

  ];
  @override
  Widget build(BuildContext context) {
    return Container(
      child: SafeArea(
        child: ImageAvatarGrid(imageAvatars: _imageAvatarItems),
      ),
    );
  }
}
