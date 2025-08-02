import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Widgets/BannerGrid.dart';

class Cartoon extends StatelessWidget {
  const Cartoon();

  static const List<Map<String, dynamic>> _banners = [
    {'image': 'assets/images/Banners/Joyful/Joyful1.png', 'cost': 100},

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ImageBannerGrid(banners: _banners),
    );
  }
}
