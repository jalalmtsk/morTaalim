import 'package:flutter/material.dart';
import 'package:mortaalim/main.dart';
import 'package:mortaalim/widgets/ComingSoon.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mortaalim/l10n/app_localizations.dart';

import '../../Manager/models/LearningPrefrences.dart';
import '../../User_Input_Info_DataForm/LearningPreferencesForm/LearningPreferencesEnteringForm.dart';
import 'PractiseCoursesSubjects/Arabic1/1_primaire_Arabic_Practise.dart';
import 'PractiseCoursesSubjects/French1/1_primaire_French_Practise.dart';
import 'PractiseCoursesSubjects/Math1/1_primaire_Math_Practise.dart';
import 'PractiseCoursesSubjects/Science1/1_primaire_Science_Practise.dart';
import 'PractiseCoursesSubjects/IslamicEducation1/1_primaire_IslamicEducation_Practise.dart';

// ═══════════════════════════════════════════════════════════════
//  SHARED THEME (same palette as Index1Primaire)
// ═══════════════════════════════════════════════════════════════
class _T {
  static const orange      = Color(0xFFEA580C);
  static const orangeLight = Color(0xFFFFF7ED);
  static const orangeMid   = Color(0xFFFDBA74);
  static const orangeDark  = Color(0xFF9A3412);
  static const amber       = Color(0xFFF59E0B);
  static const teal        = Color(0xFF0D9488);
  static const tealLight   = Color(0xFFCCFBF1);
  static const green       = Color(0xFF16A34A);
  static const white       = Color(0xFFFFFFFF);

  // Card accent colors — each InfoCard gets its own warm/cool tint
  static const List<Color> infoAccents = [
    Color(0xFFF97316), // orange  – fav subject
    Color(0xFF0D9488), // teal    – learning style
    Color(0xFF8B5CF6), // violet  – study time
    Color(0xFFEC4899), // pink    – difficulty
    Color(0xFF22C55E), // green   – goal
  ];
}

// ═══════════════════════════════════════════════════════════════
//  COURSE CARD CONFIG
// ═══════════════════════════════════════════════════════════════
class _CourseConfig {
  final String titleKey;
  final String route;
  final String image;
  final Color  accent;
  final String emoji;
  const _CourseConfig({
    required this.titleKey,
    required this.route,
    required this.image,
    required this.accent,
    required this.emoji,
  });
}

// ═══════════════════════════════════════════════════════════════
//  PAGE
// ═══════════════════════════════════════════════════════════════
class Primaire1Pratique extends StatefulWidget {
  const Primaire1Pratique({super.key});

  @override
  State<Primaire1Pratique> createState() => _Primaire1PratiqueState();
}

