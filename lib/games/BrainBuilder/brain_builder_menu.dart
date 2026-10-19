import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

import 'bb_common.dart';
import 'bb_engine.dart';
import 'brain_builder_game.dart';

/// Brain Builder home: cover art, "play" shortcut and the 3 worlds × 10 levels map.
class BrainBuilderMenu extends StatefulWidget {
  const BrainBuilderMenu({super.key});

  @override
  State<BrainBuilderMenu> createState() => _BrainBuilderMenuState();
}

class _BrainBuilderMenuState extends State<BrainBuilderMenu> with SingleTickerProviderStateMixin {
  List<int> _stars = List.filled(bbLevelCount, 0);
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  static const _worldColors = [
    [Color(0xFF7EE08A), Color(0xFF2FB45A)],
    [Color(0xFFFF9BD0), Color(0xFFE2489A)],
    [Color(0xFF8BE3FF), Color(0xFF2A9BEA)],
  ];

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final a in BBAssets.all) {
      precacheImage(AssetImage(a), context);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await BBProgress.allStars();
    if (mounted) setState(() => _stars = s);
  }

  bool _unlocked(int n) => n == 1 || _stars[n - 2] > 0;

  int get _nextLevel {
    for (var n = 1; n <= bbLevelCount; n++) {
      if (_stars[n - 1] == 0) return n;
    }
    return bbLevelCount;
  }

  Future<void> _open(int n) async {
    _audio.playEventSound('PopButton');
    int? next = n;
    while (next != null && mounted) {
      final level = next;
      final r = await Navigator.push<int>(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, __, ___) => BrainBuilderGame(level: level),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        ),
      );
      await _load();
      next = (r != null && r <= bbLevelCount) ? r : null;
    }
  }

  void _lockedTap() {
    _audio.playEventSound('invalid');
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: KidColors.purpleDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(bbT(context, 'lockedMsg'), style: kidBodyStyle(15, color: Colors.white, weight: FontWeight.w600)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final total = _stars.fold<int>(0, (a, b) => a + b);
    return Scaffold(
      backgroundColor: const Color(0xFF8FD3FF),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(BBAssets.bg, fit: BoxFit.cover)),
          Positioned.fill(child: ColoredBox(color: Colors.white.withOpacity(0.12))),
          SafeArea(
            child: LayoutBuilder(builder: (context, c) {
              final width = min(c.maxWidth, 560.0);
              final s = (width / 400).clamp(0.8, 1.3).toDouble();
              return Center(
                child: SizedBox(
                  width: width,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(12 * s, 6 * s, 12 * s, 4 * s),
                        child: Row(
                          children: [
                            BBSpriteButton(
                              asset: BBAssets.back,
                              size: 50 * s,
                              flipRtl: true,
                              label: MaterialLocalizations.of(context).backButtonTooltip,
                              onTap: () {
                                _audio.playEventSound('cancelButton');
                                Navigator.maybePop(context);
                              },
                            ),
                            Expanded(
                              child: Center(
                                child: FittedBox(fit: BoxFit.scaleDown, child: BBTitle(bbT(context, 'title'), size: 32 * s)),
                              ),
                            ),
                            BBPill(
                              height: 44 * s,
                              padding: EdgeInsets.symmetric(horizontal: 10 * s),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Image.asset(BBAssets.star, width: 26 * s, height: 26 * s),
                                SizedBox(width: 4 * s),
                                Text('$total/${bbLevelCount * 3}',
                                    style: kidBodyStyle(15 * s, color: bbInk, weight: FontWeight.w700)),
                              ]),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(16 * s, 6 * s, 16 * s, 28 * s),
                          children: [
                            _hero(s),
                            for (var w = 0; w < 3; w++) _world(w, s),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _hero(double s) {
    final next = _nextLevel;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28 * s),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24 * s),
        child: AspectRatio(
          aspectRatio: 1.5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(BBAssets.cover, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.55, 1],
                    colors: [Colors.transparent, const Color(0xFF2A1366).withOpacity(0.45)],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 12 * s,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _idle,
                    builder: (_, c) => Transform.scale(scale: 1 + 0.03 * sin(_idle.value * 2 * pi), child: c),
                    child: KidButton(
                      label: '${bbT(context, 'play')} · ${bbT(context, 'levelN', {'n': next})}',
                      width: 240 * s,
                      height: 56 * s,
                      onPressed: () => _open(next),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _world(int w, double s) {
    final first = w * bbLevelsPerWorld + 1;
    final mode = BBMode.values[w];
    final got = _stars.sublist(first - 1, first - 1 + bbLevelsPerWorld).fold<int>(0, (a, b) => a + b);
    final colors = _worldColors[w];
    final icon = switch (w) {
      0 => Image.asset(BBAssets.robot, fit: BoxFit.contain),
      1 => Image.asset(BBAssets.star, fit: BoxFit.contain),
      _ => const FittedBox(child: Icon(Icons.ac_unit_rounded, color: Colors.white)),
    };
    return Container(
      margin: EdgeInsets.only(top: 16 * s),
      padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 14 * s, 16 * s),
      decoration: BoxDecoration(
        color: bbCream.withOpacity(0.95),
        borderRadius: BorderRadius.circular(26 * s),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.16), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 50 * s,
                height: 50 * s,
                padding: EdgeInsets.all(7 * s),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: icon,
              ),
              SizedBox(width: 10 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bbT(context, 'world${w + 1}'), style: kidBodyStyle(20 * s, color: bbInk, weight: FontWeight.w700)),
                    Text(bbT(context, 'goal_${mode.name}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: kidBodyStyle(13 * s, color: KidColors.muted, weight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
                decoration: BoxDecoration(color: const Color(0xFFF1ECFF), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Image.asset(BBAssets.star, width: 20 * s, height: 20 * s),
                  SizedBox(width: 3 * s),
                  Text('$got/${bbLevelsPerWorld * 3}', style: kidBodyStyle(14 * s, color: bbInk, weight: FontWeight.w700)),
                ]),
              ),
            ],
          ),
          SizedBox(height: 14 * s),
          LayoutBuilder(builder: (_, c) {
            const perRow = 5;
            final gap = 10 * s;
            final size = (c.maxWidth - gap * (perRow - 1)) / perRow;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [for (var n = first; n < first + bbLevelsPerWorld; n++) _tile(n, size)],
            );
          }),
        ],
      ),
    );
  }

  Widget _tile(int n, double size) {
    final st = _stars[n - 1];
    final open = _unlocked(n);
    final current = open && st == 0;
    final colors = !open
        ? const [Color(0xFFDDD7EE), Color(0xFFBFB6DA)]
        : st > 0
            ? const [Color(0xFFA57BFF), Color(0xFF6A2EE8)]
            : const [Color(0xFFFFCF4D), Color(0xFFFF9A1A)];
    Widget body = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: colors.last.withOpacity(0.45), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (open)
            Text('$n',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.36,
                  height: 1,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black.withOpacity(0.25), blurRadius: 3, offset: const Offset(0, 2))],
                ))
          else
            Icon(Icons.lock_rounded, color: Colors.white, size: size * 0.38),
          if (open) ...[
            SizedBox(height: size * 0.06),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [for (var i = 0; i < 3; i++) BBStar(on: i < st, size: size * 0.2)],
            ),
          ],
        ],
      ),
    );
    if (current) {
      body = AnimatedBuilder(
        animation: _idle,
        builder: (_, c) => Transform.scale(scale: 1 + 0.06 * sin(_idle.value * 2 * pi), child: c),
        child: body,
      );
    }
    return KidPressable(
      onTap: () => open ? _open(n) : _lockedTap(),
      semanticLabel: bbT(context, 'levelN', {'n': n}),
      child: body,
    );
  }
}
