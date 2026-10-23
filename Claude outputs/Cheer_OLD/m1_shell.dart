import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mortaalim/Manager/rewards.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:provider/provider.dart';

import 'm1_games.dart';
import 'm1_kit.dart';
import 'm1_text.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Shared screens of the maths games: game menu, play frame, results page,
// level map and "how to play".
// ═══════════════════════════════════════════════════════════════════════════

/// A set of games with its own home, map and results look (maths, sciences …).
class M1World {
  final String id; // 'math', 'science'
  final List<M1Game> Function() games;
  final String subject; // LessonProgress subject
  final String homeBg, homeSign, homeBack, homeSound, footerSprite;
  final String mapBg, mapMascot, endBg;
  final String? endLeft, endRight;
  final double mapRatio; // map picture height / width
  final List<Offset> mapPath; // painted path, fractions of the map picture
  final String prefix; // sprite prefix of this world's pictures ('sc', 'ar')
  final String? lang; // fixed language of the world (null = app language)
  final Widget Function(BuildContext c)? homeExtra; // extra button on the home page
  final String? homeTitle; // full painted title banner (text included), replaces the home sign
  const M1World({
    this.prefix = 'sc',
    this.lang,
    this.homeExtra,
    this.homeTitle,
    required this.id,
    required this.games,
    required this.subject,
    required this.homeBg,
    required this.homeSign,
    required this.homeBack,
    required this.homeSound,
    required this.footerSprite,
    required this.mapBg,
    required this.mapMascot,
    required this.endBg,
    required this.mapRatio,
    required this.mapPath,
    this.endLeft,
    this.endRight,
  });

  /// Text key of this world ('mapTitle' → 'science_mapTitle').
  String k(String key) => id == 'math' ? key : '${id}_$key';
}

const m1MathWorld = M1World(
  id: 'math',
  games: _mathGames,
  subject: 'math',
  homeBg: 'home',
  homeSign: 'sign_plank',
  homeBack: 'btn_back',
  homeSound: 'btn_sound',
  footerSprite: 'plank_leaf',
  mapBg: 'map',
  mapMascot: 'fox_conductor',
  endBg: 'end',
  endLeft: 'robot_jump',
  endRight: 'kid_cheer',
  mapRatio: 723 / 720,
  mapPath: [
    Offset(0.372, 0.891), Offset(0.411, 0.714), Offset(0.248, 0.556), Offset(0.576, 0.574),
    Offset(0.709, 0.370), Offset(0.847, 0.256), Offset(0.912, 0.150), Offset(0.794, 0.061),
  ],
);
List<M1Game> _mathGames() => m1Games;

/// One game of a world.
class M1Game {
  final String id;
  final String menuSign, playSign; // title sign sprites
  final String back, sound; // round button sprites
  final String playButton; // big "Jouer" sprite
  final List<String> modes; // mode ids, e.g. ['recognize', 'count', 'order']
  final List<int> ranges; // biggest number of each range (shape: difficulty 0..2)
  final M1RangeStyle rangeStyle;
  final String tabIcon; // icon on the map tabs
  final List<String> helpIcons; // 3 sprites for "how to play"
  final List<String> checkIcons; // 3 sprites for the results checklist
  final String robot; // robot for help & tips
  final Widget Function(int mode, double size) modeIcon;
  final Widget Function(M1Level level) play;
  final String? menuTitle; // full painted title banner (text included), replaces the sign on the menu
  final Widget Function(BuildContext c, double w, double h)? menuScene; // characters between title and cards
  const M1Game({
    required this.id,
    required this.menuSign,
    required this.playSign,
    required this.back,
    required this.sound,
    required this.playButton,
    required this.modes,
    required this.ranges,
    required this.rangeStyle,
    required this.tabIcon,
    required this.helpIcons,
    required this.checkIcons,
    required this.robot,
    required this.modeIcon,
    required this.play,
    this.world,
    this.menuTitle,
    this.menuScene,
  });

  final M1World? world;
  M1World get w => world ?? m1MathWorld;

  /// Scene picture of this game: '' = play, 'menu' = its menu.
  String bgOf([String s = '']) {
    final b = w.id == 'math' ? id : '${w.prefix}_bg_$id';
    return s.isEmpty ? b : '${b}_$s';
  }

  String get thumb => w.id == 'math' ? 'thumb_$id' : '${w.prefix}_thumb_$id';

  int get levels => modes.length * ranges.length;
  M1Level level(int i) => M1Level(this, i);
  int indexOf(int mode, int range) => range * modes.length + mode;
  String title(BuildContext c) => '${m1T(c, '${id}_t1')} ${m1T(c, '${id}_t2')}';
}

enum M1RangeStyle { blue, teal, tealStars, purple, stars }

class M1Level {
  final M1Game game;
  final int index;
  const M1Level(this.game, this.index);
  int get mode => index % game.modes.length;
  int get range => index ~/ game.modes.length;
  String get modeId => game.modes[mode];
  int get top => game.ranges[range];
  int get tier => range + 1;
  bool get isLast => index == game.levels - 1;
  String modeName(BuildContext c) => m1T(c, '${game.id}_m$mode');
  String rangeName(BuildContext c) => m1T(c, '${game.id}_r$range');
}

void m1OpenLevel(BuildContext context, M1Level lv, {bool replace = false}) {
  final route = PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (_, __, ___) => lv.game.play(lv),
    transitionsBuilder: (_, a, __, c) => FadeTransition(
      opacity: a,
      child: ScaleTransition(scale: Tween(begin: 1.06, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOut)), child: c),
    ),
  );
  if (replace) {
    Navigator.of(context).pushReplacement(route);
  } else {
    Navigator.of(context).push(route);
  }
}

Route<T> m1Route<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, c) => FadeTransition(
        opacity: a,
        child: SlideTransition(position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOut)), child: c),
      ),
    );

// ═══════════════════════════════════════════════════════════════════════════
// GAME MENU
// ═══════════════════════════════════════════════════════════════════════════

class M1GameMenu extends StatefulWidget {
  final M1Game game;
  const M1GameMenu({super.key, required this.game});
  @override
  State<M1GameMenu> createState() => _M1GameMenuState();
}

