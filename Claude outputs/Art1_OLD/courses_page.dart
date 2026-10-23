import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mortaalim/Manager/lesson_progress.dart';
import 'package:mortaalim/XpSystem.dart';
import 'package:mortaalim/courses/primaire1Page/PractiseCoursesSubjects/French1/1_primaire_French_Practise.dart';
import 'package:mortaalim/courses/primaire1Page/PractiseCoursesSubjects/IslamicEducation1/1_primaire_IslamicEducation_Practise.dart';
import 'package:mortaalim/courses/primaire1Page/PractiseCoursesSubjects/Math1/1_primaire_Math_Practise.dart';
import 'package:mortaalim/courses/primaire1Page/PractiseCoursesSubjects/Science1/1_primaire_Science_Practise.dart';
import 'package:mortaalim/courses/primaire1Page/PractiseCoursesSubjects/Arabic1/1_primaire_Arabic_Practise.dart';
import 'package:mortaalim/l10n/app_localizations.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/tools/ConnectivityManager/Connectivity_Manager.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:mortaalim/widgets/KidScene/kid_form.dart';
import 'package:mortaalim/widgets/KidScene/kid_page_parts.dart';
import 'package:mortaalim/widgets/KidScene/kid_scene.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoursesAssets {
  CoursesAssets._();
  static const String dir = 'assets/images/UI/KidScene/';
  static const String heroBg = '${dir}games_hero_bg.webp';
  static const String mascot = '${dir}courses_mascot.webp';
  static const String cap = '${dir}courses_cap.webp';
  static const String chevron = '${dir}courses_chevron.webp';
  static const String medal = '${dir}courses_medal.webp';
  static const String play = '${dir}courses_play.webp';
  static const String tileMath = '${dir}courses_tile_math.webp';
  static const String tileLanguages = '${dir}courses_tile_languages.webp';
  static const String tileScience = '${dir}courses_tile_science.webp';
  static const String tileReading = '${dir}courses_tile_reading.webp';
  static const String tileGeography = '${dir}courses_tile_geography.webp';
  static const String tileArt = '${dir}courses_tile_art.webp';
  static String go(String c) => '${dir}courses_go_$c.webp';

  static List<String> get all => [
        heroBg, mascot, cap, chevron, medal, play, tileMath, tileLanguages, tileScience, tileReading,
        tileGeography, tileArt, kidCoinAsset, kidGemAsset,
        for (final c in ['orange', 'green', 'blue', 'pink', 'purple']) go(c),
      ];
}

/// A subject card. [lessons] == 0 means "coming soon".
class _Subject {
  final String id;
  final String Function(AppLocalizations) label;
  final String? art;
  final String? iconArt; // square image used when there is no wide art
  final List<Color> iconColors;
  final String go;
  final int lessons;
  final Widget Function()? page;
  const _Subject(this.id, this.label, this.art, this.go, this.lessons, this.page,
      {this.iconArt, this.iconColors = const []});
  bool get available => page != null && lessons > 0;
}

/// Lesson counts match the exercises listed in each subject page.
final List<_Subject> _grade1 = [
  _Subject('math', (t) => t.math, CoursesAssets.tileMath, 'orange', 5, () => const IndexMath1Practise()),
  _Subject('french', (t) => t.french, CoursesAssets.tileLanguages, 'green', 3, () => const IndexFrench1Practise()),
  _Subject('science', (t) => t.science, CoursesAssets.tileScience, 'blue', 5, () => const IndexScience1Practise()),
  _Subject('islamicEducation', (t) => t.islamicEducation, null, 'pink', 3, () => const IndexIslamicEducation1Practise(),
      iconArt: 'assets/images/UI/BackGrounds/Course_BG/islamCourse_bg.png',
      iconColors: const [Color(0xFFD4F7D9), Color(0xFF6FD08A)]),
  _Subject('arabic', (t) => t.arabic, CoursesAssets.tileReading, 'purple', 5, () => const IndexArabic1Practise()),
  _Subject('geography', (t) => t.geography, CoursesAssets.tileGeography, 'green', 0, null),
  _Subject('artEducation', (t) => t.artEducation, CoursesAssets.tileArt, 'purple', 0, null),
];

/// Full-screen Courses page (no bottom bar).
class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> with TickerProviderStateMixin {
  static const _kGrade = 'courses_grade';

  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  ConnectivityService? _connectivity;
  int _grade = 1;
  LessonSnapshot _snap = LessonSnapshot.empty;
  bool _precached = false;
  bool _opening = false;

  List<_Subject> get _subjects => _grade == 1 ? _grade1 : const [];

