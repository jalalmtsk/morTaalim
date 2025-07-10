import 'package:flutter/material.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';



class IndexStars extends StatelessWidget {

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
                  length: 2,
                  child: Column(
                    children: const [
                      TabBar(
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        indicatorColor: Colors.white,
                        tabs: [
                          Tab(text: 'Stars',),
                          Tab(text: 'Avatar'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            Center(child: Text('🎭 Stars', style: TextStyle(color: Colors.white))),
                            Center(child: Text('🎭 Lol', style: TextStyle(color: Colors.white))),
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



