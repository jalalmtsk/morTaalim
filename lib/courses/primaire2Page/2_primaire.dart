import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/tools/HomeCourse.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';



class primaire2 extends StatefulWidget {
  @override
  _primaire2State createState() => _primaire2State();
}

class _primaire2State extends State<primaire2> {
  final List<Map<String, String>> courses = [
    {'title': 'Mathématiques', 'file': 'assets/courses/primary/microeconomics.json'},
    {'title': 'Français', 'file': 'assets/courses/primary/economics.json'},
    {'title': 'Arabe', 'file': 'assets/courses/primary/economics.json'},
    {'title': 'Éducation Islamique', 'file': 'assets/courses/primary/primaire1/Education_Islamique/1primaire_education_islamique.json'},
    {'title': 'Éducation Artistique', 'file': 'assets/courses/primary/macroeconomics.json'},
  ];

  Map<String, double> courseProgress = {};

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

      double progress = total > 0 ? saved.length / total : 0.0;
      setState(() {
        courseProgress[courseId] = progress;
      });
    }
  }

  Future<int> getTotalSections(String jsonFilePath) async {
    final data = await rootBundle.loadString(jsonFilePath);
    final jsonResult = jsonDecode(data);
    return (jsonResult['sections'] as List).length;
  }

  IconData getCourseIcon(String title) {
    switch (title) {
      case 'Mathématiques':
        return Icons.calculate;
      case 'Français':
        return Icons.language;
      case 'Arabe':
        return Icons.translate;
      case 'Éducation Islamique':
        return Icons.mosque;
      case 'Éducation Artistique':
        return Icons.brush;
      default:
        return Icons.menu_book;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(AppLocalizations.of(context)!.class2,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 10),
            height: 150,
            child: Image.asset('assets/images/Mathematics_toy.png'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                final title = course['title']!;
                final progress = courseProgress[title] ?? 0.0;
                final percentText = (progress * 100).toStringAsFixed(0);
                final icon = getCourseIcon(title);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GestureDetector(
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
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(icon, color: Colors.teal),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  "$percentText%",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.grey[300],
                              color: Colors.teal,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
