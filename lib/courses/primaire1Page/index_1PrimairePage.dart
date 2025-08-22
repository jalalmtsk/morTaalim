import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/courses/primaire1Page/1_primairePage.dart';
import 'package:mortaalim/courses/primaire1Page/1_primairePratique.dart' hide Primaire1;
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';

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
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    const headerTextStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      shadows: [Shadow(blurRadius: 3, color: Colors.black54)],
    );

    const tabLabelStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 16,
    );

    return DefaultTabController(
      length: 2,
      child: Builder(builder: (context) {
        final TabController tabController = DefaultTabController.of(context)!;

        tabController.addListener(() {
          if (!tabController.indexIsChanging) return;
          audioManager.playEventSound('clickButton');
        });

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/UI/BackGrounds/bg2.jpg',
                  fit: BoxFit.cover,
                ),
              ),

              // Blurred overlay for entire page
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.black.withOpacity(0.25)),
                ),
              ),

              Column(
                children: [
                  // User status bar with blur
         Userstatutbar(),
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              color: Colors.black.withOpacity(0.25),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back,
                                            color: Colors.deepOrange),
                                        onPressed: () {
                                          audioManager.playEventSound('cancelButton');
                                          Navigator.pop(context);
                                        },
                                      ),
                                      Expanded(
                                        child: Text(
                                          tr(context).class1,
                                          style: headerTextStyle,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(width: 48),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Blurred TabBar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                      child: Container(
                                        color: Colors.black.withOpacity(0.3),
                                        child: TabBar(
                                          indicatorSize: TabBarIndicatorSize.tab,
                                          indicator: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.8),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          labelColor: Colors.deepOrange,
                                          unselectedLabelColor: Colors.white70,
                                          indicatorColor: Colors.deepOrange,
                                          indicatorWeight: 3,
                                          labelStyle: tabLabelStyle,
                                          tabs: [
                                            Tab(icon: const Icon(Icons.menu_book), text: tr(context).courses),
                                             Tab(
                                                icon: Icon(Icons.track_changes_rounded),
                                                text: tr(context).exercices),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: TabBarView(
                      children: [
                        Primaire1(key: _keyTab1, experienceManager: xpManager),
                        Primaire1Pratique(key: _keyTab2),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}
