import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Widgets/BannerGrid.dart';

class Islamic extends StatelessWidget {
  const Islamic();

  static const List<Map<String, dynamic>> _banners = [
    {'image': 'assets/images/Banners/Islamic/Islamic1.png', 'cost': 30},
    {'image': 'assets/images/Banners/Islamic/Islamic2.png', 'cost': 30},
    {'image': 'assets/images/Banners/Islamic/Islamic3.png', 'cost': 30},
    {'image': 'assets/images/Banners/Islamic/Islamic4.png', 'cost': 30},
    {'image': 'assets/images/Banners/Islamic/Islamic5.png', 'cost': 30},
    {'image': 'assets/images/Banners/Islamic/Islamic6.png', 'cost': 30},
    {'image': 'assets/images/Banners/Islamic/Islamic7.png', 'cost': 30},
    {'image': 'assets/images/Banners/Islamic/Islamic8.png', 'cost': 30},
    {'image': 'assets/images/Banners/Islamic/Islamic9.png', 'cost': 30},
    {'image': 'assets/images/Banners/Islamic/Islamic10.png', 'cost': 30},
    {'image': 'assets/images/Banners/Islamic/Islamic11.png', 'cost': 30},
    {'image': 'assets/images/Banners/Islamic/Islamic12.png', 'cost': 30},
    {'image': 'assets/images/Banners/Islamic/Islamic13.png', 'cost': 30},
    {'image': 'assets/images/Banners/Islamic/Islamic14.png', 'cost': 30},
    {'image': 'assets/images/Banners/Islamic/Islamic15.png', 'cost': 30},
    {'image': 'assets/images/Banners/Islamic/Islamic16.png', 'cost': 30},


  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ImageBannerGrid(banners: _banners),
    );
  }
}
