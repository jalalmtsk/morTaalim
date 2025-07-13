import 'package:flutter/material.dart';
import 'package:mortaalim/Shop/FunMojiTab/IndexFunMojiPage/Aliens.dart';
import 'package:mortaalim/Shop/FunMojiTab/IndexFunMojiPage/AnimatedAvatars.dart';
import 'package:mortaalim/Shop/FunMojiTab/IndexFunMojiPage/Beams.dart';
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
                  length: 6,
                  child: Column(
                    children: const [
                      TabBar(
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.white60,
                        indicatorColor: Colors.white,
                        isScrollable: true,

                        tabs: [
                          Tab(text: 'Avatar'),
                          Tab(text: 'Beams',),
                          Tab(text: 'Moji',),
                          Tab(text: 'Babies'),
                          Tab(text: 'Aliens'),
                          Tab(text: 'Animated'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            AvatarCr(),
                            Beams(),
                            Moji(),  // 👈 You can define each tab's content
                            Babies(),
                            Aliens(),
                            AnimatedAvatars(),
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



