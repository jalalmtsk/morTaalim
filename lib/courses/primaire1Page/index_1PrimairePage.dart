import 'package:flutter/material.dart';
import 'package:mortaalim/courses/primaire1Page/1_primaireExamenPage.dart';
import 'package:mortaalim/courses/primaire1Page/1_primairePage.dart';

class index1Primaire extends StatefulWidget {
  const index1Primaire({super.key});

  @override
  State<index1Primaire> createState() => _index1PrimaireState();
}

class _index1PrimaireState extends State<index1Primaire> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.deepOrangeAccent,
          elevation: 2,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          title: const Text(
            '1ère Année Primaire',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(icon: Icon(Icons.menu_book), text: 'Cours'),
              Tab(icon: Icon(Icons.assignment), text: 'Examens'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            primaire1(),
            primaire1Exam(),
          ],
        ),
      ),
    );
  }
}
