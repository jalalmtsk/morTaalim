import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/games/BrainBuilder/bb_common.dart' show BBTitle, BBPill, bbCream, bbInk;
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

import 'puzzle_land_game.dart';
import 'pz_common.dart';

/// Puzzle Land home: every picture with its Easy / Medium / Hard progress.
class PuzzleLandMenu extends StatefulWidget {
  const PuzzleLandMenu({super.key});

  @override
  State<PuzzleLandMenu> createState() => _PuzzleLandMenuState();
}

class _PuzzleLandMenuState extends State<PuzzleLandMenu> with SingleTickerProviderStateMixin {
  Map<String, List<int>> _stars = {for (final p in pzPictures) p: [0, 0, 0]};
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final p in pzPictures) {
      precacheImage(AssetImage(PZAssets.picture(p)), context);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await PZProgress.load();
    if (mounted) setState(() => _stars = s);
  }

  /// Next difficulty to play on a picture (or the hardest when all done).
  int _nextDiff(String pic) {
    final s = _stars[pic]!;
    for (var d = 0; d < pzGrid.length; d++) {
      if (s[d] == 0) return d;
    }
    return pzGrid.length - 1;
  }

  Future<void> _open(String pic, int d) async {
    if (!PZProgress.unlocked(_stars, pic, d)) {
      _audio.playEventSound('invalid');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: KidColors.purpleDeep,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Text(pzT(context, 'lockedMsg'), style: kidBodyStyle(15, color: Colors.white, weight: FontWeight.w600)),
        ));
      return;
    }
    _audio.playEventSound('PopButton');
    (String, int)? next = (pic, d);
    while (next != null && mounted) {
      final (p, diff) = next;
      final r = await Navigator.push<(String, int)>(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, __, ___) => PuzzleLandGame(picture: p, difficulty: diff),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        ),
      );
      await _load();
      next = r;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _stars.values.fold<int>(0, (a, l) => a + l.fold<int>(0, (x, y) => x + y));
    final maxStars = pzPictures.length * pzGrid.length * 3;
    return Scaffold(
      backgroundColor: const Color(0xFF8FD3FF),
      body: Stack(children: [
        Positioned.fill(child: Image.asset(PZAssets.bg, fit: BoxFit.cover)),
        SafeArea(
          child: LayoutBuilder(builder: (context, c) {
            final width = min(c.maxWidth, 600.0);
            final s = (width / 400).clamp(0.8, 1.35).toDouble();
            return Center(
              child: SizedBox(
                width: width,
                child: Column(children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(12 * s, 6 * s, 12 * s, 4 * s),
                    child: Row(children: [
                      KidPressable(
                        onTap: () {
                          _audio.playEventSound('cancelButton');
                          Navigator.maybePop(context);
                        },
                        child: Transform.flip(
                          flipX: Directionality.of(context) == TextDirection.rtl,
                          child: Image.asset(PZAssets.back, width: 50 * s, height: 50 * s),
                        ),
                      ),
                      Expanded(
                        child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: BBTitle(pzT(context, 'title'), size: 32 * s))),
                      ),
                      BBPill(
                        height: 44 * s,
                        padding: EdgeInsets.symmetric(horizontal: 10 * s),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Image.asset(PZAssets.star, width: 24 * s, height: 24 * s),
                          SizedBox(width: 4 * s),
                          Text('$total/$maxStars', style: kidBodyStyle(14 * s, color: bbInk, weight: FontWeight.w700)),
                        ]),
                      ),
                    ]),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 2 * s, bottom: 6 * s),
                    padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 5 * s),
                    decoration: BoxDecoration(color: const Color(0xFFEDE6FF).withOpacity(0.94), borderRadius: BorderRadius.circular(20)),
                    child: Text(pzT(context, 'choose'), style: kidBodyStyle(15 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)),
                  ),
                  Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(14 * s, 4 * s, 14 * s, 24 * s),
                      itemCount: pzPictures.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12 * s,
                        crossAxisSpacing: 12 * s,
                        childAspectRatio: 0.74,
                      ),
                      itemBuilder: (_, i) => _card(pzPictures[i], s, i),
                    ),
                  ),
                ]),
              ),
            );
          }),
        ),
      ]),
    );
  }

  Widget _card(String pic, double s, int i) {
    final st = _stars[pic]!;
    final done = st.every((v) => v > 0);
    return KidPressable(
      pressedScale: 0.95,
      onTap: () => _open(pic, _nextDiff(pic)),
      child: Container(
        padding: EdgeInsets.all(7 * s),
        decoration: BoxDecoration(
          color: bbCream,
          borderRadius: BorderRadius.circular(24 * s),
          border: Border.all(color: done ? const Color(0xFFFFC21A) : Colors.white, width: 3),
          boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.16), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Column(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18 * s),
              child: Stack(fit: StackFit.expand, children: [
                Image.asset(PZAssets.picture(pic), fit: BoxFit.cover),
                if (st[0] == 0)
                  Positioned(
                    right: 6 * s,
                    bottom: 6 * s,
                    child: AnimatedBuilder(
                      animation: _idle,
                      builder: (_, c) => Transform.scale(scale: 1 + 0.08 * sin(_idle.value * 2 * pi + i), child: c),
                      child: Container(
                        padding: EdgeInsets.all(6 * s),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        child: Icon(Icons.extension_rounded, color: KidColors.purple, size: 20 * s),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
          SizedBox(height: 6 * s),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(pzT(context, 'pic_$pic'), maxLines: 1, style: kidBodyStyle(15 * s, color: bbInk, weight: FontWeight.w700)),
          ),
          SizedBox(height: 5 * s),
          Row(children: [
            for (var d = 0; d < pzGrid.length; d++) ...[
              if (d > 0) SizedBox(width: 4 * s),
              Expanded(child: _diffChip(pic, d, s)),
            ],
          ]),
        ]),
      ),
    );
  }

  Widget _diffChip(String pic, int d, double s) {
    final stars = _stars[pic]![d];
    final open = PZProgress.unlocked(_stars, pic, d);
    const colors = [
      [Color(0xFF7EE08A), Color(0xFF2FB45A)],
      [Color(0xFFFFCF4D), Color(0xFFFF9A1A)],
      [Color(0xFFFF8FB8), Color(0xFFE2489A)],
    ];
    return KidPressable(
      onTap: () => _open(pic, d),
      child: Container(
        height: 36 * s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12 * s),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: open ? colors[d] : const [Color(0xFFE2DDF0), Color(0xFFC9C1E0)],
          ),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: open
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${pzGrid[d]}×${pzGrid[d]}', style: kidBodyStyle(11.5 * s, color: Colors.white, weight: FontWeight.w700).copyWith(height: 1)),
                SizedBox(height: 2 * s),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < 3; i++)
                    Image.asset(i < stars ? PZAssets.star : PZAssets.starOff, width: 10 * s, height: 10 * s),
                ]),
              ])
            : Icon(Icons.lock_rounded, color: Colors.white, size: 16 * s),
      ),
    );
  }
}
