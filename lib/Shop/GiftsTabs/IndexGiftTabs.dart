import 'package:flutter/material.dart';
import 'package:mortaalim/Shop/Tools/BuyTokens.dart';
import 'package:mortaalim/Shop/Tools/watchAdButton.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/widgets/SpinWheel/SpinTheWheel.dart';
import 'package:provider/provider.dart';


class IndexGiftsPage extends StatefulWidget {

  @override
  State<IndexGiftsPage> createState() => _IndexGiftsPageState();
}


class _IndexGiftsPageState extends State<IndexGiftsPage> {

  @override
  Widget build(BuildContext context) {
    final xpManager = Provider.of<ExperienceManager>(context, listen: false);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: DefaultTabController(
                  length: 2, // Number of gift categories
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.white60,
                        indicatorColor: Colors.white,
                        isScrollable: true,
                        tabs: [
                          Tab(text: tr(context).spinningWheel),
                          Tab(text: tr(context).spin),

                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            const SingleChildScrollView(child: SpinWheelPopup()),
                            SingleChildScrollView(child: BuyTokenWidget(xpManager: xpManager)),
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
