import 'package:flutter/material.dart';
import 'package:mortaalim/Shop/BannerTab/IndexBanner.dart';
import 'package:mortaalim/Shop/StarsTab/IndexStars.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';

import 'FunMojiTab/IndexFunMoji.dart';


class MainShopPageIndex extends StatelessWidget {
  const MainShopPageIndex({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // Total 5 tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🎁 SHOP'),
          backgroundColor: Colors.deepOrangeAccent,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.face_2_sharp), text: "FunMoji"),
              Tab(icon: Icon(Icons.filter_b_and_w_outlined), text: "Banner"),
              Tab(icon: Icon(Icons.token), text: "Stars/Tolims"),
              Tab(icon: Icon(Icons.card_giftcard), text: "Specials"),
              Tab(icon: Icon(Icons.info_outline), text: "Info"),
            ],),
        ),
        body: Column(
          children: [
            Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFff9966), Color(0xFFff5e62)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Userstatutbar()),
            Expanded(
              child: TabBarView(
                children: [
                  IndexFunMojiPage(),
                  IndexBanner(),
                  IndexStars(),
                  const Center(child: Text("🎮 Mini Games", style: TextStyle(fontSize: 18))),
                  const Center(child: Text("ℹ️ Information", style: TextStyle(fontSize: 18))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

