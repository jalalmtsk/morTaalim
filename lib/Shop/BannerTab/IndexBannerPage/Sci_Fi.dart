import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Widgets/BannerGrid.dart';

class SciFi extends StatelessWidget {
  const SciFi();

  static const List<Map<String, dynamic>> _banners = [
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci1.webp', 'cost': 30},
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci2.png', 'cost': 30},
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci3.png', 'cost': 30},
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci4.png', 'cost': 30},
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci5.png', 'cost': 30},
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci6.png', 'cost': 30},
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci7.png', 'cost': 30},
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci8.png', 'cost': 30},
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci9.png', 'cost': 30},
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci10.png', 'cost': 30},
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci11.png', 'cost': 30},
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci12.png', 'cost': 30},
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci13.png', 'cost': 30},
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci14.png', 'cost': 30},
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci15.png', 'cost': 30},
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci16.png', 'cost': 30},
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci17.png', 'cost': 30},
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci18.png', 'cost': 30},
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci19.png', 'cost': 30},
    {'image': 'assets/images/Banners/Sci_FI_Banners/Sci20.webp', 'cost': 30},


  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ImageBannerGrid(banners: _banners),
    );
  }
}