class _M1GameMenuState extends State<M1GameMenu> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  List<int>? _stars;
  int _mode = 0, _range = 0;
  M1Game get g => widget.game;

  @override
  void initState() {
    super.initState();
    _load(first: true);
  }

  Future<void> _load({bool first = false}) async {
    final st = await M1Store.stars(g.id, g.levels);
    if (!mounted) return;
    setState(() {
      _stars = st;
      if (first) {
        final n = M1Store.next(st);
        _mode = n % g.modes.length;
        _range = n ~/ g.modes.length;
      }
    });
    if (first) {
      M1Voice.say(context, '${g.title(context)}. ${m1T(context, '${g.id}_tag')}');
      if (!await M1Store.seenHelp(g.id) && mounted) {
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) _help();
      }
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    M1Voice.stop();
    super.dispose();
  }

  bool _open(int mode, int range) => _stars != null && M1Store.unlocked(_stars!, g.indexOf(mode, range));
  bool _rangeOpen(int range) => _stars != null && List.generate(g.modes.length, (m) => _open(m, range)).any((e) => e);

  Future<void> _help() async {
    await M1Store.setSeenHelp(g.id);
    if (!mounted) return;
    await m1Dialog(context, M1HowTo(game: g));
  }

  Future<void> _play() async {
    final i = g.indexOf(_mode, _range);
    if (!_open(_mode, _range)) {
      m1Sfx(context, 'Invalid_SFX.mp3');
      M1Voice.say(context, m1T(context, 'locked'));
      _toast(m1T(context, 'locked'));
      return;
    }
    M1Voice.stop();
    await Navigator.of(context).push(m1Route(g.play(g.level(i))));
    _load();
  }

  void _toast(String t) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(t, style: m1Text(15, color: Colors.white)),
      backgroundColor: m1Ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      duration: const Duration(milliseconds: 1600),
    ));

  Future<void> _map() async {
    await Navigator.of(context).push(m1Route(M1MapPage(game: g)));
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF6E9C8),
        body: M1Frame(child: Builder(builder: _page)),
      );

  Widget _page(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final pad = MediaQuery.paddingOf(context);
    final h = size.height - pad.vertical;
    final grid = g.modes.length == 4;
    final next = _stars == null ? 0 : M1Store.next(_stars!);
    return Stack(children: [
      M1Bg(asset: g.bgOf('menu')),
      SafeArea(
        child: Column(children: [
          // top: buttons + sign
          SizedBox(
            height: g.menuTitle != null ? min(h * 0.32, 270.0) : min(h * 0.27, 215.0),
            child: Stack(children: [
              if (g.menuTitle != null)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: M1TitleBanner(
                      sprite: g.menuTitle!,
                      width: min(w - 16, (min(h * 0.32, 270.0) - 22) / m1Ratio(g.menuTitle!)),
                      onTap: () => M1Voice.say(context, '${g.title(context)}. ${m1T(context, '${g.id}_tag')}'),
                    ),
                  ),
                ),
              PositionedDirectional(start: 10, top: 6, child: m1Round(context, g.back, 52, () => Navigator.of(context).maybePop(), flipRtl: true, label: 'back')),
              PositionedDirectional(
                end: 10,
                top: 6,
                child: m1Round(context, g.sound, 52, () => M1Voice.say(context, '${g.title(context)}. ${m1T(context, '${g.id}_tag')}'), label: 'sound'),
              ),
              if (g.menuTitle == null)
              Align(
                alignment: Alignment.topCenter,
                child: M1Swing(
                  child: M1Sign(
                    sprite: g.menuSign,
                    title: m1T(context, '${g.id}_t1'),
                    title2: m1T(context, '${g.id}_t2'),
                    sub: m1T(context, '${g.id}_tag'),
                    width: min(w * 0.7, min(h * 0.27, 215.0) / m1Ratio(g.menuSign) * 0.98),
                  ),
                ),
              ),
            ]),
          ),
          g.menuScene == null ? const Spacer() : Expanded(child: LayoutBuilder(builder: (c, bc) => g.menuScene!(c, bc.maxWidth, bc.maxHeight))),
          // mode cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: grid
                ? Column(children: [
                    Row(children: [for (var m = 0; m < 2; m++) Expanded(child: _modeCard(m, (h * 0.12).clamp(84.0, 104.0)))]),
                    const SizedBox(height: 8),
                    Row(children: [for (var m = 2; m < 4; m++) Expanded(child: _modeCard(m, (h * 0.12).clamp(84.0, 104.0)))]),
                  ])
                : Row(children: [for (var m = 0; m < g.modes.length; m++) Expanded(child: _modeCard(m, (h * 0.155).clamp(104.0, 128.0)))]),
          ),
          SizedBox(height: h * 0.018),
          M1SlideIn(delay: 250, child: _ranges(w - 40)),
          SizedBox(height: h * 0.02),
          M1PlayButton(
            label: m1T(context, 'play'),
            onTap: _stars == null ? null : _play,
            width: min(w * 0.62, 92 / m1Ratio(g.playButton)),
            sprite: g.playButton,
            pulse: _pulse,
          ),
          SizedBox(height: h * 0.014),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(children: [
              Expanded(child: M1OutlineButton(label: m1T(context, 'myLevels'), icon: const M1BarsIcon(), onTap: _map, width: double.infinity)),
              const SizedBox(width: 10),
              Expanded(child: M1OutlineButton(label: m1T(context, 'howTo'), icon: m1QuestionIcon(22), onTap: _help, width: double.infinity)),
            ]),
          ),
          SizedBox(height: h * 0.014),
          _tip(next, w),
          SizedBox(height: h * 0.012),
        ]),
      ),
    ]);
  }

  Widget _modeCard(int m, double height) {
    final sel = m == _mode;
    final open = _open(m, _range);
    final st = _stars == null ? 0 : _stars![g.indexOf(m, _range)];
    return M1PopIn(
      delay: 80 * m,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: M1Press(
          onTap: () {
            setState(() => _mode = m);
            M1Voice.say(context, m1T(context, '${g.id}_m$m'));
          },
          sound: 'toggleButton',
          child: AnimatedScale(
            scale: sel ? 1.04 : 1,
            duration: const Duration(milliseconds: 200),
            child: M1Card(
              height: height,
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
              rim: sel ? const Color(0xFFFFC21A) : m1Line,
              rimWidth: sel ? 3.5 : 2.5,
              glow: sel,
              child: Stack(children: [
                Column(children: [
                  SizedBox(
                    height: height * 0.24,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(m1T(context, '${g.id}_m$m'), maxLines: 2, textAlign: TextAlign.center, style: m1Text(15, height: 1.05)),
                    ),
                  ),
                  Expanded(
                    child: Opacity(
                      opacity: open ? 1 : 0.45,
                      child: Center(child: g.modeIcon(m, height * 0.6)),
                    ),
                  ),
                  SizedBox(height: height * 0.14, child: _miniStars(st, height * 0.12)),
                ]),
                if (!open)
                  Positioned(
                    right: 0,
                    top: height * 0.25,
                    child: Icon(Icons.lock_rounded, color: const Color(0xFF9A8F80), size: height * 0.2),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStars(int n, double size) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < 3; i++)
          Icon(Icons.star_rounded, size: size, color: i < n ? m1Yellow : const Color(0xFFD9CFC0)),
      ]);

  Widget _ranges(double width) {
    final style = g.rangeStyle;
    final selColor = switch (style) {
      M1RangeStyle.blue => const [Color(0xFF5BB8FF), Color(0xFF1F6FE0)],
      M1RangeStyle.teal || M1RangeStyle.tealStars => const [Color(0xFF5DE0EA), Color(0xFF14A9C0)],
      _ => const [Color(0xFF9B62F2), Color(0xFF6A2BD9)],
    };
    return Container(
      width: width,
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E4),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: m1Line, width: 2),
        boxShadow: [BoxShadow(color: const Color(0xFFB98B3E).withOpacity(0.25), offset: const Offset(0, 4), blurRadius: 6)],
      ),
      child: Row(children: [
        for (var r = 0; r < g.ranges.length; r++)
          Expanded(
            child: M1Press(
              onTap: () {
                if (!_rangeOpen(r)) {
                  m1Sfx(context, 'Invalid_SFX.mp3');
                  _toast(m1T(context, 'locked'));
                  return;
                }
                setState(() {
                  _range = r;
                  if (!_open(_mode, r)) _mode = 0;
                });
                M1Voice.say(context, m1T(context, '${g.id}_r$r'));
              },
              sound: 'toggleButton',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  gradient: r == _range ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: selColor) : null,
                  border: r == _range ? Border.all(color: Colors.white, width: 2) : null,
                  boxShadow: [if (r == _range) BoxShadow(color: selColor[1].withOpacity(0.5), blurRadius: 10)],
                ),
                child: Center(child: _rangeLabel(r, r == _range)),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _rangeLabel(int r, bool sel) {
    final open = _rangeOpen(r);
    final c = sel ? Colors.white : (open ? m1Ink : const Color(0xFFAAA092));
    final label = Text(m1T(context, '${g.id}_r$r'), maxLines: 1, style: m1Text(15, color: c).copyWith(shadows: sel ? [const Shadow(color: Color(0x55000000), offset: Offset(0, 1.5))] : null));
    final row = Row(mainAxisSize: MainAxisSize.min, children: [
      if (!open) ...[Icon(Icons.lock_rounded, size: 15, color: c), const SizedBox(width: 3)],
      if (g.rangeStyle == M1RangeStyle.stars || g.rangeStyle == M1RangeStyle.tealStars) ...[
        for (var i = 0; i <= r; i++) Icon(Icons.star_rounded, size: 15, color: sel ? m1Yellow : c),
        const SizedBox(width: 3),
      ],
      label,
    ]);
    return FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: row));
  }

  Widget _tip(int next, double w) {
    final unlockedText = next > 0 ? m1T(context, 'unlocked', {'n': next + 1}) : m1T(context, '${g.id}_tip');
    return M1SlideIn(
      delay: 400,
      child: Container(
        width: min(w * 0.82, 330.0),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4DE).withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: m1Line, width: 2),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          M1Float(amp: 0, tilt: 0.25, child: Image.asset(m1(next > 0 ? 'star' : 'btn_hint_round'), width: 24, errorBuilder: (_, __, ___) => const Icon(Icons.lightbulb_rounded, color: m1Yellow, size: 22))),
          const SizedBox(width: 8),
          Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(unlockedText, maxLines: 1, style: m1Text(15)))),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HOW TO PLAY
// ═══════════════════════════════════════════════════════════════════════════

class M1HowTo extends StatefulWidget {
  final M1Game game;
  const M1HowTo({super.key, required this.game});
  @override
  State<M1HowTo> createState() => _M1HowToState();
}

/// "Comment jouer ?": the three steps light up one after another, Waki reads
/// each one and a hand taps its picture, then the "C'est parti !" button pulses.
class _M1HowToState extends State<M1HowTo> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  int _step = -1;
  bool _alive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  Future<void> _play() async {
    for (var i = 0; i < 3; i++) {
      if (!_alive || !mounted) return;
      setState(() => _step = i);
      m1Sound(context, 'PopButton');
      M1Voice.say(context, m1T(context, '${widget.game.id}_h${i + 1}'));
      await Future.delayed(const Duration(milliseconds: 2900));
    }
    if (mounted && _alive) setState(() => _step = 3);
  }

  @override
  void dispose() {
    _alive = false;
    _pulse.dispose();
    M1Voice.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => M1Frame(child: Builder(builder: (context) {
        final w = MediaQuery.sizeOf(context).width;
        final game = widget.game;
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              width: min(w - 32, 380.0),
              child: Stack(clipBehavior: Clip.none, children: [
                M1Card(
                  padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                  radius: 28,
                  rimWidth: 3,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    for (var i = 0; i < 3; i++) _stepRow(i, game),
                    const SizedBox(height: 6),
                    M1OrangeButton(
                      label: m1T(context, 'letsGo'),
                      icon: Icons.play_arrow_rounded,
                      onTap: () => Navigator.of(context).pop(),
                      width: 230,
                      height: 54,
                      pulse: _step >= 3 ? _pulse : null,
                    ),
                    const SizedBox(height: 6),
                    M1Press(
                      onTap: () {
                        setState(() => _step = -1);
                        _play();
                      },
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.replay_rounded, color: m1Purple, size: 20),
                        const SizedBox(width: 4),
                        Text(m1T(context, 'howAgain'), style: m1Text(14, color: m1Purple)),
                      ]),
                    ),
                  ]),
                ),
                Positioned(
                  top: -44,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF9B62F2), Color(0xFF6A2BD9)]),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: m1Purple.withOpacity(0.45), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Text(m1T(context, 'howTo'), style: m1Text(22, color: Colors.white)),
                    ),
                  ),
                ),
                Positioned(right: -12, top: -70, child: M1Float(child: Image.asset(m1(game.robot), width: 84))),
              ]),
            ),
          ),
        );
      }));

  Widget _stepRow(int i, M1Game game) {
    final now = _step == i, done = _step > i;
    return M1SlideIn(
      delay: 120 + i * 140,
      child: AnimatedScale(
        scale: now ? 1.04 : 1,
        duration: const Duration(milliseconds: 250),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: now ? const Color(0xFFFFF1C9) : (done ? const Color(0xFFEFFBE9) : Colors.transparent),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: now ? const Color(0xFFFFC21A) : (done ? const Color(0xFF9BDB86) : Colors.transparent), width: 2.5),
          ),
          child: Opacity(
            opacity: _step < 0 || now || done ? 1 : 0.45,
            child: Row(children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: done ? m1Green : m1Purple, shape: BoxShape.circle),
                child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : Text('${i + 1}', style: m1Text(17, color: Colors.white)),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 58,
                height: 52,
                child: M1Spot(
                  size: 52,
                  hand: now,
                  child: M1Float(phase: i * 0.3, amp: now ? 5 : 2, child: Image.asset(m1(game.helpIcons[i]), width: 58, height: 52, fit: BoxFit.contain)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(m1T(context, '${game.id}_h${i + 1}'), style: m1Text(16, height: 1.15))),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PLAY FRAME — 5 challenges per level
// ═══════════════════════════════════════════════════════════════════════════

abstract class M1Play extends StatefulWidget {
  final M1Level lv;
  const M1Play({super.key, required this.lv});
}

abstract class M1PlayState<W extends M1Play> extends State<W> with TickerProviderStateMixin {
  /// Challenges in one level (creative levels use 1).
  int get rounds => 5;
  final Random rng = Random();
  int round = 0;
  int mistakes = 0;
  int roundMistakes = 0;
  bool busy = false;
  bool finished = false;
  String robotSay = '';
  final List<String> review = [];
  late final AnimationController burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController idle = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  late final AnimationController pulse = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  late final AnimationController ghostAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
  final GlobalKey _stageKey = GlobalKey();
  ({Offset a, Offset b, String sprite, double size, Widget? w})? _ghost;

  M1Level get lv => widget.lv;
  M1Game get game => lv.game;

  /// What the child must do now (read aloud, shown in the robot bubble).
  String get instruction;

  /// Prepares the next challenge (called inside setState).
  void newRound();

  /// The playing area.
  Widget board(BuildContext context, double w, double h);

  /// Optional extra button row under the board (e.g. "Vérifier").
  Widget? actions(BuildContext context, double w) => null;

  /// Shows help for the current challenge.
  void hint() => say(instruction);

  /// Sprite of the play background.
  String get bg => game.bgOf();

  // ── guided help ───────────────────────────────────────────────────────────
  // When the child waits, a hand shows what to do (idleHelp). After a right
  // answer, the game shows why (explain): counting, reading, naming…

  /// The object being counted / shown right now (games highlight it).
  int? countIdx;

  /// True while the helping hand is shown.
  bool showHand = false;

  /// How many times help was shown in this challenge (1 = show how, 2+ = point at the answer).
  int helpLevel = 0;

  Timer? _idleT;
  int _demoTok = 0;
  bool _touched = false; // the child already touched the screen in this level

  /// Any touch on the screen: hides the hand and restarts the wait.
  void poke() {
    _idleT?.cancel();
    _demoTok++;
    if (_ghost != null) ghostAnim.stop();
    if (showHand || _ghost != null || (countIdx != null && !busy)) {
      setState(() {
        showHand = false;
        _ghost = null;
        if (!busy) countIdx = null;
      });
    }
    if (!busy && !finished) _idleT = Timer(Duration(seconds: round == 0 && helpLevel == 0 && !_touched ? 3 : 7), _onIdle);
  }

  void _onIdle() {
    if (!mounted || busy || finished) return;
    helpLevel++;
    setState(() => showHand = true);
    idleHelp();
    _idleT = Timer(const Duration(seconds: 10), _onIdle);
  }

  /// What the helping hand does when the child waits (games override).
  void idleHelp() => say(instruction);

  /// Shown after a right answer, before the next challenge (games override).
  Future<void> explain() async {}

  /// Highlights objects 0…n-1 one by one and says their number (or [word]).
  /// A [demo] stops as soon as the child touches the screen.
  Future<void> countAlong(int n, {int from = 1, String Function(int k)? word, int ms = 650, bool demo = false}) async {
    final tok = _demoTok;
    for (var k = 0; k < n; k++) {
      if (!mounted || (demo && tok != _demoTok)) return;
      setState(() => countIdx = k);
      m1Sound(context, 'PopButton');
      M1Voice.say(context, word?.call(k) ?? '${from + k}');
      await Future.delayed(Duration(milliseconds: ms));
    }
    if (!mounted || (demo && tok != _demoTok)) return;
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted && (!demo || tok == _demoTok)) setState(() => countIdx = null);
  }

  @override
  void initState() {
    super.initState();
    newRound();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        say(instruction);
        poke();
      }
    });
  }

  @override
  void dispose() {
    _idleT?.cancel();
    burst.dispose();
    idle.dispose();
    pulse.dispose();
    ghostAnim.dispose();
    M1Voice.stop();
    super.dispose();
  }

  /// Centre of a widget (by its key) in the play page.
  Offset? centerOf(GlobalKey k) {
    final box = k.currentContext?.findRenderObject() as RenderBox?;
    final stage = _stageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || stage == null || !box.attached || !box.hasSize) return null;
    return stage.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  }

  /// A see-through copy of [sprite] is dragged by a hand from [from] to [to],
  /// so the child sees the gesture and copies it. Stops when the child touches.
  Future<void> showDrag(GlobalKey from, GlobalKey to, String sprite, {double size = 60, int times = 2, Widget? ghost}) async {
    final tok = _demoTok;
    for (var i = 0; i < times; i++) {
      final a = centerOf(from), b = centerOf(to);
      if (!mounted || a == null || b == null || tok != _demoTok) break;
      setState(() => _ghost = (a: a, b: b, sprite: ghost != null ? '*' : sprite, size: size, w: ghost));
      try {
        await ghostAnim.forward(from: 0).orCancel;
      } on TickerCanceled {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 350));
    }
    if (mounted) setState(() => _ghost = null);
  }

  /// A hand taps on [target] a few times ("touche ici").
  Future<void> showTap(GlobalKey target, {int times = 2}) async {
    final tok = _demoTok;
    final a = centerOf(target);
    if (a == null) return;
    for (var i = 0; i < times; i++) {
      if (!mounted || tok != _demoTok) break;
      setState(() => _ghost = (a: a, b: a, sprite: '', size: 0, w: null));
      try {
        await ghostAnim.forward(from: 0).orCancel;
      } on TickerCanceled {
        break;
      }
    }
    if (mounted) setState(() => _ghost = null);
  }

  Widget _ghostLayer() {
    final g = _ghost;
    if (g == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: ghostAnim,
          builder: (_, __) {
            final t = ghostAnim.value;
            // 0–0.18 press · 0.18–0.8 carry (with a little arc) · 0.8–1 drop
            final m = Curves.easeInOut.transform(((t - 0.18) / 0.62).clamp(0.0, 1.0));
            final p = Offset.lerp(g.a, g.b, m)! + Offset(0, -sin(m * pi) * 40);
            final press = (t < 0.18 ? t / 0.18 : (t > 0.8 ? 1 - (t - 0.8) / 0.2 : 1.0)).clamp(0.0, 1.0);
            final fade = (t > 0.85 ? 1 - (t - 0.85) / 0.15 : (t < 0.08 ? t / 0.08 : 1.0)).clamp(0.0, 1.0);
            return Stack(clipBehavior: Clip.none, children: [
              if (g.sprite.isNotEmpty)
                Positioned(
                  left: p.dx - g.size / 2,
                  top: p.dy - g.size / 2,
                  child: Opacity(
                    opacity: (0.75 * fade).clamp(0.0, 1.0),
                    child: Transform.scale(scale: 1 + 0.15 * press, child: g.w ?? Image.asset(m1(g.sprite), width: g.size, height: g.size, fit: BoxFit.contain)),
                  ),
                ),
              if (g.sprite.isEmpty)
                Positioned(
                  left: p.dx - 30,
                  top: p.dy - 30,
                  child: Opacity(
                    opacity: ((1 - press) * 0.6).clamp(0.0, 1.0),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF39B8F2), width: 4)),
                    ),
                  ),
                ),
              Positioned(
                left: p.dx - 8,
                top: p.dy - 6 + (1 - press) * 12,
                child: Opacity(opacity: fade, child: Image.asset(m1('hand_tap'), width: 58)),
              ),
            ]);
          },
        ),
      ),
    );
  }

  void say(String t, {bool speak = true}) {
    if (!mounted) return;
    setState(() => robotSay = t);
    if (speak) M1Voice.say(context, t);
  }

  String praise() => m1T(context, 'praise${rng.nextInt(6)}');

  /// Right answer: sparkles, praise, then the next challenge.
  Future<void> good({String? text, int wait = 1300}) async {
    if (busy) return;
    busy = true;
    _idleT?.cancel();
    _demoTok++;
    setState(() {
      showHand = false;
      countIdx = null;
    });
    m1Sfx(context, 'CorrectAnwser_SFX.mp3');
    burst.forward(from: 0);
    say(text ?? praise());
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await explain();
    if (!mounted) return;
    await Future.delayed(Duration(milliseconds: max(500, wait - 900)));
    if (!mounted) return;
    nextRound();
  }

  /// Wrong answer: soft sound, the robot helps; [topic] is remembered for the results page.
  void bad(String topic, {String? help}) {
    mistakes++;
    roundMistakes++;
    m1Sfx(context, 'WrongAnwser_SFX.mp3');
    if (!review.contains(topic)) review.add(topic);
    say(help ?? m1T(context, 'tryAgain'));
  }

  void nextRound() {
    if (!mounted) return;
    if (round + 1 >= rounds) {
      setState(() => round = rounds);
      finish();
      return;
    }
    setState(() {
      round++;
      roundMistakes = 0;
      busy = false;
      helpLevel = 0;
      showHand = false;
      countIdx = null;
      newRound();
    });
    say(instruction);
    poke();
  }

  int get stars => mistakes <= 1 ? 3 : (mistakes <= 3 ? 2 : 1);

  Future<void> finish() async {
    if (finished) return;
    finished = true;
    final st = stars;
    final before = await M1Store.stars(game.id, game.levels);
    final prev = await M1Store.record(game.id, lv.index, st);
    // the last level of a range (all modes done) gives the badge, the very last one +3 gems
    final after = await M1Store.stars(game.id, game.levels);
    bool rangeDone(List<int> s) => List.generate(game.modes.length, (m) => s[game.indexOf(m, lv.range)] > 0).every((e) => e);
    final badge = !rangeDone(before) && rangeDone(after);
    final reward = Rewards.level(tier: lv.tier, stars: st, prevStars: prev, bonusGems: (prev == 0 && badge) ? 2 : 0);
    if (!mounted) return;
    Provider.of<ExperienceManager>(context, listen: false).grant(context, reward);
    m1Sfx(context, st == 3 ? 'VictoryOrchestral_SFX.mp3' : 'victory2_SFX.mp3');
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(m1Route(M1ResultPage(lv: lv, stars: st, reward: reward, review: review, badge: badge, perfect: mistakes == 0)));
  }

  /// Standard robot + bubble line.
  Widget robotLine(double w, double h, {String? sprite, bool right = false, double? robotH}) {
    final rh = robotH ?? min(h, 130.0);
    final robot = M1Float(
      amp: 4,
      child: Transform.flip(flipX: right, child: Image.asset(m1(sprite ?? game.robot), height: rh, fit: BoxFit.contain)),
    );
    final bubble = Flexible(child: Padding(padding: EdgeInsets.only(bottom: rh * 0.35), child: M1Bubble(text: robotSay, width: min(w * 0.58, 230.0), tailRight: right)));
    return SizedBox(
      height: rh,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: right ? [bubble, const SizedBox(width: 4), robot] : [robot, const SizedBox(width: 4), bubble],
      ),
    );
  }

  /// Sparkles over a box when a challenge is solved.
  Widget burstLayer() => IgnorePointer(child: AnimatedBuilder(animation: burst, builder: (_, __) => CustomPaint(painter: M1Burst(burst.value), size: Size.infinite)));

  Future<void> _quit() async {
    M1Voice.stop();
    final yes = await m1Dialog<bool>(context, _QuitDialog(game: game));
    if (yes == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (did, _) {
          if (!did) _quit();
        },
        child: Scaffold(backgroundColor: const Color(0xFFF6E9C8), body: M1Frame(child: Builder(builder: _page))),
      );

  Widget _page(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = size.width, h = size.height - pad.vertical;
    final head = min(h * 0.16, 128.0);
    final act = actions(context, w);
    return Stack(key: _stageKey, children: [
      M1Bg(asset: bg),
      SafeArea(
        child: Column(children: [
          SizedBox(
            height: head,
            child: Stack(children: [
              PositionedDirectional(start: 8, top: 4, child: m1Round(context, game.back, 50, _quit, flipRtl: true, label: 'back')),
              PositionedDirectional(end: 8, top: 4, child: m1Round(context, game.sound, 50, () => say(instruction), label: 'sound')),
              Align(
                alignment: Alignment.topCenter,
                child: M1Swing(
                  child: M1Sign(
                    sprite: game.playSign,
                    title: game.title(context),
                    sub: m1T(context, 'levelChallenge', {'n': lv.index + 1, 'k': min(round + 1, rounds), 't': rounds}),
                    width: min(w - 124, head / m1Ratio(game.playSign) * 0.98),
                  ),
                ),
              ),
            ]),
          ),
          Expanded(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) {
                _touched = true;
                poke();
              },
              child: LayoutBuilder(builder: (_, c) => board(context, c.maxWidth, c.maxHeight)),
            ),
          ),
          if (act != null) act,
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            child: Row(children: [
              M1Press(
                onTap: busy ? null : hint,
                label: m1T(context, 'hint'),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: m1Cream,
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: const Color(0xFF5B2BB5), width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 3))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Image.asset(m1('btn_hint_round'), width: 26, errorBuilder: (_, __, ___) => const Icon(Icons.lightbulb_rounded, color: m1Yellow)),
                    const SizedBox(width: 6),
                    Text(m1T(context, 'hint'), style: m1Text(16)),
                  ]),
                ),
              ),
              const Spacer(),
              M1Dots(total: rounds, done: min(round, rounds)),
            ]),
          ),
        ]),
      ),
      _ghostLayer(),
    ]);
  }
}

