import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Widgets/BannerGrid.dart';

class FanBan extends StatelessWidget {
  const FanBan();

  static const List<Map<String, dynamic>> _banners = [
    {'image': 'assets/images/Banners/FantasyBanners/FanBan1.png','rarity' : 'rare', 'cost': 300},
    {'image': 'assets/images/Banners/FantasyBanners/FanBan2.png','rarity' : 'rare', 'cost': 300},
    {'image': 'assets/images/Banners/FantasyBanners/FanBan3.png','rarity' : 'rare', 'cost': 300},
    {'image': 'assets/images/Banners/FantasyBanners/FanBan4.png','rarity' : 'rare', 'cost': 300},
    {'image': 'assets/images/Banners/FantasyBanners/FanBan5.png','rarity' : 'rare', 'cost': 400},
    {'image': 'assets/images/Banners/FantasyBanners/FanBan6.png','rarity' : 'rare', 'cost': 450},
    {'image': 'assets/images/Banners/FantasyBanners/FanBan7.png','rarity' : 'rare', 'cost': 450},
    {'image': 'assets/images/Banners/FantasyBanners/FanBan8.png','rarity' : 'rare', 'cost': 800},
    {'image': 'assets/images/Banners/FantasyBanners/FanBan9.png','rarity' : 'rare', 'cost': 800},
    {'image': 'assets/images/Banners/FantasyBanners/FanBan10.png','rarity':'rare', 'cost': 1000},
    {'image': 'assets/images/Banners/FantasyBanners/FanBan11.png','rarity':'LEGENDARY', 'cost': 1000},
    {'image': 'assets/images/Banners/FantasyBanners/FanBan12.png','rarity':'LEGENDARY', 'cost': 1000},
    {'image': 'assets/images/Banners/FantasyBanners/FanBan13.png','rarity':'LEGENDARY', 'cost': 1000},
    {'image': 'assets/images/Banners/FantasyBanners/FanBan14.png','rarity':'LEGENDARY', 'cost': 1000},
    {'image': 'assets/images/Banners/FantasyBanners/FanBan15.png','rarity':'LEGENDARY', 'cost': 1000},
    {'image': 'assets/images/Banners/FantasyBanners/FanBan16.png','rarity':'LEGENDARY', 'cost': 1000},
    {'image': 'assets/images/Banners/FantasyBanners/FanBan17.png','rarity':'LEGENDARY', 'cost': 2000},

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ImageBannerGrid(banners: _banners),
    );
  }
}
