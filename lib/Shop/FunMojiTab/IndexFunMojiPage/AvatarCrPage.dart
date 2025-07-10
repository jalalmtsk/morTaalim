import 'package:flutter/cupertino.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';

import '../../Widgets/ImageAvatarGrid.dart';



class AvatarCr extends StatelessWidget {
  const AvatarCr();

  static const List<Map<String, dynamic>> _imageAvatarItems = [
    {'image': 'assets/images/AvatarImage/Avatar1.png', 'cost': 30},
    {'image': 'assets/images/AvatarImage/Avatar2.png', 'cost': 50},
    {'image': 'assets/images/AvatarImage/Avatar3.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/Avatar4.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/Avatar5.png', 'cost': 400},
    {'image': 'assets/images/AvatarImage/Avatar6.png', 'cost': 400},
    {'image': 'assets/images/AvatarImage/Avatar7.png', 'cost': 400},
    {'image': 'assets/images/AvatarImage/Avatar8.png', 'cost': 400},
    {'image': 'assets/images/AvatarImage/Avatar9.png', 'cost': 400},
    {'image': 'assets/images/AvatarImage/Avatar10.png', 'cost': 400},
    {'image': 'assets/images/AvatarImage/Avatar11.png', 'cost': 400},
    {'image': 'assets/images/AvatarImage/Avatar12.png', 'cost': 400},
    {'image': 'assets/images/AvatarImage/Avatar13.png', 'cost': 400},
    {'image': 'assets/images/AvatarImage/Avatar14.png', 'cost': 400},
    {'image': 'assets/images/AvatarImage/Avatar15.png', 'cost': 400},
    {'image': 'assets/images/AvatarImage/Avatar16.png', 'cost': 400},
    {'image': 'assets/images/AvatarImage/Avatar17.png', 'cost': 400},
    {'image': 'assets/images/AvatarImage/Avatar18.png', 'cost': 400},
    {'image': 'assets/images/AvatarImage/Avatar19.png', 'cost': 400},
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
        child: Column(
          children: [
            Expanded(child: ImageAvatarGrid(imageAvatars: _imageAvatarItems)),
          ],
        ),
      ),
    );
  }
}