class _QuitDialog extends StatelessWidget {
  final M1Game game;
  const _QuitDialog({required this.game});
  @override
  Widget build(BuildContext context) => M1Frame(
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: M1Card(
              width: 320,
              radius: 26,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Image.asset(m1('robot_relax'), height: 100),
                const SizedBox(height: 6),
                Text(m1T(context, 'quitQ'), textAlign: TextAlign.center, style: m1Text(20)),
                const SizedBox(height: 14),
                M1OrangeButton(label: m1T(context, 'keepPlaying'), onTap: () => Navigator.of(context).pop(false), width: 250, height: 50),
                const SizedBox(height: 10),
                M1OutlineButton(
                  label: m1T(context, 'quit'),
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFF4A1D9E)),
                  onTap: () => Navigator.of(context).pop(true),
                  width: 250,
                ),
              ]),
            ),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// RESULTS
// ═══════════════════════════════════════════════════════════════════════════

class M1ResultPage extends StatefulWidget {
  final M1Level lv;
  final int stars;
  final Reward reward;
  final List<String> review;
  final bool badge, perfect;
  const M1ResultPage({super.key, required this.lv, required this.stars, required this.reward, required this.review, required this.badge, required this.perfect});
  @override
  State<M1ResultPage> createState() => _M1ResultPageState();
}

