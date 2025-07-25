import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Widgets/BannerGrid.dart';

class Cartoon extends StatelessWidget {
  const Cartoon();

  static const List<Map<String, dynamic>> _banners = [
    {'image': 'assets/images/Banners/Joyful/Joyful1.png', 'cost': 100},
    {'image': 'assets/images/Banners/Joyful/Joyful2.png', 'cost': 120},
    {'image': 'assets/images/Banners/Joyful/Joyful3.png', 'cost': 150},
    {'image': 'assets/images/Banners/Joyful/Joyful4.png', 'cost': 200},
    {'image': 'assets/images/Banners/Joyful/Joyful5.png', 'cost': 2500},
    {'image': 'assets/images/Banners/Joyful/Joyful6.png', 'cost': 300},
    {'image': 'assets/images/Banners/Joyful/Joyful7.png', 'cost': 300},
    {'image': 'assets/images/Banners/Joyful/Joyful8.png', 'cost': 400},
    {'image': 'assets/images/Banners/Joyful/Joyful9.png', 'cost': 400},
    {'image': 'assets/images/Banners/Joyful/Joyful10.png', 'cost': 400},
    {'image': 'assets/images/Banners/Joyful/Joyful11.png', 'cost': 500},
    {'image': 'assets/images/Banners/Joyful/Joyful12.png', 'cost': 500},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ImageBannerGrid(banners: _banners),
    );
  }
}
