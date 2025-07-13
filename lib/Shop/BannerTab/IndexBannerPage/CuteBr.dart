import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Widgets/BannerGrid.dart';

class Cutebr extends StatelessWidget {
  const Cutebr();

  static const List<Map<String, dynamic>> _banners = [
    {'image': 'assets/images/Banners/CuteBr/Banner1.png', 'cost': 30},
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
    {'image': 'assets/images/Banners/CuteBr/Banner17.png', 'cost': 300},


  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ImageBannerGrid(banners: _banners),
    );
  }
}
