import 'package:flutter/material.dart';
import 'package:mortaalim/games/paitingGame/paintOnSketch/SketchSelectorIndex.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/userStatutBar.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import 'drawing_exercice.dart';
import 'paint_main.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const DrawingIndex();
}

class DrawingIndex extends StatefulWidget {
  const DrawingIndex({Key? key}) : super(key: key);

  @override
  State<DrawingIndex> createState() => _DrawingIndexState();
}

class _DrawingIndexState extends State<DrawingIndex>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _anims;

  final _modes = const [
    _ModeData(
      emoji: '🎨',
      titleKey: 'freeDrawing',
      descKey: 'drawWhateverYouLike',
      icon: Icons.brush_rounded,
      gradient: [Color(0xFFFF6584), Color(0xFFFF9A44)],
    ),
    _ModeData(
      emoji: '🖼️',
      titleKey: 'paintOnSketches',
      descKey: 'colorBeautifulTemplates',
      icon: Icons.image_rounded,
      gradient: [Color(0xFF6C63FF), Color(0xFF3F8EFC)],
    ),
    _ModeData(
      emoji: '✏️',
      titleKey: 'exercises',
      descKey: 'stepByStepExercises',
      icon: Icons.school_rounded,
      gradient: [Color(0xFF43E97B), Color(0xFF38F9D7)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anims = List.generate(
      _modes.length,
          (i) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(i * 0.18, 0.7 + i * 0.1, curve: Curves.easeOutBack),
      ),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioManager>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      body: SafeArea(
        child: Column(
          children: [
            Userstatutbar(),
            // Back button row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      audio.playEventSound('cancelButton');
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.arrow_back_ios_new,
                          size: 20, color: Colors.orange.shade700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '🎨 Art Studio',
                    style: TextStyle(
                      fontFamily: 'ComicSansMS',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),

            // Title banner
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFCC02), Color(0xFFFF9A44)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x44FFCC02),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Text(
                      'What would you like to do?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'ComicSansMS',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pick your adventure below! 🚀',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'ComicSansMS',
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mode cards
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _modes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (ctx, i) {
                  final mode = _modes[i];
                  return ScaleTransition(
                    scale: _anims[i],
                    child: FadeTransition(
                      opacity: _anims[i],
                      child: _ModeCard(
                        data: mode,
                        onTap: () {
                          audio.playEventSound('clickButton');
                          _navigate(context, i);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    Widget page;
    switch (index) {
      case 0:
        page = DrawingApp();
        break;
      case 1:
        page =  SketchSelectorPage();
        break;
      case 2:
      default:
        page = const DrawingExercisesPage();
        break;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

// ─────────────────────────────────────────────────────────
//  DATA + CARD
// ─────────────────────────────────────────────────────────
class _ModeData {
  final String emoji;
  final String titleKey;
  final String descKey;
  final IconData icon;
  final List<Color> gradient;
  const _ModeData({
    required this.emoji,
    required this.titleKey,
    required this.descKey,
    required this.icon,
    required this.gradient,
  });
}

class _ModeCard extends StatefulWidget {
  final _ModeData data;
  final VoidCallback onTap;
  const _ModeCard({required this.data, required this.onTap});

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _pressed = false;

  // Simple title / desc mapping (replace with tr(context) localisation calls)
  static const _titles = {
    'freeDrawing': 'Free Drawing',
    'paintOnSketches': 'Paint on Sketches',
    'exercises': 'Drawing Exercises',
  };
  static const _descs = {
    'drawWhateverYouLike': 'Draw whatever you like!',
    'colorBeautifulTemplates': 'Color beautiful templates',
    'stepByStepExercises': 'Step-by-step art lessons for kids',
  };

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: d.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: d.gradient.first.withOpacity(0.4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon circle
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(d.emoji, style: const TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titles[d.titleKey] ?? d.titleKey,
                      style: const TextStyle(
                        fontFamily: 'ComicSansMS',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _descs[d.descKey] ?? d.descKey,
                      style: const TextStyle(
                        fontFamily: 'ComicSansMS',
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white70, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}