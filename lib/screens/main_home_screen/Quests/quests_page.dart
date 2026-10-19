import 'package:mortaalim/widgets/KidScene/kid_toast.dart';
import 'package:mortaalim/widgets/KidScene/glossy_bar.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:mortaalim/Manager/lesson_progress.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/screens/main_home_screen/indexPage_tools/Course_index_tool/courses_page.dart';
import 'package:mortaalim/screens/main_home_screen/indexPage_tools/Game_index_tool/game_data.dart';
import 'package:mortaalim/screens/main_home_screen/indexPage_tools/Game_index_tool/games_page.dart';
import 'package:mortaalim/screens/main_home_screen/indexPage_tools/IT_index_tool/it_page.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_page_parts.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuestAssets {
  QuestAssets._();
  static const String dir = 'assets/images/UI/KidScene/';
  static const String heroBg = '${dir}quest_hero_bg.webp';
  static const String mascot = '${dir}quest_mascot.webp';
  static const String chest = '${dir}quest_chest.webp';
  static const String chestOpen = '${dir}quest_chest_open.webp';
  static const String calendar = '${dir}quest_calendar.webp';
  static const String trophy = '${dir}quest_trophy.webp';
  static const String book = '${dir}quest_icon_book.webp';
  static const String games = '${dir}quest_icon_games.webp';
  static const String robot = '${dir}quest_icon_robot.webp';
  static const String btnGreen = '${dir}quest_btn_green.webp';
  static const String btnLavender = '${dir}quest_btn_lavender.webp';
  static const String check = '${dir}quest_check.webp';
  static const String laurel = '${dir}quest_laurel.webp';

  static const all = [heroBg, mascot, chest, chestOpen, calendar, trophy, book, games, robot, btnGreen, btnLavender, check, laurel];
}

// ═══════════════════════════════════════════════════════════════════════════
// Data
// ═══════════════════════════════════════════════════════════════════════════

enum QuestReward { gold, gems }

class DailyQuest {
  final String id;
  final String icon;
  final List<Color> bar;
  final int goal;
  final QuestReward rewardType;
  final int reward;
  const DailyQuest(this.id, this.icon, this.bar, this.goal, this.rewardType, this.reward);
}

const List<DailyQuest> dailyQuests = [
  DailyQuest('reader', QuestAssets.book, [Color(0xFF9B5CFF), Color(0xFF6A2BE0)], 1, QuestReward.gold, 20),
  DailyQuest('player', QuestAssets.games, [Color(0xFFFF7AB8), Color(0xFFEC3F8C)], 2, QuestReward.gold, 30),
  DailyQuest('tech', QuestAssets.robot, [Color(0xFFFFD84A), Color(0xFFFFB21A)], 1, QuestReward.gems, 2),
];

class Milestone {
  final String track; // 'lessons' | 'games'
  final int target, gems;
  const Milestone(this.track, this.target, this.gems);
  String get key => '${track}_$target';
}

const List<Milestone> milestones = [
  Milestone('lessons', 5, 2), Milestone('games', 5, 2),
  Milestone('lessons', 10, 3), Milestone('games', 15, 3),
  Milestone('lessons', 25, 5), Milestone('games', 30, 5),
  Milestone('lessons', 50, 10), Milestone('games', 60, 10),
  Milestone('lessons', 100, 20), Milestone('games', 100, 20),
];

const int treasureGems = 5;

/// Everything the page shows, read from what the other pages record.
class QuestState {
  final Map<String, int> progress; // quest id → progress today
  final Set<String> claimed; // quest ids claimed today
  final bool treasureClaimed;
  final int totalLessons, totalGames;
  final Set<String> milestonesClaimed;
  const QuestState(this.progress, this.claimed, this.treasureClaimed, this.totalLessons, this.totalGames, this.milestonesClaimed);
  static const empty = QuestState({}, {}, false, 0, 0, {});

