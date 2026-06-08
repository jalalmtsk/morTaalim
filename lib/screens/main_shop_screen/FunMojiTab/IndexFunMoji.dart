import 'package:flutter/material.dart';



import '../../../main.dart';
import '../Widgets/avatarGrid.dart';
import '../Tools/_StarCounter.dart';
import '../Tools/_TokenAndSection.dart';
import 'IndexFunMojiPage/Aliens.dart';
import 'IndexFunMojiPage/AnimatedAvatars.dart';
import 'IndexFunMojiPage/AvatarCrPage.dart';
import 'IndexFunMojiPage/BabiesPage.dart';
import 'IndexFunMojiPage/Beams.dart';
import 'IndexFunMojiPage/FantasyAvatar.dart';
import 'IndexFunMojiPage/MojiPage.dart';
import 'IndexFunMojiPage/RoyaltyAvatar.dart';

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
                  length: 8,
                  child: Column(
                    children:  [
                      TabBar(
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.white60,
                        indicatorColor: Colors.white,
                        isScrollable: true,

                        tabs: [
                          Tab(text: tr(context).avatar),
                          Tab(text: tr(context).beams),
                          Tab(text: tr(context).moji),
                          Tab(text: tr(context).royalty),
                          Tab(text: tr(context).babies),
                          Tab(text: tr(context).fantasy),
                          Tab(text: tr(context).aliens),
                          Tab(text: tr(context).animated),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            AvatarCr(),
                            Beams(),
                            Moji(),  // 👈 You can define each tab's content
                            Royalties(),
                            Babies(),
                            FantasyAvatar(),
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



