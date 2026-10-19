import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:mortaalim/Manager/lesson_progress.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/l10n/app_localizations.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_page_parts.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_data.dart';

/// Sprites sliced from the games design sheet.
class GamesAssets {
  GamesAssets._();
  static const String dir = 'assets/images/UI/KidScene/';
  static const String heroBg = '${dir}games_hero_bg.webp';
  static const String mascot = '${dir}games_mascot.webp';
  static const String pad = '${dir}games_pad.webp';
  static const String tileMath = '${dir}games_tile_math.webp';
  static const String tileWords = '${dir}games_tile_words.webp';
  static const String tileMemory = '${dir}games_tile_memory.webp';
  static const String tilePuzzle = '${dir}games_tile_puzzle.webp';
  static const String tilePaint = '${dir}games_tile_paint.webp';
  static const String tileBrain = '${dir}games_tile_brain.webp';
  static const String starOn = '${dir}games_star_on.webp';
  static const String starOff = '${dir}games_star_off.webp';
  static const String trophy = '${dir}games_trophy.webp';
  static const String arrowNext = '${dir}games_arrow_next.webp';
  static const String coin = '${dir}home_coin.webp';
  static const String gem = '${dir}home_gem.webp';
  static String play(String color) => '${dir}games_play_$color.webp';

  static List<String> get all => [
        heroBg, mascot, pad, tileMath, tileWords, tileMemory, tilePuzzle, tilePaint, tileBrain,
        starOn, starOff, trophy, arrowNext, coin, gem,
        for (final c in ['orange', 'green', 'pink', 'blue', 'purple', 'yellow']) play(c),
      ];
}

enum GameCategory { all, words, logic, creative }

/// How each game from [games] (game_data.dart) is shown on the page.
class _GameStyle {
  final GameCategory category;
  final String? art; // wide illustrated art; null = use the game's own square icon
  final String play; // play-button colour
  final List<Color> backdrop; // gradient behind the square icon when there is no art
  const _GameStyle(this.category, this.art, this.play, this.backdrop);
}

const Map<String, _GameStyle> _styles = {
  'quizGame': _GameStyle(GameCategory.logic, GamesAssets.tileBrain, 'yellow', []),
  'WordExplorer': _GameStyle(GameCategory.words, GamesAssets.tileWords, 'green', []),
  'MemoryFlip': _GameStyle(GameCategory.logic, GamesAssets.tileMemory, 'pink', []),
  'shapeSorter': _GameStyle(GameCategory.logic, GamesAssets.tilePuzzle, 'blue', []),
  'MagicPainting': _GameStyle(GameCategory.creative, GamesAssets.tilePaint, 'purple', []),
  'drawingAlphabet': _GameStyle(GameCategory.words, null, 'orange', [Color(0xFFFFE3B3), Color(0xFFFFB86B)]),
  'appStories': _GameStyle(GameCategory.words, null, 'blue', [Color(0xFFCFE8FF), Color(0xFF7CB8FF)]),
  'AnimalSounds': _GameStyle(GameCategory.creative, null, 'green', [Color(0xFFD4F7D9), Color(0xFF7FD78F)]),
  'WordLink': _GameStyle(GameCategory.words, null, 'pink', [Color(0xFFFFD9EC), Color(0xFFFF8CC6)]),
  'Piano': _GameStyle(GameCategory.creative, null, 'purple', [Color(0xFFE7DBFF), Color(0xFFAE8CFF)]),
};

_GameStyle _styleOf(String title) =>
    _styles[title] ?? const _GameStyle(GameCategory.logic, null, 'orange', [Color(0xFFFFF0CC), Color(0xFFFFC85C)]);

String gameTitle(AppLocalizations t, String key) {
  switch (key) {
    case 'drawingAlphabet':
      return t.drawingAlphabet;
    case 'quizGame':
      return t.quizGame;
    case 'appStories':
      return t.appStories;
    case 'MagicPainting':
      return t.magicPainting;
    case 'AnimalSounds':
      return t.animalSound;
    case 'MemoryFlip':
      return t.memoryFlip;
    case 'shapeSorter':
      return t.shapeSorter;
    case 'WordLink':
      return t.wordLink;
    case 'WordExplorer':
      return t.wordExplorer;
    case 'Piano':
      return t.piano;
    default:
      return key;
  }
}