  int total(String track) => track == 'lessons' ? totalLessons : totalGames;
  bool ready(DailyQuest q) => (progress[q.id] ?? 0) >= q.goal;

  /// Daily quests whose reward has been collected.
  int get claimedCount => dailyQuests.where((q) => claimed.contains(q.id)).length;

  Milestone? get nextMilestone {
    for (final m in milestones.where((m) => m.track == 'lessons')) {
      if (!milestonesClaimed.contains(m.key)) return m;
    }
    return null;
  }

  int get readyMilestones =>
      milestones.where((m) => !milestonesClaimed.contains(m.key) && total(m.track) >= m.target).length;
}

class QuestStore {
  static const _kClaimPrefix = 'quest_claim_';
  static const _kTreasure = 'quest_treasure_day';
  static const _kMilestones = 'milestones_claimed';
  static final _lessonKey = RegExp(r'^(?:it_|religion_)?lessons_done_');

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  static Future<QuestState> load() async {
    final p = await SharedPreferences.getInstance();
    final today = _today();
    final courses = await LessonProgress.courses.load(const []);
    final it = await LessonProgress.it.load(const []);
    final (_, gamesToday, _) = await GameProgress.load(games.map((g) => g['title'] as String));

    var lessons = 0, plays = 0;
    for (final k in p.getKeys()) {
      if (_lessonKey.hasMatch(k)) lessons += (p.getStringList(k) ?? const []).length;
      if (k.startsWith('games_plays_')) plays += p.getInt(k) ?? 0;
    }

    return QuestState(
      {
        'reader': courses.learnedToday ? 1 : 0,
        'player': min(2, gamesToday.length),
        'tech': it.learnedToday ? 1 : 0,
      },
      {for (final q in dailyQuests) if (p.getString('$_kClaimPrefix${q.id}') == today) q.id},
      p.getString(_kTreasure) == today,
      lessons,
      plays,
      (p.getStringList(_kMilestones) ?? const []).toSet(),
    );
  }

  static Future<bool> claimQuest(String id) async {
    final p = await SharedPreferences.getInstance();
    if (p.getString('$_kClaimPrefix$id') == _today()) return false;
    await p.setString('$_kClaimPrefix$id', _today());
    return true;
  }

  static Future<bool> claimTreasure() async {
    final p = await SharedPreferences.getInstance();
    if (p.getString(_kTreasure) == _today()) return false;
    await p.setString(_kTreasure, _today());
    return true;
  }

