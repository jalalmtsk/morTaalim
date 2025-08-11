import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../XpSystem.dart';
import '../../l10n/app_localizations.dart';
import '../../Inside_Course_Logic/HomeCourse.dart';

class Primaire2 extends StatefulWidget {
  final ExperienceManager experienceManager;

  const Primaire2({Key? key, required this.experienceManager}) : super(key: key);

  @override
  State<Primaire2> createState() => _Primaire2State();
}

class _Primaire2State extends State<Primaire2> {
  final List<Map<String, String>> courses = [
    {'title': 'math2', 'file': 'assets/courses/primaire2/Primaire2Cours/2primaire_mathematique.json'},
    {'title': 'french2', 'file': 'assets/courses/primaire2/Primaire2Cours/2primaire_francais.json'},
    {'title': 'arabic2', 'file': 'assets/courses/primaire2/Primaire2Cours/2primaire_educationArtistique.json'},
    {'title': 'islamicEducation2', 'file': 'assets/courses/primaire2/Primaire2Cours/2primaire_education_islamique.json'},
    {'title': 'artEducation2', 'file': 'assets/courses/primaire2/Primaire2Cours/2primaire_educationArtistique.json'},
    {'title': 'Activitéscientifique2', 'file': 'assets/courses/primaire2/Primaire2Cours/2primaire_activite_scientifique.json'},
  ];

  Map<String, double> courseProgress = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.experienceManager.addListener(_onExperienceChanged);
    _loadAllCoursesTotalSectionsAndProgress();
  }

  @override
  void dispose() {
    widget.experienceManager.removeListener(_onExperienceChanged);
    super.dispose();
  }

  Future<void> _loadAllCoursesTotalSectionsAndProgress() async {
    setState(() => isLoading = true);
    final totals = <String, int>{};
    for (var course in courses) {
      final courseId = course['title']!;
      final jsonFile = course['file']!;
      final raw = await rootBundle.loadString(jsonFile);
      final jsonData = jsonDecode(raw);
      final sections = jsonData['sections'] as List<dynamic>? ?? [];
      totals[courseId] = sections.length;
    }
    widget.experienceManager.courseProgressionManager.setTotalSectionsBatch(totals);

    // Update progress map after totals are set
    for (var course in courses) {
      final courseId = course['title']!;
      courseProgress[courseId] = widget.experienceManager.courseProgressionManager.getProgress(courseId);
    }
    setState(() => isLoading = false);
  }



  void _onExperienceChanged() {
    if (!mounted) return;
    setState(() {
      for (var course in courses) {
        final courseId = course['title']!;
        courseProgress[courseId] = widget.experienceManager.courseProgressionManager.getProgress(courseId);
      }
      isLoading = false;
    });
  }

  IconData getCourseIcon(String title) {
    switch (title) {
      case 'math2':
        return Icons.calculate_rounded;
      case 'french2':
        return Icons.language_rounded;
      case 'arabic2':
        return Icons.translate_rounded;
      case 'islamicEducation2':
        return Icons.mosque;
      case 'artEducation2':
        return Icons.palette_rounded;
      default:
        return Icons.book_rounded;
    }
  }

  String getCourseName(String key, AppLocalizations tr) {
    switch (key) {
      case 'math2':
        return tr.math;
      case 'french2':
        return tr.french;
      case 'arabic2':
        return tr.arabic;
      case 'islamicEducation2':
        return tr.islamicEducation;
      case 'artEducation2':
        return tr.artEducation;
      default:
        return tr.class6;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xfffdf6e3),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
          : CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final course = courses[index];
                  final title = course['title']!;
                  final icon = getCourseIcon(title);
                  final percent = courseProgress[title] ?? 0.0;
                  final percentText = (percent * 100).toStringAsFixed(0);

                  return GestureDetector(
                    onTap: () async {
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
                      // Reload progress on return
                      _loadAllCoursesTotalSectionsAndProgress();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.orange.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.orangeAccent.shade100,
                            child: Icon(icon, size: 32, color: Colors.deepOrange),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  getCourseName(title, tr),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: LinearProgressIndicator(
                                    value: percent,
                                    minHeight: 10,
                                    backgroundColor: Colors.orange.shade100,
                                    valueColor: const AlwaysStoppedAnimation(Colors.deepOrangeAccent),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "$percentText%",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: courses.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
