import 'package:flutter/material.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:mortaalim/tools/Ads_Manager.dart';
import 'package:provider/provider.dart';

import '../../XpSystem.dart';

import '../Widgets/avatarGrid.dart';
import '../Tools/_StarCounter.dart';
import '../Tools/_TokenAndSection.dart';
import 'IndexFunMojiPage/AvatarCrPage.dart';
import 'IndexFunMojiPage/BabiesPage.dart';
import 'IndexFunMojiPage/MojiPage.dart';

class IndexFunMojiPage extends StatelessWidget {

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
                          Tab(text: 'Moji',),
                          Tab(text: 'Avatar'),
                          Tab(text: 'Babies'),
                          Tab(text: 'SuperHero'),
                          Tab(text: 'Aliens'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            Moji(),  // 👈 You can define each tab's content
                            AvatarCr(),
                            Babies(),
                            Center(child: Text('🎭 Themes', style: TextStyle(color: Colors.white))),
                            Center(child: Text('🎭 Themes', style: TextStyle(color: Colors.white))),
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



