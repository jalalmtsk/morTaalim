import 'package:flutter/cupertino.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';

import '../../Widgets/ImageAvatarGrid.dart';



class AvatarCr extends StatelessWidget {
  const AvatarCr();

  static const List<Map<String, dynamic>> _imageAvatarItems = [
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar1.png', 'cost': 50},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar2.png', 'cost': 50},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar3.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar4.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar5.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar6.png', 'cost': 100},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar7.png', 'cost': 250},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar8.png', 'cost': 250},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar9.png', 'cost': 250},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar10.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar11.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar12.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar13.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar14.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar15.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar16.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar17.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar18.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar19.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar20.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar21.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar22.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar23.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/OnlyAvatar/Avatar24.png', 'cost': 300},

  ];
  @override
  Widget build(BuildContext context) {
    return Container(
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

