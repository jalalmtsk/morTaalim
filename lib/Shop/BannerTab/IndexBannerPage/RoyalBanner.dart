import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Widgets/BannerGrid.dart';

class RoyBan extends StatelessWidget {
  const RoyBan();

  static const List<Map<String, dynamic>> _banners = [
    {'image': 'assets/images/Banners/RoyalBanners/RoyBan1.png','rarity':'LEGENDARY', 'cost': 1000},
    {'image': 'assets/images/Banners/RoyalBanners/RoyBan2.png','rarity':'LEGENDARY', 'cost': 1000},
    {'image': 'assets/images/Banners/RoyalBanners/RoyBan3.png','rarity':'LEGENDARY', 'cost': 1000},
    {'image': 'assets/images/Banners/RoyalBanners/RoyBan4.png','rarity':'LEGENDARY', 'cost': 1000},
    {'image': 'assets/images/Banners/RoyalBanners/RoyBan5.png','rarity':'LEGENDARY', 'cost': 1000},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ImageBannerGrid(banners: _banners),
    );
  }
}
