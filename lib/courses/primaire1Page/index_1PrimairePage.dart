import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/courses/primaire1Page/1_primairePratique.dart' hide Primaire1;
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/ComingSoonNotPage.dart';
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
    'math', 'french', 'arabic', 'islamicEducation', 'artEducation',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
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
    if (!mounted) return;
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
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    return DefaultTabController(
      length: 2,
      child: Builder(builder: (context) {
        final tabController = DefaultTabController.of(context)!;
        tabController.addListener(() {
          if (!tabController.indexIsChanging) return;
          audioManager.playEventSound('clickButton');
        });

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // ── Background ──────────────────────────────────
              Positioned.fill(
                child: Image.asset(
                  'assets/images/UI/BackGrounds/bg2.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.black.withOpacity(0.30)),
                ),
              ),

              // ── Content ─────────────────────────────────────
              SafeArea(
                child: Column(
                  children: [
                    // Status bar (XP, coins, etc.)
                    const Userstatutbar(),

                    // Header + tabs (animated)
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _Header(audioManager: audioManager),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tab content
                    Expanded(
                      child: TabBarView(
                        children: [
                          Primaire1Pratique(key: _keyTab2),
                           ComingSoonNotPage(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Header: back button + title + tab bar — all in one compact card
// ─────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final AudioManager audioManager;
  const _Header({required this.audioManager});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: Colors.white.withOpacity(0.08),
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Back + Title row ──
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: Colors.deepOrange),
                      onPressed: () {
                        audioManager.playEventSound('cancelButton');
                        Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: Text(
                        tr(context).class1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    // Mirror of back button to keep title centered
                    const SizedBox(width: 40),
                  ],
                ),

                // ── Tab bar ──
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.deepOrange,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    tabs: [
                      Tab(
                        iconMargin: const EdgeInsets.only(bottom: 2),
                        icon: const Icon(Icons.track_changes_rounded, size: 18),
                        text: tr(context).exercices,
                      ),
                      Tab(
                        iconMargin: const EdgeInsets.only(bottom: 2),
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        text: tr(context).courses,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}