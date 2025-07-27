import 'package:flutter/material.dart';
import 'package:mortaalim/courses/primaire1Page/1_primaireExamenPage.dart';
import 'package:mortaalim/courses/primaire1Page/1_primairePage.dart';
import 'package:mortaalim/courses/primaire1Page/1_primairePratique.dart';
import 'package:mortaalim/tools/audio_tool.dart';
import 'package:shared_preferences/shared_preferences.dart';

class index1Primaire extends StatefulWidget {
  const index1Primaire({super.key});

  @override
  State<index1Primaire> createState() => _index1PrimaireState();
}

final MusicPlayer backGroundIndexMusic = MusicPlayer();

class _index1PrimaireState extends State<index1Primaire>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  Key _keyTab1 = UniqueKey();
  Key _keyTab2 = UniqueKey();
  Key _keyTab3 = UniqueKey();

  Future<void> resetAllProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> titles = [
      'math',
      'french',
      'arabic',
      'islamicEducation',
      'artEducation'
    ];

    for (String title in titles) {
      await prefs.remove('progress_$title');
      await prefs.remove('progress1_$title');
      await prefs.remove('progress2_$title');
    }

    setState(() {
      _keyTab1 = UniqueKey(); // force primaire1 to rebuild
      _keyTab2 = UniqueKey(); // force primaire1Pratique to rebuild
      _keyTab3 = UniqueKey(); // force primaire1Exam to rebuild
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Tous les progrès ont été réinitialisés.'),
        backgroundColor: Colors.deepOrange,
        duration: Duration(seconds: 2),
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    backGroundIndexMusic.play("assets/audios/sound_track/SugarSprinkle_BcG.mp3", loop: true);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
    backGroundIndexMusic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Column(
          children: [
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:  [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon:  Icon(Icons.arrow_back, color: Colors.deepOrange),
                            onPressed: () {
                              backGroundIndexMusic.stop();
                              Navigator.pop(context);}
                          ),
                          Text(
                            '1ère Année Primaire',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 48), // same width as back button for balance
                        ],
                      ),
                      SizedBox(height: 16),
                      TabBar(
                        labelColor: Colors.deepOrange,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.deepOrange,
                        indicatorWeight: 2.5,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        tabs: [
                          Tab(icon: Icon(Icons.menu_book), text: 'Cours'),
                          Tab(icon: Icon(Icons.assignment), text: 'Examens'),
                          Tab(icon: Icon(Icons.track_changes_rounded), text: 'Exercices'),

                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  primaire1(key: _keyTab1),
                  primaire1Exam(key: _keyTab3),
                  Primaire1Pratique(key: _keyTab2),

                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text("Réinitialiser tous les progrès"),
                content: Text("Êtes-vous sûr de vouloir supprimer tous les progrès des cours et examens ?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Annuler"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      resetAllProgress();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                    child: Text("Réinitialiser"),
                  ),
                ],
              ),
            );
          },
          label: Text("Réinitialiser tout"),
          icon: Icon(Icons.refresh),
          backgroundColor: Colors.deepOrange,
        ),

      ),

    );

  }
}