  static Future<bool> claimMilestone(Milestone m) async {
    final p = await SharedPreferences.getInstance();
    final set = (p.getStringList(_kMilestones) ?? const []).toSet();
    if (!set.add(m.key)) return false;
    await p.setStringList(_kMilestones, set.toList());
    return true;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Page
// ═══════════════════════════════════════════════════════════════════════════

class QuestsPage extends StatefulWidget {
  final bool startOnMilestones;
  final bool embedded; // shown as a bottom-bar tab: no back button
  const QuestsPage({super.key, this.startOnMilestones = false, this.embedded = false});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> with TickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late bool _milestonesTab = widget.startOnMilestones;
  QuestState _q = QuestState.empty;
  Timer? _clock;
  Duration _left = Duration.zero;
  bool _precached = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tick();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _refresh();
  }

  void _tick() {
    final now = DateTime.now();
    final left = DateTime(now.year, now.month, now.day + 1).difference(now);
    if (left.inSeconds > _left.inSeconds && _left != Duration.zero) _refresh(); // a new day began
    if (mounted) setState(() => _left = left);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      KidAssets.precache(context, [...QuestAssets.all, KidAssets.valleyBg, KidAssets.backBtn, kidCoinAsset, kidGemAsset]);
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);
  ExperienceManager get _xp => Provider.of<ExperienceManager>(context, listen: false);

  Future<void> _refresh() async {
    final q = await QuestStore.load();
    if (mounted) setState(() => _q = q);
  }

  void _celebrate() => _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3');

  Future<void> _claim(DailyQuest q) async {
    if (!_q.ready(q) || !await QuestStore.claimQuest(q.id) || !mounted) return;
    KidToast.show(KidToastKind.quest);
    if (q.rewardType == QuestReward.gold) {
      _xp.addTokenBanner(context, q.reward);
    } else {
      _xp.addGems(context, q.reward);
    }
    _celebrate();
    _refresh();
  }

  Future<void> _go(DailyQuest q) async {
    if (_busy) return;
    _busy = true;
    _audio.playEventSound('clickButton');
    final Widget page = switch (q.id) {
      'reader' => const CoursesPage(),
      'player' => const GamesPage(),
      _ => const ITPage(),
    };
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
    _busy = false;
    if (mounted) _refresh();
  }

  Future<void> _claimTreasure() async {
    if (_q.claimedCount < dailyQuests.length || !await QuestStore.claimTreasure() || !mounted) return;
    KidToast.show(KidToastKind.quest);
    _xp.addGems(context, treasureGems);
    _celebrate();
    _refresh();
  }

  Future<void> _claimMilestone(Milestone m) async {
    if (_q.total(m.track) < m.target || !await QuestStore.claimMilestone(m) || !mounted) return;
    KidToast.show(KidToastKind.quest);
    _xp.addGems(context, m.gems);
    _celebrate();
    _refresh();
  }

  void _setTab(bool milestones) {
    if (milestones == _milestonesTab) return;
    _audio.playEventSound('clickButton2');
    setState(() => _milestonesTab = milestones);
  }

  String _hms(Duration d) =>
      '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final xp = Provider.of<ExperienceManager>(context);
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final w = min(size.width, 600.0) - 28;
    final s = (w / 380).clamp(0.8, 1.45);
    final t = tr(context);

    Widget step(int i, Widget child) =>
        KidIntro(intro: _intro, from: 0.06 * i, to: min(1.0, 0.42 + 0.06 * i), rise: 24, child: child);

    final List<Widget> body = _milestonesTab
        ? [
            for (final m in milestones)
              _MilestoneCard(
                scale: s,
                milestone: m,
                value: _q.total(m.track),
                claimed: _q.milestonesClaimed.contains(m.key),
                onClaim: () => _claimMilestone(m),
              ),
          ]
        : [
            for (final q in dailyQuests)
              _QuestCard(
                scale: s,
                quest: q,
                value: min(q.goal, _q.progress[q.id] ?? 0),
                claimed: _q.claimed.contains(q.id),
                idle: _idle,
                onClaim: () => _claim(q),
                onGo: () => _go(q),
              ),
            _TreasureCard(
              scale: s,
              idle: _idle,
              claimedQuests: _q.claimedCount,
              opened: _q.treasureClaimed,
              onClaim: _claimTreasure,
            ),
            _NextMilestoneCard(
              scale: s,
              milestone: _q.nextMilestone,
              value: _q.totalLessons,
              ready: _q.readyMilestones,
              onTap: () => _setTab(true),
            ),
          ];

    return Scaffold(
      backgroundColor: KidColors.sky,
      body: Stack(children: [
        const Positioned.fill(child: KidPageBackground()),
        SafeArea(
          bottom: false,
          child: Center(
            child: SizedBox(
              width: w,
              child: Column(children: [
                const SizedBox(height: 6),
                step(0, KidPageHeader(scale: s, title: t.navQuests, gold: xp.gold, gems: xp.gems, showBack: !widget.embedded)),
                SizedBox(height: 8 * s),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: pad.bottom + 24),
                    children: [
                      step(1, _Hero(scale: s, idle: _idle)),
                      SizedBox(height: 12 * s),
                      step(2, _Tabs(scale: s, milestones: _milestonesTab, badge: _q.readyMilestones, onChanged: _setTab)),
                      SizedBox(height: 8 * s),
                      if (!_milestonesTab)
                        step(
                          3,
                          Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 4 * s),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3EEFF).withOpacity(0.95),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Text.rich(
                                TextSpan(children: [
                                  TextSpan(text: '${t.newQuestsIn} '),
                                  TextSpan(
                                    text: _hms(_left),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]),
                                  ),
                                ]),
                                style: kidBodyStyle(13 * s, color: _ink, weight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: 10 * s),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (c, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                              position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(a), child: c),
                        ),
                        child: Column(
                          key: ValueKey(_milestonesTab),
                          children: [
                            for (int i = 0; i < body.length; i++) ...[
                              step(4 + min(i, 6), body[i]),
                              SizedBox(height: 10 * s),
                            ],
                          ],
                        ),
                      ),
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

// ═══════════════════════════════════════════════════════════════════════════
// Pieces
// ═══════════════════════════════════════════════════════════════════════════

const _ink = KidColors.ink;
const _panel = Color(0xFFF7EEDD);

/// One-line text that shrinks instead of overflowing.
Widget _fit(String text, TextStyle style, {AlignmentGeometry align = AlignmentDirectional.centerStart, TextAlign? textAlign}) =>
    FittedBox(
      fit: BoxFit.scaleDown,
      alignment: align,
      child: Text(text, maxLines: 1, softWrap: false, textAlign: textAlign, style: style),
    );

TextStyle _heroWord(Color c, double size) => TextStyle(
      fontFamily: 'Fredoka',
      fontWeight: FontWeight.w700,
      fontSize: size,
      height: 1.05,
      color: c,
      shadows: const [
        Shadow(color: Color(0xFF2A0F6B), offset: Offset(0, 2.5)),
        Shadow(color: Color(0x88000000), blurRadius: 6, offset: Offset(0, 3)),
      ],
    );

class _Hero extends StatelessWidget {
  final double scale;
  final Animation<double> idle;
  const _Hero({required this.scale, required this.idle});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    final r = 26 * s;
    return AspectRatio(
      aspectRatio: 2.55, // keeps the scene's proportions on every screen
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r - 3),
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth, h = c.maxHeight;
            final mascotH = h * 0.86;
            final mascotW = mascotH / 1.1086;
            final chestW = w * 0.22;
            return Stack(children: [
              Positioned.fill(child: Image.asset(QuestAssets.heroBg, fit: BoxFit.cover, alignment: Alignment.centerRight)),
              // soft shade behind the text so it reads on the starry sky
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      colors: [const Color(0xFF1B1464).withOpacity(0.35), Colors.transparent],
                      stops: const [0.3, 0.7],
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                end: -w * 0.01,
                bottom: -h * 0.04,
                child: AnimatedBuilder(
                  animation: idle,
                  builder: (_, ch) => Transform.rotate(angle: sin(idle.value * 6 * pi) * 0.03, child: ch),
                  child: Image.asset(QuestAssets.chestOpen, width: chestW, height: chestW * 0.8471),
                ),
              ),
              PositionedDirectional(
                end: chestW * 0.62,
                bottom: -h * 0.03,
                child: AnimatedBuilder(
                  animation: idle,
                  builder: (_, ch) => Transform.translate(offset: Offset(0, sin(idle.value * 4 * pi) * 3 * s), child: ch),
                  child: Image.asset(QuestAssets.mascot, width: mascotW, height: mascotH),
                ),
              ),
              PositionedDirectional(
                start: w * 0.045,
                top: h * 0.1,
                bottom: h * 0.1,
                width: w * 0.54,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fit(t.questHeroTop, _heroWord(Colors.white, h * 0.2)),
                    _fit(t.questHeroBottom, _heroWord(const Color(0xFFFFD447), h * 0.19)),
                    SizedBox(height: h * 0.06),
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: _fit(t.questHeroSub, kidBodyStyle(12 * s, color: KidColors.purpleDeep, weight: FontWeight.w700),
                            align: Alignment.center),
                      ),
                    ),
                  ],
                ),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final double scale;
  final bool milestones;
  final int badge;
  final ValueChanged<bool> onChanged;
  const _Tabs({required this.scale, required this.milestones, required this.badge, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    Widget tab(bool isMilestones, String icon, String label) {
      final active = milestones == isMilestones;
      return Expanded(
        child: KidPressable(
          onTap: () => onChanged(isMilestones),
          pressedScale: 0.95,
          semanticLabel: label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            height: 50 * s,
            padding: EdgeInsets.symmetric(horizontal: 10 * s),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: active
                  ? const LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9B5CFF), Color(0xFF6A2BE0)])
                  : null,
              color: active ? null : KidColors.cream,
              border: Border.all(color: active ? const Color(0xFFB794FF) : Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                    color: KidColors.purpleDeep.withOpacity(active ? 0.35 : 0.12),
                    blurRadius: active ? 10 : 6,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Image.asset(icon, width: 30 * s, height: 30 * s),
                  SizedBox(width: 8 * s),
                  Text(label, maxLines: 1, style: kidBodyStyle(18 * s, color: active ? Colors.white : _ink, weight: FontWeight.w700)),
                  if (isMilestones && badge > 0) ...[
                    SizedBox(width: 6 * s),
                    Container(
                      width: 22 * s,
                      height: 22 * s,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF4D6D)),
                      child: Text('$badge', style: kidBodyStyle(12 * s, color: Colors.white, weight: FontWeight.w700)),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: [
      tab(false, QuestAssets.calendar, t.questDaily),
      SizedBox(width: 10 * s),
      tab(true, QuestAssets.trophy, t.questMilestones),
    ]);
  }
}

class _Bar extends StatelessWidget {
  final double value, height;
  final List<Color> colors;
  const _Bar({required this.value, required this.height, required this.colors});

  @override
  Widget build(BuildContext context) =>
      GlossyBar(value: value, height: height * 1.5, color: GlossyBar.forColor(colors.last));
}

/// Glossy 3D pill button drawn in code, so it keeps its round ends at any
/// width (the sliced sprites would stretch). Label is always centred and
/// shrinks to fit.
class _GlossyButton extends StatelessWidget {
  final double scale;
  final String label;
  final List<Color> colors; // top, bottom
  final Color lip, textColor;
  final bool arrow;
  final VoidCallback? onTap;
  const _GlossyButton({super.key, required this.scale, required this.label, required this.colors, required this.lip,
      required this.textColor, this.arrow = false, this.onTap});

  static const green = [Color(0xFF5BE37D), Color(0xFF1FA845)];
  static const greenLip = Color(0xFF137A31);
  static const lavender = [Color(0xFFEDE5FF), Color(0xFFD3C2FF)];
  static const lavenderLip = Color(0xFFB59DF0);
  static const purple = [Color(0xFF8B5CF6), Color(0xFF5B21B6)];
  static const purpleLip = Color(0xFF3F1690);

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final h = 40 * s;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.93,
      semanticLabel: label,
      child: Container(
        height: h,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(h),
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
          border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
          boxShadow: [
            BoxShadow(color: lip, offset: Offset(0, 3 * s)),
            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: Offset(0, 5 * s)),
          ],
        ),
        child: Stack(children: [
          // top shine
          Positioned(
            left: h * 0.35,
            right: h * 0.35,
            top: h * 0.1,
            height: h * 0.28,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(h),
                color: Colors.white.withOpacity(0.32),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10 * s),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(label,
                        maxLines: 1,
                        style: kidBodyStyle(18 * s, color: textColor, weight: FontWeight.w700).copyWith(
                          height: 1.0,
                          shadows: textColor == Colors.white
                              ? const [Shadow(color: Color(0x55000000), offset: Offset(0, 1.5), blurRadius: 2)]
                              : null,
                        )),
                    if (arrow) ...[
                      SizedBox(width: 2 * s),
                      Transform.flip(
                        flipX: Directionality.of(context) == TextDirection.rtl,
                        child: Icon(Icons.chevron_right_rounded, color: textColor, size: 24 * s),
                      ),
                    ],
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

Widget _rewardLabel(double s, QuestReward type, int amount) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Image.asset(type == QuestReward.gold ? kidCoinAsset : kidGemAsset, width: 28 * s, height: 28 * s),
        SizedBox(width: 4 * s),
        Text('+$amount', style: kidBodyStyle(18 * s, color: _ink, weight: FontWeight.w700).copyWith(height: 1.0)),
      ]),
    );

Widget _doneChip(double s, String label) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Image.asset(QuestAssets.check, width: 26 * s, height: 26 * s),
        SizedBox(width: 4 * s),
        Text(label, style: kidBodyStyle(15 * s, color: const Color(0xFF16A34A), weight: FontWeight.w700)),
      ]),
    );

/// Reward on top, action underneath, in a soft panel of fixed width.
Widget _rewardPanel(double s, {required Widget reward, required Widget action, Color color = _panel}) => Container(
      width: 112 * s,
      padding: EdgeInsets.fromLTRB(8 * s, 8 * s, 8 * s, 10 * s),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18 * s)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(height: 30 * s, child: Center(child: reward)),
        SizedBox(height: 6 * s),
        SizedBox(height: 43 * s, child: Center(child: action)),
      ]),
    );

