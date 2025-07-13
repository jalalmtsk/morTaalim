import 'package:flutter/cupertino.dart';

import '../../Widgets/ImageAvatarGrid.dart';


class Beams extends StatelessWidget {
  const Beams();
  static const List<Map<String, dynamic>> _imageAvatarItems = [
    {'image': 'assets/images/AvatarImage/Beams/Beam1.jpg', 'cost': 250},
    {'image': 'assets/images/AvatarImage/Beams/Beam2.jpg', 'cost': 250},
    {'image': 'assets/images/AvatarImage/Beams/Beam3.jpg', 'cost': 250},
    {'image': 'assets/images/AvatarImage/Beams/Beam4.jpg', 'cost': 250},
    {'image': 'assets/images/AvatarImage/Beams/Beam5.jpg', 'cost': 250},
    {'image': 'assets/images/AvatarImage/Beams/Beam6.jpg', 'cost': 250},
    {'image': 'assets/images/AvatarImage/Beams/Beam7.jpg', 'cost': 250},
    {'image': 'assets/images/AvatarImage/Beams/Beam8.jpg', 'cost': 250},
    {'image': 'assets/images/AvatarImage/Beams/Beam9.jpg', 'cost': 250},
    {'image': 'assets/images/AvatarImage/Beams/Beam10.jpg', 'cost': 250},
    {'image': 'assets/images/AvatarImage/Beams/Beam11.jpg', 'cost': 250},
    {'image': 'assets/images/AvatarImage/Beams/Beam12.jpg', 'cost': 250},
    {'image': 'assets/images/AvatarImage/Beams/Beam13.jpg', 'cost': 250},
    {'image': 'assets/images/AvatarImage/Beams/Beam14.jpg', 'cost': 250},
    {'image': 'assets/images/AvatarImage/Beams/Beam15.jpg', 'cost': 500},
    {'image': 'assets/images/AvatarImage/Beams/Beam16.jpg', 'cost': 500},
    {'image': 'assets/images/AvatarImage/Beams/Beam17.jpg', 'cost': 500},
    {'image': 'assets/images/AvatarImage/Beams/Beam18.jpg', 'cost': 500},
    {'image': 'assets/images/AvatarImage/Beams/Beam19.jpg', 'cost': 500},
    {'image': 'assets/images/AvatarImage/Beams/Beam20.jpg', 'cost': 500},
    {'image': 'assets/images/AvatarImage/Beams/Beam21.jpg', 'cost': 500},
    {'image': 'assets/images/AvatarImage/Beams/Beam22.jpg', 'cost': 500},
    {'image': 'assets/images/AvatarImage/Beams/Beam23.jpg', 'cost': 500},
    {'image': 'assets/images/AvatarImage/Beams/Beam24.jpg', 'cost': 500},
    {'image': 'assets/images/AvatarImage/Beams/Beam25.jpg', 'cost': 500},
    {'image': 'assets/images/AvatarImage/Beams/Beam26.jpg', 'cost': 500},
    {'image': 'assets/images/AvatarImage/Beams/Beam27.jpg', 'cost': 1000},
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
