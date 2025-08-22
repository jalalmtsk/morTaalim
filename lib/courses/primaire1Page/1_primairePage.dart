import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/courses/primaire1Page/GlobalStatCard.dart';
import 'package:mortaalim/tools/audio_tool/Audio_Manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mortaalim/Inside_Course_Logic/HomeCourse_Tools/Widgets/MascotBubble.dart';
import 'package:mortaalim/Inside_Course_Logic/HomeCourse_Tools/Widgets/ProgressCard.dart';
import '../../XpSystem.dart';
import '../../l10n/app_localizations.dart';
import '../../Inside_Course_Logic/HomeCourse.dart';
import '../../main.dart';

class Primaire1 extends StatefulWidget {
  final ExperienceManager experienceManager;

  const Primaire1({Key? key, required this.experienceManager}) : super(key: key);

  @override
  State<Primaire1> createState() => _Primaire1State();
}

class _Primaire1State extends State<Primaire1> {
  final List<Map<String, String>> courses = [
    {'title': 'math1', 'file': 'assets/courses/primaire1/Primaire1Cours/1primaire_mathematique.json'},
    {'title': 'french1', 'file': 'assets/courses/primaire1/Primaire1Cours/1primaire_francais.json'},
    {'title': 'arabic1', 'file': 'assets/courses/primaire1/Primaire1Cours/1primaire_arabe.json'},
    {'title': 'islamicEducation1', 'file': 'assets/courses/primaire1/Primaire1Cours/1primaire_education_islamique.json'},
    {'title': 'artEducation1', 'file': 'assets/courses/primaire1/Primaire1Cours/1primaire_educationArtistique.json'},
    {'title': 'Activitéscientifique1', 'file': 'assets/courses/primaire1/Primaire1Cours/1primaire_activite_scientifique.json'},
  ];

  Map<String, double> courseProgress = {};
  double overallProgressPct = 0.0; // 0.0 .. 1.0
  bool isLoading = true;

  // same prefix keys used by your CourseProgressionManager
  static const String _kProgressPrefix = 'gamified_progress';

  @override
  void initState() {
    super.initState();
    widget.experienceManager.addListener(_onExperienceChanged);
    _loadAllCoursesTotalSectionsAndProgress().then((_) {
      _onExperienceChanged();
    });  }

  @override
  void dispose() {
    widget.experienceManager.removeListener(_onExperienceChanged);
    super.dispose();
  }

