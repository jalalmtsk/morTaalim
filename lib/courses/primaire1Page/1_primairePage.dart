import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../Inside_Course_Logic/HomeCourse.dart';

class Primaire1 extends StatefulWidget {
  const Primaire1({Key? key}) : super(key: key);

  @override
  State<Primaire1> createState() => _Primaire1State();
}

class _Primaire1State extends State<Primaire1> {
  final List<Map<String, String>> courses = [
    {'title': 'math', 'file': 'assets/courses/primaire1/Primaire1Cours/1primaire_mathematique.json'},
    {'title': 'french', 'file': 'assets/courses/primaire1/Primaire1Cours/1primaire_francais.json'},
    {'title': 'arabic', 'file': 'assets/courses/primaire1/Primaire1Cours/1primaire_educationArtistique.json'},
    {'title': 'islamicEducation', 'file': 'assets/courses/primaire1/Primaire1Cours/1primaire_education_islamique.json'},
    {'title': 'artEducation', 'file': 'assets/courses/primaire1/Primaire1Cours/1primaire_educationArtistique.json'},
    {'title': 'Activitéscientifique', 'file': 'assets/courses/primaire1/Primaire1Cours/1primaire_activite_scientifique.json'},
  ];

  Map<String, double> courseProgress = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProgressForCourses();
  }

  Future<void> loadProgressForCourses() async {
    final prefs = await SharedPreferences.getInstance();
    for (var course in courses) {
      final courseId = course['title']!;
      final saved = prefs.getStringList('progress_$courseId') ?? [];
      final total = await getTotalSections(course['file']!);
      final progress = total > 0 ? saved.length / total : 0.0;
      courseProgress[courseId] = progress;
    }
    await Future.delayed(const Duration(milliseconds: 800)); // playful loading
    setState(() => isLoading = false);
  }

  Future<int> getTotalSections(String jsonFilePath) async {
    final data = await rootBundle.loadString(jsonFilePath);
    final jsonResult = jsonDecode(data);
    return (jsonResult['sections'] as List).length;
  }

  IconData getCourseIcon(String title) {
    switch (title) {
      case 'math':
        return Icons.calculate_rounded;
      case 'french':
        return Icons.language_rounded;
      case 'arabic':
        return Icons.translate_rounded;
      case 'islamicEducation':
        return Icons.mosque;
      case 'artEducation':
        return Icons.palette_rounded;
      default:
        return Icons.book_rounded;
    }
  }

  String getCourseName(String key, AppLocalizations tr) {
    switch (key) {
      case 'math':
        return tr.math;
      case 'french':
        return tr.french;
      case 'arabic':
        return tr.arabic;
      case 'islamicEducation':
        return tr.islamicEducation;
      case 'artEducation':
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Text(
                "🎒 ${tr.class1}",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black26, blurRadius: 3),
                  ],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xfff9a825), Color(0xfff57c00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image(
                      image: AssetImage('assets/images/cartoon_kid.png'),
                      height: 90,
                    ),
                  ),
                ),
              ),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: isLoading
                  ? Center(
                child: SizedBox(
                  height: 80,
                  width: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    color: Colors.orangeAccent,
                  ),
                ),
              )
                  : Column(
                children: courses.map((course) {
                  final title = course['title']!;
                  final icon = getCourseIcon(title);
                  final percent = courseProgress[title] ?? 0.0;
                  final percentText = (percent * 100).toStringAsFixed(0);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CoursePage(
                            jsonFilePath: course['file']!,
                            courseId: title,
                          ),
                        ),
                      ).then((_) => loadProgressForCourses());
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
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: LinearProgressIndicator(
                                    value: percent,
                                    minHeight: 10,
                                    backgroundColor: Colors.orange.shade100,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.deepOrangeAccent,
                                    ),
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
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