class _M1ResultPageState extends State<M1ResultPage> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..forward();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  M1Level get lv => widget.lv;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      M1Voice.say(context, '${m1T(context, lv.game.w.k(widget.stars == 3 ? 'bravoTop' : 'bravo'))} ${m1T(context, 'levelDone', {'n': lv.index + 1})}');
    });
    for (var i = 0; i < widget.stars; i++) {
      Future.delayed(Duration(milliseconds: 500 + i * 300), () {
        if (mounted) m1Sfx(context, 'StarSound.mp3');
      });
    }
  }

  @override
  void dispose() {
    _in.dispose();
    _pulse.dispose();
    M1Voice.stop();
    super.dispose();
  }

  void _next() {
    if (lv.isLast) {
      Navigator.of(context).pushReplacement(m1Route(M1MapPage(game: lv.game)));
    } else {
      m1OpenLevel(context, lv.game.level(lv.index + 1), replace: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFF6E9C8), body: M1Frame(child: Builder(builder: _page)));

  Widget _page(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = size.width, h = size.height - pad.vertical;
    final g = lv.game;
    final topH = min(h * 0.24, 190.0);
    return Stack(children: [
      M1Bg(asset: lv.game.w.endBg),
      SafeArea(
        child: Column(children: [
          SizedBox(
            height: topH,
            child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
              if (g.w.endLeft != null)
                Positioned(left: w * 0.08, bottom: 6, child: M1PopIn(delay: 100, child: M1Float(amp: 6, tilt: 0.05, child: Image.asset(m1(g.w.endLeft!), height: topH * 0.9)))),
              if (g.w.endRight != null)
                Positioned(right: w * 0.06, bottom: 0, child: M1PopIn(delay: 250, child: M1Float(amp: 5, phase: 0.4, child: Image.asset(m1(g.w.endRight!), height: topH * 0.88)))),
              Positioned(bottom: -8, child: _stars(topH * 0.4)),
            ]),
          ),
          // ribbon + level pill
          SizedBox(
            height: 92,
            child: Stack(alignment: Alignment.topCenter, children: [
              M1PopIn(
                delay: 300,
                child: m1OnSprite(
                  'ribbon',
                  min(w - 20, 380.0),
                  m1Outlined(m1T(context, g.w.k(widget.stars == 3 ? 'bravoTop' : 'bravo')), 34, color: m1Yellow, outline: const Color(0xFF3B1388), stroke: 0.2),
                  area: const EdgeInsets.fromLTRB(0.08, 0.06, 0.08, 0.3),
                ),
              ),
              Positioned(
                bottom: 0,
                child: M1PopIn(
                  delay: 500,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(color: m1Cream, borderRadius: BorderRadius.circular(20), border: Border.all(color: m1Line, width: 2)),
                    child: Text(m1T(context, 'levelDone', {'n': lv.index + 1}), style: m1Text(18)),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: M1Card(
                radius: 26,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(children: [
                  // checklist
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      flex: 10,
                      child: M1SlideIn(
                        delay: 700 + i * 220,
                        child: Row(children: [
                          M1PopIn(delay: 800 + i * 220, child: Image.asset(m1('check'), width: 28)),
                          const SizedBox(width: 8),
                          SizedBox(width: 44, height: 34, child: Image.asset(m1(g.checkIcons[i]), fit: BoxFit.contain)),
                          const SizedBox(width: 8),
                          Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(m1T(context, '${g.id}_c${i + 1}'), style: m1Text(17)))),
                        ]),
                      ),
                    ),
                  const SizedBox(height: 4),
                  // review
                  Expanded(flex: 15, child: M1SlideIn(delay: 1400, child: _review())),
                  const SizedBox(height: 8),
                  // rewards + badge
                  Expanded(
                    flex: 26,
                    child: Row(children: [
                      Expanded(flex: 11, child: M1PopIn(delay: 1600, child: _rewards())),
                      const SizedBox(width: 8),
                      Expanded(flex: 10, child: M1PopIn(delay: 1800, child: _badge())),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          M1OrangeButton(
            label: m1T(context, lv.isLast ? 'map' : 'nextLevel'),
            icon: Icons.arrow_forward_rounded,
            onTap: _next,
            width: min(w - 40, 340.0),
            height: 54,
            pulse: _pulse,
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            M1OutlineButton(
              label: m1T(context, 'replay'),
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4A1D9E)),
              onTap: () => m1OpenLevel(context, lv, replace: true),
              width: min((w - 50) / 2, 170.0),
            ),
            const SizedBox(width: 10),
            M1OutlineButton(
              label: m1T(context, 'map'),
              icon: const Icon(Icons.map_rounded, color: Color(0xFF1F6FE0)),
              onTap: () => Navigator.of(context).pushReplacement(m1Route(M1MapPage(game: g))),
              width: min((w - 50) / 2, 170.0),
            ),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
      IgnorePointer(child: AnimatedBuilder(animation: _in, builder: (_, __) => CustomPaint(painter: M1Confetti((_in.value * 1.2).clamp(0.0, 1.0)), size: Size.infinite))),
    ]);
  }

  Widget _stars(double size) => Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == 1 ? size * 0.25 : 0),
            child: M1PopIn(
              delay: 500 + i * 300,
              from: 0.1,
              child: i < widget.stars
                  ? Image.asset(m1('star'), width: size * (i == 1 ? 1.15 : 1))
                  : ColorFiltered(
                      colorFilter: const ColorFilter.matrix([0.3, 0.4, 0.1, 0, 40, 0.3, 0.4, 0.1, 0, 40, 0.3, 0.4, 0.1, 0, 40, 0, 0, 0, 0.8, 0]),
                      child: Image.asset(m1('star'), width: size * (i == 1 ? 1.15 : 1)),
                    ),
            ),
          ),
      ]);

  Widget _review() {
    final has = widget.review.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: has ? const [Color(0xFFE3F3FF), Color(0xFFCDE9FF)] : const [Color(0xFFEFFFE6), Color(0xFFD9F5CB)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: has ? const Color(0xFF9CD3FA) : const Color(0xFF9BDB86), width: 2),
      ),
      child: Row(children: [
        SizedBox(width: 54, child: Image.asset(m1(lv.game.tabIcon), fit: BoxFit.contain)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(m1T(context, has ? 'reviewT' : 'perfectT'), style: m1Text(17))),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(has ? widget.review.first : m1T(context, 'perfectS'), maxLines: 1, style: m1Text(14, color: m1Blue, weight: FontWeight.w600)),
            ),
          ]),
        ),
        if (has)
          M1Press(
            onTap: () => m1OpenLevel(context, lv, replace: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4FA8FF), Color(0xFF1F6FE0)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: const Color(0xFF1550B0).withOpacity(0.5), offset: const Offset(0, 3))],
              ),
              child: Text('${m1T(context, 'practice')} ›', style: m1Text(14, color: Colors.white)),
            ),
          ),
      ]),
    );
  }

  Widget _rewards() => Container(
        decoration: BoxDecoration(color: const Color(0xFFFFF6E4), borderRadius: BorderRadius.circular(18), border: Border.all(color: m1Line, width: 2)),
        padding: const EdgeInsets.all(6),
        child: Column(children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(m1T(context, 'rewards'), style: m1Text(15))),
          Expanded(
            child: Row(children: [
              Expanded(child: _prize('coin', '+${widget.reward.gold}', const Color(0xFFF29A0A))),
              Container(width: 1.5, margin: const EdgeInsets.symmetric(vertical: 8), color: m1Line),
              Expanded(child: _prize('gem', '+${widget.reward.gems}', m1Blue, dim: widget.reward.gems == 0)),
            ]),
          ),
          FittedBox(fit: BoxFit.scaleDown, child: Text('+${widget.reward.xp} XP', style: m1Text(13, color: m1Purple))),
        ]),
      );

  Widget _prize(String sprite, String text, Color c, {bool dim = false}) => Opacity(
        opacity: dim ? 0.45 : 1,
        child: Column(children: [
          Expanded(child: M1Float(amp: 3, child: Image.asset(m1(sprite), fit: BoxFit.contain))),
          FittedBox(fit: BoxFit.scaleDown, child: m1Outlined(text, 22, color: c)),
        ]),
      );

  Widget _badge() => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF6EEFF), Color(0xFFE7D9FF)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD2BCF7), width: 2),
        ),
        padding: const EdgeInsets.all(6),
        child: Column(children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(m1T(context, widget.badge ? 'badgeNew' : 'badgeNext'), style: m1Text(14))),
          Expanded(
            child: Opacity(
              opacity: widget.badge ? 1 : 0.4,
              child: Stack(alignment: Alignment.center, children: [
                Image.asset(m1('badge'), fit: BoxFit.contain),
                FractionallySizedBox(
                  widthFactor: 0.34,
                  heightFactor: 0.4,
                  child: Transform.translate(
                    offset: const Offset(0, -4),
                    child: FittedBox(child: Image.asset(m1(lv.game.tabIcon))),
                  ),
                ),
              ]),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFFFF4C9), borderRadius: BorderRadius.circular(10)),
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(m1T(context, '${lv.game.id}_badge${lv.range}'), maxLines: 1, style: m1Text(12))),
          ),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// LEVEL MAP — "Mon aventure en maths"