class _QuestCard extends StatelessWidget {
  final double scale;
  final DailyQuest quest;
  final int value;
  final bool claimed;
  final Animation<double> idle;
  final VoidCallback onClaim, onGo;
  const _QuestCard({required this.scale, required this.quest, required this.value, required this.claimed,
      required this.idle, required this.onClaim, required this.onGo});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    final ready = value >= quest.goal;
    final (title, sub) = switch (quest.id) {
      'reader' => (t.questReader, t.questReaderSub),
      'player' => (t.questPlayer, t.challengeGoal(quest.goal)),
      _ => (t.questTech, t.questTechSub),
    };
    return Container(
      padding: EdgeInsets.all(8 * s),
      decoration: kidCardDecoration(24 * s),
      child: Row(children: [
        AnimatedBuilder(
          animation: idle,
          builder: (_, c) => Transform.scale(scale: ready && !claimed ? 1 + 0.03 * sin(idle.value * 12 * pi) : 1, child: c),
          child: SizedBox(
            width: 76 * s,
            height: 76 * s,
            child: Image.asset(quest.icon, fit: BoxFit.contain),
          ),
        ),
        SizedBox(width: 10 * s),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fit(title, kidTitleStyle(19 * s, color: _ink).copyWith(shadows: const [])),
              SizedBox(height: 2 * s),
              _fit(sub, kidBodyStyle(12.5 * s, color: KidColors.purple, weight: FontWeight.w600)),
              SizedBox(height: 8 * s),
              _Bar(value: value / quest.goal, height: 10 * s, colors: quest.bar),
              SizedBox(height: 4 * s),
              Text('$value / ${quest.goal}', style: kidBodyStyle(12 * s, color: _ink, weight: FontWeight.w700)),
            ],
          ),
        ),
        SizedBox(width: 10 * s),
        _rewardPanel(
          s,
          reward: _rewardLabel(s, quest.rewardType, quest.reward),
          action: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: claimed
                ? KeyedSubtree(key: const ValueKey('done'), child: _doneChip(s, t.doneLabel))
                : ready
                    ? _GlossyButton(
                        key: const ValueKey('claim'),
                        scale: s,
                        label: t.claimLabel,
                        colors: _GlossyButton.green,
                        lip: _GlossyButton.greenLip,
                        textColor: Colors.white,
                        onTap: onClaim)
                    : _GlossyButton(
                        key: const ValueKey('go'),
                        scale: s,
                        label: t.goLabel,
                        colors: _GlossyButton.lavender,
                        lip: _GlossyButton.lavenderLip,
                        textColor: KidColors.purpleDeep,
                        arrow: true,
                        onTap: onGo),
          ),
        ),
      ]),
    );
  }
}

