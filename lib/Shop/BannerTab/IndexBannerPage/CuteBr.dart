import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Widgets/BannerGrid.dart';

class Cutebr extends StatelessWidget {
  const Cutebr();

  static const List<Map<String, dynamic>> _banners = [
    {'image': 'assets/images/Banners/CuteBr/Banner1.png','rarity': 'COMMON', 'cost': 30},
    {'image': 'assets/images/Banners/CuteBr/Banner2.png', 'cost': 35},
    {'image': 'assets/images/Banners/CuteBr/Banner3.png', 'cost': 40},
    {'image': 'assets/images/Banners/CuteBr/Banner4.png', 'cost': 45},
    {'image': 'assets/images/Banners/CuteBr/Banner5.png', 'cost': 50},
    {'image': 'assets/images/Banners/CuteBr/Banner6.png', 'cost': 50},
    {'image': 'assets/images/Banners/CuteBr/Banner7.png', 'cost': 80},
    {'image': 'assets/images/Banners/CuteBr/Banner8.png', 'cost': 100},
    {'image': 'assets/images/Banners/CuteBr/Banner9.png', 'cost': 120},
    {'image': 'assets/images/Banners/CuteBr/Banner10.png', 'cost': 120},
    {'image': 'assets/images/Banners/CuteBr/Banner11.png', 'cost': 120},
    {'image': 'assets/images/Banners/CuteBr/Banner12.png', 'cost': 120},
    {'image': 'assets/images/Banners/CuteBr/Banner13.png', 'cost': 120},
    {'image': 'assets/images/Banners/CuteBr/Banner14.png', 'cost': 120},
    {'image': 'assets/images/Banners/CuteBr/Banner15.png', 'cost': 120},
    {'image': 'assets/images/Banners/CuteBr/Banner16.png', 'cost': 300},
    {'image': 'assets/images/Banners/CuteBr/Banner17.png','rarity': 'COMMON', 'cost': 300},
    {'image': 'assets/images/Banners/Joyful/Joyful1.png','rarity': 'RARE', 'cost': 100},
    {'image': 'assets/images/Banners/Joyful/Joyful2.png','rarity': 'RARE',  'cost': 120},
    {'image': 'assets/images/Banners/Joyful/Joyful3.png','rarity': 'RARE',  'cost': 150},
    {'image': 'assets/images/Banners/Joyful/Joyful4.png','rarity': 'RARE',  'cost': 200},
    {'image': 'assets/images/Banners/Joyful/Joyful5.png','rarity': 'RARE',  'cost': 250},
    {'image': 'assets/images/Banners/Joyful/Joyful6.png','rarity': 'RARE',  'cost': 300},
    {'image': 'assets/images/Banners/Joyful/Joyful7.png','rarity': 'RARE',  'cost': 300},
    {'image': 'assets/images/Banners/Joyful/Joyful8.png','rarity': 'RARE',  'cost': 400},
    {'image': 'assets/images/Banners/Joyful/Joyful9.png','rarity': 'RARE',  'cost': 400},
    {'image': 'assets/images/Banners/Joyful/Joyful10.png','rarity': 'RARE',  'cost': 400},
    {'image': 'assets/images/Banners/Joyful/Joyful11.png','rarity': 'RARE',  'cost': 500},
    {'image': 'assets/images/Banners/Joyful/Joyful12.png','rarity': 'RARE',  'cost': 500},

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ImageBannerGrid(banners: _banners),
    );
  }
}
