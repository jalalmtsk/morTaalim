import 'package:flutter/material.dart';
import 'package:mortaalim/games/paitingGame/paintOnSketch/paintonSketchPage.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';

class SketchSelectorPage extends StatefulWidget {
  @override
  State<SketchSelectorPage> createState() => _SketchSelectorPageState();
}

class _SketchSelectorPageState extends State<SketchSelectorPage> {
  final List<Map<String, String>> sketches = [
    {'path': 'assets/images/Sketches/CuteBear_Sketch.jpg', 'name': 'Cute Bear'},
    {'path': 'assets/images/Sketches/CuteDog_Sketch.jpg', 'name': 'Cute Dog'},
    {'path': 'assets/images/Sketches/CuteGirl_Sketch.jpg', 'name': 'Cute Girl'},
    {'path': 'assets/images/Sketches/doll.jpg', 'name': 'Doll'},
    {'path': 'assets/images/Sketches/Girl.jpg', 'name': 'Girl'},
    {'path': 'assets/images/Sketches/Labubu.jpg', 'name': 'Labubu'},
    {'path': 'assets/images/Sketches/Parrot_sketch.jpg', 'name': 'Parrot'},
  ];

  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back button & summary
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      audioManager.playEventSound("cancelButton");
                      Navigator.pop(context);
                      },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.pinkAccent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pinkAccent.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                      shadowColor: Colors.pinkAccent.withOpacity(0.4),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.pinkAccent, Colors.orangeAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Sketches',
                                  style: TextStyle(
                                    fontFamily: 'ComicSansMS',
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${sketches.length}',
                                  style: TextStyle(
                                    fontFamily: 'ComicSansMS',
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.brush_rounded,
                              size: 48,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sketch Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  itemCount: sketches.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final sketch = sketches[index];
                    bool isSelected = _selectedIndex == index;
                    return GestureDetector(
                      onTapDown: (_) {
                        setState(() => _selectedIndex = index);
                      },
                      onTapUp: (_) async {
                        audioManager.playEventSound("clickButton");
                        await Future.delayed(const Duration(milliseconds: 150));
                        setState(() => _selectedIndex = -1);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                DrawingOnBackgroundPage(imageAssetPath:sketch['path']! ,),
                            transitionsBuilder: (_, animation, __, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: Colors.pinkAccent.withOpacity(0.6),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                              : [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Transform.scale(
                          scale: isSelected ? 1.05 : 1.0,
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 6,
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                Hero(
                                  tag: sketch['path']!,
                                  child: Image.asset(
                                    sketch['path']!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.pinkAccent.withOpacity(0.8),
                                          Colors.orangeAccent.withOpacity(0.8)
                                        ],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ),
                                      borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(20),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        sketch['name']!,
                                        style: const TextStyle(
                                          fontFamily: 'ComicSansMS',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