class _TreasureCard extends StatelessWidget {
  final double scale;
  final Animation<double> idle;
  final int claimedQuests;
  final bool opened;
  final VoidCallback onClaim;
  const _TreasureCard({required this.scale, required this.idle, required this.claimedQuests, required this.opened,
      required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    final total = dailyQuests.length;
    final ready = claimedQuests >= total && !opened;
    final chestW = 92 * s;
    return Container(
      padding: EdgeInsets.fromLTRB(6 * s, 8 * s, 8 * s, 8 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26 * s),
        gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF1E8FF), Color(0xFFD9C8FF)]),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.22), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        SizedBox(
          width: chestW,
          height: chestW * 0.86,
          child: AnimatedBuilder(
            animation: idle,
            builder: (_, c) => Transform.rotate(
                angle: ready ? sin(idle.value * 30 * pi) * 0.05 : 0,
                child: Transform.scale(scale: ready ? 1.05 : 1, child: c)),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Image.asset(opened ? QuestAssets.chestOpen : QuestAssets.chest,
                  key: ValueKey(opened), fit: BoxFit.contain, width: chestW, height: chestW * 0.86),
            ),
          ),
        ),
        SizedBox(width: 8 * s),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fit(t.dailyTreasure, kidTitleStyle(20 * s, color: _ink).copyWith(shadows: const [])),
              SizedBox(height: 2 * s),
              _fit(opened ? t.treasureOpened : t.dailyTreasureSub,
                  kidBodyStyle(12.5 * s, color: KidColors.purpleDeep, weight: FontWeight.w600)),
              SizedBox(height: 8 * s),
              Row(children: [
                for (int i = 0; i < total; i++)
                  Padding(
                    padding: EdgeInsetsDirectional.only(end: 6 * s),
                    child: SizedBox(
                      width: 28 * s,
                      height: 28 * s,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                        child: i < claimedQuests
                            ? Image.asset(QuestAssets.check, key: const ValueKey('c'), width: 28 * s, height: 28 * s)
                            : Container(
                                key: const ValueKey('o'),
                                margin: EdgeInsets.all(1 * s),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFC7B4F5),
                                  border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
                                ),
                              ),
                      ),
                    ),
                  ),
              ]),
            ],
          ),
        ),
        SizedBox(width: 8 * s),
        _rewardPanel(
          s,
          color: Colors.white.withOpacity(0.6),
          reward: _rewardLabel(s, QuestReward.gems, treasureGems),
          action: opened
              ? _doneChip(s, t.doneLabel)
              : _GlossyButton(
                  scale: s,
                  label: ready ? t.claimLabel : '$claimedQuests / $total',
                  colors: ready ? _GlossyButton.green : _GlossyButton.purple,
                  lip: ready ? _GlossyButton.greenLip : _GlossyButton.purpleLip,
                  textColor: Colors.white,
                  onTap: ready ? onClaim : null,
                ),
        ),
      ]),
    );
  }
}

