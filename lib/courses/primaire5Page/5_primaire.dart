import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mortaalim/tools/HomeCourse.dart';
import 'package:shared_preferences/shared_preferences.dart';

class primaire5 extends StatefulWidget {
  @override
  _primaire5State createState() => _primaire5State();
}

class _primaire5State extends State<primaire5> {
  final List<Map<String, String>> courses = [
    {'title': 'Mathématiques', 'file': 'assets/courses/primary/microeconomics.json'},
    {'title': 'Activité scientifique', 'file': 'assets/courses/primary/macroeconomics.json'},
    {'title': 'Arabe', 'file': 'assets/courses/primary/economics.json'},
    {'title': 'Francais', 'file': 'assets/courses/primary/economics.json'},
    {'title': 'Education Islamique', 'file': 'assets/courses/primary/economics.json'},
    {'title': 'Education Artistique', 'file': 'assets/courses/primary/economics.json'},
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
        backgroundColor: Colors.white,
        appBar: AppBar(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            title: Text('5ème Primaire')),
        body: Column(children: [
          Expanded(child: Image.asset('assets/images/Mathematics_child.png',
            height: MediaQuery.of(context).size.width,
            width: MediaQuery.sizeOf(context).width,)),
          Expanded(flex: 2,
            child: ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                final title = course['title']!;
                final progress = courseProgress[title] ?? 0.0;
                final percentText = (progress * 100).toStringAsFixed(0);
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Card(
                    color: Theme.of(context).cardColor,
                    child: ListTile(
                      title: Text('$title ($percentText%)'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CoursePage(
                              jsonFilePath: course['file']!,
                              courseId: title,
                            ),
                          ),
                        ).then((_) => loadProgressForCourses()); // refresh when returning
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],)
    );
  }
}