/// Per-game play count (shown as 0–3 stars) and the "Today's challenge":
/// play [goal] different games today → +[reward] gold, once a day.
class GameProgress {
  static const int goal = 2;
  static const int reward = 20;
  static const _kDate = 'games_ch_date';
  static const _kDone = 'games_ch_done';
  static const _kClaimed = 'games_ch_claimed';
  static String _plays(String g) => 'games_plays_$g';

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  static Future<(Map<String, int>, Set<String>, bool)> load(Iterable<String> titles) async {
    final p = await SharedPreferences.getInstance();
    final plays = {for (final t in titles) t: p.getInt(_plays(t)) ?? 0};
    if (p.getString(_kDate) != _today()) return (plays, <String>{}, false);
    return (plays, (p.getStringList(_kDone) ?? const []).toSet(), p.getBool(_kClaimed) ?? false);
  }

  /// Records a launch. Returns true when this launch completes today's challenge.
  static Future<bool> recordPlay(String title) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_plays(title), (p.getInt(_plays(title)) ?? 0) + 1);
    await ActivityLog.markToday();
    final today = _today();
    if (p.getString(_kDate) != today) {
      await p.setString(_kDate, today);
      await p.setStringList(_kDone, const []);
      await p.setBool(_kClaimed, false);
    }
    final done = (p.getStringList(_kDone) ?? const []).toSet()..add(title);
    await p.setStringList(_kDone, done.toList());
    if (!(p.getBool(_kClaimed) ?? false) && done.length >= goal) {
      await p.setBool(_kClaimed, true);
      return true;
    }
    return false;
  }
}