class _Primaire1PratiqueState extends State<Primaire1Pratique>
    with SingleTickerProviderStateMixin {

  // ── Course cards config ───────────────────────────────────────
  static const _courses = [
    _CourseConfig(
      titleKey: 'arabic',
      route:    'IndexArabic1Practise',
      image:    'assets/images/UI/BackGrounds/Course_BG/arabicCourse_bg.png',
      accent:   Color(0xFF8B5CF6),
      emoji:    '📖',
    ),
    _CourseConfig(
      titleKey: 'math',
      route:    'IndexMath1Practise',
      image:    'assets/images/UI/BackGrounds/Course_BG/mathCourse_bg.png',
      accent:   Color(0xFFF97316),
      emoji:    '🔢',
    ),
    _CourseConfig(
      titleKey: 'french',
      route:    'IndexFrench1Practise',
      image:    'assets/images/UI/BackGrounds/Course_BG/frenchCourse_bg.png',
      accent:   Color(0xFF3B82F6),
      emoji:    '🥐',
    ),
    _CourseConfig(
      titleKey: 'islamicEducation',
      route:    'IndexIslamicEducation1Practise',
      image:    'assets/images/UI/BackGrounds/Course_BG/islamCourse_bg.png',
      accent:   Color(0xFF22C55E),
      emoji:    '🌙',
    ),
    _CourseConfig(
      titleKey: 'science',
      route:    'IndexScience1Practise',
      image:    'assets/images/UI/BackGrounds/Course_BG/scienceCourse_bg.png',
      accent:   Color(0xFF06B6D4),
      emoji:    '🔬',
    ),
  ];

  LearningPreferences? _prefs;
  final List<_InfoItem> _infoItems = [];

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
    _loadPreferences();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final sp     = await SharedPreferences.getInstance();
    final loaded = await LearningPreferences.fromPrefs(sp);
    if (!mounted) return;
    setState(() {
      _prefs = loaded;
      _rebuildInfoItems();
    });
  }

  void _rebuildInfoItems() {
    if (_prefs == null) return;
    final l = tr(context);
    _infoItems
      ..clear()
      ..addAll([
        _InfoItem(
          emoji:    '📚',
          title:    l.preferredSubject,
          value:    _prefs!.betterSubjects.isNotEmpty
              ? _prefs!.betterSubjects.first
              : l.notSet,
          subtitle: l.keepUpTheGoodWork,
          accent:   _T.infoAccents[0],
        ),
        _InfoItem(
          emoji:    '🧠',
          title:    l.learningStyle,
          value:    _prefs!.preferredLearningStyle.isNotEmpty
              ? _prefs!.preferredLearningStyle
              : l.notSet,
          accent:   _T.infoAccents[1],
        ),
        _InfoItem(
          emoji:    '⏰',
          title:    l.studyTime,
          value:    _prefs!.studyTimePreference.isNotEmpty
              ? _prefs!.studyTimePreference
              : l.notSet,
          accent:   _T.infoAccents[2],
        ),
        _InfoItem(
          emoji:    '💪',
          title:    l.difficulty,
          value:    _prefs!.difficultyPreference.isNotEmpty
              ? _prefs!.difficultyPreference
              : l.notSet,
          accent:   _T.infoAccents[3],
        ),
        _InfoItem(
          emoji:    '🎯',
          title:    l.goals,
          value:    _prefs!.goalType.isNotEmpty ? _prefs!.goalType : l.notSet,
          accent:   _T.infoAccents[4],
        ),
      ]);
  }

  String _label(String key) {
    final l = tr(context);
    switch (key) {
      case 'math':             return l.math;
      case 'french':           return l.french;
      case 'arabic':           return l.arabic;
      case 'islamicEducation': return l.islamicEducation;
      case 'science':          return l.science;
      default:                 return key;
    }
  }

  Widget? _getPage(String route) {
    switch (route) {
      case 'IndexMath1Practise':             return const IndexMath1Practise();
      case 'IndexFrench1Practise':           return IndexFrench1Practise();
      case 'IndexArabic1Practise':           return ComingSoonPage();
      case 'IndexScience1Practise':          return IndexScience1Practise();
      case 'IndexIslamicEducation1Practise': return IndexIslamicEducation1Practise();
      default:                               return null;
    }
  }

  Future<void> _editPreferences() async {
    if (_prefs == null) return;
    final result = await Navigator.push<LearningPreferences>(
      context,
      MaterialPageRoute(
        builder: (_) => LearningPreferencesPages(initialPreferences: _prefs),
      ),
    );
    if (result != null) {
      final sp = await SharedPreferences.getInstance();
      await result.saveToPrefs(sp);
      setState(() {
        _prefs = result;
        _rebuildInfoItems();
      });
    }
  }

  // ═════════════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entryFade,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section: My Profile ──────────────────────────
            _SectionHeader(
              emoji: '🌟',
              label: tr(context).myProfile,
              trailing: _EditButton(onTap: _editPreferences),
            ),
            const SizedBox(height: 10),

            // Info cards — horizontal scroll
            SizedBox(
              height: 120,
              child: _prefs == null
                  ? const Center(
                child: CircularProgressIndicator(
                  color: _T.orange,
                  strokeWidth: 2.5,
                ),
              )
                  : ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _infoItems.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) =>
                    _KidInfoCard(item: _infoItems[i]),
              ),
            ),

            const SizedBox(height: 22),

            // ── Section: Practice Courses ────────────────────
            _SectionHeader(
              emoji: '🚀',
              label: tr(context).practiseCourses,
            ),
            const SizedBox(height: 12),

            // 2-column grid of course cards
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _courses.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.80,
              ),
              itemBuilder: (ctx, i) {
                final c = _courses[i];
                return _KidCourseCard(
                  emoji:  c.emoji,
                  label:  _label(c.titleKey),
                  image:  c.image,
                  accent: c.accent,
                  // Make last item span full width if odd count
                  isWide: _courses.length.isOdd && i == _courses.length - 1,
                  onTap: () {
                    final page = _getPage(c.route);
                    if (page != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => page),
                      );
                    }
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
//  DATA  MODEL
// ═══════════════════════════════════════════════════════════════
class _InfoItem {
  final String emoji;
  final String title;
  final String value;
  final String? subtitle;
  final Color   accent;
  const _InfoItem({
    required this.emoji,
    required this.title,
    required this.value,
    required this.accent,
    this.subtitle,
  });
}

// ═══════════════════════════════════════════════════════════════
//  SMALL WIDGETS
// ═══════════════════════════════════════════════════════════════

/// Section heading with emoji + coloured label
class _SectionHeader extends StatelessWidget {
  final String emoji;
  final String label;
  final Widget? trailing;
  const _SectionHeader({
    required this.emoji,
    required this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Fredoka One',
            fontSize: 20,
            color: _T.orange,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Edit preferences pill button
class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF97316), Color(0xFFF59E0B)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _T.orange.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_rounded, size: 15, color: _T.white),
            const SizedBox(width: 5),
            Text(
              tr(context).edit,
              style: const TextStyle(
                fontFamily: 'Fredoka One',
                fontSize: 14,
                color: _T.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal info card — shows one preference item
class _KidInfoCard extends StatelessWidget {
  final _InfoItem item;
  const _KidInfoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final bg = Color.lerp(item.accent, Colors.white, 0.82)!;
    final fg = item.accent.withOpacity(1);

    return Container(
      width: 155,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: item.accent.withOpacity(0.35), width: 2),
        boxShadow: [
          BoxShadow(
            color: item.accent.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(item.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Fredoka One',
              fontSize: 15,
              color: Color.lerp(item.accent, Colors.black, 0.65)!,
              height: 1.15,
            ),
          ),
          if (item.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              item.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: fg.withOpacity(0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Course card — image background + emoji + label + tap ripple
class _KidCourseCard extends StatefulWidget {
  final String       emoji;
  final String       label;
  final String       image;
  final Color        accent;
  final bool         isWide;
  final VoidCallback onTap;

  const _KidCourseCard({
    required this.emoji,
    required this.label,
    required this.image,
    required this.accent,
    required this.onTap,
    this.isWide = false,
  });

  @override
  State<_KidCourseCard> createState() => _KidCourseCardState();
}

class _KidCourseCardState extends State<_KidCourseCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0,
      upperBound: 0.04,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
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
                color: widget.accent.withOpacity(0.30),
                blurRadius: 16,
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

                // Colour overlay — accent tint + bottom dark gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.55),
                        widget.accent.withOpacity(0.35),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),

                // Accent top-left corner dot
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: widget.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.accent.withOpacity(0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),

                // Content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Emoji badge
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.accent.withOpacity(0.40),
                            blurRadius: 14,
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
                    // Subject label
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: const TextStyle(
                          fontFamily: 'Fredoka One',
                          fontSize: 18,
                          color: _T.white,
                          height: 1.15,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(0, 2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // "Let's go!" pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: widget.accent.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Let's go!",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _T.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}