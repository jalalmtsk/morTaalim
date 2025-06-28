import 'package:flutter/material.dart';
import 'package:mortaalim/courses/primaire1Page/1_primaireExamenPage.dart';
import 'package:mortaalim/courses/primaire1Page/1_primairePage.dart';
import 'package:mortaalim/courses/primaire2Page/2_primaire.dart';
import 'package:mortaalim/courses/primaire2Page/2_primaireExamenPage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class index2Primaire extends StatefulWidget {
  const index2Primaire({super.key});

  @override
  State<index2Primaire> createState() => _index2PrimaireState();
}

class _index2PrimaireState extends State<index2Primaire> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.teal,
          elevation: 2,
          shape:  RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          title:  Text(
            "${AppLocalizations.of(context)!.class2}",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
            primaire2(),
            primaire2Exam(),
          ],
        ),
      ),
    );
  }
}