/// Full-screen Games page (no bottom bar).
class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> with TickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final ConfettiController _confetti = ConfettiController(duration: const Duration(seconds: 1));

  GameCategory _filter = GameCategory.all;
  Map<String, int> _plays = {};
  Set<String> _doneToday = {};
  bool _claimed = false;
  bool _precached = false;
  bool _launching = false;

  List<Map<String, dynamic>> get _visible => _filter == GameCategory.all
      ? games
      : games.where((g) => _styleOf(g['title']).category == _filter).toList();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      KidAssets.precache(context, [...GamesAssets.all, KidAssets.valleyBg, KidAssets.backBtn]);
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final (plays, done, claimed) = await GameProgress.load(games.map((g) => g['title'] as String));
    if (mounted) {
      setState(() {
        _plays = plays;
        _doneToday = done;
        _claimed = claimed;
      });
    }
  }

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  bool _isUnlocked(ExperienceManager xp, Map<String, dynamic> g) =>
      !(g['locked'] as bool) || xp.isCourseUnlocked(g['title']);

  Future<void> _tapGame(Map<String, dynamic> g) async {
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    if (!_isUnlocked(xp, g)) return _askUnlock(g);
    if (_launching) return;
    _launching = true;
    _audio.playEventSound('PopButton');
    final completed = await GameProgress.recordPlay(g['title']);
    if (!mounted) return;
    if (completed) xp.addTokenBanner(context, GameProgress.reward);
    await Navigator.pushNamed(context, g['routeName']);
    _launching = false;
    if (mounted) _refresh();
  }

  Future<void> _askUnlock(Map<String, dynamic> g) async {
    _audio.playEventSound('clickButton2');
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    final cost = (g['cost'] ?? 10) as int;
    final name = gameTitle(tr(context), g['title']);
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: KidColors.purpleDeep.withOpacity(0.35),
      builder: (ctx) => KidDialog(
        headerAsset: GamesAssets.coin,
        headerAspect: 0.9813,
        title: name,
        message: cost == 0 ? tr(ctx).unlockGameFree : tr(ctx).unlockGameFor(cost),
        actions: [
          KidOutlineButton(
            label: tr(ctx).cancel,
            onTap: () {
              _audio.playEventSound('cancelButton');
              Navigator.pop(ctx, false);
            },
          ),
          KidButton(
            label: tr(ctx).unlock,
            width: double.infinity,
            height: 54,
            showArrow: false,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (xp.unlockCourse(g['title'], cost)) {
      xp.addXP(10, context: context);
      _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3');
      _confetti.play();
      setState(() {});
    } else {
      _audio.playEventSound('invalid');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: KidColors.purpleDeep,
        duration: const Duration(milliseconds: 1600),
        content: Text(tr(context).notEnoughGold, style: kidBodyStyle(15, color: Colors.white, weight: FontWeight.w600)),
      ));
    }
  }

  /// The arrow on the challenge card: jump into an unlocked game not played today.
  void _playSuggested() {
    final xp = Provider.of<ExperienceManager>(context, listen: false);
    final open = games.where((g) => _isUnlocked(xp, g)).toList();
    if (open.isEmpty) return;
    final fresh = open.where((g) => !_doneToday.contains(g['title'])).toList();
    final pool = fresh.isNotEmpty ? fresh : open;
    _tapGame(pool[Random().nextInt(pool.length)]);
  }

  @override
  Widget build(BuildContext context) {
    final xp = Provider.of<ExperienceManager>(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 600.0) - 28;
    final s = (w / 380).clamp(0.8, 1.45);
    final visible = _visible;
    final cols = size.width >= 700 ? 3 : 2;

    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.06 * i, to: min(1.0, 0.42 + 0.06 * i), rise: 24, child: child);

    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(
        children: [
          const Positioned.fill(child: KidPageBackground()),
          SafeArea(
            bottom: false,
            child: Center(
              child: SizedBox(
                width: w,
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    step(0, KidPageHeader(scale: s, title: tr(context).games, gold: xp.gold, gems: xp.gems)),
                    SizedBox(height: 8 * s),
                    Expanded(
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(child: step(1, _Hero(scale: s, idle: _idle))),
                          SliverToBoxAdapter(child: SizedBox(height: 12 * s)),
                          SliverToBoxAdapter(
                            child: step(
                              2,
                              _Filters(
                                scale: s,
                                value: _filter,
                                onChanged: (c) {
                                  if (c == _filter) return;
                                  _audio.playEventSound('clickButton2');
                                  setState(() => _filter = c);
                                },
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(child: SizedBox(height: 12 * s)),
                          SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              mainAxisSpacing: 12 * s,
                              crossAxisSpacing: 12 * s,
                              childAspectRatio: 0.98,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final g = visible[i];
                                return step(
                                  3 + min(i, 6),
                                  _GameCard(
                                    key: ValueKey('${_filter.name}-${g['title']}'),
                                    scale: s,
                                    game: g,
                                    style: _styleOf(g['title']),
                                    title: gameTitle(tr(context), g['title']),
                                    stars: min(3, _plays[g['title']] ?? 0),
                                    unlocked: _isUnlocked(xp, g),
                                    playedToday: _doneToday.contains(g['title']),
                                    idle: _idle,
                                    phase: i * 0.13,
                                    onTap: () => _tapGame(g),
                                  ),
                                );
                              },
                              childCount: visible.length,
                            ),
                          ),
                          SliverToBoxAdapter(child: SizedBox(height: 96 * s + pad.bottom)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Today's challenge, pinned at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: pad.bottom + 10,
            child: Center(
              child: SizedBox(
                width: w,
                child: KidIntro(
                  intro: _intro,
                  from: 0.5,
                  to: 1.0,
                  rise: 40,
                  child: _ChallengeCard(
                    scale: s,
                    done: min(_doneToday.length, GameProgress.goal),
                    claimed: _claimed,
                    idle: _idle,
                    onGo: _playSuggested,
                  ),
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.05,
                  numberOfParticles: 40,
                  maxBlastForce: 22,
                  minBlastForce: 10,
                  gravity: 0.3,
                  colors: const [Color(0xFFFFC93C), Color(0xFF7B3FE4), Color(0xFFFF5FA2), Color(0xFF34D27A), Color(0xFF45AEEE)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Pieces
// ═══════════════════════════════════════════════════════════════════════════

const _ink = KidColors.ink;
const _cardCream = kidCardCream;

class _Hero extends StatelessWidget {
  final double scale;
  final Animation<double> idle;
  const _Hero({required this.scale, required this.idle});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final h = 128 * s;
    final r = 26 * s;
    TextStyle word(Color c, double size) => TextStyle(
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.w700,
          fontSize: size,
          height: 1.0,
          color: c,
          shadows: const [
            Shadow(color: Color(0xFF2A0F6B), offset: Offset(0, 2.5)),
            Shadow(color: Color(0x88000000), blurRadius: 6, offset: Offset(0, 3)),
          ],
        );
    return Container(
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r - 3),
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(GamesAssets.heroBg, fit: BoxFit.cover)),
            // Mascot (left) and gamepad (right) float gently.
            Positioned(
              left: -4 * s,
              bottom: -6 * s,
              child: AnimatedBuilder(
                animation: idle,
                builder: (_, c) => Transform.translate(
                  offset: Offset(0, sin(idle.value * 4 * pi) * 3 * s),
                  child: Transform.rotate(angle: sin(idle.value * 2 * pi) * 0.03, child: c),
                ),
                child: Image.asset(GamesAssets.mascot, height: 128 * s, width: 128 * s / 0.9027),
              ),
            ),
            Positioned(
              right: 4 * s,
              bottom: 8 * s,
              child: AnimatedBuilder(
                animation: idle,
                builder: (_, c) => Transform.translate(
                  offset: Offset(0, sin(idle.value * 4 * pi + 1.6) * 4 * s),
                  child: Transform.rotate(angle: -0.12 + sin(idle.value * 4 * pi) * 0.05, child: c),
                ),
                child: Image.asset(GamesAssets.pad, width: 104 * s, height: 104 * s * 0.6619),
              ),
            ),
            // Text in the middle
            Positioned(
              left: 128 * s,
              right: 104 * s,
              top: 10 * s,
              bottom: 10 * s,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: '${tr(context).heroPlay} ', style: word(Colors.white, 27 * s)),
                        TextSpan(text: tr(context).heroLearn, style: word(const Color(0xFFFFD447), 27 * s)),
                      ]),
                      textAlign: TextAlign.center,
                    ),
                    Text(tr(context).heroShine, style: word(const Color(0xFFFF7AD9), 31 * s)),
                    SizedBox(height: 4 * s),
                    SizedBox(
                      width: 150 * s,
                      child: Text(
                        tr(context).gamesHeroSub,
                        textAlign: TextAlign.center,
                        style: kidBodyStyle(11.5 * s, color: Colors.white, weight: FontWeight.w600)
                            .copyWith(shadows: const [Shadow(color: Color(0xAA1B1464), blurRadius: 4)]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final double scale;
  final GameCategory value;
  final ValueChanged<GameCategory> onChanged;
  const _Filters({required this.scale, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final labels = {
      GameCategory.all: tr(context).filterAll,
      GameCategory.words: tr(context).filterWords,
      GameCategory.logic: tr(context).filterLogic,
      GameCategory.creative: tr(context).filterCreative,
    };
    return Row(
      children: [
        for (final c in GameCategory.values) ...[
          if (c != GameCategory.all) SizedBox(width: 7 * s),
          Expanded(
            child: KidPressable(
              onTap: () => onChanged(c),
              pressedScale: 0.94,
              semanticLabel: labels[c],
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                height: 38 * s,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 6 * s),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  gradient: c == value
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF9B5CFF), Color(0xFF6A2BE0)])
                      : null,
                  color: c == value ? null : KidColors.cream,
                  border: Border.all(color: c == value ? const Color(0xFFB794FF) : Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: KidColors.purpleDeep.withOpacity(c == value ? 0.35 : 0.12),
                      blurRadius: c == value ? 10 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(labels[c]!,
                      maxLines: 1,
                      style: kidBodyStyle(15 * s,
                          color: c == value ? Colors.white : _ink, weight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  final double scale;
  final Map<String, dynamic> game;
  final _GameStyle style;
  final String title;
  final int stars;
  final bool unlocked, playedToday;
  final Animation<double> idle;
  final double phase;
  final VoidCallback onTap;

  const _GameCard({
    super.key,
    required this.scale,
    required this.game,
    required this.style,
    required this.title,
    required this.stars,
    required this.unlocked,
    required this.playedToday,
    required this.idle,
    required this.phase,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final r = 22 * s;
    final cost = (game['cost'] ?? 0) as int;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.95,
      semanticLabel: title,
      child: Container(
        decoration: BoxDecoration(
          color: _cardCream,
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.16), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r - 3),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _art(s),
                    if (!unlocked) ...[
                      ColoredBox(color: const Color(0xFF1B1464).withOpacity(0.45)),
                      Center(
                        child: AnimatedBuilder(
                          animation: idle,
                          builder: (_, c) => Transform.rotate(angle: sin((idle.value * 4 + phase) * 2 * pi) * 0.08, child: c),
                          child: Container(
                            width: 50 * s,
                            height: 50 * s,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.95),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10)],
                            ),
                            child: Icon(Icons.lock_rounded, color: KidColors.purpleDeep, size: 28 * s),
                          ),
                        ),
                      ),
                    ],
                    if (unlocked && playedToday)
                      PositionedDirectional(
                        top: 7 * s,
                        start: 7 * s,
                        child: Container(
                          padding: EdgeInsets.all(2.5 * s),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(Icons.check_circle_rounded, color: const Color(0xFF16A34A), size: 20 * s),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                height: 62 * s,
                color: _cardCream,
                padding: EdgeInsetsDirectional.only(start: 10 * s, end: 7 * s),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(title,
                                maxLines: 1,
                                style: kidTitleStyle(19 * s, color: _ink).copyWith(shadows: const [])),
                          ),
                          SizedBox(height: 3 * s),
                          if (unlocked)
                            Row(children: [
                              for (int i = 0; i < 3; i++)
                                Padding(
                                  padding: EdgeInsetsDirectional.only(end: 1 * s),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Image.asset(
                                      i < stars ? GamesAssets.starOn : GamesAssets.starOff,
                                      key: ValueKey(i < stars),
                                      width: 19 * s,
                                      height: 19 * s,
                                    ),
                                  ),
                                ),
                            ])
                          else
                            Container(
                              padding: EdgeInsetsDirectional.only(start: 2 * s, end: 8 * s, top: 1 * s, bottom: 1 * s),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3C4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Image.asset(GamesAssets.coin, width: 18 * s, height: 18 * s),
                                SizedBox(width: 3 * s),
                                Text(cost == 0 ? tr(context).free : '$cost',
                                    style: kidBodyStyle(13 * s, color: const Color(0xFF8A5A00), weight: FontWeight.w700)),
                              ]),
                            ),
                        ],
                      ),
                    ),
                    Transform.flip(
                      flipX: Directionality.of(context) == TextDirection.rtl,
                      child: Opacity(
                        opacity: unlocked ? 1 : 0.55,
                        child: Image.asset(GamesAssets.play(style.play), width: 44 * s, height: 44 * s),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _art(double s) {
    if (style.art != null) {
      return Image.asset(style.art!, fit: BoxFit.cover, alignment: Alignment.center, filterQuality: FilterQuality.medium);
    }
    // The game's own picture fills the whole tile (cropped, never letter-boxed).
    final img = (game['image'] ?? '') as String;
    if (img.isEmpty) {
      return KidIconArt(image: img, colors: style.backdrop, idle: idle, phase: phase, scale: s);
    }
    return Image.asset(img, fit: BoxFit.cover, alignment: const Alignment(0, -0.2), filterQuality: FilterQuality.medium);
  }
}

class _ChallengeCard extends StatelessWidget {
  final double scale;
  final int done;
  final bool claimed;
  final Animation<double> idle;
  final VoidCallback onGo;
  const _ChallengeCard({required this.scale, required this.done, required this.claimed, required this.idle, required this.onGo});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      height: 76 * s,
      padding: EdgeInsetsDirectional.only(start: 6 * s, end: 10 * s),
      decoration: BoxDecoration(
        color: _cardCream,
        borderRadius: BorderRadius.circular(26 * s),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: idle,
            builder: (_, c) => Transform.rotate(angle: sin(idle.value * 6 * pi) * 0.06, child: c),
            child: Image.asset(GamesAssets.trophy, width: 74 * s, height: 74 * s * 0.7471),
          ),
          SizedBox(width: 6 * s),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(tr(context).todaysChallenge, style: kidBodyStyle(18 * s, color: _ink, weight: FontWeight.w700)),
                ),
                SizedBox(height: 2 * s),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    claimed ? tr(context).challengeDone : tr(context).challengeGoal(GameProgress.goal),
                    style: kidBodyStyle(12.5 * s, color: KidColors.purpleDeep, weight: FontWeight.w600),
                  ),
                ),
                SizedBox(height: 4 * s),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 7 * s,
                    width: 110 * s,
                    child: Stack(children: [
                      const Positioned.fill(child: ColoredBox(color: Color(0xFFE3DAF8))),
                      AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutCubic,
                        widthFactor: claimed ? 1 : done / GameProgress.goal,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Color(0xFFFFC23A), Color(0xFFFFA514)])),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1.5, height: 40 * s, color: const Color(0xFFEADFC8)),
          SizedBox(width: 8 * s),
          claimed
              ? Icon(Icons.check_circle_rounded, color: const Color(0xFF16A34A), size: 34 * s)
              : Container(
                  padding: EdgeInsetsDirectional.only(start: 2 * s, end: 10 * s),
                  height: 38 * s,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFF1E6CC), width: 1.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Image.asset(GamesAssets.coin, width: 32 * s, height: 32 * s),
                    SizedBox(width: 3 * s),
                    Text('+${GameProgress.reward}', style: kidBodyStyle(18 * s, color: _ink, weight: FontWeight.w700)),
                  ]),
                ),
          SizedBox(width: 8 * s),
          KidPressable(
            onTap: onGo,
            semanticLabel: tr(context).playLabel,
            child: Transform.flip(
              flipX: Directionality.of(context) == TextDirection.rtl,
              child: Image.asset(GamesAssets.arrowNext, width: 44 * s, height: 44 * s),
            ),
          ),
        ],
      ),
    );
  }
}
