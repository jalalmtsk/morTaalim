import 'package:flutter/material.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/courses/primaire1Page/1_primairePage.dart';
import 'package:mortaalim/courses/primaire1Page/1_primairePratique.dart' hide Primaire1;
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../tools/audio_tool/Audio_Manager.dart';

class Index1Primaire extends StatefulWidget {
  const Index1Primaire({super.key});

  @override
  State<Index1Primaire> createState() => _Index1PrimaireState();
}


class _Index1PrimaireState extends State<Index1Primaire>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  Key _keyTab1 = UniqueKey();
  Key _keyTab2 = UniqueKey();
  Key _keyTab3 = UniqueKey();

  static const _titles = [
    'math',
    'french',
    'arabic',
    'islamicEducation',
    'artEducation',
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> resetAllProgress() async {
    final prefs = await SharedPreferences.getInstance();

    for (final title in _titles) {
      await prefs.remove('progress_$title');
      await prefs.remove('progress1_$title');
      await prefs.remove('progress2_$title');
    }

    setState(() {
      _keyTab1 = UniqueKey();
      _keyTab2 = UniqueKey();
      _keyTab3 = UniqueKey();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Tous les progrès ont été réinitialisés.'),
        backgroundColor: Colors.deepOrange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
final xpManager = ExperienceManager();
    const headerTextStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    );

    const tabLabelStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 16,
    );

    return DefaultTabController(
      length:
      2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Column(
          children: [

            Userstatutbar(),

            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        Expanded(
                          child: Text(
                            '1ère Année Primaire',
                            style: headerTextStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Invisible SizedBox for symmetry with back button
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TabBar(
                      labelColor: Colors.deepOrange,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.deepOrange,
                      indicatorWeight: 3,
                      labelStyle: tabLabelStyle,
                      tabs: const [
                        Tab(icon: Icon(Icons.menu_book), text: 'Cours'),
                        Tab(icon: Icon(Icons.track_changes_rounded), text: 'Exercices'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Pass null or actual experienceManager object if you have one
                  Primaire1(key: _keyTab1, experienceManager: xpManager),
                  Primaire1Pratique(key: _keyTab2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
