import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_page_parts.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryAssets {
  MemoryAssets._();
  static const String dir = 'assets/images/UI/KidScene/';
  static const String bg = '${dir}it_page_bg.webp';
  static const String sound = '${dir}mm_sound.webp';
  static const String back = '${dir}mm_card_back.webp';
  static const String face = '${dir}mm_card_face.webp';
  static const String star = '${dir}mm_star.webp';
  static const String restart = '${dir}mm_restart.webp';
  static const String bulb = '${dir}mm_bulb.webp';
  static const String coin = '${dir}mm_coin.webp';

  static const List<String> pictures = [
    'fox', 'robot', 'panda', 'elephant', 'lion', 'dragon', 'owl', 'duck', 'turtle',
    'bunny', 'apple', 'banana', 'strawberry', 'rainbow', 'rocket', 'train', 'butterfly', 'fish',
  ];
  static String picture(String id) => '${dir}mm_$id.webp';

  static List<String> get all => [bg, sound, back, face, star, restart, bulb, coin, for (final p in pictures) picture(p)];
}

/// Level → board size. Grows gently, then stays at 12 pairs.
class _LevelSpec {
  final int pairs, cols;
  const _LevelSpec(this.pairs, this.cols);
  int get rows => pairs * 2 ~/ cols;
  static _LevelSpec of(int level) => switch (level) {
        1 => const _LevelSpec(3, 3),
        2 => const _LevelSpec(6, 3),
        3 => const _LevelSpec(8, 4),
        4 => const _LevelSpec(10, 4),
        _ => const _LevelSpec(12, 4),
      };
}

class _Card {
  final String picture;
  bool open = false, matched = false;
  _Card(this.picture);
}

/// "Memory Match" (shown as "Retour de mémoire" in French): flip two cards,
/// find the pairs. Levels grow from 3 to 12 pairs; each win gives gold.
class MemoryMatchPage extends StatefulWidget {
  const MemoryMatchPage({super.key});

  @override
  State<MemoryMatchPage> createState() => _MemoryMatchPageState();
}

class _MemoryMatchPageState extends State<MemoryMatchPage> with TickerProviderStateMixin {
  static const _kLevel = 'memory_match_level';
  static const int _hintsPerLevel = 3;

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  final _rnd = Random();

  int _level = 1;
  List<_Card> _cards = [];
  final List<int> _picked = [];
  int _moves = 0, _hints = _hintsPerLevel;
  bool _busy = true; // blocks taps during preview / flip-back
  bool _precached = false;
  int _shake = -1; // index of a wrong card (wiggle)
  Timer? _timer;

  _LevelSpec get _spec => _LevelSpec.of(_level);
  int get _found => _cards.where((c) => c.matched).length ~/ 2;
  int get _reward => min(40, 10 + _level * 5);
  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      _level = max(1, p.getInt(_kLevel) ?? 1);
      if (mounted) _newGame();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      KidAssets.precache(context, [...MemoryAssets.all, KidAssets.backBtn]);
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  /// Deal a fresh board and show every card for a moment ("look, remember").
  void _newGame() {
    _timer?.cancel();
    final pics = [...MemoryAssets.pictures]..shuffle(_rnd);
    final chosen = pics.take(_spec.pairs);
    setState(() {
      _cards = [for (final p in chosen) ...[_Card(p), _Card(p)]]..shuffle(_rnd);
      for (final c in _cards) {
        c.open = true;
      }
      _picked.clear();
      _moves = 0;
      _hints = _hintsPerLevel;
      _busy = true;
    });
    _timer = Timer(Duration(milliseconds: 1200 + _spec.pairs * 180), () {
      if (!mounted) return;
      setState(() {
        for (final c in _cards) {
          c.open = false;
        }
        _busy = false;
      });
    });
  }

