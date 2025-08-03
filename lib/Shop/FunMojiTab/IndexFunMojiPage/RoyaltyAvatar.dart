import 'package:flutter/cupertino.dart';

import '../../Widgets/ImageAvatarGrid.dart';


class Royalties extends StatelessWidget {
  const Royalties();

  static const List<Map<String, dynamic>> _imageAvatarItems = [
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty1.webp', 'cost': 300},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty2.webp','cost': 300},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty3.webp','cost': 300},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty4.webp','cost': 300},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty5.webp','cost': 350},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty6.webp','cost': 400},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty8.webp','cost': 400},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty9.webp','cost': 500},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty10.webp','cost': 1000},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty11.webp','cost': 1000},
    {'image': 'assets/images/AvatarImage/RoyaltyAvatar/Royalty12.webp','cost': 1000},


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
