import 'package:flutter/material.dart';
import 'package:mortaalim/Shop/BannerTab/IndexBannerPage/Joyful.dart';
import 'package:mortaalim/Shop/BannerTab/IndexBannerPage/CuteBr.dart';
import 'package:mortaalim/Shop/BannerTab/IndexBannerPage/Islamic.dart';
import 'package:mortaalim/Shop/BannerTab/IndexBannerPage/Sci_Fi.dart';

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
                    children: const [
                      TabBar(
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        indicatorColor: Colors.white,
                        tabs: [
                          Tab(text: 'CuteBr',),
                          Tab(text: 'Joyful'),
                          Tab(text: 'Sci-Fi'),
                          Tab(text: 'Fantasy'),
                          Tab(text: 'Islamic'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            Cutebr(),
                            Cartoon(),
                            SciFi(),
                            Center(child: Text('🎭 Lol', style: TextStyle(color: Colors.white))),
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