  void _tap(int i) {
    final c = _cards[i];
    if (_busy || c.open || c.matched || _picked.length >= 2) return;
    _audio.playEventSound('clickButton2');
    setState(() {
      c.open = true;
      _picked.add(i);
    });
    if (_picked.length < 2) return;

    _moves++;
    final a = _cards[_picked[0]], b = _cards[_picked[1]];
    if (a.picture == b.picture) {
      _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory1_SFX.mp3');
      setState(() {
        a.matched = b.matched = true;
        _picked.clear();
      });
      if (_cards.every((c) => c.matched)) _win();
    } else {
      _busy = true;
      final wrong = _picked[1];
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) setState(() => _shake = wrong);
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        _audio.playEventSound('invalid');
        setState(() {
          a.open = b.open = false;
          _picked.clear();
          _shake = -1;
          _busy = false;
        });
      });
    }
  }

  /// Hint: peek at all hidden cards for a second.
  void _hint() {
    if (_busy || _hints == 0 || _cards.every((c) => c.matched)) {
      if (_hints == 0) _audio.playEventSound('invalid');
      return;
    }
    _audio.playEventSound('toggleButton');
    final hidden = [for (int i = 0; i < _cards.length; i++) if (!_cards[i].open && !_cards[i].matched) i];
    setState(() {
      _hints--;
      _busy = true;
      for (final i in hidden) {
        _cards[i].open = true;
      }
    });
    _timer = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        for (final i in hidden) {
          if (!_picked.contains(i)) _cards[i].open = false;
        }
        _busy = false;
      });
    });
  }

  int get _stars {
    final p = _spec.pairs;
    if (_moves <= (p * 1.5).ceil()) return 3;
    if (_moves <= (p * 2.2).ceil()) return 2;
    return 1;
  }

  Future<void> _win() async {
    final stars = _stars;
    final reward = _reward;
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3');
    xp.addTokenBanner(context, reward);
    xp.addXP(10, context: context);
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kLevel, _level + 1);
    if (!mounted) return;
    final next = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: KidColors.purpleDeep.withOpacity(0.4),
      builder: (ctx) => KidDialog(
        title: tr(ctx).mmWellDone,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (int i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.only(left: 4, right: 4, bottom: i == 1 ? 14 : 0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + i * 250),
                  curve: Curves.easeOutBack,
                  builder: (_, v, c) => Transform.scale(scale: v, child: c),
                  child: Opacity(
                    opacity: i < stars ? 1 : 0.25,
                    child: Image.asset(MemoryAssets.star, width: i == 1 ? 64 : 50, height: i == 1 ? 64 : 50),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 10),
          Text(tr(ctx).mmMovesN(_moves), style: kidBodyStyle(16, color: KidColors.inkSoft, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset(MemoryAssets.coin, width: 30, height: 30),
            const SizedBox(width: 6),
            Text('+$reward', style: kidBodyStyle(22, color: KidColors.ink, weight: FontWeight.w700)),
          ]),
        ]),
        actions: [
          KidOutlineButton(label: tr(ctx).mmReplay, onTap: () => Navigator.pop(ctx, false)),
          KidButton(
            label: tr(ctx).mmNextLevel,
            width: double.infinity,
            height: 54,
            showArrow: false,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (next == true) _level++;
    _newGame();
  }

  @override
  Widget build(BuildContext context) {
    final audio = Provider.of<AudioManager>(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 600.0) - 28;
    final s = (w / 380).clamp(0.8, 1.4);
    final t = tr(context);
    final spec = _spec;

    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.08 * i, to: min(1.0, 0.5 + 0.08 * i), rise: 20, child: child);

    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(children: [
        const Positioned.fill(child: KidPageBackground(asset: MemoryAssets.bg, wash: 0.04)),
        SafeArea(
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                const SizedBox(height: 6),
                // Title row
                step(
                  0,
                  SizedBox(
                    height: 56 * s,
                    child: Row(children: [
                      KidBackButton(
                        size: 50 * s,
                        onTap: () {
                          audio.playEventSound('cancelButton');
                          Navigator.of(context).maybePop();
                        },
                      ),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(t.memoryFlip, maxLines: 1, style: kidTitleStyle(34 * s)),
                        ),
                      ),
                      KidPressable(
                        onTap: () {
                          audio.playEventSound('toggleButton');
                          audio.toggleSfxMute();
                        },
                        semanticLabel: t.soundEffects,
                        child: Stack(alignment: Alignment.center, children: [
                          Opacity(
                            opacity: audio.isSfxMuted ? 0.5 : 1,
                            child: Image.asset(MemoryAssets.sound, width: 50 * s, height: 50 * s),
                          ),
                          if (audio.isSfxMuted)
                            Transform.rotate(
                              angle: -0.8,
                              child: Container(
                                  width: 42 * s,
                                  height: 4 * s,
                                  decoration:
                                      BoxDecoration(color: const Color(0xFFE11D48), borderRadius: BorderRadius.circular(4))),
                            ),
                        ]),
                      ),
                    ]),
                  ),
                ),
                SizedBox(height: 8 * s),
                // Status pill
                step(1, _StatusBar(scale: s, level: _level, found: _found, pairs: spec.pairs, reward: _reward)),
                SizedBox(height: 10 * s),
                step(
                  2,
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 22 * s, vertical: 8 * s),
                    decoration: kidCardDecoration(30 * s, shadow: 0.15),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(t.mmFindPairs, maxLines: 1, style: kidBodyStyle(19 * s, color: KidColors.ink, weight: FontWeight.w700)),
                    ),
                  ),
                ),
                SizedBox(height: 12 * s),
                // Board
                Expanded(
                  child: step(
                    3,
                    LayoutBuilder(builder: (context, c) {
                      final framePad = 14 * s;
                      final gap = 10 * s;
                      final maxW = c.maxWidth - framePad * 2 - 4;
                      final maxH = c.maxHeight - framePad * 2 - 4;
                      final cell = min(
                        (maxW - gap * (spec.cols - 1)) / spec.cols,
                        (maxH - gap * (spec.rows - 1)) / spec.rows,
                      ).clamp(30.0, 150.0);
                      // +4: the cream panel's 2px border on each side
                      final boardW = cell * spec.cols + gap * (spec.cols - 1) + framePad * 2 + 4;
                      final boardH = cell * spec.rows + gap * (spec.rows - 1) + framePad * 2 + 4;
                      return Center(
                        child: Container(
                          width: boardW,
                          height: boardH,
                          padding: EdgeInsets.all(framePad - 6 * s),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30 * s),
                            gradient: const LinearGradient(
                                begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA36BFF), Color(0xFF7B3FE4)]),
                            boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
                          ),
                          child: Container(
                            padding: EdgeInsets.all(6 * s),
                            decoration: BoxDecoration(
                              color: KidColors.cream,
                              borderRadius: BorderRadius.circular(24 * s),
                              border: Border.all(color: const Color(0xFFEFE2C8), width: 2),
                            ),
                            child: Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                for (int i = 0; i < _cards.length; i++)
                                  SizedBox(
                                    width: cell,
                                    height: cell,
                                    child: _MemoryCard(
                                      key: ValueKey('$_level-$i-${_cards[i].picture}'),
                                      card: _cards[i],
                                      shake: _shake == i,
                                      idle: _idle,
                                      phase: i * 0.07,
                                      onTap: () => _tap(i),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(height: 10 * s),
                step(
                  4,
                  Column(children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 40 * s, vertical: 6 * s),
                      decoration: kidCardDecoration(30 * s, shadow: 0.12),
                      child: Text(t.mmMovesN(_moves), style: kidBodyStyle(19 * s, color: KidColors.ink, weight: FontWeight.w700)),
                    ),
                    SizedBox(height: 4 * s),
                    Text(t.mmTagline,
                        style: kidBodyStyle(15 * s, color: KidColors.ink, weight: FontWeight.w700)
                            .copyWith(shadows: [Shadow(color: Colors.white.withOpacity(0.9), blurRadius: 8)])),
                  ]),
                ),
                SizedBox(height: 10 * s),
                step(
                  5,
                  Row(children: [
                    Expanded(
                      child: KidPressable(
                        onTap: () {
                          audio.playEventSound('clickButton');
                          _newGame();
                        },
                        pressedScale: 0.95,
                        semanticLabel: t.mmRestart,
                        child: Container(
                          height: 60 * s,
                          padding: EdgeInsets.symmetric(horizontal: 14 * s),
                          decoration: kidCardDecoration(34 * s, shadow: 0.2),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Image.asset(MemoryAssets.restart, width: 40 * s, height: 40 * s),
                            SizedBox(width: 8 * s),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(t.mmRestart, style: kidBodyStyle(20 * s, color: KidColors.ink, weight: FontWeight.w700)),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    Expanded(
                      child: KidPressable(
                        onTap: _hint,
                        pressedScale: 0.95,
                        semanticLabel: t.mmHint,
                        child: Opacity(
                          opacity: _hints > 0 ? 1 : 0.55,
                          child: Stack(clipBehavior: Clip.none, children: [
                            Container(
                              height: 60 * s,
                              padding: EdgeInsets.symmetric(horizontal: 14 * s),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(34 * s),
                                gradient: const LinearGradient(
                                    begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFE45C), Color(0xFFFFC21A)]),
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFFD08A00), offset: Offset(0, 3 * s)),
                                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: Offset(0, 6 * s)),
                                ],
                              ),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                AnimatedBuilder(
                                  animation: _idle,
                                  builder: (_, ch) => Transform.rotate(angle: sin(_idle.value * 6 * pi) * 0.08, child: ch),
                                  child: Image.asset(MemoryAssets.bulb, width: 30 * s, height: 30 * s * 1.44),
                                ),
                                SizedBox(width: 8 * s),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(t.mmHint, style: kidBodyStyle(22 * s, color: KidColors.ink, weight: FontWeight.w700)),
                                  ),
                                ),
                              ]),
                            ),
                            PositionedDirectional(
                              top: -8 * s,
                              end: -2 * s,
                              child: Container(
                                width: 30 * s,
                                height: 30 * s,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(colors: [Color(0xFF9B5CFF), Color(0xFF6A2BE0)]),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Text('$_hints', style: kidBodyStyle(15 * s, color: Colors.white, weight: FontWeight.w700)),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                ),
                SizedBox(height: 8 * s + (pad.bottom > 0 ? 0 : 6)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final double scale;
  final int level, found, pairs, reward;
  const _StatusBar({required this.scale, required this.level, required this.found, required this.pairs, required this.reward});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    Widget divider() => Container(width: 1.5, height: 30 * s, margin: EdgeInsets.symmetric(horizontal: 8 * s), color: const Color(0xFFE5D7BD));
    return Container(
      height: 56 * s,
      padding: EdgeInsets.symmetric(horizontal: 10 * s),
      decoration: kidCardDecoration(32 * s, shadow: 0.15),
      child: Row(children: [
        Expanded(
          flex: 5,
          child: Container(
            height: 38 * s,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFDCD3FB), borderRadius: BorderRadius.circular(30)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8 * s),
                child: Text(t.levelN(level), style: kidBodyStyle(18 * s, color: KidColors.ink, weight: FontWeight.w700)),
              ),
            ),
          ),
        ),
        divider(),
        Expanded(
          flex: 5,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Text(t.mmPairs(found, pairs),
                  key: ValueKey(found), style: kidBodyStyle(18 * s, color: KidColors.ink, weight: FontWeight.w700)),
            ),
          ),
        ),
        divider(),
        Expanded(
          flex: 4,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Image.asset(MemoryAssets.coin, width: 32 * s, height: 32 * s),
              SizedBox(width: 4 * s),
              Text('+$reward', style: kidBodyStyle(18 * s, color: KidColors.ink, weight: FontWeight.w700)),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// A card that flips in 3D between the star back and the picture face.
class _MemoryCard extends StatelessWidget {
  final _Card card;
  final bool shake;
  final Animation<double> idle;
  final double phase;
  final VoidCallback onTap;
  const _MemoryCard({super.key, required this.card, required this.shake, required this.idle, required this.phase, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final showFace = card.open || card.matched;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: showFace ? 1 : 0),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
        builder: (_, v, __) {
          final angle = v * pi;
          final face = v >= 0.5;
          Widget side = face
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(pi),
                  child: _Face(picture: card.picture, matched: card.matched, idle: idle, phase: phase),
                )
              : _Back(idle: idle, phase: phase);
          return TweenAnimationBuilder<double>(
            tween: Tween(end: shake ? 1 : 0),
            duration: const Duration(milliseconds: 400),
            builder: (_, sh, child) => Transform.translate(offset: Offset(sin(sh * pi * 6) * 5 * sh, 0), child: child),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(angle),
              child: side,
            ),
          );
        },
      ),
    );
  }
}