  @override
  void initState() {
    super.initState();
    _loadGrade();
    _refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _connectivity ??= Provider.of<ConnectivityService>(context, listen: false)..resumeMonitoring();
    if (!_precached) {
      _precached = true;
      KidAssets.precache(context, [...CoursesAssets.all, KidAssets.valleyBg, KidAssets.backBtn]);
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _connectivity?.pauseMonitoring();
    _intro.dispose();
    _idle.dispose();
    super.dispose();
  }

  Future<void> _loadGrade() async {
    final p = await SharedPreferences.getInstance();
    var g = p.getInt(_kGrade);
    if (g == null && mounted) {
      // First visit: start from the grade picked during onboarding ("Grade 3" → 3).
      final school = Provider.of<ExperienceManager>(context, listen: false).userProfile.schoolGrade;
      final m = RegExp(r'\d+').firstMatch(school);
      final n = m == null ? null : int.tryParse(m.group(0)!);
      g = (n != null && n >= 1 && n <= 6) ? n : 1;
    }
    if (mounted) setState(() => _grade = g!);
  }

  Future<void> _refresh() async {
    final snap = await LessonProgress.load(_grade1.map((s) => s.id));
    if (!mounted) return;
    setState(() => _snap = snap);
    if (snap.learnedToday && !snap.claimedToday && await LessonProgress.claimToday() && mounted) {
      Provider.of<ExperienceManager>(context, listen: false).addTokenBanner(context, LessonProgress.goalReward);
      _audio.playSfx('assets/audios/UI_Audio/SFX_Audio/victory2_SFX.mp3');
      setState(() => _snap = LessonSnapshot(
          done: snap.done, lastSubject: snap.lastSubject, learnedToday: true, claimedToday: true));
    }
  }

  AudioManager get _audio => Provider.of<AudioManager>(context, listen: false);

  Future<void> _pickGrade() async {
    _audio.playEventSound('clickButton');
    final t = tr(context);
    final names = [t.class1, t.class2, t.class3, t.class4, t.class5, t.class6];
    final g = await showKidOptionSheet<int>(
      context: context,
      title: t.chooseGrade,
      options: const [1, 2, 3, 4, 5, 6],
      label: (i) => names[i - 1],
      selected: _grade,
    );
    if (g == null || g == _grade || !mounted) return;
    _audio.playEventSound('clickButton2');
    setState(() => _grade = g);
    (await SharedPreferences.getInstance()).setInt(_kGrade, g);
  }

  Future<void> _open(_Subject s) async {
    if (!s.available) {
      _audio.playEventSound('clickButton2');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: KidColors.purpleDeep,
        duration: const Duration(milliseconds: 1500),
        content: Text('${s.label(tr(context))} · ${tr(context).comingSoon}',
            style: kidBodyStyle(15, color: Colors.white, weight: FontWeight.w600)),
      ));
      return;
    }
    if (_opening) return;
    _opening = true;
    try {
      _audio.playEventSound('PopButton');
      await Navigator.push(context, MaterialPageRoute(builder: (_) => s.page!()));
    } finally {
      _opening = false;
    }
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
    final subjects = _subjects;
    final available = subjects.where((x) => x.available).toList();
    final current = available.isEmpty
        ? null
        : available.firstWhere((x) => x.id == _snap.lastSubject, orElse: () => available.first);

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
                    step(0, KidPageHeader(scale: s, title: t.courses, gold: xp.gold, gems: xp.gems)),
                    SizedBox(height: 8 * s),
                    Expanded(
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: step(
                              1,
                              _Hero(
                                scale: s,
                                idle: _idle,
                                subject: current,
                                done: current == null ? 0 : (_snap.done[current.id] ?? 0),
                                onContinue: current == null ? null : () => _open(current),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(child: SizedBox(height: 12 * s)),
                          SliverToBoxAdapter(
                            child: step(2, _GradeRow(scale: s, grade: _grade, count: subjects.length, onTap: _pickGrade)),
                          ),
                          SliverToBoxAdapter(child: SizedBox(height: 12 * s)),
                          if (subjects.isEmpty)
                            SliverToBoxAdapter(child: step(3, _GradeSoon(scale: s, idle: _idle, onBack: _pickGrade)))
                          else
                            SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                mainAxisSpacing: 12 * s,
                                crossAxisSpacing: 12 * s,
                                childAspectRatio: 1.08,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, i) {
                                  final sub = subjects[i];
                                  return step(
                                    3 + min(i, 6),
                                    _SubjectCard(
                                      scale: s,
                                      subject: sub,
                                      done: min(sub.lessons, _snap.done[sub.id] ?? 0),
                                      idle: _idle,
                                      phase: i * 0.13,
                                      onTap: () => _open(sub),
                                    ),
                                  );
                                },
                                childCount: subjects.length,
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
                  child: _GoalCard(scale: s, idle: _idle, done: _snap.learnedToday, claimed: _snap.claimedToday),
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

TextStyle _heroWord(Color c, double size) => TextStyle(
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

class _Hero extends StatelessWidget {
  final double scale;
  final Animation<double> idle;
  final _Subject? subject;
  final int done;
  final VoidCallback? onContinue;
  const _Hero({required this.scale, required this.idle, required this.subject, required this.done, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    final h = 146 * s;
    final r = 26 * s;
    final sub = subject;
    final started = done > 0;
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
            Positioned.fill(child: Image.asset(CoursesAssets.heroBg, fit: BoxFit.cover)),
            // Mascot with the ABC book
            PositionedDirectional(
              start: -6 * s,
              bottom: -6 * s,
              child: AnimatedBuilder(
                animation: idle,
                builder: (_, c) => Transform.translate(
                  offset: Offset(0, sin(idle.value * 4 * pi) * 3 * s),
                  child: Transform.rotate(angle: sin(idle.value * 2 * pi) * 0.025, child: c),
                ),
                child: Image.asset(CoursesAssets.mascot, width: 150 * s, height: 150 * s * 0.7666),
              ),
            ),
            // Headline
            PositionedDirectional(
              start: 140 * s,
              end: 10 * s,
              top: 10 * s,
              height: 62 * s,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(t.coursesHeroTop, style: _heroWord(Colors.white, 21 * s)),
                  SizedBox(height: 2 * s),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFFFFE04A), Color(0xFFFFB627), Color(0xFFFF7AD9), Color(0xFFB794FF)],
                    ).createShader(b),
                    child: Text(t.coursesHeroBottom, style: _heroWord(Colors.white, 30 * s)),
                  ),
                ]),
              ),
            ),
            // Continue strip
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
                            child: Text(
                              sub == null ? t.comingSoon : sub.label(t),
                              maxLines: 1,
                              style: kidBodyStyle(14 * s, color: _ink, weight: FontWeight.w700),
                            ),
                          ),
                          SizedBox(height: 4 * s),
                          if (sub != null)
                            Row(children: [
                              Expanded(child: KidProgressBar(value: done / sub.lessons, height: 8 * s)),
                              SizedBox(width: 6 * s),
                              Text(t.lessonsCount(done, sub.lessons),
                                  style: kidBodyStyle(10.5 * s, color: KidColors.muted, weight: FontWeight.w600)),
                            ]),
                        ],
                      ),
                    ),
                    SizedBox(width: 6 * s),
                    KidPressable(
                      onTap: onContinue,
                      pressedScale: 0.93,
                      child: Opacity(
                        opacity: onContinue == null ? 0.5 : 1,
                        child: Container(
                          height: 46 * s,
                          padding: EdgeInsets.symmetric(horizontal: 12 * s),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16 * s),
                            gradient: const LinearGradient(
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                colors: [Color(0xFFFFDF4F), Color(0xFFFFB21A)]),
                            border: Border.all(color: const Color(0xFFFFF0A8), width: 1.5),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFC2620A).withOpacity(0.45), offset: Offset(0, 3 * s)),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Transform.flip(
                                flipX: Directionality.of(context) == TextDirection.rtl,
                                child: Image.asset(CoursesAssets.play, height: 16 * s, width: 16 * s / 1.1733),
                              ),
                              SizedBox(height: 1 * s),
                              Text(started ? t.continueLabel : t.startLabel,
                                  style: kidBodyStyle(13 * s, color: const Color(0xFF7A2E00), weight: FontWeight.w700)),
                            ],
                          ),
                        ),
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

