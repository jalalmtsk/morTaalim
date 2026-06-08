import 'package:flutter/cupertino.dart';

import '../../Widgets/ImageAvatarGrid.dart';


class FantasyAvatar extends StatelessWidget {
  const FantasyAvatar();

  static const List<Map<String, dynamic>> _imageAvatarItems = [
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy1.png', 'cost': 150},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy2.png', 'cost': 1500},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy3.png', 'cost': 150},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy4.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy5.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy6.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy7.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy8.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy9.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy10.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy11.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy12.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy13.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy14.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy15.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy16.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy17.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy18.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy19.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy20.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy21.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy22.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy23.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy24.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy25.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy26.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy27.png', 'cost': 300},
    {'image': 'assets/images/AvatarImage/FantasyAvatars/Fantasy28.png', 'cost': 300},



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