// ═══════════════════════════════════════════════════════════════════════════

class M1MapPage extends StatefulWidget {
  final M1Game game;
  const M1MapPage({super.key, required this.game});
  @override
  State<M1MapPage> createState() => _M1MapPageState();
}

class _M1MapPageState extends State<M1MapPage> with TickerProviderStateMixin {
  late M1Game _g = widget.game;
  List<int>? _stars;
  int _sel = 0;
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  // painted path of the map picture (fractions of the picture)
  List<Offset> get _path => _g.w.mapPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final st = await M1Store.stars(_g.id, _g.levels);
    if (!mounted) return;
    setState(() {
      _stars = st;
      _sel = M1Store.next(st);
    });
  }

  /// Positions of [n] nodes spread evenly along the painted path.
  List<Offset> _nodes(int n) {
    final seg = <double>[];
    var total = 0.0;
    for (var i = 1; i < _path.length; i++) {
      final d = (_path[i] - _path[i - 1]).distance;
      seg.add(d);
      total += d;
    }
    final out = <Offset>[];
    for (var k = 0; k < n; k++) {
      var t = n == 1 ? 0.0 : k / (n - 1) * total;
      var i = 0;
      while (i < seg.length - 1 && t > seg[i]) {
        t -= seg[i];
        i++;
      }
      out.add(Offset.lerp(_path[i], _path[i + 1], (t / seg[i]).clamp(0.0, 1.0))!);
    }
    return out;
  }

  Future<void> _play(int i) async {
    if (_stars == null || !M1Store.unlocked(_stars!, i)) {
      m1Sfx(context, 'Invalid_SFX.mp3');
      M1Voice.say(context, m1T(context, 'locked'));
      return;
    }
    await Navigator.of(context).push(m1Route(_g.play(_g.level(i))));
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFF9ED7FF), body: M1Frame(child: Builder(builder: _page)));

  Widget _page(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = size.width, h = size.height - pad.vertical;
    return Stack(children: [
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7CC8FF), Color(0xFFD7F0FF), Color(0xFF9BD27A)])),
        ),
      ),
      const IgnorePointer(child: M1Sparkles(count: 10)),
      SafeArea(
        child: Column(children: [
          // header
          SizedBox(
            height: 70,
            child: Stack(children: [
              PositionedDirectional(start: 8, top: 6, child: m1Round(context, _g.w.id == 'arabic' ? 'sc_btn_back' : 'btn_back_p', 48, () => Navigator.of(context).maybePop(), flipRtl: true)),
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  FittedBox(child: m1Outlined(m1T(context, _g.w.k('mapTitle')), 30, color: const Color(0xFF6A2BD9), stroke: 0.2)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(color: m1Cream, borderRadius: BorderRadius.circular(12), border: Border.all(color: m1Line, width: 1.5)),
                    child: Text('♪ ${m1T(context, _g.w.k('grade'))} ♪', style: m1Text(13)),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          // game tabs
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [for (final g in _g.w.games()) _tab(g)],
            ),
          ),
          // the map
          Expanded(child: _map()),
          _levelCard(w),
          SizedBox(height: max(6.0, h * 0.01)),
        ]),
      ),
    ]);
  }

  Widget _tab(M1Game g) {
    final sel = g.id == _g.id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: M1Press(
        onTap: () {
          if (sel) return;
          setState(() {
            _g = g;
            _stars = null;
          });
          _load();
        },
        sound: 'toggleButton',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 82,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: m1Cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sel ? const Color(0xFF22C8F0) : m1Line, width: sel ? 3.5 : 2),
            boxShadow: [
              if (sel) BoxShadow(color: const Color(0xFF22C8F0).withOpacity(0.7), blurRadius: 12),
              BoxShadow(color: Colors.black.withOpacity(0.12), offset: const Offset(0, 3), blurRadius: 4),
            ],
          ),
          child: Column(children: [
            Expanded(child: Image.asset(m1(g.tabIcon), fit: BoxFit.contain)),
            FittedBox(fit: BoxFit.scaleDown, child: Text(m1T(context, '${g.id}_short'), maxLines: 1, style: m1Text(11))),
          ]),
        ),
      ),
    );
  }

  Widget _map() => LayoutBuilder(builder: (_, c) {
        final ar = _g.w.mapRatio; // picture height / width
        final W = c.maxWidth, H = c.maxHeight;
        final k = max(W / 720, H / (720 * ar));
        final iw = 720 * k, ih = 720 * ar * k;
        final ox = (W - iw) / 2, oy = H - ih;
        final n = _g.levels;
        final pts = _nodes(n);
        final nodeW = (W * (n > 9 ? 0.15 : 0.18)).clamp(52.0, 82.0);
        final nxt = _stars == null ? -1 : M1Store.next(_stars!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(left: ox, top: oy, width: iw, height: ih, child: Image.asset(m1BgPath(_g.w.mapBg), fit: BoxFit.fill)),
            if (_stars != null)
              for (var i = 0; i < n; i++)
                Positioned(
                  left: ox + pts[i].dx * iw - nodeW / 2,
                  top: oy + pts[i].dy * ih - nodeW * 0.62,
                  child: M1PopIn(delay: 40 * i, child: _node(i, nodeW, i == nxt)),
                ),
            if (_stars != null && nxt >= 0)
              Positioned(
                left: ox + pts[nxt].dx * iw - nodeW * 0.55,
                top: oy + pts[nxt].dy * ih - nodeW * 1.75,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _idle,
                    builder: (_, ch) => Transform.translate(offset: Offset(0, -6 * sin(_idle.value * 2 * pi).abs()), child: ch),
                    child: Image.asset(m1(_g.w.mapMascot), width: nodeW * 1.1),
                  ),
                ),
              ),
          ]),
        );
      });

  Widget _node(int i, double nw, bool now) {
    final st = _stars![i];
    final open = M1Store.unlocked(_stars!, i);
    final sprite = now ? 'node_now' : (st > 0 ? 'node_blue' : (open ? 'node_now' : 'node_lock'));
    final nh = nw * m1Ratio(sprite);
    final sel = i == _sel;
    return M1Press(
      onTap: () {
        setState(() => _sel = i);
        if (open) M1Voice.say(context, '${m1T(context, 'level', {'n': i + 1})}. ${_g.level(i).modeName(context)}');
      },
      sound: 'toggleButton',
      child: AnimatedScale(
        scale: sel ? 1.12 : 1,
        duration: const Duration(milliseconds: 220),
        child: SizedBox(
          width: nw,
          height: nh,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(child: Image.asset(m1(sprite), fit: BoxFit.contain)),
            Positioned(
              left: 0,
              right: open ? 0 : nw * 0.25,
              top: nh * 0.08,
              height: nh * 0.5,
              child: Center(child: FittedBox(child: m1Outlined('${i + 1}', nh * 0.42, color: Colors.white, outline: open ? const Color(0xFF15449A) : const Color(0xFF6E6E78), stroke: 0.18))),
            ),
            if (st > 0)
              Positioned(
                left: nw * 0.05,
                right: nw * 0.05,
                top: nh * 0.58,
                height: nh * 0.32,
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  for (var k = 0; k < 3; k++)
                    Image.asset(m1('star'), width: nw * 0.25, color: k < st ? null : const Color(0xFFB9C3D6), colorBlendMode: k < st ? null : BlendMode.srcIn),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _levelCard(double w) {
    if (_stars == null) return const SizedBox(height: 120);
    final lv = _g.level(_sel.clamp(0, _g.levels - 1).toInt());
    final done = _stars!.where((e) => e > 0).length;
    final open = M1Store.unlocked(_stars!, lv.index);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: M1Card(
        radius: 22,
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.asset(m1(_g.thumb), width: 104, height: 78, fit: BoxFit.cover)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('${m1T(context, 'level', {'n': lv.index + 1})} · ${lv.rangeName(context)}', maxLines: 1, style: m1Text(17)),
              ),
              Text(lv.modeName(context), maxLines: 1, overflow: TextOverflow.ellipsis, style: m1Text(14, color: m1InkSoft, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              _progress(done, _g.levels),
              const SizedBox(height: 3),
              FittedBox(fit: BoxFit.scaleDown, child: Text(m1T(context, 'doneOf', {'d': done, 'n': _g.levels}), style: m1Text(12, color: m1InkSoft))),
            ]),
          ),
          const SizedBox(width: 8),
          M1Press(
            onTap: () => _play(lv.index),
            sound: 'PopButton',
            child: Opacity(
              opacity: open ? 1 : 0.5,
              child: Container(
                width: 92,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFB347), Color(0xFFF2620C)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD35A), width: 2),
                  boxShadow: [BoxShadow(color: const Color(0xFFC9480A), offset: const Offset(0, 4))],
                ),
                child: open
                    ? FittedBox(child: Padding(padding: const EdgeInsets.all(8), child: m1Outlined(m1T(context, 'play'), 24, color: Colors.white, outline: const Color(0xFFC9480A))))
                    : const Icon(Icons.lock_rounded, color: Colors.white, size: 28),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _progress(int done, int n) => Container(
        height: 16,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: const Color(0xFFE6DED0), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          for (var i = 0; i < n; i++)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: i < done ? const Color(0xFF22B8F0) : const Color(0xFFCFC6B6),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
        ]),
      );
}
