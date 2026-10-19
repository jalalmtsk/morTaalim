import 'package:flutter/material.dart';

import '../../../Manager/models/banner_catalog.dart';
import '../Widgets/BannerGrid.dart';

/// Shop → Banners. One grid fed by [BannerCatalog] (new banners get added there).
class IndexBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFff9966), Color(0xFFff5e62)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const SafeArea(
          child: ImageBannerGrid(banners: BannerCatalog.shop),
        ),
      ),
    );
  }
}
