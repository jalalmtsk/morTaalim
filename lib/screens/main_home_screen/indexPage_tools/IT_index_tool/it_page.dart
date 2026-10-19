import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/Manager/lesson_progress.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/l10n/app_localizations.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/tools/loading_page.dart';
import 'package:mortaalim/widgets/KidScene/kid_page_parts.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';

import 'ComputerBasics/computer_basics_lesson.dart';
import 'ComputerBasics/computer_basics_menu.dart';

class ITAssets {
  ITAssets._();
  static const String dir = 'assets/images/UI/KidScene/';
  static const String heroBg = '${dir}it_hero_bg.webp';
  static const String pageBg = '${dir}it_page_bg.webp';
  static const String mascot = '${dir}it_mascot.webp';
  static const String medal = '${dir}courses_medal.webp';
  static const String play = '${dir}courses_play.webp';
  static String tile(String id) => '${dir}it_tile_$id.webp';
  static String go(String c) => '${dir}courses_go_$c.webp';

  static List<String> get all => [
        heroBg, pageBg, mascot, medal, play, kidCoinAsset, kidGemAsset,
        for (final t in ['basics', 'coding', 'typing', 'safety', 'robotics', 'creativity']) tile(t),
        for (final c in ['orange', 'green', 'blue', 'pink', 'purple']) go(c),
      ];
}

enum ITLevel { all, beginner, explorer, creator }

class ITLesson {
  final String Function(AppLocalizations) title;
  final String route; // named route in main.dart
  final String image;
  const ITLesson(this.title, this.route, this.image);
}

class ITTopic {
  final String id;
  final String Function(AppLocalizations) label;
  final ITLevel level;
  final String go;
  final List<ITLesson> lessons; // empty = coming soon
  const ITTopic(this.id, this.label, this.level, this.go, this.lessons);
  bool get available => lessons.isNotEmpty;
  String get art => ITAssets.tile(id);
}

/// Only lessons whose routes are live in main.dart are listed.
final List<ITTopic> itTopics = [
  // Opens the Computer Basics lesson map (computer_basics_menu.dart).
  ITTopic('basics', (t) => t.itBasics, ITLevel.beginner, 'orange', [
    for (final l in computerBasicsLessons) ITLesson((t) => t.itBasics, '', l.thumb),
  ]),
  ITTopic('coding', (t) => t.itCoding, ITLevel.explorer, 'purple', [
    ITLesson((t) => t.lessonBinary, 'IT_BinaryNumbers', 'assets/images/IT/binary.png'),
  ]),
  ITTopic('typing', (t) => t.itTyping, ITLevel.beginner, 'blue', const []),
  ITTopic('safety', (t) => t.itSafety, ITLevel.beginner, 'green', const []),
  ITTopic('robotics', (t) => t.itRobotics, ITLevel.explorer, 'orange', const []),
  ITTopic('creativity', (t) => t.itCreativity, ITLevel.creator, 'pink', const []),
];

const _ink = KidColors.ink;
const LessonTracker _tracker = LessonProgress.it;

void _comingSoonSnack(BuildContext context, String what) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: KidColors.purpleDeep,
    duration: const Duration(milliseconds: 1500),
    content: Text('$what · ${tr(context).comingSoon}', style: kidBodyStyle(15, color: Colors.white, weight: FontWeight.w600)),
  ));
}