  Future<void> _loadAllCoursesTotalSectionsAndProgress() async {
    setState(() => isLoading = true);

    // read prefs early so we can show immediate saved progress (no need to wait for ExperienceManager init)
    final prefs = await SharedPreferences.getInstance();

    int totalSectionsAll = 0;
    int completedSectionsAll = 0;
    final totals = <String, int>{};

    for (var course in courses) {
      final courseId = course['title']!;
      final jsonFile = course['file']!;

      // Load JSON (to determine total sections and optional per-section 'completed' flags)
      final raw = await rootBundle.loadString(jsonFile);
      final jsonData = jsonDecode(raw);
      final sections = jsonData['sections'] as List<dynamic>? ?? [];
      final totalSections = sections.length;

      totals[courseId] = totalSections;
      totalSectionsAll += totalSections;

      // 1) Prefer persisted SharedPreferences saved completed list (same key your manager uses).
      final savedKey = '$_kProgressPrefix\_$courseId';
      final savedList = prefs.getStringList(savedKey);
      int completedCount = 0;

      if (savedList != null) {
        // If prefs contains stored completed indices, use that
        completedCount = savedList.length;
      } else {
        // 2) If JSON contains per-section 'completed' flags, count them
        bool jsonHasCompletedField = false;
        int jsonCompletedCount = 0;
        for (var sec in sections) {
          if (sec is Map<String, dynamic> && sec.containsKey('completed')) {
            jsonHasCompletedField = true;
            if (sec['completed'] == true) jsonCompletedCount++;
          } else if (sec is Map && sec.containsKey('completed')) {
            jsonHasCompletedField = true;
            if (sec['completed'] == true) jsonCompletedCount++;
          }
        }
        if (jsonHasCompletedField) {
          completedCount = jsonCompletedCount;
        } else {
          // 3) fallback to experienceManager (may be empty if it's not initialized yet)
          completedCount = widget.experienceManager.courseProgressionManager
              .getCompletedSections(courseId)
              .length;
        }
      }

      completedSectionsAll += completedCount;

      // per-course progress as fraction 0..1
      courseProgress[courseId] = totalSections == 0 ? 0.0 : (completedCount / totalSections);
    }

    // Store totals into the manager so other parts can read totals
    widget.experienceManager.courseProgressionManager.setTotalSectionsBatch(totals);

    // Weighted overall progress across all courses (completed sections / total sections)
    overallProgressPct = totalSectionsAll == 0 ? 0.0 : (completedSectionsAll / totalSectionsAll);

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  void _onExperienceChanged() {
    // When experienceManager notifies, recalc progress using the manager's authoritative data
    if (!mounted) return;

    int totalSectionsAll = 0;
    int completedSectionsAll = 0;

    for (var course in courses) {
      final courseId = course['title']!;
      final totalSections = widget.experienceManager.courseProgressionManager.getTotalSections(courseId);
      final completedCount = widget.experienceManager.courseProgressionManager.getCompletedSections(courseId).length;

      totalSectionsAll += totalSections;
      completedSectionsAll += completedCount;

      courseProgress[courseId] = totalSections == 0 ? 0.0 : (completedCount / totalSections);
    }

    overallProgressPct = totalSectionsAll == 0 ? 0.0 : (completedSectionsAll / totalSectionsAll);

    setState(() {
      // just update UI
    });
  }

  IconData getCourseIcon(String title) {
    switch (title) {
      case 'math1':
        return Icons.calculate_rounded;
      case 'arabic1':
        return Icons.accessibility_new_sharp;
      case 'french1':
        return Icons.language_rounded;
      case 'Activitéscientifique1':
        return Icons.translate_rounded;
      case 'islamicEducation1':
        return Icons.mosque;
      case 'artEducation1':
        return Icons.palette_rounded;
      default:
        return Icons.book_rounded;
    }
  }

  String getCourseImagePath(String title) {
    switch (title) {
      case 'math1':
        return 'assets/images/UI/BackGrounds/Course_BG/mathCourse_bg.png';
      case 'arabic1':
        return 'assets/images/UI/BackGrounds/Course_BG/arabicCourse_bg.png';
      case 'french1':
        return 'assets/images/UI/BackGrounds/Course_BG/frenchCourse_bg.png';
      case 'Activitéscientifique1':
        return 'assets/images/UI/BackGrounds/Course_BG/scienceCourse_bg.png';
      case 'islamicEducation1':
        return 'assets/images/UI/BackGrounds/Course_BG/islamCourse_bg.png';
      case 'artEducation1':
        return 'assets/images/UI/BackGrounds/Course_BG/artCourse_bg.png';
      default:
        return 'assets/images/default_bg.png';
    }
  }

  String getCourseName(String key, AppLocalizations tr) {
    switch (key) {
      case 'math1':
        return tr.math;
      case 'french1':
        return tr.french;
      case 'arabic1':
        return tr.arabic;
      case 'islamicEducation1':
        return tr.islamicEducation;
      case 'artEducation1':
        return tr.artEducation;
      default:
        return tr.science;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final audioManager = Provider.of<AudioManager>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GlobalStatsCard(
                    progress: overallProgressPct,
                    badges: widget.experienceManager.courseProgressionManager.getBadges().length,
                    courseXp: widget.experienceManager.courseProgressionManager.getCourseXp(),
                    completedCourses: courseProgress.values.where((p) => p >= 1.0).length,
                    totalCourses: courses.length,
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: courses.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: screenWidth > 700 ? 3 : 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: 4 / 3,
                ),
                itemBuilder: (context, index) {
                  final course = courses[index];
                  final title = course['title']!;
                  final icon = getCourseIcon(title);
                  final percent = courseProgress[title] ?? 0.0;
                  final percentText = (percent * 100).toStringAsFixed(0);

                  return GestureDetector(
                    onTap: () async {
                      audioManager.playEventSound('clickButton2');
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CoursePage(
                            jsonFilePath: course['file']!,
                            courseId: title,
                            experienceManager: widget.experienceManager,
                          ),
                        ),
                      );
                      // Recalculate after coming back (keeps UI fresh)
                      await _loadAllCoursesTotalSectionsAndProgress();
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              getCourseImagePath(title),
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.4),
                                    Colors.black.withOpacity(0.0),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 35,
                                    color: Colors.orangeAccent,
                                    shadows: const [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black45,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  getCourseName(title, tr(context)),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 4,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 30),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: percent,
                                      minHeight: 8,
                                      backgroundColor: Colors.white.withOpacity(0.3),
                                      valueColor: const AlwaysStoppedAnimation(Colors.orangeAccent),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$percentText%",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black87,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
