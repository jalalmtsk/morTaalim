import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/courses/primaire1Page/GlobalStatCard.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../XpSystem.dart';
import '../../l10n/app_localizations.dart';
import '../../Inside_Course_Logic/HomeCourse.dart';
import '../../main.dart';

// ═══════════════════════════════════════════════════════════════
//  THEME
// ═══════════════════════════════════════════════════════════════
class _T {
  static const orange      = Color(0xFFEA580C);
  static const orangeLight = Color(0xFFFFF7ED);
  static const orangeMid   = Color(0xFFFDBA74);
  static const amber       = Color(0xFFF59E0B);
  static const teal        = Color(0xFF0D9488);
  static const white       = Color(0xFFFFFFFF);

  // Per-subject accent colors (warm → cool)
  static const subjectAccents = [
    Color(0xFFF97316), // math        — orange
    Color(0xFF3B82F6), // french      — blue
    Color(0xFF8B5CF6), // arabic      — violet
    Color(0xFF22C55E), // islamic ed  — green
    Color(0xFFEC4899), // art         — pink
    Color(0xFF06B6D4), // science     — cyan
  ];

  static const subjectEmojis = ['🔢', '🥐', '📖', '🌙', '🎨', '🔬'];
}

// ═══════════════════════════════════════════════════════════════
//  PAGE
// ═══════════════════════════════════════════════════════════════
class Primaire1 extends StatefulWidget {
  final ExperienceManager experienceManager;
  const Primaire1({Key? key, required this.experienceManager}) : super(key: key);

  @override
  State<Primaire1> createState() => _Primaire1State();
}

