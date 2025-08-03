import 'package:flutter/cupertino.dart';

import '../../Widgets/ImageAvatarGrid.dart';


class FantasyAvatar extends StatelessWidget {
  const FantasyAvatar();

  static const List<Map<String, dynamic>> _imageAvatarItems = [
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty1.webp','rarity':'RARE', 'cost': 300},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty2.webp','rarity':'RARE', 'cost': 300},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty3.webp','rarity':'RARE', 'cost': 300},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty4.webp','rarity':'RARE', 'cost': 300},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty5.webp','rarity':'RARE', 'cost': 350},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty6.webp','rarity':'RARE', 'cost': 400},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty8.webp','rarity':'RARE', 'cost': 400},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty9.webp','rarity':'RARE', 'cost': 500},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty10.webp','rarity':'LEGENDARY', 'cost': 1000},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty11.webp','rarity':'LEGENDARY', 'cost': 1000},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty12.webp','rarity':'LEGENDARY', 'cost': 1000},


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
