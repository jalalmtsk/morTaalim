import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';

import 'paintonSketchPage.dart';

// ─────────────────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────────────────
class _SketchItem {
  final String path;
  final String name;
  final String emoji;
  final String category;
  const _SketchItem(this.path, this.name, this.emoji, this.category);
}

const _sketches = [
  _SketchItem('assets/images/Sketches/CuteBear_Sketch.jpg',  'Cute Bear',  '🐻', 'Animals'),
  _SketchItem('assets/images/Sketches/CuteDog_Sketch.jpg',   'Cute Dog',   '🐶', 'Animals'),
  _SketchItem('assets/images/Sketches/Parrot_sketch.jpg',    'Parrot',     '🦜', 'Animals'),
  _SketchItem('assets/images/Sketches/CuteGirl_Sketch.jpg',  'Cute Girl',  '👧', 'People'),
  _SketchItem('assets/images/Sketches/Girl.jpg',             'Girl',       '👩', 'People'),
  _SketchItem('assets/images/Sketches/doll.jpg',             'Doll',       '🪆', 'People'),
  _SketchItem('assets/images/Sketches/Labubu.jpg',           'Labubu',     '🧸', 'Fantasy'),
];

const _categories = ['All', 'Animals', 'People', 'Fantasy'];

// ─────────────────────────────────────────────────────────
//  PAGE
// ─────────────────────────────────────────────────────────
class SketchSelectorPage extends StatefulWidget {
  const SketchSelectorPage({Key? key}) : super(key: key);

  @override
  State<SketchSelectorPage> createState() => _SketchSelectorPageState();
}

class _SketchSelectorPageState extends State<SketchSelectorPage>
    with SingleTickerProviderStateMixin {
  String _activeCategory = 'All';
  int _pressedIndex = -1;
  late AnimationController _headerAnim;
  late Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _headerAnim.forward();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  List<_SketchItem> get _filtered => _activeCategory == 'All'
      ? _sketches
      : _sketches.where((s) => s.category == _activeCategory).toList();

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioManager>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────
          SliverToBoxAdapter(
            child: SafeArea(
              child: FadeTransition(
                opacity: _headerFade,
                child: _buildHeader(context, audio),
              ),
            ),
          ),

          // ── Category Chips ───────────────────────────────
          SliverToBoxAdapter(child: _buildCategoryRow()),

          // ── Grid ─────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final sketch = _filtered[index];
                  return _SketchCard(
                    sketch: sketch,
                    isPressed: _pressedIndex == index,
                    staggerIndex: index,
                    onTapDown: () => setState(() => _pressedIndex = index),
                    onTapUp: () async {
                      audio.playEventSound('clickButton');
                      await Future.delayed(const Duration(milliseconds: 120));
                      setState(() => _pressedIndex = -1);
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 400),
                          pageBuilder: (_, __, ___) =>
                              DrawingOnBackgroundPage(imageAssetPath: sketch.path),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                        ),
                      );
                    },
                  );
                },
                childCount: _filtered.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.82,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AudioManager audio) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              audio.playEventSound('cancelButton');
              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6584),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6584).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6584), Color(0xFFFFCC02)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6584).withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pick a Sketch!',
                        style: TextStyle(
                          fontFamily: 'ComicSansMS',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Color it your way ✨',
                        style: TextStyle(
                          fontFamily: 'ComicSansMS',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_filtered.length} 🖼️',
                      style: const TextStyle(
                        fontFamily: 'ComicSansMS',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final isActive = cat == _activeCategory;
          return GestureDetector(
            onTap: () => setState(() => _activeCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF6C63FF) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? const Color(0xFF6C63FF) : const Color(0xFFDDDDDD),
                  width: 1.5,
                ),
                boxShadow: isActive
                    ? [const BoxShadow(color: Color(0x556C63FF), blurRadius: 8)]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                style: TextStyle(
                  fontFamily: 'ComicSansMS',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : const Color(0xFF555555),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  SKETCH CARD
// ─────────────────────────────────────────────────────────
class _SketchCard extends StatefulWidget {
  final _SketchItem sketch;
  final bool isPressed;
  final int staggerIndex;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  const _SketchCard({
    required this.sketch,
    required this.isPressed,
    required this.staggerIndex,
    required this.onTapDown,
    required this.onTapUp,
  });

  @override
  State<_SketchCard> createState() => _SketchCardState();
}

class _SketchCardState extends State<_SketchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = Tween<double>(begin: 0.75, end: 1.0)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutBack));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: 80 * widget.staggerIndex), () {
      if (mounted) _anim.forward();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, _) => FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: GestureDetector(
            onTapDown: (_) => widget.onTapDown(),
            onTapUp: (_) => widget.onTapUp(),
            onTapCancel: () {},
            child: AnimatedScale(
              scale: widget.isPressed ? 0.94 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isPressed
                          ? const Color(0xFFFF6584).withOpacity(0.4)
                          : Colors.black.withOpacity(0.12),
                      blurRadius: widget.isPressed ? 20 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // image
                      Hero(
                        tag: widget.sketch.path,
                        child: Image.asset(
                          widget.sketch.path,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Color(0xCC000000)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(widget.sketch.emoji,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.sketch.name,
                                  style: const TextStyle(
                                    fontFamily: 'ComicSansMS',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // category badge
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.sketch.category,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6C63FF),
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
    );
  }
}