class _Primaire1State extends State<Primaire1>
    with SingleTickerProviderStateMixin {

  final List<Map<String, String>> courses = [
    {'title': 'math1',               'file': 'assets/courses/primaire1/Primaire1Cours/1primaire_mathematique.json'},
    {'title': 'french1',             'file': 'assets/courses/primaire1/Primaire1Cours/1primaire_francais.json'},
    {'title': 'arabic1',             'file': 'assets/courses/primaire1/Primaire1Cours/1primaire_arabe.json'},
    {'title': 'islamicEducation1',   'file': 'assets/courses/primaire1/Primaire1Cours/1primaire_education_islamique.json'},
    {'title': 'artEducation1',       'file': 'assets/courses/primaire1/Primaire1Cours/1primaire_educationArtistique.json'},
    {'title': 'Activitéscientifique1', 'file': 'assets/courses/primaire1/Primaire1Cours/1primaire_activite_scientifique.json'},
  ];

  Map<String, double> courseProgress = {};
  double overallProgressPct = 0.0;
  bool isLoading = true;

  static const String _kProgressPrefix = 'gamified_progress';

  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryFade;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    widget.experienceManager.addListener(_onXpChanged);
    _loadProgress().then((_) => _onXpChanged());
  }

  @override
  void dispose() {
    widget.experienceManager.removeListener(_onXpChanged);
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── Progress loading ──────────────────────────────────────────
  Future<void> _loadProgress() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    int totalAll = 0, doneAll = 0;
    final totals = <String, int>{};

    for (var course in courses) {
      final id  = course['title']!;
      final raw = await rootBundle.loadString(course['file']!);
      final sections = (jsonDecode(raw)['sections'] as List<dynamic>? ?? []);
      final total = sections.length;
      totals[id]  = total;
      totalAll   += total;

      final saved = prefs.getStringList('${_kProgressPrefix}_$id');
      int done;
      if (saved != null) {
        done = saved.length;
      } else {
        bool hasFlag = false;
        int flagDone = 0;
        for (var s in sections) {
          if (s is Map && s.containsKey('completed')) {
            hasFlag = true;
            if (s['completed'] == true) flagDone++;
          }
        }
        done = hasFlag
            ? flagDone
            : widget.experienceManager.courseProgressionManager
            .getCompletedSections(id)
            .length;
      }

      doneAll += done;
      courseProgress[id] = total == 0 ? 0 : done / total;
    }

    widget.experienceManager.courseProgressionManager
        .setTotalSectionsBatch(totals);
    overallProgressPct = totalAll == 0 ? 0 : doneAll / totalAll;

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void _onXpChanged() {
    if (!mounted) return;
    int total = 0, done = 0;
    for (var c in courses) {
      final id = c['title']!;
      final t  = widget.experienceManager.courseProgressionManager
          .getTotalSections(id);
      final d  = widget.experienceManager.courseProgressionManager
          .getCompletedSections(id)
          .length;
      total += t;
      done  += d;
      courseProgress[id] = t == 0 ? 0 : d / t;
    }
    overallProgressPct = total == 0 ? 0 : done / total;
    setState(() {});
  }

  // ── Helpers ───────────────────────────────────────────────────
  String _name(String key, AppLocalizations l) {
    switch (key) {
      case 'math1':               return l.math;
      case 'french1':             return l.french;
      case 'arabic1':             return l.arabic;
      case 'islamicEducation1':   return l.islamicEducation;
      case 'artEducation1':       return l.artEducation;
      default:                    return l.science;
    }
  }

  String _image(String key) {
    switch (key) {
      case 'math1':               return 'assets/images/UI/BackGrounds/Course_BG/mathCourse_bg.png';
      case 'arabic1':             return 'assets/images/UI/BackGrounds/Course_BG/arabicCourse_bg.png';
      case 'french1':             return 'assets/images/UI/BackGrounds/Course_BG/frenchCourse_bg.png';
      case 'islamicEducation1':   return 'assets/images/UI/BackGrounds/Course_BG/islamCourse_bg.png';
      case 'artEducation1':       return 'assets/images/UI/BackGrounds/Course_BG/artCourse_bg.png';
      default:                    return 'assets/images/UI/BackGrounds/Course_BG/scienceCourse_bg.png';
    }
  }

  Color _accent(int i)  => _T.subjectAccents[i % _T.subjectAccents.length];
  String _emoji(int i)  => _T.subjectEmojis[i % _T.subjectEmojis.length];

  // ═════════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final screenW  = MediaQuery.of(context).size.width;
    final audio    = Provider.of<AudioManager>(context, listen: false);
    final cols     = screenW > 700 ? 3 : 2;

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🦁', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            CircularProgressIndicator(
              color: _T.orange,
              strokeWidth: 3,
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _entryFade,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Global stats banner ──────────────────────────
            _GlobalBanner(
              progress: overallProgressPct,
              badges: widget.experienceManager.courseProgressionManager
                  .getBadges()
                  .length,
              xp: widget.experienceManager.courseProgressionManager
                  .getCourseXp(),
              completed: courseProgress.values.where((p) => p >= 1.0).length,
              total: courses.length,
            ),

            const SizedBox(height: 20),

            // ── Section header ───────────────────────────────
            Row(children: [
              const Text('📚', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                tr(context).myCourses,
                style: const TextStyle(
                  fontFamily: 'Fredoka One',
                  fontSize: 20,
                  color: _T.orange,
                ),
              ),
            ]),

            const SizedBox(height: 12),

            // ── Course grid ──────────────────────────────────
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: courses.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 3 / 4,
              ),
              itemBuilder: (ctx, i) {
                final c       = courses[i];
                final id      = c['title']!;
                final pct     = courseProgress[id] ?? 0.0;
                final accent  = _accent(i);
                final emoji   = _emoji(i);
                final label   = _name(id, tr(context));
                final imgPath = _image(id);

                return _CourseGridCard(
                  emoji:   emoji,
                  label:   label,
                  image:   imgPath,
                  accent:  accent,
                  percent: pct,
                  onTap: () async {
                    audio.playEventSound('clickButton2');
                    await Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => CoursePage(
                          jsonFilePath: c['file']!,
                          courseId:    id,
                          experienceManager: widget.experienceManager,
                        ),
                      ),
                    );
                    await _loadProgress();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  GLOBAL BANNER  — replaces GlobalStatsCard row
// ═══════════════════════════════════════════════════════════════
class _GlobalBanner extends StatelessWidget {
  final double progress;
  final int badges, xp, completed, total;

  const _GlobalBanner({
    required this.progress,
    required this.badges,
    required this.xp,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _T.orange.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: mascot + title + pct
          Row(
            children: [
              const Text('🦁', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(context).myProgress,
                      style: const TextStyle(
                        fontFamily: 'Fredoka One',
                        fontSize: 18,
                        color: _T.white,
                      ),
                    ),
                    Text(
                      '$completed / $total ${tr(context).coursesCompleted}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              // Big percentage circle
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$pct%',
                  style: const TextStyle(
                    fontFamily: 'Fredoka One',
                    fontSize: 16,
                    color: _T.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(_T.white),
            ),
          ),

          const SizedBox(height: 14),

          // Stats pills row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatPill('🏅', '$badges', tr(context).badges),
              _StatPill('⚡', '$xp XP',  tr(context).totalXp),
              _StatPill('🎯', '$completed', tr(context).done),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatPill(this.emoji, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Fredoka One',
                  fontSize: 14,
                  color: _T.white,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.80),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  COURSE GRID CARD  — image bg + emoji + label + progress bar
// ═══════════════════════════════════════════════════════════════
class _CourseGridCard extends StatefulWidget {
  final String       emoji;
  final String       label;
  final String       image;
  final Color        accent;
  final double       percent;
  final VoidCallback onTap;

  const _CourseGridCard({
    required this.emoji,
    required this.label,
    required this.image,
    required this.accent,
    required this.percent,
    required this.onTap,
  });

  @override
  State<_CourseGridCard> createState() => _CourseGridCardState();
}

class _CourseGridCardState extends State<_CourseGridCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0,
      upperBound: 0.04,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _press, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pctText = '${(widget.percent * 100).round()}%';
    final isDone  = widget.percent >= 1.0;

    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp:   (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withOpacity(0.28),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                Image.asset(widget.image, fit: BoxFit.cover),

                // Dark gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.65),
                        widget.accent.withOpacity(0.30),
                        Colors.black.withOpacity(0.05),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),

                // ── COMPLETED badge ───────────────────────────
                if (isDone)
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withOpacity(0.4),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('✓', style: TextStyle(
                              color: _T.white, fontSize: 11,
                              fontWeight: FontWeight.w900)),
                          SizedBox(width: 3),
                          Text('Done!', style: TextStyle(
                              color: _T.white, fontSize: 11,
                              fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),

                // Accent corner dot
                if (!isDone)
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      width: 9, height: 9,
                      decoration: BoxDecoration(
                        color: widget.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.accent.withOpacity(0.55),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Centre content ────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Emoji circle
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.90),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.accent.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Subject name
                      Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: const TextStyle(
                          fontFamily: 'Fredoka One',
                          fontSize: 17,
                          color: _T.white,
                          height: 1.15,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(0, 2),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Progress bar + pct
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: widget.percent,
                              minHeight: 7,
                              backgroundColor:
                              Colors.white.withOpacity(0.25),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDone ? const Color(0xFF4ADE80) : widget.accent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pctText,
                            style: const TextStyle(
                              fontFamily: 'Fredoka One',
                              fontSize: 13,
                              color: _T.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}