class _NextMilestoneCard extends StatelessWidget {
  final double scale;
  final Milestone? milestone;
  final int value, ready;
  final VoidCallback onTap;
  const _NextMilestoneCard({required this.scale, required this.milestone, required this.value, required this.ready,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    final m = milestone;
    final laurelW = 72 * s;
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.97,
      child: Container(
        padding: EdgeInsetsDirectional.fromSTEB(8 * s, 10 * s, 10 * s, 10 * s),
        decoration: kidCardDecoration(24 * s),
        child: Row(children: [
          Image.asset(QuestAssets.laurel, width: laurelW, height: laurelW * 0.8163, fit: BoxFit.contain),
          SizedBox(width: 10 * s),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fit(t.nextMilestone, kidBodyStyle(16 * s, color: _ink, weight: FontWeight.w700)),
                _fit(m == null ? t.allMilestonesDone : t.milestoneLessons(m.target),
                    kidBodyStyle(12.5 * s, color: KidColors.purple, weight: FontWeight.w600)),
                if (m != null) ...[
                  SizedBox(height: 6 * s),
                  Row(children: [
                    Expanded(
                      child: _Bar(
                          value: value / m.target, height: 10 * s, colors: const [Color(0xFFFFD84A), Color(0xFFFFB21A)]),
                    ),
                    SizedBox(width: 8 * s),
                    Text('${min(value, m.target)} / ${m.target}',
                        style: kidBodyStyle(12 * s, color: _ink, weight: FontWeight.w700)),
                  ]),
                ],
              ],
            ),
          ),
          SizedBox(width: 6 * s),
          if (ready > 0)
            Container(
              width: 22 * s,
              height: 22 * s,
              margin: EdgeInsetsDirectional.only(end: 2 * s),
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF4D6D)),
              child: Text('$ready', style: kidBodyStyle(12 * s, color: Colors.white, weight: FontWeight.w700)),
            ),
          Transform.flip(
            flipX: Directionality.of(context) == TextDirection.rtl,
            child: Icon(Icons.chevron_right_rounded, color: KidColors.purple, size: 30 * s),
          ),
        ]),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final double scale;
  final Milestone milestone;
  final int value;
  final bool claimed;
  final VoidCallback onClaim;
  const _MilestoneCard({required this.scale, required this.milestone, required this.value, required this.claimed,
      required this.onClaim});

  static const _grey = ColorFilter.matrix([
    0.4, 0.4, 0.2, 0, 30, //
    0.3, 0.5, 0.2, 0, 30,
    0.3, 0.4, 0.3, 0, 30,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    final m = milestone;
    final reached = value >= m.target;
    final isLessons = m.track == 'lessons';
    Widget icon = Image.asset(isLessons ? QuestAssets.book : QuestAssets.games, fit: BoxFit.contain);
    if (!reached && !claimed) icon = ColorFiltered(colorFilter: _grey, child: icon);
    return Container(
      padding: EdgeInsets.all(8 * s),
      decoration: kidCardDecoration(22 * s),
      child: Row(children: [
        SizedBox(width: 60 * s, height: 60 * s, child: icon),
        SizedBox(width: 10 * s),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fit(isLessons ? t.milestoneLessons(m.target) : t.milestoneGames(m.target),
                  kidBodyStyle(16 * s, color: _ink, weight: FontWeight.w700)),
              SizedBox(height: 8 * s),
              Row(children: [
                Expanded(
                  child: _Bar(
                    value: value / m.target,
                    height: 9 * s,
                    colors: isLessons
                        ? const [Color(0xFF9B5CFF), Color(0xFF6A2BE0)]
                        : const [Color(0xFFFF7AB8), Color(0xFFEC3F8C)],
                  ),
                ),
                SizedBox(width: 8 * s),
                Text('${min(value, m.target)} / ${m.target}', style: kidBodyStyle(11.5 * s, color: _ink, weight: FontWeight.w700)),
              ]),
            ],
          ),
        ),
        SizedBox(width: 10 * s),
        _rewardPanel(
          s,
          reward: _rewardLabel(s * 0.95, QuestReward.gems, m.gems),
          action: claimed
              ? _doneChip(s, t.doneLabel)
              : reached
                  ? _GlossyButton(
                      scale: s,
                      label: t.claimLabel,
                      colors: _GlossyButton.green,
                      lip: _GlossyButton.greenLip,
                      textColor: Colors.white,
                      onTap: onClaim)
                  : Icon(Icons.lock_rounded, color: KidColors.lavender, size: 26 * s),
        ),
      ]),
    );
  }
}
