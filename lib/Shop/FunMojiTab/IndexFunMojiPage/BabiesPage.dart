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
      child: SafeArea(
        child: ImageAvatarGrid(imageAvatars: _imageAvatarItems),
      ),
    );
  }
}
