import 'package:flutter/material.dart';
import 'package:mortaalim/courses/primaire1Page/1_primaireExamenPage.dart';
import 'package:mortaalim/courses/primaire1Page/1_primairePage.dart';
import 'package:mortaalim/courses/primaire2Page/2_primaire.dart';
import 'package:mortaalim/courses/primaire3Page/3_primaire.dart';
import 'package:mortaalim/tools/HomeCourse.dart';


class index1Primaire extends StatefulWidget {
  const index1Primaire({super.key});

  @override
  State<index1Primaire> createState() => _index1PrimaireState();
}

class _index1PrimaireState extends State<index1Primaire> {

  List page = [
    Center(child: Text("ENter 1")),
    Center(child: Text("What"),)
  ];
  int currentPage = 0;

  onTap(int index){
    setState(() {
      currentPage = index!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
            bottom:  TabBar(tabs: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Tab(text: "Cours",icon: Icon(Icons.note), ),
              ),
              Tab(text: "Examens",),
            ])
        ),

        body: Column(
          children: [
            Expanded(
              child: TabBarView(children: [

                primaire1(),
                primaire1Exam(),
              ]),
            ),
          ],
        ),


      ),
    );
  }
}