class _Back extends StatelessWidget {
  final Animation<double> idle;
  final double phase;
  const _Back({required this.idle, required this.phase});

  @override
  Widget build(BuildContext context) => Image.asset(MemoryAssets.back, fit: BoxFit.fill);
}

class _Face extends StatelessWidget {
  final String picture;
  final bool matched;
  final Animation<double> idle;
  final double phase;
  const _Face({required this.picture, required this.matched, required this.idle, required this.phase});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = c.maxWidth;
      return Stack(fit: StackFit.expand, children: [
        Image.asset(MemoryAssets.face, fit: BoxFit.fill),
        Padding(
          padding: EdgeInsets.all(size * 0.12),
          child: matched
              ? AnimatedBuilder(
                  animation: idle,
                  builder: (_, ch) => Transform.scale(scale: 1 + 0.04 * sin((idle.value * 6 + phase) * 2 * pi), child: ch),
                  child: Image.asset(MemoryAssets.picture(picture), fit: BoxFit.contain),
                )
              : Image.asset(MemoryAssets.picture(picture), fit: BoxFit.contain),
        ),
        if (matched)
          Positioned(
            top: size * 0.05,
            right: size * 0.05,
            child: Icon(Icons.check_circle_rounded, color: const Color(0xFF16A34A), size: size * 0.2),
          ),
      ]);
    });
  }
}