/// Opens one lesson and records it.
Future<void> openITLesson(BuildContext context, ITTopic topic, int index) async {
  Provider.of<AudioManager>(context, listen: false).playEventSound('PopButton');
  await _tracker.record(topic.id, index);
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => LoadingPage(
        loadingFuture: Future.delayed(Duration(milliseconds: 900 + Random().nextInt(700))),
        nextRouteName: topic.lessons[index].route,
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// IT page
// ═══════════════════════════════════════════════════════════════════════════

class ITPage extends StatefulWidget {
  const ITPage({super.key});

  @override
  State<ITPage> createState() => _ITPageState();
}

class _ITPageState extends State<ITPage> with TickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  ITLevel _filter = ITLevel.all;
  LessonSnapshot _snap = LessonSnapshot.empty;
  bool _precached = false;
  bool _busy = false;

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
      KidAssets.precache(context, [...ITAssets.all, KidAssets.backBtn]);
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  Future<void> _refresh() async {
    final snap = await _tracker.load(itTopics.map((t) => t.id));
    if (!mounted) return;
    setState(() => _snap = snap);
    if (snap.learnedToday && !snap.claimedToday && await _tracker.claimToday() && mounted) {
      Provider.of<ExperienceManager>(context, listen: false).addTokenBanner(context, LessonTracker.goalReward);
      _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3');
      setState(() => _snap = LessonSnapshot(
          done: snap.done, lastSubject: snap.lastSubject, learnedToday: true, claimedToday: true));
    }
  }

  Future<void> _openTopic(ITTopic t) async {
    if (!t.available) {
      _audio.playEventSound('clickButton2');
      _comingSoonSnack(context, t.label(tr(context)));
      return;
    }
    if (_busy) return;
    _busy = true;
    _audio.playEventSound('clickButton');
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => t.id == 'basics' ? const ComputerBasicsMenuPage() : ITTopicPage(topic: t),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
    _busy = false;
    if (mounted) _refresh();
  }

  /// Continue: the next unopened lesson of the last topic (or the first one).
  Future<void> _continue(ITTopic t) async {
    if (t.id == 'basics') return _openTopic(t);
    if (_busy) return;
    _busy = true;
    final done = await _tracker.doneIn(t.id);
    var next = 0;
    while (next < t.lessons.length && done.contains(next)) {
      next++;
    }
    if (next >= t.lessons.length) next = 0;
    if (mounted) await openITLesson(context, t, next);
    _busy = false;
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final xp = Provider.of<ExperienceManager>(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 600.0) - 28;
    final s = (w / 380).clamp(0.8, 1.45);
    final cols = size.width >= 700 ? 3 : 2;
    final t = tr(context);
    final visible = _filter == ITLevel.all ? itTopics : itTopics.where((x) => x.level == _filter).toList();
    final live = itTopics.where((x) => x.available).toList();
    final current = live.firstWhere((x) => x.id == _snap.lastSubject, orElse: () => live.first);

    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.06 * i, to: min(1.0, 0.42 + 0.06 * i), rise: 24, child: child);

    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(
        children: [
          const Positioned.fill(child: KidPageBackground(asset: ITAssets.pageBg, wash: 0.04)),
          SafeArea(
            bottom: false,
            child: Center(
              child: SizedBox(
                width: w,
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    step(0, KidPageHeader(scale: s, title: t.homeIT, gold: xp.saveTokenCount, gems: xp.stars)),
                    SizedBox(height: 8 * s),
                    Expanded(
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: step(
                              1,
                              _ITHero(
                                scale: s,
                                idle: _idle,
                                topic: current,
                                done: min(current.lessons.length, _snap.done[current.id] ?? 0),
                                onContinue: () => _continue(current),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(child: SizedBox(height: 12 * s)),
                          SliverToBoxAdapter(
                            child: step(
                              2,
                              _LevelChips(
                                scale: s,
                                value: _filter,
                                onChanged: (v) {
                                  if (v == _filter) return;
                                  _audio.playEventSound('clickButton2');
                                  setState(() => _filter = v);
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
                              childAspectRatio: 1.08,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final tp = visible[i];
                                return step(
                                  3 + min(i, 6),
                                  _TopicCard(
                                    key: ValueKey('${_filter.name}-${tp.id}'),
                                    scale: s,
                                    topic: tp,
                                    done: min(tp.lessons.length, _snap.done[tp.id] ?? 0),
                                    idle: _idle,
                                    phase: i * 0.13,
                                    onTap: () => _openTopic(tp),
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
                  child: _TechChallenge(scale: s, idle: _idle, claimed: _snap.claimedToday),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ITHero extends StatelessWidget {
  final double scale;
  final Animation<double> idle;
  final ITTopic topic;
  final int done;
  final VoidCallback onContinue;
  const _ITHero({required this.scale, required this.idle, required this.topic, required this.done, required this.onContinue});

  TextStyle _word(Color c, double size) => TextStyle(
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

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    final h = 150 * s;
    final r = 26 * s;
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
            Positioned.fill(child: Image.asset(ITAssets.heroBg, fit: BoxFit.cover)),
            PositionedDirectional(
              start: -4 * s,
              bottom: -4 * s,
              child: AnimatedBuilder(
                animation: idle,
                builder: (_, c) => Transform.translate(
                  offset: Offset(0, sin(idle.value * 4 * pi) * 3 * s),
                  child: Transform.rotate(angle: sin(idle.value * 2 * pi) * 0.025, child: c),
                ),
                child: Image.asset(ITAssets.mascot, width: 140 * s, height: 140 * s * 0.8941),
              ),
            ),
            PositionedDirectional(
              start: 136 * s,
              end: 10 * s,
              top: 10 * s,
              height: 72 * s,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(t.itHeroTop, style: _word(Colors.white, 22 * s)),
                  SizedBox(height: 2 * s),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFFFFE04A), Color(0xFFFFB627), Color(0xFFFF7AD9), Color(0xFFC08BFF)],
                    ).createShader(b),
                    child: Text(t.itHeroBottom, style: _word(Colors.white, 31 * s)),
                  ),
                  SizedBox(height: 4 * s),
                  Text(t.itHeroSub,
                      style: kidBodyStyle(11 * s, color: Colors.white, weight: FontWeight.w600)
                          .copyWith(shadows: const [Shadow(color: Color(0xAA1B1464), blurRadius: 4)])),
                ]),
              ),
            ),
            PositionedDirectional(
              start: 128 * s,
              end: 8 * s,
              bottom: 8 * s,
              height: 56 * s,
              child: Container(
                padding: EdgeInsetsDirectional.only(start: 10 * s, end: 4 * s),
                decoration: BoxDecoration(
                  color: kidCardCream.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(18 * s),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(topic.label(t),
                              maxLines: 1, style: kidBodyStyle(14 * s, color: _ink, weight: FontWeight.w700)),
                        ),
                        SizedBox(height: 4 * s),
                        Row(children: [
                          Expanded(child: KidProgressBar(value: done / topic.lessons.length, height: 8 * s)),
                          SizedBox(width: 6 * s),
                          Text(t.lessonsCount(done, topic.lessons.length),
                              style: kidBodyStyle(10.5 * s, color: KidColors.muted, weight: FontWeight.w600)),
                        ]),
                      ],
                    ),
                  ),
                  SizedBox(width: 6 * s),
                  KidPressable(
                    onTap: onContinue,
                    pressedScale: 0.93,
                    child: Container(
                      height: 46 * s,
                      padding: EdgeInsets.symmetric(horizontal: 12 * s),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16 * s),
                        gradient: const LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [Color(0xFFFFDF4F), Color(0xFFFFB21A)]),
                        border: Border.all(color: const Color(0xFFFFF0A8), width: 1.5),
                        boxShadow: [BoxShadow(color: const Color(0xFFC2620A).withOpacity(0.45), offset: Offset(0, 3 * s))],
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Transform.flip(
                          flipX: Directionality.of(context) == TextDirection.rtl,
                          child: Image.asset(ITAssets.play, height: 16 * s, width: 16 * s / 1.1733),
                        ),
                        SizedBox(height: 1 * s),
                        Text(done > 0 ? t.continueLabel : t.startLabel,
                            style: kidBodyStyle(13 * s, color: const Color(0xFF7A2E00), weight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelChips extends StatelessWidget {
  final double scale;
  final ITLevel value;
  final ValueChanged<ITLevel> onChanged;
  const _LevelChips({required this.scale, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    final labels = {
      ITLevel.all: t.filterAll,
      ITLevel.beginner: t.levelBeginner,
      ITLevel.explorer: t.levelExplorer,
      ITLevel.creator: t.levelCreator,
    };
    return Row(children: [
      for (final c in ITLevel.values) ...[
        if (c != ITLevel.all) SizedBox(width: 7 * s),
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
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Color(0xFF9B5CFF), Color(0xFF6A2BE0)])
                    : null,
                color: c == value ? null : KidColors.cream,
                border: Border.all(color: c == value ? const Color(0xFFB794FF) : Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: KidColors.purpleDeep.withOpacity(c == value ? 0.35 : 0.12),
                      blurRadius: c == value ? 10 : 6,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(labels[c]!,
                    maxLines: 1,
                    style: kidBodyStyle(15 * s, color: c == value ? Colors.white : _ink, weight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      ],
    ]);
  }
}

class _TopicCard extends StatelessWidget {
  final double scale;
  final ITTopic topic;
  final int done;
  final Animation<double> idle;
  final double phase;
  final VoidCallback onTap;
  const _TopicCard({super.key, required this.scale, required this.topic, required this.done, required this.idle,
      required this.phase, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    final r = 22 * s;
    final ok = topic.available;
    final label = topic.label(t);
    final total = topic.lessons.length;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.95,
      semanticLabel: label,
      child: Container(
        decoration: kidCardDecoration(r),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r - 3),
          child: Column(children: [
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                Image.asset(topic.art, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
                if (!ok) ...[
                  ColoredBox(color: Colors.white.withOpacity(0.35)),
                  PositionedDirectional(
                    top: 8 * s,
                    end: 8 * s,
                    child: AnimatedBuilder(
                      animation: idle,
                      builder: (_, c) => Transform.rotate(angle: sin((idle.value * 4 + phase) * 2 * pi) * 0.06, child: c),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(colors: [Color(0xFF9B5CFF), Color(0xFF6A2BE0)]),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(t.soonBadge, style: kidBodyStyle(12 * s, color: Colors.white, weight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
                if (ok && done >= total)
                  PositionedDirectional(
                    top: 7 * s,
                    start: 7 * s,
                    child: Container(
                      padding: EdgeInsets.all(2.5 * s),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(Icons.emoji_events_rounded, color: const Color(0xFFF59E0B), size: 20 * s),
                    ),
                  ),
              ]),
            ),
            Container(
              height: 62 * s,
              color: kidCardCream,
              padding: EdgeInsetsDirectional.only(start: 10 * s, end: 7 * s),
              child: Row(children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(label, maxLines: 1, style: kidTitleStyle(19 * s, color: _ink).copyWith(shadows: const [])),
                      ),
                      SizedBox(height: 5 * s),
                      if (ok)
                        Row(children: [
                          Expanded(child: KidProgressBar(value: done / total, height: 8 * s)),
                          SizedBox(width: 6 * s),
                          Text(t.lessonsCount(done, total),
                              style: kidBodyStyle(10.5 * s, color: KidColors.muted, weight: FontWeight.w600)),
                        ])
                      else
                        Text(t.comingSoon, style: kidBodyStyle(11.5 * s, color: KidColors.muted, weight: FontWeight.w600)),
                    ],
                  ),
                ),
                SizedBox(width: 4 * s),
                Transform.flip(
                  flipX: Directionality.of(context) == TextDirection.rtl,
                  child: Opacity(
                    opacity: ok ? 1 : 0.45,
                    child: Image.asset(ITAssets.go(topic.go), width: 42 * s, height: 42 * s),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _TechChallenge extends StatelessWidget {
  final double scale;
  final Animation<double> idle;
  final bool claimed;
  const _TechChallenge({required this.scale, required this.idle, required this.claimed});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    return Container(
      height: 76 * s,
      padding: EdgeInsetsDirectional.only(start: 8 * s, end: 12 * s),
      decoration: kidCardDecoration(26 * s, shadow: 0.25),
      child: Row(children: [
        AnimatedBuilder(
          animation: idle,
          builder: (_, c) => Transform.rotate(angle: sin(idle.value * 6 * pi) * 0.06, child: c),
          child: Image.asset(ITAssets.medal, width: 52 * s, height: 52 * s * 1.1),
        ),
        SizedBox(width: 10 * s),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(t.techChallenge, style: kidBodyStyle(18 * s, color: _ink, weight: FontWeight.w700)),
              ),
              SizedBox(height: 2 * s),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(claimed ? t.learningGoalDone : t.techChallengeMsg,
                    style: kidBodyStyle(12.5 * s, color: KidColors.purpleDeep, weight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        Container(width: 1.5, height: 40 * s, color: const Color(0xFFEADFC8)),
        SizedBox(width: 10 * s),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
          child: claimed
              ? Icon(Icons.check_circle_rounded, key: const ValueKey('ok'), color: const Color(0xFF16A34A), size: 36 * s)
              : Container(
                  key: const ValueKey('reward'),
                  padding: EdgeInsetsDirectional.only(start: 2 * s, end: 10 * s),
                  height: 40 * s,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFF1E6CC), width: 1.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Image.asset(kidCoinAsset, width: 34 * s, height: 34 * s),
                    SizedBox(width: 3 * s),
                    Text('+${LessonTracker.goalReward}', style: kidBodyStyle(18 * s, color: _ink, weight: FontWeight.w700)),
                  ]),
                ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Topic page: the lessons inside one topic
// ═══════════════════════════════════════════════════════════════════════════

class ITTopicPage extends StatefulWidget {
  final ITTopic topic;
  const ITTopicPage({super.key, required this.topic});

  @override
  State<ITTopicPage> createState() => _ITTopicPageState();
}

class _ITTopicPageState extends State<ITTopicPage> with TickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();
  Set<int> _done = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final d = await _tracker.doneIn(widget.topic.id);
    if (mounted) setState(() => _done = d);
  }

  Future<void> _open(int i) async {
    if (_busy) return;
    _busy = true;
    await openITLesson(context, widget.topic, i);
    _busy = false;
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final xp = Provider.of<ExperienceManager>(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 600.0) - 28;
    final s = (w / 380).clamp(0.8, 1.45);
    final t = tr(context);
    final topic = widget.topic;
    final total = topic.lessons.length;
    final done = _done.where((i) => i < total).length;

    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.07 * i, to: min(1.0, 0.45 + 0.07 * i), rise: 22, child: child);

    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(children: [
        const Positioned.fill(child: KidPageBackground(asset: ITAssets.pageBg, wash: 0.04)),
        SafeArea(
          bottom: false,
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                const SizedBox(height: 6),
                step(0, KidPageHeader(scale: s, title: topic.label(t), gold: xp.saveTokenCount, gems: xp.stars)),
                SizedBox(height: 10 * s),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: pad.bottom + 20),
                    children: [
                      step(
                        1,
                        Container(
                          decoration: kidCardDecoration(24 * s, shadow: 0.22),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24 * s - 3),
                            child: Column(children: [
                              AspectRatio(
                                aspectRatio: 1 / 0.4164,
                                child: Image.asset(topic.art, fit: BoxFit.cover, filterQuality: FilterQuality.medium),
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(14 * s, 10 * s, 14 * s, 12 * s),
                                child: Row(children: [
                                  Expanded(child: KidProgressBar(value: total == 0 ? 0 : done / total, height: 10 * s)),
                                  SizedBox(width: 10 * s),
                                  Text(t.lessonsCount(done, total),
                                      style: kidBodyStyle(13 * s, color: _ink, weight: FontWeight.w700)),
                                ]),
                              ),
                            ]),
                          ),
                        ),
                      ),
                      SizedBox(height: 14 * s),
                      for (int i = 0; i < total; i++) ...[
                        step(
                          2 + min(i, 6),
                          _LessonRow(
                            scale: s,
                            index: i,
                            lesson: topic.lessons[i],
                            done: _done.contains(i),
                            go: topic.go,
                            onTap: () => _open(i),
                          ),
                        ),
                        SizedBox(height: 10 * s),
                      ],
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _LessonRow extends StatelessWidget {
  final double scale;
  final int index;
  final ITLesson lesson;
  final bool done;
  final String go;
  final VoidCallback onTap;
  const _LessonRow({required this.scale, required this.index, required this.lesson, required this.done,
      required this.go, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.96,
      semanticLabel: lesson.title(t),
      child: Container(
        height: 78 * s,
        padding: EdgeInsetsDirectional.only(start: 8 * s, end: 10 * s),
        decoration: kidCardDecoration(22 * s),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16 * s),
            child: Image.asset(lesson.image, width: 60 * s, height: 60 * s, fit: BoxFit.cover),
          ),
          SizedBox(width: 12 * s),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.lessonN(index + 1),
                    style: kidBodyStyle(12 * s, color: KidColors.purpleDeep, weight: FontWeight.w700)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(lesson.title(t),
                      maxLines: 1, style: kidBodyStyle(17 * s, color: _ink, weight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          if (done) ...[
            Icon(Icons.check_circle_rounded, color: const Color(0xFF16A34A), size: 26 * s),
            SizedBox(width: 6 * s),
          ],
          Transform.flip(
            flipX: Directionality.of(context) == TextDirection.rtl,
            child: Image.asset(ITAssets.go(go), width: 42 * s, height: 42 * s),
          ),
        ]),
      ),
    );
  }
}