class _GradeRow extends StatelessWidget {
  final double scale;
  final int grade, count;
  final VoidCallback onTap;
  const _GradeRow({required this.scale, required this.grade, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    final names = [t.class1, t.class2, t.class3, t.class4, t.class5, t.class6];
    BoxDecoration deco() => BoxDecoration(
          color: KidColors.cream,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [BoxShadow(color: KidColors.purpleDeep.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3))],
        );
    return SizedBox(
      height: 46 * s,
      child: Row(
        children: [
          Expanded(
            child: KidPressable(
              onTap: onTap,
              pressedScale: 0.95,
              semanticLabel: t.chooseGrade,
              child: Container(
                decoration: deco(),
                padding: EdgeInsets.symmetric(horizontal: 10 * s),
                child: Row(children: [
                  Image.asset(CoursesAssets.cap, width: 36 * s, height: 36 * s * 0.7302),
                  SizedBox(width: 6 * s),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: FittedBox(
                        key: ValueKey(grade),
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(names[grade - 1], style: kidBodyStyle(17 * s, color: _ink, weight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  Image.asset(CoursesAssets.chevron, width: 18 * s, height: 18 * s * 0.6716),
                ]),
              ),
            ),
          ),
          SizedBox(width: 10 * s),
          Expanded(
            child: Container(
              decoration: deco(),
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 10 * s),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: t.yourSubjects),
                  if (count > 0)
                    TextSpan(text: '  $count', style: const TextStyle(color: KidColors.purple)),
                ]), style: kidBodyStyle(17 * s, color: _ink, weight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final double scale;
  final _Subject subject;
  final int done;
  final Animation<double> idle;
  final double phase;
  final VoidCallback onTap;
  const _SubjectCard({required this.scale, required this.subject, required this.done, required this.idle,
      required this.phase, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    final r = 22 * s;
    final ok = subject.available;
    final label = subject.label(t);
    return KidPressable(
      onTap: onTap,
      pressedScale: 0.95,
      semanticLabel: label,
      child: Container(
        decoration: kidCardDecoration(r),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(r - 3),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    subject.art != null
                        ? Image.asset(subject.art!, fit: BoxFit.cover, filterQuality: FilterQuality.medium)
                        : KidIconArt(image: subject.iconArt!, colors: subject.iconColors, idle: idle, phase: phase, scale: s),
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
                            child: Text(t.soonBadge,
                                style: kidBodyStyle(12 * s, color: Colors.white, weight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ],
                    if (ok && done >= subject.lessons)
                      PositionedDirectional(
                        top: 7 * s,
                        start: 7 * s,
                        child: Container(
                          padding: EdgeInsets.all(2.5 * s),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(Icons.emoji_events_rounded, color: const Color(0xFFF59E0B), size: 20 * s),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                height: 62 * s,
                color: kidCardCream,
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
                            child: Text(label, maxLines: 1, style: kidTitleStyle(19 * s, color: _ink).copyWith(shadows: const [])),
                          ),
                          SizedBox(height: 5 * s),
                          if (ok)
                            Row(children: [
                              Expanded(child: KidProgressBar(value: done / subject.lessons, height: 8 * s)),
                              SizedBox(width: 6 * s),
                              Text(t.lessonsCount(done, subject.lessons),
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
                        child: Image.asset(CoursesAssets.go(subject.go), width: 42 * s, height: 42 * s),
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
}

/// Shown for grades whose lessons are not ready yet.
class _GradeSoon extends StatelessWidget {
  final double scale;
  final Animation<double> idle;
  final VoidCallback onBack;
  const _GradeSoon({required this.scale, required this.idle, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    return Container(
      padding: EdgeInsets.fromLTRB(18 * s, 18 * s, 18 * s, 20 * s),
      decoration: kidCardDecoration(24 * s),
      child: Column(children: [
        AnimatedBuilder(
          animation: idle,
          builder: (_, c) => Transform.translate(offset: Offset(0, sin(idle.value * 4 * pi) * 4 * s), child: c),
          child: Image.asset(CoursesAssets.mascot, width: 170 * s, height: 170 * s * 0.7666),
        ),
        SizedBox(height: 10 * s),
        Text(t.gradeSoonTitle, textAlign: TextAlign.center, style: kidBodyStyle(20 * s, color: _ink, weight: FontWeight.w700)),
        SizedBox(height: 6 * s),
        Text(t.gradeSoonBody, textAlign: TextAlign.center, style: kidBodyStyle(14 * s, color: KidColors.muted)),
        SizedBox(height: 14 * s),
        KidButton(label: t.chooseGrade, width: 220 * s, height: 50 * s, showArrow: false, onPressed: onBack),
      ]),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final double scale;
  final Animation<double> idle;
  final bool done, claimed;
  const _GoalCard({required this.scale, required this.idle, required this.done, required this.claimed});

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final t = tr(context);
    return Container(
      height: 76 * s,
      padding: EdgeInsetsDirectional.only(start: 8 * s, end: 12 * s),
      decoration: kidCardDecoration(26 * s, shadow: 0.25),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: idle,
            builder: (_, c) => Transform.rotate(angle: sin(idle.value * 6 * pi) * 0.06, child: c),
            child: Image.asset(CoursesAssets.medal, width: 52 * s, height: 52 * s * 1.1),
          ),
          SizedBox(width: 10 * s),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(t.learningGoal, style: kidBodyStyle(18 * s, color: _ink, weight: FontWeight.w700)),
                ),
                SizedBox(height: 2 * s),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(claimed ? t.learningGoalDone : t.learningGoalMsg,
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
                      Text('+${LessonProgress.goalReward}',
                          style: kidBodyStyle(18 * s, color: _ink, weight: FontWeight.w700)),
                    ]),
                  ),
          ),
        ],
      ),
    );
  }
}
