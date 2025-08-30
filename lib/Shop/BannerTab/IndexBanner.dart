import 'package:flutter/material.dart';
import 'package:mortaalim/Shop/BannerTab/IndexBannerPage/RoyalBanner.dart';
import 'package:mortaalim/Shop/BannerTab/IndexBannerPage/CuteBr.dart';
import 'package:mortaalim/Shop/BannerTab/IndexBannerPage/Islamic.dart';
import 'package:mortaalim/Shop/BannerTab/IndexBannerPage/Sci_Fi.dart';

import '../../main.dart';
import 'IndexBannerPage/Fantasy.dart';

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
        child: SafeArea(
          child: Column(
            children: [
              // 👇👇👇 TAB BAR SECTION HERE
              Expanded(
                child: DefaultTabController(
                  length: 5,
                  child: Column(
                    children:  [
                      TabBar(
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        indicatorColor: Colors.white,
                        tabs: [
                          Tab(text: tr(context).cute),
                          Tab(text: tr(context).royalty),
                          Tab(text: tr(context).sciFi),
                          Tab(text: tr(context).fantasy),
                          Tab(text: tr(context).islamic),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            Cutebr(),
                            RoyBan(),
                            SciFi(),
                            FanBan(),
                            Islamic(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



