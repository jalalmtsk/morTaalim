import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/tools/HomeCourse.dart';
import 'package:shared_preferences/shared_preferences.dart';

class primaire1Exam extends StatefulWidget {
  @override
  _primaire1ExamState createState() => _primaire1ExamState();
}

class _primaire1ExamState extends State<primaire1Exam> {
  final List<Map<String, String>> courses = [
    {'title': 'Mathématiques', 'file': 'assets/courses/primary/microeconomics.json'},
    {'title': 'Activité scientifique', 'file': 'assets/courses/primary/economy.json'},
    {'title': 'Arabe', 'file': 'assets/courses/primary/economics.json'},
    {'title': 'Français', 'file': 'assets/courses/primary/economics.json'},
    {'title': 'Éducation Islamique', 'file': 'assets/courses/primary/economics.json'},
    {'title': 'Éducation Artistique', 'file': 'assets/courses/primary/economics.json'},
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 20),
            height: 180,
            child: Image.asset('assets/images/Mathematics_toy.png'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Choisis une matière',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                final title = course['title']!;
                final progress = courseProgress[title] ?? 0.0;
                final percentText = (progress * 100).toStringAsFixed(0);

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
                                Icon(Icons.book_outlined, color: Colors.deepPurple),
                                const SizedBox(width: 8),
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
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: Colors.grey[300],
                              color: Colors.deepPurple,
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
